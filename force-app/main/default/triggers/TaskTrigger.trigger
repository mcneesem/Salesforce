/**
 * Represents the Task/Activity trigger.
 */
trigger TaskTrigger on Task (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
   if(!triggerSwitch.Task_Trigger__c){
   NSP_TriggerDispatcher.run(new NSP_TaskTriggerHandler(), 'Task_Trigger');
   }
}