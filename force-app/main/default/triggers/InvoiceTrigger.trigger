/* Trigger
 * Checks Custom setting for current user 
 * */
trigger InvoiceTrigger on blng__Invoice__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    //NSP_InvoiceTriggerHandler
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    if(!triggerSwitch.InvoiceTrigger__c) {
    	NSP_TriggerDispatcher.run(new NSP_InvoiceTriggerHandler(), 'Invoice_Trigger');
    }
}