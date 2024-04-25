/**  
 * Represents the EventRelationChangeEvent trigger helper which handles all the logic.  
 */  
public class EventRelationChangeEventTriggerHelper {
    // test w/ EventRelationChangeEventHelperTest (91%)
    
    /**
    * Iterates throught the map of new EventRelationChangeEvent and passes the required attributes to other methods.
    * @param newList List of New EventRelationChangeEvent.  
    * @param eventNewMap Map of EventRelationChangeEvent id and EventRelationChangeEvent records.
    * @return void             
    *                
    */
  	
    public void afterInsertDirector(List<EventRelationChangeEvent> newList, Map<Id, EventRelationChangeEvent> eventNewMap) {  
  
        List<EventRelationChangeEvent> createEventList = new List<EventRelationChangeEvent>();
    
        try {  
            if (newList != null) {  
                for (EventRelationChangeEvent event : newList) {
                    EventBus.ChangeEventHeader header = event.ChangeEventHeader;
                    //CREATE
                    if (header.changeType == 'CREATE') {  
                        createEventList.add(event);  
                    }
                }  
            }
  
            if (!createEventList.isEmpty()) {  
                createResourceAbsence(createEventList);
            }
        } catch (Exception ex) {  
            NSP_ErrorLogHandler.logSaveException('NSP_EventRelationTriggerHelper', 'afterInsertDirector', ex.getMessage());  
        }  
    }
    
    /**
	* Method Name : createResourceAbsence 
	* Description : Method to create RAs for attendees events
	* @param List of EventRelationChangeEvent. 
	* @return void  
	*/
  
    private void createResourceAbsence(List<EventRelationChangeEvent> createEventList) {  
  
        List<EventRelationChangeEvent> eventRelList = new List<EventRelationChangeEvent>();  
        Set<Id> eventIdSet = new Set<Id>();  
        Set<Id> userIdSet = new Set<Id>();  
        Map<ID, List<ID>> eventVsRelationIdMap = new Map<ID, List<ID>>();  
        Map<ID, ID> eventRelVsUserMap = new Map<ID, ID>();  
        Map<ID, ID> mapOfServiceResourceMem = new Map<ID, ID>();  
        Map<ID, Event> eventRelVsEventMap = new Map<ID, Event>();  
        List<ResourceAbsence> resList = new List<ResourceAbsence>();  
        String TRAVEL = 'Travel';
        Id NArecordType = Schema.SObjectType.ResourceAbsence.getRecordTypeInfosByDeveloperName().get('Non_Availability')?.getRecordTypeId();
  
        try {  
            if (createEventList != null) {  
                for (EventRelationChangeEvent eventRel : createEventList) {  
                    if (eventRel != null && eventRel.IsInvitee && eventRel.EventId != null && eventRel.RelationId != null && String.valueOf(eventRel.RelationId).startsWith('005')) {
                        eventRelList.add(eventRel);  
                        eventIdSet.add(eventRel.EventId);  
                        userIdSet.add(eventRel.RelationId);  
                        if (!eventVsRelationIdMap.containsKey(eventRel.EventId)) {  
                            eventVsRelationIdMap.put(eventRel.EventId, new List<ID>{ eventRel.Id });  
                        } else {  
                            eventVsRelationIdMap.get(eventRel.EventId).add(eventRel.Id);  
                        }  
                        eventRelVsUserMap.put(eventRel.Id, eventRel.RelationId);  
                    }  
                }  
            }    
  
            // Get all event fields here  
            if (!eventIdSet.isEmpty()) {  
                for (Event eventRec : [SELECT Id, Subject, ShowAs, StartDateTime, EndDateTime, IsRecurrence2 FROM Event WHERE Id IN :eventIdSet AND IsRecurrence2 = false]) {  
                    if (!eventVsRelationIdMap.isEmpty() && eventVsRelationIdMap.containsKey(eventRec.Id)) {  
                        for (ID eachId : eventVsRelationIdMap.get(eventRec.Id)) {  
                            eventRelVsEventMap.put(eachId, eventRec);  
                        }  
                    }  
                }  
            }  
  
            // Confirm attendee is Resource/ Dispatcher+ Resource, if not - no need to create resource absence  
            mapOfServiceResourceMem = isResource(userIdSet);  
  
            if (!eventRelList.isEmpty()) {  
                for (EventRelationChangeEvent eventRel : eventRelList) {  
                    if (!eventRelVsEventMap.isEmpty() && eventRelVsEventMap.containsKey(eventRel.Id)) {  
                        if (!mapOfServiceResourceMem.isEmpty() && mapOfServiceResourceMem.containsKey(eventRelVsUserMap.get(eventRel.Id))) {  
                            Event eventRec = eventRelVsEventMap.get(eventRel.Id);  
                            EventBus.ChangeEventHeader header = eventRel.ChangeEventHeader;
                        	Id actualCreatedByUserId = header.commitUser;
                            ResourceAbsence resObject = new ResourceAbsence();  
                            resObject.ResourceId = mapOfServiceResourceMem.get(eventRelVsUserMap.get(eventRel.Id));  
                            resObject.Type = eventRec.Subject;  
                            if (String.isNotBlank(eventRec.Subject) && eventRec.Subject.toLowerCase().contains(TRAVEL.toLowerCase())) {  
                                resObject.FSL__GanttLabel__c = TRAVEL;  
                            } else {  
                                resObject.FSL__GanttLabel__c = eventRec.ShowAs;  
                            }  
                            resObject.Start = eventRec.StartDateTime;  
                            resObject.End = eventRec.EndDateTime;  
                            resObject.Event_Id__c = eventRec.Id;  
                            resObject.RecordTypeId = NArecordType;
                            resObject.Actual_Created_By__c = actualCreatedByUserId;
                            resList.add(resObject);
                        }  
                    }  
                }  
            }  
  
            if (!resList.isEmpty()) {  
                List<Database.SaveResult> results = Database.insert(resList, false);  
                NSP_ErrorLogHandler.logSaveResult('NSP_EventRelationTriggerHelper', 'createResourceAbsence', results);  
            }  
        } catch (Exception ex) {  
            NSP_ErrorLogHandler.logSaveException('NSP_EventRelationTriggerHelper', 'createResourceAbsence', ex.getMessage());  
        }  
    } 
    
    /**
	* Method Name : isResource 
	* Description : Method to check if User is Resource
	* @param Set of User Id. 
	* @return Map<ID, ID>  
	*/
  
    private Map<ID, ID> isResource(Set<Id> userIdSet) {  
  
        Map<ID, ID> mapOfServiceResourceMem = new Map<ID, ID>();  
  
        if (userIdSet != null) {  
            Map<Id, User> userIdMap = new Map<Id, User>([SELECT Id from user where Id In :userIdSet AND (NSP_Salesforce_Field_Service__c = :NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_RESOURCE OR NSP_Salesforce_Field_Service__c = :NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_DISPATCHER_RESOURCE)]);  
            if (!userIdMap.isEmpty()) {  
                for (ServiceResource serviceResourceMember : [SELECT RelatedRecordId, Id FROM ServiceResource where RelatedRecordId In :userIdMap.KeySet() AND ResourceType = 'T']) {  
                    if (!mapOfServiceResourceMem.containsKey(serviceResourceMember.RelatedRecordId)) {  
                        mapOfServiceResourceMem.put(serviceResourceMember.RelatedRecordId, serviceResourceMember.Id);  
                    }  
                }  
            }  
        }  
        return mapOfServiceResourceMem;  
    }  
}