trigger NSP_TerminationFormTrigger on NSP_Termination_Form__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    //run if trigger switch is off
    if(!triggerSwitch.TerminationFormTrigger__c){
    	NSP_TriggerDispatcher.run(new NSP_TerminationFormTriggerHandler(), 'TerminationForm_Trigger');
    }
}