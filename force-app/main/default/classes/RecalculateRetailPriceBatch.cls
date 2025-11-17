public with sharing class RecalculateRetailPriceBatch implements ISelfSchedulable , Schedulable , Database.Batchable<sObject> , Database.Stateful  {
    // test w/ RecalculateRetailPriceBatchTest (92%)

    //
    // External Entry Point
    //

    public static void executeBatch() {
        Database.executeBatch(
            new RecalculateRetailPriceBatch( ) ,
            RecalculateRetailPriceBatch.batchSize
        );
    }

    //
    //schedulable
    //
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'RecalculateRetailPriceBatch ~ Recalculate Retail Price on Modified Purchased Products daily at 1 AM' + suffix ,
            '0 0 1 * * ?' , // Everyday at 1 AM
            New RecalculateRetailPriceBatch()
        );
    }

    public void execute( SchedulableContext sc ) {
        Database.executeBatch(
            new RecalculateRetailPriceBatch() ,
            RecalculateRetailPriceBatch.batchSize
        );
    }

    //preserved asset records across all chunks
    //this prevents reprocessing of purchased products belonging to same asset
    private Set<Id> assetIdSet = new Set<Id>();

    //constants
    private static final String CANCELED = 'Canceled';

    //fetch all Assets for which Purchased Products need to be re-evaluated
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(
            [
                SELECT Parent.Asset__c
                FROM Purchased_Product__History
                WHERE (
                    ( CreatedDate = LAST_N_DAYS:1  )
                    AND (
                        ( //price is updated
                            ( Field = 'Component_Price__c' OR Field = 'created' )
                            AND ( Parent.Purchase_Status__c != :CANCELED )
                        )
                        OR ( //purchase status is changed
                            ( Field = 'Purchase_Status__c' )
                        )
                    )
                )
            ]
        );
    }

    public void execute(Database.BatchableContext bc, List<Purchased_Product__History> scope) {
        if( ( scope != null )
           && ( !scope.isEmpty() )
           && ( RecalculateRetailPriceBatch.isEnabled ))
        {
            //assets for current chunk
            Set<Id> localAssetIdSet = new Set<Id>();

            //make sure asset hasn't already been processed
            for(Purchased_Product__History historyRecord : scope){
                //new asset in the chunk
                if(( historyRecord.Parent.Asset__c != null )
                   && ( !assetIDSet.contains(historyRecord.Parent.Asset__c) ))
                {
                    //use new asset for recalculation
                    localAssetIdSet.add(historyRecord.Parent.Asset__c);
                }
            }

            if(( localAssetIdSet != null )
               && ( !localAssetIdSet.isEmpty() ))
            {
                //fetch all Purchased Products under those unique Assets for current chunk
                List<Purchased_Product__c> allPP = [
                    SELECT
                        Id ,
                        Is_Bundle__c ,
                        Asset__c ,
                        Component_Price__c ,
                        Retail_Price__c ,
                        Parent_Bundle_Product__c ,
                        Product__r.ProductCode ,
                        Purchase_Status__c
                    FROM Purchased_Product__c
                    WHERE Asset__c IN :localAssetIdSet
                    ORDER BY Asset__c, Is_Bundle__c DESC
                ];

                //rollup logic
                RecalculateRetailPriceBatch.rollUpBundles(allPP);

                //update set with new values
                this.assetIdSet.addAll(localAssetIdSet);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        if( RecalculateRetailPriceBatch.isEnabled ){
            try {
                //email success batch job
                List<String> toUsers = new List<String>();
                if ( ( RecalculateRetailPriceBatch.monitorEmailAddresses != null )
                    && !RecalculateRetailPriceBatch.monitorEmailAddresses.isEmpty()
                   )
                {
                    toUsers.addAll( RecalculateRetailPriceBatch.monitorEmailAddresses );
                }
                RecalculateRetailPriceBatch.sendEmail(
                    toUsers ,
                    'RecalculateRetailPriceBatch Complete' ,
                    'Retail Prices on various Purchased Products were recalculated successfully accross '
                    + this.assetIdSet.size() + ' Assets.'
                );

            } catch ( exception e ) {
                NSP_ErrorLogHandler.logException(
                    RecalculateRetailPriceBatch.class.getName() ,
                    'finish',
                    e
                );
            }

        }
    }

    //method that rolls-up prices of child Purchased products on to parent
    private static void rollUpBundles(List<Purchased_Product__c> allPPs){
        if( allPPs != null && !allPPs.isEmpty() ){

            //maps for storing parents and their price data
            //key = ProductCode-AssetId
            Map<String, Purchased_Product__c> productCodeMap = new Map<String,Purchased_Product__c>();
            Map<String, Decimal> productPriceMap = new Map<String, Decimal>();

            //process purchased products
            for(Purchased_Product__C pp : allPPs){
                RecalculateRetailPriceBatch.handleParentProduct(pp,productCodeMap,productPriceMap);
                RecalculateRetailPriceBatch.handleChildProduct(pp,productCodeMap,productPriceMap);
                RecalculateRetailPriceBatch.handleStandaloneProduct(pp,productCodeMap,productPriceMap);
            }

            //insert only parent purchased records (subset of chunk size)
            RecalculateRetailPriceBatch.performDML( productCodeMap , productPriceMap );
        }
    }

    //method to handle Parent Purchased Products
    private static void handleParentProduct(
        Purchased_Product__c pp,
        Map<String,Purchased_Product__c> productCodeMap,
        Map<String, Decimal> productPriceMap)
    {
        if(( pp != null )
           && ( pp.Is_Bundle__c )
           && ( String.isBlank( pp.Parent_Bundle_Product__c ) )
           && ( String.isNotBlank( pp.Product__r.ProductCode ) )
           && ( pp.Purchase_Status__c != CANCELED )
           && ( productCodeMap != null )
           && ( productPriceMap != null )
          )
        {
            //assign current parent in maps
            productCodeMap.put(pp.Product__r.ProductCode + '-' + pp.Asset__c, pp);
            productPriceMap.put(pp.Product__r.ProductCode + '-' + pp.Asset__c, pp.Component_Price__c);
        }
    }

    //method to handle Child Purchased Products
    private static void handleChildProduct(
        Purchased_Product__c pp,
        Map<String,Purchased_Product__c> productCodeMap,
        Map<String, Decimal> productPriceMap)
    {
        if(( pp != null)
           && ( !pp.Is_Bundle__c )
           && ( String.isNotBlank( pp.Parent_Bundle_Product__c ) )
           && ( pp.Component_Price__c != null )
           && ( pp.Component_Price__c != 0.00)
           && ( pp.Purchase_Status__c != CANCELED)
           && ( productCodeMap != null )
           && ( productPriceMap != null ))
        {
            //check for active and applicable bundles
            for(String parent : pp.Parent_Bundle_Product__c.split(',')){
                if(( productCodeMap.containsKey( parent  + '-' + pp.Asset__c ) )
                   && ( productPriceMap.containsKey( parent + '-' + pp.Asset__c ) ))
                {
                    //rollup component price to available bundle/s
                    productPriceMap.put( parent + '-' + pp.Asset__c ,
                                        productPriceMap.get( parent + '-' + pp.Asset__c ) + pp.Component_Price__c );
                }
            }
        }
    }

    //method to handle Standalone Purchased Products
    private static void handleStandaloneProduct(
        Purchased_Product__c pp,
        Map<String,Purchased_Product__c> productCodeMap,
        Map<String, Decimal> productPriceMap)
    {
        if(( pp != null )
           && ( !pp.Is_Bundle__c )
           && ( String.isBlank( pp.Parent_Bundle_Product__c ) )
           && ( pp.Purchase_Status__c != CANCELED )
           && ( productCodeMap != null )
           && ( productPriceMap != null ))
        {
            productCodeMap.put( pp.Product__r.ProductCode + '-' + pp.Asset__c , pp );
            productPriceMap.put( pp.Product__r.ProductCode + '-' + pp.Asset__c , pp.Component_Price__c );
        }
    }


    //method that perdorms dml for Parent Purchased products
    private static void performDML(Map<String, Purchased_Product__c> productCodeMap, Map<String, Decimal> productPriceMap){
        List<Purchased_Product__c> updateList = new List<Purchased_Product__c>();
        if(productCodeMap != null && productPriceMap != null){
            for(String code: productCodeMap.keyset()){
                //check if price needs to be updated
                if(( productPriceMap.containsKey( code ) )
                   && ( productPriceMap.get( code ) != null )
                   && ( productPriceMap.get( code ) != productCodeMap.get( code ).Retail_Price__c )
                   && ( productCodeMap.get( code ) != null ))
                {
                    Purchased_Product__c updateProduct = productCodeMap.get( code );
                    updateProduct.Retail_Price__c = productPriceMap.get( code );
                    updateList.add( updateProduct );
                }
            }
        }
        if( updateList != null && !updateList.isEmpty()){
            try{
                Database.SaveResult[] purchasedProductSaveResult = Database.update( updateList , false );
                NSP_ErrorLogHandler.logResults(
                    RecalculateRetailPriceBatch.class.getName() ,
                    'execute:update',
                    purchasedProductSaveResult
                );
            }
            catch( exception e) {
                NSP_ErrorLogHandler.logException(
                    RecalculateRetailPriceBatch.class.getName() ,
                    'execute' ,
                    e
                );
            }
        }
    }

    //method to send email via flow
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

    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a running job...
    //

    private static RecalculateRetailPriceBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = RecalculateRetailPriceBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( RecalculateRetailPriceBatch.settings != null ) {
                    local = RecalculateRetailPriceBatch.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    public static Integer batchSize {
        public get {
            if ( batchSize == null ) {
                Integer local = 200;
                if ( ( RecalculateRetailPriceBatch.settings != null )
                    && ( RecalculateRetailPriceBatch.settings.BatchSize__c != null )
                   )
                {
                    local = RecalculateRetailPriceBatch.settings.BatchSize__c.intValue();
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
                if ( RecalculateRetailPriceBatch.settings != null ) {
                    String rawMonitorEmailAddresses = RecalculateRetailPriceBatch.settings.MonitorEmailAddresses__c;
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