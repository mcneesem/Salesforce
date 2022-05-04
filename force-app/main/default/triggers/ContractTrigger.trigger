//Trigger on Contract Object
trigger ContractTrigger on Contract (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    //run if trigger switch is off
    if(!triggerSwitch.ContractTrigger__c){
        NSP_TriggerDispatcher.run(new NSP_ContractTriggerHandler(), 'Contract_Trigger');
    }
}