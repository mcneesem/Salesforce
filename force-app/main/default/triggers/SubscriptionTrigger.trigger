/* Trigger
* Checks Custom setting for current user 
* */
trigger SubscriptionTrigger on SBQQ__Subscription__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
     //NSP_SubscriptionTriggerHandler
     NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
     if(!triggerSwitch.SubscriptionTrigger__c) {
         NSP_TriggerDispatcher.run(new NSP_SubscriptionTriggerHandler(), 'Subscription_Trigger');
     }
     
 }