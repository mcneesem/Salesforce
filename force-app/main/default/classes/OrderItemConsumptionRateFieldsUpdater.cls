public with sharing class OrderItemConsumptionRateFieldsUpdater {
    // test w/ OrderItemConsumptionRateUpdaterTest (92%)

    private static Map<Id, List<SBQQ__OrderItemConsumptionRate__c>> orderItemConsumptionRateMap = new Map<Id, List<SBQQ__OrderItemConsumptionRate__c>>();
    private static List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
    private static List<SBQQ__OrderItemConsumptionRate__c> scholarshipRates = new List<SBQQ__OrderItemConsumptionRate__c>();
    private static List<SBQQ__OrderItemConsumptionRate__c> otherRates = new List<SBQQ__OrderItemConsumptionRate__c>();

    @InvocableMethod(label='Update Order Item Consumption Rates')
    public static void updateOrderItems(List<Id> orderIds) {
        try{
            if (orderIds != null && !orderIds.isEmpty()) {
                List<OrderItem> orderItems = OrderItemConsumptionRateFieldsUpdater.fetchOrderItems(orderIds);
                Set<Id> orderItemIds = OrderItemConsumptionRateFieldsUpdater.getOrderItemIds(orderItems);

                if (!orderItemIds.isEmpty()) {
                    orderItemConsumptionRateMap = OrderItemConsumptionRateFieldsUpdater.groupRatesByOrderItemId(
                        OrderItemConsumptionRateFieldsUpdater.fetchConsumptionRates( orderItemIds )
                    );
                }

                if(orderItems != null && !orderItems.isEmpty()){
                    for (OrderItem oi : orderItems) {
                        List<SBQQ__OrderItemConsumptionRate__c> csRates =  OrderItemConsumptionRateFieldsUpdater.classifyRates(oi);
                        orderItemsToUpdate = OrderItemConsumptionRateFieldsUpdater.applyRatesToOrderItem(
                            orderItemsToUpdate ,
                            oi ,
                            csRates
                        );
                    }
                }

                if (orderItemsToUpdate != null && !orderItemsToUpdate.isEmpty()) {
                    List<Database.SaveResult> results = Database.update( orderItemsToUpdate , false );
                    NSP_ErrorLogHandler.logResults(
                        OrderItemConsumptionRateFieldsUpdater.class.getName() ,
                        'OrderItem:Update' ,
                        results
                    );
                }
            }
        }catch (Exception e ){
            OrderItemConsumptionRateFieldsUpdater.handleException( e , 'updateOrderItems' );
        }
    }

    private static List<SBQQ__OrderItemConsumptionRate__c> classifyRates(OrderItem oi){
        List<SBQQ__OrderItemConsumptionRate__c> csRates = new List<SBQQ__OrderItemConsumptionRate__c>();

        List<SBQQ__OrderItemConsumptionRate__c> allRates;
        if( orderItemConsumptionRateMap != null && orderItemConsumptionRateMap.containsKey(oi.Id) ){
            allRates = orderItemConsumptionRateMap.get(oi.Id);
        }

        OrderItemConsumptionRateFieldsUpdater.groupRates(allRates);

        if(scholarshipRates != null && !scholarshipRates.isEmpty()){
            csRates = scholarshipRates;
        }else if (otherRates != null && !otherRates.isEmpty() ){
            csRates = otherRates;
        }
        return csRates;
    }

    private static void groupRates(List<SBQQ__OrderItemConsumptionRate__c> allRates){
        if(allRates != null && !allRates.isEmpty()){
            for(SBQQ__OrderItemConsumptionRate__c cr: allRates){
                String csName;
                if(cr.SBQQ__OrderItemConsumptionSchedule__r != null){
                    csName = cr.SBQQ__OrderItemConsumptionSchedule__r.Name;
                }
                if(String.isNotBlank(csName) && csName.contains('Scholarship')){
                    scholarshipRates.add(cr);
                }else{
                    otherRates.add(cr);
                }
            }
        }
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
                if (!rateMap.containsKey(cr.OrderItemId__c)) {
                    rateMap.put(cr.OrderItemId__c, new List<SBQQ__OrderItemConsumptionRate__c>());
                }
                rateMap.get(cr.OrderItemId__c).add(cr);
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
                    oi = OrderItemConsumptionRateFieldsUpdater.setSeasonalRates(rate,oi);
                }else{
                    oi = OrderItemConsumptionRateFieldsUpdater.setNonSeasonalRates(rate,oi);
                }
            }

            if(oi != null){
                records.add(oi);
            }
        }
        return records;
    }

    private static OrderItem setNonSeasonalRates(SBQQ__OrderItemConsumptionRate__c rate, OrderItem oi){
        if(oi != null && rate != null){
            if(rate.SBQQ__PricingMethod__c == 'FlatFee' && oi.NSP_Consumption_Rate_Flat_Price__c != rate.SBQQ__Price__c){
                oi.NSP_Consumption_Rate_Flat_Price__c = rate.SBQQ__Price__c;
            }
            if(rate.SBQQ__PricingMethod__c == 'PerUnit' && oi.NSP_Consumption_Rate_Per_Unit__c != rate.SBQQ__Price__c){
                oi.NSP_Consumption_Rate_Per_Unit__c = rate.SBQQ__Price__c;
            }
        }
        return oi;
    }

    private static orderItem setSeasonalRates(SBQQ__OrderItemConsumptionRate__c rate, OrderItem oi){
        if(oi != null && rate != null && rate.SBQQ__ProcessingOrder__c == 1 && rate.SBQQ__PricingMethod__c == 'PerUnit' &&
           oi.NSP_Consumption_Rate_Per_Unit__c != rate.SBQQ__Price__c){
            oi.NSP_Consumption_Rate_Per_Unit__c = rate.SBQQ__Price__c;
        }
        return oi;
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            OrderItemConsumptionRateFieldsUpdater.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            OrderItemConsumptionRateFieldsUpdater.class.getName() ,
            methodName ,
            e
        );
    }
}