/**
 * Represents the Quote trigger.
 */

trigger QuoteTrigger on SBQQ__Quote__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    //Calling Trigger Dispatcher
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    //run if trigger switch is off
    if(!triggerSwitch.QuoteTrigger__c){
        NSP_TriggerDispatcher.run(new NSP_QuoteTriggerHandler(), 'Quote_Trigger');
    }
}