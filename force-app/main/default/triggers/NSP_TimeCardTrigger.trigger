/**
 * Represents the TimeCard trigger.
 */
trigger NSP_TimeCardTrigger on pse__Timecard_Header__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    //Calling Trigger Dispatcher
	 NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());    
	 //run if trigger switch is off
    if(!triggerSwitch.TimeCardTrigger__c){
        NSP_TriggerDispatcher.run(new NSP_TimeCardTriggerHandler(), 'TimeCard_Trigger');
    }
    
}