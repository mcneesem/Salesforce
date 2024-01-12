/**
* Represents the Asset trigger.
* V2.0    - STY-02841 - Ramya Ravi - TES Asset & RET Asset - AIMS Information - <STY-02841>
* 
*/
trigger NSP_AddressTrigger on NSP_Address__c(before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    //run if trigger switch is off
    if(!triggerSwitch.NSP_Address__c){      
        NSP_TriggerDispatcher.run(new NSP_AddressTriggerHandler(), 'NSP_AddressTrigger');
    }
}