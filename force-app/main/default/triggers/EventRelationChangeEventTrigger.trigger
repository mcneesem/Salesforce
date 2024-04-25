trigger EventRelationChangeEventTrigger on EventRelationChangeEvent (after Insert) {
    // test w/ EventRelationChangeEventHelperTest (100%)
    
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    if(!triggerSwitch.EventRelationChangeEventTrigger__c){
        NSP_TriggerDispatcher.run(new EventRelationChangeEventTriggerHandler(), 'EventRelationChangeEvent_Trigger');
    } 
}