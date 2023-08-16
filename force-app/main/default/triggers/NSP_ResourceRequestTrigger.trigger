trigger NSP_ResourceRequestTrigger on pse__Resource_Request__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
	NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());

    //run if trigger switch is off
    if(!triggerSwitch.NSP_Resource_Request_Trigger__c){
    	NSP_TriggerDispatcher.run(new NSP_ResourceRequestTriggerHandler(), 'NSP_ResourceRequestTriggerHandler');
    }
}