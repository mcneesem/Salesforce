// Represents the Order trigger helper which handles all the logic.
public class NSP_OrderTriggerHelper {
    // test w/ NSP_OrderTriggerHelperTest, NSP_OrderItemTriggerHelperTest, NSP_QuoteTriggerHelper_Test, NSP_ProjBlngTriggerHelperTest (79%)

    static final string STRING_ACCOUNT = 'Account';
    static final string CLOSE_LOST = 'Close/Lost';

    //
    // Iterates throught the list of new Order and passes the required attributes to other methods.
    // @param newList List of New Order.
    // @return void
    //
    public void beforeInsertDirector( List<Order> newList ) {
        copyQuoteDateOnOrder(newList);
        updateBillingShippingAddress(newList,null);
    }

    //
    // Iterates throught the Order map and identifies the records that needs to worked based on various criterias.
    // @param orderNewMap Map of New Order.
    // @param orderOldMap Map of Old Order.
    // @return void
    //
    public void beforeUpdateDirector( Map<Id,Order> orderNewMap , Map<Id,Order> orderOldMap ) {
        updateBillingShippingAddress( orderNewMap.values() , orderOldMap );
        createContract( orderNewMap.values() , orderOldMap );
        OriginalOpportunityHelper.stampOriginalOpportunityFromAsset( orderNewMap , orderOldMap );
    }

    //
    // Iterates throught the list of new Orders and passes the required attributes to other methods.
    // @param orderNewMap Map of New Order.
    // @param orderOldMap Map of Old Order.
    // @return void
    //
    public void afterUpdateDirector( Map<Id,Order> orderNewMap , Map<Id, Order> orderOldMap ) {
        checkProjectGoLiveChanged( orderNewMap.values() , orderOldMap );
        activateHardwareAssets( orderNewMap.values() , orderOldMap );
        OrderTriggerCreateInvoice.createInvoice( orderNewMap.values() , orderOldMap );
        AssetMismatchSyncUp.setFlagAsset( orderNewMap.values() , orderOldMap );
    }

    //
    // Method added for STY-00397 to copy data from quote to Order
    // @param newList List of New Order.
    // @return void
    //
    public static void copyQuoteDateOnOrder( List<Order> newList ) {
        set<Id> quoteIdSet = new set<Id>();
        List<Group> orderProcessingQueue = [SELECT Id,DeveloperName,name FROM Group WHERE Type = 'Queue' AND DeveloperName = :System.label.NSP_ITA_Order_Queue_Name LIMIT 1];
        for(Order newOrder : newList){
            if(newOrder.SBQQ__Quote__c != null){
                quoteIdSet.add(newOrder.SBQQ__Quote__c);
            }
        }
        if(quoteIdSet.Size() > 0){
            Map<Id,SBQQ__Quote__c> quoteMap = new Map<Id,SBQQ__Quote__c>(
                [
                    SELECT
                        Id , NSP_Invoice_To_Email__c , NSP_Billing_Account__c , SBQQ__Partner__c , SBQQ__StartDate__c ,
                        NSP_Billing_Address__c , NSP_Shipping_Address__c , SBQQ__Account__r.NSP_AIMS_Client__c
                    FROM SBQQ__Quote__c
                    WHERE ( Id In : quoteIdSet )
                ]
            );
            for(Order newOrder : newList){
                newOrder.OwnerId = orderProcessingQueue[0].Id;
                if(newOrder.SBQQ__Quote__c != null && quoteMap.ContainsKey(newOrder.SBQQ__Quote__c)){
                    SBQQ__Quote__c objQuote = quoteMap.get(newOrder.SBQQ__Quote__c);
                    newOrder.BillToContactId = objQuote.NSP_Invoice_To_Email__c;
                    newOrder.blng__BillingAccount__c = objQuote.NSP_Billing_Account__c;
                    newOrder.NSP_Partner__c = objQuote.SBQQ__Partner__c;
                    newOrder.NSP_AIMS_Billing_ID__c=objQuote.SBQQ__Account__r.NSP_AIMS_Client__c;
                    if ( ( Order_Settings__c.getInstance( UserInfo.getUserId() ).EffectiveDateStartOfMonth__c == True )
                        && ( newOrder.Type == NSP_CPQConstants.ORDER_TYPE_AMENDMENT )
                        && ( newOrder.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION )
                        && ( objQuote.SBQQ__StartDate__c != null )
                        )
                    {
                        newOrder.EffectiveDate = objQuote.SBQQ__StartDate__c.toStartOfMonth();
                    }
                }
            }
        }
    }

    //
    // Method Name : updateOrderStartDate
    // Description : Method to set Start date on termination Order to Termination Date+1 [DF-04145]
    // Author : Sancharini       Date : 05/16/2023
    // @return void
    //
    @future
    public static void updateOrderStartDate(Set<ID>orderIds){
        List<Order>newList = [Select Id,Type,NSP_TerminationDate__c,Status,EffectiveDate FROM Order WHERE Id In:orderIds];
        List<Order> ordersToUpdate = new List<Order>();
        for(Order newOrder : newList){
                newOrder.EffectiveDate = newOrder.NSP_TerminationDate__c.addDays(1);
                ordersToUpdate.add(newOrder);
        }
        if(ordersToUpdate.size()>0){
            Database.update(ordersToUpdate);
        }
    }

    //
    // Method Name : updateBillingShippingAddress
    // Description : Method to set custom address fields on Order
    // Author : Sales Team       Date : 28/10/2021
    // @return void
    //
    public static void updateBillingShippingAddress( List<Order> newList , Map<Id,Order> orderOldMap ) {
        Set<Id> addressIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        set<Id> processOrderIdSet = new set<Id>();
        Map<Id,NSP_Address__c> addressMap;
        Map<Id,Account> accountMap;
        String addressParam = 'Address';
        String accountParam = STRING_ACCOUNT;
        for( Order newOrder : newList ) {
            Order oldOrder = ( ( orderOldMap != null ) ? orderOldMap.get( newOrder.Id ) : null );
            if( (Trigger.isInsert && newOrder.blng__InvoiceBatch__c == 'Standalone Order') ||
                (Trigger.isUpdate && (newOrder.NSP_Billing_Address__c !=  oldOrder.NSP_Billing_Address__c
               || newOrder.NSP_Shipping_Address__c !=  oldOrder.NSP_Shipping_Address__c
                   || newOrder.NSP_Billing_Account__c !=  oldOrder.NSP_Billing_Account__c)
                )
              ){
                   processOrderIdSet.add(newOrder.Id);
                   if(newOrder.NSP_Billing_Address__c != null){
                       addressIdSet.add(newOrder.NSP_Billing_Address__c);
                   }

                   if(newOrder.NSP_Shipping_Address__c != null){
                       addressIdSet.add(newOrder.NSP_Shipping_Address__c);
                   }

                   if(newOrder.NSP_Billing_Account__c != null){
                       accountIdSet.add(newOrder.NSP_Billing_Account__c);
                   }
                   accountIdSet.add(newOrder.AccountId);
               }
        }

        if(addressIdSet.Size() > 0){
            addressMap  = new Map<Id,NSP_Address__c>([SELECT    Id,NSP_Street__c,NSP_Street_Address_2__c,Name,
                                                      NSP_City__c,NSP_State__c,NSP_Country__c,
                                                      NSP_Postal_Code__c FROM NSP_Address__c
                                                      WHERE Id IN : addressIdSet]);
        }

        if(accountIdSet.Size() > 0){
            accountMap = new Map<Id,Account>([SELECT Id,BillingStreet,BillingCity,BillingState,BillingCountry,BillingPostalCode,
                                              ShippingStreet,ShippingCity,ShippingState,ShippingCountry,ShippingPostalCode
                                              FROM Account WHERE Id IN: accountIdSet]);
        }

        for(Order newOrder : newList){
            if(processOrderIdSet.contains(newOrder.Id)){
                boolean hasBillingAddress = false;
                boolean hasShippingAddress = false;
                boolean hasBillinAccount = false;

                if( newOrder.NSP_Billing_Address__c != null && addressMap != null && addressMap.containsKey(newOrder.NSP_Billing_Address__c)){
                    hasBillingAddress = true;
                    NSP_Address__c billingaddress       = addressMap.get(newOrder.NSP_Billing_Address__c);
                    copyBillingAddress(newOrder,null,billingaddress,addressParam);
                }

                if( newOrder.NSP_Shipping_Address__c != null && addressMap != null && addressMap.containsKey(newOrder.NSP_Shipping_Address__c)){
                    hasShippingAddress = true;
                    NSP_Address__c shippingaddress       = addressMap.get(newOrder.NSP_Shipping_Address__c);
                    copyShippingAddress(newOrder,null,shippingaddress,addressParam);
                }

                if(newOrder.NSP_Billing_Account__c != null && accountMap != null && accountMap.containsKey(newOrder.NSP_Billing_Account__c)){
                    Account billingAccount = accountMap.get(newOrder.NSP_Billing_Account__c);
                    hasBillinAccount = true;
                    if(!hasBillingAddress){
                        copyBillingAddress(newOrder,billingAccount,null,accountParam);
                    }

                    if(!hasShippingAddress){
                        copyShippingAddress(newOrder,billingAccount,null,accountParam);
                    }
                }

                if(newOrder.AccountId != null && accountMap != null && accountMap.containsKey(newOrder.AccountId )){
                    Account objAccount = accountMap.get(newOrder.AccountId);
                    if(!hasBillingAddress && !hasBillinAccount){
                        copyBillingAddress(newOrder,objAccount,null,accountParam);
                    }

                    if(!hasShippingAddress && !hasBillinAccount){
                        copyShippingAddress(newOrder,objAccount,null,accountParam);
                    }
                }
            }
        }
    }

    //
    // Method Name : copyBillingAddress
    // Description : Method to update billing address fields on Order
    // Author : Sales Team       Date : 28/10/2021
    // @param Order New Order data.
    // @param Account Account data.
    // @param NSP_Address__c Custom Address data.
    // @param String Indicates the copy from which object
    // @return void
    //
    public static void copyBillingAddress( Order newOrder , Account objAccount , NSP_Address__c objAddress , String copyFrom ) {
        if ( ( copyFrom == STRING_ACCOUNT ) && ( objAccount != null ) ) {
            newOrder.BillingStreet = objAccount.BillingStreet;
            newOrder.BillingState = objAccount.BillingState;
            newOrder.BillingCity = objAccount.BillingCity;
            newOrder.BillingPostalCode = objAccount.BillingPostalCode;
            newOrder.BillingCountry = objAccount.BillingCountry;
        } else {
            newOrder.BillingStreet = objAddress.NSP_Street__c;
            newOrder.BillingState = objAddress.NSP_State__c;
            newOrder.BillingCity = objAddress.NSP_City__c;
            newOrder.BillingPostalCode = objAddress.NSP_Postal_Code__c;
            newOrder.BillingCountry = objAddress.NSP_Country__c;
        }
    }

    //
    // Method Name : copyShippingAddress
    // Description : Method to update Shipping address fields on Order
    // Author : Sales Team       Date : 28/10/2021
    // @param Order New Order data.
    // @param Account Account data.
    // @param NSP_Address__c Custom Address data.
    // @param String Indicates the copy from which object
    // @return void
    //
    public static void copyShippingAddress( Order newOrder , Account objAccount , NSP_Address__c objAddress , String copyFrom ) {
        if ( ( copyFrom ==STRING_ACCOUNT ) && ( objAccount != null ) ) {
            newOrder.ShippingStreet = objAccount.ShippingStreet;
            newOrder.ShippingState = objAccount.ShippingState;
            newOrder.ShippingCity = objAccount.ShippingCity;
            newOrder.ShippingPostalCode = objAccount.ShippingPostalCode;
            newOrder.ShippingCountry = objAccount.ShippingCountry;
        } else {
            newOrder.ShippingStreet = objAddress.NSP_Street__c;
            newOrder.ShippingState = objAddress.NSP_State__c;
            newOrder.ShippingCity = objAddress.NSP_City__c;
            newOrder.ShippingPostalCode = objAddress.NSP_Postal_Code__c;
            newOrder.ShippingCountry = objAddress.NSP_Country__c;
        }
    }

    //
    // Method Name : createContract
    // Description : Method to create Contract on activated Order
    // Author : CPQ Team       Date : 07/20/2022
    // @param orderNewMap Map of New Order.
    // @param orderOldMap Map of Old Order.
    // @return void
    //
    public static void createContract( List<Order> newList , Map<Id,Order> orderOldMap ) {
        Set<Id> orderIdNew = new Set<Id>();
        Set<Id> orderIdAmend = new Set<Id>();
        Set<Id> orderIdSuppl = new Set<Id>();
        Set<Id> orderIdSet = new Set<Id>();
        Set<Id> blngTypeIdSet = new Set<Id>();
        Set<Id> usageIdSet = new Set<Id>();
        Set<Id> woBillingOrder = new Set<Id>();
        // STY-03797 Start
        Set<Id> reviewedOrdersAccountSet = new Set<Id>();
        Map<String, Order> uniqueAddressKeyMap = new Map<String, Order> ();
        //STY-03797 End

        for(Order newOrder : newList){
            Order oldOrder = orderOldMap != null ? orderOldMap.get(newOrder.Id):null;
            if(oldOrder.NSP_First_usage_upload__c == false && newOrder.NSP_First_usage_upload__c == true &&
               newOrder.Status != NSP_CPQConstants.ORDER_ACTIVATED
               && newOrder.Type == NSP_CPQConstants.ORDER_TYPE_NEW
               && newOrder.NSP_Usage_Products_Count__c > 0) {
                    usageIdSet.add(newOrder.Id);
            }
            if(newOrder.NSP_Project_Name__c == null
               && newOrder.Type == NSP_CPQConstants.ORDER_TYPE_NEW) {
                orderIdNew.add(newOrder.Id);
            }
            if ( ( newOrder.NSP_Project_Name__c == null )
                && ( newOrder.Type == NSP_CPQConstants.ORDER_TYPE_AMENDMENT )
                && ( newOrder.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION )
                )
            {
                orderIdAmend.add(newOrder.Id);
            }
            if(newOrder.NSP_Project_Name__c == null
               && newOrder.Type == NSP_CPQConstants.SUPPLEMENTAL) {
                orderIdSuppl.add(newOrder.Id);
            }
            //This code is used to update Invoice Batch on Order
            if((oldOrder.Status == NSP_CPQConstants.ORDER_REVIEWED
               && newOrder.Status == NSP_CPQConstants.ORDER_ACTIVATED) ||
               (oldOrder.Status == NSP_CPQConstants.ORDER_DRAFT
               && newOrder.Status == NSP_CPQConstants.ORDER_ACTIVATED)) {
                orderIdSet.add(newOrder.Id);
            }
            if(newOrder.NSP_BillingType__c == null
               && newOrder.NSP_Usage_Products_Count__c == 0){
                blngTypeIdSet.add(newOrder.Id);
            }
            //STY-03797 Start - This code is used to collect Account Ids of reviewed Orders
            if((oldOrder.Status == NSP_CPQConstants.ORDER_DRAFT && newOrder.Status == NSP_CPQConstants.ORDER_REVIEWED) ||
              (oldOrder.Status == NSP_CPQConstants.ORDER_DRAFT && newOrder.Status == NSP_CPQConstants.ORDER_ACTIVATED)) {
                String accIdstr;
                if(newOrder.blng__BillingAccount__c != null) {
                reviewedOrdersAccountSet.add(newOrder.blng__BillingAccount__c);
                    accIdstr = newOrder.blng__BillingAccount__c;
                }
                else {
                reviewedOrdersAccountSet.add(newOrder.AccountId);
                     accIdstr = newOrder.AccountId;
                }
                String ordUniqAddressKey = accIdstr +'-'+newOrder.ShippingCity +'-'+ newOrder.ShippingStateCode +'-'+ newOrder.ShippingCountryCode +'-'+newOrder.ShippingPostalCode;
                uniqueAddressKeyMap.put(ordUniqAddressKey, newOrder);
            }
            // STY-03797 Ends
            if ( oldOrder.NSP_Rev_Rec_Rules_Reviewed__c == false
                && newOrder.NSP_Rev_Rec_Rules_Reviewed__c == true
                && newOrder.NSP_Billing_Account_Name__c != null
                && newOrder.NSP_Billing_Account_Name__c == 'Insperity WO Billing Account'
                )
            {
                woBillingOrder.add(newOrder.Id);
            }
        }
        if(orderIdNew.Size() >0){
            setProjNameNew(orderIdNew,newList);
        }
        else if(orderIdAmend.Size() >0){
            setProjNameAmend(orderIdAmend,newList);
        }
        else if(orderIdSuppl.Size() >0){
            setProjNameSupplement(orderIdSuppl,newList);
        }
        if(orderIdSet != null && orderIdSet.size() > 0){
            setInvoiceBatch(orderIdSet,newList);
        }
        if(usageIdSet != null && usageIdSet.size() > 0){
            updateUsageProd(usageIdSet,newList);
         }
        // STY-03797 - ShipTo Contact Function
        if(reviewedOrdersAccountSet.size() > 0) {
            createAndStampSalesTaxContact(reviewedOrdersAccountSet,newList,uniqueAddressKeyMap);
        }
        if(woBillingOrder.size()>0){
            changeTaxRulesForWOOrders(woBillingOrder);
        }
    }

    //
    // Method Name : setProjNameNew
    // Description : Method to update Project Template on Order for New transaction
    // Author : CPQ Team       Date : 08/29/2022
    // @return void
    //
    public static void setProjNameNew( Set<Id> orderListNew , List<Order> newList ) {
        Map<Id,OrderItem> ordProdMap = new Map<Id,OrderItem> ();
        if(orderListNew!= null && orderListNew.size() > 0){
            List <OrderItem> orderProductObj=[SELECT Id,Product2.ProductCode,NSP_Priority_New_Sales__c,NSP_Project_Name_New_Sales__c,OrderId  from OrderItem WHERE OrderId IN :orderListNew AND NSP_Priority_New_Sales__c!=null and Separate_Project__c = false order by NSP_Priority_New_Sales__c ASC ];
            for( OrderItem orderLine : orderProductObj){
                if(!ordProdMap.containskey(orderLine.OrderId)){
                    ordProdMap.put(orderLine.OrderId,orderLine);
                }
            }
            for(Order newOrder : newList){
                if(ordProdMap.containskey(newOrder.Id)){
                    newOrder.NSP_Project_Name__c = ordProdMap.get(newOrder.Id).NSP_Project_Name_New_Sales__c;
                    newOrder.NSP_Project_Key__c = ordProdMap.get(newOrder.Id).Product2.ProductCode;
                }
            }
        }
    }

    //
    // Method Name : setProjNameAmend
    // Description : Method to update Project Template on Order for Amendment transaction
    // Author : CPQ Team       Date : 08/29/2022
    // @param orderNewMap Map of New Order.
    // @param orderOldMap Map of Old Order.
    // @return void
    //
    public static void setProjNameAmend( Set<Id> orderListAmend , List<Order> newList ) {
        String transactionType;
        String action;
        Map<Id,OrderItem> ordProdMap = new Map<Id,OrderItem> (); // this will hold Matching order line as value and order id as key;

        if(orderListAmend!= null && orderListAmend.size() > 0){

            List <OrderItem> orderProductObj=[SELECT Id,Product2.ProductCode,NSP_Priority_Amendment__c,NSP_Project_Name_Amendment__c,OrderId,NSP_QL_ActionType__c,NSP_Transaction_for_Project__c,NSP_ApplicableProductAmendNew__c,NSP_ApplicableProduct_AmendDowngrade__c,NSP_ApplicableProduct_AmendUpsell__c,SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.Product2.ProductCode  from OrderItem WHERE OrderId IN :orderListAmend AND NSP_Priority_Amendment__c!=null and Separate_Project__c = false order by NSP_Priority_Amendment__c ASC];

            for( OrderItem orderLine : orderProductObj){
                if(String.isNotBlank( orderLine.NSP_QL_ActionType__c )) {
                    action = orderLine.NSP_QL_ActionType__c.replace('Amend/','');
                    if(action == NSP_CPQConstants.ACTION_NEW && orderLine.NSP_ApplicableProductAmendNew__c != null){
                        if(orderLine.NSP_ApplicableProductAmendNew__c.replace(';',' ').contains(orderLine.SBQQ__RequiredBy__r.Product2.ProductCode)){
                            if(!ordProdMap.containskey(orderLine.OrderId)){
                                ordProdMap.put(orderLine.OrderId,orderLine);
                            }
                        }
                    }
                    else if(action == NSP_CPQConstants.ACTION_DOWNGRADE && String.isNotBlank( orderLine.NSP_ApplicableProduct_AmendDowngrade__c )){
                        if(orderLine.NSP_ApplicableProduct_AmendDowngrade__c.replace(';',' ').contains(orderLine.SBQQ__RequiredBy__r.Product2.ProductCode)){
                            if(!ordProdMap.containskey(orderLine.OrderId)){
                                ordProdMap.put(orderLine.OrderId,orderLine);
                            }
                        }
                    }
                    else if(action == NSP_CPQConstants.ACTION_UPSELL && String.isNotBlank( orderLine.NSP_ApplicableProduct_AmendUpsell__c )){
                        if(orderLine.NSP_ApplicableProduct_AmendUpsell__c.replace(';',' ').contains(orderLine.SBQQ__RequiredBy__r.Product2.ProductCode)){
                            if(!ordProdMap.containskey(orderLine.OrderId)){
                                ordProdMap.put(orderLine.OrderId,orderLine);
                            }
                        }
                    }
                    else if(String.isBlank( orderLine.NSP_ApplicableProduct_AmendUpsell__c )  && String.isBlank( orderLine.NSP_ApplicableProduct_AmendDowngrade__c ) && String.isBlank( orderLine.NSP_ApplicableProductAmendNew__c )) {
                        if(String.isNotBlank( orderLine.NSP_Transaction_for_Project__c )){
                            transactionType = orderLine.NSP_Transaction_for_Project__c.replace(';',' ');
                        }
                        if(String.isNotBlank( orderLine.NSP_QL_ActionType__c )) {
                            action = orderLine.NSP_QL_ActionType__c.replace('Amend/','');
                            if(transactionType!=null && transactionType.contains(action)){
                                if(!ordProdMap.containskey(orderLine.OrderId)){
                                    ordProdMap.put(orderLine.OrderId,orderLine);
                                }
                            }
                        }
                    }
                }
            }
            for(Order newOrder : newList){
                if(ordProdMap.containskey(newOrder.Id)){
                    newOrder.NSP_Project_Name__c = ordProdMap.get(newOrder.Id).NSP_Project_Name_Amendment__c;
                    newOrder.NSP_Project_Key__c = ordProdMap.get(newOrder.Id).Product2.ProductCode;
                }
            }
        }
    }

    //
    // Method Name : setProjNameSupplement
    // Description : Method to update Project Template on Order on supplement transaction
    //
    public static void setProjNameSupplement( Set<Id> orderListSuppl , List<Order> newList ) {
        Map<Id,OrderItem> ordProdMap = new Map<Id,OrderItem> (); // this will hold Matching order line as value and order id as key;

        if(orderListSuppl!= null && orderListSuppl.size() > 0){

            List <OrderItem> orderProductObj=[SELECT Id,Product2.ProductCode,NSP_Priority_Amendment__c,NSP_Project_Name_Amendment__c,
                                            OrderId,NSP_QL_ActionType__c,NSP_Transaction_for_Project__c,NSP_ApplicableProductAmendNew__c,
                                            NSP_ApplicableProduct_AmendDowngrade__c,NSP_ApplicableProduct_AmendUpsell__c,SBQQ__RequiredBy__c,
                                            SBQQ__RequiredBy__r.Product2.ProductCode,SBQQ__QuoteLine__r.NSP_ActionType__c FROM OrderItem WHERE OrderId IN :orderListSuppl AND NSP_Priority_Amendment__c!=null and  Separate_Project__c = false  ORDER BY NSP_Priority_Amendment__c ASC];

            for( OrderItem orderLine : orderProductObj){
                if(orderLine.SBQQ__QuoteLine__r.NSP_ActionType__c != null) {
                    if(orderLine.SBQQ__QuoteLine__r.NSP_ActionType__c == NSP_CPQConstants.ACTION_NEW){
                        if(!ordProdMap.containskey(orderLine.OrderId)){
                                ordProdMap.put(orderLine.OrderId,orderLine);
                        }
                    }
                }
            }
            for(Order newOrder : newList){
                if(ordProdMap.containskey(newOrder.Id)){
                    newOrder.NSP_Project_Name__c = ordProdMap.get(newOrder.Id).NSP_Project_Name_Amendment__c;
                    newOrder.NSP_Project_Key__c = ordProdMap.get(newOrder.Id).Product2.ProductCode;
                }
            }
        }
    }

    //
    // Method Name : stampDunningEmailonContact
    // Description : Method to check and stamp contact acr record for dunning emails.
    // Author : Rakesh       Date : 09/20/2022
    // @param Set<Id> contact Ids
    // @param Set<Id> account Ids
    // @return void
    //
    public static void stampDunningEmailonContact( Set<Id> contactIds , Set<Id> accountIds , Set<String> uniqueACRIds ) {
    try{
    List<AccountContactRelation> acrRecsToUpdate = new List<AccountContactRelation>();
    Map<String,Integer> accountWithOrdersMap = new Map<String,Integer>();
    AggregateResult[] groupedResults = [SELECT AccountId, COUNT(Id)OrderCount FROM Order WHERE AccountId IN:accountIds AND Status!= :NSP_CPQConstants.ORDER_DRAFT GROUP BY AccountId];
    for (AggregateResult ar : groupedResults)  {
        accountWithOrdersMap.put((String)ar.get('AccountId'),(Integer)ar.get('OrderCount'));
    }
    for (AccountContactRelation acrRec : [Select Id, NSP_Dunning_Emails__c, ContactId, AccountId FROM AccountContactRelation WHERE AccountId IN:accountIds AND ContactId IN:contactIds]){
        String uniquekey = String.valueof(acrRec.ContactId)+String.valueOf(acrRec.AccountId);
        if(accountWithOrdersMap.containsKey(acrRec.AccountId)){
        if(uniqueACRIds.contains(uniquekey) && acrRec.NSP_Dunning_Emails__c==false && accountWithOrdersMap.get(acrRec.AccountId) <= 1 )  {
            acrRec.NSP_Dunning_Emails__c = true;
            acrRecsToUpdate.add(acrRec);
        }
    }
    }

            if ( acrRecsToUpdate.size() > 0 ) {
                update acrRecsToUpdate;
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_OrderTriggerHelper.class.getName() ,
                'stampDunningEmailonContact' ,
                e
            );
        }
    }

    //
    // Method Name : setInvoiceBatch
    // Description : Method to update invoice batch based on order product type.
    //
    public static void setInvoiceBatch( Set<Id> orderIdSet , List<Order> newList ) {
        Map<String,String> invoiceBatchMap = new Map<String,String> ();
        //Invoice Batch metadata holds the Invoice Batch names for each order product type
        List<NSP_Invoice_Batch__mdt> invoiceBatch = NSP_Invoice_Batch__mdt.getAll().values();
        //List<String> keySet = new List<String>();
            for(NSP_Invoice_Batch__mdt ib: invoiceBatch){
                List<String> opType = ib.NSP_Order_Product_Type__c.split(';');
                for(String s1 : opType) {
                    invoiceBatchMap.put(s1, ib.NSP_Batch_Name__c);
                }
            }
            for(Order orderOb : newList){
                if(invoiceBatchMap.containsKey(orderOb.NSP_Order_Product_Type__c)){
                    orderOb.blng__InvoiceBatch__c = invoiceBatchMap.get(orderOb.NSP_Order_Product_Type__c);
                }
            }
    }

    //
    // Method Name : updateSubStartDate
    // Description : Method to update StartDate on Subscription
    //
    public static void updateSubStartDate( Set<Id> orderIdSet ) {
        Set<Id> ordProductSet = new Set<Id>();
        List<SBQQ__Subscription__c> updateSubList = new List<SBQQ__Subscription__c>();
        List<OrderItem> orderProductList=[SELECT Id,SBQQ__Status__c,Order.Type,ServiceDate,SBQQ__BillingFrequency__c,NSP_AnniversaryBlngApplicable__c FROM OrderItem WHERE OrderId IN :orderIdSet AND NSP_AnniversaryBlngApplicable__c = TRUE AND SBQQ__BillingFrequency__c = 'Annual' AND NSP_SubscriptionStartDate__c = 'Project go-live date'];
            for(OrderItem orderItemObj :orderProductList){
                ordProductSet.add(orderItemObj.ID);
            }
            if(ordProductSet !=null && ordProductSet.size()>0){
                List<SBQQ__Subscription__c> subsList=[SELECT Id,SBQQ__SubscriptionStartDate__c,SBQQ__SubscriptionEndDate__c,NSP_ProjectGoLiveDate__c FROM SBQQ__Subscription__c WHERE SBQQ__OrderProduct__c IN :ordProductSet];
                for(SBQQ__Subscription__c subObj :subsList){
                    subObj.SBQQ__SubscriptionStartDate__c = subObj.NSP_ProjectGoLiveDate__c;
                    subObj.SBQQ__SubscriptionEndDate__c = subObj.NSP_ProjectGoLiveDate__c.addMonths(12) - 1;
                    updateSubList.add(subObj);
                }
            }
            if(updateSubList.size() > 0){
                database.update(updateSubList);
            }
    }

    //
    // Method Name : checkDownPaymentDetails
    // Description : method to determine if down payment id required. called from flow  // added for STY-02870
    //
    @InvocableMethod(label='check DownPayment Detail' description='method to determine if down payment id required' category='Account')
    public static void checkDownPaymentDetails( List<Id> orderIds ) {
        set<Id> orderItemToCheckSet = new set<Id>();
        map<id,pse__Proj__c> projectUpdateMap = new map<id,pse__Proj__c>();
        Map<Id,Order> OrderUpdateMap = new Map<Id,Order>();
        try
        {
            list<Order> orderProcessList = new list<Order>(
                [
                    SELECT
                        Id , NSP_Down_Payment_Required__c , NSP_Project__c , NSP_Project__r.Project_Complete_Date__c , OpportunityId ,
                        (
                            SELECT Id , SBQQ__BillingFrequency__c , NSP_Project__c , NSP_Project__r.Project_Complete_Date__c
                            FROM ORDERITEMS
                            WHERE ( SBQQ__BillingFrequency__c IN ( 'Monthly' , 'Annual' , 'Invoice Plan' ) )
                        )
                    FROM Order
                    WHERE (
                        ( Id IN : orderIds )
                        AND ( NSP_Project_Complete_Date__c = NULL )
                    )
                ]
            );

            for(Order eachOrder : orderProcessList)
            {
                if(eachOrder.ORDERITEMS != null && eachOrder.ORDERITEMS.Size() > 0)
                {
                    for(OrderItem eacholi : eachOrder.ORDERITEMS )
                    {
                        if(String.isNotBlank(eacholi.SBQQ__BillingFrequency__c) && eacholi.SBQQ__BillingFrequency__c == 'Annual')
                        {
                            eachOrder.NSP_Down_Payment_Required__c = 'Yes';
                        }
                        else if(eacholi.SBQQ__BillingFrequency__c == 'Monthly' && eachOrder.NSP_Down_Payment_Required__c != 'Yes'){
                            eachOrder.NSP_Down_Payment_Required__c = 'No';
                        }

                        if((String.isBlank(eachOrder.NSP_Down_Payment_Required__c) || eachOrder.NSP_Down_Payment_Required__c != 'Yes') && eacholi.SBQQ__BillingFrequency__c == 'Invoice Plan' )
                        {
                            orderItemToCheckSet.add(eacholi.Id);
                        }
                    }
                }

                if(String.isNotBlank(eachOrder.NSP_Down_Payment_Required__c))
                {
                    OrderUpdateMap.put(eachOrder.Id,eachOrder);
                }
            }

            //if(orderItemToCheckSet.Size() > 0)
           // {
                Map<Id,boolean> orderItemToDownpaymentRequiredMap = new Map<Id,boolean>();
                // get billing Transactions for order lines
                for(blng__BillingTransaction__c eachTransaction : [SELECT Id,blng__BillingSchedule__r.blng__OrderProduct__c,blng__InvoicePlanLine__c, blng__InvoicePlanLine__r.NSP_Billing_Commencement_Trigger__c FROM blng__BillingTransaction__c
                                                                    WHERE blng__BillingSchedule__r.blng__OrderProduct__c IN : orderItemToCheckSet
                                                                    AND NSP_DownPayment_Required__c = TRUE ])
                {
                    orderItemToDownpaymentRequiredMap.put(eachTransaction.blng__BillingSchedule__r.blng__OrderProduct__c,True);
                }
                // process the orders
                for(Order eachOrder : orderProcessList)
                {
                    if(eachOrder.ORDERITEMS != null && eachOrder.ORDERITEMS.Size() > 0)
                    {
                        for(OrderItem eacholi : eachOrder.ORDERITEMS )
                        {
                            // check if order item have billing transaction
                            if((String.isBlank(eachOrder.NSP_Down_Payment_Required__c) || eachOrder.NSP_Down_Payment_Required__c != 'Yes') && eacholi.SBQQ__BillingFrequency__c == 'Invoice Plan'
                            &&  orderItemToDownpaymentRequiredMap.containsKey(eacholi.Id))
                            {
                                eachOrder.NSP_Down_Payment_Required__c = 'Yes';
                            }
                        }
                    }
                    // set the field on project record
                    if ( eachOrder.NSP_Project__c != null ) {
                        pse__Proj__c newProject = new pse__Proj__c(
                            Id=eachOrder.NSP_Project__c ,
                            pse__Opportunity__c=eachOrder.OpportunityId
                        );
                        if ( eachOrder.NSP_Down_Payment_Required__c == 'No' ) {
                            newProject.Project_Down_Payment_Not_Required__c = true;
                        }
                        projectUpdateMap.put( newProject.Id , newProject );
                    }
                    if(String.isNotBlank(eachOrder.NSP_Down_Payment_Required__c))
                    {
                        OrderUpdateMap.put(eachOrder.Id,eachOrder);
                    }
                }
                // update project
                if(projectUpdateMap.Size() > 0)
                {
                    update projectUpdateMap.values();
                }


            //}
            // update order
            if(OrderUpdateMap.Size() > 0)
            {
                update OrderUpdateMap.values();
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_OrderTriggerHelper.class.getName() ,
                'checkDownPaymentDetails' ,
                e
            );
        }
    }

    //
    // Method Name : updateUsageProd
    // Description : Method to activate Order and update start date on usage based products
    //
    public static void updateUsageProd( Set<Id> orderIdSet , List<Order> newList ) {
        List<OrderItem> updateOrdProdList = new List<OrderItem>();
        List<OrderItem> orderProductList=[SELECT Id,Order.Project_Status__c,SBQQ__Status__c,ServiceDate,NSP_Order_Activation_Trigger__c,SBQQ__QuoteLine__r.SBQQ__HasConsumptionSchedule__c FROM OrderItem WHERE OrderId IN :orderIdSet AND NSP_Order_Activation_Trigger__c =: NSP_CPQConstants.FIRSTUSAGEUPLOAD];
            for(OrderItem oi :orderProductList){
                if(oi.SBQQ__Status__c != NSP_CPQConstants.ORDER_ACTIVATED){
                    if(oi.SBQQ__QuoteLine__r.SBQQ__HasConsumptionSchedule__c == true){

                        Date opDate = oi.ServiceDate;
                        Date compareDate = System.today().toStartOfMonth().addMonths(-1);
                        //Boolean value = opDate < compareDate;
                        if(opDate < compareDate){
                            oi.ServiceDate = System.today().toStartOfMonth().addMonths(-1);
                            if(oi.Order.Project_Status__c != CLOSE_LOST){
                                oi.SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
                            }
                            updateOrdProdList.add(oi);
                        } else{
                            if(oi.Order.Project_Status__c != CLOSE_LOST){
                                oi.SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
                            }
                            updateOrdProdList.add(oi);
                        }
                    }
                    else{
                        if(oi.Order.Project_Status__c != CLOSE_LOST){
                            oi.SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
                        }
                        updateOrdProdList.add(oi);
                    }
                }
            }
                try{
                    if(updateOrdProdList != null && updateOrdProdList.size() > 0){
                        database.update(updateOrdProdList);
                    for(Order ordObj : newList){
                            if(ordObj.Status != NSP_CPQConstants.ORDER_ACTIVATED){
                            ordObj.Status = NSP_CPQConstants.ORDER_ACTIVATED;
                            }
                        }
                    }
                    //Call Invoice batch after order activation
                    setInvoiceBatch(orderIdSet,newList);
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_OrderTriggerHelper.class.getName() ,
                'updateUsageProd' ,
                e
            );
        }
    }

    //
    // Method Name : checkProjectGoLiveChangedToDiffPeriod
    // Description : Method to set a flag when Project go live date change to a different period
    // Author : CPQ Team       Date : 11/10/2022
    // @param newList Map of New Orders.
    // @param orderOldMap Map of Old Order.
    // @return void
    //
    public static void checkProjectGoLiveChanged( List<Order> newList , Map<Id,Order> orderOldMap ) {
    Set<String> backoutOrders = new Set<String>();
    Set<Id> createProjectIds = new Set<Id>();
    Set<ID> projCompletedIdSet = new Set<Id>();
    List<Process_Billing_Event__e> billingEvents= new List<Process_Billing_Event__e>();
    for(Order newOrder :newList){
        Order oldOrder = orderOldMap.get( newOrder.Id );
        if(newOrder.NSP_Back_Out__c && newOrder.NSP_Back_Out__c != oldOrder.NSP_Back_Out__c) {
            backoutOrders.add(newOrder.Id);
        }
        if(oldOrder.NSP_CreateProject__c == FALSE
           && newOrder.NSP_CreateProject__c == TRUE) {
            createProjectIds.add(newOrder.Id);
            Process_Billing_Event__e event= new Process_Billing_Event__e();
            event.NSP_Action__c = 'CREATE_PROJECT';
            event.NSP_Order_SF_Id__c = newOrder.Id;
            event.NSP_CreateProject__c = newOrder.NSP_CreateProject__c;
            billingEvents.add(event);
        }
        //Added as part of DF-05544
        if(newOrder.NSP_Project_Complete_Date__c != null && oldOrder.NSP_Project_Complete_Date__c != newOrder.NSP_Project_Complete_Date__c){
            projCompletedIdSet.add(newOrder.Id);
        }
    }
    if(backoutOrders.size() > 0) {
        NSP_AssetUpdate.assetBackoutUpdate(backoutOrders,NSP_SalesConstants.BACKOUT_STATUS);
        updateRevisedOrderProd(backoutOrders);
    }
    if(projCompletedIdSet != null && projCompletedIdSet.size() > 0){
        //Queuable job which queries the billing transactions associated with the order products and update the override next billing date on Billing transaction
        NSP_UpdateProjMilestone updateJob = new NSP_UpdateProjMilestone(projCompletedIdSet);
       // enqueue the job for processing , updates Override Next Billing Date on Billing transaction
       System.enqueueJob(updateJob);
   }
        //Platform event to trigger Project creation, when Create Project field is checked
        if ( billingEvents.size() > 0 ) {
            // Call method to publish events
            List<Database.SaveResult> results = EventBus.publish(billingEvents);
            NSP_ErrorLogHandler.logResults(
                NSP_OrderTriggerHelper.class.getName() ,
                'checkProjectGoLiveChanged' ,
                results
            );
        }
    }

    //
    // Method Name : createAndStampSaleTaxContact
    // Description : Method to create a Sales Tax contact based on Primary Shipping Address
    //
    public static void createAndStampSalesTaxContact(
        Set<Id> accountIdSet ,
        List<Order> newList ,
        Map<String,Order> orderAddressKeyToCheck
        )
    {

        // query record type
        Id salesTaxRecordType = NSP_GenericRecordType.getRecordTypeId('Contact','Sales_Tax');

        Map<String, Integer> accountIdwithCounterMap = new  Map<String, Integer>();
        Map<String, String> existingContactsMap = new  Map<String, String>();
        Map<String, String> AccountNameMap = new  Map<String, String>();
        List<Contact> contactsToInsert = new List<Contact>();

        List<Account> accRecords = NSP_sObjectSelector.getAccountsById(accountIdSet);
        for (Account acc : accRecords) {

            if(!AccountNameMap.containsKey(acc.Id)) {
                AccountNameMap.put(acc.Id, acc.Name);
            }
        }
        List<Contact> salesTaxContacts = NSP_sObjectSelector.getContactsByAccountAndRecTypeId(accountIdSet,salesTaxRecordType);
        for ( Contact con : salesTaxContacts) {
            if(orderAddressKeyToCheck.containsKey(con.NSP_Sales_Tax_Contact_Key__c)) {
                existingContactsMap.put(con.NSP_Sales_Tax_Contact_Key__c, con.Id);
            }


            if(accountIdwithCounterMap.containsKey(con.AccountId)) {
                if(accountIdwithCounterMap.get(con.AccountId) < con.NSP_Sales_Tax_Contact_Counter__c) {
                    accountIdwithCounterMap.put(con.AccountId,(Integer)con.NSP_Sales_Tax_Contact_Counter__c);
                }
            }
            else {
                accountIdwithCounterMap.put(con.AccountId,(Integer)con.NSP_Sales_Tax_Contact_Counter__c);
            }

        }

        for (String ackey : orderAddressKeyToCheck.keySet()) {
            if(!existingContactsMap.containsKey(ackey)) {

                String accId = ackey.substringBefore('-');
                Integer accCounter;
                if(accountIdwithCounterMap.containsKey(accId) && accountIdwithCounterMap.get(accId) != null ) {
                    accCounter = accountIdwithCounterMap.get(accId);
                    accCounter+=1;
                }
                else {
                    accCounter = 1;
                }

                accountIdwithCounterMap.put(accId,accCounter);

                Order matchOrder = orderAddressKeyToCheck.get(ackey);
                //populate new contact details
                Contact newCon = new Contact();
                newCon.FirstName = (AccountNameMap.get(accId)!=null && AccountNameMap.get(accId).length()>40?AccountNameMap.get(accId).substring(0,40):AccountNameMap.get(accId));
                newCon.LastName = 'Sales Tax '+ accCounter;
                newCon.NSP_Sales_Tax_Contact_Key__c = ackey;
                newCon.NSP_Sales_Tax_Contact_Counter__c = accCounter;
                newCon.AccountId = matchOrder.AccountId;
                if(matchOrder.blng__BillingAccount__c != null) {
                    newCon.AccountId = matchOrder.blng__BillingAccount__c;
                }
                newCon.recordTypeId = salesTaxRecordType;
                newCon.MailingStreet = matchOrder.ShippingStreet;
                newCon.MailingCity = matchOrder.ShippingCity;
                newCon.MailingState = matchOrder.ShippingState;
                newCon.MailingCountry = matchOrder.ShippingCountry;
                newCon.MailingPostalCode = matchOrder.ShippingPostalCode;

                //add to insert contact list
                contactsToInsert.add(newCon);
            }
        }

        // Database insert contacts
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_ContactTriggerHandler.TriggerDisabled = true;
        Database.DmlOptions opts = new Database.DmlOptions();
        opts.DuplicateRuleHeader.allowSave = true;
        opts.OptAllOrNone = false;
        Database.SaveResult[] result = Database.insert(contactsToInsert, opts);
        for(Integer index = 0; index < contactsToInsert.size(); index++) {
            if(result[index].isSuccess()) {
                existingContactsMap.put(contactsToInsert[index].NSP_Sales_Tax_Contact_Key__c,result[index].getId());
            }
        }

        for ( Order ord : orderAddressKeyToCheck.values() ) {

            // key formation
            String accStr;
            if(ord.blng__BillingAccount__c != null) {
                    accStr = ord.blng__BillingAccount__c;
                }
            else {
                accStr=ord.AccountId;
            }
            String ordUniqAddressKey = accStr +'-'+ord.ShippingCity +'-'+ ord.ShippingStateCode +'-'+ ord.ShippingCountryCode +'-'+ord.ShippingPostalCode;

            // get contact id from existing contacts map
            ord.ShipToContactId = existingContactsMap.get(ordUniqAddressKey);
        }
    }

    //
    // Method Name : changeTaxRulesForWOOrders
    // Description : Method update zero tax rule on Order items for Insperity WO Billing Account Orders
    //
    public static void changeTaxRulesForWOOrders( Set<Id> woBillingOrderId ) {
        Map<String,String> legalEntiyBasedZeroTaxRuleMap= new Map<String,String>();
        try{
        List<blng__TaxTreatment__c> zeroTaxTreatments= [SELECT Id,blng__TaxLegalEntity__c,blng__TaxRule__c FROM blng__TaxTreatment__c WHERE blng__TaxRule__r.blng__TaxableYesNo__c='No' AND blng__Active__c=TRUE];
        for(blng__TaxTreatment__c treatment:zeroTaxTreatments){
            legalEntiyBasedZeroTaxRuleMap.put(treatment.blng__TaxLegalEntity__c,treatment.blng__TaxRule__c);
        }
        List<OrderItem> orderLines= [SELECT Id,OrderId,blng__TaxRule__c,blng__LegalEntity__c FROM OrderItem WHERE OrderId IN :woBillingOrderId];
        List<SBQQ__OrderItemConsumptionSchedule__c> oitemconsumptions=[SELECT Id,blng__LegalEntity__c,blng__TaxRule__c,SBQQ__OrderItem__r.OrderId FROM SBQQ__OrderItemConsumptionSchedule__c WHERE SBQQ__OrderItem__r.OrderId IN :woBillingOrderId];
        for(OrderItem line :orderLines){
            line.blng__TaxRule__c=legalEntiyBasedZeroTaxRuleMap?.get(line.blng__LegalEntity__c);
        }
        for(SBQQ__OrderItemConsumptionSchedule__c oicsh:oitemconsumptions){
            oicsh.blng__TaxRule__c=legalEntiyBasedZeroTaxRuleMap?.get(oicsh.blng__LegalEntity__c);
        }
         if(orderLines.size()>0){
             update orderLines;
         }
        if(oitemconsumptions.size()>0){
            update oitemconsumptions;
        }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_OrderTriggerHelper.class.getName() ,
                'changeTaxRulesForWOOrders' ,
                e
            );
        }
    }

    //
    // Method Name : activateHardwareAssets
    // Description : Method to activate purchased hardware assets
    // Author : CPQ Team     Date : 01/28/2023
    // @param List of new Orders,Map of Old Orders
    // @return void
    //
    private void activateHardwareAssets( List<Order> newList , Map<Id,Order> orderOldMap ) {
        List<Id> optyIds = new List<Id>();
        List<Asset> assetsToActivate= new List<Asset>();
        for (Order newOrder : newList){
            Order oldOrder = orderOldMap.get( newOrder.Id );
            if (newOrder.Status == NSP_CPQConstants.ORDER_ACTIVATED && oldOrder.Status != newOrder.Status && newOrder.OpportunityId != null){
                optyIds.add(newOrder.OpportunityId);
            }
        }
        if(optyIds != null && optyIds.size()>0){
            for(Asset eachAsset:[SELECT Id,Status FROM Asset WHERE Opportunity__c IN :optyIds AND RecordType.Name=:NSP_CPQConstants.HARDWARE_ASSET AND Status=:NSP_CPQConstants.PURCHASED]){
                eachAsset.Status=NSP_CPQConstants.ACTIVE;
                assetsToActivate.add(eachAsset);
            }
            if(assetsToActivate.size()>0){
                NSP_AssetTriggerHandler.TriggerDisabled=true;
                List<Database.SaveResult> results = Database.update(assetsToActivate,false);
                NSP_ErrorLogHandler.logResults(
                    NSP_OrderTriggerHelper.class.getName() ,
                    'activateHardwareAssets' ,
                    results
                );
                NSP_AssetTriggerHandler.TriggerDisabled=false;
            }
        }
    }

    //
    // Method Name : setOrderProductType
    // Description : Method to set order product type
    //
    @future
    public static void setOrderProductType( Set<Id> orderIdPT ) {
        Map<Id,Order> productType = new Map<Id,Order>();

        List<OrderItem> orderProdList=[SELECT Id,SBQQ__Status__c,NSP_Order_Product_Type__c,OrderId FROM OrderItem WHERE OrderId IN :orderIdPT];
                    for(OrderItem oi:orderProdList){
                        Order orObj = new Order();
                        if(!productType.containsKey(oi.OrderId)
                           && oi.NSP_Order_Product_Type__c != null){
                            orObj.NSP_Order_Product_Type__c = oi.NSP_Order_Product_Type__c;
                            orObj.Id = oi.OrderId;
                            productType.put(oi.OrderId,orObj);
                        }
                    }
                    try{
                        if(productType != null && productType.size()>0) {
                            database.update(productType.values());
                        }
        } catch ( Exception e ){
            NSP_ErrorLogHandler.logException(
                NSP_OrderTriggerHelper.class.getName() ,
                'setOrderProductType' ,
                e
            );
        }
    }

    //
    // Method Name : setProjectDatesForInfightOrders
    // Description : Method to get Project Go Live Dates from Existing Project to Order
    //
    public void setProjectDatesForInfightOrders( List<Order> newList ) {
        Map<String,Order> projectOrderMap= new Map<String,Order>();
        List<Order> ordersToUpdate= new List<Order>();
        for(Order ord :newList){
            if(ord.NSP_Project__c!=null
               && ord.NSP_Inflight_Order__c==true){
                projectOrderMap.put(ord.NSP_Project__c,ord);
            }
        }
        if(projectOrderMap.values().size()>0){
            Map<Id,pse__Proj__c> projectMap = new Map<Id,pse__Proj__c>([Select Id,Go_Live_Date__c,Invoice_Ready__c FROM pse__Proj__c WHERE Id IN:projectOrderMap.keySet()]);
            for(Order ord :newList){
                if(projectMap.get(ord.NSP_Project__c)!=null){
                    ordersToUpdate.add(new Order(Id=ord.Id,NSP_Project_Go_Live_Approved__c=projectMap.get(ord.NSP_Project__c)?.Invoice_Ready__c,NSP_Project_Go_Live_Date__c=projectMap.get(ord.NSP_Project__c)?.Go_Live_Date__c));
                }
            }
        }
        if(ordersToUpdate.size()>0 && ordersToUpdate!=null){
            NSP_OrderTriggerHandler.TriggerDisabled=true;
            List<Database.SaveResult> results = Database.update(ordersToUpdate,false);
            NSP_ErrorLogHandler.logResults(
                NSP_OrderTriggerHelper.class.getName() ,
                'setProjectDatesForInfightOrders' ,
                results
            );
            NSP_OrderTriggerHandler.TriggerDisabled=false;
        }
    }

    //
    // Method Name : updateRevisedOrderProd
    // Description : Method to nullify Revised Order Product on order items when Order is marked as Backout
    //
    public static void updateRevisedOrderProd( Set<String> orderIdSet ) {
        List<OrderItem> updateList = new List<OrderItem>();
        List<OrderItem> orderProdList=[SELECT Id,SBQQ__Status__c,SBQQ__RevisedOrderProduct__c,OrderId FROM OrderItem WHERE OrderId IN :orderIdSet];
        for(OrderItem oi:orderProdList){
            oi.SBQQ__RevisedOrderProduct__c = null;
            updateList.add(oi);
        }
        if(updateList != null && updateList.size()>0) {
            List<Database.SaveResult> results = Database.update(updateList,false);
            NSP_ErrorLogHandler.logResults(
                NSP_OrderTriggerHelper.class.getName() ,
                'updateRevisedOrderProd' ,
                results
            );
        }
    }

}
//