/**
 * Represents the Sub Client trigger.
 */
trigger SubClientTrigger on NSP_Sub_Client__c (after insert,after update) {
	 //Calling Trigger Dispatcher
	 NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
	 //run if trigger switch is off
	 if(!triggerSwitch.SubClientTrigger__c){
		NSP_TriggerDispatcher.run(new NSP_SubClientTriggerHandler(), 'SubClient_Trigger');
	 }
}