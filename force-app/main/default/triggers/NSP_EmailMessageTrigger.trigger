//This trigger handles insert,update,delete && Undelete operations
trigger NSP_EmailMessageTrigger on EmailMessage (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    //run if trigger switch is off
    if(!triggerSwitch.Email_Message__c){ 
    NSP_TriggerDispatcher.run(new NSP_EmailMessageTriggerHandler(), 'EmailMessage_Trigger');
    }
}