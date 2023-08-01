/***********************************************************************************************
* Class Name: NSP_assignTaskOwners
* Description : Controller Class for Assign Task Quick Action
* Author:       Nischay Jindal 
* CreatedDate : 20/06/2022
* ********************************************************************************************/

public class NSP_assignTaskOwners {
    
    /***********************************************************************************************
    * MethodName	: projectTaskAssignment
    * Description	: This method will update the owners on Project Task 
    * Params		: String projectId
    * Return		: void
    * ********************************************************************************************/
    @AuraEnabled
    public static void projectTaskAssignment(String projectId){
        List<pse__Project_Task__c> updateProjectTaskList = new List<pse__Project_Task__c>();
        Map<Id,Map<String,String>> mapProjectIdMapRoleContactId= new Map<Id,Map<String,String>>();
        Set<Id> contactIdSet = new Set<Id>();
        try{
            
            List<NSP_Project_Team__c> projectTeamList = [SELECT Id,NSP_Role__c, NSP_Project__c, NSP_Assignee__c, RecordTypeId FROM NSP_Project_Team__c 
                                                         WHERE NSP_Project__c =:projectId AND NSP_Role__c!=null AND NSP_Assignee__c!=null];
            
            for(NSP_Project_Team__c prjTeam :projectTeamList){
                contactIdSet.add(prjTeam.NSP_Assignee__c);
                if(!mapProjectIdMapRoleContactId.containsKey(prjTeam.NSP_Project__c)){
                    mapProjectIdMapRoleContactId.put(prjTeam.NSP_Project__c, new Map<String,String>());
                }
                mapProjectIdMapRoleContactId.get(prjTeam.NSP_Project__c).put(prjTeam.NSP_Role__c,prjTeam.NSP_Assignee__c);
            } 
            Map<Id,Contact> contactMap = new Map<Id,Contact>([Select Id , pse__Salesforce_User__c FROM Contact WHERE Id IN:contactIdSet 
                                                              AND pse__Salesforce_User__c != null]);
            // fetching list of Primary Project Task Assignments  related to Project
            List<pse__Project_Task_Assignment__c> projectTaskAssignList = [Select Id, Name,pse__Project_Task__c,  pse__Resource_Role__c,pse__Project_Task__r.pse__Project__c FROM
                                                                           pse__Project_Task_Assignment__c WHERE 
                                                                           ( pse__Resource_Role__c !=Null AND  pse__Resource_Role__c!= :NSP_ServiceConstants.Resource_Role) 
                                                                           AND (pse__Project_Task__r.pse__Status__c !=:NSP_ServiceConstants.PROJECTSTATUSCOMPLETED AND 
                                                                                pse__Project_Task__r.pse__Status__c !=:NSP_ServiceConstants.PROJECT_TASK_CANCELLED  ) 
                                                                           AND pse__Project_Task__r.pse__Project__c IN : mapProjectIdMapRoleContactId.keySet() ];
            // updating Project Task Owner based on Project Task Assignment Role and related Projects 
            for (pse__Project_Task_Assignment__c taskAssign:projectTaskAssignList){
                if(mapProjectIdMapRoleContactId.containsKey(taskAssign.pse__Project_Task__r.pse__Project__c) && 
                   mapProjectIdMapRoleContactId.get(taskAssign.pse__Project_Task__r.pse__Project__c).containsKey(taskAssign.pse__Resource_Role__c) &&
                   contactMap.containsKey(mapProjectIdMapRoleContactId.get(taskAssign.pse__Project_Task__r.pse__Project__c).get(taskAssign.pse__Resource_Role__c))
                  ){
                      pse__Project_Task__c prjTask = new pse__Project_Task__c();
                      prjTask.Id = taskAssign.pse__Project_Task__c;
                      prjTask.OwnerId = contactMap.get(mapProjectIdMapRoleContactId.get(taskAssign.pse__Project_Task__r.pse__Project__c).get(taskAssign.pse__Resource_Role__c)).pse__Salesforce_User__c;
                      updateProjectTaskList.add(prjTask);
                  }
            } 
            //updating Project Task Owners 
                if(!updateProjectTaskList.isEmpty()){
                    Database.Update(updateProjectTaskList,false) ;
                }
        }catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}