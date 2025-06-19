public with sharing class CampaignMemberTriggerHelper {
    // test w/ CampaignMemberTriggerHelperTest (100%)

    public void afterUpdate( Map<Id,CampaignMember> newMap , Map<Id,CampaignMember> oldMap ) {
        if ( ( newMap != null ) 
            && ( newMap.size() > 0 )
            && ( oldMap != null )
            && ( oldMap.size() > 0 )
            )
        {
            NSP_SObjectHistoryTrackingHelper.enqueueJob(
                (Map<Id,sObject>)newMap ,
                (Map<Id,sObject>)oldMap
            );
        }
    }

}
//