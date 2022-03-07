/**
 * Represents the Asset trigger.
 */
trigger AssetTrigger on Asset (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    //run if trigger switch is off
    if(!triggerSwitch.AssetTrigger__c){
    NSP_TriggerDispatcher.run(new NSP_AssetTriggerHandler(), 'Asset_Trigger');
    }
}