// intentionally `without sharing` to preserve default sharing at api version 64...
public without sharing class ContractTerminationQueue implements Queueable , Database.AllowsCallouts , Finalizer {
    // test w/ ContractTerminationHandlerTest (86%)

    private Map<Id,Date> contractToTerminationDates = null;
    private List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
    private Map<Id,String> contractToEmails = null;
    private List<String> toUsers = new List<String>();
    private Id contractIdToSendEmail = null;

    public ContractTerminationQueue( Map<Id,Date> local , Map<Id,String> contractToEmails ) {
        this.contractToTerminationDates = local;
        this.contractToEmails = contractToEmails;
    }

    public void execute( QueueableContext context ) {
        try {
            // Start Termination process by making callout
            this.processTermination();
            if ( !this.quotesToUpdate.isEmpty() ) {
                System.attachFinalizer( this );
            }
        } catch ( Exception e ) {
            this.handleException( e , 'execute-Queueable' );
        }
    }

    public void execute( FinalizerContext context ) {
        try {
            if ( !this.quotesToUpdate.isEmpty() ) {
                List<Database.SaveResult> quoteResults = Database.update( this.quotesToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    ContractTerminationQueue.class.getName() ,
                    'QuoteUpdate' ,
                    quoteResults
                );
                List<Id> successfulQuoteIds = new List<Id>();
                for ( Database.SaveResult quoteResult : quoteResults ) {
                    if ( quoteResult.isSuccess() ) {
                        successfulQuoteIds.add( quoteResult.getId() );
                    } else {
                        ContractTerminationHandler.sendEmail(
                            this.toUsers ,
                            'Updating Quote for Contract (Id=' + this.contractIdToSendEmail + ')'
                        );
                    }
                }
                // Chain CPQ pipeline queueable - new transaction keeps callouts away from DML
                QuoteTerminationQueueable.enqueueJob(
                    successfulQuoteIds ,
                    this.toUsers ,
                    this.contractIdToSendEmail
                );
            }
        } catch ( Exception e ) {
            this.handleException( e , 'execute-Finalizer' );
        }
    }

    private void processTermination(){
        if ( ( this.contractToTerminationDates != null ) && !this.contractToTerminationDates.isEmpty() ){
            ContractAmender amender = new ContractAmender();
            for ( Id contractId : contractToTerminationDates.keySet() ) {
                this.contractIdToSendEmail = contractId;
                //add users to send email notification
                this.addToUsers( contractId );
                Date terminationDate = contractToTerminationDates.get( contractId );
                QuoteModel quoteModel = amender.load( contractId );
                if ( ( quoteModel != null ) && ( quoteModel.record != null ) ) {
                    SBQQ__Quote__c quote = (SBQQ__Quote__c)quoteModel.record;
                    quote.NSP_TerminationDate__c = terminationDate;
                    this.quotesToUpdate.add( quote );
                }
            }
        }
    }

    private void addToUsers( Id contractId ) {
        if ( ( contractToEmails != null ) && !contractToEmails.isEmpty() ) {
            this.toUsers.add( contractToEmails.get( contractId ) );
        } else if ( ( ContractTerminationHandler.autoTerminationEmailAddresses != null )
            && !ContractTerminationHandler.autoTerminationEmailAddresses.isEmpty()
            )
        {
            this.toUsers.addAll( ContractTerminationHandler.autoTerminationEmailAddresses );
        }
    }

    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            ContractTerminationQueue handler = new ContractTerminationQueue( null , null );
            handler.handleException( e , methodName );
        }
    }

    private void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            ContractTerminationQueue.class.getName() ,
            methodName ,
            e
        );
        ContractTerminationHandler.sendEmail( null , ContractTerminationQueue.class.getName() + '.' + methodName + ' (Contract.Id=' + this.contractIdToSendEmail + ')' );
    }

}
//