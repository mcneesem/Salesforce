// @description Queueable and Finalizer that completes contract termination by inserting the
//              IWXWaiver line and flagging quotes for CPQ recalculation. Chained from
//              ContractTerminationQueue Finalizer.
public with sharing class QuoteTerminationQueueable implements Queueable , Finalizer {
    // test w/ ContractTerminationHandlerTest (89%)

    // Transaction 3 (execute): attaches Finalizer only.
    // Transaction 4 (Finalizer): adds IWXWaiver line directly (Selection product rule cannot be
    //   triggered via ServiceRouter.save alone - it requires CPQ's calculation engine), then sets
    //   Run_Quote_Calc_for_Termination__c = true so the flow triggers QuoteUpdateQueue.

    public static void enqueueJob(
        List<Id> quoteIdsLocal ,
        List<String> toUsersLocal ,
        Id contractIdLocal
        )
    {
        if ( ( quoteIdsLocal != null )
            && !quoteIdsLocal.isEmpty()
            && ( toUsersLocal != null )
            && !toUsersLocal.isEmpty()
            && ( contractIdLocal != null )
            && !System.isQueueable() // prevent AsyncExceptions...
            && ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() )
            )
        {
            System.enqueueJob(
                new QuoteTerminationQueueable(
                    quoteIdsLocal ,
                    toUsersLocal ,
                    contractIdLocal
                )
            );
        }
    }

    private List<Id> quoteIds;
    private List<String> toUsers;
    private Id contractIdToSendEmail;

    // @description Constructs the queueable with the quote IDs and notification recipients.
    // @param quoteIds Quote record identifiers to process.
    // @param toUsers Email recipients for failure notifications.
    // @param contractIdToSendEmail Contract identifier used in notification messages.
    private QuoteTerminationQueueable( List<Id> quoteIds , List<String> toUsers , Id contractIdToSendEmail ) {
        this.quoteIds = quoteIds != null ? quoteIds : new List<Id>();
        this.toUsers = toUsers != null ? toUsers : new List<String>();
        this.contractIdToSendEmail = contractIdToSendEmail;
    }

    // @description Attaches the Finalizer to run post-transaction IWXWaiver logic.
    // @param context Queueable execution context provided by the platform.
    public void execute( QueueableContext context ) {
        try {
            if ( !this.quoteIds.isEmpty() ) {
                System.attachFinalizer( this );
            }
        } catch ( Exception e ) {
            this.handleException( e , 'execute' );
        }
    }

    // @description Adds IWXWaiver lines to eligible quotes and flags them for CPQ recalculation.
    // @param context Finalizer execution context provided by the platform.
    // @throws Exception details are logged through NSP_ErrorLogHandler.
    public void execute( FinalizerContext context ) {
        try {
            if( this.quoteIds != null && !this.quoteIds.isEmpty() ){
                this.saveWaiverLines( this.buildWaiverLines( this.quoteIds ) );

                List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
                for ( Id quoteId : this.quoteIds ) {
                    quotesToUpdate.add( new SBQQ__Quote__c(
                        Id = quoteId ,
                        Run_Quote_Calc_for_Termination__c = true
                    ) );
                }
                if ( !quotesToUpdate.isEmpty() ) {
                    List<Database.SaveResult> updateResults = Database.update( quotesToUpdate , false );
                    NSP_ErrorLogHandler.logResults(
                        QuoteTerminationQueueable.class.getName() ,
                        'execute:Finalizer:update' ,
                        updateResults
                    );
                    for ( Database.SaveResult updateResult : updateResults ) {
                        if ( !updateResult.isSuccess() ) {
                            ContractTerminationHandler.sendEmail(
                                this.toUsers ,
                                'Setting Run_Quote_Calc_for_Termination__c for Contract (Id=' + this.contractIdToSendEmail + ')'
                            );
                        }
                    }
                }
            }
        } catch ( Exception e ) {
            this.handleException( e , 'execute:Finalizer' );
        }
    }

    // Mirrors: IF(AND(TEXT(SBQQ__Quote__r.SBQQ__Type__c)='Termination',
    //              (TODAY()-NSP_Original_Subscription_Date__c)<365,
    //              NOT(ISNULL(NSP_Original_waived_Amount__c))),1,0)
    private List<SBQQ__QuoteLine__c> buildWaiverLines( List<Id> quoteIdsToProcess ) {
        List<SBQQ__QuoteLine__c> waiverLines = new List<SBQQ__QuoteLine__c>();
        if( quoteIdsToProcess != null && !quoteIdsToProcess.isEmpty() ){
            Set<Id> alreadyHaveWaiver = new Set<Id>();
            for ( SBQQ__QuoteLine__c quoteLine : [
                SELECT SBQQ__Quote__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c IN :quoteIdsToProcess
                AND SBQQ__Product__r.ProductCode = 'IWXWaiver'
            ] ) {
                alreadyHaveWaiver.add( quoteLine.SBQQ__Quote__c );
            }

            Date cutoffDate = Date.today().addDays( -365 );
            Set<Id> eligibleQuoteIds = new Set<Id>();
            for ( SBQQ__QuoteLine__c quoteLine : [
                SELECT SBQQ__Quote__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c IN :quoteIdsToProcess
                AND SBQQ__Quote__r.NSP_TransactionType__c = 'Termination'
                AND NSP_Original_Subscription_Date__c > :cutoffDate
                AND NSP_Original_waived_Amount__c != null
            ] ) {
                eligibleQuoteIds.add( quoteLine.SBQQ__Quote__c );
            }
            eligibleQuoteIds.removeAll( alreadyHaveWaiver );

            if ( !eligibleQuoteIds.isEmpty() ) {
                List<Product2> waiverProductList = [
                    SELECT Id
                    FROM Product2
                    WHERE ProductCode = 'IWXWaiver'
                    AND IsActive = true
                    LIMIT 1
                ];
                if ( !waiverProductList.isEmpty() ) {
                    for ( Id quoteId : eligibleQuoteIds ) {
                        waiverLines.add( new SBQQ__QuoteLine__c(
                            SBQQ__Quote__c = quoteId ,
                            SBQQ__Product__c = waiverProductList[0].Id ,
                            SBQQ__Quantity__c = 1
                        ) );
                    }
                }
            }
        }
        return waiverLines;
    }

    private void saveWaiverLines( List<SBQQ__QuoteLine__c> waiverLines ) {
        if( waiverLines != null && !waiverLines.isEmpty() ){
            List<Database.SaveResult> saveResults = Database.insert( waiverLines , false );
            NSP_ErrorLogHandler.logResults(
                QuoteTerminationQueueable.class.getName() ,
                'saveWaiverLines' ,
                saveResults
            );
            for ( Database.SaveResult saveResult : saveResults ) {
                if ( !saveResult.isSuccess() ) {
                    ContractTerminationHandler.sendEmail(
                        this.toUsers ,
                        'Failed to add IWXWaiver line for Contract (Id=' + this.contractIdToSendEmail + ')'
                    );
                }
            }
        }
    }

    // @description Test-visible entry point that exercises the private exception handler.
    // @param e Exception to handle.
    // @param methodName Method identifier for logging context.
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            QuoteTerminationQueueable handler = new QuoteTerminationQueueable( null , null, null );
            handler.handleException( e , methodName );
        }
    }

    private void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            QuoteTerminationQueueable.class.getName() ,
            methodName ,
            e
        );
    }
}
//