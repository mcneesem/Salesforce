/**
 * Represents the AccountContactRelation trigger.
 */
trigger AccountContactRelationTrigger on AccountContactRelation (after insert,after update, before insert , before update, before delete, after delete) {
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    //run if trigger switch is off
    if(!triggerSwitch.AccountContactRelationTrigger__c){
    NSP_TriggerDispatcher.run(new NSP_AccountContactRelationTriggerHandler(), 'AccountContactRelation_Trigger');
    }
}