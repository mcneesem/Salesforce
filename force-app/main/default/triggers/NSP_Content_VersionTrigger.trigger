/**
 * Represents the Task/Activity trigger.
 * Added as part of STY-01774
 */
trigger NSP_Content_VersionTrigger on ContentVersion (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    NSP_TriggerDispatcher.run(new NSP_ContentVersionHandler(), 'ContentVersion_Trigger');  
}