public with sharing class CampaignMemberTriggerHandler implements NSP_ITriggerHandler {
    // test w/ CampaignMemberTriggerHelperTest (100%)

    //
    // Represents whether the trigger is disabled or not
    // @param N/A.
    // @return Boolean
    //
    public Boolean isDisabled() {
        return false;
    }

    //
    // Handles before insert for Campaign Member.
    // @param newList List of New Campaign Member.
    // @return void
    //
    public void beforeInsert( List<sObject> newList ) {
    }

    //
    // Handles after insert for Campaign
    // @param newList List of New Campaign.
    // @param newMap Map of New Campaign.
    // @return void
    //
    public void afterInsert( List<sObject> newList , Map<Id,sObject> newMap ) {
    }

    //
    // Handles before update for Campaign Member
    // @param newMap Map of New Campaign Member.
    // @param oldMap Map of Old Campaign Member.
    // @return void
    //
    public void beforeUpdate( Map<Id,sObject> newMap , Map<Id,sObject> oldMap ) {
    }

    //
    // Handles after update for Campaign Member
    // @param newMap Map of New Campaign Member.
    // @param oldMap Map of Old Campaign Member.
    // @return void
    //
    public void afterUpdate( Map<Id,sObject> newMap , Map<Id,sObject> oldMap ) {
        CampaignMemberTriggerHelper campaignMemberTriggerHelper = new CampaignMemberTriggerHelper();
        campaignMemberTriggerHelper.afterUpdate( (Map<Id,CampaignMember>) newMap , (Map<Id,CampaignMember>) oldMap );
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
    // Handles before delete for Campaign Member
    // @param oldList Map of old Campaign Member.
    // @param oldMap Map of old Campaign Member.
    // @return void
    //
    public void afterDelete( List<sobject> oldList , Map<Id,sObject> oldMap ) {
    }

}
//