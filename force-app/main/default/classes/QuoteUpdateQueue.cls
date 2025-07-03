public class QuoteUpdateQueue implements Queueable , Finalizer {
    // test w/ QuoteCalculationForTerminationTest (87%)

    private static final String QUOTE_STATUS_APPROVED = 'Approved';
    private Id quoteId = null;
    private List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();

    public QuoteUpdateQueue( Id quoteId ) {
        this.quoteId = quoteId;
    }

    public void execute( QueueableContext context ) {
        try {
            List<SBQQ__Quote__c> quotes = null;
            if ( this.quoteId != null ) {
                quotes = [
                    SELECT
                        Id ,
                        Ready_for_Approval__c ,
                        ApprovalStatus__c ,
                        SBQQ__Status__c ,
                        SubmittedUser__c ,
                        SubmittedDate__c ,
                        Auto_Termination__c
                    FROM SBQQ__Quote__c
                    WHERE Id = :this.quoteId
                ];
            }
            if ( ( quotes != null ) && !quotes.isEmpty() ) {
                SBQQ__Quote__c quote = quotes[0];
                if ( ( quote != null )
                    && !quote.Ready_for_Approval__c
                    && !quote.Auto_Termination__c
                    )
                {
                    quote.Ready_for_Approval__c = true;
                    quote.ApprovalStatus__c = QuoteUpdateQueue.QUOTE_STATUS_APPROVED;
                    quote.SBQQ__Status__c = QuoteUpdateQueue.QUOTE_STATUS_APPROVED;
                    quote.SubmittedUser__c = UserInfo.getUserId();
                    quote.SubmittedDate__c = System.now().date();
                    quote.Auto_Termination__c = true;
                    this.quotesToUpdate.add( quote );
                }
            }
            if ( !this.quotesToUpdate.isEmpty() ) {
                System.attachFinalizer( this );
            }
        } catch ( Exception e ) {
            QuoteUpdateQueue.handleException( e , 'execute-Queueable' );
        }
    }

    public void execute( System.FinalizerContext context ) {
        try {
            if ( !this.quotesToUpdate.isEmpty() ) {
                Database.SaveResult[] quoteResults = Database.update( this.quotesToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    QuoteUpdateQueue.class.getName() ,
                    'QuoteUpdate' ,
                    quoteResults
                );
            }
        } catch ( Exception e ) {
            QuoteUpdateQueue.handleException( e , 'execute-Finalizer' );
        }
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            QuoteUpdateQueue.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            QuoteUpdateQueue.class.getName() ,
            methodName ,
            e
        );
    }

}
//