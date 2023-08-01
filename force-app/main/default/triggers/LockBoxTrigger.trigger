/* Trigger
* Checks Custom setting for current user 
* */
trigger LockBoxTrigger on NSP_Lock_Box__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
     //NSP_SubscriptionTriggerHandler
     NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
     if(!triggerSwitch.LockBoxTrigger__c) {
         NSP_TriggerDispatcher.run(new NSP_Lock_Box_TriggerHandler(), 'LockBox_Trigger');
     }
     
 }