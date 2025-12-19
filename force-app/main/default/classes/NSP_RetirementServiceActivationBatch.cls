public class NSP_RetirementServiceActivationBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<sObject> , Database.Stateful {
    // test w/ NSP_RetirementServiceActivationBatchTest (91%)

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_RetirementServiceActivationBatch() {
    }

    //
    // ISelfSchedulable
    //

    // runs M-F at 6am central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_RetirementServiceActivationBatch ~ Retirement Service Activation on Order Products related to Assets in the Client Sub Plan History ~ M-F at 6 AM' + suffix ,
            '0 0 6 ? * MON-FRI *' ,
            new NSP_RetirementServiceActivationBatch()
        );
    }

    //
    // Schedulable
    //

    public void execute( SchedulableContext sc ) {
        this.call( 'run' , null );
    }

    //
    // Callable
    //

    public Object call( String action , Map<String,Object> args ) {
        Object response = null;
        if ( action == 'run' ) {
            response = this.run();
        }
        return response;
    }

    //
    // IJobRunnable
    //

    public Id run() {
        Id response = null;
        if ( NSP_RetirementServiceActivationBatch.isEnabled ) {
            response = Database.executeBatch(
                new NSP_RetirementServiceActivationBatch() ,
                NSP_RetirementServiceActivationBatch.batchSize
            );
        }
        return response;
    }

    //
    // Batchable
    //

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
                    AND ( NOT ( NSP_Plan_ID__r.NSP_Plan_Id__c LIKE '7%' ) )
                )
            ]
        );
    }

    // Collecting the order id from the order product associated to Asset and
    // Checking all order product for that order which has order trigger as Plan activation and Order product is not Active.
    public void execute( Database.BatchableContext bc , list<NSP_Client_Sub_Plan_History__c> clientSubPlanHistoryList ) {
        if ( NSP_RetirementServiceActivationBatch.isEnabled ) {
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
                            'execute:update' ,
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

    //
    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a Scheduled job...
    //

    private static RetirementServiceActivationBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = RetirementServiceActivationBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = false;
                if ( NSP_RetirementServiceActivationBatch.settings != null ) {
                    local = NSP_RetirementServiceActivationBatch.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    private static Integer batchSize {
        private get {
            if ( batchSize == null ) {
                Integer local = 200;
                if ( ( NSP_RetirementServiceActivationBatch.settings != null )
                    && ( NSP_RetirementServiceActivationBatch.settings.BatchSize__c != null )
                    )
                {
                    local = NSP_RetirementServiceActivationBatch.settings.BatchSize__c.intValue();
                }
                // batch size must be greater than zero...
                if ( local < 1 ) {
                    local = 1;
                }
                // batch size must be less than or equal to 2000...
                if ( local > 2000 ) {
                    local = 2000;
                }
                batchSize = local;
            }
            return batchSize;
        }
        private set;
    }

}
//