// intentionally `without sharing` to preserve default sharing at api version 55...
public without sharing class NSP_AssetUpdate {
    // test w/ NSP_AssetUpdateTest (84%)

    private static final string ASSET_RECORDTYPE = System.Label.NSP_Asset_Product;
    public static final Id ASSET_RECORDTYPE_ID = Schema.SObjectType.ASSET.getRecordTypeInfosByDeveloperName().get(ASSET_RECORDTYPE).getRecordTypeId();

    public NSP_AssetUpdate() {
    }

    //
    // Method Name : assetBackoutUpdate
    // Description : Method to update asset status to backout
    // Author : CPQ Team
    // Date : 11/20/2022
    // @param optyIdSet Set of optyId.
    // @param status to be updated.
    // @return void
    //
    public static void assetBackoutUpdate(Set<String> orderIdSet,String status){
        List<Asset> updateList = new List<Asset>();
        List<OrderItem> orderItems = [
            SELECT Id , NSP_ServiceAsset__c
            FROM OrderItem
            WHERE (
                (
                    OrderId IN (
                        SELECT Id
                        FROM Order
                        WHERE (
                            Id IN :orderIdSet
                            AND Prevent_Asset_Updates__c = False
                        )
                    )
                )
                AND ( NSP_ServiceAsset__c != null )
            )
        ];
        for(OrderItem orderItem : orderItems){
                Asset asset = new Asset(Id=orderItem.NSP_ServiceAsset__c);
                asset.Status = NSP_SalesConstants.BACKOUT_STATUS;
                updateList.add(asset);
        }
        try {
            if(updateList != null && updateList.size() > 0){
                database.update(updateList);
            }
        } catch ( Exception e ) {
            NSP_AssetUpdate.handleException( e , 'assetBackoutUpdate' );
        }
    }

    //
    // Method Name : activateAsset
    // Description : Method to activatevAsset
    // Author : CPQ Team
    // Date : 11/20/2022
    // @param opActiveMap Map of OrderItem.
    // @param accountId account Id.
    // @return void
    //
    public static void activateAsset(Map<Id,OrderItem> opActiveMap,String accountId){
        List<Asset> updateList = new List<Asset>();
        List<Asset> assetList = [
            SELECT Id , Status , NSP_Termination_Date__c , RecordTypeId
            FROM Asset
            WHERE (
                AccountId = :accountId
                AND RecordTypeId IN :opActiveMap.keySet()
            )
        ];
        for(Asset assetObj:assetList){
            if ( opActiveMap.get(assetObj.RecordTypeId).SBQQ__Status__c == NSP_SalesConstants.ACTIVATED_STATUS
                && ( assetObj.status == NSP_SalesConstants.ONDEMAND_STATUS || assetObj.status == NSP_SalesConstants.ONBOARDING )
                && assetObj.status != NSP_SalesConstants.TERMINATED_STATUS
                && assetObj.status != NSP_SalesConstants.BACKOUT_STATUS
                )
            {
                assetObj.NSP_ActivationDate__c = System.today();
                assetObj.Status = NSP_SalesConstants.ACTIVE_STATUS;
                if(assetObj.RecordTypeId == ASSET_RECORDTYPE_ID){
                    assetObj.NSP_First_Pay_Date__c = System.today().addMonths(-1).toStartOfMonth();
                }
                else{
                    assetObj.NSP_First_Pay_Date__c = System.today();
                }

                updateList.add(assetObj);
            }
        }
        try {
            if(updateList != null && updateList.size() > 0){
                database.update(updateList);
            }
        } catch ( Exception e ) {
            NSP_AssetUpdate.handleException( e , 'activateAsset' );
        }
    }

    //
    // Method Name : assetTermination
    // Description : Method to update asset status to terminated, condition added for DF-02743
    // Author : CPQ Team
    // Date : 11/20/2022
    // @param opTermMap Map of termination date.
    // @return void
    //
    public static void assetTermination(Map<Id,Date> opTermMap){
        List<Asset> updateList = new List<Asset>();
        List<Asset> assetList = [
            SELECT Id , Status , NSP_Termination_Date__c , NSP_OrderProduct__c
            FROM Asset
            WHERE (
                NSP_OrderProduct__c IN :opTermMap.keySet()
                AND NSP_Termination_Date__c = NULL
                AND NSP_Process_Order_Change__c = false
            )
        ];
        for(Asset assetObj:assetList){
            if(opTermMap.get(assetObj.NSP_OrderProduct__c) != null){
                assetObj.Status = NSP_SalesConstants.TERMINATED_STATUS;
                assetObj.NSP_Termination_Date__c = opTermMap.get(assetObj.NSP_OrderProduct__c);
                updateList.add(assetObj);
            }
        }
        try {
            if ( updateList != null && !updateList.isEmpty() ){
                database.update(updateList);
            }
        } catch ( Exception e ) {
            NSP_AssetUpdate.handleException( e , 'assetTermination' );
        }
    }

    //
    // Method Name : createAssetProject
    // Description : Method to create asset project record on Order Review
    // Author : CPQ Team
    // Date : 11/20/2022
    // @param orderIdSet Order Id.
    // @return void
    //
    @future
    public static void createAssetProject(Set<Id> orderIdSet){
        List<Project_Asset__c> updateList = new List<Project_Asset__c>();
        Map<Id,OrderItem> ordProdMap = new Map<Id,OrderItem>();
        List<OrderItem> orderProductList = [
            SELECT Id , SBQQ__Status__c , NSP_ServiceAsset__c , NSP_Project__c , Order.AccountId
            FROM OrderItem
            WHERE OrderId IN :orderIdSet
        ];
        for(OrderItem opObj: orderProductList){
            if(opObj.NSP_ServiceAsset__c != null){
                ordProdMap.put(opObj.Id,opObj);
            }
        }
        if(ordProdMap != null && ordProdMap.size() > 0){
            List<Asset> assetList = [
                SELECT Id , Status , NSP_Termination_Date__c , NSP_OrderProduct__c
                FROM Asset
                WHERE NSP_OrderProduct__c IN :ordProdMap.keySet()
                LIMIT 1
            ];
            for(Asset assetObj:assetList){
                if(ordProdMap.get(assetObj.NSP_OrderProduct__c).NSP_Project__c != null){
                    Project_Asset__c projAssetObj = new Project_Asset__c();
                    projAssetObj.Asset__c = assetObj.Id;
                    projAssetObj.Project__c = ordProdMap.get(assetObj.NSP_OrderProduct__c).NSP_Project__c;
                    updateList.add(projAssetObj);
                }
            }
            try {
                if ( ( updateList != null ) && !updateList.isEmpty() ){
                    database.upsert(updateList);
                }
            } catch ( Exception e ) {
                NSP_AssetUpdate.handleException( e , 'createAssetProject' );
            }
        }
    }

    //
    // Method Name : setActiveUsers
    // Description : Method to set active users when usage is processed
    // Author : CPQ Team
    // Date : 07/20/2022
    // @param activeUserMap Map of total usage quantity.
    // @return void
    //
    public static void setActiveUsers(Map<Id,Decimal> activeUserMap){
        List<Asset> updateAssetList = new List<Asset>();
        if ( activeUserMap != null && !activeUserMap.isEmpty() ) {
            List<Asset> assetList = [
                SELECT Id , Status , NSP_Termination_Date__c , NSP_Current_SaaS_Seats__c
                FROM Asset
                WHERE Id IN :activeUserMap.keySet()
            ];
            for(Asset assetObj : assetList){
                if ( activeUserMap.containsKey(assetObj.Id)
                    && (activeUserMap.get(assetObj.Id) != null)
                    )
                {
                    assetObj.NSP_Current_SaaS_Seats__c = String.valueOf(activeUserMap.get(assetObj.Id).intValue());
                    updateAssetList.add(assetObj);
                }
            }
        }
        try {
            if(updateAssetList != null && updateAssetList.size() > 0){
                database.update(updateAssetList);
            }
        } catch ( Exception e ) {
            NSP_AssetUpdate.handleException( e , 'setActiveUsers' );
        }
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_AssetUpdate.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_AssetUpdate.class.getName() ,
            methodName ,
            e
        );
    }

}
//