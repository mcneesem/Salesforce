trigger ClientSubPlanHistoryTrigger on NSP_Client_Sub_Plan_History__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
	NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());

    //run if trigger switch is off
    if(!triggerSwitch.ClientSubPlanHistoryTrigger__c){
    	NSP_TriggerDispatcher.run(new NSP_ClientSubPlanHistTriggerHandler(), 'ClientSubPlanHistoryTrigger');
    }
}