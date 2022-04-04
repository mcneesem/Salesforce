/**
 * Represents the Task/Activity trigger.
 */
trigger TaskTrigger on Task (before insert,before update) {
    NSP_TriggerDispatcher.run(new NSP_TaskTriggerHandler(), 'Task_Trigger');
}