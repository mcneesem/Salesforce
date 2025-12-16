@isTest
private class NSP_ContractRenewal_Batch_Test {

    @testSetup
    private static void setupTestData() {
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;

        // NSP_TestHelper th = new NSP_TestHelper();
        Account acc1 = NSP_TestHelper.createAccount(true);
        NSP_TestHelper.createContact(acc1.id, true);
        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id,'New Product',true);
        Product2 product1 = NSP_TestHelper.createProduct('Test Product',true);
        PriceBookEntry pe1 = NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
        SBQQ__Quote__c quote1 = NSP_TestHelper.createCPQQuote(acc1.Id,opp1.Id,true);
        NSP_TestHelper.createCPQQuotelines(quote1,new List<Product2>{product1},new List<PriceBookEntry> {pe1}, true);
        opp1.NSP_PrimaryProduct__c = 'Performance Management';
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        update opp1;
        //Creating Contract
        Contract ct = new Contract();
        ct.AccountId = acc1.Id;
        ct.SBQQ__Opportunity__c = opp1.Id;
        ct.SBQQ__Quote__c = quote1.Id;
        ct.ContractTerm = 12;
        ct.NSP_Product_Type__c = 'Performance Management';
        Date dt = Date.today()-350;
        ct.StartDate = dt;
        ct.EndDate = dt+365;
        ct.Status = 'Draft';
        ct.NSP_Number_of_Employees__c = 86;
        ct.NSP_PrimaryProduct__c = 'Performance Management';
        insert ct;
        //Activating the contract
        ct.NSP_Product_Type__c = 'Performance Management';
        ct.Status = 'Activated';
        update ct;

    }

    //Test method for contract renewal
    //Executes batch job for NSP_ContractRenewal_Batch
    @isTest
    private static void renewalbatchtest() {

        Test.startTest();
        NSP_ContractRenewal_Batch rcbatch= new NSP_ContractRenewal_Batch();
        Database.executeBatch(rcbatch,1);
        Test.stopTest();

        Contract cont = [SELECT Id, SBQQ__RenewalForecast__c, SBQQ__RenewalQuoted__c,Name from Contract WHERE ContractNumber !=null LIMIT 1];
        System.assertEquals(cont.SBQQ__RenewalQuoted__c,true);

    }

    //Test method for contract renewal
    //Executes batch job for NSP_ContractRenewal_Batch
    @isTest
    private static void renewalbatchtestwithParams() {

        Test.startTest();
        Contract cont = [SELECT Id, SBQQ__RenewalForecast__c, SBQQ__RenewalQuoted__c, ContractTerm,NSP_Product_Type__c,SBQQ__ActiveContract__c, SBQQ__Evergreen__c,EndDate from Contract WHERE ContractNumber !=null LIMIT 1];
        NSP_ContractRenewal_Batch rcbatch= new NSP_ContractRenewal_Batch(cont.Id);
        Database.executeBatch(rcbatch,1);
        Test.stopTest();
        Contract contChk = [SELECT Id, SBQQ__RenewalForecast__c, SBQQ__RenewalQuoted__c,Name from Contract WHERE ContractNumber !=null LIMIT 1];
        System.assertEquals(contChk.SBQQ__RenewalQuoted__c,true);

    }

}
//