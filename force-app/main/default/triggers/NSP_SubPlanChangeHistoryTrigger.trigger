/**
 * Represents the Sub Plan Change History trigger.
 */
trigger NSP_SubPlanChangeHistoryTrigger on NSP_Sub_Plan_Change_History__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    //Calling Trigger Dispatcher
	 NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());    
	 //run if trigger switch is off
	 if(!triggerSwitch.NSP_Sub_Plan_Change_History__c){
    	NSP_TriggerDispatcher.run(new NSP_SubPlanChangeHistoryTriggerHandler(), 'SubPlanChangeHistory_Trigger');
     }
}