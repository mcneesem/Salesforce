public class BudgetaryQuoteTaxControllerQueue implements Queueable {
    // test w/ BudgetaryQuoteTaxControllerQueueTest (95%)

    private List<String> opportunityIdList;

    public static void enqueueJob( List<String> local ) {
        if ( local != null ) {
            System.enqueueJob( new BudgetaryQuoteTaxControllerQueue( local ) );
        }
    }

    private BudgetaryQuoteTaxControllerQueue( List<String> opportunityIdList ) {
        this.opportunityIdList = opportunityIdList;
    }

    public void execute( QueueableContext context ) {
        try {
            List<SBQQ__Quote__c> quoteToUpdate = new List<SBQQ__Quote__c>();
            List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
            for ( Opportunity op : [
                        SELECT
                            Id ,
                            AVA_SFCLOUD__Sales_Tax__c ,
                            SBQQ__PrimaryQuote__c,
                            (
                                SELECT
                                    Id ,
                                    AVA_SFCLOUD__Sales_Tax_Rate__c ,
                                    AVA_SFCLOUD__Sales_Tax_Details__c ,
                                    AVA_SFCLOUD__SalesTax_Line__c ,
                                    SBQQ__QuoteLine__c
                                FROM OpportunityLineItems
                            )
                        FROM Opportunity
                        WHERE (
                            ( SBQQ__PrimaryQuote__r.NSP_Budgetary_Quote__c = true )
                            AND ( Id IN :opportunityIdList )
                        )
                    ]
                )
            {
                SBQQ__Quote__c qt = new SBQQ__Quote__c();
                qt.Id = op.SBQQ__PrimaryQuote__c;
                qt.NSP_Sales_Tax__c = op.AVA_SFCLOUD__Sales_Tax__c;
                quoteToUpdate.add( qt );
                for ( OpportunityLineItem oli : op.OpportunityLineItems ) {
                    SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c();
                    qli.Id = oli.SBQQ__QuoteLine__c;
                    qli.NSP_Sales_Tax_Amount__c = oli.AVA_SFCLOUD__SalesTax_Line__c;
                    qli.NSP_Sales_Tax_Rate__c = oli.AVA_SFCLOUD__Sales_Tax_Rate__c;
                    qli.NSP_Sales_Tax_Details__c = oli.AVA_SFCLOUD__Sales_Tax_Details__c;
                    quoteLinesToUpdate.add( qli );
                }
            }
            if ( !quoteToUpdate.isEmpty() ) {
                List<Database.SaveResult> quoteUpdatedResults = Database.update( quoteToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_BudgetaryQuoteTaxController.class.getName() ,
                    'execute:updateQuote' ,
                    quoteUpdatedResults
                );
            }
            if ( !quoteLinesToUpdate.isEmpty() ) {
                List<Database.SaveResult> quoteLineUpdatedResults = Database.update( quoteLinesToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_BudgetaryQuoteTaxController.class.getName() ,
                    'execute:updateQuoteLine' ,
                    quoteLineUpdatedResults
                );
            }
        } catch ( Exception e ) {
            BudgetaryQuoteTaxControllerQueue.handleException( e , 'execute' );
        }
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            BudgetaryQuoteTaxControllerQueue.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            BudgetaryQuoteTaxControllerQueue.class.getName() ,
            methodName ,
            e
        );
    }

}
//