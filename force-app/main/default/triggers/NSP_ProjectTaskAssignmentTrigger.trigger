trigger NSP_ProjectTaskAssignmentTrigger on pse__Project_Task_Assignment__c (before insert, before update, after insert, after update) {
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
//run if trigger switch is off
if(!triggerSwitch.ProjectTaskAssignmentTrigger__c){
    NSP_TriggerDispatcher.run(new NSP_ProjectTaskAssignmentTriggerHandler(), 'Project_Task_Assignment_Trigger');
}
}