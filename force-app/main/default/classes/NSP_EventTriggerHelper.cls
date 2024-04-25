/**
* Represents the Event trigger helper which handles all the logic.
*/
public class NSP_EventTriggerHelper {
    // test w/ NSP_EventTriggerHelperTest (88%)
    
    public static String DISCOVERY_CALL = 'Discovery Call';
    private static final String EMPTY_STRING = '';
    private static final String WORD_SEPARATOR =  ' : ';
    /* Iterates throught the list of new Event and passes the required attributes to other methods.
    * @param newList List of New Event.  
    * @return void             
    *                
    */
        public void beforeInsertDirector(List<Event> newList){  
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
     
        /**
    * Iterates throught the map of new Event and passes the required attributes to other methods.
    * @param newList List of New Event.  
    * @param eventNewMap Map of Event id and Event records.
    * @return void             
    *                
    */
        
        public void afterInsertDirector(List<Event> newList, Map<Id, Event> eventNewMap){ 

            updateOpportunitiesWithDiscoverCalls(newList);
            updateActivityDate(newList,null);  
        }
        
        /**
    * Iterates throught the Event map and identifies the records that needs to worked based on various criterias.
    * @param eventNewMap Map of New Event. 
    * @param eventOldMap Map of Old Event. 
    * @return void             
    *                
    */
        
        public void beforeUpdateDirector(Map<Id, Event> eventNewMap, Map<Id, Event> eventOldMap){
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

    //
    // Iterates throught the list of new Events and passes the required attributes to other methods.
    // @param eventNewMap Map of New Event.
    // @param eventOldMap Map of Old Event.
    // @return void
    //
    public void afterUpdateDirector(Map<Id, Event> eventNewMap, Map<Id, Event> eventOldMap){
        Map<Id,Event> rescheduledEventsMap = new Map<Id,Event>();
        Set<String> subjectSet = new Set<String>();  
    	Id eventRecordType = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Core_Sales_Event_RT')?.getRecordTypeId();
        String RESOURCE_ABSENCE = 'Resource Absence';
            
        if(eventNewMap != null){
            for (Event newEventRecord : eventNewMap.Values()){
                if( ( eventOldMap != null ) && eventOldMap.containsKey( newEventRecord.Id ) ){
                    Event oldEventRecord = eventOldMap.get(newEventRecord.Id);
                    if (newEventRecord.RecordTypeId == eventRecordType
                		&& newEventRecord.WhatId != null && newEventRecord.FSL__Event_Type__c == RESOURCE_ABSENCE
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
        updateOpportunitiesWithDiscoverCalls(eventNewMap.values());
        updateActivityDate(eventNewMap.values(),eventOldMap);
    }

    //
    // Method Name : updateResourceAbsenceDate 
    // Description : Method to update start and end date on RAs for recurring events
    // @param Map of Event. 
    // @return void  
    //
    private void updateResourceAbsenceDate(Map<Id,Event> rescheduledEventsMap){
        List<ResourceAbsence> resourceAbsenceList = new List<ResourceAbsence>();
        List<ResourceAbsence> resourceAbsenceToUpdateList = new List<ResourceAbsence>();
        try{
            if (rescheduledEventsMap.size() > 0){
                resourceAbsenceList = [
                    SELECT ID, Start, End, Event_Id__c
                    FROM ResourceAbsence
                    WHERE Event_Id__c IN: rescheduledEventsMap.keySet()
                ];
            }
            if (resourceAbsenceList.size() > 0){
                for (ResourceAbsence eachRA : resourceAbsenceList){
                    if ( rescheduledEventsMap.containsKey( eachRA.Event_Id__c ) ) {
                        Event record = rescheduledEventsMap.get( eachRA.Event_Id__c );
                        if ( record != null ) {
                            eachRA.Start = record.StartDateTime;
                            eachRA.End = record.EndDateTime;
                            resourceAbsenceToUpdateList.add(eachRA);
                        }
                    }
                }
            }
            if (resourceAbsenceToUpdateList.size() > 0){
                Update resourceAbsenceToUpdateList;
            }
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_EventTriggerHelper', 'updateResourceAbsenceDate', ex.getMessage());
        }
    }

    /**
    * Iterates throught the list of old Events and map of old Events and passes the required attributes to other methods.
    * @param eventOldList List of Old Event.
    * @param eventOldMap Map of Old Event.
    * @return void
    */
    public void beforeDeleteDirector(List<Event> eventOldList, Map<Id, Event> eventOldMap) {
        Set<String> subjectSet = new Set<String>();
        Map<Id, Event> recurringEvents = new Map<Id,Event>();
        Id eventRecordType = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Core_Sales_Event_RT')?.getRecordTypeId();
        try {
            if (eventOldMap != null) {
                for (Event eachEvent : eventOldMap.values()) {
                    if ( ( eachEvent.RecordTypeId == eventRecordType )
                        && ( eachEvent.WhatId == NULL && eachEvent.Type == NULL )
                        && ( eachEvent.IsRecurrence2 == TRUE || eachEvent.IsRecurrence == TRUE )
                        )
                    {
                        subjectSet.add(eachEvent.Subject);  
                        recurringEvents.put(eachEvent.Id, eachEvent);  
                    }
                }
            }
            Map<Id, Event> attendeesEventMap = getAttendeesEvent(subjectSet,recurringEvents);
            if (attendeesEventMap != null && attendeesEventMap.size() > 0) {
                deleteResourceAbsence(attendeesEventMap);
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_EventTriggerHelper', 'beforeDeleteDirector', ex.getMessage());
        }
    }

    /**
    * Method Name : getAttendeesEvent
    * Description : Method to update start and end date on RAs for recurring events
    * @param newList Map of Event.
    * @return Map of ResourceAbsence
    */
    private Map<Id, Event> getAttendeesEvent(Set<String> subjectSet,Map<Id, Event> recurringEvents){
        List<Event> eventWithSameSubject = new List<Event>();
        Map<Id, ResourceAbsence> childResourceAbsenceMap = new Map<Id, ResourceAbsence>();
        String DISPATCHER_RESOURCE = 'Dispatcher + Resource';
        String RESOURCE = 'Resource';
        Map<Id,Event> attendeesEventMap = new Map<Id,Event>();
        Id eventRecordType = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Core_Sales_Event_RT')?.getRecordTypeId();
        if (subjectSet != null && subjectSet.size() > 0){
            eventWithSameSubject = [
                SELECT Id, Subject, StartDateTime, EndDateTime, ShowAs, Description, CreatedById, Location
                FROM Event
                WHERE (
                    Subject IN :subjectSet
                    AND IsChild = TRUE
                    AND (CreatedBy.NSP_Salesforce_Field_Service__c = :DISPATCHER_RESOURCE OR CreatedBy.NSP_Salesforce_Field_Service__c = :RESOURCE)
                    AND RecordTypeId = :eventRecordType
                    AND WhatId = NULL
                    AND Type = NULL
                    AND (IsRecurrence2 = TRUE OR IsRecurrence = TRUE)
                )
            ];
        }
        if (recurringEvents != null && recurringEvents.size() > 0){
            for (Event eachEvent : recurringEvents.values()) {
                Set<String> eventAttributes = new Set<String>{
                    eachEvent.Subject, eachEvent.ShowAs, eachEvent.Description, eachEvent.Location
                };
                Set<Datetime> eventDateAttributes = new Set<Datetime>{
                    eachEvent.StartDateTime, eachEvent.EndDateTime
                };
                for (Event childEvent : eventWithSameSubject) {
                    if (eventAttributes.contains(childEvent.Subject)
                        && eventDateAttributes.contains(childEvent.StartDateTime)
                        && eventDateAttributes.contains(childEvent.EndDateTime)
                        && eventAttributes.contains(childEvent.ShowAs)
                        && eventAttributes.contains(childEvent.Description)
                        && eventAttributes.contains(childEvent.Location)
                        )
                    {  
                        attendeesEventMap.put(childEvent.Id,childEvent);
                    }
                }
            }
        }
        return attendeesEventMap;
    }

    /**
    * Iterates throught the list of old Events and passes the required attributes to other methods.
    * @param eventOldList List of Old Event.
    * @param eventOldMap Map of Old Event.
    * @return void
    */
    public void afterDeleteDirector(List<Event> eventOldList,Map<Id, Event> eventOldMap){
        try{
            if (eventOldMap != null && eventOldMap.size() > 0){
                deleteResourceAbsence(eventOldMap);
            }
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_EventTriggerHelper', 'afterDeleteDirector', ex.getMessage());
        }
    }

    /**
    * Method to deleted Resource Absences.
    * @param eventMap Map of Event.
    * @return void
    */
    private void deleteResourceAbsence(Map<Id, Event> eventMap){
        List<ResourceAbsence> resourceAbsenceList = new List<ResourceAbsence>();
        try{
            if (eventMap != null && eventMap.size() > 0){
                resourceAbsenceList = [SELECT ID,Event_Id__c From ResourceAbsence WHERE Event_Id__c IN: eventMap.keySet()];
            }
            if (resourceAbsenceList.size() > 0){
                Delete resourceAbsenceList;
            }
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_EventTriggerHelper', 'deleteResourceAbsence', ex.getMessage());
        }
    }

    public void updateOpportunitiesWithDiscoverCalls(List<Event> newList) {

        Set<ID> updateOpportunityIDList = new Set<ID>();
        List<Opportunity> updateOpportunityList = new List<Opportunity>();
        try{
            String opportunity_prefix = Schema.SObjectType.Opportunity.getKeyPrefix();

            for(Event event : newList){
                if(event != NULL && event.WhatId != NULL && event.NSP_Event_Subtype__c != NULL){
                    if(event.NSP_Event_Subtype__c.equalsIgnoreCase(DISCOVERY_CALL) && 
                       ((String)event.WhatId).startsWith(opportunity_prefix)){
                        updateOpportunityIDList.add(event.WhatId);
                    }           
                }  
            }
            List<Opportunity> listOpportunity = [SELECT ID, NSP_Ready_for_Integration_Sync__c FROM Opportunity 
                                                 WHERE ID IN: updateOpportunityIDList]; //Capitalized WHERE Condition as part of code fix
            for(Opportunity oppty : listOpportunity){
                Opportunity opp = new Opportunity();
                opp.Id = oppty.Id;
                opp.NSP_Ready_for_Integration_Sync__c = true;
                updateOpportunityList.add(opp);
            }
            if(!updateOpportunityList.isEmpty()){
                Database.update(updateOpportunityList);
            }
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_EventTriggerHelper', 'updateOpportunitiesWithDiscoverCalls', ex.getMessage());
        }  
    }
  /**
* Method Name : updateActivityDate 
* Description : Method to update last activity date on all related leads with same DUNS.
* Date : 31/03/2021
* @param newList List of New Event. 
* @param eventOldMap Map of Old Event.   
* @return void  
*/
        public void updateActivityDate(List<Event> newList,Map<Id,Event> eventOldMap){
            Set < Id > leadIdSet = new Set < Id > ();
            List < Lead > leadResult = new List<Lead> ();
            List < Lead > leadWithDuns = new List<Lead> ();
            Map < String, Date > lastActivityDateMap = new Map < String, Date > ();
            List < Lead > leadToUpdate = new List<Lead> ();
            for(Event event : newList){
                Event oldEvent = eventOldMap != null ? eventOldMap.get(event.Id):null;
                if((Trigger.isInsert || event.StartDateTime != oldEvent.StartDateTime) && event.StartDateTime != null && event.WhoId!= null){
                leadIdSet.add(event.WhoId);
            }
            }
            if(!leadIdSet.isEmpty()){
                leadResult = [SELECT Id, Salutation, FirstName, MiddleName, LastName, NSP_Parent_Lead__c, DNB_Connect_DUNS_Number__c,LastActivityDate FROM Lead WHERE Id IN: leadIdSet];
                if(!leadResult.isEmpty()) {
                    for(Lead leadObj :leadResult){
                        if(leadObj.LastActivityDate != null && leadObj.DNB_Connect_DUNS_Number__c !=null) {
                            lastActivityDateMap.put(leadObj.DNB_Connect_DUNS_Number__c,leadObj.LastActivityDate);
                        }
                    }
                    if(!lastActivityDateMap.isEmpty()) {
                        leadWithDuns = [SELECT Id, Salutation, FirstName, NSP_Last_Activity__c, LastName, NSP_Parent_Lead__c, DNB_Connect_DUNS_Number__c,LastActivityDate FROM Lead WHERE DNB_Connect_DUNS_Number__c IN: lastActivityDateMap.keySet()];
                        Lead lastActive = [SELECT LastActivityDate FROM Lead WHERE DNB_Connect_DUNS_Number__c IN: lastActivityDateMap.keySet() AND LastActivityDate != null ORDER BY LastActivityDate DESC LIMIT 1];
                        if(!leadWithDuns.isEmpty()){
                            for(Lead leadObject : leadWithDuns){
                                 leadObject.NSP_Last_Activity__c = lastActive.LastActivityDate;
                                 leadToUpdate.add(leadObject);
                               }
                        }
                    }
                }
            }
            try{
                if(!leadToUpdate.isEmpty()){
                    update leadToUpdate;
                }
            }
            catch(Exception ex){
                NSP_ErrorLogHandler.logSaveException('NSP_EventTriggerHelper', 'updateActivityDate', ex.getMessage());
            }
        }
    
/**
* Method Name : updateEventSales 
* Description : Method to update sales region, sales devison and sales office.
* Date : 08/12/2022
* @param newList List of New Event. 
* @param OldEventMap Map of Old Event.   
* @return void  
*/

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
     
    /**
* Method Name : populateWhatAndWhoNamesEvent 
* Description : Method to update NSP_What_Name__c and/or NSP_Who_Name__c on Event Object
* Date : 25/05/2023
* @param newEventList List of new Events 
* @return void  
*/
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
    
    private Map<Id, String> getRelatedRecordDetails(String objectName, String fieldName, Set<String> recordIds, String objectLabel) {
        Map<Id, String> relatedRecordDetailsMap = new Map<Id, String>();
        List<String> fieldList = new List<String>{fieldName};
        NSP_sObjectSelector sObjectSelector = new NSP_sObjectSelector(objectName, fieldList);
        for(sObject record: sObjectSelector.selectById(new List<String>(recordIds))) {
            relatedRecordDetailsMap.put(record.Id, objectLabel + WORD_SEPARATOR + record.get(fieldName));
        }
        return relatedRecordDetailsMap;
    }
    
    }