//This trigger is on Order objec
trigger OrderTrigger on Order (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
     //run if trigger switch is off
    if(!triggerSwitch.OrderTrigger__c){
        NSP_TriggerDispatcher.run(new NSP_OrderTriggerHandler(), 'Order_Trigger');
}
}