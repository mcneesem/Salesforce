/**
 * Represents the CLMDocument trigger.
 */

trigger OnCLMDocumentCreateTrigger on CLM_Document__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    //run if trigger switch is off
    if(!triggerSwitch.CLMDocumentTrigger__c){
        NSP_TriggerDispatcher.run(new CLMDocumentTriggerHandler(), 'OnCLMDocumentCreate_Trigger');
    }
}