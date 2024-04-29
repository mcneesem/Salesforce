// Represents the Event trigger handler.
public class EventRelationChangeEventTriggerHandler implements NSP_ITriggerHandler {
    // test w/ EventRelationChangeEventHelperTest (100%)

    //Use this variable to disable this trigger from transaction
    public static Boolean TriggerDisabled = false;

    // Represents whether the trigger is disabled or not
    // @param N/A.
    // @return Boolean
    public Boolean isDisabled() {
        return TriggerDisabled;
    }

    // Handles before insert for Event
    // @param newList List of New Event.
    // @return void
    public static void beforeInsert( List<sObject> newList ) {}

    // Handles after insert for Event
    // @param newList List of New Event.
    // @param newMap Map of New Event.
    // @return void
    public void afterInsert( List<sObject> newList , Map<Id,sObject> newMap ) {
        EventRelationChangeEventTriggerHelper eventRelationTriggerHelperObject = new EventRelationChangeEventTriggerHelper();
        eventRelationTriggerHelperObject.afterInsertDirector(
            (List<EventRelationChangeEvent>) newList,
            (Map<Id, EventRelationChangeEvent>) newMap
        );
    }

    // Handles before update for Event
    // @param newMap Map of New Event.
    // @param oldMap Map of Old Event.
    // @return void
    public static void beforeUpdate( Map<Id,sObject> newMap , Map<Id,sObject> oldMap ) {}

    // Handles after update for Event
    // @param newMap Map of New Event.
    // @param oldMap Map of Old Event.
    // @return void
    public static void afterUpdate( Map<Id,sObject> newMap , Map<Id,sObject> oldMap ) {}

    // Handles before delete.
    // @param oldList List, OldMap Map.
    // @return void
    // Added beforeDelete method as this is referred in in NSP_ITriggerHandler
    public static void beforeDelete( List<sObject> oldList , Map<Id,sObject> oldMap ) {}

    // Handles after delete for Event
    // @param oldList List of old Event
    // @param oldMap Map of Old Event
    // @return void
    public static void afterDelete( List<sObject> oldList , Map<Id,sObject> oldMap ) {}

}