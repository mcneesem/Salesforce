/**
 * Represents the NSP_Account_Team__c trigger.
 */
trigger AccountTeamTrigger on NSP_Account_Team__c (before insert,after insert,before update, after update , before delete, after delete) {
	NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    //run if trigger switch is off
    if(!triggerSwitch.AccountTeamTrigger__c){
	NSP_TriggerDispatcher.run(new NSP_AccountTeamTriggerHandler(), 'AccountTeam_Trigger');
	}
}