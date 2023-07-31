/**
* Represents the DocusignStatus trigger.
*/
trigger NSP_DocusignStatustrigger on dfsle__EnvelopeStatus__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());    
    //run if trigger switch is off
    if(!triggerSwitch.NSP_Docusign_status__c){
        NSP_TriggerDispatcher.run(new NSP_DocusignStatusHandler(), 'NSP_DocusignStatustrigger');
    }
}