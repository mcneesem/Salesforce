/**
Apex Class Name      :  NSP_CorporateEmployeeCheckTest
Version              :  1.0                                                                          
Created Date         :  01/8/2023  
Function             :  Test class for NSP_CorporateEmployeeCheck 
Story                :  STY-03784                                                                  
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
*/
@isTest(SeeAllData=FALSE)
private class NSP_CorporateEmployeeCheckTest {
    private static final String CASEDEFAULTS  = 'NSP_TestDataFactory.CaseDefaults';
    private static final String HIRED =  'HIRED';
    private static final String ACR_DEFAULTS = 'NSP_TestDataFactory.acrDefaults';
    private static final String LAST_NAME = 'LastName';
    private static final String CONTACT = 'Contact';
    private static final String ACCOUNT = 'Account';
    private static final String TEST_CON = 'test con';
    private static final String TEST_ACCOUNT = 'Test Account';
    private static final List<String> CONTACT_FIELDS = new List<String>{
        'Id',
        'Name'};
    private static final List<String> ACR_FIELDS = new List<String>{ 
        'Id',
        'AccountId', 'ContactId', 'NSP_Employee_Status__c'
    };
    private static final List<String> ACCOUNT_FIELDS = new List<String>{
        'Id',
        'Name'
    };
          private static final List<String> CASE_FIELDS = new List<String>{
        'Id',
        'NSP_CorporateEmployeeEE__c', 'AccountId', 'ContactId'
    };
    private static final Id PEO_RECORDTYPE = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.CASE_OBJECT_NAME, NSP_ServiceConstants.PEO);
        /** 
* Test Data for AccountContactRelationHelperTest
* Method Name : testData
*/
    @testsetup 
    static void testData() {      
        //insert account1
        Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc.Name = System.Label.NSP_Insperity_Account;
        acc.AccountNumber = '12345';
        insert acc;
        
        //insert account2
        Account acc1 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc1.Name = TEST_ACCOUNT;
        insert acc1;
        
        //insert contact
        Contact con = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        con.AccountId = acc.Id;
        con.LastName = TEST_CON;
        insert con;
        
        Case newCaseWithCon = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        newCaseWithCon.contactId = con.Id;
        newCaseWithCon.AccountId = acc.Id;
        newCaseWithCon.recordTypeId = PEO_RECORDTYPE;
        newCaseWithCon.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
        
        Test.startTest();
        Database.insert(newCaseWithCon);
    	Test.stopTest();
    }
    
       /**
* @Description: This test method is used to cover oneAcrWithInsperityAccount
* @Created date: 01/08/2022. 
* @return void             
*/  
    @isTest
    private static void oneAcrWithInsperityAccountTest(){
        //query records
        String accQuery = new NSP_QueryBuilder( ACCOUNT, ACCOUNT_FIELDS).addFilter('Name', System.Label.NSP_Insperity_Account).addLimit(1).build();
        Account acc =  Database.query(accQuery);
        
        String conQuery = new NSP_QueryBuilder(CONTACT, CONTACT_FIELDS).addFilter(LAST_NAME,  TEST_CON).addLimit(1).build();
        Contact con =  Database.query(conQuery);
        //insert case
        Case newCaseWithCon = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        newCaseWithCon.contactId = con.Id;
        newCaseWithCon.AccountId = acc.Id;
        newCaseWithCon.recordTypeId = PEO_RECORDTYPE;
        newCaseWithCon.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
        
        Test.startTest();
        Database.insert(newCaseWithCon);
        Test.stopTest();
        
        String assertCaseQuery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, CASE_FIELDS).addFilter('Id', newCaseWithCon.Id).addLimit(1).build();
        Case assertCse =  Database.query(assertCaseQuery);
        
        // Checking if the Contact has only ACR. If the contact is having only one ACR, then NSP_CorporateEmployeeEE__c will be true irrespective of Employee Status
        system.assertEquals(true, assertCse.NSP_CorporateEmployeeEE__c); 
    }
    
    /**
* @Description: This test method is used to cover contactWasclientEmployee
* @Created date: 01/08/2022. 
* @return void             
*/  
    @isTest
    private static void contactWasclientEmployeeTest(){
        //query records
        String conQuery = new NSP_QueryBuilder(CONTACT, CONTACT_FIELDS).addFilter(LAST_NAME,TEST_CON).addLimit(1).build();
        Contact con =  Database.query(conQuery);
        
        String accQuery = new NSP_QueryBuilder(ACCOUNT, ACCOUNT_FIELDS).addFilter('Name', TEST_ACCOUNT).addLimit(1).build();
        Account acc =  Database.query(accQuery);
        
        AccountContactRelation acr = (AccountContactRelation)NSP_TestExtendedDataFactory.createSObject(new AccountContactRelation(), ACR_DEFAULTS, false);
        acr.Accountid = acc.id;
        acr.Contactid = con.id;
        insert acr;
        
        Case newCaseWithCon = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        newCaseWithCon.contactId = con.Id;
        newCaseWithCon.AccountId = acc.Id;
        newCaseWithCon.recordTypeId = PEO_RECORDTYPE;
        newCaseWithCon.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
        
        Test.startTest();
        insert newCaseWithCon;
        Test.stopTest();
        
        String assertCaseQuery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, CASE_FIELDS).addFilter('Id', newCaseWithCon.Id).addLimit(1).build();
        Case assertCse =  Database.query(assertCaseQuery);
        
        // If the contact is having more than one ACR, And Insperity Account status is Not Terminated or other ACRs Emp Status is Blank then 
        // NSP_CorporateEmployeeEE__c will be false
        system.assertNotEquals(true, assertCse.NSP_CorporateEmployeeEE__c);
    }
    /**
* @Description: This test method is used to cover contactWasInsperityEmployee
* @Created date: 01/08/2022. 
* @return void             
*/
    @isTest
    private static void contactWasInsperityEmployeeTest(){
        
        String conQuery = new NSP_QueryBuilder(CONTACT, CONTACT_FIELDS).addFilter(LAST_NAME, TEST_CON).addLimit(1).build();
        Contact con =  Database.query(conQuery);
        
        String accQuery = new NSP_QueryBuilder(ACCOUNT, ACCOUNT_FIELDS).addFilter('Name', TEST_ACCOUNT).addLimit(1).build();
        Account acc =  Database.query(accQuery);
        
        String CaseQuery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, CASE_FIELDS).addFilter('ContactId', con.Id).addLimit(1).build();
        Case cse =  Database.query(CaseQuery);
        //insert acr
        AccountContactRelation acr = (AccountContactRelation)NSP_TestExtendedDataFactory.createSObject(new AccountContactRelation(), ACR_DEFAULTS, false);
        acr.Accountid = acc.id;
        acr.Contactid = con.id;
        insert acr;
        
        String insAaccQuery = new NSP_QueryBuilder(ACCOUNT, ACCOUNT_FIELDS).addFilter('Name', System.Label.NSP_Insperity_Account).addLimit(1).build();
        Account insAacc =  Database.query(insAaccQuery);
        
        String acr1Query = new NSP_QueryBuilder('AccountContactRelation', ACR_FIELDS).addFilter('ContactId', con.Id).addFilter('AccountId', insAacc.Id)
            .addLimit(1).build();
        AccountContactRelation acr1 =  Database.query(acr1Query);
        acr1.NSP_Employee_Status__c = HIRED;
        
        Test.startTest();
        update acr1;
        Test.stopTest();
        
        String assertCaseQuery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, CASE_FIELDS).addFilter('Id', cse.Id).addLimit(1).build();
        Case assertCse =  Database.query(assertCaseQuery);
        
        // If the contact is having more than one ACR, And Insperity Account status is updated Terminated then 
        // NSP_CorporateEmployeeEE__c will be false
        system.assertEquals(true, assertCse.NSP_CorporateEmployeeEE__c);
        
    }
    
    /**
* @Description: This test method is used to cover contactWorksForBothInsperityAndClient
* @Created date: 01/08/2022. 
* @return void             
*/
    @isTest
    private static void contactWorksForBothInsperityAndClientTest(){
        
        String conQuery = new NSP_QueryBuilder(CONTACT, CONTACT_FIELDS).addFilter(LAST_NAME, TEST_CON).addLimit(1).build();
        Contact con =  Database.query(conQuery);
        
        String accQuery = new NSP_QueryBuilder(ACCOUNT, ACCOUNT_FIELDS).addFilter('Name', TEST_ACCOUNT).addLimit(1).build();
        Account acc =  Database.query(accQuery);
        
        String CaseQuery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, CASE_FIELDS).addFilter('ContactId', con.Id).addLimit(1).build();
        Case cse =  Database.query(CaseQuery);
        
        AccountContactRelation acr = (AccountContactRelation)NSP_TestExtendedDataFactory.createSObject(new AccountContactRelation(), ACR_DEFAULTS, false);
        acr.Accountid = acc.id;
        acr.Contactid = con.id;
        acr.NSP_Employee_Status__c = HIRED;
        insert acr;
        
        String insAccQuery = new NSP_QueryBuilder(ACCOUNT, ACCOUNT_FIELDS).addFilter('Name', System.Label.NSP_Insperity_Account).addLimit(1).build();
        Account insAacc =  Database.query(insAccQuery);
        
        String acrQuery = new NSP_QueryBuilder('AccountContactRelation', ACR_FIELDS).addFilter('ContactId', con.Id).addFilter('AccountId', insAacc.Id).
            addLimit(1).build();
        
        AccountContactRelation acr1 =  Database.query(acrQuery);
        acr1.NSP_Employee_Status__c = HIRED;
        
        Test.startTest();
        update acr1;
        Test.stopTest();
        
        String assertCaseQuery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, CASE_FIELDS).addFilter('Id', cse.Id).addLimit(1).build();
        Case assertCse =  Database.query(assertCaseQuery);
        
        // If the contact is having more than one ACR, And other Account status is updated Terminated then 
        // NSP_CorporateEmployeeEE__c will be false
        system.assertNotEquals(false, assertCse.NSP_CorporateEmployeeEE__c);
        
    }
    /**
* @Description: This test method is used to cover negative Test of CorporateEmployeeCheck
* @Created date: 01/08/2022. 
* @return void             
*/
    @isTest
    private static void corporateEmployeeCheckNegativeTest(){
        
        String conQuery = new NSP_QueryBuilder(CONTACT, CONTACT_FIELDS).addFilter(LAST_NAME, TEST_CON).addLimit(1).build();
        Contact con =  Database.query(conQuery);
        
        String accQuery = new NSP_QueryBuilder(ACCOUNT, ACCOUNT_FIELDS).addFilter('Name', TEST_ACCOUNT).addLimit(1).build();
        Account acc =  Database.query(accQuery);
        
        String CaseQuery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, CASE_FIELDS).addFilter('ContactId', con.Id).addLimit(1).build();
        Case cse =  Database.query(CaseQuery);
        
        AccountContactRelation acr = (AccountContactRelation)NSP_TestExtendedDataFactory.createSObject(new AccountContactRelation(), ACR_DEFAULTS, false);
        acr.Accountid = acc.id;
        acr.Contactid = con.id;
        acr.NSP_Employee_Status__c = HIRED;
        insert acr;
        
        String insAccQuery = new NSP_QueryBuilder(ACCOUNT, ACCOUNT_FIELDS).addFilter('Name', System.Label.NSP_Insperity_Account).addLimit(1).build();
        Account insAacc =  Database.query(insAccQuery);
        
        String acrQuery = new NSP_QueryBuilder('AccountContactRelation', ACR_FIELDS).addFilter('ContactId', con.Id).addFilter('AccountId', insAacc.Id).
            addLimit(1).build();
        AccountContactRelation acr1 =  Database.query(acrQuery);
        acr1.NSP_Employee_Status__c = 'TERMINATED';
        
        Test.startTest();
        update acr1;
        Test.stopTest();
        
        String assertCaseQuery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, CASE_FIELDS).addFilter('Id', cse.Id).addLimit(1).build();
        Case assertCse =  Database.query(assertCaseQuery);
        
        // If the contact is having more than one ACR, And Insp Account status is updated Terminated then 
        // NSP_CorporateEmployeeEE__c will be false
        system.assertEquals(true, assertCse.NSP_CorporateEmployeeEE__c);
        
    }

}