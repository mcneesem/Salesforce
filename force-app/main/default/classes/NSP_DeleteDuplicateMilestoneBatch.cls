/**
* @description  :  Batch Class to delete duplicate milestones
* @date 12/15/2022
* Author : Abhishek Kumar
* Name : NSP_DeleteDuplicateMilestoneBatch
* Story : STY-02725
* Version : first iteration
*/
public class NSP_DeleteDuplicateMilestoneBatch implements Schedulable,Database.Batchable<SObject>{

    private static final List<String> MILESTONE_FIELDS = new List<String>{
        'Id',
        'Name',
        'pse__Project__c'
    };

    //start
    public Database.QueryLocator start(Database.BatchableContext bc){
        //query to duplicate milestones
        String query = new NSP_QueryBuilder('pse__Milestone__c', MILESTONE_FIELDS)
                            .addFilter('NSP_isDuplicate__c', true)
                            .build();
        
        return Database.getQueryLocator(query);
    }
    
    //Execute
    public void execute(Database.BatchableContext bc, List<pse__Milestone__c> milestoneList){
        List<Id> milestoneIds = new List<Id>();
        List<String> milestoneNameList = new List<String>();
        Map<String,Id> mapOldMilestoneName = new Map<String,Id>();
        List<pse__Project_Task__c> projectTaskListToUpdate = new List<pse__Project_Task__c>();
        try{
            //iterate over queried milestone to store id and name
            for(pse__Milestone__c eachMilestone : milestoneList ){
                milestoneIds.add(eachMilestone.Id);
                milestoneNameList.add(eachMilestone.Name);
            }
            //iterate over milstones with same name w
            if( !milestoneNameList.isEmpty()){
                for(pse__Milestone__c eachOldMilestone : [SELECT ID,Name FROM pse__Milestone__c WHERE NAME IN: milestoneNameList AND NSP_isDuplicate__c = false]){
                    mapOldMilestoneName.put(eachOldMilestone.Name, eachOldMilestone.Id);
                }
            }
            //iterate over project having reference of duplicate Milestones
            if(!milestoneIds.isEmpty()){
                for(pse__Project_Task__c eachProjectTask : [SELECT ID,Name,pse__Milestone__c,pse__Milestone__r.Name  FROM pse__Project_Task__c WHERE pse__Milestone__c IN: milestoneIds ]){
                    eachProjectTask.pse__Milestone__c = mapOldMilestoneName.get(eachProjectTask.pse__Milestone__r.Name);
                    projectTaskListToUpdate.add(eachProjectTask);
                }
            }
            //update project task's milestone reference
            if(!projectTaskListToUpdate.isEmpty()){
                List<Database.SaveResult> results = Database.update(projectTaskListToUpdate,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_DeleteDuplicateMilestoneBatch', 'ExecuteMethod', results );
            }
            //delete duplicate milestones   
            if(!milestoneIds.isEmpty()){
                List<Database.DeleteResult> results = Database.delete(milestoneIds,false); 
                NSP_ErrorLogHandler.logDeleteResultsException('NSP_DeleteDuplicateMilestoneBatch', 'ExecuteMethod', results );
            }
            
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_DeleteDuplicateMilestoneBatch', 'ExecuteMethod', ex.getMessage());
        }
    }

    //finish
    public void finish(Database.BatchableContext bc){
        
    }
    public void execute(SchedulableContext scon) {
        //Executes Batch
        Database.executeBatch(new NSP_DeleteDuplicateMilestoneBatch(),200);
    }
    
}