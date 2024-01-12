/**
* Represents the AccountGroupMember
*/
trigger AccountGroupMemberTrigger on NSP_Account_Group_Member__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    //run if trigger switch is off
    if(!triggerSwitch.AccountGroupMemberTrigger__c){
        NSP_TriggerDispatcher.run(new NSP_AccountGroupMemberTriggerHandler(), 'AccountGroupMember_Trigger');
    }
}