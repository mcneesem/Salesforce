global class NSP_OrderChangeCallback implements SBQQ.CalculateCallback  {
	
    global void callback(String quoteJSON){
        try{
            QuoteModel newquoteModel = (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
            SBQQ__Quote__c objNewQuote = newquoteModel.record;
            objNewQuote.SBQQ__Ordered__c =  true;
            update objNewQuote;
        }catch(Exception ex ){
               NSP_ErrorLogHandler.logSaveException('NSP_OrderChangeCallback', 'callback', ex.getMessage());
       }   
        
    }
   
   @InvocableMethod(label='runQuoteCalculation' description='Method to trigger calculation on Quote' category='Quote')
   public static void runQuoteCalculation(List<String> quoteIdSet) {
       if(quoteIdSet != null && quoteIdSet.Size() > 0){
           list<SBQQ__QuoteLine__c> quoteLineList = new list<SBQQ__QuoteLine__c>([SELECT Id from SBQQ__QuoteLine__c WHERE SBQQ__Product__r.SBQQ__SubscriptionType__c = NULL AND SBQQ__Quote__c IN : quoteIdSet ]);
           if(quoteLineList.Size() > 0){
               delete quoteLineList;
           }
           QuoteReader reader = new QuoteReader();
           QuoteModel quoteModel = reader.read(quoteIdSet[0]);
           QuoteCalculator calculator = new QuoteCalculator();
           calculator.calculate(quoteModel, 'NSP_OrderChangeCallback');
       }
   }
}