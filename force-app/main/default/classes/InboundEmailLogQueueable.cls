public with sharing class InboundEmailLogQueueable implements Queueable {
    // test w/ InboundEmailLogQueueableTest (100%)
    private static final String CLASS_NAME = ' ~ InboundEmailLogQueueable';

    public static void processInboundEmailLogs( Set<Id> logIds ) {
        // enqueue-within-limits...
        if ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) {
            System.enqueueJob( new InboundEmailLogQueueable( logIds ) );
        }
    }

    //
    //
    //

    private Set<Id> recordIds {
        private get;
        private set;
    }

    private List<InboundEmailLog__c> records {
        private get {
            if ( ( records == null )
                && ( this.recordIds != null )
                && ( this.recordIds.size() > 0 ) 
               )
            {
                List<InboundEmailLog__c> logs = [
                    SELECT
                        Id ,
                        InboundEmail__c ,
                        InboundEnvelope__c ,
                        FromName__c ,
                        FromAddress__c ,
                        ReplyTo__c ,
                        ToAddress__c ,
                        ToAddresses__c ,
                        CcAddresses__c ,
                        Subject__c ,
                        PlainTextBody__c ,
                        HtmlBody__c ,
                        LastModifiedDate ,
                        CreatedDate
                    FROM InboundEmailLog__c
                    WHERE ( Id IN :this.recordIds )
                    ORDER BY CreatedDate ASC
                ];
                if ( ( logs != null ) && ( logs.size() > 0 ) ) {
                    records = logs;
                }
            }
            return records;
        }
        private set;
    }

    private InboundEmailLogQueueable( Set<Id> logIds ) {
        String METHOD_NAME = 'InboundEmailLogQueueable(Set<Id>)';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ logIds=' + logIds );
        this.recordIds = logIds;
    }

    public void execute( QueueableContext context ) {
        String METHOD_NAME = 'execute';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ context=' + context );
        System.debug( DEBUG_PREFIX + ' ~ this.recordIds=' + this.recordIds );
        if ( ( this.records != null ) && ( this.records.size() > 0 ) ) {
            System.debug( DEBUG_PREFIX + ' ~ this.records.size=' + this.records.size() );
            ApexExceptionLogController.insertApexExceptionLogs( this.records );
            FlowErrorLogController.insertFlowErrorLogs( this.records );
        }
    }
}
//