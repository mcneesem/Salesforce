global class QuoteCalculationForTermination implements SBQQ.CalculateCallback {
    // test w/ QuoteCalculationForTerminationTest (85%)

    global void callback( String quoteJSON ) {
        try {
            if ( String.isNotBlank( quoteJSON ) ) {
                QuoteModel newquoteModel = (QuoteModel)JSON.deserialize( quoteJSON , QuoteModel.class );
                if ( ( newquoteModel != null ) && ( newquoteModel.record != null ) ) {
                    SBQQ__Quote__c objNewQuote = newquoteModel.record;
                    if ( objNewQuote != null ) {
                        if ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) {
                            System.enqueueJob( new QuoteUpdateQueue( objNewQuote.Id ) );
                        } else {
                            String recipientEmail = getRequesterEmailAddress( objNewQuote.Id );
                            QuoteCalculationForTermination.sendfailureEmail( recipientEmail , 'Quote Calculation Callback for Quote (Id=' + objNewQuote.Id + ')' );
                        }
                    }
                }
            }
        } catch ( Exception e ) {
            QuoteCalculationForTermination.handleException( e , 'callback' );
        }
    }

    @InvocableMethod(label='runQuoteCalculationForTermination' description='Method to trigger calculation on Quote for Termination' category='Quote')
    public static void runQuoteCalculationForTermination( List<String> quoteIdSet ) {
        try {
            if ( ( quoteIdSet != null ) && !quoteIdSet.isEmpty() ) {
                QuoteReader reader = new QuoteReader();
                QuoteModel quoteModel = reader.read( quoteIdSet[0] );
                QuoteCalculator calculator = new QuoteCalculator();
                calculator.calculate( quoteModel , 'QuoteCalculationForTermination' );
            }
        } catch ( Exception e ) {
            QuoteCalculationForTermination.handleException( e , 'runQuoteCalculationForTermination' );
        }
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            QuoteCalculationForTermination.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            QuoteCalculationForTermination.class.getName() ,
            methodName ,
            e
        );
        ContractTerminationHandler.sendEmail( null , methodName );
    }

    public static void sendfailureEmail( String recipientEmail , String failureReason ) {
        List<String> toUsers = new List<String>();
        if ( String.isNotBlank( recipientEmail ) ) {
            toUsers.add( recipientEmail );
        } else if ( ContractTerminationHandler.autoTerminationEmailAddresses != null
            && !ContractTerminationHandler.autoTerminationEmailAddresses.isEmpty()
            )
        {
            toUsers.addAll( ContractTerminationHandler.autoTerminationEmailAddresses );
        }
        if ( !toUsers.isEmpty() ) {
            ContractTerminationHandler.sendEmail( toUsers , failureReason );
        }
    }

    public static String getRequesterEmailAddress( Id quoteId ) {
        String emailaddress = null;
        if ( quoteId != null ) {
            List<SBQQ__Quote__c> quotes = [
                SELECT
                    Id ,
                    SBQQ__MasterEvergreenContract__r.Auto_Termination_Email__c ,
                    SBQQ__MasterContract__r.Auto_Termination_Email__c
                FROM SBQQ__Quote__c
                WHERE ( Id = :quoteId )
            ];
            if ( !quotes.isEmpty() ) {
                SBQQ__Quote__c quote = quotes[0];
                if ( quote.SBQQ__MasterEvergreenContract__r != null ) {
                    emailaddress = quote.SBQQ__MasterEvergreenContract__r.Auto_Termination_Email__c;
                } else if ( quote.SBQQ__MasterContract__r != null ) {
                    emailaddress = quote.SBQQ__MasterContract__r.Auto_Termination_Email__c;
                }
            }
        }
        return emailaddress;
    }

}
//