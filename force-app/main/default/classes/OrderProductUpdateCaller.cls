public class OrderProductUpdateCaller {
    // test w/ OrderProductUpdateCallerTest (82%)

    private OrderProductUpdateCaller () { }

    //
    // Method Name: reCalculateQuoteLine
    // Description: Invocable method.Triggers CPQ calculation engine to fetch the updated price for an order item
    // Parameters: List of Strings which are OrderItem Ids
    // Return Type: void
    //
    @InvocableMethod(label='ReCalculate OrderProduct' description='Triggers CPQ calculation engine to fetch the updated price for an order item')
    public static void reCalculateQuoteLine( List<String> orderProductIds ) {
        try {
            List<OrderItem> validOrderItems = [
                SELECT
                    Id ,
                    SBQQ__Activated__c ,
                    OrderItemNumber ,
                    ServiceDate ,
                    OrderId ,
                    Order.ActivatedDate ,
                    EndDate ,
                    SBQQ__QuoteLine__c ,
                    NSP_ReCalculation_Status_Internal__c ,
                    SBQQ__QuoteLine__r.SBQQ__Quote__c ,
                    NSP_Project_Completion_Date__c ,
                    NSP_Override_Start_Date__c
                FROM OrderItem
                WHERE (
                    ( Id IN :orderProductIds )
                    AND ( NSP_ReCalculation_Status_Internal__c = 'Processing' )
                )
            ];
            Map<String,List<quoteLineWrapper>> quoteToQLIMap = new Map<String,List<quoteLineWrapper>>();
            Set<Id> uniqueOrderIds = new Set<Id>();
            for ( OrderItem oi : validOrderItems ) {
                uniqueOrderIds.add( oi.OrderId );
                if ( quoteToQLIMap.containskey( oi.SBQQ__QuoteLine__r.SBQQ__Quote__c ) ) {
                    List<quoteLineWrapper> qliwrapList = quoteToQLIMap.get( oi.SBQQ__QuoteLine__r.SBQQ__Quote__c );
                    qliwrapList.add(
                        new quoteLineWrapper(
                            oi.SBQQ__QuoteLine__c ,
                            oi.NSP_Override_Start_Date__c ,
                            oi.EndDate
                        )
                    );
                    quoteToQLIMap.put(
                        oi.SBQQ__QuoteLine__r.SBQQ__Quote__c ,
                        qliwrapList
                    );
                }
                else {
                    quoteToQLIMap.put(
                        oi.SBQQ__QuoteLine__r.SBQQ__Quote__c ,
                        new List<quoteLineWrapper>{
                            new quoteLineWrapper(
                                oi.SBQQ__QuoteLine__c ,
                                oi.NSP_Override_Start_Date__c ,
                                oi.EndDate
                            )
                        }
                    );
                }
            }
            if ( !quoteToQLIMap.isEmpty() && ( uniqueOrderIds.size() < 2 ) ) {
                for ( String quoteid : quoteToQLIMap.keyset() ) {
                    List<quoteLineWrapper> currQLIs = quoteToQLIMap.get( quoteid );
                    Map<String,quoteLineWrapper> currQliWrapMap= new Map<String,quoteLineWrapper>();
                    for ( quoteLineWrapper qw : currQLIs ) {
                        currQliWrapMap.put( qw.qlId , qw );
                    }
                    QuoteReader reader = new QuoteReader();
                    QuoteModel quoteModel = reader.read( quoteid );
                    if ( !quoteModel.lineItems.isEmpty() ) {
                        Date quoteStartDate;
                        for ( QuoteLineModel qlm : quoteModel.lineItems ) {
                            if ( currQliWrapMap.containsKey( qlm.record.Id ) ) {
                                quoteLineWrapper matchingQLWrap = currQliWrapMap.get( qlm.record.Id );
                                qlm.record.SBQQ__StartDate__c = matchingQLWrap.StartDate;
                                qlm.record.SBQQ__EndDate__c = matchingQLWrap.EndDate;
                                if ( ( matchingQLWrap.StartDate != null )
                                    && ( ( quoteStartDate == null ) || ( matchingQLWrap.StartDate < quoteStartDate ) )
                                    )
                                {
                                    quoteStartDate = matchingQLWrap.StartDate;
                                }
                            }
                        }
                        if ( quoteStartDate != null ) {
                            quoteModel.record.SBQQ__StartDate__c = quoteStartDate;
                        }
                    }
                    QuoteCalculator calculator = new QuoteCalculator();
                    calculator.calculate( quoteModel , 'MyCallback' );
                }
            }
            //update validOrderItems;
        } catch ( Exception e ) {
            OrderProductUpdateCaller.handleException( e , 'reCalculateQuoteLine' );
        }
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            OrderProductUpdateCaller.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            OrderProductUpdateCaller.class.getName() ,
            methodName ,
            e
        );
    }

    public class quoteLineWrapper {
        public String qlId;
        public Date StartDate;
        public Date EndDate;
        quoteLineWrapper(String qlid, Date startdt, Date enddt) {
            this.qlId = qlid;
            this.StartDate = startdt;
            this.EndDate = enddt;
        }
    }
}
//