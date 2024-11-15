trigger NSP_Content_VersionTrigger on ContentVersion (
    before insert ,
    after insert ,
    before update ,
    after update ,
    before delete ,
    after delete ,
    after undelete
    )
{
    // test w/ CLMDocumentTransferTest (100%)
    if ( !NSP_Trigger_Switch__c.getInstance( UserInfo.getUserId() ).ContentVersionTrigger__c ) {
        // run handler when trigger switch is off...
        NSP_TriggerDispatcher.run( new NSP_ContentVersionHandler() , 'ContentVersion_Trigger' );
    }
}
//