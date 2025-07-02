global class QuoteCalculationForTermination implements SBQQ.CalculateCallback{
    //test w/ QuoteCalculationForTerminationTest (85%)

	global void callback(String quoteJSON){
        try{
            QuoteModel newquoteModel = (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
            if (newquoteModel != null && newquoteModel.record != null) {
                SBQQ__Quote__c objNewQuote = newquoteModel.record;
                if(objNewQuote != null){
                    if ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) {
                    	System.enqueueJob(new QuoteUpdateQueue(objNewQuote.Id));
                    }
                }
            }
        }catch(Exception e ){
             QuoteCalculationForTermination.handleException( e , 'callback' );
       }
    }

   @InvocableMethod(label='runQuoteCalculationForTermination' description='Method to trigger calculation on Quote for Termination' category='Quote')
   public static void runQuoteCalculationForTermination(List<String> quoteIdSet) {
       try{
           if(quoteIdSet != null && quoteIdSet.Size() > 0){
               QuoteReader reader = new QuoteReader();
               QuoteModel quoteModel = reader.read(quoteIdSet[0]);
               QuoteCalculator calculator = new QuoteCalculator();
               calculator.calculate(quoteModel, 'QuoteCalculationForTermination');
           }
       }Catch(Exception e){
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
    }
}