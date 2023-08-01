trigger NSP_ProjectTaskQueueEventTrigger on NSP_ProjectTaskQueueEvent__e (after insert) {
    NSP_ProjectTaskQueueEventHandler.afterInsertHandler(Trigger.new);
}