public without sharing class NSP_CreateRAforRecurringEventsBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<SObject> , Database.Stateful {
    // test w/ NSP_CreateRAforRecurringEventsBatchTest (93%)

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_CreateRAforRecurringEventsBatch() {
    }

    //
    // ISelfSchedulable
    //

    // runs everyday at 1am central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_CreateRAforRecurringEventsBatch ~ Create Resource Absences for previous day events ~ everyday at 1 AM' + suffix ,
            '0 0 1 ? * * *' ,
            new NSP_CreateRAforRecurringEventsBatch()
        );
    }

    //
    // Scheduleable
    //

    public void execute( SchedulableContext sc ) {
        this.call( 'run' , null );
    }

    //
    // Callable
    //

    public Object call( String action , Map<String,Object> args ) {
        Object response = null;
        if ( action == 'run' ) {
            response = this.run();
        }
        return response;
    }

    //
    // IJobRunnable
    //

    public Id run() {
        return Database.executeBatch( new NSP_CreateRAforRecurringEventsBatch() , 100 );
    }

    //
    // Batchable
    //

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id ,
                    OwnerId ,
                    Subject ,
                    StartDateTime ,
                    EndDateTime ,
                    ShowAs
                FROM Event
                WHERE
                    ( WhatId = null )
                    AND ( ( IsRecurrence2 = true ) OR ( IsRecurrence = true ) )
                    AND (
                        CreatedBy.NSP_Salesforce_Field_Service__c IN (
                            'Dispatcher + Resource' ,
                            'Resource'
                        )
                    )
                    AND ( RecordTypeId = :NSP_CreateRAforRecurringEventsBatch.eventRecordTypeId )
                    AND ( CreatedDate <= :NSP_CreateRAforRecurringEventsBatch.createdDateTime )
                    AND ( CreatedDate > :NSP_CreateRAforRecurringEventsBatch.createdDateTime.addDays( -1 ) )
            ]
        );
    }

    //Execute Method of Batch Class.
    public void execute( Database.BatchableContext bc , List<Event> scope ) {
        try {
            Map <Id,Id> mapOfServiceResourceMem = new  Map<Id,Id>();
            Set<Id> ownerIdSet = new Set<Id>();
            Set<Id> eventIdSet = new Set<Id>();
            Integer eventCount = 0;
            List <ResourceAbsence> resList = new List<ResourceAbsence> ();
            List<ResourceAbsence> resAbsence = NEW List<ResourceAbsence>();
            Map<String,Id> eventIdToRAidMap = new Map<String,Id>();
            Map<Id,Event> eventMap = null;
            List<Event> eventScope = new List<Event>();
            String TRAVEL = 'Travel';
            Id naRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'ResourceAbsence' , 'Non_Availability' );
            //creating Map of events in scope
            if (scope != NULL && scope.size() > 0){
                eventMap = NEW Map<Id,Event>(scope);
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
                            if ( naRecordTypeId != null ) {
                                resObject.RecordTypeId = naRecordTypeId;
                            }
                            resList.add(resObject);
                        }
                    }
                }
            }
            NSP_CreateRAforRecurringEventsBatch.handleDmlOperations( resList );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_CreateRAforRecurringEventsBatch.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    public void finish( Database.BatchableContext bc ) {
    }


    //
    //
    //

    private static Set<Id> handleDmlOperations( List<ResourceAbsence> records ) {
        if ( ( records != null ) && !records.isEmpty() ) {
            try {
                List<Database.SaveResult> results = Database.insert( records , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_CreateRAforRecurringEventsBatch.class.getName() ,
                    'handleDmlOperations:insert' ,
                    results
                );
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    NSP_CreateRAforRecurringEventsBatch.class.getName() ,
                    'handleDmlOperations' ,
                    e
                );
            }
        }
        return new Set<Id>();
    }

    private static CreateResourceAbsencesBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = CreateResourceAbsencesBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Id eventRecordTypeId {
        private get {
            if ( eventRecordTypeId == null ) {
                Id local = NSP_GenericRecordType.getRecordTypeId( 'Event' , 'Core_Serv_Event_RT' );
                if ( ( NSP_CreateRAforRecurringEventsBatch.settings != null )
                    && String.isNotBlank( NSP_CreateRAforRecurringEventsBatch.settings.EventRecordTypeId__c )
                    && ( NSP_CreateRAforRecurringEventsBatch.settings.EventRecordTypeId__c InstanceOf Id )
                    )
                {
                    Id checkId = Id.valueOf( NSP_CreateRAforRecurringEventsBatch.settings.EventRecordTypeId__c );
                    if ( checkId.getSObjectType() == RecordType.getSObjectType() ) {
                        local = checkId;
                    }
                }
                eventRecordTypeId = local;
            }
            return eventRecordTypeId;
        }
        private set;
    }

    private static DateTime createdDateTime {
        private get {
            if ( createdDateTime == null ) {
                createdDateTime = System.now().addDays( -1 * NSP_CreateRAforRecurringEventsBatch.soqlDaysLimit );
            }
            return createdDateTime;
        }
        private set;
    }

    private static Integer soqlDaysLimit {
        private get {
            if ( soqlDaysLimit == null ) {
                Integer local = 1;
                if ( ( NSP_CreateRAforRecurringEventsBatch.settings != null )
                    && ( NSP_CreateRAforRecurringEventsBatch.settings.SoqlDaysLimit__c != null )
                    )
                {
                    local = NSP_CreateRAforRecurringEventsBatch.settings.SoqlDaysLimit__c.intValue();
                }
                if ( local < 0 ) {
                    local = 0;
                }
                soqlDaysLimit = local;
            }
            return soqlDaysLimit;
        }
        private set;
    }

}
//