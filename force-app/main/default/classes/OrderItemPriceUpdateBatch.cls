public with sharing class OrderItemPriceUpdateBatch implements Database.Batchable<sObject> , Database.Stateful {
    // test w/ OrderItemPriceUpdateTest (96%)

    //variable to maintain count of processed records
    private Map<String,Integer> DML_COUNTS = new Map<String,Integer>{
        'SBQQ__SubscriptionConsumptionRate__c-Success' => 0 ,
        'SBQQ__SubscriptionConsumptionRate__c-Fail' => 0 ,
        'SBQQ__OrderItemConsumptionRate__c-Success' => 0 ,
        'SBQQ__OrderItemConsumptionRate__c-Fail' => 0 ,
        'SBQQ__Subscription__c-Success' => 0 ,
        'SBQQ__Subscription__c-Fail' => 0 ,
        'OrderItem-Success' => 0 ,
        'OrderItem-Fail' => 0
    };

    //constant for all subscrption price fields
    private static final List<String> subsPriceFields = new List<String>{
        'SBQQ__CustomerPrice__c' ,
        'SBQQ__ListPrice__c' ,
        'SBQQ__NetPrice__c' ,
        'SBQQ__RegularPrice__c' ,
        'SBQQ__SpecialPrice__c'
    };

    //constant for all OP price fields
    private static final List<String> opPriceFields = new List<String>{
        'SBQQ__QuotedListPrice__c' ,
        'blng__BillableUnitPrice__c' ,
        'UnitPrice' ,
        'NSP_Consumption_Rate_Per_Unit__c'
    };

    //constant for all objects being processed
    private static final List<String> objectAPIs = new List<String>{
        'SBQQ__SubscriptionConsumptionRate__c' ,
        'SBQQ__OrderItemConsumptionRate__c' ,
        'SBQQ__Subscription__c' ,
        'OrderItem'
    };

    private static final String SUCCESS = '-Success';
    private static final String FAIL = '-Fail';
    private static final String AMOUNT = 'Amount';
    private static final String PER_UNIT = 'PerUnit';
    private static final String FLAT_FEE = 'FlatFee';
    private Set<Id> orderIdSet = new Set<Id>();
    private Map<Id,String> orderPricingModelMap = new Map<Id,String>();

    public static void executeBatch() {
        Database.executeBatch(
            new OrderItemPriceUpdateBatch() ,
            OrderItemPriceUpdateBatch.batchSize
        );
    }

    //query all OPs with pending status
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        publishBatchStatus( 'Started' );
        return Database.getQueryLocator([
            SELECT
                Id ,
                Monthly_Minimum_Price_Increase_Type__c ,
                Monthly_Minimum_Price_Increase_Value__c ,
                NSP_Consumption_Rate_Flat_Price__c ,
                Per_Unit_Price_Increase_Type__c ,
                Per_Unit_Price_Increase_Value__c ,
                Price_Increase_Status__c ,
                Last_Batch_Execution_Date__c ,
                SBQQ__QuotedListPrice__c ,
                blng__BillableUnitPrice__c ,
                UnitPrice ,
                NSP_Consumption_Rate_Per_Unit__c ,
                Update_Record_Price__c ,
                Pricing_Model__c ,
                OrderId
            FROM OrderItem
            WHERE (
                ( Price_Increase_Status__c = 'Pending' )
                AND (
                    ( Monthly_Minimum_Price_Increase_Type__c != null )
                    OR ( Per_Unit_Price_Increase_Type__c != null )
                )
            )
        ]);
    }

    //process OP and related records in batches
    public void execute( Database.BatchableContext bc , List<OrderItem> scope ) {
        if ( OrderItemPriceUpdateBatch.isEnabled
            && ( scope!= null )
            && !scope.isEmpty()
            )
        {
            //publish platform event for LWC
            publishBatchStatus( 'Running' );
            //get map from scope
            Map<Id, OrderItem> opMap = new Map<Id,OrderItem>( scope );
            //process Subscription Consumption Rates
            List<SBQQ__SubscriptionConsumptionRate__c> subCSRates = [
                SELECT
                    Id ,
                    SBQQ__PricingMethod__c ,
                    OrderItemId__c ,
                    SBQQ__Price__c ,
                    Is_Price_Updated__c
                FROM SBQQ__SubscriptionConsumptionRate__c
                WHERE (
                    ( OrderItemId__c IN :opMap.keySet() )
                    AND ( SBQQ__SubscriptionConsumptionSchedule__r.SBQQ__MatchingAttribute__c != 'Scholarship' )
                    AND ( Update_Record_Price__c = true )
                )
            ];
            processCSRates( subCSRates , opMap );
            performDML( subCSRates );
            //process OrderItem Consumption Rates
            List<SBQQ__OrderItemConsumptionRate__c> ordItemCSRates = [
                SELECT
                    Id ,
                    SBQQ__PricingMethod__c ,
                    OrderItemId__c ,
                    SBQQ__Price__c ,
                    Is_Price_Updated__c
                FROM SBQQ__OrderItemConsumptionRate__c
                WHERE (
                    ( OrderItemId__c IN :opMap.keySet() )
                    AND ( SBQQ__OrderItemConsumptionSchedule__r.SBQQ__MatchingAttribute__c != 'Scholarship' )
                    AND ( Update_Record_Price__c = true )
                )
                ];
            processCSRates( ordItemCSRates , opMap );
            performDML( ordItemCSRates );
            //process subscription records
            List<SBQQ__Subscription__c> subRecords = [
                SELECT
                    Id ,
                    SBQQ__OrderProduct__c ,
                    Is_Price_Updated__c ,
                    SBQQ__CustomerPrice__c ,
                    SBQQ__ListPrice__c ,
                    SBQQ__NetPrice__c ,
                    SBQQ__RegularPrice__c ,
                    SBQQ__SpecialPrice__c
                FROM SBQQ__Subscription__c
                WHERE (
                    ( SBQQ__OrderProduct__c IN :scope )
                    AND ( Update_Record_Price__c = true )
                )
            ];
            OrderItemPriceUpdateBatch.processSubscriptions( subRecords , opMap );
            this.performDML( subRecords );
            //stamp pricing model on Contract and Asset
            this.processPricingModel( scope );
            //process OPs
            OrderItemPriceUpdateBatch.processOPs( scope );
            this.performDML( scope );
        }
    }

    //email results and stats
    public void finish( Database.BatchableContext bc ) {
        if ( OrderItemPriceUpdateBatch.isEnabled ) {
            publishBatchStatus( 'Executed' );
            try {
                //email success batch job
                String userId = UserInfo.getUserId();
                List<User> records = [
                    SELECT Email
                    FROM User
                    WHERE Id = :userId
                    LIMIT 1
                ];
                User record = null;
                if ( ( records != null ) && !records.isEmpty() ) {
                    record = records[0];
                }
                if ( ( record != null ) && String.isNotBlank( record.Email ) ) {
                    List<String> toUsers = new List<String>();
                    toUsers.add(record.Email);
                    if ( ( OrderItemPriceUpdateBatch.monitorEmailAddresses != null )
                        && !OrderItemPriceUpdateBatch.monitorEmailAddresses.isEmpty()
                       )
                    {
                        toUsers.addAll( OrderItemPriceUpdateBatch.monitorEmailAddresses );
                    }
                    OrderItemPriceUpdateBatch.sendEmail(
                        toUsers ,
                        'OrderItemPriceUpdateBatch Complete' ,
                        constructMailBody()
                    );
                }
            } catch ( exception e ) {
                NSP_ErrorLogHandler.logException(
                    CreateGLTransactionsBatch.class.getName() ,
                    'finish',
                    e
                );
            }
        }
    }

    //method to publish platform event with all stats of records processed
    private void publishBatchStatus( String status ) {
        if ( String.isNotBlank( status ) ) {
            PriceUpdateBatchJobStatus__e event = new PriceUpdateBatchJobStatus__e();
            event.Status__c = status;
            event.SubscriptionSuccess__c = this.DML_COUNTS.get( 'SBQQ__Subscription__c' + SUCCESS );
            event.SubscriptionFail__c = this.DML_COUNTS.get( 'SBQQ__Subscription__c' + FAIL );
            event.SubscriptionCSRateSuccess__c = this.DML_COUNTS.get( 'SBQQ__SubscriptionConsumptionRate__c' + SUCCESS );
            event.SubscriptionCSRateFail__c = this.DML_COUNTS.get( 'SBQQ__SubscriptionConsumptionRate__c' + FAIL );
            event.OrderItemCSRateSuccess__c = this.DML_COUNTS.get( 'SBQQ__OrderItemConsumptionRate__c' + SUCCESS );
            event.OrderItemCSRateFail__c = this.DML_COUNTS.get( 'SBQQ__OrderItemConsumptionRate__c' + FAIL );
            event.OrderItemSuccess__c = this.DML_COUNTS.get( 'OrderItem' + SUCCESS );
            event.OrderItemFail__c = this.DML_COUNTS.get( 'OrderItem' + FAIL );
            EventBus.publish( event );
        }
    }

    //disable CPQ triggers, perform DML & log results
    private void performDML( List<sObject> records ) {
        if ( ( records != null ) && !records.isEmpty() ) {
            Schema.sObjectType soType = records[0].getSobjectType();
            Schema.DescribeSObjectResult soTypeDescribe = soType.getDescribe();
            String sObjectAPIName = soTypeDescribe.getName();
            try {
                SBQQ.TriggerControl.disable();
                List<Database.SaveResult> results = Database.update( records , false );
                NSP_ErrorLogHandler.logResults(
                    OrderItemPriceUpdateBatch.class.getName() ,
                    'performDML:update:' + sObjectAPIName ,
                    results
                );
                //update count of records processed
                updateCount( sObjectAPIName , results );
            } catch( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    OrderItemPriceUpdateBatch.class.getName() ,
                    'performDML:' + sObjectAPIName ,
                    e
                );
            } finally {
                SBQQ.TriggerControl.enable();
            }
        }
    }

    //keep count of record updates
    private void updateCount( String sObjectAPIName , List<Database.SaveResult> results ) {
        if ( String.isNotBlank( sObjectAPIName )
            && ( results != null )
            && !results.isEmpty()
            )
        {
            for ( Database.SaveResult res : results ) {
                //construct key using constants
                String key = sObjectAPIName;
                key = ( res.isSuccess() ) ? key + SUCCESS : key + FAIL;
                //update map values
                this.DML_COUNTS.put(
                    key ,
                    this.DML_COUNTS.get( key ) + 1
                );
            }
        }
    }

    //method to process consumption rate records
    private static void processCSRates( List<sObject> records , Map<Id,OrderItem> opMap) {
        if ( ( records != null )
            && !records.isEmpty()
            && ( opMap != null )
            && !opMap.isEmpty()
            )
        {
            for ( sObject record : records ) {
                String pricingMethod = (String)record.get( 'SBQQ__PricingMethod__c' );
                Id opID = (String)record.get( 'OrderItemId__c' );
                //update price only for FlatFee/PerUnit
                if ( ( pricingMethod != null )
                    && String.isNotBlank( pricingMethod )
                    && (
                        ( pricingMethod == PER_UNIT )
                        || ( pricingMethod == FLAT_FEE )
                    )
                    && ( opID != null )
                    && opMap.containsKey( opID )
                    )
                {
                    updatePrice(
                        record ,
                        opMap.get( opID ) ,
                        pricingMethod
                    );
                }
            }
        }
    }

    //update price on consumption rate record
    private static void updatePrice( sObject record , OrderItem op , String feeType ) {
        if ( ( record != null )
            && ( op != null )
            && String.isNotBlank( feeType )
            )
        {
            //choose increase type based on business logic (FlatFee/PerUnit)
            String increaseType = null;
            Decimal increaseValue = 0;
            //fee type is flatfee
            if ( ( feeType == FLAT_FEE )
                && ( op.Monthly_Minimum_Price_Increase_Type__c != null )
                && String.isNotBlank( op.Monthly_Minimum_Price_Increase_Type__c )
                )
            {
                increaseType = op.Monthly_Minimum_Price_Increase_Type__c;
                increaseValue = ( ( op.Monthly_Minimum_Price_Increase_Value__c != null ) ? op.Monthly_Minimum_Price_Increase_Value__c : 0 );
            }
            //fee type is perunit
            if ( ( feeType == PER_UNIT )
                && ( op.Per_Unit_Price_Increase_Type__c != null )
                && String.isNotBlank( op.Per_Unit_Price_Increase_Type__c )
                )
            {
                increaseType = op.Per_Unit_Price_Increase_Type__c;
                increaseValue = ( ( op.Per_Unit_Price_Increase_Value__c != null ) ? op.Per_Unit_Price_Increase_Value__c : 0 );
            }
            OrderItemPriceUpdateBatch.priceCalculationHelper(
                increaseValue ,
                increaseType ,
                record ,
                new List<String>{ 'SBQQ__Price__c' }
            );
            record.put( 'Is_Price_Updated__c' , true );
        }
    }

    //update price fields on subscription records
    private static void processSubscriptions( List<SBQQ__Subscription__c> subRecords , Map<Id,OrderItem> opMap ) {
        if ( ( subRecords != null )
            && !subRecords.isEmpty()
            && ( opMap != null )
            && !opMap.isEmpty()
            )
        {
            for ( SBQQ__Subscription__c sub : subRecords ) {
                //check if OP exists in map
                if ( !opMap.containsKey( sub.SBQQ__OrderProduct__c ) ) {
                    continue;
                }
                //fetch OP
                OrderItem op = opMap.get( sub.SBQQ__OrderProduct__c );
                if ( ( op.Per_Unit_Price_Increase_Type__c == null )
                    || String.isBlank( op.Per_Unit_Price_Increase_Type__c )
                    )
                {
                    continue;
                }
                OrderItemPriceUpdateBatch.priceCalculationHelper(
                    op.Per_Unit_Price_Increase_Value__c ,
                    op.Per_Unit_Price_Increase_Type__c ,
                    sub ,
                    subsPriceFields
                );
                sub.put( 'Is_Price_Updated__c' , true );
            }
        }
    }

    //method to help with price calculation
    private static void priceCalculationHelper(
        Decimal increaseValue ,
        String increaseType ,
        sObject record ,
        List<String> fields
        )
    {
        if ( ( increaseValue != null )
            && String.isNotBlank( increaseType )
            && ( record != null )
            && ( fields != null )
            && ( !fields.isEmpty() )
            )
        {
            Decimal increaseFactor = ( 1 + ( increaseValue / 100 ) );
            for ( String field : fields ) {
                Decimal price = 0;
                if ( record.get( field ) != null ) {
                    price = (Decimal)record.get( field );
                    Decimal value = ( price + increaseValue );
                    if ( increaseType == 'Percentage' ) {
                        value = ( price * increaseFactor ).setScale( 2 , System.RoundingMode.HALF_UP );
                    }
                    record.put( field , value );
                }
            }
        }
    }

    //method to process OPs separately
    private static void processOPs( List<OrderItem> scope ) {
        if ( ( scope != null ) && !scope.isEmpty() ) {
            for ( OrderItem op : scope ) {
                //mark record as executed
                op.Price_Increase_Status__c = 'Executed';
                op.Last_Batch_Execution_Date__c = system.today();
                //check price update requirement
                if ( !op.Update_Record_Price__c ) {
                    continue; //skip price updates
                }
                //perform flat price update
                populateFlatPrice( op );
                //perform per unit update
                populatePerUnitPrices( op );
            }
        }
    }

    //update OrderItem flat prices
    private static void populateFlatPrice( OrderItem op ) {
        //check conditional monthly update
        if ( ( op != null )
            && String.isNotBlank( op.Monthly_Minimum_Price_Increase_Type__c )
            )
        {
            Decimal value = 0;
            if ( op.Monthly_Minimum_Price_Increase_Value__c != null ) {
                value = op.Monthly_Minimum_Price_Increase_Value__c;
            }
            OrderItemPriceUpdateBatch.priceCalculationHelper(
                value ,
                op.Monthly_Minimum_Price_Increase_Type__c ,
                op ,
                new List<String>{ 'NSP_Consumption_Rate_Flat_Price__c' }
            );
        }
    }

    //update OrderItem Per unit prices
    private static void populatePerUnitPrices( OrderItem op ) {
        if ( ( op != null )
            && String.isNotBlank( op.Per_Unit_Price_Increase_Type__c )
            )
        {
            Decimal value = 0;
            if ( op.Per_Unit_Price_Increase_Value__c != null ) {
                value = op.Per_Unit_Price_Increase_Value__c;
            }
            OrderItemPriceUpdateBatch.priceCalculationHelper(
                value ,
                op.Per_Unit_Price_Increase_Type__c ,
                op ,
                opPriceFields
            );
        }
    }

    //method to process Pricning Model On Assets and Contracts
    private void processPricingModel( List<OrderItem> scope ) {
        if ( ( scope != null ) && ( !scope.isEmpty() ) ) {
            //maintain localOrders
            Set<Id> localOrderIdsSet = new Set<Id>();
            //add un processed orders to local set and Pricing Map
            for ( OrderItem item : scope ) {
                if ( String.isNotBlank( item.OrderId )
                    && ( this.orderIdSet != null )
                    && !this.orderIdSet.contains( item.OrderId )
                    && String.isNotBlank( item.Pricing_Model__c ) //blanks are not processed
                    )
                {
                    //new order
                    localOrderIdsSet.add( item.OrderId );
                    this.orderPricingModelMap.put( item.OrderId , item.Pricing_Model__c );
                }
            }
            //maintain processed orders
            this.orderIdSet.addAll( localOrderIdsSet );
            this.processContracts( localOrderIdsSet );
            this.processAssets( localOrderIdsSet );
        }
    }

    //method to stamp Pricing Model on Contracts
    private void processContracts( Set<Id> localOrderIdsSet ) {
        if ( ( localOrderIdsSet != null ) && !localOrderIdsSet.isEmpty() ) {
            //get Contracts
            List<Contract> conRecords = [
                SELECT
                    Id ,
                    NSP_Pricing_Model__c ,
                    SBQQ__Order__c
                FROM Contract
                WHERE ( SBQQ__Order__c IN :localOrderIdsSet)
            ];

            if ( ( conrecords != null ) && !conrecords.isEmpty() ) {
                //update pricing model on Contract
                for ( Contract con : conrecords ) {
                    if ( String.isNotBlank( con.SBQQ__Order__c )
                        && ( this.orderPricingModelMap != null )
                        && this.orderPricingModelMap.containsKey( con.SBQQ__Order__c )
                        && ( this.orderPricingModelMap.get( con.SBQQ__Order__c ) != null )
                        )
                    {
                        con.NSP_Pricing_Model__c = this.orderPricingModelMap.get( con.SBQQ__Order__c );
                    }
                }
                //update contracts
                this.performDML( conrecords );
            }
        }
    }

    private void processAssets( Set<Id> localOrderIdsSet ) {
        if ( ( localOrderIdsSet != null ) && !localOrderIdsSet.isEmpty() ) {
            //extract service assetsfor new local Orders
            List<Asset> serviceAssetList = [
                SELECT
                    Id ,
                    NSP_Price_Level__c ,
                    NSP_OrderProduct__c ,
                    NSP_OrderProduct__r.OrderId
                FROM Asset
                WHERE (
                    Id IN (//check all available OPs for a service asset
                        SELECT NSP_ServiceAsset__c
                        FROM OrderItem
                        WHERE (
                            ( OrderId IN :localOrderIdsSet )
                            AND ( NSP_ServiceAsset__c != null )
                            AND ( SBQQ__QuotedQuantity__c > 0 )
                        )
                    )
                )
            ];
            if ( ( serviceAssetList != null ) && !serviceAssetList.isEmpty() ) {
                //update pricing model on Asset
                for ( Asset serviceAsset : serviceAssetList ) {
                    if ( String.isNotBlank( serviceAsset.NSP_OrderProduct__c )
                        && String.isNotBlank( serviceAsset.NSP_OrderProduct__r.OrderId )
                        && ( this.orderPricingModelMap != null )
                        && this.orderPricingModelMap.containsKey( serviceAsset.NSP_OrderProduct__r.OrderId )
                        )
                    {
                        serviceAsset.NSP_Price_Level__c = this.orderPricingModelMap.get( serviceAsset.NSP_OrderProduct__r.OrderId );
                    }
                }
                //update Assets
                this.performDML( serviceAssetList );
            }
        }
    }

    //method to make email body dynamically
    private String constructMailBody() {
        String emailBody = 'Your batch job has completed.</br></br>';
        for ( String objectAPI: objectAPIs ) {
            String objectStats = ''
                + objectAPI + ':</br>'
                + this.DML_COUNTS.get( objectAPI + SUCCESS ) + SUCCESS
                + ' '
                + this.DML_COUNTS.get( objectAPI + FAIL ) + FAIL
                + '</br></br>';
            emailBody = emailBody + objectStats;
        }
        return emailBody;
    }

    private static void sendEmail( String[] listOfToAddresses , String subject , String body ) {
        Map<String,Object> inputs = new Map<String,Object>();
        if ( !listOfToAddresses.isEmpty() ) {
            inputs.put( 'toEmailAddresses' , listOfToAddresses );
            inputs.put( 'emailSubject' , subject );
            inputs.put( 'emailBody' , body );
            Flow.Interview.Send_Email sendEmailFlow = new Flow.Interview.Send_Email( inputs );
            sendEmailFlow.start();
        }
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a running job...
    //

    private static OrderItemPriceUpdateBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = OrderItemPriceUpdateBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( OrderItemPriceUpdateBatch.settings != null ) {
                    local = OrderItemPriceUpdateBatch.settings.IsEnabled__c;
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
                if ( ( OrderItemPriceUpdateBatch.settings != null )
                    && ( OrderItemPriceUpdateBatch.settings.BatchSize__c != null )
                   )
                {
                    local = OrderItemPriceUpdateBatch.settings.BatchSize__c.intValue();
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

    private static List<String> monitorEmailAddresses  {
        private get {
            if ( monitorEmailAddresses == null ) {
                List<String> local = new List<String>();
                if ( OrderItemPriceUpdateBatch.settings != null ) {
                    String rawMonitorEmailAddresses = OrderItemPriceUpdateBatch.settings.MonitorEmailAddresses__c;
                    if ( String.isNotBlank( rawMonitorEmailAddresses ) ) {
                        List<String> splitMonitorEmailAddresses = rawMonitorEmailAddresses.split( '\r\n' );
                        if ( ( splitMonitorEmailAddresses != null ) && ( splitMonitorEmailAddresses.size() > 0 ) ) {
                            local = splitMonitorEmailAddresses;
                        }
                    }
                }
                monitorEmailAddresses = local;
            }
            return monitorEmailAddresses;
        }
        private set;
    }

}
//