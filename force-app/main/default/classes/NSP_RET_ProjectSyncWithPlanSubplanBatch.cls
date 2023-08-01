/**************************************************************************************************************************
* @description  :  Batch Class to Syn RET Project records with plan, subplan field values populated from RET Asset
* @date 11/22/2022
* Author : Ramya Ravi
* Name : NSP_RET_ProjectSyncWithPlanSubplanBatch
* Story : STY-02240 - RET - Automation - Sync Projects with No Sub Plan Relationship
* Version : V1
**************************************************************************************************************************/
public class NSP_RET_ProjectSyncWithPlanSubplanBatch implements Schedulable,Database.Batchable<SObject>{

    //start method to query all RET Project records with Plan subplan null
    public Database.QueryLocator start(Database.BatchableContext bc){
        Id retProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', NSP_ServiceConstants.PROJECT_RET_RECORDTYPE);
        List<String> NSP_RET_PRJ_TEMPLATELIST = System.label.NSP_RET_PRJ_TEMPLATELIST.split(',')  ;
        String query = 'Select ID FROM pse__Proj__c ';
        query+= 'WHERE RecordTypeId =: retProjectRecordTypeId AND pse__Is_Template__c = FALSE AND TemplateName__c  LIKE :NSP_RET_PRJ_TEMPLATELIST AND (NSP_Plan__c = NULL OR NSP_Sub_Plan_Relationship__c = NULL) ' ;
        query+= 'AND pse__Project_Status__c in (' +'\''+ NSP_ServiceConstants.PROJECTSTATUSACTIVE  +'\','+'\''+ NSP_ServiceConstants.PROJECTSTATUSONHOLD  +'\','+'\''+ NSP_ServiceConstants.PROJECT_TASK_NOT_STARTED  +'\''+')';
        return Database.getQueryLocator(query);
    }
    //Execute method to populate plan subplan values from asset to project records
    public void execute(Database.BatchableContext bc, List<pse__Proj__c> projectList){
         try{ // Get RET choice and RET WO asset record type IDs
              Id RETCHOICEASSETRECORDTYPE = NSP_GenericRecordType.getRecordTypeId('Asset', 'RET_Choice');
              Id RETWOASSETRECORDTYPE = NSP_GenericRecordType.getRecordTypeId('Asset', 'RET_WO');
              List<ID> projectIds = new List<ID>();
              List<pse__Proj__c> projListToUpdate = new List<pse__Proj__c>();
             // Get list of project IDs
             for(pse__Proj__c projectRec: projectList){
                 projectIds.add(projectRec.ID);
             }                
             // Get plan sub plan IDs from linked RET choice or WO asset and update the fields in Project records
             for(Project_Asset__c projectAsset: [Select ID, Asset__c, Project__c,Asset__r.NSP_RET_Plan_and_Sub_Plan__c, Asset__r.NSP_RET_Plan_and_Sub_Plan__r.NSP_Parent_Plan_ID__c
                                                 FROM Project_Asset__c 
                                                 WHERE Project__c IN : projectIds  
                                                 AND (Asset__r.RecordTypeId = : RETCHOICEASSETRECORDTYPE OR Asset__r.RecordTypeId = :RETWOASSETRECORDTYPE) 
                                                 AND Asset__r.NSP_RET_Plan_and_Sub_Plan__c != NULL ]){                                                                                                                                                     
                                                     pse__Proj__c projToUpdate = new  pse__Proj__c();
                                                     projToUpdate.ID = projectAsset.Project__c;
                                                     projToUpdate.NSP_Plan__c = projectAsset.Asset__r.NSP_RET_Plan_and_Sub_Plan__r.NSP_Parent_Plan_ID__c;
                                                     projToUpdate.NSP_Sub_Plan_Relationship__c = projectAsset.Asset__r.NSP_RET_Plan_and_Sub_Plan__c;
                                                     projListToUpdate.add(projToUpdate);
                                                 }
             // Update the Project record List - DML Update
             if(!projListToUpdate.isEmpty()){
                 Database.update(projListToUpdate);
             }
         }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_RET_ProjectSyncWithPlanSubplanBatch', 'Execute', ex.getMessage());
        }        
    }
    
    //finish method
    public void finish(Database.BatchableContext bc){
        
    }
    
    // Schedulable execute method to fire the batch class
    public void execute(SchedulableContext scon){
        //To fire the Batchclass
        Database.executeBatch(new NSP_RET_ProjectSyncWithPlanSubplanBatch(),200);
    }
}