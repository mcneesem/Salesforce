//Represents Quote Line Trigger
trigger QuoteLineTrigger on SBQQ__QuoteLine__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    //Calling Trigger Dispatcher
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    //run if trigger switch is off
    if(!triggerSwitch.QuoteLineTrigger__c){
        NSP_TriggerDispatcher.run(new NSP_QuoteLineTriggerHandler(), 'QuoteLine_Trigger');
    }
}