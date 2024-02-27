/**
* @description  : 
* @author Harsha Khiroya
* @date 15/11/2023
* Name : NSP_CreateRAforRecurringEventsBatch
*/
global without sharing class NSP_CreateRAforRecurringEventsBatch implements Schedulable,Database.Batchable<SObject>, Database.Stateful {
    // test w/ NSP_CreateRAforRecurringEventsBatchTest (93%)

    public Database.QueryLocator start(Database.BatchableContext bc){
        String RecurringCreatedDate = System.Label.Recurring_Created_Date;
        //returns QueryLocator to execute method.
        String query = 'SELECT Id,OwnerId, Subject, StartDateTime, EndDateTime,showAs FROM Event WHERE WhatId = null and (IsRecurrence2 = true or IsRecurrence=true) and createdBy.NSP_Salesforce_Field_Service__c IN (\'Dispatcher + Resource\',\'Resource\') and recordType.Name = \'Core Sales Event RT\' and createdDate = '+ RecurringCreatedDate;
        return Database.getQueryLocator(query);
    }

    //Execute Method of Batch Class.
    global void execute(Database.BatchableContext bc, List<Event> scope){
        Map <ID,ID> mapOfServiceResourceMem = new  Map <ID,ID>();
        Set<Id> ownerIdSet = new Set<Id>();
        Set<Id> eventIdSet = new Set<Id>();
        Integer eventCount = 0;
        List <ResourceAbsence> resList = new List<ResourceAbsence> ();
        List<ResourceAbsence> resAbsence = NEW List<ResourceAbsence>();
        Map<String,Id> eventIdToRAidMap = new Map<String,Id>(); 
        Map<ID, Event> eventMap = null;
        List<Event> eventScope = new List<Event>();
        String TRAVEL = 'Travel';
        Schema.RecordTypeInfo info = SObjectType.ResourceAbsence.getRecordTypeInfosByDeveloperName().get('Non_Availability');
        Id NArecordType = null;
        if ( info != null ) {
            NArecordType = info.getRecordTypeId();
        }
        
        //creating Map of events in scope
        if (scope != NULL && scope.size() > 0){
            eventMap = NEW Map<ID, Event>(scope);
        }
        //creating list of existing RA
        if (eventMap != NULL && eventMap.size() > 0){
            resAbsence = [SELECT Id, Event_Id__c FROM ResourceAbsence WHERE Event_Id__c IN :eventMap.keySet()];
        }
        if (resAbsence.size() > 0){
            for (ResourceAbsence eachRA : resAbsence){
                eventIdToRAidMap.put(eachRA.Event_Id__c,eachRA.Id);
            }
        }
        if(scope != NULL){
            for(Event eventRec : scope){
                //checking if events in scope already has a RA created
                if (!eventIdToRAidMap.containsKey( eventRec.Id ) || ( eventIdToRAidMap.get( eventRec.Id ) == null)){
                    ownerIdSet.add(eventRec.OwnerId); 
                    eventIdSet.add(eventRec.Id);
                    eventScope.add(eventRec);
                }
            }
        }
        
        if(ownerIdSet.Size() > 0){
            Map<Id,User> userIdMap = new Map<Id,User>([SELECT Id from user where Id In :ownerIdSet AND (NSP_Salesforce_Field_Service__c = 'Resource' OR NSP_Salesforce_Field_Service__c = 'Dispatcher + Resource')]);
            for(ServiceResource serviceResourceMember : [SELECT RelatedRecordId, Id FROM ServiceResource where RelatedRecordId In :ownerIdSet AND ResourceType = 'T']){
                if(!mapOfServiceResourceMem.containsKey(serviceResourceMember.RelatedRecordId)){
                    mapOfServiceResourceMem.put(serviceResourceMember.RelatedRecordId,serviceResourceMember.Id);
                }
            }
            if (eventScope.size() > 0){
                for (Event eventRec : eventScope){
                    if ( mapOfServiceResourceMem != null && mapOfServiceResourceMem.containsKey(eventRec.OwnerId) ) {
                        ResourceAbsence resObject = new ResourceAbsence();
                        resObject.ResourceId = mapOfServiceResourceMem.get(eventRec.OwnerId);
                        resObject.Type = eventRec.Subject;
                        if (String.isNotBlank( eventRec.Subject ) && ((eventRec.Subject).toLowerCase()).contains(TRAVEL.toLowerCase())){
                            resObject.FSL__GanttLabel__c = TRAVEL;
                        } else{
                            resObject.FSL__GanttLabel__c = eventRec.ShowAs;
                        }
                        resObject.Start = eventRec.StartDateTime;
                        resObject.End = eventRec.EndDateTime;
                        resObject.Event_Id__c = String.valueOf(eventRec.Id);
                        if ( NArecordType != null ) {
                            resObject.RecordTypeId = NArecordType;
                        }
                        resList.add(resObject); 
                    }
                }
            }
        }
        if(!resList.isEmpty()){
            try{
                List<Database.SaveResult> results = Database.insert(resList, false);
                NSP_ErrorLogHandler.logSaveResult('NSP_CreateRAforRecurringEventsBatch', 'updateResourceAbscene', results );
            }
            catch(Exception ex){
                NSP_ErrorLogHandler.logSaveException('NSP_CreateRAforRecurringEventsBatch', 'updateResourceAbscene', ex.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc){
    }

    global void execute(SchedulableContext scon) {
        Database.executeBatch(new NSP_CreateRAforRecurringEventsBatch(),100);
    }

    public static void schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        System.schedule(
            'NSP_CreateRAforRecurringEventsBatch ~ Create Resource Absences for previous day events ~ everyday at 1 AM' + suffix ,
            '0 0 1 1/1 * ? *', // this is for Every Day at 1:00 AM...
            new NSP_CreateRAforRecurringEventsBatch()
        );
    }

}