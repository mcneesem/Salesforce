public with sharing class NSP_EventTriggerHelper {
    // test w/ NSP_EventTriggerHelperTest, LeadLastActivityDateHelperTest (82%)
    // test w/ NSP_EventTriggerHelperTest (81%)
    // test w/ LeadLastActivityDateHelperTest (35%)

    private static final String DISCOVERY_CALL = 'Discovery Call';
    private static final String CLOSING_APPT = 'Closing Appointment';
    private static final String WO_PROPOSAL = 'WO Proposal';
    private static final String WS_PROPOSAL = 'WS Proposal';
    private static final String EMPTY_STRING = '';
    private static final String WORD_SEPARATOR =  ' : ';
    private static Id coreSalesEventRecordType = NSP_GenericRecordType.getRecordTypeId( 'Event' , 'Core_Sales_Event_RT' );
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
            //  ADO-504540
            evt.Creator_Title__c = NSP_EventTriggerHelper.userTitle;
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
        List<DiscoveryCallCompletedEvent__e> dcCompletedEventList = new List<DiscoveryCallCompletedEvent__e>();
        Map<Id,Event> rescheduledEventsMap = new Map<Id,Event>();
        Set<String> subjectSet = new Set<String>();
        if ( eventNewMap != null ) {
            for ( Event newEventRecord : eventNewMap.values() ) {
                if ( ( eventOldMap != null ) && eventOldMap.containsKey( newEventRecord.Id ) ) {
                    Event oldEventRecord = eventOldMap.get(newEventRecord.Id);
                    rescheduledEventsMap = this.processRescheduledEventsMap(
                        newEventRecord ,
                        oldEventRecord ,
                        rescheduledEventsMap
                    );
                    subjectSet = this.processSubjectSet(
                        newEventRecord ,
                        oldEventRecord ,
                        subjectSet
                    );
                    dcCompletedEventList = this.processDCCompleted(
                        newEventRecord ,
                        oldEventRecord ,
                        dcCompletedEventList
                    );
                }
            }
        }
        Map<Id,Event> attendeesEventMap = this.getAttendeesEvent( subjectSet , rescheduledEventsMap );
        if ( !attendeesEventMap.isEmpty() ) {
            rescheduledEventsMap.putAll( attendeesEventMap );
        }
        if ( !rescheduledEventsMap.isEmpty() ) {
            this.updateResourceAbsenceDate( rescheduledEventsMap );
        }
        if ( NSP_EventTriggerHelper.is_Enabled_DCCompletedScreen
            && ( dcCompletedEventList != null )
            && !dcCompletedEventList.isEmpty()
            )
        {
            List<Database.SaveResult> results = EventBus.publish( dcCompletedEventList );
            NSP_ErrorLogHandler.logResults(
                NSP_EventTriggerHelper.class.getName() ,
                'afterUpdateDirector' ,
                results
            );
        }
        this.updateOpportunitiesWithDiscoverCalls( eventNewMap.values() );
        this.updateActivityDate( eventNewMap.values() , eventOldMap );
        this.checkOpportunityStageCriteria( eventNewMap.values() );
    }

    private Set<String> processSubjectSet( Event newEventRecord , Event oldEventRecord , Set<String> subjectSet ) {
        if ( ( subjectSet != null )
            && ( newEventRecord != null )
            && ( newEventRecord.RecordTypeId == NSP_EventTriggerHelper.eventRecordType )
            && ( oldEventRecord != null )
            && ( oldEventRecord.StartDateTime != newEventRecord.StartDateTime || oldEventRecord.EndDateTime != newEventRecord.EndDateTime )
            && ( newEventRecord.WhatId == null && newEventRecord.Type == null )
            && ( newEventRecord.IsRecurrence2 == true || newEventRecord.IsRecurrence == true )
            )
        {
            subjectSet.add(newEventRecord.Subject);
        }
        return subjectSet;
    }

    private Map<Id,Event> processRescheduledEventsMap( Event newEventRecord , Event oldEventRecord , Map<Id,Event> rescheduledEventsMap ) {
        if ( ( rescheduledEventsMap != null )
            && ( newEventRecord != null )
            && ( newEventRecord.RecordTypeId == NSP_EventTriggerHelper.eventRecordType )
            && ( oldEventRecord != null )
            && ( oldEventRecord.StartDateTime != newEventRecord.StartDateTime || oldEventRecord.EndDateTime != newEventRecord.EndDateTime )
            && ( ( newEventRecord.WhatId != null && newEventRecord.FSL__Event_Type__c == 'Resource Absence' ) 
                || ( ( newEventRecord.WhatId == null && newEventRecord.Type == null )
                    && ( newEventRecord.IsRecurrence2 == true || newEventRecord.IsRecurrence == true )
                    )
                )
            )
        {
            rescheduledEventsMap.put(newEventRecord.Id, newEventRecord);
        }
        return rescheduledEventsMap;
    }

    private List<DiscoveryCallCompletedEvent__e> processDCCompleted( Event newEventRecord , Event oldEventRecord , List<DiscoveryCallCompletedEvent__e> dcCompletedEventList ) {
        if ( ( dcCompletedEventList != null )
            && ( newEventRecord != null )
            && String.isNotBlank( newEventRecord.WhatId )
            && ( newEventRecord.NSP_Event_Subtype__c != NULL )
            && ( newEventRecord.WhatId.getSObjectType() == Opportunity.getSObjectType() )
            && newEventRecord.NSP_Event_Subtype__c.equalsIgnoreCase( NSP_EventTriggerHelper.DISCOVERY_CALL )
            && ( oldEventRecord != null && oldEventRecord.NSP_Status__c != newEventRecord.NSP_Status__c )
            && ( newEventRecord.NSP_Status__c == NSP_SalesConstants.DISCOVERY_CALL_COMPLETED )
            )
        {
            DiscoveryCallCompletedEvent__e dcCompletedEvent = new DiscoveryCallCompletedEvent__e();
            dcCompletedEvent.Id__c = newEventRecord.Id;
            dcCompletedEvent.UserId__c = UserInfo.getUserId();
            dcCompletedEvent.WhatId__c = newEventRecord.WhatId;
            dcCompletedEventList.add( dcCompletedEvent );
        }
        return dcCompletedEventList;
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
        if ( NSP_EventTriggerHelper.is_Enabled_WO_WS_Stage_Entry ) {
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

    private static Boolean is_Enabled_WO_WS_Stage_Entry {
        private get {
            if ( is_Enabled_WO_WS_Stage_Entry == null ) {
                is_Enabled_WO_WS_Stage_Entry = OpportunityStageSettings__c.getInstance( UserInfo.getUserId() ).Is_Enabled_WO_WS_Stage_Entry__c;
            }
            return is_Enabled_WO_WS_Stage_Entry;
        }
        private set;
    }

    private static Boolean is_Enabled_DCCompletedScreen {
        private get {
            if ( is_Enabled_DCCompletedScreen == null ) {
                is_Enabled_DCCompletedScreen = OpportunityStageSettings__c.getInstance( UserInfo.getUserId() ).Is_Enabled_DiscoveryCallCompletedScreen__c;
            }
            return is_Enabled_DCCompletedScreen;
        }
        private set;
    }

    private static Id eventRecordType {
        private get {
            if ( eventRecordType == null ) {
                eventRecordType = NSP_GenericRecordType.getRecordTypeId( 'Event' , 'Core_Sales_Event_RT' );
            }
            return eventRecordType;
        }
        private set;
    }
  
    // 
    // Method : getUserTitle
    // Description : Get the current user's job title
    // @param : none
    // @return String
    //
    private static String userTitle {
        private get {
            if ( userTitle == null ) {
                String local = '';
                List<User> records = [
                    SELECT Id , Title
                    FROM User
                    WHERE ( Id = :UserInfo.getUserId() )
                    LIMIT 1
                ];
                if ( ( records != null )
                    && !records.isEmpty()
                    && ( records[0] != null )
                    && String.isNotBlank( records[0].Title )
                    )
                {
                    local = records[0].Title;
                }
                userTitle = local;
            }
            return userTitle;
        }
        private set;
    }
}
//