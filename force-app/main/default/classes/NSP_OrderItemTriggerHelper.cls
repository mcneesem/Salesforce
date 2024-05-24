/**
* Represents the OrderItem trigger helper which handles all the logic.
*/
public class NSP_OrderItemTriggerHelper {
    // test w/ NSP_OrderTriggerHelperTest,NSP_OrderItemTriggerHelperTest (77%)

    static final string RENEWABLE = 'Renewable';
    static final String LASSO_PARTNERNAME=System.Label.NSP_Lasso_PartnerName;
    /**
    * Single method for before insert operations for Order Item Trigger.
    * @param newList List of New OrderItems.  
    * @return void             
    *                
    */
    public void populateFieldValuesOnInsert(List<OrderItem> OrderItemNewList)  {
    
        List<String> orderIds = new List<String> (); 
        Set<String> billingAccounts= new Set<String>();  
        Set<String> productsByLegalEntity = new Set<String>(System.Label.NSP_InvoiceByLegalEntityProducts.split(','));
            for(OrderItem oli : OrderItemNewList) {
                if(oli.OrderId !=null && oli.blng__BillingAccount__c==null){
                    orderIds.add(oli.OrderId);
                }
            oli.blng__InvoiceGrouping__c = 'Invoice Group ID;'+'Legal Entity';
            if(oli.NSP_Scholarship_Price__c == true){
                oli.NSP_Scholarship_End_Date__c = System.today().addMonths(23).toStartOfMonth();
            }
        }
            if(orderIds.size()>0) {
            Map<Id,Order> ordersMap = new Map<Id,Order>([Select Id, Status, AccountId,  NSP_Billing_Account__c, ShippingPostalCode, NSP_Partner__r.Name,blng__BillingAccount__c  FROM Order WHERE Id IN:orderIds]);
            for (OrderItem oi : OrderItemNewList) {
                if(orderIds.contains(oi.OrderId)) {
                    if(ordersMap.containsKey(oi.OrderId)) {
                        Order currOrder = ordersMap.get(oi.OrderId);
                        if(currOrder.blng__BillingAccount__c!=null){
                            oi.blng__BillingAccount__c = currOrder.blng__BillingAccount__c;
                        }
                        else{
                            oi.blng__BillingAccount__c = currOrder.AccountId;
                        }
                        billingAccounts.add(oi.blng__BillingAccount__c);
                    }
                }
            }
            Map<String,blng__PaymentMethod__c> billingActPaymentMap=retrieveACHActivePaymentMethods(billingAccounts);
            for(OrderItem oi : OrderItemNewList){
                Order currOrder = ordersMap.get(oi.OrderId);
                if(ordersMap.containsKey(oi.OrderId) && oi.NSP_Preferred_Payment_Method__c=='ACH' && oi.blng__BillingAccount__c!=null){
                    oi.NSP_Payment_Method__c=billingActPaymentMap.get(oi.blng__BillingAccount__c)?.Id;
                }
                if(currOrder.NSP_Partner__r.Name != LASSO_PARTNERNAME){
                    oi.blng__InvoiceGroupId__c = (String)currOrder.AccountId + (String)currOrder.NSP_Billing_Account__c + (String)currOrder.ShippingPostalCode +(String)oi.NSP_Payment_Method__c;
                }
            }
         }
    }
    
    
    /**
    * Iterates throught the list of new OrderItem and passes the required attributes to other methods.
    * @param newList List of New OrderItems.  
    * @return void             
    *                
    */
        
        public void processOrderItemForScholarshipCS(Map<Id, OrderItem> newMap)  {
            Map<Id,boolean> orderItemIdToScholarShipFeeMap = new Map<Id,boolean>();
            Map<Id,String> opIdMap = new Map<Id,String>();
            List<String> cat1ListOrderItems = new List<String>();
            List<String> cat2ListOrderItems = new List<String>();
            List<String> cat3ListOrderItems = new List<String>();
            List<String> orderItemPartnerAccounts = new List<String>();

            for(OrderItem eachItem : newMap.values()) {
                if(eachItem.NSP_IsScholarshipFee_Applicable__c || eachItem.NSP_Is_Partner_CS_Applicable__c || eachItem.NSP_OLI_CS_Applicable__c ) {
                if(!eachItem.NSP_Scholarship_Price__c && !eachItem.NSP_Is_Partner_CS_Applicable__c) {
                   cat1ListOrderItems.add(eachItem.Id); // Category 1 - Delete Scholarship and Partner consumption schedules - Both not applicable
                }
                if(eachItem.NSP_Scholarship_Price__c && !eachItem.NSP_Is_Partner_CS_Applicable__c) {
                   cat2ListOrderItems.add(eachItem.Id); // Category 2 - Scholarship Applicable - Delete Partner consumption schedules
                }
                if(!eachItem.NSP_Scholarship_Price__c && eachItem.NSP_Is_Partner_CS_Applicable__c) {
                   cat3ListOrderItems.add(eachItem.Id); // Category 3 - Partner consumption schedule applicable - Delete every consumption schedules except the one that matches with Order Partner
   					orderItemPartnerAccounts.add(eachItem.NSP_Order_Partner_Reference__c); 
                }
                }
                if(eachItem.NSP_ServiceAssetCategory__c != null && eachItem.NSP_ServiceAssetCategory__c != NSP_CPQConstants.HARDWARE_ASSET && eachItem.NSP_ServiceAsset__c == null){
                    opIdMap.put(eachItem.Id,eachItem.NSP_ServiceAssetCategory__c);
                }
            }
            
            if(cat1ListOrderItems.size () > 0 ) {
                processConsumptionSchedule(cat1ListOrderItems, 1, null);
            }
            if(cat2ListOrderItems.size () > 0 ) {
                processConsumptionSchedule(cat2ListOrderItems, 2, null);
            }
            if(cat3ListOrderItems.size () > 0 ) {
                processConsumptionSchedule(cat3ListOrderItems, 3, orderItemPartnerAccounts);
            }
            // call future method to process consumption schedule
           // if(orderItemIdToScholarShipFeeMap.Size() > 0) {
           //     processConsumptionSchedule(JSON.serialize(orderItemIdToScholarShipFeeMap));
           // }
            
            //call asset mapping method
            if(opIdMap != null && opIdMap.size() >0){
               updateAsset(opIdMap);
            }
        }
        
    /**
    * Parse the string in to map and then process map to decide which recird to delete
    * @param OrderItemMapStr string of serialize Map.  
    * @return void             
    *                
    */
        @Future
        public static void processConsumptionSchedule(List<String> orderItemIds, Integer category, List<String> partnerIds ) {
            Set<Id> usageSummaryDeleteSet = new Set<Id>();
            Set<Id> consumptionScheduleDeleteSet = new Set<Id>();
            List<OrderItem> orderItemUpdate = new List<OrderItem>();
           // Map<Id,boolean> orderItemIdToScholarShipFeeMap = (Map<Id,boolean>) JSON.deserialize(OrderItemMapStr, Map<Id,boolean>.class);
            String partnerFormat = 'Partner%'; 
            
            switch on category {
                when 1 {
                    List<SBQQ__OrderItemConsumptionSchedule__c> orderItemCSList = [SELECT Id FROM SBQQ__OrderItemConsumptionSchedule__c WHERE SBQQ__OrderItem__c IN : orderItemIds AND ( SBQQ__MatchingAttribute__c = 'Scholarship' OR SBQQ__MatchingAttribute__c LIKE : partnerFormat )];
					delete orderItemCSList;
                }
                when 2 {
                    List<SBQQ__OrderItemConsumptionSchedule__c> orderItemCSList = [SELECT Id FROM SBQQ__OrderItemConsumptionSchedule__c WHERE SBQQ__OrderItem__c IN : orderItemIds AND SBQQ__MatchingAttribute__c LIKE : partnerFormat];
					delete orderItemCSList;
                }
                when 3 {
                    List<SBQQ__OrderItemConsumptionSchedule__c> orderItemCSList = [SELECT Id FROM SBQQ__OrderItemConsumptionSchedule__c WHERE SBQQ__OrderItem__c IN : orderItemIds AND ( (NOT SBQQ__MatchingAttribute__c LIKE:partnerFormat ) OR SBQQ__ConsumptionSchedule__r.NSP_Partner_Account__c NOT IN : partnerIds) ];
					delete orderItemCSList;
                    //copy matching attribute to Order Product
                    for (SBQQ__OrderItemConsumptionSchedule__c orderItemCS : [SELECT Id, SBQQ__OrderItem__c, SBQQ__MatchingAttribute__c FROM SBQQ__OrderItemConsumptionSchedule__c WHERE SBQQ__OrderItem__c IN: orderItemIds]) {
                        OrderItem oi = new OrderItem();
                        oi.Id = orderItemCS.SBQQ__OrderItem__c;
                        oi.NSP_Matching_Attribute__c = orderItemCS.SBQQ__MatchingAttribute__c;
                        //adding to list
                        orderItemUpdate.add(oi);
                    }
                    
                    NSP_OrderItemTriggerHandler.TriggerDisabled = true;
                    Database.update(orderItemUpdate);
                }
            
            }
            // process map to get two set to delete id.
           /* for(Id eachOrderItemId : orderItemIdToScholarShipFeeMap.keyset()) {
                if(orderItemIdToScholarShipFeeMap.get(eachOrderItemId)) {
                    usageSummaryDeleteSet.add(eachOrderItemId);
                }
                else{
                    consumptionScheduleDeleteSet.add(eachOrderItemId);
                }
            } */
            
            // delete UsageSummary
            //if(usageSummaryDeleteSet.size() > 0) {
            // Delete [SELECT Id from blng__UsageSummary__c WHERE blng__OrderProduct__c IN : usageSummaryDeleteSet AND blng__MatchingAttribute__c = NULL];
            //}
            
            // delete OrderItemConsumptionSchedule of MatchingAttribute Scholarship
           /* if(consumptionScheduleDeleteSet.Size() > 0 ){
                List<SBQQ__OrderItemConsumptionSchedule__c> orderItemCSList = [SELECT Id FROM SBQQ__OrderItemConsumptionSchedule__c WHERE SBQQ__OrderItem__c IN : consumptionScheduleDeleteSet AND ( SBQQ__MatchingAttribute__c = 'Scholarship' OR SBQQ__MatchingAttribute__c LIKE : partnerFormat )];
				delete orderItemCSList;
                
            } */
            
        }
        
    /**
    * Single method for before update operations for Order Item Trigger.
    * @param OrderItemNewMap Map of New OrderItems.
    * @param OrderItemOldMap Map of Old OrderItems.  
    * @return void             
    *                
    */
    public void beforeUpdateDirector(Map<Id, OrderItem> OrderItemNewMap,Map<Id, OrderItem> OrderItemOldMap) {
            Set<String> actionTypeValues = new Set<String>(System.Label.OrderItemRecalcTypes.split(';'));
            Set<Id> statusIdToChange = new Set<Id>();
            Set<Id> paymentMethodChangedLines = new Set<Id>();
            Set<Id> orderLinesToActivate = new Set<Id> ();  
            Set<String> orderLinesForUsage = new Set<String> ();
            Map<Id,Date> opTerminationMap= new Map<Id,Date>();
            List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();

            Map<Id,SBQQ__QuoteLine__c> mapRelatedQuoteLines = new Map<Id,SBQQ__QuoteLine__c>();
            NSP_hotfix_Switch__c hotfixSwitch =  NSP_hotfix_Switch__c.getInstance(UserInfo.getUserId());
            Boolean isEnabled = ( ( ( hotfixSwitch != null ) && hotfixSwitch.IsHoldBillingOrderitem__c ) || Test.isRunningTest() );
            if(isEnabled){
                set<Id> quoteIds = new set<Id>();
                for (OrderItem op : OrderItemNewMap.Values()){
                    if ( ( op.OrderType__c == 'Amendment' )
                        && ( op.order.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION )
                        )
                    {
                        quoteIds.add(op.SBQQ__QuoteLine__c);
                    }
                }
                if(!quoteIds.isEmpty()){
                    for(SBQQ__QuoteLine__c sqLine : [Select Id,(select id,NSP_IsClonedLine__c,NSP_ActionType__c from SBQQ__Clones__r) from SBQQ__QuoteLine__c where Id IN:quoteIds]){
                        for(SBQQ__QuoteLine__c sc: sqLine.SBQQ__Clones__r){
                            mapRelatedQuoteLines.put(sqLine.Id,sc);
                        }
                    }
                }
            }

            for ( OrderItem op : [
                        Select Id, OrderItemNumber, ServiceDate, SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.SBQQ__Description__c,
                        SBQQ__QuoteLine__r.NSP_ActionType__c,SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, OrderId, Order.Status,
                        NSP_Project_Completion_Date__c,NSP_ReCalculation_Status_Internal__c, NSP_Payment_Method__c,SBQQ__Activated__c,
                        Product2.NSP_Partial_Period_Free_Treatment__c, Product2.NSP_Legal_Entity__c,NSP_Additional_Product_Description__c,
                        SBQQ__QuoteLine__r.SBQQ__EndDate__c,SBQQ__OrderedQuantity__c,SBQQ__RevisedOrderProduct__c,SBQQ__BillingFrequency__c,
                        EndDate,Order.Type,SBQQ__QuoteLine__r.NSP_MergeProducts__c
                        FROM OrderItem
                        WHERE Id IN:OrderItemNewMap.keyset()
                    ]
                )
            {
                op.NSP_Product_Description__c = op.SBQQ__QuoteLine__r.SBQQ__Description__c;
                if(OrderItemNewMap.get(op.Id).NSP_Additional_Product_Description__c == null){
                    OrderItemNewMap.get(op.Id).NSP_Additional_Product_Description__c = op.SBQQ__QuoteLine__r.SBQQ__Description__c;
                }
                if(op.SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c == RENEWABLE && op.SBQQ__Activated__c == false && op.SBQQ__BillingFrequency__c=='Annual' && op.SBQQ__QuoteLine__r.SBQQ__EndDate__c!=null && op.EndDate!= op.SBQQ__QuoteLine__r.SBQQ__EndDate__c ) {
                    OrderItemNewMap.get(op.Id).EndDate = op.SBQQ__QuoteLine__r.SBQQ__EndDate__c;
                }
                if(  OrderItemNewMap.get(op.Id).NSP_Project_Completion_Date__c != null && OrderItemNewMap.get(op.Id).NSP_Project_Completion_Date__c != OrderItemOldMap.get(op.id).NSP_Project_Completion_Date__c) {
                        if(actionTypeValues.contains(op.SBQQ__QuoteLine__r.NSP_ActionType__c ) && op.SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c == RENEWABLE	
                            && op.NSP_ReCalculation_Status_Internal__c != 'Processing' && op.NSP_ReCalculation_Status_Internal__c != 'Staged') {
                            statusIdToChange.add(op.Id);   
                        }
                        if( !(actionTypeValues.contains(op.SBQQ__QuoteLine__r.NSP_ActionType__c ) && op.SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c == RENEWABLE)	
                            && op.NSP_ReCalculation_Status_Internal__c == 'Not Applicable' && op.SBQQ__Activated__c == false) {
                            orderLinesToActivate.add(op.Id);   
                        }   
                }
                if(OrderItemNewMap.get(op.Id).NSP_Payment_Method__c != OrderItemOldMap.get(op.id).NSP_Payment_Method__c ) {
                    paymentMethodChangedLines.add(op.id);
                }


                // Free Month Logic to accomodate zero dollar invoice for partial month + free months if applicable
                if(OrderItemNewMap.get(op.Id).SBQQ__Activated__c==true && OrderItemNewMap.get(op.Id).SBQQ__Activated__c!= OrderItemOldMap.get(op.id).SBQQ__Activated__c && OrderItemNewMap.get(op.Id).SBQQ__SubscriptionType__c == 'Evergreen' && OrderItemNewMap.get(op.Id).SBQQ__BillingFrequency__c!='Annual'){
                    Decimal freeMonths = 0;
                        if(OrderItemNewMap.get(op.Id).NSP_Total_Free_Periods__c != null) {
                            freeMonths += OrderItemNewMap.get(op.Id).NSP_Total_Free_Periods__c;
                    }
                    Date currDate = System.Date.today();
                    Date startDate = System.Date.today().toStartOfMonth(); 
                    Date endDate = startDate.addMonths(1).addDays(-1);
                    if(currDate!=startDate && op.Product2.NSP_Partial_Period_Free_Treatment__c == true && op.Order.Type == NSP_CPQConstants.QUOTE_TYPE_NEW) {
                            freeMonths += 1;
                            OrderItemNewMap.get(op.Id).NSP_Partial_Period_Applicable__c = true;
                        }
                    if(freeMonths>0) {
                    OrderItemNewMap.get(op.Id).NSP_Total_Free_Periods__c = freeMonths;
                    OrderItemNewMap.get(op.Id).NSP_Free_Periods_Available__c = freeMonths;
                    orderLinesForUsage.add(op.Id);
                    }
                }
                //Logic to update Scholarship End date on Order Item
                if((OrderItemNewMap.get(op.Id).SBQQ__Status__c != OrderItemOldMap.get(op.id).SBQQ__Status__c) && OrderItemNewMap.get(op.Id).SBQQ__Status__c == NSP_CPQConstants.ORDER_ACTIVATED
                    && OrderItemNewMap.get(op.Id).NSP_Scholarship_Price__c == true) {
                    Date firstDayOfMonth = System.today().addMonths(11).toStartOfMonth();
                    Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);
                    OrderItemNewMap.get(op.Id).NSP_Scholarship_End_Date__c = lastDayOfMonth;
                }   
                //Update asset status to terminated when order product is terminated
                if(OrderItemOldMap.get(op.Id).SBQQ__TerminatedDate__c == null && OrderItemNewMap.get(op.Id).SBQQ__TerminatedDate__c != null){
                    opTerminationMap.put(op.Id,OrderItemNewMap.get(op.Id).SBQQ__TerminatedDate__c);
                }
                //Update Bill through override date for anniversay billing products when invoice is cancelled and rebilled
                if(OrderItemNewMap.get(op.Id).blng__InvoiceRunProcessingStatus__c == NSP_CPQConstants.INVRUN_PENDING && OrderItemNewMap.get(op.Id).blng__BillThroughDateOverride__c == null &&
                  OrderItemNewMap.get(op.Id).NSP_AnniversaryBlngApplicable__c == true && OrderItemNewMap.get(op.Id).SBQQ__BillingFrequency__c == NSP_CPQConstants.BLNGFREQ_ANNUAL && op.Order.Status != NSP_CPQConstants.ORDER_DRAFT && 
                  op.SBQQ__QuoteLine__r.NSP_ActionType__c != 'Amend' && op.SBQQ__QuoteLine__r.NSP_ActionType__c != null){
                  OrderItemNewMap.get(op.Id).blng__BillThroughDateOverride__c = OrderItemNewMap.get(op.Id).EndDate;
              }

                if (isEnabled) {
                    //Added as part of 	DF-05939 to update Hold Billing to "Yes" which helps in not creating Invoice lines for the products which are unchanged during amendment
                    // //Modified as part of 	STY-252638 to update Hold Billing to "Yes" which helps in not creating Invoice lines for the products which are unchanged during amendment
                    Boolean blnIsClonedLn = False;
                    String strActionType = null;
                    if ( !mapRelatedQuoteLines.isempty()
                        && ( mapRelatedQuoteLines.size() > 0 )
                        && mapRelatedQuoteLines.containsKey( op.SBQQ__QuoteLine__c )
                        && ( mapRelatedQuoteLines.get(op.SBQQ__QuoteLine__c) != null )
                        )
                    {
                        strActionType = mapRelatedQuoteLines.get(op.SBQQ__QuoteLine__c).NSP_ActionType__c;
                        blnIsClonedLn = mapRelatedQuoteLines.get(op.SBQQ__QuoteLine__c).NSP_IsClonedLine__c;
                    }
                    if ( ( ( op.SBQQ__QuoteLine__r.NSP_ActionType__c == 'Amend' && blnIsClonedLn == true && strActionType == null ) || op.SBQQ__QuoteLine__r.NSP_ActionType__c == null )
                        && op.SBQQ__BillingFrequency__c == NSP_CPQConstants.BLNGFREQ_ANNUAL
                        && OrderItemNewMap.get(op.Id).blng__NextChargeDate__c != null
                        && op.Order.Type == 'Amendment'
                        && op.SBQQ__QuoteLine__r.NSP_MergeProducts__c == FALSE
                        && op.order.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION
                        )
                    {
                        OrderItemNewMap.get(op.Id).blng__NextChargeDate__c = null;
                        OrderItemNewMap.get(op.Id).blng__HoldBilling__c = 'Yes';
                    }
                } else {
                    if ( ( (op.SBQQ__QuoteLine__r.NSP_ActionType__c == 'Amend' ) || ( op.SBQQ__QuoteLine__r.NSP_ActionType__c == null ) )
                        && op.SBQQ__BillingFrequency__c == NSP_CPQConstants.BLNGFREQ_ANNUAL
                        && OrderItemNewMap.get(op.Id).blng__NextChargeDate__c != null
                        && op.Order.Type == 'Amendment'
                        && op.SBQQ__QuoteLine__r.NSP_MergeProducts__c == FALSE
                        && op.order.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION
                        )
                    {
                        OrderItemNewMap.get(op.Id).blng__NextChargeDate__c = null;
                        OrderItemNewMap.get(op.Id).blng__HoldBilling__c = 'Yes';
                    }
                }
            }
            // STY-03095 - logic to handle order line reprocessing that calls CPQ Quote Calculator API
            if(statusIdToChange.size()>0 || orderLinesToActivate.size()>0){
                for(OrderItem oi : OrderItemNewMap.values()) {
                    
                    if(statusIdToChange.contains(oi.Id)){
                        //oi.NSP_ReCalculation_Status_Internal__c = 'Staged';
                        oi.NSP_Order_Product_Activated__c = true;
                        oi.NSP_ReCalculation_Status_Internal__c = 'Processing';
                        oi.NSP_Override_Start_Date__c = oi.NSP_Project_Completion_Date__c;
                        oi.blng__OverrideInitialRevenueStartDate__c = oi.NSP_Project_Completion_Date__c;
                        oi.blng__OverrideNextBillingDate__c = oi.NSP_Project_Completion_Date__c;
                    }
                     
                }
            }
            // STY-03076 - logic to handle multiple invoice lines grouping
            if(paymentMethodChangedLines.size()>0){
                for(OrderItem oi : OrderItemNewMap.values()) {  
                if(paymentMethodChangedLines.contains(oi.Id)){
                    if(oi.NSP_Payment_Method__c!=null) {
                        oi.blng__InvoiceGroupId__c = (String)oi.NSP_Order_Account__c + (String)oi.blng__BillingAccount__c +oi.NSP_Shipping_Postal_Code__c+(String)oi.NSP_Payment_Method__c;
                    if(oi.SBQQ__QuoteLine__c!=null){
                        quoteLinesToUpdate.add(new SBQQ__QuoteLine__c(Id=oi.SBQQ__QuoteLine__c,NSP_Payment_Method__c=oi.NSP_Payment_Method__c));
                    }
                    }
                }
                }
            }
    
            if (quoteLinesToUpdate.size()>0){ update quoteLinesToUpdate;}
            if (orderLinesForUsage.size()>0){ NSP_OrderItemFreePeriodCalculator.applyZeroUnitPriceToUsageRecords(orderLinesForUsage);}
            if(opTerminationMap != null && opTerminationMap.size() > 0){
                NSP_AssetUpdate.assetTermination(opTerminationMap);
            }
    }
        
        /**
        * Single method for after update operations for Order Item Trigger.
        * @param OrderItemNewMap Map of New OrderItems.
        * @param OrderItemOldMap Map of Old OrderItems.  
        * @return void             
        *                
        */
            
        public void afterUpdateDirector(Map<Id, OrderItem> OrderItemNewMap,Map<Id, OrderItem> OrderItemOldMap)  {
            Set<Id> orderIdSet = new Set<Id>();
            Map<Id,OrderItem> opActiveMap = new Map<Id,OrderItem>();   
            Map<Id,Decimal> activeUserMap = new Map<Id,Decimal>();
            String accId = null; 
                
            for (OrderItem op : [
                        SELECT
                            Id , OrderItemNumber , Order.Type , ServiceDate , SBQQ__QuoteLine__c , SBQQ__QuoteLine__r.NSP_ActionType__c ,
                            SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c , Order.NSP_Transaction_Type__c , OrderId , Order.Status ,
                            Order.NSP_Usage_Products_Count__c , NSP_Project_Completion_Date__c , NSP_ReCalculation_Status_Internal__c ,
                            NSP_Payment_Method__c , SBQQ__Activated__c , blng__LegalEntity__c , SBQQ__Status__c , NSP_ServiceAssetCategory__c ,
                            Order.AccountId
                        FROM OrderItem
                        WHERE ( Id IN :OrderItemNewMap.keyset() )
                    ]
                )
            {
                if(OrderItemOldMap.get(op.id).SBQQ__Status__c != NSP_CPQConstants.ORDER_ACTIVATED
                && OrderItemNewMap.get(op.Id).SBQQ__Status__c == NSP_CPQConstants.ORDER_ACTIVATED && op.Order.Status != NSP_CPQConstants.ORDER_ACTIVATED) {
                    if ( ( op.Order.NSP_Usage_Products_Count__c == 0 && op.Order.Type == NSP_CPQConstants.QUOTE_TYPE_NEW )
                        || op.Order.Type == NSP_CPQConstants.SUPPLEMENTAL
                        || op.Order.Type == NSP_CPQConstants.QUOTE_TYPE_AMENDMENT
                        && op.Order.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION
                        )
                    {
                        orderIdSet.add(op.OrderId);
                    }
                }
               //Set map value which will update service asset
               if(OrderItemNewMap.get(op.Id).NSP_ServiceAssetCategory__c != null && OrderItemNewMap.get(op.Id).NSP_ServiceAsset__c != null && OrderItemNewMap.get(op.Id).SBQQ__Status__c == NSP_CPQConstants.ORDER_ACTIVATED){
                    String rectypeId = Schema.SObjectType.ASSET.getRecordTypeInfosByName().get(OrderItemNewMap.get(op.Id).NSP_ServiceAssetCategory__c).getRecordTypeId();
                    opActiveMap.put(rectypeId,op);
                    if(accId == null){
                        accId = op.Order.AccountId;
                    }
            }
            if(OrderItemOldMap.get(op.id).NSP_TotalUsageQuantity__c != OrderItemNewMap.get(op.id).NSP_TotalUsageQuantity__c && 
               OrderItemNewMap.get(op.id).NSP_TotalUsageQuantity__c != null && OrderItemNewMap.get(op.id).NSP_ServiceAsset__c != null){
                if(OrderItemNewMap.get(op.id).NSP_UsageUpperBound__c > OrderItemNewMap.get(op.id).NSP_TotalUsageQuantity__c){
                    activeUserMap.put(OrderItemNewMap.get(op.id).NSP_ServiceAsset__c,OrderItemNewMap.get(op.id).NSP_UsageUpperBound__c);
                }
                else if(OrderItemNewMap.get(op.id).NSP_UsageUpperBound__c < OrderItemNewMap.get(op.id).NSP_TotalUsageQuantity__c){
                    activeUserMap.put(OrderItemNewMap.get(op.id).NSP_ServiceAsset__c,OrderItemNewMap.get(op.id).NSP_TotalUsageQuantity__c);
                }
            }
            }
            if(orderIdSet.size()>0){
                activateOrder(orderIdSet);
            }
            if(opActiveMap != null && opActiveMap.size()>0 && accId != null){
                NSP_AssetTriggerHandler.TriggerDisabled=true;
                NSP_AssetUpdate.activateAsset(opActiveMap,accId);
                NSP_AssetTriggerHandler.TriggerDisabled=false;
            }
            if(activeUserMap != null && activeUserMap.size() > 0){
                NSP_AssetUpdate.setActiveUsers(activeUserMap);
            }
        }

        /**
        * Method Name : activateOrderProduct 
        * Description : Method to activate order product based on order activation trigger
        * Author : CPQ Team       Date : 09/06/2022
        * @param OrderNewMap Map of New Order. 
        * @param OrderOldMap Map of Old Order.   
        * @return void  
        */
        public static void activateOrder(Set<Id> orderIdSet){
            List<Order> orderUp = new List<Order>();
            AggregateResult[]  groupedResults =  [SELECT COUNT(Id)Ids,OrderId FROM OrderItem WHERE OrderId IN :orderIdSet AND SBQQ__Status__c != :NSP_CPQConstants.ORDER_ACTIVATED GROUP BY OrderId ]; 
           
            if(groupedResults.isEmpty()){
                for(Id ordId : orderIdSet){
                    Order orderToUpdate = new Order();
                    orderToUpdate.ID = ordId;
                    orderToUpdate.Status = NSP_CPQConstants.ORDER_ACTIVATED;
                    orderUp.add(orderToUpdate);
                }
                if(orderUp != null && orderUp.size() > 0){
                    try{
                        database.update(orderUp);
                    }
                    catch(Exception ex){
                        NSP_CustomException.LogException(ex);
                    } 
                }
            }
        }
            /**
* Method Name : populateLegalEntityOnOrderItem 
* Description : Method to copy legal entity from Proudcts to Order Products
* Author : Samba Raju      Date : 10/17/2022
* @param OrderItemNewList List of new OrderItems.   
* @return void  
*/
    public void populateLegalEntityOnOrderItem(List<OrderItem> OrderItemNewList){
        Set<Id> productIds= new Set<Id>();
        for(OrderItem op :OrderItemNewList){
            productIds.add(op.Product2Id);
        }
        Map<Id,Product2> productsMap = new Map<Id,Product2>([Select Id, NSP_Legal_Entity__c FROM Product2 WHERE Id IN:productIds]);
        List<OrderItem> orderItemsToUpdate= new List<OrderItem>();
            for (OrderItem oi : OrderItemNewList) {
                if(productsMap.containskey(oi.Product2Id)){
                    OrderItem op = new OrderItem(Id=oi.Id,blng__LegalEntity__c=productsMap.get(oi.Product2Id).NSP_Legal_Entity__c);
                    orderItemsToUpdate.add(op);
                }
            }
        if(orderItemsToUpdate.size()>0){
            update orderItemsToUpdate;
        }
    }
            /**
* Method Name : updateAsset 
* Description : Method to update order product value on asset
* Author : Raksha     Date : 11/20/2022
* @param opIdMap Map of order product.   
* @return void  
*/
    public static void updateAsset(Map<Id,String> opIdMap){
        Set<Id> optyId = new Set<Id>();
        Set<Id> recordTypeId = new Set<Id>();
        Map<Id,OrderItem> ordProdMap = new Map<Id,OrderItem>();
        List<Asset> updateAssetList = new List<Asset>();
        OrderItem ordObj = new OrderItem();
        String type = null;
        Set<Id> recordTypeSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id,Decimal> quantityMap = new Map<Id,Decimal>();
        List<OrderItem> ordItemList = new List<OrderItem>();
        for ( OrderItem op : [
                    SELECT
                        Id , OrderItemNumber , NSP_QL_ActionType__c , SBQQ__QuoteLine__r.NSP_Quoted_Quantity__c , OrderId ,
                        order.NSP_Transaction_Type__c , Order.Status , SBQQ__QuoteLine__r.NSP_Number_of_Checks__c ,
                        SBQQ__QuoteLine__r.NSP_TCFullUserLicenseQty__c , Order.OpportunityId , NSP_ServiceAssetCategory__c ,
                        SBQQ__QuotedQuantity__c , Order.Type , Order.AccountId , SBQQ__QuoteLine__r.NSP_Number_Of_Boxes__c ,
                        SBQQ__QuoteLine__r.NSP_Number_Of_Users__c
                    FROM OrderItem
                    WHERE ( Id IN :opIdMap.keyset() )
                ]
            )
        {
            if(op.Order.OpportunityId != null){
                optyId.add(op.Order.OpportunityId);
            } 
            if(op.NSP_ServiceAssetCategory__c != null){
                String recType = Schema.SObjectType.ASSET.getRecordTypeInfosByName().get(op.NSP_ServiceAssetCategory__c).getRecordTypeId();
                recordTypeId.add(recType);
                ordProdMap.put(recType,op);
                type = op.Order.Type;
                if(op.SBQQ__QuoteLine__r.NSP_Number_of_Checks__c != null && !quantityMap.containsKey(recType)){
                    quantityMap.put(recType,op.SBQQ__QuoteLine__r.NSP_Number_of_Checks__c);
                } else if(op.SBQQ__QuoteLine__r.NSP_Number_Of_Boxes__c != null && !quantityMap.containsKey(recType)){
                    quantityMap.put(recType,op.SBQQ__QuoteLine__r.NSP_Number_Of_Boxes__c);
                } else if(op.SBQQ__QuoteLine__r.NSP_Number_Of_Users__c != null && !quantityMap.containsKey(recType)){
                    quantityMap.put(recType,op.SBQQ__QuoteLine__r.NSP_Number_Of_Users__c);
                } else if(op.SBQQ__QuoteLine__r.NSP_TCFullUserLicenseQty__c != null && !quantityMap.containsKey(recType)){
                    quantityMap.put(recType,op.SBQQ__QuoteLine__r.NSP_TCFullUserLicenseQty__c);
                } else{
                    quantityMap.put(recType,op.SBQQ__QuoteLine__r.NSP_Quoted_Quantity__c);
                }
                if ( op.NSP_QL_ActionType__c != NSP_CPQConstants.ACTION_AMEND
                    && op.SBQQ__QuoteLine__r.NSP_Quoted_Quantity__c > 0
                    && op.Order.Type == 'Amendment'
                    && op.order.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION
                    )
                {
                    recordTypeSet.add(recType);
                    accountIdSet.add(op.Order.AccountId);
                }
            }    
        }
        if(optyId != null && optyId.size() > 0){
            List<Asset> assetList = [SELECT Id,Status,NSP_Termination_Date__c,RecordTypeId,Opportunity__c,NSP_OrderProduct__c,AccountId FROM Asset WHERE Opportunity__c IN:optyId AND RecordTypeId IN:recordTypeId AND Status != 'Active'];
            for(Asset assetObj: assetList){
                ordObj = new OrderItem();
                if(assetObj.NSP_OrderProduct__c == NULL && assetList.size() > 0){
                    assetObj.NSP_OrderProduct__c = ordProdMap.get(assetObj.RecordTypeId).Id;
                    assetObj.NSP_Current_SaaS_Seats__c = String.valueOf(quantityMap.get(assetObj.RecordTypeId));
                    ordObj.Id = ordProdMap.get(assetObj.RecordTypeId).Id;
                    ordObj.NSP_ServiceAsset__c = assetObj.Id;
                    ordItemList.add(ordObj);
                    updateAssetList.add(assetObj); 
                 }
               
             }     
                if(type == NSP_CPQConstants.QUOTE_TYPE_AMENDMENT && assetList.size() == 0 && accountIdSet != null && accountIdSet.size() > 0){
                    List<Asset> assetAmendList = [SELECT Id,Status,NSP_Termination_Date__c,RecordTypeId,Opportunity__c,NSP_OrderProduct__c,AccountId FROM Asset WHERE AccountId IN:accountIdSet AND RecordTypeId IN:recordTypeSet AND Status != 'Terminated' AND Status != 'Backout'];
                    for(Asset assetObj:assetAmendList){
                        assetObj.NSP_OrderProduct__c = ordProdMap.get(assetObj.RecordTypeId).Id;
                        assetObj.NSP_Current_SaaS_Seats__c = String.valueOf(quantityMap.get(assetObj.RecordTypeId));
                        ordObj.Id = ordProdMap.get(assetObj.RecordTypeId).Id;
                        ordObj.NSP_ServiceAsset__c = assetObj.Id;
                        ordItemList.add(ordObj);
                        updateAssetList.add(assetObj); 
                    }
                }
        }
        
            try{
                if(ordItemList != null && ordItemList.size() > 0){
                    database.update(ordItemList);
                }
                if(updateAssetList != null && updateAssetList.size() > 0){
                    database.update(updateAssetList);
                }
            } catch(Exception ex){
                NSP_CustomException.LogException(ex);
            }
    }

            /**
* Method Name : retrieveACHActivePaymentMethods 
* Description : Method to retrieve the ACH Active Payment Methods
* Author : CPQ Team     Date : 11/20/2022
* @param billingAccounts Set of Billing Account.   
* @return blng__PaymentMethod__c  
*/   
    private static Map<String,blng__PaymentMethod__c> retrieveACHActivePaymentMethods(Set<String> billingAccounts){
        Map<String,blng__PaymentMethod__c> billingActPaymentMap= new Map<String,blng__PaymentMethod__c>();
        for(blng__PaymentMethod__c method :[SELECT Id,blng__Account__c FROM blng__PaymentMethod__c WHERE blng__Account__c IN:billingAccounts AND NSP_Active_Custom__c=TRUE]){
            billingActPaymentMap.put(method.blng__Account__c,method);
        }
        return billingActPaymentMap;
    }
}