/**
 * Represents the SubClientContactAddress trigger.
 */
trigger NSP_SubClientContactAddressTrigger on NSP_Sub_Client_Contact_Address__c (before insert, before update, after insert, after update) {
    //Calling Trigger Dispatcher
     NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());    
     //run if trigger switch is off
     if(!triggerSwitch.NSP_Sub_Client_Contact_Address__c){
        NSP_TriggerDispatcher.run(new NSP_SubCCAddressTriggerHandler(), 'NSP_SubClientContactAddress_Trigger');
     }
}