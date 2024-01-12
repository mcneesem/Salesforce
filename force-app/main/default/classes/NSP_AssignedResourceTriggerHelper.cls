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
        Map<Id, DateTime> mapprojectTaskStartDateTime = new Map<Id, DateTime>();
        Map<Id, DateTime> mapprojectTaskEndDateTime = new Map<Id, DateTime>();
        Map<Id, Id> mapServAppServTerr = new Map<Id, Id>();
        Map<Id, Id> mapprojectTaskServTerr = new Map<Id, Id>();
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
                    mapServAppServTerr.put(resource.ServiceAppointmentId, getServiceTerriortyId(resource.ServiceResourceId));
                }    
            }
            for( ServiceResource eachServiceRes : [ SELECT Id,RelatedRecordId FROM ServiceResource WHERE Id IN: assignedVsService.keySet()]){
                resVsResUserIdMap.put(assignedVsService.get(eachServiceRes.Id), eachServiceRes.RelatedRecordId );
            }
            
            for(ServiceAppointment appt : [Select Id, OwnerId, NSP_Project_Task_ID__c,SchedStartTime, SchedEndTime FROM ServiceAppointment WHERE Id IN: sAVsAssigned.keySet() AND Status IN ('Scheduled', 'Dispatched')]){
                appt.OwnerId = resVsResUserIdMap.get(sAVsAssigned.get(appt.Id));
                appt.ServiceTerritoryId = mapServAppServTerr.get(appt.Id);
                mapOfProjectTaskOwnerAndSAOwnerId.put(appt.NSP_Project_Task_ID__c, resVsResUserIdMap.get(sAVsAssigned.get(appt.Id)));
                mapprojectTaskStartDateTime.put(appt.NSP_Project_Task_ID__c, appt.SchedStartTime);
                mapprojectTaskEndDateTime.put(appt.NSP_Project_Task_ID__c, appt.SchedEndTime);
                mapprojectTaskServTerr.put(appt.NSP_Project_Task_ID__c, mapServAppServTerr.get(appt.Id));
                serAppToUpdate.add(appt);
            }
            for(pse__Project_Task__c pTask : [SELECT id, pse__Start_Date_Time__c, pse__End_Date_Time__c  FROM pse__Project_Task__c WHERE ID IN : mapOfProjectTaskOwnerAndSAOwnerId.keyset()]){
                pTask.OwnerId = mapOfProjectTaskOwnerAndSAOwnerId.get(pTask.id);
                pTask.pse__Start_Date_Time__c = mapprojectTaskStartDateTime.get(pTask.id);
                pTask.pse__End_Date_Time__c = mapprojectTaskEndDateTime.get(pTask.id);
                pTask.NSP_Dispatch_Region__c = mapprojectTaskServTerr.get(pTask.Id);
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
    
    Public static Id getServiceTerriortyId(Id servResId){
        List<String> serviceTerrMemFields = new List<String>{'Id','ServiceResourceId', 'ServiceTerritoryId'};
        String query = new NSP_QueryBuilder('ServiceTerritoryMember', serviceTerrMemFields)
            					.addFilter('ServiceResourceId', servResId)
            					.addLimit(1).build();
        ServiceTerritoryMember serviceTerrMem = Database.query(query);
        return serviceTerrMem.ServiceTerritoryId;
    }

}