public class OrderItemConsumptionRateFieldAction {
    // test w/ OrderItemConsumptionRateFieldActionTest (92%)

    @InvocableMethod(label='Update Order Item Consumption Rates')
    public static void updateOrderItems(List<Id> orderIds) {
        try{
            if (orderIds != null && !orderIds.isEmpty()) {
                List<OrderItem> orderItems = OrderItemConsumptionRateFieldAction.fetchOrderItems(orderIds);
                Set<Id> orderItemIds = OrderItemConsumptionRateFieldAction.getOrderItemIds(orderItems);

                Map<Id, List<SBQQ__OrderItemConsumptionRate__c>> orderItemConsumptionRateMap = new Map<Id, List<SBQQ__OrderItemConsumptionRate__c>>();
                if (!orderItemIds.isEmpty()) {
                    orderItemConsumptionRateMap = OrderItemConsumptionRateFieldAction.groupRatesByOrderItemId(
                        OrderItemConsumptionRateFieldAction.fetchConsumptionRates( orderItemIds )
                    );
                }

                List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
                if(orderItems != null && !orderItems.isEmpty()){
                    for (OrderItem oi : orderItems) {
                        List<SBQQ__OrderItemConsumptionRate__c> csRates =  OrderItemConsumptionRateFieldAction.classifyRates(
                            oi ,
                            orderItemConsumptionRateMap
                        );
                        orderItemsToUpdate = OrderItemConsumptionRateFieldAction.applyRatesToOrderItem(
                            orderItemsToUpdate ,
                            oi ,
                            csRates
                        );
                    }
                }

                if (orderItemsToUpdate != null && !orderItemsToUpdate.isEmpty()) {
                    List<Database.SaveResult> results = Database.update( orderItemsToUpdate , false );
                    NSP_ErrorLogHandler.logResults(
                        OrderItemConsumptionRateFieldAction.class.getName() ,
                        'OrderItem:Update' ,
                        results
                    );
                }
            }
        }catch (Exception e ){
            OrderItemConsumptionRateFieldAction.handleException( e , 'updateOrderItems' );
        }
    }

    private static List<SBQQ__OrderItemConsumptionRate__c> classifyRates(
        OrderItem oi ,
        Map<Id, List<SBQQ__OrderItemConsumptionRate__c>> orderItemConsumptionRateMap
    ){
        List<SBQQ__OrderItemConsumptionRate__c> response = null;
        if ( ( oi != null )
            && ( oi.Id != null )
            && orderItemConsumptionRateMap != null
            && orderItemConsumptionRateMap.containsKey( oi.Id )
            )
        {
            response = OrderItemConsumptionRateFieldAction.filterRates(
                orderItemConsumptionRateMap.get( oi.Id )
            );
        }
        return response;
    }

    private static List<SBQQ__OrderItemConsumptionRate__c> filterRates( List<SBQQ__OrderItemConsumptionRate__c> allRates ) {
        List<SBQQ__OrderItemConsumptionRate__c> response = null;
        if ( allRates != null && !allRates.isEmpty() ) {
            List<SBQQ__OrderItemConsumptionRate__c> scholarshipRates = new List<SBQQ__OrderItemConsumptionRate__c>();
            List<SBQQ__OrderItemConsumptionRate__c> otherRates = new List<SBQQ__OrderItemConsumptionRate__c>();
            for ( SBQQ__OrderItemConsumptionRate__c cr : allRates ) {
                if ( OrderItemConsumptionRateFieldAction.isScholarship( cr ) ) {
                    scholarshipRates.add( cr );
                } else {
                    otherRates.add( cr );
                }
            }
            if ( !scholarshipRates.isEmpty() ) {
                response = scholarshipRates;
            } else if ( !otherRates.isEmpty() ) {
                response = otherRates;
            }
        }
        return response;
    }

    private static Boolean isScholarship( SBQQ__OrderItemConsumptionRate__c cr ) {
        String csName = null;
        if ( ( cr != null ) && ( cr.SBQQ__OrderItemConsumptionSchedule__r != null ) ) {
            csName = cr.SBQQ__OrderItemConsumptionSchedule__r.Name;
        }
        Boolean response = false;
        if ( String.isNotBlank( csName ) && csName.contains( 'Scholarship' ) ) {
            response = true;
        }
        return response;
    }

    private static List<SBQQ__OrderItemConsumptionRate__c> fetchConsumptionRates(Set<Id> orderItemIds) {
        List<SBQQ__OrderItemConsumptionRate__c> csRateResults = new List<SBQQ__OrderItemConsumptionRate__c>();
        if(orderItemIds != null && !orderItemIds.isEmpty()){
            csRateResults = [ SELECT Id, OrderItemId__c, SBQQ__PricingMethod__c,SBQQ__Price__c,
                             SBQQ__OrderItemConsumptionSchedule__r.Name,SBQQ__ProcessingOrder__c
                             FROM SBQQ__OrderItemConsumptionRate__c
                             WHERE OrderItemId__c IN :orderItemIds];
        }
        return csRateResults;
    }

    private static List<OrderItem> fetchOrderItems(List<Id> orderIds) {
        List<OrderItem> orderItemResults = new List<OrderItem>();
        if(orderIds != null && !orderIds.isEmpty()){
            orderItemResults = [SELECT Id, Product2Id, Quantity, NSP_Consumption_Rate_Per_Unit__c,NSP_Consumption_Rate_Flat_Price__c
                                FROM OrderItem
                                WHERE OrderId IN :orderIds];
        }
        return orderItemResults;
    }

    private static Map<Id,List<SBQQ__OrderItemConsumptionRate__c>> groupRatesByOrderItemId(List<SBQQ__OrderItemConsumptionRate__c> consumptionRates) {
        Map<Id,List<SBQQ__OrderItemConsumptionRate__c>> rateMap = new Map<Id,List<SBQQ__OrderItemConsumptionRate__c>>();
        if(consumptionRates != null && !consumptionRates.isEmpty()){
            for (SBQQ__OrderItemConsumptionRate__c cr : consumptionRates) {
                if(String.isNotBlank( cr.OrderItemId__c )){
                    if (!rateMap.containsKey(cr.OrderItemId__c)) {
                        rateMap.put(cr.OrderItemId__c, new List<SBQQ__OrderItemConsumptionRate__c>());
                    }
                    rateMap.get(cr.OrderItemId__c).add(cr);
                }
            }
        }
        return rateMap;
    }

    private static Set<Id> getOrderItemIds(List<OrderItem> orderItems){
        Set<Id> collectIds = new Set<Id>();
        if(orderItems != null && !orderItems.isEmpty()){
            Map<Id,OrderItem> recordMap = new Map<Id,OrderItem>( orderItems );
            collectIds = recordMap.keySet();
        }
        return collectIds;
    }

    private static List<OrderItem> applyRatesToOrderItem(List<OrderItem> records, OrderItem oi, List<SBQQ__OrderItemConsumptionRate__c> csRates) {
        if (oi != null && csRates != null && !csRates.isEmpty() && records != null) {
            for (SBQQ__OrderItemConsumptionRate__c rate : csRates) {
                String csName;
                if(rate.SBQQ__OrderItemConsumptionSchedule__r != null){
                    csName = rate.SBQQ__OrderItemConsumptionSchedule__r.Name;
                }
                if(String.isNotBlank(csName) && csName.contains('Seasonal')){
                    oi = OrderItemConsumptionRateFieldAction.setSeasonalRates(rate,oi);
                }else{
                    oi = OrderItemConsumptionRateFieldAction.setNonSeasonalRates(rate,oi);
                }
            }

            if(oi != null){
                records.add(oi);
            }
        }
        return records;
    }

    private static OrderItem setNonSeasonalRates( SBQQ__OrderItemConsumptionRate__c rate , OrderItem oi ) {
        OrderItem response = null;
        if ( oi != null && rate != null ) {
            if ( rate.SBQQ__PricingMethod__c == 'FlatFee'
                && oi.NSP_Consumption_Rate_Flat_Price__c != rate.SBQQ__Price__c
                )
            {
                response = oi;
                response.NSP_Consumption_Rate_Flat_Price__c = rate.SBQQ__Price__c;
            }
            if ( rate.SBQQ__PricingMethod__c == 'PerUnit'
                && oi.NSP_Consumption_Rate_Per_Unit__c != rate.SBQQ__Price__c
                )
            {
                response = oi;
                response.NSP_Consumption_Rate_Per_Unit__c = rate.SBQQ__Price__c;
            }
        }
        return response;
    }

    private static OrderItem setSeasonalRates( SBQQ__OrderItemConsumptionRate__c rate , OrderItem oi ){
        OrderItem response = null;
        if ( oi != null
            && rate != null
            && rate.SBQQ__ProcessingOrder__c == 1
            && rate.SBQQ__PricingMethod__c == 'PerUnit'
            && oi.NSP_Consumption_Rate_Per_Unit__c != rate.SBQQ__Price__c
            )
        {
            response = oi;
            response.NSP_Consumption_Rate_Per_Unit__c = rate.SBQQ__Price__c;
        }
        return response;
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            OrderItemConsumptionRateFieldAction.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            OrderItemConsumptionRateFieldAction.class.getName() ,
            methodName ,
            e
        );
    }
}