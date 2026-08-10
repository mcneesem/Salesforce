// Represents the OrderItem trigger helper which handles all the logic.
public class NSP_OrderItemTriggerHelper {
    // test w/ NSP_OrderItemTriggerHelperTest, NSP_OrderTriggerHelperTest (77%)
    // test w/ NSP_OrderItemTriggerHelperTest (77%)
    // test w/ NSP_OrderTriggerHelperTest (22%)

    static final string RENEWABLE = 'Renewable';
    static final String LASSO_PARTNERNAME = System.Label.NSP_Lasso_PartnerName;

    //
    // Single method for before insert operations for Order Item Trigger.
    // @param newList List of New OrderItems.
    // @return void
    //
    public void populateFieldValuesOnInsert( List<OrderItem> orderItemNewList ) {
        List<String> orderIds = new List<String> ();
        Set<String> billingAccounts = new Set<String>();
        for ( OrderItem oli : orderItemNewList ) {
            if ( ( oli.OrderId != null ) && ( oli.blng__BillingAccount__c == null ) ) {
                orderIds.add( oli.OrderId );
            }
            oli.blng__InvoiceGrouping__c = 'Invoice Group ID;'+'Legal Entity';
            if ( oli.NSP_Scholarship_Price__c == true ) {
                oli.NSP_Scholarship_End_Date__c = System.today().addMonths( 23 ).toStartOfMonth();
            }
        }
        if ( orderIds.size() > 0 ) {
            Map<Id,Order> ordersMap = new Map<Id,Order>(
                [
                    SELECT
                        Id ,
                        Status ,
                        AccountId ,
                        NSP_Billing_Account__c ,
                        ShippingPostalCode ,
                        NSP_Partner__r.Name,blng__BillingAccount__c
                    FROM Order
                    WHERE ( Id IN :orderIds )
                ]
            );
            for ( OrderItem oi : orderItemNewList ) {
                if ( orderIds.contains( oi.OrderId ) ) {
                    if ( ordersMap.containsKey( oi.OrderId ) ) {
                        Order currOrder = ordersMap.get( oi.OrderId );
                        if ( currOrder.blng__BillingAccount__c != null ) {
                            oi.blng__BillingAccount__c = currOrder.blng__BillingAccount__c;
                        } else {
                            oi.blng__BillingAccount__c = currOrder.AccountId;
                        }
                        billingAccounts.add( oi.blng__BillingAccount__c );
                    }
                }
            }
            Map<String,blng__PaymentMethod__c> billingActPaymentMap=retrieveACHActivePaymentMethods( billingAccounts );
            for ( OrderItem oi : orderItemNewList ) {
                Order currOrder = ordersMap.get( oi.OrderId );
                if ( ordersMap.containsKey( oi.OrderId )
                    && ( oi.blng__BillingAccount__c != null )
                    && ( billingActPaymentMap != null )
                    && String.isNotBlank( oi.NSP_Preferred_Payment_Method__c )
                    )
                {
                    String key = oi.blng__BillingAccount__c + oi.NSP_Preferred_Payment_Method__c;
                    if ( billingActPaymentMap.containsKey( key ) ) {
                        blng__PaymentMethod__c method = billingActPaymentMap.get( key );
                        if ( ( method != null )
                            && ( oi.NSP_Preferred_Payment_Method__c == method.Payment_Method_Type__c )
                            )
                        {
                            oi.NSP_Payment_Method__c = method.Id;
                        }
                    }
                }
                if ( ( currOrder.NSP_Partner__r.Name != LASSO_PARTNERNAME )
                    && ( oi.Preserve_Invoice_Group_ID__c == false )
                    )
                {
                    oi.blng__InvoiceGroupId__c = ''
                        + (String)currOrder.AccountId
                        + (String)currOrder.NSP_Billing_Account__c
                        + (String)currOrder.ShippingPostalCode
                        + (String)oi.NSP_Payment_Method__c
                        ;
                }
            }
        }
    }

    //
    // Iterates throught the list of new OrderItem and passes the required attributes to other methods.
    // @param newList List of New OrderItems.
    // @return void
    //
    public void processOrderItemForScholarshipCS( Map<Id,OrderItem> newMap ) {
        Map<Id,String> opIdMap = new Map<Id,String>();
        for ( OrderItem eachItem : newMap.values() ) {
            if ( ( eachItem.NSP_ServiceAssetCategory__c != null )
                && ( eachItem.NSP_ServiceAssetCategory__c != NSP_CPQConstants.HARDWARE_ASSET )
                && ( eachItem.NSP_ServiceAsset__c == null )
                )
            {
                opIdMap.put(
                    eachItem.Id ,
                    eachItem.NSP_ServiceAssetCategory__c
                );
            }
        }
        //call asset mapping method
        if ( ( opIdMap != null ) && !opIdMap.isEmpty() ) {
            NSP_OrderItemTriggerHelper.updateAsset( opIdMap );
        }
    }

    // DEPRECATED
    @future
    public static void processConsumptionSchedule( List<String> orderItemIds , Integer category , List<String> partnerIds ) {
        Set<Id> usageSummaryDeleteSet = new Set<Id>();
        Set<Id> consumptionScheduleDeleteSet = new Set<Id>();
        List<OrderItem> orderItemUpdate = new List<OrderItem>();
        String partnerFormat = 'Partner%';
        switch on category {
            when 1 {
                List<SBQQ__OrderItemConsumptionSchedule__c> orderItemCSList = [
                    SELECT Id
                    FROM SBQQ__OrderItemConsumptionSchedule__c
                    WHERE (
                        SBQQ__OrderItem__c IN :orderItemIds
                        AND (
                            SBQQ__MatchingAttribute__c = 'Scholarship'
                            OR SBQQ__MatchingAttribute__c LIKE :partnerFormat
                            OR Name Like 'Seasonal%'
                        )
                    )
                ];
                delete orderItemCSList;
            }
            when 2 {
                List<SBQQ__OrderItemConsumptionSchedule__c> orderItemCSList = [
                    SELECT Id
                    FROM SBQQ__OrderItemConsumptionSchedule__c
                    WHERE (
                        SBQQ__OrderItem__c IN :orderItemIds
                        AND (
                            SBQQ__MatchingAttribute__c LIKE :partnerFormat
                            OR Name like 'Seasonal%'
                        )
                    )
                ];
                delete orderItemCSList;
            }
            when 4 {
                List<SBQQ__OrderItemConsumptionSchedule__c> oicsList = [
                    SELECT Id , Name, SBQQ__OrderItem__r.Seasonal_Pricing__c
                    FROM SBQQ__OrderItemConsumptionSchedule__c
                    WHERE SBQQ__OrderItem__c IN :orderItemIds
                ];
                List<SBQQ__OrderItemConsumptionSchedule__c> deleteList = new List<SBQQ__OrderItemConsumptionSchedule__c>();
                for(SBQQ__OrderItemConsumptionSchedule__c oics: oicsList){
                    String oicsName = oics.Name;
                    String oiSeasonalName = oics.SBQQ__OrderItem__r.Seasonal_Pricing__c;
                    if(oicsName.contains('Seasonal')){
                        if(oicsName != oiSeasonalName){
                            deleteList.add(oics);
                        }
                    }else{
                        deleteList.add(oics);
                    }
                }
                if(deleteList.size() > 0){
                    delete deleteList;
                }
            }
        }
    }

    //
    // Single method for before update operations for Order Item Trigger.
    // @param OrderItemNewMap Map of New OrderItems.
    // @param OrderItemOldMap Map of Old OrderItems.
    // @return void
    //
    public void beforeUpdateDirector( Map<Id,OrderItem> orderItemNewMap , Map<Id,OrderItem> orderItemOldMap ) {
        Set<String> actionTypeValues = new Set<String>(System.Label.OrderItemRecalcTypes.split(';'));
        Set<Id> statusIdToChange = new Set<Id>();
        Set<Id> paymentMethodChangedLines = new Set<Id>();
        Set<Id> orderLinesToActivate = new Set<Id> ();
        Set<String> orderLinesForUsage = new Set<String>();
        Map<Id,Date> opTerminationMap= new Map<Id,Date>();
        List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();

        Map<Id,SBQQ__QuoteLine__c> mapRelatedQuoteLines = new Map<Id,SBQQ__QuoteLine__c>();
        NSP_hotfix_Switch__c hotfixSwitch =  NSP_hotfix_Switch__c.getInstance(UserInfo.getUserId());
        Boolean isEnabled = ( ( ( hotfixSwitch != null ) && hotfixSwitch.IsHoldBillingOrderitem__c ) || Test.isRunningTest() );
        if(isEnabled){
            set<Id> quoteIds = new set<Id>();
            for ( OrderItem op : orderItemNewMap.values() ) {
                if ( ( op.OrderType__c == 'Amendment' )
                    && ( op.order.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION )
                    )
                {
                    quoteIds.add(op.SBQQ__QuoteLine__c);
                }
            }
            if(!quoteIds.isEmpty()){
                for ( SBQQ__QuoteLine__c sqLine : [
                            SELECT Id , ( SELECT Id , NSP_IsClonedLine__c , NSP_ActionType__c FROM SBQQ__Clones__r )
                            FROM SBQQ__QuoteLine__c
                            WHERE ( Id IN :quoteIds )
                        ]
                    )
                {
                    for(SBQQ__QuoteLine__c sc: sqLine.SBQQ__Clones__r){
                        mapRelatedQuoteLines.put(sqLine.Id,sc);
                    }
                }
            }
        }

        for ( OrderItem op : [
                    SELECT
                        Id , OrderItemNumber , ServiceDate ,
                        SBQQ__QuoteLine__c , SBQQ__QuoteLine__r.SBQQ__Description__c ,
                        SBQQ__QuoteLine__r.NSP_ActionType__c , SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c ,
                        OrderId , Order.Status , NSP_Project_Completion_Date__c ,
                        NSP_ReCalculation_Status_Internal__c , NSP_Payment_Method__c , SBQQ__Activated__c ,
                        Product2.NSP_Partial_Period_Free_Treatment__c , Product2.NSP_Legal_Entity__c ,
                        NSP_Additional_Product_Description__c , SBQQ__QuoteLine__r.SBQQ__EndDate__c ,
                        SBQQ__OrderedQuantity__c , SBQQ__RevisedOrderProduct__c , SBQQ__BillingFrequency__c ,
                        EndDate , Order.Type , Order.NSP_Transaction_Type__c ,
                        SBQQ__QuoteLine__r.NSP_MergeProducts__c , Prevent_Product_Description_Update__c
                    FROM OrderItem
                    WHERE ( Id IN :orderItemNewMap.keyset() )
                ]
            )
        {
            op.NSP_Product_Description__c = op.SBQQ__QuoteLine__r.SBQQ__Description__c;
            if ( ( orderItemNewMap.get(op.Id).NSP_Additional_Product_Description__c == null )
                && !orderItemNewMap.get(op.Id).Prevent_Product_Description_Update__c
                )
            {
                orderItemNewMap.get(op.Id).NSP_Additional_Product_Description__c = op.SBQQ__QuoteLine__r.SBQQ__Description__c;
            }
            if(op.SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c == RENEWABLE && op.SBQQ__Activated__c == false && op.SBQQ__BillingFrequency__c=='Annual' && op.SBQQ__QuoteLine__r.SBQQ__EndDate__c!=null && op.EndDate!= op.SBQQ__QuoteLine__r.SBQQ__EndDate__c ) {
                orderItemNewMap.get(op.Id).EndDate = op.SBQQ__QuoteLine__r.SBQQ__EndDate__c;
            }
            if ( ( orderItemNewMap.get( op.Id ).NSP_Override_Start_Date__c != null )
                && ( orderItemNewMap.get( op.Id ).NSP_Override_Start_Date__c != orderItemOldMap.get( op.Id ).NSP_Override_Start_Date__c )
                )
            {
                if ( actionTypeValues.contains(op.SBQQ__QuoteLine__r.NSP_ActionType__c )
                    && op.SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c == RENEWABLE
                    && op.NSP_ReCalculation_Status_Internal__c != 'Processing'
                    && op.NSP_ReCalculation_Status_Internal__c != 'Staged'
                    )
                {
                    statusIdToChange.add(op.Id);
                }
                if ( !(actionTypeValues.contains(op.SBQQ__QuoteLine__r.NSP_ActionType__c ) && op.SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c == RENEWABLE)
                    && op.NSP_ReCalculation_Status_Internal__c == 'Not Applicable'
                    && op.SBQQ__Activated__c == false
                    )
                {
                    orderLinesToActivate.add(op.Id);
                }
            }
            if ( orderItemNewMap.get(op.Id).NSP_Payment_Method__c != orderItemOldMap.get(op.id).NSP_Payment_Method__c ) {
                paymentMethodChangedLines.add(op.id);
            }


            // Free Month Logic to accomodate zero dollar invoice for partial month + free months if applicable
            if ( orderItemNewMap.get(op.Id).SBQQ__Activated__c == true
                && orderItemNewMap.get(op.Id).SBQQ__Activated__c!= orderItemOldMap.get(op.id).SBQQ__Activated__c
                && orderItemNewMap.get(op.Id).SBQQ__SubscriptionType__c == 'Evergreen'
                && orderItemNewMap.get(op.Id).SBQQ__BillingFrequency__c!='Annual'
                )
            {
                Decimal freeMonths = 0;
                if ( orderItemNewMap.get(op.Id).NSP_Total_Free_Periods__c != null ) {
                    freeMonths += orderItemNewMap.get(op.Id).NSP_Total_Free_Periods__c;
                }
                Date currDate = System.Date.today();
                Date startDate = System.Date.today().toStartOfMonth();
                Date endDate = startDate.addMonths(1).addDays(-1);
                if ( currDate!=startDate
                    && op.Product2.NSP_Partial_Period_Free_Treatment__c == true
                    && op.Order.Type == NSP_CPQConstants.QUOTE_TYPE_NEW
                    )
                {
                    freeMonths += 1;
                    orderItemNewMap.get(op.Id).NSP_Partial_Period_Applicable__c = true;
                }
                if ( freeMonths > 0 ) {
                    orderItemNewMap.get(op.Id).NSP_Total_Free_Periods__c = freeMonths;
                    orderItemNewMap.get(op.Id).NSP_Free_Periods_Available__c = freeMonths;
                    orderLinesForUsage.add(op.Id);
                }
            }
            //Logic to update Scholarship End date on Order Item
            if ( ( orderItemNewMap.get(op.Id).SBQQ__Status__c != orderItemOldMap.get(op.id).SBQQ__Status__c )
                && ( orderItemNewMap.get(op.Id).SBQQ__Status__c == NSP_CPQConstants.ORDER_ACTIVATED )
                && ( orderItemNewMap.get(op.Id).NSP_Scholarship_Price__c == true )
                )
            {
                Date firstDayOfMonth = System.today().addMonths(11).toStartOfMonth();
                Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);
                orderItemNewMap.get(op.Id).NSP_Scholarship_End_Date__c = lastDayOfMonth;
            }
            //Update asset status to terminated when order product is terminated
            if ( orderItemOldMap.get(op.Id).SBQQ__TerminatedDate__c == null
                && orderItemNewMap.get(op.Id).SBQQ__TerminatedDate__c != null
                )
            {
                opTerminationMap.put(op.Id,orderItemNewMap.get(op.Id).SBQQ__TerminatedDate__c);
            }
            //Update Bill through override date for anniversay billing products when invoice is cancelled and rebilled

            if ( orderItemNewMap.get(op.Id).blng__InvoiceRunProcessingStatus__c == NSP_CPQConstants.INVRUN_PENDING
                && orderItemNewMap.get(op.Id).blng__BillThroughDateOverride__c == null
                && orderItemNewMap.get(op.Id).NSP_AnniversaryBlngApplicable__c == true
                && orderItemNewMap.get(op.Id).SBQQ__BillingFrequency__c == NSP_CPQConstants.BLNGFREQ_ANNUAL
                && op.Order.Status != NSP_CPQConstants.ORDER_DRAFT
                && op.SBQQ__QuoteLine__r.NSP_ActionType__c != 'Amend'
                && op.SBQQ__QuoteLine__r.NSP_ActionType__c != null
                )
            {
                orderItemNewMap.get(op.Id).blng__BillThroughDateOverride__c = orderItemNewMap.get(op.Id).EndDate;
            }

            if (isEnabled) {
                //Added as part of DF-05939 to update Hold Billing to "Yes" which helps in not creating Invoice lines for the products which are unchanged during amendment
                // //Modified as part of STY-252638 to update Hold Billing to "Yes" which helps in not creating Invoice lines for the products which are unchanged during amendment
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
                    && orderItemNewMap.get(op.Id).blng__NextChargeDate__c != null
                    && op.Order.Type == 'Amendment'
                    && op.SBQQ__QuoteLine__r.NSP_MergeProducts__c == FALSE
                    && op.order.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION
                    )
                {
                    orderItemNewMap.get(op.Id).blng__NextChargeDate__c = null;
                    orderItemNewMap.get(op.Id).blng__HoldBilling__c = 'Yes';
                }
            } else {
                if ( ( (op.SBQQ__QuoteLine__r.NSP_ActionType__c == 'Amend' ) || ( op.SBQQ__QuoteLine__r.NSP_ActionType__c == null ) )
                    && op.SBQQ__BillingFrequency__c == NSP_CPQConstants.BLNGFREQ_ANNUAL
                    && orderItemNewMap.get(op.Id).blng__NextChargeDate__c != null
                    && op.Order.Type == 'Amendment'
                    && op.SBQQ__QuoteLine__r.NSP_MergeProducts__c == FALSE
                    && op.order.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION
                    )
                {
                    orderItemNewMap.get(op.Id).blng__NextChargeDate__c = null;
                    orderItemNewMap.get(op.Id).blng__HoldBilling__c = 'Yes';
                }
            }
        }
        // STY-03095 - logic to handle order line reprocessing that calls CPQ Quote Calculator API
        if ( !statusIdToChange.isEmpty() || !orderLinesToActivate.isEmpty() ) {
            for ( OrderItem oi : orderItemNewMap.values() ) {
                if ( statusIdToChange.contains(oi.Id) ) {
                    oi.NSP_Order_Product_Activated__c = true;
                    oi.NSP_ReCalculation_Status_Internal__c = 'Processing';
                    oi.blng__OverrideInitialRevenueStartDate__c = oi.NSP_Override_Start_Date__c;
                    oi.blng__OverrideNextBillingDate__c = oi.NSP_Override_Start_Date__c;
                    oi.blng__NextChargeDate__c = oi.NSP_Override_Start_Date__c;
                }
            }
        }
        // STY-03076 - logic to handle multiple invoice lines grouping
        if ( paymentMethodChangedLines.size() > 0 ) {
            for ( OrderItem oi : orderItemNewMap.values() ) {
                if ( paymentMethodChangedLines.contains( oi.Id )
                    && ( oi.NSP_Payment_Method__c != null )
                    && ( oi.Preserve_Invoice_Group_ID__c == false )
                    )
                {
                    oi.blng__InvoiceGroupId__c = (String)oi.NSP_Order_Account__c
                        + (String)oi.blng__BillingAccount__c
                        + oi.NSP_Shipping_Postal_Code__c
                        + (String)oi.NSP_Payment_Method__c
                        ;
                    if ( oi.SBQQ__QuoteLine__c != null ) {
                        quoteLinesToUpdate.add(
                            new SBQQ__QuoteLine__c(
                                Id=oi.SBQQ__QuoteLine__c ,
                                NSP_Payment_Method__c=oi.NSP_Payment_Method__c
                            )
                        );
                    }
                }
            }
        }
        try {
            if ( quoteLinesToUpdate.size() > 0 ) {
                update quoteLinesToUpdate; // throws ~ System.ListException: Duplicate id in list: a6oXXXXXXXXXXXXXXX
            }
            if ( orderLinesForUsage.size() > 0 ) {
                NSP_OrderItemFreePeriodCalculator.applyZeroUnitPriceToUsageRecords( orderLinesForUsage );
            }
            if ( ( opTerminationMap != null )
                && ( opTerminationMap.size() > 0 )
                )
            {
                NSP_AssetUpdate.assetTermination( opTerminationMap );
            }
        } catch ( Exception e ) {
            NSP_OrderItemTriggerHelper.handleException( e , 'beforeUpdateDirector' );
        }
    }

    //
    // Single method for after update operations for Order Item Trigger.
    // @param OrderItemNewMap Map of New OrderItems.
    // @param OrderItemOldMap Map of Old OrderItems.
    // @return void
    //
    public void afterUpdateDirector( Map<Id,OrderItem> OrderItemNewMap , Map<Id,OrderItem> OrderItemOldMap ) {
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
            orderIdSet = this.collectOrderIdsToActivate(
                op ,
                OrderItemNewMap.get( op.Id ) ,
                OrderItemOldMap.get( op.Id ) ,
                orderIdSet
            );
            //Set map value which will update service asset
            if ( OrderItemNewMap.get(op.Id).NSP_ServiceAssetCategory__c != null
                && OrderItemNewMap.get(op.Id).NSP_ServiceAsset__c != null
                && OrderItemNewMap.get(op.Id).SBQQ__Status__c == NSP_CPQConstants.ORDER_ACTIVATED
                )
            {
                String rectypeId = NSP_GenericRecordType.getRecordTypeId('Asset', OrderItemNewMap.get(op.Id).NSP_ServiceAssetCategory__c);
                opActiveMap.put(rectypeId,op);
                if(accId == null){
                    accId = op.Order.AccountId;
                }
            }
            if( OrderItemOldMap.get(op.id).NSP_TotalUsageQuantity__c != OrderItemNewMap.get(op.id).NSP_TotalUsageQuantity__c
                && OrderItemNewMap.get(op.id).NSP_TotalUsageQuantity__c != null
                && OrderItemNewMap.get(op.id).NSP_ServiceAsset__c != null
                && OrderItemNewMap.get(op.id).Prevent_Asset_Updates__c == false
                && OrderItemNewMap.get(op.id).OrderType__c != 'Supplemental'
                )
            {
                if(OrderItemNewMap.get(op.id).NSP_UsageUpperBound__c > OrderItemNewMap.get(op.id).NSP_TotalUsageQuantity__c){
                    activeUserMap.put(OrderItemNewMap.get(op.id).NSP_ServiceAsset__c,OrderItemNewMap.get(op.id).NSP_UsageUpperBound__c);
                }
                else if(OrderItemNewMap.get(op.id).NSP_UsageUpperBound__c < OrderItemNewMap.get(op.id).NSP_TotalUsageQuantity__c){
                    activeUserMap.put(OrderItemNewMap.get(op.id).NSP_ServiceAsset__c,OrderItemNewMap.get(op.id).NSP_TotalUsageQuantity__c);
                }
            }
        }
        if ( !orderIdSet.isEmpty() ) {
            NSP_OrderItemTriggerHelper.activateOrder( orderIdSet );
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

    private Set<Id> collectOrderIdsToActivate(
        OrderItem record ,
        OrderItem recordNew ,
        OrderItem recordOld ,
        Set<Id> orderIdSet
        )
    {
        if ( orderIdSet == null ) {
           orderIdSet = new Set<Id>();
        }
        if ( ( recordOld.SBQQ__Status__c != NSP_CPQConstants.ORDER_ACTIVATED )
            && ( recordNew.SBQQ__Status__c == NSP_CPQConstants.ORDER_ACTIVATED )
            && ( record.Order.Status != NSP_CPQConstants.ORDER_ACTIVATED )
            && record.Order.Status != NSP_CPQConstants.ORDER_DRAFT
            && ( ( ( record.Order.NSP_Usage_Products_Count__c == 0 ) && ( record.Order.Type == NSP_CPQConstants.QUOTE_TYPE_NEW ) )
                || ( record.Order.Type == NSP_CPQConstants.SUPPLEMENTAL )
                || ( ( record.Order.Type == NSP_CPQConstants.QUOTE_TYPE_AMENDMENT )
                    && ( record.Order.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION )
                    )
                )
            )
        {
            orderIdSet.add( record.OrderId );
        }
        return  orderIdSet;
    }

    //
    // Method Name : activateOrderProduct
    // Description : Method to activate order product based on order activation trigger
    // Author : CPQ Team
    // Date : 09/06/2022
    // @param OrderNewMap Map of New Order.
    // @param OrderOldMap Map of Old Order.
    // @return void
    //
    public static void activateOrder( Set<Id> orderIdSet ) {
        List<Order> orderUp = new List<Order>();
        AggregateResult[] groupedResults = [
            SELECT
                COUNT(Id)Ids ,
                OrderId
            FROM OrderItem
            WHERE (
                ( OrderId IN :orderIdSet )
                AND ( SBQQ__Status__c != :NSP_CPQConstants.ORDER_ACTIVATED )
            )
            GROUP BY OrderId
        ];
        if ( !groupedResults.isEmpty() ) {
            Set<Id> okOrderIds = new Set<Id>();
            for ( AggregateResult ar : groupedResults ) {
                okOrderIds.add( (Id)ar.get( 'OrderId' ) );
            }
            orderIdSet.removeAll( okOrderIds );
        }
        if ( !orderIdSet.isEmpty() ) {
            for ( Id ordId : orderIdSet ) {
                Order orderToUpdate = new Order();
                orderToUpdate.ID = ordId;
                orderToUpdate.Status = NSP_CPQConstants.ORDER_ACTIVATED;
                orderUp.add( orderToUpdate );
            }
        }
        if ( ( orderUp != null ) && !orderUp.isEmpty() ) {
            try {
                database.update( orderUp );
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    NSP_OrderItemTriggerHelper.class.getName() ,
                    'activateOrder' ,
                    e
                );
            }
        }
    }

    //
    // Method Name : populateLegalEntityOnOrderItem
    // Description : Method to copy legal entity from Proudcts to Order Products
    // Author : Samba Raju      Date : 10/17/2022
    //
    public void populateLegalEntityOnOrderItem( List<OrderItem> orderItemNewList ) {
        Set<Id> productIds= new Set<Id>();
        for ( OrderItem op : orderItemNewList ) {
            productIds.add( op.Product2Id );
        }
        Map<Id,Product2> productsMap = new Map<Id,Product2>(
            [
                SELECT Id , NSP_Legal_Entity__c
                FROM Product2
                WHERE ( Id IN :productIds )
            ]
        );
        List<OrderItem> orderItemsToUpdate= new List<OrderItem>();
            for ( OrderItem oi : orderItemNewList ) {
                if ( productsMap.containskey( oi.Product2Id )
                    && ( productsMap.get( oi.Product2Id ) != null )
                    )
                {
                    OrderItem op = new OrderItem(
                        Id=oi.Id ,
                        blng__LegalEntity__c=productsMap.get( oi.Product2Id ).NSP_Legal_Entity__c
                    );
                    orderItemsToUpdate.add( op );
                }
            }
        if ( !orderItemsToUpdate.isEmpty() ) {
            update orderItemsToUpdate;
        }
    }

    //
    // Method Name : updateAsset
    // Description : Method to update order product value on asset
    // Author : Raksha     Date : 11/20/2022
    // @param opIdMap Map of order product.
    // @return void
    //
    public static void updateAsset(Map<Id,String> opIdMap){
        Set<Id> optyId = new Set<Id>();
        Set<Id> recordTypeId = new Set<Id>();
        Map<Id,OrderItem> ordProdMap = new Map<Id,OrderItem>();
        List<Asset> updateAssetList = new List<Asset>();
        OrderItem ordObj = new OrderItem();
        String type = null;
        Set<Id> recordTypeSet = new Set<Id>();
        Set<Id> retRecordTypeSet = new Set<Id>();
        List<String> retirementRecordTypeName = new List<String>{'RET Choice','RET WO'};
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id,Decimal> quantityMap = new Map<Id,Decimal>();
        List<OrderItem> ordItemList = new List<OrderItem>();
        for ( OrderItem op : [
                    SELECT
                        Id , NSP_Action_Type__c,OrderItemNumber , NSP_QL_ActionType__c , SBQQ__QuoteLine__r.NSP_Quoted_Quantity__c , OrderId ,
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
                String recType = NSP_GenericRecordType.getRecordTypeId('Asset', op.NSP_ServiceAssetCategory__c);
                if(!retirementRecordTypeName.contains(op.NSP_ServiceAssetCategory__c)){
                    recordTypeId.add(recType);
                }else{
                    retRecordTypeSet.add(recType);
                    accountIdSet.add(op.Order.AccountId);
                }
                ordProdMap.put(recType,op);
                type = op.Order.Type;
                if ( op.SBQQ__QuoteLine__r.NSP_Number_of_Checks__c != null
                    && !quantityMap.containsKey(recType)
                    )
                {
                    quantityMap.put(recType,op.SBQQ__QuoteLine__r.NSP_Number_of_Checks__c);
                } else if (
                    op.SBQQ__QuoteLine__r.NSP_Number_Of_Boxes__c != null
                    && !quantityMap.containsKey(recType)
                    )
                {
                    quantityMap.put(recType,op.SBQQ__QuoteLine__r.NSP_Number_Of_Boxes__c);
                } else if (
                    op.SBQQ__QuoteLine__r.NSP_Number_Of_Users__c != null
                    && !quantityMap.containsKey(recType)
                    )
                {
                    quantityMap.put(recType,op.SBQQ__QuoteLine__r.NSP_Number_Of_Users__c);
                } else if (
                    op.SBQQ__QuoteLine__r.NSP_TCFullUserLicenseQty__c != null
                    && !quantityMap.containsKey(recType)
                    )
                {
                    quantityMap.put(recType,op.SBQQ__QuoteLine__r.NSP_TCFullUserLicenseQty__c);
                } else {
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
        if ( optyId != null && optyId.size() > 0 ) {
            List<Asset> assetList = new List<Asset>();
            if ( !retRecordTypeSet.isEmpty() ) {
                assetList = [
                    SELECT Id , Status , NSP_Termination_Date__c , RecordTypeId , Opportunity__c , NSP_OrderProduct__c , AccountId
                    FROM Asset
                    WHERE (
                        AccountId IN :accountIdSet
                        AND RecordTypeId IN :retRecordTypeSet
                    )
                ];
            }else{
                assetList = [
                    SELECT Id , Status , NSP_Termination_Date__c , RecordTypeId , Opportunity__c , NSP_OrderProduct__c , AccountId
                    FROM Asset
                    WHERE (
                        Opportunity__c IN :optyId
                        AND RecordTypeId IN :recordTypeId
                        AND Status != 'Active'
                    )
                ];
            }
            for(Asset assetObj: assetList){
                ordObj = new OrderItem();
                if ( !assetList.isEmpty()
                    && ( ( assetObj.NSP_OrderProduct__c == null ) || !retRecordTypeSet.isEmpty() )
                    )
                {
                    assetObj.NSP_OrderProduct__c = ordProdMap.get(assetObj.RecordTypeId).Id;
                    assetObj.NSP_Current_SaaS_Seats__c = String.valueOf(quantityMap.get(assetObj.RecordTypeId));
                    ordObj.Id = ordProdMap.get(assetObj.RecordTypeId).Id;
                    ordObj.NSP_ServiceAsset__c = assetObj.Id;
                    ordItemList.add(ordObj);
                    updateAssetList.add(assetObj);
                }
            }
            if ( type == NSP_CPQConstants.QUOTE_TYPE_AMENDMENT
                && assetList.size() == 0
                && accountIdSet != null
                && accountIdSet.size() > 0
                )
            {
                List<Asset> assetAmendList = [
                    SELECT
                        Id , Status , NSP_Termination_Date__c , RecordTypeId ,
                        RecordType.Name , Opportunity__c , NSP_OrderProduct__c , AccountId
                    FROM Asset
                    WHERE (
                        AccountId IN :accountIdSet
                        AND RecordTypeId IN :recordTypeSet
                    )
                ];
                for ( Asset assetObj : assetAmendList ) {
                    if ( retirementRecordTypeName.contains(assetObj.RecordType.Name)
                        || ( !retirementRecordTypeName.contains(assetObj.RecordType.Name)
                            && assetObj.Status != 'Terminated'
                            && assetObj.Status != 'Backout'
                            )
                        )
                    {
                        assetObj.NSP_OrderProduct__c = ordProdMap.get(assetObj.RecordTypeId).Id;
                        assetObj.NSP_Current_SaaS_Seats__c = String.valueOf(quantityMap.get(assetObj.RecordTypeId));
                        ordObj.Id = ordProdMap.get(assetObj.RecordTypeId).Id;
                        ordObj.NSP_ServiceAsset__c = assetObj.Id;
                        ordItemList.add(ordObj);
                        updateAssetList.add(assetObj);
                    }
                }
            }
            try {
                if ( ( ordItemList != null ) && ( ordItemList.size() > 0 ) ) {
                    database.update( ordItemList );
                }
                if ( ( updateAssetList != null ) && ( updateAssetList.size() > 0 ) ) {
                    database.update( updateAssetList );
                }
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    NSP_OrderItemTriggerHelper.class.getName() ,
                    'updateAsset' ,
                    e
                );
            }
        }
    }

    //
    // Method Name : retrieveACHActivePaymentMethods
    // Description : Method to retrieve the ACH Active Payment Methods
    // Author : CPQ Team     Date : 11/20/2022
    //
    private static Map<String,blng__PaymentMethod__c> retrieveACHActivePaymentMethods( Set<String> billingAccounts ) {
        Map<String,blng__PaymentMethod__c> billingActPaymentMap = new Map<String,blng__PaymentMethod__c>();
        for ( blng__PaymentMethod__c method : [
                    SELECT Id , blng__Account__c , Payment_Method_Type__c
                    FROM blng__PaymentMethod__c
                    WHERE (
                        ( blng__Account__c IN :billingAccounts )
                        AND ( NSP_Active_Custom__c = TRUE )
                    )
                ]
            )
        {
            billingActPaymentMap.put( method.blng__Account__c+method.Payment_Method_Type__c , method );
        }
        return billingActPaymentMap;
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_OrderItemTriggerHelper.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_OrderItemTriggerHelper.class.getName() ,
            methodName ,
            e
        );
    }

}
//
