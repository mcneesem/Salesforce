/**
* Represents the Milestone trigger.
*/
trigger NSP_MilestoneTrigger on pse__Milestone__c (before insert,before update,after insert, after update) {
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    if(!triggerSwitch.Milestone_Trigger__c){
        NSP_TriggerDispatcher.run(new NSP_MilestoneTriggerHandler(), 'Milestone_Trigger');
    }
}