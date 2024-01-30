/**
* @description  : 
* @author Harsha Khiroya
* @date 15/11/2023
* Name : NSP_CreateRAforRecurringEventsBatch
*/
global without sharing class NSP_CreateRAforRecurringEventsBatch implements Schedulable,Database.Batchable<SObject>, Database.Stateful {
    // test w/ NSP_CreateRAforRecurringEventsBatchTest (93%)

    public Integer recordsProcessed = 0; // stores number of records processed.
    public static String RecurringCreatedDate = System.Label.Recurring_Created_Date;


    public Database.QueryLocator start(Database.BatchableContext bc){
        //returns QueryLocator to execute method.
        String query = 'SELECT Id,OwnerId, Subject, StartDateTime, EndDateTime,showAs FROM Event WHERE WhatId = null and (IsRecurrence2 = true or IsRecurrence=true) and createdBy.NSP_Salesforce_Field_Service__c IN (\'Dispatcher + Resource\',\'Resource\') and recordType.Name = \'Core Sales Event RT\' and createdDate = '+ RecurringCreatedDate;
        return Database.getQueryLocator(query);
    }

    //Execute Method of Batch Class.
    global void execute(Database.BatchableContext bc, List<Event> scope){
        Map <ID,ID> mapOfServiceResourceMem = new  Map <ID,ID>();
        Set<Id> ownerIdSet = new Set<Id>();
        Set<Id> eventIdSet = new Set<Id>();
        Set<Id> recurringEvents = new Set<Id>();
        List<Event> eventList = new List<Event>();
        List<Event> eventListToUpdate = new List<Event>();
        Set<Id> eventsForRA = new Set<Id>();
        Map<Id,Id> eventResourceMap = new Map<Id,Id>();
        Integer eventCount = 0;
        List<ResourceAbsence> raUpdateList = new List<ResourceAbsence>();
        List <ResourceAbsence> resList = new List<ResourceAbsence> ();
        Id NArecordType = SObjectType.ResourceAbsence.getRecordTypeInfosByDeveloperName().get('Non_Availability').getRecordTypeId();
        for(Event eventRec : scope){
            ownerIdSet.add(eventRec.OwnerId); 
            eventIdSet.add(eventRec.Id);
        }
        if(ownerIdSet.Size() > 0){
            Map<Id,User> userIdMap = new Map<Id,User>([SELECT Id from user where Id In :ownerIdSet AND (NSP_Salesforce_Field_Service__c = 'Resource' OR NSP_Salesforce_Field_Service__c = 'Dispatcher + Resource')]);
            for(ServiceResource serviceResourceMember : [SELECT RelatedRecordId, Id FROM ServiceResource where RelatedRecordId In :ownerIdSet AND ResourceType = 'T']){
                if(!mapOfServiceResourceMem.containsKey(serviceResourceMember.RelatedRecordId)){
                    mapOfServiceResourceMem.put(serviceResourceMember.RelatedRecordId,serviceResourceMember.Id);
                }
            }
            for(Event eventRec : scope){ 
                if ( mapOfServiceResourceMem.containsKey(eventRec.OwnerId) ) {
                    ResourceAbsence resObject = new ResourceAbsence();
                    resObject.ResourceId = mapOfServiceResourceMem.get(eventRec.OwnerId);
                    resObject.Type = eventRec.Subject;
                    resObject.FSL__GanttLabel__c = eventRec.ShowAs;
                    resObject.Start = eventRec.StartDateTime;
                    resObject.End = eventRec.EndDateTime;
                    resObject.Event_Id__c = String.valueOf(eventRec.Id);
                    resObject.RecordTypeId = NArecordType;
                    resList.add(resObject); 
                    eventsForRA.add(resObject.Event_Id__c);
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
        for(ResourceAbsence res : [Select Id, Event_Id__c from ResourceAbsence where Event_Id__c in:eventsForRA ]){
            eventResourceMap.put(res.Event_Id__c, res.Id);
        }
        if(!eventResourceMap.isEmpty()){
            for(Event newEvent : [Select Id, WhatId,IsRecurrence2 from Event where Id in: eventIdSet]){
                if(eventResourceMap.containsKey(newEvent.Id)){
                    newEvent.WhatId = eventResourceMap.get(newEvent.Id);
                    eventListToUpdate.add(newEvent);
                }
            }
        }
        try{
            if(!eventListToUpdate.isEmpty()){
                List<Database.SaveResult> results = Database.update(eventListToUpdate, false);
                NSP_ErrorLogHandler.logSaveResult('NSP_CreateRAforRecurringEventsBatch', 'updateResourceAbscene', results );
            }
        }
        catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_EventTriggerHelper', 'updateResourceAbscene', ex.getMessage());
        }
    }

    public void finish(Database.BatchableContext bc){
    }

    global void execute(SchedulableContext scon) {
        Database.executeBatch(new NSP_CreateRAforRecurringEventsBatch(),100);
    }

    public static void schedule() {
        System.schedule(
            'NSP_CreateRAforRecurringEventsBatch ~ Create Resource Absences for previous day events ~ everyday at 1 AM',
            '0 0 1 1/1 * ? *', //This is for Every Day at 1:00 AM
            new NSP_CreateRAforRecurringEventsBatch()
        );
    }

}