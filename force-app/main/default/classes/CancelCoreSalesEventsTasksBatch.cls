public without sharing class CancelCoreSalesEventsTasksBatch implements Database.Batchable<sObject>  {
    // test w/ CancelCoreSalesEventsTasksBatchTest (95%)

    private static Id evtRecTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Core_Sales_Event_RT').getRecordTypeId();
    private static Id evtMMRecTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Mid_Market_Event_RT').getRecordTypeId();
	private static Id taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Core_Sales_Task_RT').getRecordTypeId();
    private static Id taskMMRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Mid_Market_Task_RT').getRecordTypeId();

    List<Id> parentIds = new List<Id>();

    public CancelCoreSalesEventsTasksBatch(List<Id> parentIds){
        this.parentIds = parentIds;
    }
    
    public List<sObject> start(Database.BatchableContext bc) {
        sObject[] scope = new sObject[0];

        // cancels Core Sales Activities related to optional specified parent sObjects Ids (Account, Opportunity), 
        // otherwise cancels Core Sales Activities that have been inactive more than 30 (Event) or 45 (Task) days
        if(parentIds != null && !parentIds.isEmpty()) {
            scope.addAll([SELECT Id, WhatId, RecordTypeId, Status, ActivityDate, CreatedDate, NSP_Status__c
                    FROM Task
                    WHERE (
                        (RecordTypeId = :taskRecTypeId
                        OR RecordTypeId = :taskMMRecTypeId)
                        AND (
                            Status = null
                            OR Status = 'Open'
                        )
                        AND WhatId IN :parentIds
                    )
                ]);

            scope.addAll([SELECT Id, RecordTypeId, EndDateTime, CreatedDate, NSP_Status__c
                    FROM Event
                    WHERE (
                        (RecordTypeId = :evtRecTypeId
                        OR RecordTypeId = :evtMMRecTypeId)
                        AND IsRecurrence2 = false
                        AND FSL__Event_Type__c = null
                        AND (
                            NSP_Status__c = null
                            OR NSP_Status__c = 'Open'
                        )
                        AND WhatId IN :parentIds
                    )
                ]);
        } else {
            scope.addAll([
                    SELECT Id, RecordTypeId, Status, ActivityDate, CreatedDate, NSP_Status__c
                    FROM Task
                    WHERE (
                        RecordTypeId = :taskRecTypeId
                        AND (
                            Status = null
                            OR Status = 'Open'
                        )
                        AND (
                            ActivityDate < N_DAYS_AGO:45
                            OR (
                                ActivityDate = null
                                AND CreatedDate < N_DAYS_AGO:45
                            )
                        )
                    )
                ]);

            scope.addAll([SELECT Id, RecordTypeId, EndDateTime, CreatedDate, NSP_Status__c
                    FROM Event
                    WHERE (
                        RecordTypeId = :evtRecTypeId
                        AND IsRecurrence2 = false
                        AND FSL__Event_Type__c = null
                        AND (
                            NSP_Status__c = null
                            OR NSP_Status__c = 'Open'
                        )
                        AND (
                            EndDateTime < N_DAYS_AGO:30
                            OR (
                                EndDateTime = null
                                AND CreatedDate < N_DAYS_AGO:30
                            )
                        )
                    )
                ]);
        }
        return scope;
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        try {
            List<sObject> recordsToUpdate = new List<sObject>();
            
            for(sObject record : scope) {
                switch on record
                {
                    when Task tsk
                    {
                        tsk.Status = 'Cancelled';
                        tsk.NSP_Status__c = 'Cancelled';
                    }
                    when Event evt
                    {
                        evt.NSP_Status__c = 'Cancelled';
                    }
                }
                recordsToUpdate.add(record);
            }

            if ( !recordsToUpdate.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( recordsToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    CancelCoreSalesEventsTasksBatch.class.getName() ,
                    'execute:update' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                CancelCoreSalesEventsTasksBatch.class.getName() ,
                'execute' ,
                e
            );
        }
    }
    
    public void finish(Database.BatchableContext bc){
    }

}