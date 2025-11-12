public class PurchasedProductsCreateBatch implements Database.Batchable<SObject> {
    // test w/ PurchasedProductsCreateBatchTest (90%)

    private Set<Id> opportunityIds = new Set<Id>();
    private Map<String, Purchased_Product__c> purchasedProductsToUpdate = new Map<String, Purchased_Product__c>();
    private Set<Id> scopeIds = new Set<Id>();
    private Map<Id,Map<String,Asset>> oppToAssetMap = new Map<Id,Map<String,Asset>>();
    private List<Purchased_Product__c> existingProducts = new List<Purchased_Product__c>();
    private Set<String> existingProductKeys = new Set<String>();
    private List<Purchased_Product__c> purchasedProductsToInsert = new List<Purchased_Product__c>();
    private Map<Id, Decimal> itemToListPriceMap = new Map<Id, Decimal>();
    private List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
    private Map<Id,List<Id>> accToProductsMap = new Map<Id,List<Id>>();

    public static void executeBatch( List<Opportunity> records ) {
        if ( PurchasedProductsCreateBatch.isEnabled
            && ( records != null )
            && !records.isEmpty()
            )
        {
            Map<Id,Opportunity> recordMap = new Map<Id,Opportunity>( records );
            PurchasedProductsCreateBatch.executeBatch( recordMap.keySet() );
        }
    }

    public static void executeBatch( Set<Id> opportunityIdsLocal ) {
        if ( PurchasedProductsCreateBatch.isEnabled
            && ( opportunityIdsLocal != null )
            && !opportunityIdsLocal.isEmpty()
            )
        {
            Database.executeBatch(
                new PurchasedProductsCreateBatch( opportunityIdsLocal ) ,
                PurchasedProductsCreateBatch.purchasedProductBatchSize
            );
        }
    }

    private PurchasedProductsCreateBatch( Set<Id> opportunityIdsLocal ) {
        if ( opportunityIdsLocal != null ) {
            this.opportunityIds = opportunityIdsLocal;
        }
    }

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Opportunity
            WHERE ( Id IN :this.opportunityIds )
        ]);
    }

    public void execute( Database.BatchableContext bc , List<Opportunity> scope ) {
        try {
            if ( PurchasedProductsCreateBatch.isEnabled ) {
                this.purchasedProductsToUpdate = new Map<String,Purchased_Product__c>();
                this.purchasedProductsToInsert = new List<Purchased_Product__c>();
                Map<Id,Opportunity> scopeMap = new Map<Id,Opportunity>( scope );
                this.scopeIds = scopeMap.keySet();
                this.createOppToAssetMap();
                this.fetchExistingProducts();
                this.createExitingProductKeys();
                this.fetchOpportunityLineItems();
                this.getListPricesForOpportunityLineItems();
                if ( ( this.oppLineItems != null ) && !this.oppLineItems.isEmpty() ) {
                    for ( OpportunityLineItem lineItem : this.oppLineItems ) {
                        if (this.isValidLineItem( lineItem ) ) {
                            this.processLineItem( lineItem );
                        }
                    }
                }
                this.insertPurchasedProducts();
                this.collectProductsToCancel();
                this.updatePurchasedProducts();
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                PurchasedProductsCreateBatch.class.getName(),
                'execute',
                e
            );
        }
    }

    private Boolean isValidLineItem( OpportunityLineItem lineItem ) {
        Boolean isValid = false;
        if ( lineItem != null ) {
            //Validate quote quantity
            Boolean validateqq = false;
            if ( lineItem.SBQQ__QuoteLine__r != null
                && lineItem.SBQQ__QuoteLine__r.NSP_Quoted_Quantity__c > 0
                )
            {
                validateqq = true;
            }
            //Validate the recordTypeDevName
            Boolean validateRt = this.hasMatchingRecordTypeAsset( lineItem );
            //Validate Transaction Type
            Boolean validateTt = false;
            if ( lineItem.Opportunity != null
                && ( lineItem.Opportunity.NSP_TransactionType__c != 'Supplemental Only' )
                && ( lineItem.Opportunity.NSP_TransactionType__c != 'Termination' )
                )
            {
                validateTt = true;
            }
            if ( validateqq && validateRt && validateTt ) {
                isValid = true;
            }
        }
        return isValid;
    }

    private void processLineItem( OpportunityLineItem lineItem ) {
        this.getAccToProductsForExistingProductMap( lineItem );
        Id matchedAssetId = this.getMatchedAssetId( lineItem );
        String productKey = this.createProductKey( lineItem , matchedAssetId );
        if ( String.isNotBlank( productKey )
            && ( this.existingProductKeys != null )
            && !this.existingProductKeys.contains( productKey )
            )
        {
            this.createPurchasedProduct( lineItem );
        } else if ( ( lineItem != null )
            && ( lineItem.Opportunity != null )
            && ( lineItem.Opportunity.Type == 'Existing Product' )
            )
        {
            this.collectProductsToUpdate( lineItem );
        }
    }

    public void finish( Database.BatchableContext bc ) {
    }

    private void createExitingProductKeys() {
        if ( ( this.existingProducts != null ) && !this.existingProducts.isEmpty() ){
            for ( Purchased_Product__c product : this.existingProducts ) {
                if ( ( product != null )
                    && ( product.Product__c != null )
                    && ( product.Asset__c != null )
                    )
                {
                    this.existingProductKeys.add(
                        String.valueOf( product.Product__c ) + '_' + String.valueOf( product.Asset__c )
                    );
                }
            }
        }
    }

    private String createProductKey( OpportunityLineItem lineItem , Id matchedAssetId ) {
        String productKey = null;
        if ( ( lineItem != null )
            && ( lineItem.Product2Id != null )
            && ( matchedAssetId != null )
            )
        {
            productKey = lineItem.Product2Id + '_' + matchedAssetId;
        }
        return productKey;
    }

    private void getAccToProductsForExistingProductMap( OpportunityLineItem lineItem ) {
        if ( ( lineItem != null )
            && ( lineItem.Opportunity != null )
            && ( lineItem.Opportunity.SBQQ__AmendedContract__c == null )
            && ( lineItem.Opportunity.Type == 'Existing Product' )
            && ( lineItem.Product2Id != null )
            && ( lineItem.Opportunity.AccountId != null )
            )
        {
            Id accountId = lineItem.Opportunity.AccountId;
            if ( !this.accToProductsMap.containsKey( accountId ) ) {
                this.accToProductsMap.put( accountId , new List<Id>() );
            }
            this.accToProductsMap.get( accountId ).add( lineItem.Product2Id );
        }
    }

    private Id getMatchedAssetId( OpportunityLineItem lineItem ) {
        Id matchedAssetId = null;
        Map<String,Asset> assetsByRT = null;
        if ( ( lineItem != null )
            && ( lineItem.OpportunityId != null )
            && ( this.oppToAssetMap != null )
            && this.oppToAssetMap.containsKey( lineItem.OpportunityId )
            )
        {
            assetsByRT = this.oppToAssetMap.get( lineItem.OpportunityId );
        }
        if ( ( assetsByRT != null )
            && ( lineItem.Product2 != null )
            && ( lineItem.Product2.Purchased_Asset_Record_Type__c != null )
            && assetsByRT.containsKey( lineItem.Product2.Purchased_Asset_Record_Type__c )
            )
        {
            Asset matchedAsset = assetsByRT.get( lineItem.Product2.Purchased_Asset_Record_Type__c );
            if ( matchedAsset != null ) {
                matchedAssetId = matchedAsset.Id;
            }
        }
        return matchedAssetId;
    }

    private void fetchOpportunityLineItems() {
        List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();
        if ( ( this.oppToAssetMap != null ) && !this.oppToAssetMap.isEmpty() ) {
            lineItems = [
                SELECT
                    Id ,
                    Product2Id ,
                    OpportunityId ,
                    Opportunity.Type ,
                    Opportunity.AccountId ,
                    Opportunity.NSP_TransactionType__c ,
                    Opportunity.SBQQ__AmendedContract__c ,
                    Product2.Purchased_Asset_Record_Type__c ,
                    SBQQ__QuoteLine__r.NSP_Quoted_Quantity__c ,
                    SBQQ__QuoteLine__r.NSP_ActionType__c ,
                    SBQQ__QuoteLine__r.SBQQ__Quote__c ,
                    SBQQ__QuoteLine__r.SBQQ__Quote__r.Seasonal_Pricing__c ,
                    SBQQ__QuoteLine__r.SBQQ__Quote__r.NSP_Pricing_Model__c ,
                    TotalPrice ,
                    UnitPrice
                FROM OpportunityLineItem
                WHERE ( OpportunityId IN :this.oppToAssetMap.keySet() )
            ];
        }
        this.oppLineItems = lineItems;
    }

    private void fetchExistingProducts() {
        List<Purchased_Product__c> ppList = new List<Purchased_Product__c>();
        List<Id> assetIds = new List<Id>();
        if ( ( this.oppToAssetMap != null ) && !this.oppToAssetMap.isEmpty() ) {
            for ( Id oppId : this.oppToAssetMap.keySet() ) {
                Map<String,Asset> byRT = this.oppToAssetMap.get( oppId );
                if ( byRT != null ) {
                    for ( Asset a : byRT.values() ) {
                        assetIds.add( a.Id );
                    }
                }
            }
        }
        if ( !assetIds.isEmpty() ) {
            ppList = [
                SELECT
                    Id ,
                    Name ,
                    Opportunity_Product__c ,
                    Product__c ,
                    Asset__c ,
                    Purchase_Status__c ,
                    Opportunity_Product__r.Opportunity.AccountId ,
                    Original_Opportunity_Product__r.Opportunity.AccountId
                FROM Purchased_Product__c
                WHERE ( Asset__c IN :assetIds )
            ];
        }
        this.existingProducts =  ppList;
    }

    private Boolean hasMatchingRecordTypeAsset( OpportunityLineItem lineItem ) {
        Boolean isValid = false;
        Map<String,Asset> byRT = null;
        if ( ( lineItem != null )
            && ( lineItem.OpportunityId != null )
            && ( this.oppToAssetMap != null )
            && this.oppToAssetMap.containsKey( lineItem.OpportunityId )
            )
        {
            byRT = this.oppToAssetMap.get( lineItem.OpportunityId );
        }
        if ( ( byRT != null )
            && ( lineItem.Product2 != null )
            && ( lineItem.Product2.Purchased_Asset_Record_Type__c != null )
            && byRT.containsKey( lineItem.Product2.Purchased_Asset_Record_Type__c )
            )
        {
            isValid = true;
        }
        return isValid;
    }

    private void createPurchasedProduct( OpportunityLineItem lineItem ) {
        Purchased_Product__c pp = new Purchased_Product__c();
        if ( lineItem != null ) {
            if ( ( lineItem.Opportunity != null )
                && ( lineItem.Opportunity.Type == 'New Product' )
                )
            {
                pp.Original_Opportunity_Product__c = lineItem.Id;
            } else {
                pp.Opportunity_Product__c = lineItem.Id;
            }
            pp.Product__c = lineItem.Product2Id;
            pp.Total_Price__c = lineItem.UnitPrice;
            pp.Purchase_Status__c = 'Purchased';
            if ( ( this.itemToListPriceMap != null )
                && this.itemToListPriceMap.containsKey( lineItem.Id )
                )
            {
                pp.Component_Price__c = this.itemToListPriceMap.get( lineItem.Id );
            }
        }
        //set Asset field
        if ( ( lineItem != null )
            && ( lineItem.Product2 != null )
            && String.isNotBlank( lineItem.Product2.Purchased_Asset_Record_Type__c )
            && ( lineItem.OpportunityId != null )
            && ( this.oppToAssetMap != null )
            && this.oppToAssetMap.containsKey( lineItem.OpportunityId )
            && ( this.oppToAssetMap.get( lineItem.OpportunityId ) != null )
            && this.oppToAssetMap.get( lineItem.OpportunityId ).containsKey( lineItem.Product2.Purchased_Asset_Record_Type__c )
            )
        {
            Asset matchedAsset = this.oppToAssetMap.get( lineItem.OpportunityId ).get( lineItem.Product2.Purchased_Asset_Record_Type__c );
            if ( matchedAsset != null ) {
                pp.Asset__c = matchedAsset.Id;
            }
        }
        this.purchasedProductsToInsert.add( pp );
    }

    private void collectProductsToUpdate( OpportunityLineItem lineItem ) {
        if ( ( lineItem != null )
            && ( lineItem.Product2Id != null )
            && ( this.existingProducts != null )
            && !this.existingProducts.isEmpty()
            )
        {
            Id lineItemAccId = null;
            if ( lineItem.Opportunity != null ){
                lineItemAccId = lineItem.Opportunity.AccountId;
            }
            for ( Purchased_Product__c product : this.existingProducts ) {
                Id productAccId = getAccountIdFromProduct( product );
                this.updateProduct(
                    product ,
                    lineItem ,
                    productAccId ,
                    lineItemAccId
                );
            }
        }
    }

    private void updateProduct(
        Purchased_Product__c product ,
        OpportunityLineItem lineItem ,
        Id productAccId ,
        Id lineItemAccId
        )
    {
        if ( ( product != null )
            && ( product.Product__c != null )
            && ( lineItem != null )
            && ( product.Product__c == lineItem.Product2Id )
            && ( productAccId != null )
            && ( lineItemAccId != null )
            && ( productAccId == lineItemAccId )
            )
        {
            if ( product.Purchase_Status__c == 'Canceled' ) {
                product.Purchase_Status__c = 'Purchased';
            }
            SBQQ__QuoteLine__c ql = lineItem.SBQQ__QuoteLine__r;
            if ( ( ql != null )
                && String.isNotBlank( ql.NSP_ActionType__c )
                )
            {
                product.Total_Price__c = lineItem.UnitPrice;
            }
            this.updateOppProduct( product , lineItem );
            if ( ( this.itemToListPriceMap != null )
                && this.itemToListPriceMap.containsKey( lineItem.Id )
                )
            {
                product.Component_Price__c = this.itemToListPriceMap.get( lineItem.Id );
            }
            if ( !this.purchasedProductsToUpdate.containsKey( product.Name ) ) {
                this.purchasedProductsToUpdate.put( product.Name , product );
            }
        }
    }

    private void updateOppProduct( Purchased_Product__c product , OpportunityLineItem lineItem ) {
        if ( ( product != null ) && ( lineItem != null ) ) {
            if ( ( lineItem.Opportunity != null )
                && ( lineItem.Opportunity.Type == 'New Product' )
                )
            {
                product.Original_Opportunity_Product__c = lineItem.Id;
            } else {
                product.Opportunity_Product__c = lineItem.Id;
            }
        }
    }

    private Id getAccountIdFromProduct( Purchased_Product__c product ) {
        Id productAccId = null;
        if ( product != null ) {
            if ( ( product.Opportunity_Product__r != null )
                && ( product.Opportunity_Product__r.Opportunity != null )
                )
            {
                productAccId = product.Opportunity_Product__r.Opportunity.AccountId;
            } else if ( ( product.Original_Opportunity_Product__r != null )
                && ( product.Original_Opportunity_Product__r.Opportunity != null )
                )
            {
                productAccId = product.Original_Opportunity_Product__r.Opportunity.AccountId;
            }
        }
        return productAccId;
    }

    private void collectProductsToCancel() {
        if ( ( this.existingProducts != null ) && !this.existingProducts.isEmpty() ) {
            for ( Purchased_Product__c product : this.existingProducts ) {
                if ( product == null ) {
                    continue;
                }
                Id accountId = getAccountIdFromProduct( product );
                if ( this.isCancelable( product , accountId ) ) {
                    product.Purchase_Status__c = 'Canceled';
                    if ( !this.purchasedProductsToUpdate.containsKey( product.Name ) ) {
                        this.purchasedProductsToUpdate.put( product.Name , product );
                    }
                }
            }
        }
    }

    private Boolean isCancelable( Purchased_Product__c product , Id accountId ) {
        Boolean result = false;
        Boolean preconditionsMet = (
            ( product != null )
            && ( accountId != null )
            && ( product.Product__c != null )
            && ( this.accToProductsMap != null )
            && this.accToProductsMap.containsKey( accountId )
            && ( this.accToProductsMap.get( accountId ) != null )
        );
        if ( preconditionsMet ) {
            List<Id> productIdsForAccount = this.accToProductsMap.get( accountId );
            Boolean notAlreadyPresent = !productIdsForAccount.contains( product.Product__c );
            if ( notAlreadyPresent ) {
                result = true;
            }
        }
        return result;
    }

    private void insertPurchasedProducts() {
        if ( ( this.purchasedProductsToInsert != null ) && !this.purchasedProductsToInsert.isEmpty() ) {
            List<Database.SaveResult> results = Database.insert( this.purchasedProductsToInsert , false );
            NSP_ErrorLogHandler.logResults(
                PurchasedProductsCreateBatch.class.getName() ,
                'insertPurchasedProducts:insert' ,
                results
            );
        }
    }

    private void updatePurchasedProducts() {
        if ( ( this.purchasedProductsToUpdate != null ) && !this.purchasedProductsToUpdate.isEmpty() ) {
            List<Database.SaveResult> updateResults = Database.update( this.purchasedProductsToUpdate.values() , false );
            NSP_ErrorLogHandler.logResults(
                PurchasedProductsCreateBatch.class.getName() ,
                'updatePurchasedProducts:update' ,
                updateResults
            );
        }
    }

    private void getListPricesForOpportunityLineItems() {
        List<NSP_Pricing_Table__c> pricingRecords = this.queryPricingByProducts();
        if ( ( pricingRecords != null ) && !pricingRecords.isEmpty() ) {
            for ( NSP_Pricing_Table__c pricing : pricingRecords ) {
                if ( ( pricing.NSP_Product__c == null )
                    || ( pricing.NSP_Upper_Bound__c == null )
                    || ( pricing.NSP_Lower_Bound__c == null )
                    )
                {
                    continue;
                }
                this.updateItemToListPriceMap( pricing );
            }
        }
    }

    private void updateItemToListPriceMap( NSP_Pricing_Table__c pricing ) {
        if ( ( this.oppLineItems != null ) && !this.oppLineItems.isEmpty() ) {
            for ( OpportunityLineItem li : this.oppLineItems ) {
                SBQQ__QuoteLine__c ql = li.SBQQ__QuoteLine__r;
                if ( ql == null ) {
                    continue;
                }
                SBQQ__Quote__c quote = ql.SBQQ__Quote__r;
                if ( quote == null || ql.NSP_Quoted_Quantity__c == null ) {
                    continue;
                }
                if ( this.isValidPricingMatch( pricing , ql , quote , li ) ) {
                    this.itemToListPriceMap.put( li.Id , pricing.NSP_List_Price__c );
                }
            }
        }
    }

    private Boolean isValidPricingMatch( NSP_Pricing_Table__c pricing , SBQQ__QuoteLine__c ql , SBQQ__Quote__c quote , OpportunityLineItem li ) {
        return (
            ( pricing.NSP_Product__c == li.Product2Id )
            && ( ql.NSP_Quoted_Quantity__c <= pricing.NSP_Upper_Bound__c )
            && ( ql.NSP_Quoted_Quantity__c >= pricing.NSP_Lower_Bound__c )
            && ( pricing.Seasonal_Pricing__c == quote.Seasonal_Pricing__c )
            && ( pricing.NSP_Pricing_Model__c == quote.NSP_Pricing_Model__c )
        );
    }

    private List<NSP_Pricing_Table__c> queryPricingByProducts() {
        List<NSP_Pricing_Table__c> pricingRecords = new List<NSP_Pricing_Table__c>();
        Set<Id> productIds = new Set<Id>();
        if ( ( this.oppLineItems != null ) && !this.oppLineItems.isEmpty() ) {
            for ( OpportunityLineItem li : this.oppLineItems ) {
                if ( ( li != null ) && ( li.Product2Id != null ) ) {
                    productIds.add( li.Product2Id );
                }
            }
        }
        if ( !productIds.isEmpty() ) {
            pricingRecords = [
                SELECT
                    Id ,
                    NSP_Product__c ,
                    NSP_Lower_Bound__c ,
                    NSP_Upper_Bound__c ,
                    NSP_List_Price__c ,
                    Seasonal_Pricing__c ,
                    NSP_Pricing_Model__c
                FROM NSP_Pricing_Table__c
                WHERE (
                    ( NSP_Product__c IN :productIds )
                    AND ( IsPricingActive__c = true )
                )
            ];
        }
        return pricingRecords;
    }

    private void createOppToAssetMap() {
        List<Opportunity> opps = this.fetchOpportunities();
        Map<Id,Map<String,Asset>> oppToAssets = new Map<Id,Map<String,Asset>>();
        Set<Id> accountIds = new Set<Id>();
        for ( Opportunity opp : opps ) {
            oppToAssets.put( opp.Id , new Map<String,Asset>() );
            if ( opp.AccountId != null ) {
                accountIds.add( opp.AccountId );
            }
        }
        List<Asset> activeAssets = this.fetchActiveAssets( accountIds );
        Map<Id,Map<String,Asset>> acctToAssetType = this.buildAccountToTypeAssetMap( activeAssets );
        for ( Opportunity opp : opps ) {
            if ( opp.AccountId == null ) {
                continue;
            }
            Map<String,Asset> typeMap = acctToAssetType.get( opp.AccountId );
            if ( ( typeMap != null ) && !typeMap.isEmpty() ) {
                oppToAssets.get( opp.Id ).putAll( typeMap );
            }
        }
        this.oppToAssetMap = oppToAssets;
    }

    private List<Opportunity> fetchOpportunities() {
        List<Opportunity> records = new List<Opportunity>();
        if ( ( this.scopeIds != null ) && !this.scopeIds.isEmpty() ) {
            records = [
                SELECT Id , AccountId
                FROM Opportunity
                WHERE ( Id IN :this.scopeIds )
            ];
        }
        return records;
    }

    private List<Asset> fetchActiveAssets( Set<Id> accountIds ) {
        List<Asset> activeAssets = new List<Asset>();
        if ( !accountIds.isEmpty() ) {
            activeAssets = [
                SELECT
                    Id ,
                    AccountId ,
                    RecordTypeId ,
                    RecordType.DeveloperName
                FROM Asset
                WHERE (
                    ( AccountId IN :accountIds )
                    AND ( Status IN ( 'Active' , 'Onboarding' ) )
                    AND ( RecordType.DeveloperName != 'Hardware_Asset' )
                )
                ORDER BY CreatedDate ASC
            ];
        }
        return activeAssets;
    }

    private Map<Id,Map<String,Asset>> buildAccountToTypeAssetMap( List<Asset> activeAssets ) {
        Map<Id,Map<String,Asset>> acctToAssetType = new Map<Id,Map<String, Asset>>();
        for ( Asset a : activeAssets ) {
            if ( ( a.AccountId == null ) || ( a.RecordType == null ) ) {
                continue;
            }
            Map<String,Asset> typeMap = acctToAssetType.get( a.AccountId );
            if ( typeMap == null ) {
                typeMap = new Map<String,Asset>();
                acctToAssetType.put( a.AccountId , typeMap );
            }
            if ( !typeMap.containsKey( a.RecordType.DeveloperName ) ) {
                typeMap.put( a.RecordType.DeveloperName , a );
            }
        }
        return acctToAssetType;
    }

    private static PurchasedProductBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = PurchasedProductBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Integer purchasedProductBatchSize {
        private get {
            if ( purchasedProductBatchSize == null ) {
                Integer local = 200;
                if ( ( PurchasedProductsCreateBatch.settings != null )
                    && ( PurchasedProductsCreateBatch.settings.BatchSize__c != null )
                    )
                {
                    local = PurchasedProductsCreateBatch.settings.BatchSize__c.intValue();
                }
                // batch size must be greater than zero...
                if ( local < 1 ) {
                    local = 1;
                }
                // batch size must be less than or equal to 2000...
                if ( local > 2000 ) {
                    local = 2000;
                }
                purchasedProductBatchSize = local;
            }
            return purchasedProductBatchSize;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( PurchasedProductsCreateBatch.settings != null ) {
                    local = PurchasedProductsCreateBatch.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

}
//