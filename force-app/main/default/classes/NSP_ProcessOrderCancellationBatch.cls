public class NSP_ProcessOrderCancellationBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<sObject> , Database.AllowsCallouts {
    // test w/ NSP_ProcessOrderCancellationBatchTest (86%)

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_ProcessOrderCancellationBatch() {
    }

    //
    // ISelfSchedulable
    //

    // runs M-F at 11pm central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_ProcessOrderCancellationBatch ~ process asset and create amendment on contract ~ M-F at 11 PM' + suffix ,
            '0 0 23 ? * 2-6 *' ,
            new NSP_ProcessOrderCancellationBatch()
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
        if ( NSP_ProcessOrderCancellationBatch.isEnabled ) {
            response = Database.executeBatch(
                new NSP_ProcessOrderCancellationBatch() ,
                NSP_ProcessOrderCancellationBatch.batchSize
            );
        }
        return response;
    }

    //
    // Batchable
    //

    public database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id ,
                    NSP_RET_lead_parent__r.AccountId ,
                    AccountId ,
                    NSP_OrderProduct__r.Order.SBQQ__Quote__c ,
                    NSP_OrderProduct__r.Order.SBQQ__Quote__r.RecordTypeId ,
                    NSP_OrderProduct__r.Order.OpportunityId ,
                    NSP_Change_Order_Process_Contract_Status__c ,
                    NSP_ReAssigned_Order_Id__c
                FROM Asset
                WHERE (
                    ( NSP_Process_Order_Change__c = true )
                    AND ( NSP_Change_Order_Process_Contract_Status__c = 'Ready To Close' )
                    AND (
                        (
                            ( NSP_OrderProduct__c != null )
                            AND ( NSP_OrderProduct__r.OrderId != null )
                        )
                        OR ( NSP_ReAssigned_Order_Id__c != null )
                    )
                )
            ]
        );
    }

    public void execute( Database.BatchableContext bc , List<Asset> scope ) {
        if ( NSP_ProcessOrderCancellationBatch.isEnabled ) {
            try {
                Set<Id> orderIdSet = new Set<Id>();
                for ( Asset eachAsset : scope ) {
                    Id ordereIdStr = ( ( eachAsset.NSP_ReAssigned_Order_Id__c != null ) ? eachAsset.NSP_ReAssigned_Order_Id__c : eachAsset.NSP_OrderProduct__r.OrderId );
                    orderIdSet.add( ordereIdStr );
                    eachAsset.NSP_Change_Order_Process_Contract_Status__c = 'Contract Closed';
                }
                if ( !orderIdSet.isEmpty() ) {
                    List<OrderItem> orderItemUpdateList = new List<OrderItem>();
                    List<SBQQ__Subscription__c> subscriptionUpdateList = new List<SBQQ__Subscription__c>();
                    Date lastOfPreviousMonth = System.today().toStartOfMonth().addDays( -1 );
                    for ( OrderItem eachItem : [
                                SELECT
                                    Id ,
                                    SBQQ__TerminatedDate__c ,
                                    SBQQ__SubscriptionType__c ,
                                    EndDate
                                FROM OrderItem
                                WHERE ( OrderId IN :orderIdSet )
                            ]
                        )
                    {
                        eachItem.SBQQ__TerminatedDate__c = lastOfPreviousMonth;
                        orderItemUpdateList.add( eachItem );
                    }
                    for ( SBQQ__Subscription__c eachSub : [
                                SELECT
                                    Id ,
                                    SBQQ__TerminatedDate__c ,
                                    SBQQ__SubscriptionType__c ,
                                    SBQQ__SubscriptionEndDate__c
                                FROM SBQQ__Subscription__c
                                WHERE ( SBQQ__OrderProduct__r.OrderId IN :orderIdSet )
                            ]
                        )
                    {
                        eachSub.SBQQ__TerminatedDate__c = lastOfPreviousMonth;
                        if ( eachSub.SBQQ__SubscriptionType__c != 'Evergreen' ) {
                            eachSub.SBQQ__SubscriptionEndDate__c = lastOfPreviousMonth;
                        }
                        subscriptionUpdateList.add( eachSub );
                    }
                    if ( !subscriptionUpdateList.isEmpty() ) {
                        List<Database.SaveResult> subResults = Database.update( subscriptionUpdateList , false );
                        NSP_ErrorLogHandler.logResults(
                            NSP_ProcessOrderCancellationBatch.class.getName() ,
                            'execute:update:SBQQ__Subscription__c' ,
                            subResults
                        );
                    }
                    if ( !orderItemUpdateList.isEmpty() ) {
                        List<Database.SaveResult> orderitemResults = Database.update( orderItemUpdateList , false );
                        NSP_ErrorLogHandler.logResults(
                            NSP_ProcessOrderCancellationBatch.class.getName() ,
                            'execute:update:OrderItem' ,
                            orderitemResults
                        );
                    }
                    List<Database.SaveResult> results = Database.update( scope , false );
                    NSP_ErrorLogHandler.logResults(
                        NSP_ProcessOrderCancellationBatch.class.getName() ,
                        'execute:update:Asset' ,
                        results
                    );
                }
            } catch ( Exception e ) {
                NSP_ProcessOrderCancellationBatch.handleException( e , 'execute' );
            }
        }
    }

    public void finish( Database.BatchableContext bc ) {
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_ProcessOrderCancellationBatch.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_ProcessOrderCancellationBatch.class.getName() ,
            methodName ,
            e
        );
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a Scheduled job...
    //

    private static ProcessOrderCancellationBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = ProcessOrderCancellationBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( NSP_ProcessOrderCancellationBatch.settings != null ) {
                    local = NSP_ProcessOrderCancellationBatch.settings.IsEnabled__c;
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
                // batch size should be 1 because sbqq contract amendment api works for only 1 record...
                Integer local = 1;
                if ( ( NSP_ProcessOrderCancellationBatch.settings != null )
                    && ( NSP_ProcessOrderCancellationBatch.settings.BatchSize__c != null )
                    )
                {
                    local = NSP_ProcessOrderCancellationBatch.settings.BatchSize__c.intValue();
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