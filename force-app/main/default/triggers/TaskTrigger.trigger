/**
 * Represents the Task/Activity trigger.
 */
trigger TaskTrigger on Task (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    NSP_TriggerDispatcher.run(new NSP_TaskTriggerHandler(), 'Task_Trigger');
}