public class NSP_ProjectAssetTriggerHandler implements NSP_ITriggerHandler {
    // test w/ NSP_ProjectAssetTriggerHelperTest (80%)

    //Use this variable to disable this trigger from transaction
    public static Boolean TriggerDisabled = false;

    public static Boolean runOnce = true;

    //
    // Represents whether the trigger is disabled or not
    // @param N/A.
    // @return Boolean
    //
    public Boolean isDisabled() {
        return TriggerDisabled;
    }


    //
    // Handles before insert for Project Assets
    // @param newList List of New Project Assets.
    // @return void
    //
    public void beforeInsert( List<sObject> newList ) {
    }

    //
    // Handles after insert for Project Assets
    // @param newList List of New Project Assets.
    // @param oldMap Map of Old Project Assets.
    // @return void
    //
    public void afterInsert( List<sObject> newList , Map<Id,sObject> newMap ) {
    }

    //
    // Handles before update for Project Assets
    // @param newMap Map of New Project Assets.
    // @param oldMap Map of Old Project Assets.
    // @return void
    //
    public void beforeUpdate( Map<Id,sObject> newMap , Map<Id,sObject> oldMap ) {
    }

    //
    // Handles after update for Project Assets
    // @param newMap Map of New Project Assets.
    // @param oldMap Map of Old Project Assets.
    // @return void
    //
    public void afterUpdate( Map<Id,sObject> newMap , Map<Id,sObject> oldMap ) {
    }

    //
    // Handles before delete for Project Assets
    // @param oldList List of New Project Assets.
    // @param oldMap Map of Old Project Assets.
    // @return void
    //
    public void beforeDelete( List<sObject> oldList , Map<Id,sObject> oldMap ) {
    }

    //
    // Handles after delete for Project Assets
    // @param oldList List of New Project Assets.
    // @param oldMap Map of Old Project Assets.
    // @return void
    //
    public void afterDelete( List<sObject> oldList , Map<Id,sObject> oldMap ) {
    }

}
//