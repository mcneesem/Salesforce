public class NSP_SubscriptionTriggerHelper {
    // test w/ NSP_SubscriptionTriggerHelperTest (76%)

    //
    // Iterates throught the list of new subscriptions and passes the required attributes to other methods.
    // @param newList List of New subscriptions.
    // @return void
    //
    public void beforeInsertDirector( List<SBQQ__Subscription__c> newList ) {
        populateFieldValuesOnInsert( newList );
    }

    //
    // Iterates throught the list of new subscriptions and passes the required attributes to other methods.
    // @param newList List of New subscriptions.
    // @return void
    //
    public void afterInsertDirector( List<SBQQ__Subscription__c> newList ) {
        processEntitlements(newList);
    }

    //
    // Iterates throught the subscriptions map and identifies the records that needs to worked based on various criterias.
    // @param subscriptionsNewMap Map of New subscriptions.
    // @param subscriptionsOldMap Map of Old subscriptions.
    // @return void
    //
    public void beforeUpdateDirector( Map<Id,SBQQ__Subscription__c> subscriptionsNewMap , Map<Id,SBQQ__Subscription__c> subscriptionsOldMap ) {
        populateOriginalDateAndWaivedAmount( subscriptionsNewMap.values() );
    }

    //
    // Iterates throught the list of new subscriptions and passes the required attributes to other methods.
    // @param subscriptionsNewMap Map of New subscriptions.
    // @param subscriptionsOldMap Map of Old subscriptions.
    // @return void
    //
    public void afterUpdateDirector( Map<Id,SBQQ__Subscription__c> contractNewMap , Map<Id, SBQQ__Subscription__c> contractOldMap ) {
    }

    //
    // Iterates throught the list of new subscriptions and populates field values before record insert.
    // @param newList List of New subscriptions.
    // @return void
    //
    //
    public void populateFieldValuesOnInsert (List<SBQQ__Subscription__c> newList) {

        Set<String> orderItemIds = new Set<String> ();
        for ( SBQQ__Subscription__c sub : newList ) {
            if(sub.SBQQ__OrderProduct__c != null) {
                orderItemIds.add(sub.SBQQ__OrderProduct__c);
            }
            //This code is used to set the subscription start and end date
            if(sub.NSP_SubscriptionStartDate__c == NSP_CPQConstants.SUBS_PROJGOLIVE && sub.NSP_ProjectGoLiveDate__c != null && sub.NSP_Quote_Type__c == NSP_CPQConstants.ORDER_TYPE_NEW){
                sub.SBQQ__SubscriptionStartDate__c = sub.NSP_ProjectGoLiveDate__c;
                sub.SBQQ__SubscriptionEndDate__c = sub.NSP_ProjectGoLiveDate__c.addMonths(12) - 1;
            }
            if(sub.NSP_SubscriptionStartDate__c == NSP_CPQConstants.SUBS_ODERACTIVATEPLUS1MONTH && sub.SBQQ__SubscriptionStartDate__c != null && sub.NSP_Quote_Type__c == NSP_CPQConstants.ORDER_TYPE_NEW){
                sub.SBQQ__SubscriptionStartDate__c = sub.SBQQ__SubscriptionStartDate__c.addMonths(1);
                sub.SBQQ__SubscriptionEndDate__c = sub.SBQQ__SubscriptionStartDate__c.addMonths(12) - 1;
            }
            if(sub.NSP_Remove_Bundle_Details__c){
                sub.SBQQ__RootId__c = null;
                sub.SBQQ__RequiredByProduct__c = null;
                sub.SBQQ__RequiredById__c = null;
            }
        }

        if(orderItemIds.size()>0){
            Map<Id, OrderItem> orderlinesMap = new Map<Id, OrderItem>([SELECT Id, OrderItemNumber, NSP_Override_Start_Date__c,ServiceDate, Order.blng__BillingAccount__c FROM OrderItem WHERE Id IN:orderItemIds]);
            for ( SBQQ__Subscription__c sub : newList ) {
                if(orderlinesMap.containsKey(sub.SBQQ__OrderProduct__c)){
                    OrderItem currOrderLine = orderlinesMap.get(sub.SBQQ__OrderProduct__c);
                    if(currOrderLine.NSP_Override_Start_Date__c!=null && currOrderLine.NSP_Override_Start_Date__c!=currOrderLine.ServiceDate) {

                        sub.SBQQ__SubscriptionStartDate__c = currOrderLine.NSP_Override_Start_Date__c;
                    }

                    if (sub.NSP_Billing_Account__c != currOrderLine.Order.blng__BillingAccount__c) {
                        sub.NSP_Billing_Account__c = currOrderLine.Order.blng__BillingAccount__c;
                    }
                }
            }

        }

    }

    //
    // Method Name : populateOriginalDateAndWaivedAmount
    // Description : Method to populate original Sub Start date and Original waived amount
    // Author : Samba Raju
    // Date : 10/26/2022
    // @param newList List of new Subscriptions.
    // @return void
    //
    private void populateOriginalDateAndWaivedAmount(List<SBQQ__Subscription__c> newList){
        Set<Id> quoteLineIds= new Set<Id>();
        Set<Id> revOrderProdIds = new Set<Id>();
        List<OrderItem> opUpdateList = new List<OrderItem>();
        Map<Id,SBQQ__Subscription__c> updateSubsMap = new Map<Id,SBQQ__Subscription__c>();
        for ( SBQQ__Subscription__c sub : newList ) {
            if(sub.SBQQ__QuoteLine__c != null) {
                quoteLineIds.add(sub.SBQQ__QuoteLine__c);
            }

                if(sub.NSP_Remove_Bundle_Details__c && (sub.SBQQ__RootId__c != null || sub.SBQQ__RequiredById__c != null || sub.SBQQ__RequiredByProduct__c != null )){
                    sub.SBQQ__RootId__c = null;
                    sub.SBQQ__RequiredByProduct__c = null;
                    sub.SBQQ__RequiredById__c = null;

                }
                if(sub.NSP_ProjectGoLiveDate__c != null && sub.SBQQ__TerminatedDate__c != null && sub.SBQQ__BillingFrequency__c == 'Annual' && sub.SBQQ__RevisedSubscription__c !=null){
                    sub.SBQQ__TerminatedDate__c = sub.NSP_ProjectGoLiveDate__c - 1;
                    revOrderProdIds.add(sub.SBQQ__OrderProduct__c);
                }
        }
        if(quoteLineIds.size()>0){
            Map<Id,SBQQ__QuoteLine__c> quoteLinesMap= new Map<Id,SBQQ__QuoteLine__c>([SELECT Id,SBQQ__Source__c,SBQQ__Quote__r.SBQQ__Type__c FROM SBQQ__QuoteLine__c WHERE Id IN:quoteLineIds]);
            for ( SBQQ__Subscription__c sub : newList ) {
                if(quoteLinesMap.containsKey(sub.SBQQ__QuoteLine__c) && String.isBlank(quoteLinesMap.get(sub.SBQQ__QuoteLine__c).SBQQ__Source__c) && quoteLinesMap.get(sub.SBQQ__QuoteLine__c).SBQQ__Quote__r.SBQQ__Type__c=='New Product'){
                    sub.NSP_Original_Subscription_Date__c=sub.SBQQ__SubscriptionStartDate__c;
                    sub.NSP_Original_waived_Amount__c=sub.NSP_Waived_Amount__c;
                }
            }
        }
        if(revOrderProdIds.size() > 0){
            updateTermDateonOP(revOrderProdIds);
        }

    }

    //
    // Method Name : processEntitlements
    // Description : Method to filter and dispatch entitlement creation,update and Hardware update based on different business use cases
    // Author : CPQ
    // Date : 01/28/2023
    // @param newList List of new Subscriptions.
    // @return void
    //
    public void processEntitlements(List<SBQQ__Subscription__c> newList){
        Set<Id>accountIds= new Set<Id>();
        List<SBQQ__Subscription__c> supportSubs= new List<SBQQ__Subscription__c>();
        List<String> serialIdsToTerminate= new List<String>();
        List<String> serialIdsToActivate= new List<String>();
        Map<String, SBQQ__Subscription__c> oldToNewSubscrioptionIdMap= new Map<String, SBQQ__Subscription__c>();
        Map<String,Date>serialIdsDateMap= new Map<String,Date>();
        //Added for multiple contract logic
        Set<String> contractIdSet = new Set<String>();

        for(SBQQ__Subscription__c subs:newList){
            //Added for multiple contract logic
            if(subs.SBQQ__Contract__c!=null && subs.NSP_Order_Type__c == 'New Product' && String.isEmpty(subs.NSP_Product_Type_Exclusions_Internal__c) ){
                contractIdSet.add(subs.SBQQ__Contract__c);
            }

            if(subs.NSP_Create_Entitlement__c==true &&(subs.NSP_Quote_Type__c==NSP_CPQConstants.QUOTE_TYPE_NEW||(subs.NSP_QLAction__c==NSP_CPQConstants.ACTION_NEW && subs.NSP_Quote_Type__c==NSP_CPQConstants.QUOTE_TYPE_AMENDMENT))){
                supportSubs.add(subs);
                accountIds.add(subs.SBQQ__Account__c);
            }
            else if(subs.NSP_Create_Entitlement__c==true && subs.NSP_Quote_Type__c==NSP_CPQConstants.QUOTE_TYPE_RENEWAL && subs.NSP_Serial_Ids__c!=null){
                serialIdsToTerminate.addAll(subs.NSP_Serial_Ids__c.split(','));
                oldToNewSubscrioptionIdMap.put(subs.NSP_Previous_SubScription_Id__c,subs);
                serialIdsDateMap.putAll(constructSerialIdsDateMap(subs.NSP_Serial_Ids__c.split(','),subs.SBQQ__StartDate__c));
            }
            else if(subs.NSP_Create_Entitlement__c==true && subs.NSP_Quote_Type__c==NSP_CPQConstants.QUOTE_TYPE_RENEWAL && subs.NSP_Serial_Ids__c==null){
                oldToNewSubscrioptionIdMap.put(subs.NSP_Previous_SubScription_Id__c,subs);
            }
            else if(subs.NSP_Create_Entitlement__c==true && subs.NSP_QLAction__c==NSP_CPQConstants.ACTION_DOWNGRADE && subs.NSP_Serial_Ids__c!=null){
                serialIdsToTerminate.addAll(subs.NSP_Serial_Ids__c.split(','));
                oldToNewSubscrioptionIdMap.put(subs.NSP_Previous_SubScription_Id__c,subs);
                serialIdsDateMap.putAll(constructSerialIdsDateMap(subs.NSP_Serial_Ids__c.split(','),subs.SBQQ__StartDate__c));
            }
            else if(subs.NSP_Create_Entitlement__c==true && subs.NSP_QLAction__c==NSP_CPQConstants.ACTION_UPSELL && subs.NSP_Serial_Ids__c!=null){
                serialIdsToActivate.addAll(subs.NSP_Serial_Ids__c.split(','));
                oldToNewSubscrioptionIdMap.put(subs.NSP_Previous_SubScription_Id__c,subs);
                serialIdsDateMap.putAll(constructSerialIdsDateMap(subs.NSP_Serial_Ids__c.split(','),subs.SBQQ__StartDate__c));
            }
        }
        if(supportSubs.size()>0){
            createEntitlements(supportSubs,accountIds);
        }
        if(serialIdsToTerminate.size()>0){
            terminateSerialIds(serialIdsToTerminate,serialIdsDateMap);
        }
        if(serialIdsToActivate.size()>0){
            activateSerialIds(serialIdsToActivate,serialIdsDateMap);
        }
        if(oldToNewSubscrioptionIdMap.size()>0){
            remapSubscriptionsInEntitlement(oldToNewSubscrioptionIdMap,serialIdsToTerminate);
        }
        // Added for multiple contract logic
        if(contractIdSet.size()>0) {
            //call future method
            callReparentMethod(new List<String>(contractIdSet));

        }
    }

    //
    // Method Name : createEntitlements
    // Description : Method to create entitlements for new subscriptions and associate them to Hardwares Assets related to account
    // Author : CPQ
    // Date : 01/28/2023
    // @param newList List of new Subscriptions, set of Account Ids.
    // @return void
    //
    private void createEntitlements(List<SBQQ__Subscription__c> supportSubs,Set<Id>accountIds){
        List<NSP_Support_Entitlement__c> entitlementsToCreate= new List<NSP_Support_Entitlement__c>();
        Map<String,List<Asset>> assetMapWithSupportProd=getAssetsWithNoActiveEntitlements(accountIds);
        List<Asset> assetsToUpdate= new List<Asset>();
        for(SBQQ__Subscription__c supportSub:supportSubs){
            for(Integer i=0;i<supportSub.SBQQ__Quantity__c;i++){
                NSP_Support_Entitlement__c entitlement= new NSP_Support_Entitlement__c();
                entitlement.NSP_Supported_Subscription__c=supportSub.Id;
                entitlement.NSP_Support_Product__c=supportSub.NSP_Product_Code__c;
                entitlement.NSP_Covered_Asset__c=assetMapWithSupportProd.get(supportSub.NSP_Product_Code__c)?.get(i)?.Id;
                entitlement.NSP_Hardware_Product__c=assetMapWithSupportProd.get(supportSub.NSP_Product_Code__c)?.get(i)?.ProductCode;
                entitlementsToCreate.add(entitlement);
                assetsToUpdate.add(new Asset(Id=assetMapWithSupportProd.get(supportSub.NSP_Product_Code__c)?.get(i)?.Id,NSP_Support_Cost__c=supportSub.SBQQ__NetPrice__c,NSP_Support_Expires__c=supportSub.SBQQ__EndDate__c));
            }
        }
        if ( !entitlementsToCreate.isEmpty() ) {
            List<Database.SaveResult> results = Database.insert( entitlementsToCreate , false );
            NSP_SubscriptionTriggerHelper.handleResults( results , 'createEntitlements:NSP_Support_Entitlement__c' );
        }
        if ( !assetsToUpdate.isEmpty() ) {
            List<Database.SaveResult> results = Database.update( assetsToUpdate , false );
            NSP_SubscriptionTriggerHelper.handleResults( results , 'createEntitlements:Asset' );
        }
    }

    //
    // Method Name : getAssetsWithNoActiveEntitlements
    // Description : Method to fetch hardware assets which do not have any active entitlements associated with it
    // Author : CPQ
    // Date : 01/28/2023
    // @param  set of Account Ids.
    // @return void
    //
    private Map<String,List<Asset>> getAssetsWithNoActiveEntitlements(Set<Id>accountIds){
        Map<String,List<Asset>> assetMapWithSupportProd= new Map<String,List<Asset>>();
        for(Asset eachAsset :[SELECT Id,NSP_Support_ProductCode__c,ProductCode FROM Asset WHERE Id NOT IN (SELECT NSP_Covered_Asset__c FROM NSP_Support_Entitlement__c WHERE NSP_Status1__c='Active' OR NSP_Status1__c='Terminated') AND AccountId IN :accountIds AND RecordType.Name=:NSP_CPQConstants.HARDWARE_ASSET]){
            if(!assetMapWithSupportProd.containsKey(eachAsset.NSP_Support_ProductCode__c)){
                assetMapWithSupportProd.put(eachAsset.NSP_Support_ProductCode__c, new List<Asset>{eachAsset});
            }
            else{
                assetMapWithSupportProd.get(eachAsset.NSP_Support_ProductCode__c).add(eachAsset);
            }
        }
        return assetMapWithSupportProd;
    }

    //
    // Method Name : terminateSerialIds
    // Description : Method to terminate hardwate assets
    // Author : CPQ
    // Date : 01/28/2023
    // @param  List of Serial Ids.
    // @return void
    //
    private void terminateSerialIds(List<String> serialIdsToTerminate,Map<String,Date> serialIdsDateMap){
        List<Asset> assetsToUpdate=[SELECT Id,Status,SerialNumber,NSP_Termination_Date__c,NSP_Early_Termination_Notice__c FROM Asset WHERE Status=:NSP_CPQConstants.ACTIVE AND SerialNumber IN :serialIdsToTerminate AND RecordType.Name=:NSP_CPQConstants.HARDWARE_ASSET];
        if(assetsToUpdate.size()>0){
            for(Asset eachAsset:assetsToUpdate){
                //eachAsset.Status=NSP_CPQConstants.TERMINATED;
                eachAsset.NSP_Termination_Date__c=serialIdsDateMap.get(eachAsset.SerialNumber)-1;
                if(eachAsset.NSP_Early_Termination_Notice__c==true){
                    eachAsset.NSP_Early_Termination_Notice__c=false;
                }
            }
            List<Database.SaveResult> results = Database.update( assetsToUpdate , false );
            NSP_SubscriptionTriggerHelper.handleResults( results , 'terminateSerialIds' );
        }
    }

    //
    // Method Name : remapSubscriptionsInEntitlement
    // Description : Method to activate hardwate assets
    // Author : CPQ
    // Date : 01/28/2023
    // @param  Map of old and new Subscription ids.
    // @return void
    //
    private void remapSubscriptionsInEntitlement( Map<String,SBQQ__Subscription__c> oldToNewSubscrioptionIdMap , List<String> serialIdsToTerminate ) {
        List<NSP_Support_Entitlement__c> entitlementsToUpdate= new List<NSP_Support_Entitlement__c>();
        Map<Id,Asset> assetsToUpdateMap = new Map<Id,Asset>();
        if ( oldToNewSubscrioptionIdMap != null ) {
            for ( NSP_Support_Entitlement__c entitlement : [
                        SELECT
                            Id ,
                            NSP_Supported_Subscription__c ,
                            NSP_Covered_Asset__c ,
                            NSP_Covered_Asset__r.Status,NSP_Serial_ID__c
                        FROM NSP_Support_Entitlement__c
                        WHERE ( NSP_Supported_Subscription__c IN :oldToNewSubscrioptionIdMap.keySet() )
                    ]
                )
            {
                SBQQ__Subscription__c oldSubscription = null;
                if ( ( oldToNewSubscrioptionIdMap != null )
                    && oldToNewSubscrioptionIdMap.containsKey( entitlement.NSP_Supported_Subscription__c )
                    )
                {
                    oldSubscription = oldToNewSubscrioptionIdMap.get( entitlement.NSP_Supported_Subscription__c );
                }
                if ( !serialIdsToTerminate.contains( entitlement.NSP_Serial_ID__c ) ) {
                    Asset ast = assetsToUpdateMap.get( entitlement.NSP_Covered_Asset__c );
                    if ( ast == null ) {
                        ast = new Asset(
                            Id=entitlement.NSP_Covered_Asset__c
                        );
                    }
                    if ( oldSubscription != null ) {
                        ast.NSP_Support_Expires__c = oldSubscription.SBQQ__EndDate__c;
                        ast.NSP_Support_Cost__c = oldSubscription.SBQQ__NetPrice__c;
                    }
                    assetsToUpdateMap.put( ast.Id , ast );
                }
                if ( ( oldSubscription != null )
                    && ( oldSubscription.NSP_Quote_Type__c == NSP_CPQConstants.QUOTE_TYPE_RENEWAL )
                    && ( entitlement.NSP_Covered_Asset__c != null )
                    && ( entitlement.NSP_Covered_Asset__r.Status == NSP_CPQConstants.TERMINATED )
                    )
                {
                    Asset assetToActivate = assetsToUpdateMap.get( entitlement.NSP_Covered_Asset__c );
                    if ( assetToActivate == null ) {
                        assetToActivate = new Asset(
                            Id=entitlement.NSP_Covered_Asset__c
                        );
                    }
                    assetToActivate.NSP_ActivationDate__c = Date.today();
                    assetsToUpdateMap.put( assetToActivate.Id , assetToActivate );
                }
                if ( oldSubscription != null ) {
                    entitlement.NSP_Supported_Subscription__c = oldSubscription.Id;
                }
                entitlementsToUpdate.add( entitlement );
            }
        }
        if ( !entitlementsToUpdate.isEmpty() ) {
            List<Database.SaveResult> results = Database.update( entitlementsToUpdate , false );
            NSP_SubscriptionTriggerHelper.handleResults( results , 'remapSubscriptionsInEntitlement:NSP_Support_Entitlement__c' );
        }
        if ( !assetsToUpdateMap.isEmpty() ) {
            List<Asset> assetsToUpdate = assetsToUpdateMap.values();
            List<Database.SaveResult> results = Database.update( assetsToUpdate , false );
            NSP_SubscriptionTriggerHelper.handleResults( results , 'remapSubscriptionsInEntitlement:Asset' );
        }
    }

    //
    // Method Name : activateSerialIds
    // Description : Method to activate hardwate assets
    // Author : CPQ      Date : 01/28/2023
    // @param  List of Serial Ids.
    // @return void
    //
    private void activateSerialIds(List<String> serialIdsToActivate,Map<String,Date> serialIdsDateMap){
        List<Asset> assetsToActivate=[SELECT Id,Status,SerialNumber,NSP_ActivationDate__c FROM Asset WHERE Status=:NSP_CPQConstants.TERMINATED AND SerialNumber IN :serialIdsToActivate AND RecordType.Name=:NSP_CPQConstants.HARDWARE_ASSET];
        if(assetsToActivate.size()>0){
            for(Asset eachAsset:assetsToActivate){
                //eachAsset.Status=NSP_CPQConstants.ACTIVE;
                eachAsset.NSP_ActivationDate__c=serialIdsDateMap.get(eachAsset.SerialNumber);
            }
            List<Database.SaveResult> results = Database.update( assetsToActivate , false );
            NSP_SubscriptionTriggerHelper.handleResults( results , 'activateSerialIds' );
        }
    }

    //
    // Method Name : constructSerialIdsDateMap
    // Description : Method to constrcut serial Ids Start date map
    // Author : CPQ
    // Date : 02/22/2023
    // @param  List of Serial Ids, Date subStartDate
    // @return Map<String,Date>
    //
    private Map<String,Date> constructSerialIdsDateMap(List<String> SerialIds,Date subStartDate){
        Map<String,Date>serialIdDateMap= new Map<String,Date>();
        for(String serialId :SerialIds){
            serialIdDateMap.put(serialId,subStartDate);
        }
        return serialIdDateMap;
    }

    //
    // Method Name : callReparentMethod
    // Description : Method to invoke multiple contract logic
    // Author : Rakesh
    // Date : 04/28/2023
    // @param  List of Contract Ids
    // @return void
    //
    @future
    public static void callReparentMethod(List<String> contractIds) {
        if(contractIds!=null){
            NSP_MultipleContractFutureClass.createContractAndReparentSubscriptions(contractIds);
        }
    }

    //
    // Method Name : updateTermDateonOP
    // Description : Method to override termination date on order product
    // Author : CPQ Team
    // Date : 09/01/2024
    // @param  Set of Order Product Ids
    // @return void
    //
    @future
    public static void updateTermDateonOP(Set<Id> orderProdIdSet){
        List<OrderItem> opUpdateList = new List<OrderItem>();
        List<OrderItem> opList = [Select SBQQ__TerminatedDate__c,SBQQ__Subscription__r.SBQQ__TerminatedDate__c,SBQQ__Subscription__r.NSP_ProjectGoLiveDate__c FROM OrderItem WHERE Id IN :orderProdIdSet];
        for(OrderItem oi: opList){
            oi.SBQQ__TerminatedDate__c = oi.SBQQ__Subscription__r.SBQQ__TerminatedDate__c;
            //List to update Termination Date on Order Product
            opUpdateList.add(oi);
        }
        if ( !opUpdateList.isEmpty() ) {
            List<Database.SaveResult> results = Database.update( opUpdateList , false );
            NSP_SubscriptionTriggerHelper.handleResults( results , 'updateTermDateonOP' );
        }
    }

    private static void handleResults( List<Database.SaveResult> results , String methodName ) {
        NSP_ErrorLogHandler.logResults(
            NSP_SubscriptionTriggerHelper.class.getName() ,
            methodName ,
            results
        );
    }

}
//