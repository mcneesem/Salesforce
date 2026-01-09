public class OrderItemConsumptionRateFieldsUpdater {
    // test w/ OrderItemConsumptionRateUpdaterTest (92%)

    private static Map<Id, List<SBQQ__OrderItemConsumptionRate__c>> orderItemConsumptionRateMap = new Map<Id, List<SBQQ__OrderItemConsumptionRate__c>>();
    private static List<OrderItem> orderItemsToUpdate = new List<OrderItem>();

    @InvocableMethod(label='Update Order Item Consumption Rates')
    public static void updateOrderItems(List<Id> orderIds) {
        try{
            if (orderIds != null && !orderIds.isEmpty()) {
                List<OrderItem> orderItems = fetchOrderItems(orderIds);
                Set<Id> orderItemIds = getOrderItemIds(orderItems);

                if (!orderItemIds.isEmpty()) {
                    List<SBQQ__OrderItemConsumptionRate__c> consumptionRates = fetchConsumptionRates(orderItemIds);
                    groupRatesByOrderItemId(consumptionRates);
                }

                if(orderItems != null && !orderItems.isEmpty()){
                    for (OrderItem oi : orderItems) {
                        List<SBQQ__OrderItemConsumptionRate__c> csRates =  classifyRates(oi);
                        applyRatesToOrderItem(oi,csRates);
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

        List<SBQQ__OrderItemConsumptionRate__c> scholarshipRates = new List<SBQQ__OrderItemConsumptionRate__c>();
        List<SBQQ__OrderItemConsumptionRate__c> otherRates = new List<SBQQ__OrderItemConsumptionRate__c>();

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

        if(scholarshipRates != null && !scholarshipRates.isEmpty()){
            csRates = scholarshipRates;
        }else if (otherRates != null && !otherRates.isEmpty() ){
            csRates = otherRates;
        }
        return csRates;
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

    private static void groupRatesByOrderItemId(List<SBQQ__OrderItemConsumptionRate__c> consumptionRates) {
        if(consumptionRates != null && !consumptionRates.isEmpty()){
            for (SBQQ__OrderItemConsumptionRate__c cr : consumptionRates) {
                if (!orderItemConsumptionRateMap.containsKey(cr.OrderItemId__c)) {
                    orderItemConsumptionRateMap.put(cr.OrderItemId__c, new List<SBQQ__OrderItemConsumptionRate__c>());
                }
                orderItemConsumptionRateMap.get(cr.OrderItemId__c).add(cr);
            }
        }
    }

    private static Set<Id> getOrderItemIds(List<OrderItem> orderItems){
        Set<Id> collectIds = new Set<Id>();
        if(orderItems != null && !orderItems.isEmpty()){
            for (OrderItem oi : orderItems) {
                collectIds.add(oi.Id);
            }
        }
        return collectIds;
    }

    private static void applyRatesToOrderItem(OrderItem oi, List<SBQQ__OrderItemConsumptionRate__c> csRates) {
        boolean hasUpdated = false;
        if (csRates != null && !csRates.isEmpty()) {
            for (SBQQ__OrderItemConsumptionRate__c rate : csRates) {
                String csName;
                if(rate.SBQQ__OrderItemConsumptionSchedule__r != null){
                    csName = rate.SBQQ__OrderItemConsumptionSchedule__r.Name;
                }
                if(String.isNotBlank(csName) && csName.contains('Seasonal')){
                    if(rate.SBQQ__ProcessingOrder__c == 1 && rate.SBQQ__PricingMethod__c == 'PerUnit' && oi.NSP_Consumption_Rate_Per_Unit__c != rate.SBQQ__Price__c){
                        oi.NSP_Consumption_Rate_Per_Unit__c = rate.SBQQ__Price__c;
                        hasUpdated = true;
                    }
                }else{
                    if(rate.SBQQ__PricingMethod__c == 'FlatFee' && oi.NSP_Consumption_Rate_Flat_Price__c != rate.SBQQ__Price__c){
                        oi.NSP_Consumption_Rate_Flat_Price__c = rate.SBQQ__Price__c;
                        hasUpdated = true;
                    }
                    if(rate.SBQQ__PricingMethod__c == 'PerUnit' && oi.NSP_Consumption_Rate_Per_Unit__c != rate.SBQQ__Price__c){
                        oi.NSP_Consumption_Rate_Per_Unit__c = rate.SBQQ__Price__c;
                        hasUpdated = true;
                    }
                }
            }

            if(hasUpdated){
                orderItemsToUpdate.add(oi);
            }
        }
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