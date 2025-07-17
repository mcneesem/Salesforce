public class ContractTerminationQueue implements Queueable , Database.AllowsCallouts , Finalizer {
    // test w/ ContractTerminationHandlerTest (87%)

    private Map<Id,Date> contractToTerminationDates = null;
    private List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();

    public ContractTerminationQueue( Map<Id,Date> local ) {
        this.contractToTerminationDates = local;
    }

    public void execute( QueueableContext context ) {
        try {
            ContractAmender amender = new ContractAmender();
            if ( ( this.contractToTerminationDates != null )
                && !this.contractToTerminationDates.isEmpty()
                )
            {
                for ( Id contractId : contractToTerminationDates.keySet() ) {
                    Date terminationDate = contractToTerminationDates.get( contractId );
                    QuoteModel quoteModel = amender.load( contractId );
                    if ( ( quoteModel != null ) && ( quoteModel.record != null ) ) {
                        SBQQ__Quote__c quote = (SBQQ__Quote__c)quoteModel.record;
                        quote.NSP_TerminationDate__c = terminationDate;
                        quote.Run_Quote_Calc_for_Termination__c = true;
                        this.quotesToUpdate.add( quote );
                    }
                }
            }
            if ( !this.quotesToUpdate.isEmpty() ) {
                System.attachFinalizer( this );
            }
        } catch ( Exception e ) {
            ContractTerminationQueue.handleException( e , 'execute-Queueable' );
        }
    }

    public void execute( FinalizerContext context ) {
        try {
            if ( !this.quotesToUpdate.isEmpty() ) {
                Database.SaveResult[] quoteResults = Database.update( this.quotesToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    ContractTerminationQueue.class.getName() ,
                    'QuoteUpdate' ,
                    quoteResults
                );
            }
        } catch ( Exception e ) {
            ContractTerminationQueue.handleException( e , 'execute-Finalizer' );
        }
    }

    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            ContractTerminationQueue.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            ContractTerminationQueue.class.getName() ,
            methodName ,
            e
        );
    }

}
//