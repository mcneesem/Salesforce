public class NSP_InvoiceLineTriggerHelper {
    // test w/ NSP_InvoiceLineTriggerTest (89%)

    private NSP_InvoiceLineTriggerHelper() {
    }

    //
    // MethodName: afterUpdateDirector
    // Description : This method is used to handle all the after update scenarios and routes to appropriate method as needed
    // Params: Map<Id, blng__InvoiceLine__c> invLineNewMap,Map<Id, blng__InvoiceLine__c> invLineOldMap
    //
    public static void afterUpdateDirector( Map<Id,blng__InvoiceLine__c> invLineNewMap , Map<Id,blng__InvoiceLine__c> invLineOldMap ) {
        List<Id> elgibleLineForRevRec= new List<Id>();
        List<Id> elgibleLinesForRecreateRevRec= new List<Id>();
        for(blng__InvoiceLine__c invLine:invLineNewMap.values()){
            blng__InvoiceLine__c oldLine =invLineOldMap.get(invLine.Id);
            if(invLine.blng__InvoiceLineStatus__c!=oldLine.blng__InvoiceLineStatus__c && invLine.blng__InvoiceLineStatus__c=='Posted'){
                elgibleLineForRevRec.add(invLine.Id);
            }
            if(invLine.NSP_Go_Live_Date__c!=oldLine.NSP_Go_Live_Date__c){
                elgibleLinesForRecreateRevRec.add(invLine.Id);
            }
        }
        prepareForRevRecGeneration(elgibleLineForRevRec);
        if(elgibleLinesForRecreateRevRec.size()>0){
            NSP_RevRecService.recreateInvoiceRevSchedules(elgibleLinesForRecreateRevRec);
        }
    }

    //
    // MethodName: beforeUpdateDirector
    // Description : This method is used to handle all the before update scenarios and routes to appropriate method as needed
    // Params: Map<Id, blng__InvoiceLine__c> invLineNewMap,Map<Id, blng__InvoiceLine__c> invLineOldMap
    //
    public static void beforeUpdateDirector( Map<Id,blng__InvoiceLine__c> invLineNewMap , Map<Id,blng__InvoiceLine__c> invLineOldMap ) {
        List<Id> projectIds= new List<Id>();
        for(blng__InvoiceLine__c invLine:invLineNewMap.values()){
            blng__InvoiceLine__c oldLine =invLineOldMap.get(invLine.Id);
            if(invLine.NSP_Project__c!=oldLine.NSP_Project__c && oldLine.NSP_Project__c!=null){
                projectIds.add(invLine.NSP_Project__c);
            }
        }
        if(projectIds.size()>0){
            //When Project lookup changes on Invoice Line, updat Go Live Date to it;s corresponding project's go live date
            updateProjectGoLiveDate(projectIds,invLineNewMap.values());
        }
    }

    public static void beforeInsertDirector( List<blng__InvoiceLine__c> newList ) {
        updateAddProductDescription( newList );
        populateBillingFinancePeriod( newList );
    }

    public static void afterInsertDirector( List<blng__InvoiceLine__c> newList) {
        updateAddProductDescriptionOnOrderItem( newList );
    }

    //
    // MethodName: prepareForRevRecGeneration
    // Description : This method is used to get all the invoice lines and make a call to rev rec service
    // Params: List<Id> elgibleLineForRevRec
    //
    public static void prepareForRevRecGeneration( List<Id> elgibleLineForRevRec ) {
        List<blng__InvoiceLine__c> invLines = [
            SELECT
                Id ,
                blng__Subtotal__c ,
                blng__LegalEntity__c ,
                blng__OrderProduct__r.blng__RevenueRecognitionRule__c ,
                blng__Invoice__r.blng__InvoiceDate__c ,
                blng__OrderProduct__r.Order.NSP_Project_Go_Live_Date__c ,
                blng__OrderProduct__r.blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c ,
                NSP_Go_Live_Date__c
            FROM blng__InvoiceLine__c
            WHERE (
                ( Id IN :elgibleLineForRevRec )
                AND (
                    blng__OrderProduct__r.blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c NOT IN (
                        'Immediate' ,
                        '12 Month'
                    )
                )
            )
        ];
        if ( !invLines.isEmpty() ) {
            NSP_RevRecService.generateRevenue( invLines );
        }
    }

    //
    // MethodName: selectInvoiceLineOrderItems
    // Description : This method is used to Create a Map of OrderItem Ids and OrderItem records
    // Params: List<blng__InvoiceLine__c> records
    //
    private static Map<Id,OrderItem> selectInvoiceLineOrderItems( List<blng__InvoiceLine__c> records ) {
        Set<Id> orderProductIds = new Set<Id>();
        if ( ( records != null ) && !records.isEmpty() ) {
            for ( blng__InvoiceLine__c record : records ) {
                if ( record.blng__OrderProduct__c != null ) {
                    orderProductIds.add( record.blng__OrderProduct__c );
                }
            }
        }
        Map<Id,OrderItem> response = new Map<Id,OrderItem>();
        if ( ( orderProductIds != null ) && !orderProductIds.isEmpty() ) {
            response = new Map<Id,OrderItem>(
                [
                    SELECT
                        Id ,
                        Prevent_Product_Description_Update__c ,
                        NSP_Additional_Product_Description__c ,
                        Product_Description_Key__c
                    FROM OrderItem
                    WHERE ( Id IN :orderProductIds )
                ]
            );
        }
        return response;
    }

    //
    // MethodName: getInvoiceLineOrderItem
    // Description : This method is used to return OrderItem record for Invoice Line
    // Params: Id recordId , Map<Id,OrderItem> orderItemMap
    //
    private static OrderItem getInvoiceLineOrderItem( Id recordId , Map<Id,OrderItem> orderItemMap ) {
        OrderItem record = null;
        if ( ( recordId != null )
            && ( orderItemMap != null )
            && orderItemMap.containsKey( recordId )
            && ( orderItemMap.get( recordId ) != null )
            )
        {
            record = orderItemMap.get( recordId );
        }
        return record;
    }

    //
    // MethodName: selectInvoiceLineUsageSummaries
    // Description : This method is used to Create a Map of Usage Summary Ids and Usage Summary records
    // Params: List<blng__InvoiceLine__c> newInvLines
    //
    private static Map<Id,blng__UsageSummary__c> selectInvoiceLineUsageSummaries( List<blng__InvoiceLine__c> records ) {
        Set<Id> usageSummaryIds = new Set<Id>();
        if ( ( records != null ) && !records.isEmpty() ) {
            for ( blng__InvoiceLine__c record : records ) {
                if ( record.blng__UsageSummary__c != null ) {
                    usageSummaryIds.add( record.blng__UsageSummary__c );
                }
            }
        }
        Map<Id,blng__UsageSummary__c> response = new Map<Id,blng__UsageSummary__c>();
        if ( ( usageSummaryIds != null ) && !usageSummaryIds.isEmpty() ) {
            response = new Map<Id,blng__UsageSummary__c>(
                [
                    SELECT
                        Id ,
                        blng__UnitPrice__c
                    FROM blng__UsageSummary__c
                    WHERE ( Id IN : usageSummaryIds )
                ]
            );
        }
        return response;
    }

    //
    // MethodName: getInvoiceLineUsageSummary
    // Description : This method is used to return usageSummary record for Invoice Line
    // Params: Id recordId , Map<Id,blng__UsageSummary__c> usageSummaryMap
    //
    private static blng__UsageSummary__c getInvoiceLineUsageSummary( Id recordId , Map<Id,blng__UsageSummary__c> usageSummaryMap ) {
        blng__UsageSummary__c record = null;
        if ( ( recordId != null )
            && ( usageSummaryMap != null )
            && usageSummaryMap.containsKey( recordId )
            && ( usageSummaryMap.get( recordId ) != null )
            )
        {
            record = usageSummaryMap.get( recordId );
        }
        return record;
    }

    //
    // MethodName: selectOrderProductConsumptionRates
    // Description : This method is used to Create a Map of OrderProduct Ids and their Per Unit Consumption Rate records
    // Params: List<blng__InvoiceLine__c> records
    //
    public static Map<Id,SBQQ__OrderItemConsumptionRate__c> getUsageSummaryToRateMap( List<blng__InvoiceLine__c> invoiceLines ) {
        // 1. Gather all unique Usage Summary IDs from the invoice lines list
        Set<Id> usageSummaryIds = NSP_InvoiceLineTriggerHelper.buildUsageSummaryIds( invoiceLines );
        // 2. Query Usage Summaries to map OrderItemConsumptionSchedule IDs to UsageSummary IDs
        Map<Id,Id> scheduleToSummaryMap = NSP_InvoiceLineTriggerHelper.buildScheduleToSummaryMap( usageSummaryIds );
        // 3. Query standard OrderItemConsumptionRate records matching our schedules
        Map<Id,SBQQ__OrderItemConsumptionRate__c> resultMap = new Map<Id,SBQQ__OrderItemConsumptionRate__c>();
        if ( ( scheduleToSummaryMap != null ) && !scheduleToSummaryMap.isEmpty() ) {
            List<SBQQ__OrderItemConsumptionRate__c> rates = [
                SELECT
                    SBQQ__Price__c ,
                    SBQQ__PricingMethod__c ,
                    SBQQ__OrderItemConsumptionSchedule__c
                FROM SBQQ__OrderItemConsumptionRate__c
                WHERE (
                    ( SBQQ__OrderItemConsumptionSchedule__c IN :scheduleToSummaryMap.keySet() )
                    AND ( SBQQ__PricingMethod__c = 'PerUnit' )
                )
            ];
            // 4. Map the retrieved rates back to their corresponding Usage Summary ID
            if ( rates != null ) {
                for ( SBQQ__OrderItemConsumptionRate__c rate : rates ) {
                    resultMap = NSP_InvoiceLineTriggerHelper.addRateToUsageSummaryMap(
                        rate ,
                        scheduleToSummaryMap ,
                        resultMap
                    );
                }
            }
        }
        return resultMap;
    }

    private static Map<Id,SBQQ__OrderItemConsumptionRate__c> addRateToUsageSummaryMap(
        SBQQ__OrderItemConsumptionRate__c rate ,
        Map<Id,Id> scheduleToSummaryMap ,
        Map<Id,SBQQ__OrderItemConsumptionRate__c> resultMap
        )
    {
        if ( ( rate !=null )
            && ( rate.SBQQ__OrderItemConsumptionSchedule__c != null )
            && scheduleToSummaryMap.containsKey( rate.SBQQ__OrderItemConsumptionSchedule__c )
            )
        {
            Id summaryId = scheduleToSummaryMap.get( rate.SBQQ__OrderItemConsumptionSchedule__c );
            if ( ( summaryId != null )
                && !resultMap.containsKey( summaryId )
                )
            {
                resultMap.put( summaryId , rate );
            }
        }
        return resultMap;
    }

    private static Set<Id> buildUsageSummaryIds( List<blng__InvoiceLine__c> invoiceLines ) {
        Set<Id> usageSummaryIds = new set<Id>();
        // 1. Gather all unique Usage Summary IDs from the invoice lines list
        if ( ( invoiceLines != null ) && !invoiceLines.isEmpty() ) {
            for ( blng__InvoiceLine__c invLine : invoiceLines ) {
                if ( invLine.blng__UsageSummary__c != null ) {
                    usageSummaryIds.add( invLine.blng__UsageSummary__c );
                }
            }
        }
        return usageSummaryIds;
    }

    private static Map<Id,Id> buildScheduleToSummaryMap( Set<Id> usageSummaryIds ) {
        Map<Id,Id> scheduleToSummaryMap = new Map<Id,Id>();
        // 2. Query Usage Summaries to map OrderItemConsumptionSchedule IDs to UsageSummary IDs
        if ( ( usageSummaryIds != null ) && !usageSummaryIds.isEmpty() ) {
            for ( blng__UsageSummary__c summary : [
                        SELECT
                            Id ,
                            blng__OrderItemConsumptionSchedule__c
                        FROM blng__UsageSummary__c
                        WHERE (
                            ( Id IN :usageSummaryIds )
                            AND ( blng__OrderItemConsumptionSchedule__c != null )
                        )
                    ]
                )
            {
                scheduleToSummaryMap.put(
                    summary.blng__OrderItemConsumptionSchedule__c ,
                    summary.Id
                );
            }
        }
        return scheduleToSummaryMap;
    }

    //
    // MethodName: updateAddProductDescription
    // Description : This method is used to update additional Product Description Field on before Insert. STY-03868
    // Params: List<blng__InvoiceLine__c> Boolean isInsert
    //
    public static void updateAddProductDescription( List<blng__InvoiceLine__c> invLineNew ) {
        Map<String,NSP_AdditionalProductDescription_Setting__mdt>  additionalProductDesSetMap = NSP_AdditionalProductDescription_Setting__mdt.getAll();
        Map<Id,OrderItem> orderItemMap = NSP_InvoiceLineTriggerHelper.selectInvoiceLineOrderItems( invLineNew );
        Map<Id,blng__UsageSummary__c> usageSummaryMap = NSP_InvoiceLineTriggerHelper.selectInvoiceLineUsageSummaries( invLineNew );
        Map<Id, SBQQ__OrderItemConsumptionRate__c> usageSummaryToRateMap = NSP_InvoiceLineTriggerHelper.getUsageSummaryToRateMap( invLineNew );
        for ( blng__InvoiceLine__c newInvoiceLine : invLineNew ) {
            OrderItem item = NSP_InvoiceLineTriggerHelper.getInvoiceLineOrderItem(
                newInvoiceLine.blng__OrderProduct__c ,
                orderItemMap
            );
            blng__UsageSummary__c usageSummary = NSP_InvoiceLineTriggerHelper.getInvoiceLineUsageSummary(
                newInvoiceLine.blng__UsageSummary__c ,
                usageSummaryMap
            );
            if ( ( item != null )
                && item.Prevent_Product_Description_Update__c
                )
            {
                newInvoiceLine.NSP_Additional_Product_Description__c = item.NSP_Additional_Product_Description__c;
            } else {
                if ( ( item != null )
                    && ( item.Product_Description_Key__c != null )
                    && ( additionalProductDesSetMap != null )
                    && additionalProductDesSetMap.containsKey( item.Product_Description_Key__c )
                    )
                {
                    NSP_AdditionalProductDescription_Setting__mdt descriptionSetting = additionalProductDesSetMap.get( item.Product_Description_Key__c );
                    string prodDescStr = '';
                    if ( descriptionSetting != null ) {
                        prodDescStr = descriptionSetting.NSP_Product_Description_Syntex__c;
                    }
                    Decimal perunitPrice = NSP_InvoiceLineTriggerHelper.buildPerUnitPrice(
                        newInvoiceLine ,
                        usageSummary ,
                        descriptionSetting ,
                        usageSummaryToRateMap
                    );
                    //DF-05546 -- updating prices with accounting format
                    List<String> args = new String[]{'0','number','###,###,##0.00'};
                    String pepm_Text = '$'+String.format(perunitPrice.setScale(2).format(), args);
                    //monthly minimum should be removed if it's 0 or null
                    String mm_Text = (newInvoiceLine.NSP_Consumption_Rate_Flat_Price__c!=null && newInvoiceLine.NSP_Consumption_Rate_Flat_Price__c!=0) ?
                                        '$'+String.format(newInvoiceLine.NSP_Consumption_Rate_Flat_Price__c.setScale(2).format(), args) :
                                        null;
                    prodDescStr = (prodDescStr.contains('{Unit Price}') && perunitPrice != null) ? prodDescStr.replace('{Unit Price}',pepm_Text):prodDescStr;
                    prodDescStr = (prodDescStr.contains('{Upper Tier_Flat Price}') && mm_Text != null) ? prodDescStr.replace('{Upper Tier_Flat Price}',mm_Text)
                                    :prodDescStr.contains(', {Upper Tier_Flat Price} Monthly Minimum') ? prodDescStr.replace(', {Upper Tier_Flat Price} Monthly Minimum','')
                                    :prodDescStr.contains('{Upper Tier_Flat Price} monthly minimum; ') ? prodDescStr.replace('{Upper Tier_Flat Price} monthly minimum; ',''):prodDescStr;
                    prodDescStr = (prodDescStr.contains('{Qty}') && newInvoiceLine.blng__Quantity__c != null ) ? prodDescStr.replace('{Qty}',string.valueof(newInvoiceLine.blng__Quantity__c)):prodDescStr;
                    if(newInvoiceLine.NSP_Product_Code__c == 'Lasso'   ){
                        prodDescStr = newInvoiceLine.NSP_Order_Product_Account__c;
                    }
                    newInvoiceLine.NSP_Additional_Product_Description__c = prodDescStr;
                } else if(string.isNotBlank(newInvoiceLine.NSP_Order_Product_Type__c) && newInvoiceLine.NSP_Order_Product_Type__c == 'Lasso'){
                    newInvoiceLine.NSP_Additional_Product_Description__c = newInvoiceLine.NSP_Order_Product_Account__c;
                }
                //updating desc to not contain '(See appendix)' - DF-03861
                String str = newInvoiceLine.NSP_Additional_Product_Description__c;
                String removal = '(See';
                String various = '(various';
                if(str!=null && (str.contains(removal) || str.contains(various))){
                    String truncatedDesc = str.contains(removal)?str.substring(0,str.indexOf(removal,0)):str.substring(0,str.indexOf(various,0));
                    newInvoiceLine.NSP_Additional_Product_Description__c = truncatedDesc;
                }
            }
        }
    }

    private static Decimal buildPerUnitPrice(
        blng__InvoiceLine__c newInvoiceLine ,
        blng__UsageSummary__c usageSummary ,
        NSP_AdditionalProductDescription_Setting__mdt descriptionSetting ,
        Map<Id,SBQQ__OrderItemConsumptionRate__c> usageSummaryToRateMap
        )
    {
        String prodDescType = '';
        if ( descriptionSetting != null ) {
            prodDescType = descriptionSetting.Type__c;
        }
        Decimal perunitPrice = null;
        if ( newInvoiceLine != null ) {
            perunitPrice = ( ( newInvoiceLine.NSP_Consumption_Rate_Per_Unit__c != null ) ? newInvoiceLine.NSP_Consumption_Rate_Per_Unit__c : newInvoiceLine.blng__UnitPrice__c );
            if ( ( usageSummary != null )
                && ( usageSummary.blng__UnitPrice__c != null )
                && ( prodDescType == 'Dynamic' )
                )
            {
                perunitPrice = usageSummary.blng__UnitPrice__c;
                if ( newInvoiceLine.blng__UsageSummary__c != null
                    && ( usageSummaryToRateMap != null )
                    && usageSummaryToRateMap.containsKey( newInvoiceLine.blng__UsageSummary__c )
                    && ( descriptionSetting.Add_Unit_Price_From_OP_Consumption_Rate__c == true )
                    )
                {
                    perunitPrice = NSP_InvoiceLineTriggerHelper.setUnitPriceFromConsumptionRateCard(
                        usageSummaryToRateMap ,
                        newInvoiceLine ,
                        perunitPrice
                    );
                }
            }
        }
        return perunitPrice;
    }

    private static Decimal setUnitPriceFromConsumptionRateCard(
        Map<Id,SBQQ__OrderItemConsumptionRate__c> usageSummaryToRateMap ,
        blng__InvoiceLine__c newInvoiceLine ,
        Decimal perunitPrice
        )
    {
        if ( ( usageSummaryToRateMap != null ) && ( newInvoiceLine != null ) ) {
            SBQQ__OrderItemConsumptionRate__c cRate = usageSummaryToRateMap.get( newInvoiceLine.blng__UsageSummary__c );
            if ( cRate != null ) {
                perunitPrice = cRate.SBQQ__Price__c;
            }
        }
        return perunitPrice;
    }

    //
    // MethodName : updateAddProductDescriptionOnOrderItem
    // Description : This method is used to update additional Product Description Field on  orderitem after Insert. STY-03868
    //
    public static void updateAddProductDescriptionOnOrderItem( List<blng__InvoiceLine__c> invLineNew ) {
        if ( ( invLineNew != null ) && !invLineNew.isEmpty() ) {

            Set<Id> orderProductIds = new Set<Id>();
            for ( blng__InvoiceLine__c newInvoiceLine : invLineNew ) {
                if ( String.isNotBlank( newInvoiceLine.NSP_Additional_Product_Description__c )
                    && ( newInvoiceLine.blng__OrderProduct__c != null )
                    )
                {
                    orderProductIds.add( newInvoiceLine.blng__OrderProduct__c );
                }
            }
            Map<Id,OrderItem> orderItemMap = new Map<Id,OrderItem>([
                SELECT
                    Id ,
                    NSP_Additional_Product_Description__c ,
                    Prevent_Product_Description_Update__c ,
                    Product_Description_Key__c
                FROM OrderItem
                WHERE ( Id IN :orderProductIds )
            ]);
            Map<Id,OrderItem>  orderProductUpdateMap = new Map<Id,OrderItem>();
            for ( blng__InvoiceLine__c newInvoiceLine : invLineNew ) {
                if ( String.isNotBlank( newInvoiceLine.NSP_Additional_Product_Description__c )
                    && ( newInvoiceLine.blng__OrderProduct__c != null )
                    && orderItemMap.containsKey( newInvoiceLine.blng__OrderProduct__c )
                    )
                {
                    OrderItem eachProduct = orderItemMap.get( newInvoiceLine.blng__OrderProduct__c );
                    if ( ( eachProduct != null )
                        && !eachProduct.Prevent_Product_Description_Update__c
                        )
                    {
                        eachProduct.NSP_Additional_Product_Description__c = newInvoiceLine.NSP_Additional_Product_Description__c;
                        orderProductUpdateMap.put( eachProduct.Id , eachProduct );
                    }
                }
            }
            if ( !orderProductUpdateMap.isEmpty() ) {
                List<Database.SaveResult> assetResults = Database.update( orderProductUpdateMap.values() , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_InvoiceLineTriggerHelper.class.getName() ,
                    'updateAddProductDescriptionOnOrderItem' ,
                    assetResults
                );
            }
        }
    }

    public static void populateBillingFinancePeriod(List<blng__InvoiceLine__c> invLineNew){
        Map<String,blng__FinancePeriod__c> financePeriodsMap=getFinancePeriods();
        for(blng__InvoiceLine__c invLine:invLineNew){
            String key=invLine.blng__BillingFinanceBook__c+'_'+invLine.blng__LegalEntity__c+'_'+invLine.NSP_Invoice_Date_End_Of_Month__c;
            invLine.blng__BillingFinancePeriod__c=financePeriodsMap.get(key)?.Id;
        }
    }
    private static Map<String,blng__FinancePeriod__c> getFinancePeriods(){
        Map<String,blng__FinancePeriod__c> financePeriodsMap= new Map<String,blng__FinancePeriod__c>();
        for(blng__FinancePeriod__c finPeriod:[SELECT Id,blng__FinanceBook__c,blng__LegalEntity__c,blng__PeriodEndDate__c FROM blng__FinancePeriod__c WHERE blng__FinanceBook__r.Name=:NSP_CPQConstants.FINBOOK AND blng__FinanceBook__r.blng__PeriodType__c=:NSP_CPQConstants.ACCOUNTING]){
            String key=finPeriod.blng__FinanceBook__c+'_'+finPeriod.blng__LegalEntity__c+'_'+finPeriod.blng__PeriodEndDate__c;
            financePeriodsMap.put(key,finPeriod);
        }
        return financePeriodsMap;
    }

    //
    // MethodName: updateProjectGoLiveDate
    // Description : This method is used to update Go Live Date on Invoice line when Project changes on Invoice Line
    // Params: List<blng__InvoiceLine__c> newInvLines, List<Id>projectIds
    //
    private static void updateProjectGoLiveDate( List<Id>projectIds , List<blng__InvoiceLine__c>newInvLines ) {
        Map<Id,Date> projectGoLiveDateMap= new Map<Id,Date>();
        for(pse__Proj__c proj:[SELECT Id,Go_Live_Date__c FROM pse__Proj__c WHERE Id IN:projectIds]){
            projectGoLiveDateMap.put(proj.Id,proj.Go_Live_Date__c);
        }
        for(blng__InvoiceLine__c invLine:newInvLines){
            invLine.NSP_Go_Live_Date__c=projectGoLiveDateMap.get(invLine.NSP_Project__c);
        }
    }

}
//