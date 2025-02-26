//
// Represents the User trigger handler.
//
public with sharing class NSP_UserTriggerHandler implements NSP_ITriggerHandler{
    // test w/ NSP_UserTriggerHelper_Test (92%)
    // test w/ UserOnboardingTriggerHelperTest (100%)

    // Use this variable to disable this trigger from transaction
    public static Boolean TriggerDisabled = false;

    //
    // Represents whether the trigger is disabled or not
    // @param N/A.
    // @return Boolean
    //
    //
    public Boolean isDisabled() {
        return TriggerDisabled;
    }

    //
    // Handles before insert for Quote
    // @param newList List of New Quote.
    // @return void
    //
    public void beforeInsert( List<sObject> newList ) {
        NSP_UserTriggerHelper userTriggerHelperObject = new NSP_UserTriggerHelper();
        userTriggerHelperObject.beforeInsertUser( (List<User>)newList );
        UserOnboardingTriggerHelper userOnboardingTriggerHelperObject = new UserOnboardingTriggerHelper();
        userOnboardingTriggerHelperObject.beforeInsertUser( (List<User>)newList );
    }

    //
    // Handles after insert for Quote
    // @param newList List of New Quote.
    // @param newMap Map of New Quote.
    // @return void
    //
    public void afterInsert( List<sObject> newList , Map<Id,sObject> newMap ) {
        NSP_UserTriggerHelper userTriggerHelperObject = new NSP_UserTriggerHelper();
        userTriggerHelperObject.afterInsertUser( (List<User>)newList );
        if ( ( Limits.getLimitQueueableJobs() > 1 )
            && ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() )
            )
        {
            System.enqueueJob(
                new UserOnboardingQueuable(
                    (List<User>)newList ,
                    null ,
                    null ,
                    'afterinsert'
                )
            );
        }
    }

    //
    // Handles before update for Quote
    // @param newMap Map of New Quote.
    // @param oldMap Map of Old Quote.
    // @return void
    //
    public void beforeUpdate( Map<Id,sObject> newMap , Map<Id,sObject> oldMap ) {
        NSP_UserTriggerHelper userTriggerHelperObject = new NSP_UserTriggerHelper();
        userTriggerHelperObject.beforeUpdateUser( (Map<Id,User>)newMap , (Map<Id,User>)oldMap );
        UserOnboardingTriggerHelper userOnboardingTriggerHelperObject = new UserOnboardingTriggerHelper();
        userOnboardingTriggerHelperObject.beforeUpdateUser( (Map<Id,User>)newMap , (Map<Id,User>)oldMap );
    }

    //
    // Handles after update for Quote
    // @param newMap Map of New Quote.
    // @param oldMap Map of Old Quote.
    // @return void
    //
    public void afterUpdate( Map<Id,sObject> newMap , Map<Id,sObject> oldMap ) {
        // Added as a part of STY-02768
        NSP_userSalesOfficeRecordSharing.ownerSalesofficeSharing( (Map<Id,User>)newMap , (Map<Id,User>)oldMap );
        NSP_UserTriggerHelper userTriggerHelperObject = new NSP_UserTriggerHelper();
        userTriggerHelperObject.afterUpdateUser( (Map<Id,User>)newMap , (Map<Id,User>)oldMap );
        // Added as a part of STY-02108
        NSP_UserTriggerHelper.updateAssetServiceRegion( (Map<Id,User>)newMap , (Map<Id,User>)oldMap );
        if ( ( Limits.getLimitQueueableJobs() > 1 )
            && ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() )
            )
        {
            System.enqueueJob(
                new UserOnboardingQueuable(
                    null ,
                    (Map<Id,User>)newMap ,
                    (Map<Id,User>)oldMap ,
                    'afterupdate'
                )
            );
        }
    }

    //
    // Handles before delete.
    // @param oldList List, OldMap Map.
    // @return void
    // Added beforeDelete method as this is referred in in NSP_ITriggerHandler
    //
    public void beforeDelete( List<sObject> oldList , Map<Id,sObject> oldMap ) {
    }

    //
    // Handles after delete for Quote.
    // @param oldList List of old Quote.
    // @param oldMap Map of Old Quote.
    // @return void
    //
    public void afterDelete( List<sObject> oldList , Map<Id,sObject> oldMap ) {
    }

}
//