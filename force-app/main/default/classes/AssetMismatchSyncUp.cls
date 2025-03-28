public with sharing class AssetMismatchSyncUp {
    // test w/ AssetMismatchSyncUpTest (89%)

    // STY-341702
    //
    // Method Name : assetOrderProductLinkUp
    // Description : Method to link asset and order product2822
    // Author : CPQ Team     Date : 03/17/2025
    // @param set orderId
    // @return void
    //
    @InvocableMethod(label='Link Asset Mismatch' description='links all mismatched assets.' category='Asset')
    public static void assetOrderProductLinkUp( List<String> orderId ) {
        try {
            List<OrderItem> orditems = [
                SELECT Id , Mismatch_AssetId__c
                FROM OrderItem
                WHERE (
                    ( Orderid IN :OrderId )
                    AND ( Mismatch_AssetId__c != null )
                )
            ];
            List<OrderItem> ordItemsToBeUpdated = new List<OrderItem>();
            Map<String,String> mapOpAst = new Map<String,String>();
            if ( !orditems.isempty() ) {
                for ( OrderItem oi : orditems ) {
                    mapOpAst.put( oi.Mismatch_AssetId__c , oi.Id );
                    oi.Mismatch_AssetId__c = '';
                    ordItemsToBeUpdated.add( oi );
                }
            }
            List<Asset> assetLst = [
                SELECT Id,NSP_OrderProduct__c
                FROM Asset
                WHERE ( Id IN :mapOpAst.keyset() )
            ];
            List<Asset> asstsUpdated = new List<Asset>();
            if ( !assetLst.isempty() ) {
                for ( Asset ast : assetLst ) {
                    Asset asst = new Asset();
                    asst.Id = ast.Id;
                    asst.NSP_OrderProduct__c =  mapOpAst.get( asst.Id );
                    asstsUpdated.add( asst );
                }
            }
            if ( !asstsUpdated.isempty() ) {
                List<Database.SaveResult> resultsasstsUpdated = Database.update( asstsUpdated , false );
                NSP_ErrorLogHandler.logResults(
                    AssetMismatchSyncUp.class.getName() ,
                    'assetOrderProductLinkUp:update:Asset' ,
                    resultsasstsUpdated
                );
            }
            List<Order> ords = [
                SELECT Id,Mismatch_Asset__c
                FROM Order
                WHERE (
                    ( Id IN :OrderId )
                    AND ( Mismatch_Asset__c = true )
                )
            ];
            List<Order> ordsTobeUpdated = new List<Order>();
            if ( !ords.isempty() ) {
                for ( Order ord : ords ) {
                    ord.Mismatch_Asset__c =false;
                    ordsTobeUpdated.add( ord );
                }
            }
            if ( !ordItemsToBeUpdated.isEmpty() ) {
                List<Database.SaveResult> resultsOrderItem = Database.update( ordItemsToBeUpdated , false );
                NSP_ErrorLogHandler.logResults(
                    AssetMismatchSyncUp.class.getName() ,
                    'assetOrderProductLinkUp:update:OrderItem' ,
                    resultsOrderItem
                );
            }
            if ( !ordsTobeUpdated.isEmpty() ) {
                List<Database.SaveResult> resultsOrder = Database.update( ordsTobeUpdated , false );
                NSP_ErrorLogHandler.logResults(
                    AssetMismatchSyncUp.class.getName() ,
                    'assetOrderProductLinkUp:update:Order' ,
                    resultsOrder
                );
            }
        } catch(Exception e ) {
            NSP_ErrorLogHandler.logException(
                AssetMismatchSyncUp.class.getName() ,
                'assetOrderProductLinkUp ' ,
                e
            );
        }
    }

    public static void setFlagAsset( List<Order> newList , Map<Id,Order> orderOldMap ) {
        List<Id> ordlist  = new List<Id>();
        for ( Order ord : newList ) {
            if ( ( ( ord.Status == NSP_CPQConstants.ORDER_ACTIVATED ) || ( ord.Status == NSP_CPQConstants.ORDER_REVIEWED ) )
                && ( ord.Id != null )
                && ( orderOldMap != null )
                && orderOldMap.containsKey( ord.Id )
                && ( orderOldMap.get( ord.Id ) != null )
                && ( orderOldMap.get( ord.Id ).Status == NSP_CPQConstants.ORDER_DRAFT )
                && ord.Mismatch_Asset__c == false
                )
            {
                ordlist.add( ord.Id );
            }
        }
        if ( !ordlist.isEmpty() ) {
            if ( Limits.getFutureCalls() < Limits.getLimitFutureCalls() ) { // prevent LimitExceptions...
                setFlagAssetCheckerAsync( ordlist );
            } else {
                setFlagAssetCheckerStatic( ordlist );
            }
        }
    }

    @future
    private static void setFlagAssetCheckerAsync( List<Id> ordlist ) {
        setFlagAssetCheckerStatic(ordlist);
    }

    private static void setFlagAssetCheckerStatic( List<Id> ordlist ) {
        try {
            Map<Id,OrderItem> mapAsstOI = new Map<Id,OrderItem>();
            Map<Id,Order> mapOrdOPr = new Map<Id,Order>();
            for ( Order ord : [
                        SELECT
                            Id ,
                            Mismatch_Asset__c ,
                            (
                                SELECT
                                    Id ,
                                    Mismatch_AssetId__c ,
                                    NSP_ServiceAsset__c
                                FROM OrderItems
                            )
                        FROM Order
                        WHERE (
                            ( Id IN :ordlist )
                            AND ( Mismatch_Asset__c = false )
                        )
                    ]
                )
            {
                for ( OrderItem oi : ord.OrderItems ) {
                    if ( oi.NSP_ServiceAsset__c != null ) {
                        mapAsstOI.put( oi.NSP_ServiceAsset__c , oi );
                        mapOrdOPr.put( oi.Id , ord );
                    }
                }
            }
            List<OrderItem> ordItemsToBeUpdated = new List<OrderItem>();
            List<Order> ordsTobeUpdated = new List<Order>();
            for ( Asset ast : [
                        SELECT Id , NSP_OrderProduct__c
                        FROM Asset
                        WHERE ( Id IN :mapAsstOI.keyset() )
                    ]
                )
            {
                if ( ( ast.NSP_OrderProduct__c != null )
                    && ( ast.Id != null )
                    && mapAsstOI.containsKey( ast.Id )
                    && ( mapAsstOI.get( ast.Id ) != null )
                    && ( ast.NSP_OrderProduct__c != mapAsstOI.get( ast.Id ).Id )
                    )
                {
                    mapOrdOPr.get( mapAsstOI.get( ast.Id ).Id ).Mismatch_Asset__c = true;
                    mapAsstOI.get( ast.Id ).Mismatch_AssetId__c = ast.Id;
                    Order objorder = new Order();
                    objorder.Id = mapOrdOPr.get( mapAsstOI.get( ast.Id ).Id ).Id;
                    objorder.Mismatch_Asset__c = true;
                    ordsTobeUpdated.add( objorder );
                    OrderItem oi = new OrderItem();
                    oi.Id = mapAsstOI.get( ast.Id ).Id;
                    oi.Mismatch_AssetId__c = ast.Id;
                    ordItemsToBeUpdated.add( oi );
                }
            }
            if ( !ordItemsToBeUpdated.isEmpty() ) {
                List<Database.SaveResult> resultsOrderItem = Database.update( ordItemsToBeUpdated , false );
                NSP_ErrorLogHandler.logResults(
                    AssetMismatchSyncUp.class.getName() ,
                    'setFlagAssetCheckerStatic:update:OrderItem' ,
                    resultsOrderItem
                );
            }
            if ( !ordsTobeUpdated.isEmpty() ) {
                List<Database.SaveResult> resultsOrder = Database.update( ordsTobeUpdated , false );
                NSP_ErrorLogHandler.logResults(
                    AssetMismatchSyncUp.class.getName() ,
                    'setFlagAssetCheckerStatic:update:Order' ,
                    resultsOrder
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                AssetMismatchSyncUp.class.getName() ,
                'setFlagAssetCheckerStatic:update:Asset' ,
                e
            );
        }
    }

}
//