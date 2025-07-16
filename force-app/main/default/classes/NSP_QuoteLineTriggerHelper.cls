public class NSP_QuoteLineTriggerHelper {
    // test w/ NSP_ProcessSerialIdsTest, QuoteExtControllerTests (94%)
    // test w/ NSP_ProcessSerialIdsTest (94%)
    // test w/ QuoteExtControllerTests (63%)

    public void beforeUpdateDirector( List<SBQQ__Quoteline__c> newList ) {
        if ( ( newList != null ) && !newList.isEmpty() ) {
            List<Id> renewedSubIds = new List<Id>();
            List<Id> originalPriceNullIds = new List<Id>();
            for ( SBQQ__Quoteline__c qline : newList ) {
                if ( ( qline.NSP_Action_Type__c == NSP_CPQConstants.QUOTE_TYPE_RENEWAL )
                    && ( qline.SBQQ__RenewedSubscription__c != null )
                    )
                {
                    renewedSubIds.add( qline.SBQQ__RenewedSubscription__c );
                }
                if ( qline.NSP_Original_Price__c == null ) {
                    originalPriceNullIds.add( qline.Id );
                }
            }
            this.updateOriginalPriceOnAmend( originalPriceNullIds , newList );
            this.populateSerialIds( newList , renewedSubIds );
        }
    }

    private void populateSerialIds( List<SBQQ__Quoteline__c> newList , List<Id> renewedSubIds ) {
        if ( ( newList != null ) && !newList.isEmpty() ) {
            Map<Id,List<String>> flaggedEntitlementsMap = this.retrieveEntitlementsFlggedForET( renewedSubIds );
            for ( SBQQ__Quoteline__c qline : newList ) {
                if ( ( qline.NSP_Action_Type__c == NSP_CPQConstants.QUOTE_TYPE_RENEWAL )
                    && flaggedEntitlementsMap.containsKey( qline.SBQQ__RenewedSubscription__c )
                    )
                {
                    List<String> flaggedEntitlements = flaggedEntitlementsMap.get( qline.SBQQ__RenewedSubscription__c );
                    if ( ( flaggedEntitlements != null ) && !flaggedEntitlements.isEmpty() ) {
                        qLine.NSP_ET_Checked_Serial_Ids__c = String.join(
                            flaggedEntitlements ,
                            ','
                        );
                    }
                }
            }
        }
    }

    private Map<Id,List<String>> retrieveEntitlementsFlggedForET( List<Id> renewedSubIds ) {
        Map<Id,List<String>> flaggedEntitlementsMap = new Map<Id,List<String>>();
        if ( ( renewedSubIds != null ) && !renewedSubIds.isEmpty() ) {
            for ( NSP_Support_Entitlement__c entitlement : [
                        SELECT
                            Id ,
                            NSP_Supported_Subscription__c ,
                            NSP_Serial_ID__c
                        FROM NSP_Support_Entitlement__c
                        WHERE (
                            ( NSP_Early_Termination_Notice__c = true )
                            AND ( NSP_Supported_Subscription__c IN :renewedSubIds )
                        )
                    ]
                )
            {
                if ( !flaggedEntitlementsMap.containsKey( entitlement.NSP_Supported_Subscription__c ) ) {
                    flaggedEntitlementsMap.put(
                        entitlement.NSP_Supported_Subscription__c ,
                        new List<String>()
                    );
                }
                flaggedEntitlementsMap.get( entitlement.NSP_Supported_Subscription__c ).add( entitlement.NSP_Serial_ID__c );
            }
        }
        return flaggedEntitlementsMap;
    }

    private Map<Id,SBQQ__QuoteLine__c> selectOriginalQuoteLines( List<Id> recordIds ) {
        Map<Id,SBQQ__QuoteLine__c> records = new Map<Id,SBQQ__QuoteLine__c>();
        if ( ( recordIds != null ) && !recordIds.isEmpty() ) {
            records = new Map<Id,SBQQ__QuoteLine__c>(
                [
                    SELECT
                        Id ,
                        SBQQ__UpgradedSubscription__c ,
                        SBQQ__Quote__r.SBQQ__Type__c ,
                        SBQQ__UpgradedSubscription__r.NSP_Net_Total__c ,
                        NSP_Original_Price__c
                    FROM SBQQ__QuoteLine__c
                    WHERE ( Id IN :recordIds )
                ]
            );
        }
        return records;
    }

    // This method updates the original price field on all the quote line on amendment
    private void updateOriginalPriceOnAmend( List<Id> originalPriceNullIds , List<SBQQ__QuoteLine__c> quoteLines ) {
        Map<Id,SBQQ__QuoteLine__c> quoteLinesQueried = this.selectOriginalQuoteLines( originalPriceNullIds );
        if ( ( quoteLinesQueried != null )
            && !quoteLinesQueried.isEmpty()
            && ( quoteLines != null )
            && !quoteLines.isEmpty()
            )
        {
            for ( SBQQ__QuoteLine__c qline : quoteLines ) {
                if ( quoteLinesQueried.containsKey( qline.Id ) ) {
                    SBQQ__QuoteLine__c quoteLineQueried = quoteLinesQueried.get( qline.Id );
                    if ( ( quoteLineQueried != null )
                        && ( quoteLineQueried.SBQQ__Quote__r != null )
                        && ( quoteLineQueried.SBQQ__Quote__r.SBQQ__Type__c == 'Amendment' )
                        && ( quoteLineQueried.SBQQ__UpgradedSubscription__r != null )
                        && ( qline.SBQQ__UpgradedSubscription__c != null )
                        && ( qline.NSP_Original_Price__c == null )
                        )
                    {
                        qline.NSP_Original_Price__c = quoteLineQueried.SBQQ__UpgradedSubscription__r.NSP_Net_Total__c;
                    }
                }
            }
        }
    }

}
//