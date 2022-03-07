/**
 * Represents the Opportunity Split trigger.
 */
trigger OpportunitySplitTrigger on NSP_Employee_Split__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    if(!triggerSwitch.OpportunitySplitTrigger__c){
        NSP_TriggerDispatcher.run(new NSP_OpportunitySplitTriggerHandler(), 'Opportunity_Split_Trigger');
    }
}