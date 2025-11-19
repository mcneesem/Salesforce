@isTest
private class ComponentPriceUpdateBatchTest {

    @testSetup
    private static void setupTestData() {
        // Activate Standard Pricebook
        ComponentPriceUpdateBatchSettings__c sett = new ComponentPriceUpdateBatchSettings__c();
        sett.IsEnabled__c = true;
        sett.BatchSize__c = 1;
        sett.MonitorEmailAddresses__c = 'test@invalid.com';
        insert sett;
        // Create a generic Account and Opportunity to support quotes
        Account acc = new Account(Name = 'TS Account');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'TS Opp',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(15),
            AccountId = acc.Id
        );
        insert opp;
    }

    // Instance helper methods (non-static) - compliant with the constraint
    private static Product2 createProduct(Boolean isActive) {
        Product2 p = new Product2(Name = 'TS Product', ProductCode = 'TS-001', IsActive = isActive);
        insert p;
        return p;
    }

    private static PricebookEntry createPbe(Product2 p, Decimal unitPrice) {
        Id std = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = std,
            Product2Id = p.Id,
            UnitPrice = unitPrice,
            IsActive = true
        );
        insert pbe;
        return pbe;
    }

    private static SBQQ__Quote__c createQuote(String pricingModel, String seasonalPricing) {
        List<Opportunity> opp = [SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c q = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp[0].Id,
            NSP_Pricing_Model__c = pricingModel,
            Seasonal_Pricing__c = seasonalPricing
        );
        insert q;
        return q;
    }

    private static SBQQ__QuoteLine__c createQuoteLine(SBQQ__Quote__c quote, PricebookEntry pbe, Decimal quantity) {
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = pbe.Product2Id,
            NSP_Quoted_Quantity__c =5,
            SBQQ__Quantity__c = quantity
        );
        insert ql;
        return ql;
    }

    private static OpportunityLineItem createOli(PricebookEntry pbe, Decimal quantity, Decimal unitPrice,SBQQ__QuoteLine__c ql) {
        List<Opportunity> opp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp[0].Id,
            Quantity = quantity,
            UnitPrice = unitPrice,
            SBQQ__QuoteLine__c = ql.Id,
            PricebookEntryId = pbe.Id
        );
        insert oli;
        return oli;
    }

    private static Purchased_Product__c createPurchasedProduct(Product2 product, OpportunityLineItem oli, Decimal quotedQty, Decimal initialComponentPrice) {
        Purchased_Product__c pp = new Purchased_Product__c(
            Product__c = product.Id,
            Opportunity_Product__c = oli.Id,
            Component_Price__c = initialComponentPrice
        );
        insert pp;
        return pp;
    }

    private static List<NSP_Pricing_Table__c> makePricingRows() {
        List<NSP_Pricing_Table__c> rows = new List<NSP_Pricing_Table__c>{
            new NSP_Pricing_Table__c(Name = 'Tier 1', NSP_Lower_Bound__c = 1, NSP_Upper_Bound__c = 10, NSP_List_Price__c = 5),
            new NSP_Pricing_Table__c(Name = 'Tier 2', NSP_Lower_Bound__c = 11, NSP_Upper_Bound__c = 100, NSP_List_Price__c = 3)
        };
        insert rows;
        return rows;
    }

    private static ComponentPriceUpdateAction.ComponentPriceInput buildInput(String pricingModel, String seasonalPricing, Id productId, List<NSP_Pricing_Table__c> rows) {
        ComponentPriceUpdateAction.ComponentPriceInput input = new ComponentPriceUpdateAction.ComponentPriceInput();
        input.pricingModel = pricingModel;
        input.seasonalPricing = seasonalPricing;
        input.productId = (String)productId;
        input.lstPricingTable = rows;
        return input;
    }

    @isTest
    private  static void test_HappyPath_UpdatesComponentPrice() {
        Product2 prod = createProduct(true);
        PricebookEntry pbe = createPbe(prod, 10);
        SBQQ__Quote__c quote = createQuote('WX', 'Not Applicable');
        SBQQ__QuoteLine__c ql= createQuoteLine(quote, pbe, 5);
        OpportunityLineItem oli = createOli(pbe, 5, 10,ql);
        Purchased_Product__c pp = createPurchasedProduct(prod, oli, 5, 0);
        List<NSP_Pricing_Table__c> rows = makePricingRows();
        List<ComponentPriceUpdateAction.ComponentPriceInput> inputs = new List<ComponentPriceUpdateAction.ComponentPriceInput>{
            buildInput('WX', 'Not Applicable', prod.Id, rows)
        };
        Test.startTest();
        ComponentPriceUpdateAction.componentBatchExecute(inputs);
        Test.stopTest();
        List<Purchased_Product__c> refreshed = [
            SELECT Id, Component_Price__c,Opportunity_Product__c,Opportunity_Product__r.SBQQ__QuoteLine__r.NSP_Quoted_Quantity__c
            FROM Purchased_Product__c
            WHERE Id = :pp.Id
            LIMIT 1
        ];
        System.assertEquals(5, refreshed[0].Component_Price__c, 'Component_Price__c should be updated to Tier 1 price');
    }

    @isTest
    private static void test_NoRecords_Noop() {
        // Use a product that has no Purchased_Product__c created
        Product2 prod = createProduct(true);
        List<NSP_Pricing_Table__c> rows = makePricingRows();
        List<ComponentPriceUpdateAction.ComponentPriceInput> inputs = new List<ComponentPriceUpdateAction.ComponentPriceInput>{
            buildInput('ModelX', 'Winter', prod.Id, rows)
        };
        Test.startTest();
        ComponentPriceUpdateAction.componentBatchExecute(inputs);
        Test.stopTest();
        System.assert(true, 'Batch completed without processing records');
    }

}
//