/**
 * Represents the Contact trigger.
 */
trigger ContactTrigger on Contact (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    //run if trigger switch is off
    if(!triggerSwitch.ContactTrigger__c){
        NSP_TriggerDispatcher.run(new NSP_ContactTriggerHandler(), 'Contact_Trigger');
    }
}