/**
 * 
Apex Class Name      :  NSP_ServicePlanProjectTaskBatch
Version              :  1.0                                                                          
Created Date         :  6/1/2022  
Function             :  Represents batch class for NSP_ServicePlanProjectTaskBatch 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Jatin Ahuja                    6/9/2022           First Iteration
*
*/

public class NSP_ServicePlanProjectTaskBatch implements Database.Batchable<sObject>{

    public Database.QueryLocator start(Database.BatchableContext BC){
        //Using SOQL QUery to fetch Template Name, project status from Project Task object
        String query = 'SELECT Id, Name, TemplateName__c, pse__Project_Status__c, pse__Project_Type__c, pse__Account__c '+
            'FROM pse__Proj__c WHERE '+
            'TemplateName__c = '+'\''+ NSP_ServiceConstants.PROJECT_TEMPLATE_NAME +'\''+
            'AND pse__Is_Template__c = False '+
            'AND pse__Project_Type__c = '+'\''+ NSP_ServiceConstants.PROJECT_TYPE_SERVICE +'\''+
            'AND pse__Account__r.NSP_Sales_Service_Account_Status__c = '+'\''+ NSP_ServiceConstants.Account_Status +'\''+
            'AND (pse__Project_Status__c != '+'\''+ NSP_ServiceConstants.PROJECTSTATUSCANCELLED +'\''+
            'AND pse__Project_Status__c != '+'\''+ NSP_ServiceConstants.PROJECTSTATUSCOMPLETED +'\''+')';
        return Database.getQueryLocator(query);   
    }
    
    public void execute(Database.BatchableContext BC, List<pse__Proj__c> relatedProjectList){
        List<sObject> lstOfRecords = new List<sObject>();
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        Map<Id, Date> mapOfAccountIdAndRenewalDate = new Map<Id, Date> ();
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, NSP_Account_Team__c> accountTeamMap = new Map<Id, NSP_Account_Team__c>();
        
        String peoProjectTaskRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT_TASK_SOBJECT_TYPE, NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE);
        String woAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        // check relatedprojectlist not empty
        if(relatedProjectList.size() > 0){
            //iterating over project list
            for(pse__Proj__c prj : relatedProjectList){
                accountIdSet.add(prj.pse__Account__c);
            }
        }
        
        // check accountIDset not empty
        if(!accountIdSet.isEmpty()){
            for(NSP_Account_Team__c team : Database.Query(getAccountTeamQuery(accountIdSet))){
                accountTeamMap.put(team.NSP_Account__c, team);                                    
            }    
        }        
        // Get Sub Client
        for(pse__Proj__c project : [SELECT  Id, TemplateName__c,pse__Account__c, pse__Project_Type__c, RecordTypeId, pse__Account__r.NSP_AIMS_Renewal_Date__c, pse__Start_Date__c, pse__End_Date__c 
                                            FROM pse__Proj__c 
                                            WHERE ID IN : relatedProjectList]){
                     if(!mapOfAccountIdAndRenewalDate.containsKey(project.id)){
                        mapOfAccountIdAndRenewalDate.put(project.pse__Account__c, project.pse__Account__r.NSP_AIMS_Renewal_Date__c);
                      }
        }
        if(relatedProjectList.size() > 0){
            for(pse__Proj__c prj : relatedProjectList){
                //checking for Account Id && renewal date
                if(mapOfAccountIdAndRenewalDate.get(prj.pse__Account__c) == System.today()){
                    Integer randomNumber = Integer.valueof((Math.random() * 1847263450));
                    pse__Project_Task_Assignment__c projTaskAssigmt = new pse__Project_Task_Assignment__c();
                    projTaskAssigmt.pse__Resource_Role__c = NSP_ServiceConstants.BUS_TEAM_HRSP_CL;
                    projTaskAssigmt.NSP_Priority__c = 1;
                    pse__Project_Task__c projectTaskReference = new pse__Project_Task__c(pse__External_Task_ID__c = prj.Id+'-'+NSP_ServiceConstants.QTP1+'-'+randomNumber);                
                    projTaskAssigmt.pse__Project_Task__r = projectTaskReference;
                    
                    pse__Project_Task_Assignment__c projTaskAssigmt2 = new pse__Project_Task_Assignment__c();
                    projTaskAssigmt2.pse__Resource_Role__c = NSP_ServiceConstants.BUS_TEAM_HRSP_CL;
                    projTaskAssigmt2.NSP_Priority__c = 1;
                    pse__Project_Task__c projectTaskReference2 = new pse__Project_Task__c(pse__External_Task_ID__c = prj.Id+'-'+NSP_ServiceConstants.QTP2+'-'+randomNumber);                
                    projTaskAssigmt2.pse__Project_Task__r = projectTaskReference2;
                    
                    //create project task
                    pse__Project_Task__c projectTask = new pse__Project_Task__c();
                    projectTask.Name = NSP_ServiceConstants.QTP1;
                    projectTask.pse__Project__c = prj.Id;
                    projectTask.RecordTypeId = peoProjectTaskRecordTypeId;
                    projectTask.pse__Start_Date_Time__c = mapOfAccountIdAndRenewalDate.get(prj.pse__Account__c).addDays(90);
                    projectTask.pse__End_Date_Time__c = mapOfAccountIdAndRenewalDate.get(prj.pse__Account__c).addDays(120);
                    projectTask.NSP_Category__c = NSP_ServiceConstants.Client_Management;
                    projectTask.NSP_Sub_Category__c = NSP_ServiceConstants.Quality_Touch_Point;
                    projectTask.pse__External_Task_ID__c = prj.Id+'-'+NSP_ServiceConstants.QTP1+'-'+randomNumber;
                    projectTask.OwnerId = accountTeamMap.get(prj.pse__Account__c).NSP_User__c;
                    lstOfRecords.add(projectTask);
                    lstOfRecords.add(projTaskAssigmt);    
                    
                    //create project task
                    pse__Project_Task__c projectTask1 = new pse__Project_Task__c();
                    projectTask1.Name = NSP_ServiceConstants.QTP2;
                    projectTask1.pse__Project__c = prj.Id;
                    projectTask1.RecordTypeId = peoProjectTaskRecordTypeId;
                    projectTask1.pse__Start_Date_Time__c = mapOfAccountIdAndRenewalDate.get(prj.pse__Account__c).addDays(185);
                    projectTask1.pse__End_Date_Time__c = mapOfAccountIdAndRenewalDate.get(prj.pse__Account__c).addDays(215);
                    projectTask1.NSP_Category__c = NSP_ServiceConstants.Client_Management;
                    projectTask1.NSP_Sub_Category__c = NSP_ServiceConstants.Quality_Touch_Point;
                    projectTask1.pse__External_Task_ID__c = prj.Id+'-'+NSP_ServiceConstants.QTP2+'-'+randomNumber;
                    projectTask1.OwnerId = accountTeamMap.get(prj.pse__Account__c).NSP_User__c;
                    lstOfRecords.add(projectTask1);
                    lstOfRecords.add(projTaskAssigmt2);
                    
                }
            } 
        } 
        //insert projectTasklist if not empty
        if(lstOfRecords.size() > 0){
            lstOfRecords.sort();
            NSP_ProjectTasksTriggerServiceHelper.runOwnerAssignmentLogic = false;
            Database.SaveResult[] results = Database.insert(lstOfRecords, false);
            NSP_ErrorLogHandler.logResults(
                NSP_ServicePlanProjectTaskBatch.class.getName() ,
                'execute' ,
                results
            );
        }
    }
    
    public void finish(Database.BatchableContext BC){
    
    }
    
    /**
    * @param accountIds Set of accountIds that is associated with project Account
    * @return void
    */
    public static String getAccountTeamQuery(Set<Id> accountIds){
        String accTeamQuery = new NSP_QueryBuilder('NSP_Account_Team__c', new List<String>{'NSP_Account__c','NSP_Role__c','NSP_User__c','NSP_Primary__c','NSP_First_Name__c'})
            .addFilter('NSP_Role__c', NSP_ServiceConstants.BUS_TEAM_HRSP_CL , NSP_QueryBuilder.Operator.EQUALS)
            .addFilter('NSP_Account__c', new List<Id>(accountIds) , NSP_QueryBuilder.Operator.INCLUDES)
            .build();

        return accTeamQuery;
    }
}