/**
Apex Class Name      :  NSP_CaseContactTriggerHelperTest
Version              :  1.0                                                                          
Created Date         :  11/7/2022  
Function             :  Represents test class for NSP_CaseContactTriggerHelper 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------        
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------    
*/
@isTest(SeeAllData=false)
private class NSP_CaseContactTriggerHelperTest {
    
    private static final String PRIMARY_CONTACT_FIRSTNAME = 'Curie';
    private static final String SECONDARY_CONTACT_FIRSTNAME = 'Mrie';
    private static final String CONTACT_DEFAULT_TESTFACTORY = 'NSP_TestDataFactory.ContactDefaultsLight';
    private static final String ACCOUNT_ID = 'AccountId';
    private static final List<String> ACCOUNT_FIELDS = new List<String>{'Id', 'Name'};
    private static final List<String> CASE_FIELDS = new List<String>{'Id', 'NSP_CorporateEmployeeEE__c', ACCOUNT_ID, 'ContactId'};
    private static final List<String> CONTACT_FIELDS = new List<String>{'Id', 'Name'};
    private static final List<String> ACR_FIELDS = new List<String>{'Id', ACCOUNT_ID, 'ContactId', 'NSP_Employee_Status__c'};
    
    /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    
    @testSetup
    static void testData() {
        List<Contact> conList = new List<Contact>();
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
        Account insAcc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        insAcc.Name = System.Label.NSP_Insperity_Account;
        insert insAcc;
        Contact insPriCon = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), CONTACT_DEFAULT_TESTFACTORY, false);
        insPriCon.AccountId = insAcc.Id;
        insPriCon.FirstName = 'INS ' + PRIMARY_CONTACT_FIRSTNAME;
        conList.add(insPriCon);
        Contact insSecCon = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), CONTACT_DEFAULT_TESTFACTORY, false);
        insSecCon.AccountId = insAcc.Id;
        insSecCon.FirstName = 'INS ' + SECONDARY_CONTACT_FIRSTNAME;
        conList.add(insSecCon);
        
        Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), CONTACT_DEFAULT_TESTFACTORY, false);
        oContact.AccountId = oAccount.Id;
        oContact.FirstName = PRIMARY_CONTACT_FIRSTNAME;
        conList.add(oContact);
        Contact oContact1 = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), CONTACT_DEFAULT_TESTFACTORY, false);
        oContact1.FirstName = SECONDARY_CONTACT_FIRSTNAME;
        oContact1.AccountId = insAcc.Id;
        conList.add(oContact1);
        Database.insert(conList);
        Test.startTest();
        AccountContactRelation acr = (AccountContactRelation)NSP_TestExtendedDataFactory.createSObject(new AccountContactRelation(), 'NSP_TestDataFactory.acrDefaults', false);
        acr.Accountid = oAccount.id;
        acr.Contactid = insPriCon.id;
        insert acr;
        
        Case insCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        insCase.AccountId = insAcc.Id;
        insCase.ContactId = insPriCon.id;
        insCase.NSP_CorporateEmployeeEE__c = true;
        Insert insCase;
        Test.stopTest();
        
    }
    
    /**
* @Description: This test method is used to cover beforeInsertDirector method
* @Created date: 07/18/2022. 
* @return void             
*     */  
    @isTest
    private static void beforeInsertDirectorTest(){
        List<NSP_Case_Contacts__c> cseConList = new List<NSP_Case_Contacts__c>();
        NSP_Case_Contacts__c fPrimaryCseCon = new NSP_Case_Contacts__c();
        fPrimaryCseCon.NSP_Contact__c = [SELECT Id, Name FROM Contact WHERE FirstName =: PRIMARY_CONTACT_FIRSTNAME LIMIT 1].Id;
        fPrimaryCseCon.NSP_Case__c = [SELECT Id, CaseNumber FROM Case WHERE CaseNumber != NULL LIMIT 1].Id;
        fPrimaryCseCon.NSP_IsPrimary__c = true;
        cseConList.add(fPrimaryCseCon);
        Database.insert(cseConList); // inserting first Primary Case contact with ISPRIMARY = TRUE
        NSP_Case_Contacts__c sPrimaryCseCon = new NSP_Case_Contacts__c();
        sPrimaryCseCon.NSP_Contact__c =  [SELECT Id, Name FROM Contact WHERE FirstName =: SECONDARY_CONTACT_FIRSTNAME LIMIT 1].Id;
        sPrimaryCseCon.NSP_Case__c = [SELECT Id, CaseNumber FROM Case WHERE CaseNumber != NULL LIMIT 1].Id;
        sPrimaryCseCon.NSP_IsPrimary__c = true;
        Test.startTest();
        Database.insert(sPrimaryCseCon); // inserting Secondary Primary Case Contact with ISPRIMARY = TRUE so that First Primary Case Contact's ISPRIMARY will be false.
        Test.stopTest();
        NSP_Case_Contacts__c getFirstPrimayCaseContact = [SELECT Id, 
                                                          NSP_Contact__c, 
                                                          NSP_Contact__r.Name, 
                                                          NSP_IsPrimary__c 
                                                          FROM NSP_Case_Contacts__c
                                                          WHERE NSP_Contact__r.FirstName =: PRIMARY_CONTACT_FIRSTNAME LIMIT 1];
        system.assertEquals(false, getFirstPrimayCaseContact.NSP_IsPrimary__c); // Checking assert of First First Primary Case Contact's ISPRIMARY which will be false        
    }
    
    
    /**
* @Description: This test method is used to cover beforeUpdateDirector method
* @Created date: 07/18/2022. 
* @return void             
*     */  
    @isTest
    private static void beforeUpdateDirectorTest(){
        List<NSP_Case_Contacts__c> cseConList = new List<NSP_Case_Contacts__c>();
        NSP_Case_Contacts__c fPrimaryCseCon = new NSP_Case_Contacts__c();
        fPrimaryCseCon.NSP_Contact__c = [SELECT Id, Name FROM Contact WHERE FirstName =: PRIMARY_CONTACT_FIRSTNAME LIMIT 1].Id;
        fPrimaryCseCon.NSP_Case__c = [SELECT Id, CaseNumber FROM Case WHERE CaseNumber != NULL LIMIT 1].Id;
        fPrimaryCseCon.NSP_IsPrimary__c = true;
        cseConList.add(fPrimaryCseCon); // inserting first Primary Case contact with ISPRIMARY = TRUE
        NSP_Case_Contacts__c sPrimaryCseCon = new NSP_Case_Contacts__c();
        sPrimaryCseCon.NSP_Contact__c =  [SELECT Id, Name FROM Contact WHERE FirstName =: SECONDARY_CONTACT_FIRSTNAME LIMIT 1].Id;
        sPrimaryCseCon.NSP_Case__c = [SELECT Id, CaseNumber FROM Case WHERE CaseNumber != NULL LIMIT 1].Id;
        sPrimaryCseCon.NSP_IsPrimary__c = false;
        cseConList.add(sPrimaryCseCon);
        Database.insert(cseConList); // inserting first Secondary Case contact with ISPRIMARY = FALSE
        Test.startTest();
        sPrimaryCseCon.NSP_IsPrimary__c = true;
        Database.update(sPrimaryCseCon); // Updating Secondary Primary Case Contact with ISPRIMARY = TRUE so that First Primary Case Contact's ISPRIMARY will be false.
        Test.stopTest();
        
        NSP_Case_Contacts__c getFirstPrimayCaseContact = [SELECT Id, 
                                                          NSP_Contact__c, 
                                                          NSP_Contact__r.Name, 
                                                          NSP_IsPrimary__c 
                                                          FROM NSP_Case_Contacts__c
                                                          WHERE NSP_Contact__r.FirstName =: PRIMARY_CONTACT_FIRSTNAME LIMIT 1];
        system.assertEquals(false, getFirstPrimayCaseContact.NSP_IsPrimary__c); // Checking assert of First First Primary Case Contact's ISPRIMARY which will be false
    }
    
      /**
* @Description: This test method is used to cover updateCorporateEmployeecheckBox method
* @Created date: 01/08/2023. 
* @return void             
*     */  
    @isTest
    private static void updateCorporateEmployeecheckBoxTest(){
        // Querying Account
        String accQuery = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS).addFilter('Name', System.Label.NSP_Insperity_Account).addLimit(1).build();
        Account insAacc =  Database.query(accQuery);  
        
        // Querying Contact
        String conQuery = new NSP_QueryBuilder('Contact', CONTACT_FIELDS).addFilter('FirstName', 'INS ' + SECONDARY_CONTACT_FIRSTNAME).addLimit(1).build();
        Contact con =  Database.query(conQuery);
        
        // Querying AccountContact Relationship
        String acrQuery = new NSP_QueryBuilder('AccountContactRelation', ACR_FIELDS).addFilter(ACCOUNT_ID, insAacc.Id).
            addLimit(1).build();
        AccountContactRelation acr1 =  Database.query(acrQuery);
        acr1.NSP_Employee_Status__c = 'HIRED';
        update(acr1);
        Test.startTest();
        // Querying Case
        String caseQuery = new NSP_QueryBuilder('Case', CASE_FIELDS).addFilter(ACCOUNT_ID, insAacc.Id).addLimit(1).build();
        Case cse =  Database.query(caseQuery);
        
        // Checking whether NSP_CorporateEmployeeEE__c is true or not when the case is created with Only One ACR
        System.assertEquals(cse.NSP_CorporateEmployeeEE__c, true); // Negative Scenario
    
        // Inserting Additional Contact on Case so that the NSP_CorporateEmployeeEE__c will be false when Case is having multiple Case Contacts
        NSP_Case_Contacts__c addCseCon = (NSP_Case_Contacts__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Case_Contacts__c(), 'NSP_TestDataFactory.caseContactDefaults', false);
        addCseCon.NSP_Contact__c = con.Id;
        addCseCon.NSP_Case__c = cse.Id;
        addCseCon.NSP_IsPrimary__c = false;
        insert addCseCon;
        Test.stopTest();
        Case assertCse =  Database.query(CaseQuery);
        System.assertNotEquals(assertCse.NSP_CorporateEmployeeEE__c, true); // Positive Scenario
    }
    
}