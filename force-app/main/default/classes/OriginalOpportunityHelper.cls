// intentionally `without sharing` to ensure access to all OrderItem records...
public class OriginalOpportunityHelper {

    //
    // Method Name : stampOriginalOpportunityFromAsset
    // Description : When NSP_Rev_Rec_Rules_Reviewed__c is checked,
    // find the first order product with a service asset, read Opportunity__c off
    // that asset, and stamp it on Original_Opportunity__c on the order.
    //
    public static void stampOriginalOpportunityFromAsset( Map<Id,Order> orderNewMap , Map<Id,Order> orderOldMap ) {
        Set<Id> eligibleOrderIds = new Set<Id>();
        if ( orderNewMap != null && !orderNewMap.isEmpty() ) {
            for ( Order newOrder : orderNewMap.values() ) {
                Order oldOrder = null;
                if ( ( orderNewMap != null ) && orderNewMap.containsKey( newOrder.Id ) ) {
                    oldOrder= orderOldMap.get( newOrder.Id );
                }
                Boolean revRecFlipped = (
                    ( oldOrder != null )
                    && ( oldOrder.NSP_Rev_Rec_Rules_Reviewed__c == false )
                    && ( newOrder.NSP_Rev_Rec_Rules_Reviewed__c == true )
                );
                if ( revRecFlipped && ( newOrder.Original_Opportunity__c == null ) ) {
                    eligibleOrderIds.add( newOrder.Id );
                }
            }
            // Fetch first order product per order that has a service asset, along with that asset's Opportunity__c
            Map<Id,Id> orderIdToOpportunityId = new Map<Id,Id>();
            if ( !eligibleOrderIds.isEmpty() ) {
                for ( OrderItem oi : [
                            SELECT Id , OrderId, NSP_ServiceAsset__r.Opportunity__c
                            FROM OrderItem
                            WHERE (
                                ( OrderId IN :eligibleOrderIds )
                                AND ( NSP_ServiceAsset__c != null )
                                AND ( NSP_ServiceAssetCategory__c != null )
                            )
                            ORDER BY CreatedDate ASC
                        ]
                    )
                {
                    if ( !orderIdToOpportunityId.containsKey( oi.OrderId )
                        && ( oi.NSP_ServiceAsset__r.Opportunity__c != null )
                        )
                    {
                        orderIdToOpportunityId.put( oi.OrderId , oi.NSP_ServiceAsset__r.Opportunity__c );
                    }
                }
            }
            for ( Order newOrder : orderNewMap.values() ) {
                if ( orderIdToOpportunityId.containsKey( newOrder.Id ) ) {
                    newOrder.Original_Opportunity__c = orderIdToOpportunityId.get( newOrder.Id );
                }
            }
        }
    }

}
//