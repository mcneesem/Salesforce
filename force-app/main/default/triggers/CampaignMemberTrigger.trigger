trigger CampaignMemberTrigger on CampaignMember( after update ) {
    NSP_Trigger_Switch__c triggerSwitch = NSP_Trigger_Switch__c.getInstance( UserInfo.getUserId() );
    if ( !triggerSwitch.CampaignMemberTrigger__c ) {
        NSP_TriggerDispatcher.run( new CampaignMemberTriggerHandler() , 'CampaignMember_Trigger' );
    }
}