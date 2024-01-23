trigger InboundEmailLogTrigger on InboundEmailLog__c ( after insert ) {
    // test w/ InboundEmailLogControllerTest (100%)
    static final String DEBUG_PREFIX = ' ~ InboundEmailLogTrigger';
    TriggerContextHandler.debug( DEBUG_PREFIX );
    if ( Trigger.isAfter && Trigger.isInsert && ( Trigger.newMap != null ) ) {
        // after-insert...
        InboundEmailLogQueueable.processInboundEmailLogs( Trigger.newMap.keySet() );
    }
}
//