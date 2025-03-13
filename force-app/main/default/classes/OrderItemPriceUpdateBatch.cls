public with sharing class OrderItemPriceUpdateBatch implements Database.Batchable<sObject> , Database.Stateful {
    // test w/ OrderItemPriceUpdateTest (94%)

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
    private static final String PERCENT = 'Percentage';
    private static final String AMOUNT = 'Amount';
    private static final String PER_UNIT = 'PerUnit';
    private static final String FLAT_FEE = 'FlatFee';

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
                NSP_Consumption_Rate_Per_Unit__c
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
                WHERE ( SBQQ__OrderProduct__c IN :scope )
            ];
            processSubscriptions( subRecords , opMap );
            performDML( subRecords );
            //process OPs
            processOPs( scope );
            performDML( scope );
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
                    'performDML: ' + sObjectAPIName + ' Updates.' ,
                    results
                );
                //update count of records processed
                updateCount( sObjectAPIName , results );
            } catch( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    OrderItemPriceUpdateBatch.class.getName() ,
                    'performDML: ' + sObjectAPIName + ' Updates.' ,
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
            Decimal increaseFactor = ( 1 + ( increaseValue / 100 ) );
            //update price field
            if ( increaseType != null ) {
                Decimal currPrice = ( ( (Decimal)record.get( 'SBQQ__Price__c' ) != null ) ? (Decimal)record.get( 'SBQQ__Price__c' ) : 0 );
                record.put(
                    'SBQQ__Price__c' ,
                    (increaseType == PERCENT) ? ( currPrice * increaseFactor ) : ( currPrice + increaseValue )
                );
                record.put( 'Is_Price_Updated__c' , true );
            }
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
                //check increase type for percent/amount
                String increaseType = op.Per_Unit_Price_Increase_Type__c;
                //use 0 if increaseVaue is null
                Decimal increaseValue = ( ( op.Per_Unit_Price_Increase_Value__c != null ) ? op.Per_Unit_Price_Increase_Value__c : 0 );
                Decimal increaseFactor = ( 1 + ( increaseValue / 100 ) );
                //update all price fields
                for ( String field : subsPriceFields ) {
                    Decimal price = ( ( (Decimal)sub.get( field ) != null ) ? (Decimal)sub.get( field ) : 0 );
                    sub.put(
                        field ,
                        ( ( increaseType == PERCENT ) ? ( price * increaseFactor ) : ( price + increaseValue ) )
                    );
                }
                //mark record as processed
                sub.put( 'Is_Price_Updated__c' , true );
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
                //check conditional monthly update
                if ( String.isNotBlank( op.Monthly_Minimum_Price_Increase_Type__c ) ) {
                    String monthlyType = op.Monthly_Minimum_Price_Increase_Type__c;
                    Decimal monthlyIncrease = ( ( op.Monthly_Minimum_Price_Increase_Value__c != null ) ? op.Monthly_Minimum_Price_Increase_Value__c : 0 );
                    Decimal monthlyFactor = ( 1 + ( monthlyIncrease / 100 ) );
                    Decimal currPrice = ( ( op.NSP_Consumption_Rate_Flat_Price__c != null ) ? op.NSP_Consumption_Rate_Flat_Price__c : 0 );
                    op.NSP_Consumption_Rate_Flat_Price__c = ( monthlyType == PERCENT ) ? ( currPrice * monthlyFactor ) : ( currPrice + monthlyIncrease );
                }
                //perform per unit update
                if ( String.isNotBlank(op.Per_Unit_Price_Increase_Type__c ) ) {
                    String increaseType = op.Per_Unit_Price_Increase_Type__c;
                    Decimal increaseValue = ( ( op.Per_Unit_Price_Increase_Value__c != null ) ? op.Per_Unit_Price_Increase_Value__c : 0 );
                    Decimal increaseFactor = ( 1 + ( increaseValue / 100 ) );
                    //update all price fields
                    for ( String priceField : opPriceFields ) {
                        Decimal price = ( ( (Decimal)op.get( priceField ) != null ) ? (Decimal)op.get( priceField ) : 0 );
                        op.put(
                            priceField ,
                            ( ( increaseType == PERCENT ) ? ( price * increaseFactor ) : ( price + increaseValue ) )
                        );
                    }
                }
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