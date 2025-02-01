public class NSP_RetirementServiceActivationBatch implements Database.Batchable<sObject> , Database.Stateful {
    // test w/ NSP_RetirementServiceActivationBatchTest (88%)

    //Querying the data from client sub plan history which has Start date as today and current subplan is true
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id ,
                    NSP_Start_Date__c ,
                    NSP_Asset__c ,
                    NSP_Asset__r.NSP_OrderProduct__r.OrderId ,
                    NSP_Asset__r.NSP_OrderProduct__r.SBQQ__Status__c ,
                    NSP_Asset__r.NSP_OrderProduct__r.NSP_Order_Activation_Trigger__c ,
                    NSP_Current_Subplan__c ,
                    CreatedDate
                FROM NSP_Client_Sub_Plan_History__c
                WHERE (
                    ( NSP_Current_Subplan__c = true )
                    AND ( NSP_Start_Date__c <= :System.today() )
                )
            ]
        );
    }

    // Collecting the order id from the order product associated to Asset and
    // Checking all order product for that order which has order trigger as Plan activation and Order product is not Active.
    public void execute( Database.BatchableContext bc , list<NSP_Client_Sub_Plan_History__c> clientSubPlanHistoryList ) {
        try {
            if ( !clientSubPlanHistoryList.isEmpty() ) {
                Map<Id,NSP_Client_Sub_Plan_History__c> mapOrderSubClient = new Map<Id,NSP_Client_Sub_Plan_History__c>();
                for ( NSP_Client_Sub_Plan_History__c subPlan : clientSubPlanHistoryList ) {
                    mapOrderSubClient.put(
                        subPlan.NSP_Asset__r.NSP_OrderProduct__r.OrderId ,
                        subPlan
                    );
                }
                List<OrderItem> updateOrderItemList = new List<OrderItem>();
                if ( !mapOrderSubClient.isEmpty() ) {
                    for ( OrderItem orderItemRecord : [
                                SELECT
                                    Id ,
                                    OrderId ,
                                    Order.EffectiveDate ,
                                    ServiceDate ,
                                    SBQQ__Status__c ,
                                    NSP_Order_Activation_Trigger__c
                                FROM OrderItem
                                WHERE (
                                    ( OrderId != null )
                                    AND ( OrderId IN :mapOrderSubClient.keySet() )
                                    AND ( SBQQ__Status__c != :NSP_SalesConstants.ACTIVATED_STATUS )
                                    AND ( NSP_Order_Activation_Trigger__c = :NSP_SalesConstants.RET_Plan_Activation )
                                )
                            ]
                        )
                    {
                        orderItemRecord.ServiceDate = this.serviceDateHelper( orderItemRecord , mapOrderSubClient );
                        // updating the order products to 'Activated' status.
                        orderItemRecord.SBQQ__Status__c = NSP_SalesConstants.ACTIVATED_STATUS;
                        updateOrderItemList.add( orderItemRecord );
                    }
                }
                if ( !updateOrderItemList.isEmpty() ) {
                    Database.SaveResult[] results = Database.update( updateOrderItemList , false );
                    NSP_ErrorLogHandler.logResults(
                        NSP_RetirementServiceActivationBatch.class.getName() ,
                        'execute' ,
                        results
                    );
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_RetirementServiceActivationBatch.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    public void finish( Database.BatchableContext bc ) {
    }

    // calculate the Order Product Start Date (OrderItem.ServiceDate)
    // ~ default to current value in OrderItem.ServiceDate...
    // ~ attempt to use the first day of the month for the custom start date (NSP_Start_Date__c) found in the related NSP_Client_Sub_Plan_History__c record...
    // ~ value must be on/after the Order Start Date (Order.EffectiveDate) to prevent DmlExceptions...
    private Date serviceDateHelper( OrderItem record , Map<Id,NSP_Client_Sub_Plan_History__c> historyMap ) {
        Date response = null;
        if ( record != null ) {
            response = record.ServiceDate;
            if ( ( record.OrderId != null )
                && ( historyMap != null )
                && historyMap.containsKey( record.OrderId )
                )
            {
                NSP_Client_Sub_Plan_History__c history = historyMap.get( record.OrderId );
                if ( ( history != null )
                    && ( history.NSP_Start_Date__c != null )
                    && ( record.Order != null )
                    && ( record.Order.EffectiveDate != null )
                    )
                {
                    Date startOfMonthDate = history.NSP_Start_Date__c.toStartOfMonth();
                    // prevent DmlExceptions ~ FIELD_INTEGRITY_EXCEPTION, An order product's Start Date can't be earlier than Order Start Date.: Start Date: [ServiceDate]
                    if ( startOfMonthDate >= record.Order.EffectiveDate ) {
                        response = startOfMonthDate;
                    }
                }
            }
        }
        return response;
    }

}
//