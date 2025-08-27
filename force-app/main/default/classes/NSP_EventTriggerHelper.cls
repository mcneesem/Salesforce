public with sharing class NSP_EventTriggerHelper {
    // test w/ NSP_EventTriggerHelperTest, LeadLastActivityDateHelperTest (82%)
    // test w/ NSP_EventTriggerHelperTest (82%)
    // test w/ LeadLastActivityDateHelperTest (35%)

    private static final String DISCOVERY_CALL = 'Discovery Call';
    private static final String CLOSING_APPT = 'Closing Appointment';
    private static final String WO_PROPOSAL = 'WO Proposal';
    private static final String WS_PROPOSAL = 'WS Proposal';
    private static final String EMPTY_STRING = '';
    private static final String WORD_SEPARATOR =  ' : ';
    private static Id coreSalesEventRecordType = NSP_GenericRecordType.getRecordTypeId( 'Event' , 'Core_Sales_Event_RT' );
    private static Boolean Is_Enabled_WO_WS_Stage_Entry = OpportunityStageSettings__c.getInstance( UserInfo.getUserId() ).Is_Enabled_WO_WS_Stage_Entry__c;

    // Iterates throught the list of new Event and passes the required attributes to other methods.
    // @param newList List of New Event.  
    // @return void
    public void beforeInsertDirector(List<Event> newList) {
        List<Event> eventList = new List<Event>();
        for(Event evt : newList){
            evt.NSP_Last_Assigned_Owner__c = evt.OwnerId; // Added as part of STY-01774
            //Added as part of STY-03437
            if(evt.WhatId != null || evt.WhoId != null){
                eventList.add(evt);
            }
        }
        updateEventSales(newList,null);
        if(!eventList.isEmpty()){
            populateWhatAndWhoNamesEvent(eventList);//Update of NSP_What_Name__c and NSP_Who_Name__c before Insert
        }
    }

    // Iterates throught the map of new Event and passes the required attributes to other methods.
    // @param newList List of New Event.  
    // @param eventNewMap Map of Event id and Event records.
    // @return void
    public void afterInsertDirector(List<Event> newList, Map<Id,Event> eventNewMap) {
        updateOpportunitiesWithDiscoverCalls(newList);
        updateActivityDate(newList,null);
        checkOpportunityStageCriteria(newList);
    }

    // Iterates throught the Event map and identifies the records that needs to worked based on various criterias.
    // @param eventNewMap Map of New Event. 
    // @param eventOldMap Map of Old Event. 
    // @return void
    public void beforeUpdateDirector(Map<Id,Event> eventNewMap, Map<Id,Event> eventOldMap) {
        updateEventSales(eventNewMap.values(),eventOldMap);
        //Added as part of STY-03437
        List<Event> eligibleEvents = new List<Event>();
        for(Event newEventRecord : eventNewMap.values()) {
            Event oldEventRecord = eventOldMap.get(newEventRecord.Id);
            if(oldEventRecord.WhatId != newEventRecord.WhatId || oldEventRecord.WhoId != newEventRecord.WhoId) {
                eligibleEvents.add(newEventRecord);
            }
        }
        if(!eligibleEvents.isEmpty()) {
            populateWhatAndWhoNamesEvent(eligibleEvents);//Update of NSP_What_Name__c and NSP_Who_Name__c before Update
        }
    }

    // Iterates throught the list of new Events and passes the required attributes to other methods.
    // @param eventNewMap Map of New Event.
    // @param eventOldMap Map of Old Event.
    // @return void
    public void afterUpdateDirector( Map<Id,Event> eventNewMap , Map<Id,Event> eventOldMap ) {
        List < DiscoveryCallCompletedEvent__e > dcCompletedEventList = New List < DiscoveryCallCompletedEvent__e > ();
        Map<Id,Event> rescheduledEventsMap = new Map<Id,Event>();
        Set<String> subjectSet = new Set<String>();  
        Id eventRecordType = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Core_Sales_Event_RT')?.getRecordTypeId();
        if(eventNewMap != null){
            for (Event newEventRecord : eventNewMap.Values()){
                if ( ( eventOldMap != null ) && eventOldMap.containsKey( newEventRecord.Id ) ) {
                    Event oldEventRecord = eventOldMap.get(newEventRecord.Id);
                    if (newEventRecord.RecordTypeId == eventRecordType
                        && newEventRecord.WhatId != null && newEventRecord.FSL__Event_Type__c == 'Resource Absence'
                        && oldEventRecord != null && (oldEventRecord.StartDateTime != newEventRecord.StartDateTime || oldEventRecord.EndDateTime != newEventRecord.EndDateTime)
                        )
                    {
                        rescheduledEventsMap.put(newEventRecord.Id, newEventRecord);
                    }
                    if ( ( newEventRecord.IsRecurrence2 == TRUE || newEventRecord.IsRecurrence == TRUE )
                        && newEventRecord.RecordTypeId == eventRecordType
                        && newEventRecord.WhatId == NULL && newEventRecord.Type == NULL
                        && ( oldEventRecord != null )
                        && ( oldEventRecord.StartDateTime != newEventRecord.StartDateTime || oldEventRecord.EndDateTime != newEventRecord.EndDateTime )
                        )
                    {
                        rescheduledEventsMap.put(newEventRecord.Id, newEventRecord);
                        subjectSet.add(newEventRecord.Subject);  
                    }

                    if ( ( String.isNotBlank(newEventRecord.WhatId) )
                        && ( newEventRecord.NSP_Event_Subtype__c != NULL )
                        && ( newEventRecord.WhatId.getSObjectType() == Opportunity.getSObjectType() )
                        && ( newEventRecord.NSP_Event_Subtype__c.equalsIgnoreCase( NSP_EventTriggerHelper.DISCOVERY_CALL ) )
                        && ( oldEventRecord != null && oldEventRecord.NSP_Status__c != newEventRecord.NSP_Status__c )
                        && ( newEventRecord.NSP_Status__c == NSP_SalesConstants.DISCOVERY_CALL_COMPLETED ) )
                    {
                        DiscoveryCallCompletedEvent__e dcCompletedEvent = new DiscoveryCallCompletedEvent__e();
                        dcCompletedEvent.Id__c = newEventRecord.Id;
                        dcCompletedEvent.UserId__c = UserInfo.getUserId();
                        dcCompletedEvent.WhatId__c = newEventRecord.WhatId;
                        dcCompletedEventList.add( dcCompletedEvent );
                    }
                }
            }
        }
        Map<Id, Event> attendeesEventMap = getAttendeesEvent(subjectSet,rescheduledEventsMap);
        if (!attendeesEventMap.isEmpty()){
            rescheduledEventsMap.putAll(attendeesEventMap);
        }
        if (rescheduledEventsMap.size() > 0){
            updateResourceAbsenceDate(rescheduledEventsMap);
        }
        if( !dcCompletedEventList.isEmpty() ) {
            List<Database.SaveResult> results = EventBus.publish(dcCompletedEventList);
            NSP_ErrorLogHandler.logSaveResult('NSP_EventTriggerHelper', 'afterUpdateDirector', results);
        }
        updateOpportunitiesWithDiscoverCalls(eventNewMap.values());
        updateActivityDate(eventNewMap.values(),eventOldMap);
        checkOpportunityStageCriteria(eventNewMap.values());
    }

    //
    // Method Name : updateResourceAbsenceDate 
    // Description : Method to update start and end date on RAs for recurring events
    // @param Map of Event. 
    // @return void  
    //
    private void updateResourceAbsenceDate( Map<Id,Event> rescheduledEventsMap ) {
        try {
            List<ResourceAbsence> resourceAbsenceList = new List<ResourceAbsence>();
            if ( !rescheduledEventsMap.isEmpty() ) {
                resourceAbsenceList = [
                    SELECT Id , Start , End, Event_Id__c
                    FROM ResourceAbsence
                    WHERE ( Event_Id__c IN :rescheduledEventsMap.keySet() )
                ];
            }
            List<ResourceAbsence> resourceAbsenceToUpdateList = new List<ResourceAbsence>();
            if ( !resourceAbsenceList.isEmpty() ) {
                for ( ResourceAbsence eachRA : resourceAbsenceList ) {
                    if ( rescheduledEventsMap.containsKey( eachRA.Event_Id__c ) ) {
                        Event record = rescheduledEventsMap.get( eachRA.Event_Id__c );
                        if ( record != null ) {
                            eachRA.Start = record.StartDateTime;
                            eachRA.End = record.EndDateTime;
                            resourceAbsenceToUpdateList.add( eachRA );
                        }
                    }
                }
            }
            if ( !resourceAbsenceToUpdateList.isEmpty() ) {
                Update resourceAbsenceToUpdateList;
            }
        } catch ( Exception e ) {
            NSP_EventTriggerHelper.handleException( e , 'updateResourceAbsenceDate' );
        }
    }

    //
    // Iterates throught the list of old Events and map of old Events and passes the required attributes to other methods.
    // @param eventOldList List of Old Event.
    // @param eventOldMap Map of Old Event.
    // @return void
    //
    public void beforeDeleteDirector( List<Event> eventOldList , Map<Id,Event> eventOldMap ) {
        Set<String> subjectSet = new Set<String>();
        Map<Id,Event> recurringEvents = new Map<Id,Event>();
        try {
            if ( eventOldMap != null ) {
                for ( Event eachEvent : eventOldMap.values() ) {
                    if ( ( eachEvent.RecordTypeId == NSP_EventTriggerHelper.coreSalesEventRecordType )
                        && ( eachEvent.WhatId == null )
                        && ( eachEvent.Type == null )
                        && ( eachEvent.IsRecurrence2 == true || eachEvent.IsRecurrence == true )
                        )
                    {
                        subjectSet.add( eachEvent.Subject );
                        recurringEvents.put( eachEvent.Id , eachEvent );
                    }
                }
            }
            Map<Id,Event> attendeesEventMap = getAttendeesEvent( subjectSet , recurringEvents );
            if ( ( attendeesEventMap != null ) && !attendeesEventMap.isEmpty() ) {
                deleteResourceAbsence( attendeesEventMap );
            }
        } catch ( Exception e ) {
            NSP_EventTriggerHelper.handleException( e , 'beforeDeleteDirector' );
        }
    }

    //
    // Method Name : getAttendeesEvent
    // Description : Method to update start and end date on RAs for recurring events
    // @param newList Map of Event.
    // @return Map of ResourceAbsence
    //
    private Map<Id, Event> getAttendeesEvent( Set<String> subjectSet , Map<Id,Event> recurringEvents ) {
        List<Event> eventWithSameSubject = new List<Event>();
        if ( ( subjectSet != null ) && !subjectSet.isEmpty() ) {
            eventWithSameSubject = [
                SELECT Id , Subject , StartDateTime , EndDateTime , ShowAs , Description , CreatedById , Location
                FROM Event
                WHERE (
                    ( Subject IN :subjectSet )
                    AND ( IsChild = true )
                    AND (
                        ( CreatedBy.NSP_Salesforce_Field_Service__c = 'Dispatcher + Resource' )
                        OR ( CreatedBy.NSP_Salesforce_Field_Service__c = 'Resource' )
                    )
                    AND ( RecordTypeId = :NSP_EventTriggerHelper.coreSalesEventRecordType )
                    AND ( WhatId = null )
                    AND ( Type = null )
                    AND (
                        ( IsRecurrence2 = true )
                        OR ( IsRecurrence = true )
                    )
                )
            ];
        }
        Map<Id,Event> attendeesEventMap = new Map<Id,Event>();
        if ( ( recurringEvents != null ) && !recurringEvents.isEmpty() ) {
            for ( Event eachEvent : recurringEvents.values() ) {
                Set<String> eventAttributes = new Set<String>{
                    eachEvent.Subject ,
                    eachEvent.ShowAs ,
                    eachEvent.Description ,
                    eachEvent.Location
                };
                Set<Datetime> eventDateAttributes = new Set<Datetime>{
                    eachEvent.StartDateTime ,
                    eachEvent.EndDateTime
                };
                for ( Event childEvent : eventWithSameSubject ) {
                    if ( eventAttributes.contains( childEvent.Subject )
                        && eventDateAttributes.contains( childEvent.StartDateTime )
                        && eventDateAttributes.contains( childEvent.EndDateTime )
                        && eventAttributes.contains( childEvent.ShowAs )
                        && eventAttributes.contains( childEvent.Description )
                        && eventAttributes.contains( childEvent.Location )
                        )
                    {
                        attendeesEventMap.put( childEvent.Id , childEvent );
                    }
                }
            }
        }
        return attendeesEventMap;
    }

    //
    // Iterates throught the list of old Events and passes the required attributes to other methods.
    // @param eventOldList List of Old Event.
    // @param eventOldMap Map of Old Event.
    // @return void
    //
    public void afterDeleteDirector( List<Event> eventOldList , Map<Id,Event> eventOldMap ) {
        try {
            if ( ( eventOldMap != null ) && !eventOldMap.isEmpty() ) {
                deleteResourceAbsence( eventOldMap );
            }
        } catch ( Exception e ) {
            NSP_EventTriggerHelper.handleException( e , 'afterDeleteDirector' );
        }
    }

    //
    // Method to deleted Resource Absences.
    // @param eventMap Map of Event.
    // @return void
    //
    private void deleteResourceAbsence( Map<Id,Event> eventMap ) {
        try {
            List<ResourceAbsence> resourceAbsenceList = new List<ResourceAbsence>();
            if ( ( eventMap != null ) && !eventMap.isEmpty() ) {
                resourceAbsenceList = [
                    SELECT Id , Event_Id__c
                    FROM ResourceAbsence
                    WHERE ( Event_Id__c IN :eventMap.keySet() )
                ];
            }
            if ( !resourceAbsenceList.isEmpty() ) {
                delete resourceAbsenceList;
            }
        } catch ( Exception e ) {
            NSP_EventTriggerHelper.handleException( e , 'deleteResourceAbsence' );
        }
    }

    private void updateOpportunitiesWithDiscoverCalls( List<Event> newList ) {
        try {
            Set<Id> updateOpportunityIDList = new Set<Id>();
            for ( Event event : newList ) {
                if ( ( event != null )
                    && ( event.WhatId != null )
                    && ( event.NSP_Event_Subtype__c != null )
                    && event.NSP_Event_Subtype__c.equalsIgnoreCase( NSP_EventTriggerHelper.DISCOVERY_CALL )
                    && ( event.WhatId.getSObjectType() == Opportunity.getSObjectType() )
                    )
                {
                    updateOpportunityIDList.add(event.WhatId);
                }
            }
            List<Opportunity> listOpportunity = [
                SELECT Id , NSP_Ready_for_Integration_Sync__c
                FROM Opportunity 
                WHERE ( Id IN :updateOpportunityIDList )
            ];
            List<Opportunity> updateOpportunityList = new List<Opportunity>();
            for ( Opportunity oppty : listOpportunity ) {
                Opportunity opp = new Opportunity();
                opp.Id = oppty.Id;
                opp.NSP_Ready_for_Integration_Sync__c = true;
                updateOpportunityList.add( opp );
            }
            if ( !updateOpportunityList.isEmpty() ) {
                Database.update( updateOpportunityList );
            }
        } catch ( Exception e ) {
            NSP_EventTriggerHelper.handleException( e , 'updateOpportunitiesWithDiscoverCalls' );
        }
    }

    public void checkOpportunityStageCriteria( List<Event> newList ) {
        List<Id> updateOpportunityIds = new List<Id>();
        if ( NSP_EventTriggerHelper.Is_Enabled_WO_WS_Stage_Entry ) {
            for ( Event event : newList ) {
                if ( event != NULL
                    && event.WhatId != NULL
                    && event.NSP_Event_Subtype__c != NULL
                    && ( event.WhatId.getSObjectType() == Opportunity.getSObjectType() )
                    && ( event.NSP_Event_Subtype__c.equalsIgnoreCase( NSP_EventTriggerHelper.DISCOVERY_CALL )
                         || event.NSP_Event_Subtype__c.equalsIgnoreCase( NSP_EventTriggerHelper.WO_PROPOSAL )
                         || event.NSP_Event_Subtype__c.equalsIgnoreCase( NSP_EventTriggerHelper.WS_PROPOSAL )
                         || event.NSP_Event_Subtype__c.equalsIgnoreCase( NSP_EventTriggerHelper.CLOSING_APPT )
                       )
                    )
                {
                    updateOpportunityIds.add( event.WhatId );
                }
            }
            AutomateOpportunityStage.automateOpportunityStageAsync( updateOpportunityIds );
        }
    }

    // Method Name : updateActivityDate
    // Description : Method to update last activity date on all related leads with same DUNS.
    // Date : 31/03/2021
    // @param newList List of New Event.
    // @param eventOldMap Map of Old Event.
    // @return void
    public void updateActivityDate( List<Event> newList , Map<Id,Event> oldMap ) {
        try {
            Set<Id> whoIds = new Set<Id>();
            for ( Event record : newList ) {
                Event oldRecord = null;
                if ( oldMap != null ) {
                    oldRecord = oldMap.get( record.Id );
                }
                if ( ( ( oldRecord == null ) || ( record.StartDateTime != oldRecord.StartDateTime ) )
                    && ( record.StartDateTime != null )
                    && ( record.WhoId != null )
                    )
                {
                    whoIds.add( record.WhoId );
                }
            }
            LeadLastActivityDateHelper.updateLeadLastActivityDate( whoIds );
        } catch ( Exception e ) {
            NSP_EventTriggerHelper.handleException( e , 'updateActivityDate' );
        }
    }

    // Method Name : updateEventSales
    // Description : Method to update sales region, sales devison and sales office.
    // Date : 08/12/2022
    // @param newList List of New Event.
    // @param OldEventMap Map of Old Event.
    // @return void
    public void updateEventSales(List<Event> newList,Map<Id,Event> OldEventMap){
    set<Id> ownerIdSet = new set<Id>();
    for(Event newEvent : newList){
        Event oldEvent = OldEventMap != null ? OldEventMap.get(newEvent.Id):null;
        
        if(Trigger.isInsert || newEvent.OwnerId != oldEvent.OwnerId ){
            ownerIdSet.add(newEvent.ownerId);    
        }
    }

    if(ownerIdSet.Size() > 0){
        Map<Id,User> userIdMap = new Map<Id,User>([SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c from user WHERE Id In :ownerIdSet AND NSP_Sales_Office__c != null ]);
        
        for(Event newEvent : newList){
            Event oldEvent = OldEventMap != null ? OldEventMap.get(newEvent.Id):null;
            
            if((Trigger.isInsert || newEvent.OwnerId != oldEvent.OwnerId) && userIdMap.containsKey(newEvent.ownerId) ){
                user eachUser = userIdMap.get(newEvent.OwnerId);
                newEvent.NSP_Sales_Region__c = eachUser.NSP_SalesRegion__c;  // sales region
                newEvent.NSP_Sales_Division__c = eachUser.NSP_SalesDivision__c; // sales division
                newEvent.NSP_Sales_Office__c = eachUser.NSP_Sales_Office__c; // sales office
            }
        }    
    }
  }  

    // Method Name : populateWhatAndWhoNamesEvent
    // Description : Method to update NSP_What_Name__c and/or NSP_Who_Name__c on Event Object
    // Date : 25/05/2023
    // @param newEventList List of new Events
    // @return void
    private void populateWhatAndWhoNamesEvent(List<Event> newEventList) {
        List<String> fieldApiNamesList = new List<String>{ 'WhatId', 'WhoId' };
            Map<String, Set<String>> targetRecordIdsByObjectApiNameMap = new Map<String, Set<String>>();
        
        //Code to populate What and Who records by their Object Type
        for(Event taskToBeUpdateRecord : newEventList) {
            for(String fieldApiName : fieldApiNamesList) {
                Id targetRecordId = (Id)taskToBeUpdateRecord.get(fieldApiName);
                if(String.isNotBlank(targetRecordId)) {
                    String whatObjectName = String.valueOf(targetRecordId.getSObjectType());
                    if(!targetRecordIdsByObjectApiNameMap.containsKey(whatObjectName)) {
                        targetRecordIdsByObjectApiNameMap.put(whatObjectName, new Set<String>());
                    }
                    targetRecordIdsByObjectApiNameMap.get(whatObjectName).add(targetRecordId);
                }
            }
        }
        
        //Code to fetch target object details (Id, Name) using dynamic SOQL query.
        Map<Id, String> targetRelatedObjectsMap = new Map<Id, String>();
        List<Schema.DescribeSObjectResult> describeSObjectResults = Schema.describeSObjects(new List<String>(targetRecordIdsByObjectApiNameMap.keySet()));
        Map<String, String> objectApiNameLabelMap = new Map<String, String>();
        for(Schema.DescribeSObjectResult sObjResult : describeSObjectResults){
            objectApiNameLabelMap.put(sObjResult.getName(), sObjResult.getLabel());
        }
        Map<String, String> fieldNameByObjectMap = new Map<String, String>{'Case' => 'CaseNumber', 'ServiceAppointment' => 'AppointmentNumber',
                                                                                       'ResourceAbsence' => 'AbsenceNumber'};
        for(String objectApiName : targetRecordIdsByObjectApiNameMap.keySet()) {
                String targetFieldApiName = fieldNameByObjectMap.containsKey(objectApiName) ? fieldNameByObjectMap.get(objectApiName) : 'Name';
                Map<Id, String> relatedRecordDetailsMap = getRelatedRecordDetails(objectApiName,
                                                                                 targetFieldApiName,
                                                                                 targetRecordIdsByObjectApiNameMap.get(objectApiName),
                                                                                 objectApiNameLabelMap.get(objectApiName));
            targetRelatedObjectsMap.putAll(relatedRecordDetailsMap);
        }
        
        for(Event eventToBeUpdateRecord : newEventList) {
            eventToBeUpdateRecord.NSP_What_Name__c = String.isNotBlank(eventToBeUpdateRecord.WhatId) ? targetRelatedObjectsMap.get(eventToBeUpdateRecord.WhatId) : EMPTY_STRING;
            eventToBeUpdateRecord.NSP_Who_Name__c  = String.isNotBlank(eventToBeUpdateRecord.WhoId) ? targetRelatedObjectsMap.get(eventToBeUpdateRecord.WhoId) : EMPTY_STRING;
        }
    }

    private Map<Id,String> getRelatedRecordDetails(
        String objectName ,
        String fieldName ,
        Set<String> recordIds ,
        String objectLabel
        )
    {
        Map<Id,String> relatedRecordDetailsMap = new Map<Id,String>();
        List<String> fieldList = new List<String>{ fieldName };
        NSP_sObjectSelector sObjectSelector = new NSP_sObjectSelector( objectName , fieldList );
        for ( sObject record : sObjectSelector.selectById( new List<String>( recordIds ) ) ) {
            relatedRecordDetailsMap.put(
                record.Id ,
                objectLabel + WORD_SEPARATOR + record.get( fieldName )
            );
        }
        return relatedRecordDetailsMap;
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_EventTriggerHelper.handleException( e , methodName );
        }
    }
    
    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_EventTriggerHelper.class.getName() ,
            methodName ,
            e
        );
    }

}
//