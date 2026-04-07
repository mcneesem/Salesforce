public class NSP_UsageSummaryTriggerHelper {
    // test w/ NSP_UsageSummaryTriggerTest (83%)

    public void beforeUpdateDirector( Map<Id,blng__UsageSummary__c> usageSummNewMap , Map<Id,blng__UsageSummary__c> usageSummOldMap ) {
        // Copy Unbilled Subtotal to Interal field before status changes to Processed
        for ( blng__UsageSummary__c summRec : usageSummNewMap.values() ) {
            if ( ( summRec.blng__Status__c != usageSummOldMap.get( summRec.Id ).blng__Status__c )
                && ( summRec.blng__Status__c == 'Processed' )
                && ( summRec.NSP_Billed_Free__c == true )
                )
            {
                summRec.NSP_Internal_Waived_Amount__c=usageSummOldMap.get( summRec.Id ).blng__Subtotal__c;
            }
        }
    }

    public void afterUpdateDirector( Map<Id,blng__UsageSummary__c> usageSummNewMap , Map<Id,blng__UsageSummary__c> usageSummOldMap ) {
        this.rollUpWaivedAmountToSubscription( usageSummNewMap , usageSummOldMap );
    }

    // After usage Summary status changed to Processed, rollup internal Waived amount to Subscription
    private void rollUpWaivedAmountToSubscription( Map<Id,blng__UsageSummary__c> usageSummNewMap , Map<Id,blng__UsageSummary__c> usageSummOldMap ) {
        Set<Id> subscriptionIds = new Set<Id>();
        Map<Id,Decimal> ordProdIdMap = new Map<Id,Decimal>();
        List<SBQQ__Subscription__c> subscriptionsToUpdate = new List<SBQQ__Subscription__c>();
        for ( blng__UsageSummary__c summRec : usageSummNewMap.values() ) {
            if ( ( summRec.blng__Status__c != usageSummOldMap.get( summRec.Id ).blng__Status__c )
                && ( summRec.blng__Status__c == 'Processed' )
                && ( summRec.NSP_Billed_Free__c == true )
                )
            {
                subscriptionIds.add( summRec.NSP_Subscription_Id__c );
            }
            if ( ( summRec.blng__Status__c != usageSummOldMap.get( summRec.Id ).blng__Status__c )
                && ( summRec.blng__Status__c == 'Processed' )
                )
            {
                ordProdIdMap.put( summRec.blng__OrderProduct__c , summRec.blng__TotalQuantity__c );
            }
        }
        if ( !subscriptionIds.isEmpty() ) {
            Map<Id,SBQQ__Subscription__c> subRecsMap=new Map<Id,SBQQ__Subscription__c>(
                [
                    SELECT Id , NSP_Waived_Amount__c
                    FROM SBQQ__Subscription__c
                    WHERE ( Id IN :subscriptionIds )
                ]
            );
            for ( blng__UsageSummary__c summRec : usageSummNewMap.values() ) {
                if ( subRecsMap.get( summRec.NSP_Subscription_Id__c ) != null ) {
                    Decimal tempWaivedAmount = summRec.NSP_Internal_Waived_Amount__c;
                    if ( subRecsMap.get( summRec.NSP_Subscription_Id__c ).NSP_Waived_Amount__c != null ) {
                        tempWaivedAmount = (
                            subRecsMap.get( summRec.NSP_Subscription_Id__c ).NSP_Waived_Amount__c
                            + summRec.NSP_Internal_Waived_Amount__c
                        );
                    }
                    SBQQ__Subscription__c subRec = new SBQQ__Subscription__c(
                        Id=summRec.NSP_Subscription_Id__c ,
                        NSP_Waived_Amount__c=tempWaivedAmount
                    );
                    subscriptionsToUpdate.add( subRec );
                }
            }
            if ( !subscriptionsToUpdate.isEmpty() ) {
                try {
                    update subscriptionsToUpdate;
                } catch ( Exception e ) {
                    NSP_ErrorLogHandler.logException(
                        NSP_UsageSummaryTriggerHelper.class.getName() ,
                        'rollUpWaivedAmountToSubscription' ,
                        e
                    );
                }
            }
        }
        if ( ( ordProdIdMap != null ) && !ordProdIdMap.isEmpty() ) {
            NSP_UsageSummaryTriggerHelper.setUsageQty( ordProdIdMap );
        }
    }

    // update order product when usage summary record gets processed
    private static void setUsageQty( Map<Id,Decimal> ordProdIdMap ) {
        List<OrderItem> opUpdateList = new List<OrderItem>();
        List<OrderItem> orderProductList=[
            SELECT Id , SBQQ__Status__c , NSP_TotalUsageQuantity__c
            FROM OrderItem
            WHERE Id IN :ordProdIdMap.keySet()
        ];
        for ( OrderItem op : orderProductList ) {
            op.NSP_TotalUsageQuantity__c = ordProdIdMap.get( op.Id );
            opUpdateList.add( op );
        }
        try {
            if ( ( opUpdateList != null ) && !opUpdateList.isEmpty() ) {
                Database.update( opUpdateList );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_UsageSummaryTriggerHelper.class.getName() ,
                'setUsageQty' ,
                e
            );
        }
    }

}
//