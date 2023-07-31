/**
 * Represents the Amendment checklist trigger.
 */
trigger SalesToImplementationTrigger on NSP_Sales_to_Implementation__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete ) {
	NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());

    //run if trigger switch is off
    if(!triggerSwitch.SalesToImplementationTrigger__c){
    	NSP_TriggerDispatcher.run(new NSP_SalesToImplementationHandler(), 'SalesToImplementation Trigger');
    }
}