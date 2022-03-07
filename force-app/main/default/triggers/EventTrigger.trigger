/**
 * Represents the Event trigger.
 */
trigger EventTrigger on Event (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    if(!triggerSwitch.EventTrigger__c){
    NSP_TriggerDispatcher.run(new NSP_EventTriggerHandler(), 'Event_Trigger');
    }
}