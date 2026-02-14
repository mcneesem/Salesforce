trigger NSP_FocusItemTrigger on NSP_Focus_Item__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    // test w/ NSP_FocusItemTriggerHelperTest (83%)
    NSP_Trigger_Switch__c triggerSwitch = NSP_Trigger_Switch__c.getInstance( UserInfo.getUserId() );
    // run if trigger switch is off
    if ( !triggerSwitch.FocusItemTrigger__c ) {
        NSP_TriggerDispatcher.run( new NSP_FocusItemTriggerHandler() , 'Focus_Item_Trigger' );
    }
}
//