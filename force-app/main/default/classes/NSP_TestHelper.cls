/**
* @description  :   Class created for creating test records  .
* @date 06/09/2022
* Author : Tejas Patkar
* Name : NSP_TestHelper
*/
@isTest
public class NSP_TestHelper {
    static final string STRING_OTHER = 'Other';
    public class TestHelperException extends Exception {
    }
    
    /***********************************************************************************************
    * Variables
    * ********************************************************************************************/
    public static final String DEFAULT_COMPANY_NAME = 'ABCTest Co';
    public static final String DEFAULT_TEST_EMAIL = 'shree.raksha.ms@xyz.com';
    public static final String DEFAULT_CONTACT_FIRST_NAME = 'John';
    public static final String DEFAULT_CONTACT_LAST_NAME = 'Doe';
    public static final String DEFAULT_CONTACT_NAME = DEFAULT_CONTACT_FIRST_NAME + ' ' + DEFAULT_CONTACT_LAST_NAME;
    public static final String DEFAULT_ADDRESS_STREET = '123 Market Street';
    public static final String DEFAULT_ADDRESS_CITY = 'San Francisco';
    public static final String DEFAULT_ADDRESS_STATECODE = 'CA';
    public static final String DEFAULT_ADDRESS_STATENAME = 'California';
    public static final String DEFAULT_ADDRESS_POSTALCODE = '94103';
    public static final String DEFAULT_ADDRESS_COUNTRY_NAME = 'United States';
    public static final String DEFAULT_ADDRESS_COUNTRY_CODE = 'US';
    public static final String DEFAULT_CURRENCY_CODE = 'USD';
    public static final String DEFAULT_LOCALE = 'en_US';
    public static final String DEFAULT_USERNAME = 'insperity@nsp.com.invalid.testqa';
    public static final String DEFAULT_USER_F_NAME = 'Insperity';
    public static final String DEFAULT_USER_L_NAME = 'Salesforce';
    public static final String DEFAULT_USER_EMAIL = 'insperity@insperity.com';
    public static final String DEFAULT_USER_PROFILE = 'System Administrator';

    /***********************************************************************************************
    * MethodName: createAccount
    * Description : Creating account record
    * Params: Boolean insertRecord
    * ********************************************************************************************/
  public static Account createAccount(Boolean insertRecord) {
    Account acct = new Account(
        Name = DEFAULT_COMPANY_NAME,
        Website = 'http://foo.bar.com'
    );

    if (insertRecord) {
        insert acct;
    }

    return acct;
}   

    /***********************************************************************************************
    * MethodName: createContact
    * Description : Creating Contact record
    * Params: Boolean insertRecord
    * ********************************************************************************************/
public static Contact createContact(Boolean insertRecord) {
    return createContact(null, insertRecord);
}
    /***********************************************************************************************
    * MethodName: createContact
    * Description : Creating Contact record with related account
    * Params: Id accountId, Boolean insertRecord
    * ********************************************************************************************/
public static Contact createContact(Id accountId, Boolean insertRecord) {
    Contact con = new Contact(
        Firstname = DEFAULT_CONTACT_FIRST_NAME,
        Lastname = DEFAULT_CONTACT_LAST_NAME,
        Email = DEFAULT_TEST_EMAIL,
        NSP_Work_email__c = 'test@test.com',
        MailingCity = DEFAULT_ADDRESS_CITY,
        MailingState = DEFAULT_ADDRESS_STATENAME,
        MailingPostalCode = DEFAULT_ADDRESS_POSTALCODE,
        AccountId = accountId
    );

    if (insertRecord) {
        insert con;
    }

    return con;
}
    /***********************************************************************************************
    * MethodName: createOpenOpportunity
    * Description : Creating Opportunity record with related account
    * Params: Id accountId,String type, Boolean insertRecord
    * ********************************************************************************************/
public static Opportunity createOpenOpportunity(
        Id accountId,
        String type,
        Boolean insertRecord
    ) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today().addDays(10),
            StageName = 'Prospecting',
            Type = type,
            AccountId = accountId,
            CurrencyIsoCode = DEFAULT_CURRENCY_CODE
        );

        if (insertRecord) {
            insert opp;
        }

        return opp;
    }
    /***********************************************************************************************
    * MethodName: createOpportunity Credit
    * Description : Creating Opportunity Credit record with related Opportunity
    * Params: Id opportunityId,String type, Boolean insertRecord
    * ********************************************************************************************/
public static NSP_Employee_Split__c createOpportunityCredit(
    Id opportunityId,
    String type,
    Boolean insertRecord
) {
    NSP_Employee_Split__c oppcredit = new NSP_Employee_Split__c(
        NSP_Opportunity__c =opportunityId,
        NSP_Enrollment_Fee__c = 10,
        NSP_Number_of_Employees__c = 20,
        NSP_Percent_Split__c = 10,
        CurrencyIsoCode = DEFAULT_CURRENCY_CODE
    );

    if (insertRecord) {
        insert oppcredit;
    }

    return oppcredit;
}
    /***********************************************************************************************
    * MethodName: createProduct
    * Description : Creating product record
    * Params: String productName, Boolean insertRecord
    * ********************************************************************************************/
     public static Product2 createProduct(String productName, Boolean insertRecord) {
      

        Product2 product = new Product2(
            Name = productName
        );

        if (insertRecord) {
            insert product;
        }

        return product;
    }

     /***********************************************************************************************
    * MethodName: createPriceBookEntry
    * Description : Creating pricebookEntry record
    * Params: Id productId, Decimal unitPrice, Boolean insertRecord
    * ********************************************************************************************/
     public static PriceBookEntry createPriceBookEntry(Id productId, Decimal unitPrice, Boolean insertRecord) {
        PriceBookEntry priceBookEntry = new PriceBookEntry(
            CurrencyIsoCode = DEFAULT_CURRENCY_CODE,
            Product2Id = productId,
            PriceBook2Id = getStandardPriceBook2().Id,
            UseStandardPrice = false,
            UnitPrice = unitPrice,
            IsActive = true
        );

        if (insertRecord) {
            insert priceBookEntry;
        }

        return priceBookEntry;
    }
     /***********************************************************************************************
    * MethodName: createCustomPriceBookEntry
    * Description : Creating pricebookEntry record
    * Params: Id productId, Decimal unitPrice, Id pbId, Boolean insertRecord
    * ********************************************************************************************/
     public static PriceBookEntry createCustomPriceBookEntry(Id productId, Decimal unitPrice, Id pbId, Boolean insertRecord) {
        PriceBookEntry priceBookEntry = new PriceBookEntry(
            CurrencyIsoCode = DEFAULT_CURRENCY_CODE,
            Product2Id = productId,
            PriceBook2Id = pbId,
            UseStandardPrice = false,
            UnitPrice = unitPrice,
            IsActive = true
        );

        if (insertRecord) {
            insert priceBookEntry;
        }

        return priceBookEntry;
    }
    
     /***********************************************************************************************
    * MethodName: getStandardPriceBook2
    * Description : Calling Standard PriceBook
    * ********************************************************************************************/
    public static Pricebook2 getStandardPriceBook2() {
        Pricebook2 standardPricebook2 = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        //update standardPricebook2;

        return standardPricebook2;
    }
    
     /***********************************************************************************************
    * MethodName: createPriceBook2
    * Description : Creating pricebook Record
    * Params: String pbname
    * ********************************************************************************************/
    public static Pricebook2 createPriceBook2(String pbname) {
        Pricebook2 customPricebook2 = new Pricebook2(Name=pbname, IsActive = true);

        return customPricebook2;
    }

     /***********************************************************************************************
    * MethodName: createCPQQuote
    * Description : Creating Quote record for CPQ
    * Params: Id accId, Id oppId, Boolean insertRecord
    * ********************************************************************************************/
    public static SBQQ__Quote__c createCPQQuote(Id accId, Id oppId, Boolean insertRecord) {
        //Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = accId,
            SBQQ__Opportunity2__c = oppId,
            SBQQ__Type__c = 'Quote',
            SBQQ__StartDate__c = System.today(),
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__PaymentTerms__c = 'Net 30',
            SBQQ__BillingFrequency__c = 'Monthly',
            SBQQ__PricebookId__c = getStandardPriceBook2().Id
         );
        if (insertRecord) {
            insert quote;
        }
        return quote;
    }

        /***********************************************************************************************
    * MethodName: createCPQQuotelinesSeperateProject
    * Description : Creating QuoteLine record for CPQ
    * Params: SBQQ__Quote__c quoteRec,List<Product2> productList,List<PricebookEntry> priceBook,Boolean insertRecord
    * ********************************************************************************************/
    public static List<SBQQ__Quoteline__c> createCPQQuotelinesSeperateProject(
        SBQQ__Quote__c quoteRec,
        List<Product2> productList,
        List<PricebookEntry> priceBook,
        Boolean insertRecord
    ) {
        List<SBQQ__Quoteline__c> quotelineList = new List<SBQQ__Quoteline__c>();
        for (integer count = 0; count < productList.size(); count++) {
            //Quote Line
            SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
            quoteLine.SBQQ__Quote__c = quoteRec.Id;
            quoteLine.SBQQ__Product__c = productList[count].Id;
            quoteLine.SBQQ__Quantity__c = 1;
            quoteLine.SBQQ__Number__c = 1;
            quoteLine.Separate_Project__c = true;
            quoteLine.SBQQ__DefaultSubscriptionTerm__c = 12;
            quoteLine.SBQQ__PricebookEntryId__c = priceBook[count].Id;
            quoteLine.SBQQ__NetPrice__c = 10;
            quoteLine.SBQQ__Quantity__c = 1;
            quotelineList.add(quoteline);
        }
        if (insertRecord) {
            insert quotelineList;
        }

        return quotelineList;
    }

    /***********************************************************************************************
    * MethodName: createCPQQuotelines
    * Description : Creating QuoteLine record for CPQ
    * Params: SBQQ__Quote__c quoteRec,List<Product2> productList,List<PricebookEntry> priceBook,Boolean insertRecord
    * ********************************************************************************************/
    public static List<SBQQ__Quoteline__c> createCPQQuotelines(
        SBQQ__Quote__c quoteRec,
        List<Product2> productList,
        List<PricebookEntry> priceBook,
        Boolean insertRecord
    ) {
        List<SBQQ__Quoteline__c> quotelineList = new List<SBQQ__Quoteline__c>();
        for (integer count = 0; count < productList.size(); count++) {
            //Quote Line
            SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
            quoteLine.SBQQ__Quote__c = quoteRec.Id;
            quoteLine.SBQQ__Product__c = productList[count].Id;
            quoteLine.SBQQ__Quantity__c = 1;
            quoteLine.SBQQ__Number__c = 1;
            quoteLine.SBQQ__DefaultSubscriptionTerm__c = 12;
            quoteLine.SBQQ__PricebookEntryId__c = priceBook[count].Id;
            quoteLine.SBQQ__NetPrice__c = 10;
            quoteLine.SBQQ__Quantity__c = 1;
            quotelineList.add(quoteline);
        }
        if (insertRecord) {
            insert quotelineList;
        }

        return quotelineList;
    }
    
   
    /***********************************************************************************************
    * MethodName: createConsumptionSchedule
    * Description : Creating CPQ Consumption schedule
    * Params: String name
    * ********************************************************************************************/
    public static ConsumptionSchedule createConsumptionSchedule(String name){
        return new ConsumptionSchedule(
                            Name = name,
                            RatingMethod = 'Tier',
                            Type = 'Range',
                            SBQQ__Category__c = 'Rates',
                            BillingTerm = 1,
                            BillingTermUnit = 'Month',
                            IsActive = false);
    }
    
    /**Method to Create consumption Rate for a Consumption schedule
    @param ConsumptionSchedule object
    */
    public static ConsumptionRate createConsumptionRate(ConsumptionSchedule cs){
        return new ConsumptionRate(
                                ProcessingOrder = 1,
                                LowerBound = 0,
                                UpperBound = 9999,
                                Price = 1,
                                PricingMethod = 'FlatFee',
                                ConsumptionScheduleId = cs.id
                                );
    }
    
    /**Method to link product to Consumption schedule
    @param Product Id,ConsumptionSchedule Id
    */
    public static ProductConsumptionSchedule linkProductToCs(String productIdstr, String csId){
        return new ProductConsumptionSchedule(
        ProductId = productIdstr,
        ConsumptionScheduleId = csId
        );
    }
      /***********************************************************************************************
    * MethodName: createCustomAddress
    * Description : Creating NSP_Address__c record
    * ********************************************************************************************/
    public static NSP_Address__c createCustomAddress(){
        NSP_Address__c addressRecord = new NSP_Address__c();
        addressRecord.Name = 'Test Temporary Address';
        addressRecord.NSP_Source__c = 'AIMS';
        addressRecord.NSP_Address_Type__c = 'Bill To';
        addressRecord.NSP_Country__c = 'United States';
        addressRecord.NSP_State__c = 'Florida';
        addressRecord.NSP_Street__c = 'street Florida';
        addressRecord.NSP_Street_Address_2__c = 'street Florida';
        addressRecord.NSP_City__c = 'City Florida';
        addressRecord.NSP_Postal_Code__c = '12345';
        addressRecord.NSP_Active__c = true;
        
        return addressRecord;
    }
    /***********************************************************************************************
    * MethodName: createUser
    * Description : Creating user record
    * Params: boolean insertUser
    * ********************************************************************************************/
    public static User createUser(boolean insertUser){
        Profile systemAdminProfile = [SELECT Id FROM Profile WHERE Name= :DEFAULT_USER_PROFILE]; 
        
        User user = new User();
        user.FirstName = DEFAULT_USER_F_NAME;
        user.LastName = DEFAULT_USER_L_NAME;
        user.Email = DEFAULT_USER_EMAIL;
        user.Username = DEFAULT_USERNAME;
        user.ProfileId = systemAdminProfile.Id;
        user.Alias='alias';
        user.LocaleSidKey='en_US';
        user.TimeZoneSidKey='America/Los_Angeles';
        user.LanguageLocaleKey='en_US';
        user.EmailEncodingKey='UTF-8';
        
        if(insertUser){
            insert user;
        }
        
        return user;        
    }
    /***********************************************************************************************
    * MethodName: createOTMRecord
    * Description : Creating OpportunityTeamMember record
    * Params: Id opportunityId, Id userId, String otmRole, String opportunityAccess, boolean insertOTM
    * ********************************************************************************************/
    public static OpportunityTeamMember createOTMRecord(Id opportunityId, Id userId, String otmRole, String opportunityAccess, boolean insertOTM){
        OpportunityTeamMember otmRecord = new OpportunityTeamMember();
        otmRecord.OpportunityId = opportunityId;
        otmRecord.UserId =  userId;
        otmRecord.OpportunityAccessLevel=opportunityAccess;
        otmRecord.TeamMemberRole=otmRole;
        
        if(insertOTM){            
            insert otmRecord;
        }
        
        return otmRecord;
    }
    
    /***********************************************************************************************
    * MethodName: createLeadRecord
    * Description : Creating Lead record
    * Params: boolean insertLead
    * ********************************************************************************************/   
    public static Lead createLeadRecord(boolean insertLead){
        Lead leadRecord = new Lead();
        //leadRecord.Name='Test Lead 123';
        leadRecord.Company=DEFAULT_COMPANY_NAME;
        leadRecord.NumberOfEmployees=120;
        leadRecord.Email=DEFAULT_USER_EMAIL;
        leadRecord.FirstName=DEFAULT_USER_F_NAME;
        leadRecord.LastName=DEFAULT_USER_L_NAME;
        leadRecord.Phone = '56789098';
        
        if(insertLead){
            insert leadRecord;
        }
        return leadRecord;
    }
    /***********************************************************************************************
    * MethodName: accountContactTest
    * Description : Creating account and contact record
    * ********************************************************************************************/
    @isTest
    public static void accountContactTest(){
        Account acc= createAccount(true);
        Contact con= createContact(acc.Id, true);
        System.assertEquals(con.AccountId, acc.Id);
    }
                /***********************************************************************************************
    * MethodName: createBillingRule
    * Description : Creating Billing Rule
    * ********************************************************************************************/
    public static blng__BillingRule__c createBillingRule(){
        blng__BillingRule__c bRule= new blng__BillingRule__c();
        bRule.Name='Test Billing Rule';
        bRule.blng__Active__c=true;
        bRule.blng__GenerateInvoices__c='No';
        bRule.blng__InitialBillingTrigger__c='Order Product Activation Date';
        insert bRule;
        return bRule;
    }
    public static blng__RevenueRecognitionRule__c createRevrecRule(String revmodel){
        blng__RevenueRecognitionRule__c rRule= new blng__RevenueRecognitionRule__c();
        rRule.Name='Test RevRec Rule '+revmodel;
        rRule.blng__Active__c=true;
        rRule.blng__CreateRevenueSchedule__c='Yes';
        rRule.NSP_Rev_Rec_Model__c=revmodel;
        insert rRule;
        return rRule;
    }
    public static blng__TaxRule__c createRevTaxRule(){
        blng__TaxRule__c tRule= new blng__TaxRule__c();
        tRule.Name='Test Tax Rule';
        tRule.blng__Active__c=true;
        tRule.blng__TaxableYesNo__c='No';
        insert tRule;
        return tRule;
    }
        public static blng__UsageSummary__c createUsageSummary(list<OrderItem> orderItemList,Account objaccount){
        blng__UsageSummary__c uSummary= new blng__UsageSummary__c();
        uSummary.blng__OrderProduct__c=orderItemList[0].Id;
        uSummary.blng__Account__c=objaccount.Id;
        uSummary.blng__Status__c='Queued For Invoice';
        uSummary.blng__Subtotal__c=500;
        uSummary.blng__SummaryStartDate__c=system.today();
        uSummary.blng__SummaryEndDate__c=system.today()+30;
        uSummary.NSP_Billed_Free__c=TRUE;
        insert uSummary;
        return uSummary;
    }

    public static void switchOffTriggers () {
   
         NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true; 
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
      

    }
    public static blng__RevenueDistributionMethod__c createRevenueDistribution(String name){
        blng__RevenueDistributionMethod__c dist=new blng__RevenueDistributionMethod__c();
        dist.Name=name;
        dist.blng__Active__c=true;
        dist.blng__MonthlyRecognitionProration__c='Number of Days';
        dist.blng__DistributionMethod__c='Full Recognition';
        dist.blng__FullRecognitionDate__c=STRING_OTHER;
        dist.blng__RevenueTransactionCreationProcess__c='Automatic';
        dist.blng__Type__c=STRING_OTHER;
        insert dist;
        return dist;
    }
    public static blng__GLRule__c createGLRule(){
        blng__GLRule__c glrule= new blng__GLRule__c();
        glrule.Name='Test GL rule';
        glrule.blng__Active__c=true;
        insert glrule;
        return glrule;
    }
    public static blng__FinanceBook__c createFinBook(){
        blng__FinanceBook__c finbook=new blng__FinanceBook__c();
        finbook.blng__Active__c=true;
        finbook.blng__FinancePeriodDuration__c='Monthly';
        finbook.blng__PeriodType__c='Revenue';
        finbook.Name='Test FinBook';
        insert finbook;
        return finbook;
    }
    public static blng__RevenueRecognitionTreatment__c createRevRecTreatment(){
        blng__RevenueRecognitionTreatment__c treatment= new blng__RevenueRecognitionTreatment__c();
        treatment.blng__Active__c=true;
        treatment.Name='Test Treatment';
        treatment.blng__ProcessingOrder__c=1;
        treatment.blng__Type__c='Percentage';
        treatment.blng__RevenueFinanceBook__c=NSP_TestHelper.createFinBook()?.Id;
        treatment.blng__RevenueGLRule__c=NSP_TestHelper.createGLRule()?.Id;
        treatment.blng__Percentage__c=100;
        treatment.blng__RevenueScheduleCreationAction__c=STRING_OTHER;
        treatment.blng__RevenueScheduleAmount__c=STRING_OTHER;
        return treatment;
    }
    public static Product2 createBillingProduct(String prodName,blng__RevenueRecognitionRule__c rRule,blng__TaxRule__c tRule,blng__BillingRule__c bRule,String freq){
        Product2 objproduct = NSP_TestHelper.createProduct(prodName,false);
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = freq;
        objproduct.NSP_IsScholarshipPrice_Applicable__c ='YES';
        objproduct.blng__BillingRule__c=bRule.Id;
        objproduct.blng__RevenueRecognitionRule__c=rRule.Id;
        objproduct.blng__TaxRule__c=tRule.Id;
        insert objproduct;
        return objproduct;
    }
    public static Product2 createSeparateBillingProduct(String prodName,blng__RevenueRecognitionRule__c rRule,blng__TaxRule__c tRule,blng__BillingRule__c bRule,String freq){
        Product2 objproduct = NSP_TestHelper.createProduct(prodName,false);
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = freq;
        objproduct.Separate_Project__c = true;
        objproduct.NSP_IsScholarshipPrice_Applicable__c ='YES';
        objproduct.blng__BillingRule__c=bRule.Id;
        objproduct.blng__RevenueRecognitionRule__c=rRule.Id;
        objproduct.blng__TaxRule__c=tRule.Id;
        insert objproduct;
        return objproduct;
    }
                /***********************************************************************************************
    * MethodName: createOItemConsumptionSchdeule
    * Description : Creating order item consumption schdule
    * ********************************************************************************************/
    public static SBQQ__OrderItemConsumptionSchedule__c createOItemConsumptionSchdeule(list<OrderItem> orderItemList,ConsumptionSchedule cs){
        SBQQ__OrderItemConsumptionSchedule__c ocsh= new SBQQ__OrderItemConsumptionSchedule__c();
        ocsh.Name='IWX Consumption schedule';
        ocsh.SBQQ__BillingTerm__c=1;
        ocsh.SBQQ__BillingTermUnit__c='Month';
        ocsh.SBQQ__Category__c='Rates';
        ocsh.SBQQ__OrderItem__c=orderItemList[0].Id;
        ocsh.SBQQ__Type__c='Ranger';
        ocsh.SBQQ__ConsumptionSchedule__c=cs.Id;
        ocsh.SBQQ__RatingMethod__c='Tier';
        insert ocsh;
        return ocsh;
    }
            /***********************************************************************************************
    * MethodName: createOtemConsumptionRate
    * Description : Creating order item consumption rates
    * ********************************************************************************************/
    public static SBQQ__OrderItemConsumptionRate__c createOtemConsumptionRate(SBQQ__OrderItemConsumptionSchedule__c ocsh){
        SBQQ__OrderItemConsumptionRate__c ocshrate= new SBQQ__OrderItemConsumptionRate__c();
        ocshrate.SBQQ__LowerBound__c=1;
        ocshrate.SBQQ__UpperBound__c=9999;
        ocshrate.SBQQ__ProcessingOrder__c=1;
        ocshrate.SBQQ__PricingMethod__c='FlatFee';
        ocshrate.SBQQ__Price__c=10;
        ocshrate.SBQQ__OrderItemConsumptionSchedule__c=ocsh.id;
        insert ocshrate;
        return ocshrate;
    }
        /***********************************************************************************************
    * MethodName: createUsages
    * Description : Creating billing ugsae reocord
    * ********************************************************************************************/
    public static blng__Usage__c createUsages(blng__UsageSummary__c usummary,list<OrderItem> orderItemList){
        blng__Usage__c usage= new blng__Usage__c();
        usage.NSP_Combined_partner_usage__c=20;
       // usage.blng__MatchingId__c=usummary.blng__MatchingId__c;
        usage.blng__MatchingId__c='usummary.blng__MatchingId__c';
        usage.blng__StartDateTime__c=orderItemList[0].ServiceDate+1;
        usage.blng__EndDateTime__c=orderItemList[0].ServiceDate+15;
        usage.blng__OrderProduct__c=orderItemList[0].Id;
        usage.blng__Quantity__c=20;
        usage.blng__UsageSummary__c=usummary.Id;
        insert usage;
        return usage;
    }
}