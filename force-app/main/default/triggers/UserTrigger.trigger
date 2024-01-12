trigger UserTrigger on User (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    //Calling Trigger Dispatcher
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    if(!triggerSwitch.User_Trigger__c){
        NSP_TriggerDispatcher.run(new NSP_UserTriggerHandler(), 'User_Trigger');
    }
}