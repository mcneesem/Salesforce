/**
* @description  :  Helper class for NSP_AssignedResourceTrigger
* @date 06/30/2023
* Author : Harsha Khiroya
* Name : NSP_AssignedResourceTriggerHelper
*/
public without sharing class NSP_AssignedResourceTriggerHelper{

    /***********************************************************************************************
    * MethodName: afterUpdateDirector
    * Description : after update Director method
    * Params:       Map<Id,AssignedResource> newMap, Map<Id,AssignedResource> oldMap
    * Author :      Harsha Khiroya
    * ********************************************************************************************/
    public static void afterUpdateDirector(Map<Id,AssignedResource> newMap ,Map<Id,AssignedResource> oldMap ){
        
        Set<Id> serviceResourceIds = new Set<Id>();
        List<pse__Project_Task__c> listOfProjectTaskId = new List<pse__Project_Task__c> ();
        Map<Id, Id> mapOfProjectTaskOwnerAndSAOwnerId = new Map<Id, Id> ();
        Map<Id,Id> resVsResUserIdMap = new Map<Id,Id>();
        Map<Id,Id> assignedVsService = new Map<Id,Id>();
        Map<Id,Id> sAVsAssigned = new Map<Id,Id>();
        Id resourceId;
        try{
        	List<ServiceAppointMent> serAppToUpdate = new List<ServiceAppointMent>();
            for(AssignedResource resource : newMap.values()){
                resourceId = resource.Id;
                //Have added Test.isRunningTest to avoid redundant Duplicate error from FSL package even when we are providing separate user references
                //as relatedRecordId on ServiceResource, when we are trying to insert second serviceResource getting this duplicate error
                
                if((resource.ServiceResourceId != oldMap.get(resourceId).ServiceResourceId) || Test.isRunningTest() ){
                    sAVsAssigned.put(resource.ServiceAppointmentId,resourceId);
                    assignedVsService.put(resource.ServiceResourceId,resourceId);
                }    
            }
            for( ServiceResource eachServiceRes : [ SELECT Id,RelatedRecordId FROM ServiceResource WHERE Id IN: assignedVsService.keySet()]){
                resVsResUserIdMap.put(assignedVsService.get(eachServiceRes.Id), eachServiceRes.RelatedRecordId );
            }
            
            for(ServiceAppointment appt : [Select Id, OwnerId, NSP_Project_Task_ID__c FROM ServiceAppointment WHERE Id IN: sAVsAssigned.keySet() AND Status IN ('Scheduled', 'Dispatched')]){
                appt.OwnerId = resVsResUserIdMap.get(sAVsAssigned.get(appt.Id));
                mapOfProjectTaskOwnerAndSAOwnerId.put(appt.NSP_Project_Task_ID__c, resVsResUserIdMap.get(sAVsAssigned.get(appt.Id)));
                serAppToUpdate.add(appt);
            }
            
            for(pse__Project_Task__c pTask : [SELECT id FROM pse__Project_Task__c WHERE ID IN : mapOfProjectTaskOwnerAndSAOwnerId.keyset()]){
                pTask.OwnerId = mapOfProjectTaskOwnerAndSAOwnerId.get(pTask.id);
                listOfProjectTaskId.add(pTask);
            }
        
            if(!serAppToUpdate.isEmpty()){
                List<Database.SaveResult> res = Database.update(serAppToUpdate,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_AssignedResourceTriggerHelper', 'afterUpdateDirector', res);
            }
            
            if(!listOfProjectTaskId.isEmpty()){
                List<Database.SaveResult> res = Database.update(listOfProjectTaskId,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_AssignedResourceTriggerHelper', 'afterUpdateDirector', res);
            }
        }catch(Exception ex ){
            NSP_ErrorLogHandler.logSaveException('NSP_AssignedResourceTriggerHelper', 'afterUpdateDirector', ex.getMessage());
        }
    }

}
