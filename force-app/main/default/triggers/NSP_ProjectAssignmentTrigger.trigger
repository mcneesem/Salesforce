/*
 * Class Name : NSP_ProjectAssignmentTrigger
 */
trigger NSP_ProjectAssignmentTrigger on pse__Assignment__c (before insert, before update, after insert, after update) {
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
 //run if trigger switch is off
 if(!triggerSwitch.AssignmentTrigger__c){
    NSP_TriggerDispatcher.run(new NSP_ProjectAssignmentTriggerHandler(), 'Project_Assignment_Trigger');
 }
}