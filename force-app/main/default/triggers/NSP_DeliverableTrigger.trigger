trigger NSP_DeliverableTrigger on NSP_Deliverable__c (before insert, before update) {
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    if(!triggerSwitch.NSP_Deliverable_Trigger__c){
        NSP_TriggerDispatcher.run(new NSP_DeliverableTriggerHandler(), 'Deliverable_Trigger');
    }
}