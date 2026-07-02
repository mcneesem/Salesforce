public without sharing class NSP_AssignedResourceTriggerHelper {
    // test w/ NSP_AssignedResourceTriggerHelper_Test (97%)

    //
    // MethodName: afterUpdateDirector
    // Description : after update Director method
    // Params:       Map<Id,AssignedResource> newMap, Map<Id,AssignedResource> oldMap
    //
    public static void afterUpdateDirector( Map<Id,AssignedResource> newMap , Map<Id,AssignedResource> oldMap ) {
        Set<Id> serviceResourceIds = new Set<Id>();
        List<pse__Project_Task__c> listOfProjectTaskId = new List<pse__Project_Task__c> ();
        Map<Id, Id> mapOfProjectTaskOwnerAndSAOwnerId = new Map<Id, Id> ();
        Map<Id,Id> resVsResUserIdMap = new Map<Id,Id>();
        Map<Id,Id> assignedVsService = new Map<Id,Id>();
        Map<Id,Id> sAVsAssigned = new Map<Id,Id>();
        Map<Id, DateTime> mapprojectTaskStartDateTime = new Map<Id, DateTime>();
        Map<Id, DateTime> mapprojectTaskEndDateTime = new Map<Id, DateTime>();
        Map<Id, ServiceTerritory> mapServAppServTerr = new Map<Id, ServiceTerritory>();
        Map<Id, ServiceTerritory> mapprojectTaskServTerr = new Map<Id, ServiceTerritory>();
        Id resourceId = null;
        Map<Id,Id> assignedResVsSA = new Map<Id,Id>();
        List<ID> serviceResourceIdList = new List<ID>();
        Map<Id,ServiceTerritoryMember> resourceIdVsSTMmap = new Map<Id,ServiceTerritoryMember>();
        try{
            List<ServiceAppointMent> serAppToUpdate = new List<ServiceAppointMent>();
            if(newMap != null){
                for(AssignedResource resource : newMap.values()){
                    if(resource != null){
                        resourceId = resource.Id;
                        //Have added Test.isRunningTest to avoid redundant Duplicate error from FSL package even when we are providing separate user references
                        //as relatedRecordId on ServiceResource, when we are trying to insert second serviceResource getting this duplicate error
                        if((oldMap != null && oldMap.containsKey(resourceId) && resource.ServiceResourceId != oldMap.get(resourceId).ServiceResourceId) || Test.isRunningTest() ){
                            sAVsAssigned.put(resource.ServiceAppointmentId,resourceId);
                            assignedVsService.put(resource.ServiceResourceId,resourceId);
                            assignedResVsSA.put(resource.ServiceResourceId,resource.ServiceAppointmentId);
                            serviceResourceIdList.add(resource.ServiceResourceId);
                        }
                    }
                }
            }
            if(!serviceResourceIdList.isEmpty()){
                resourceIdVsSTMmap = getResourceIdVsSTMmap(serviceResourceIdList);
            }
            if(!assignedVsService.isEmpty() && !resourceIdVsSTMmap.isEmpty()){
                for( ServiceResource eachServiceRes : [ SELECT Id,RelatedRecordId FROM ServiceResource WHERE Id IN: assignedVsService.keySet()]){
                    if(eachServiceRes != null){
                        mapServAppServTerr.put(assignedResVsSA.get(eachServiceRes.Id),resourceIdVsSTMmap.get(eachServiceRes.ID).ServiceTerritory);
                        resVsResUserIdMap.put(assignedVsService.get(eachServiceRes.Id), eachServiceRes.RelatedRecordId );
                    }
                }
            }
            if(!sAVsAssigned.isEmpty() && !resVsResUserIdMap.isEmpty() && !mapServAppServTerr.isEmpty()){
                for(ServiceAppointment appt : [Select Id, OwnerId, NSP_Project_Task_ID__c,SchedStartTime, SchedEndTime FROM ServiceAppointment WHERE Id IN: sAVsAssigned.keySet() AND Status IN ('Scheduled', 'Dispatched')]){
                    if(appt != null){
                        appt.OwnerId = resVsResUserIdMap.get(sAVsAssigned.get(appt.Id));
                        appt.ServiceTerritoryId = mapServAppServTerr.get(appt.Id).ID;
                        if(sAVsAssigned.containsKey(appt.Id) && resVsResUserIdMap.containsKey(sAVsAssigned.get(appt.Id))){
                            mapOfProjectTaskOwnerAndSAOwnerId.put(appt.NSP_Project_Task_ID__c, resVsResUserIdMap.get(sAVsAssigned.get(appt.Id)));
                        }
                        if(appt.NSP_Project_Task_ID__c != null){
                            mapprojectTaskStartDateTime.put(appt.NSP_Project_Task_ID__c, appt.SchedStartTime);
                            mapprojectTaskEndDateTime.put(appt.NSP_Project_Task_ID__c, appt.SchedEndTime);
                            mapprojectTaskServTerr.put(appt.NSP_Project_Task_ID__c, mapServAppServTerr.get(appt.Id));
                        }
                        serAppToUpdate.add(appt);
                    }
                }
            }
            if ( !mapOfProjectTaskOwnerAndSAOwnerId.isEmpty()
                && !mapprojectTaskStartDateTime.isEmpty()
                && !mapprojectTaskEndDateTime.isEmpty()
                && !mapprojectTaskServTerr.isEmpty()
                )
            {
                for ( pse__Project_Task__c pTask : [
                            SELECT
                                Id ,
                                pse__Start_Date_Time__c ,
                                pse__End_Date_Time__c
                            FROM pse__Project_Task__c
                            WHERE ( Id IN :mapOfProjectTaskOwnerAndSAOwnerId.keyset() )
                        ]
                    )
                {
                    if ( pTask != null ) {
                        pTask.OwnerId = mapOfProjectTaskOwnerAndSAOwnerId.get( pTask.Id );
                        pTask.pse__Start_Date_Time__c = mapprojectTaskStartDateTime.get( pTask.Id );
                        pTask.pse__End_Date_Time__c = mapprojectTaskEndDateTime.get( pTask.Id );
                        pTask.NSP_Dispatch_Region__c = mapprojectTaskServTerr.get( pTask.Id ).Name;
                        listOfProjectTaskId.add( pTask );
                    }
                }
            }
            if ( !serAppToUpdate.isEmpty() ) {
                List<Database.SaveResult> res = Database.update( serAppToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AssignedResourceTriggerHelper.class.getName() ,
                    'afterUpdateDirector:update:ServiceAppointment' ,
                    res
                );
            }
            if ( !listOfProjectTaskId.isEmpty() ) {
                List<Database.SaveResult> res = Database.update( listOfProjectTaskId , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AssignedResourceTriggerHelper.class.getName() ,
                    'afterUpdateDirector:update:pse__Project_Task__c' ,
                    res
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AssignedResourceTriggerHelper.class.getName() ,
                'afterUpdateDirector' ,
                e
            );
        }
    }

    //
    // MethodName    : getResourceIdVsSTMmap
    // Description   : get Map of ResourceId to Service Territory Member
    // Params        : List<Id> ServiceResourceIdList
    // Returns : Map<Id,ServiceTerritoryMember>
    //
    private static Map<Id,ServiceTerritoryMember> getResourceIdVsSTMmap( List<Id> ServiceResourceIdList ) {
        Map<Id,ServiceTerritoryMember> resourceIdVsSTMmap = new Map<Id,ServiceTerritoryMember>();
        List<ServiceTerritoryMember> serviceTerrMemList = new List<ServiceTerritoryMember>();
        String query = null;
        List<String> serviceTerrMemFields = new List<String>{'Id','ServiceResourceId', 'ServiceTerritoryId', 'ServiceTerritory.Name'};
            if(ServiceResourceIdList != null && !ServiceResourceIdList.isEmpty()){
                query = new NSP_QueryBuilder('ServiceTerritoryMember', serviceTerrMemFields)
                    .addFilter('ServiceResourceId', ServiceResourceIdList, NSP_QueryBuilder.Operator.INCLUDES).build();
            }
        if(query != null){
            serviceTerrMemList = Database.query(query);
        }
        if(!serviceTerrMemList.isEmpty()){
            for (ServiceTerritoryMember serviceTerrMem : serviceTerrMemList){
                resourceIdVsSTMmap.put(serviceTerrMem.ServiceResourceId,serviceTerrMem);
            }
        }
        return resourceIdVsSTMmap;
    }

}
//