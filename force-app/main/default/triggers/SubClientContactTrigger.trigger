trigger SubClientContactTrigger on NSP_Sub_Client_Contact__c (before insert,before update,after insert,after update) {
 NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());    
	 if(!triggerSwitch.NSP_Sub_Client_Contact__c){
		NSP_TriggerDispatcher.run(new NSP_SubClientContactTriggerHandler(), 'SubClientContact_Trigger');
	 }
}