/**
 * Represents test class for Contact trigger helper
 */

@isTest(SeeAllData=FALSE)
public class NSP_ContactTriggerHelperTest {
     private static final List<String> CONTACT_FIELDS = new List<String>{
        'Id',
        'recordTypeId',
        'NSP_Work_Phone__c', 'Email', 'NSP_Work_email__c'};
    private static final List<String> ACR_FIELDS = new List<String>{
        'Id',
        'AccountId', 'ContactId', 'NSP_Work_Email__c', 'NSP_Work_Phone__c'
    };
         private static final List<String> ACCOUNT_FIELDS = new List<String>{
        'Id',
        'Name'
    };
    private static final String TEST_ACCOUNT = 'TestAccount';
    private static final String TEST_ACCOUNT2 = 'TestAccount2';
    /**
     * Checks the Contact After Insert Trigger
     * @param N/A. 
     * @return void                          
     */

    @testSetup
    static void testContactInsert() {
        pse__Region__c region = new pse__Region__c();
        region.Name = NSP_ServiceConstants.UnitedStatesRegion;
        insert region;
        
        pse__Work_Calendar__c workRec = new pse__Work_Calendar__c();
        workRec.name = 'US 40';
        insert workRec;
        
        Account acc = New Account(Name = TEST_ACCOUNT, AccountNumber = '12345');
        insert acc;

        List<Contact>  contactList = New List<Contact>();

        for(integer idx = 0; idx < 5; idx++) {
            contactList.add(New Contact(FirstName = 'FName'+idx, LastName = 'LName'+idx, AccountId = acc.Id));
        }
        Contact newRecTypeContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newRecTypeContact.recordTypeId = NSP_ContactTriggerHelper.NEW_CON_REC_TYPE_ID;
        newRecTypeContact.FirstName = 'newRecordType';
        newRecTypeContact.pse__Salesforce_User__c =  userinfo.getUserId();
        newRecTypeContact.NSP_SSN__c = '123-12-1234';
        newRecTypeContact.AccountId = acc.Id;
        contactList.add(newRecTypeContact);
        Contact oldRecTypeContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oldRecTypeContact.recordTypeId = NSP_ContactTriggerHelper.NEW_CON_REC_TYPE_ID;
        oldRecTypeContact.FirstName = 'oldRecordType';
        contactList.add(oldRecTypeContact);
        
        // Start Test
        Test.startTest();
        if(contactList.size() > 0) {
            insert contactList;
        }
        
        Contact conObj = new Contact();
        conObj.Id  = contactList[5].Id;
        conObj.LastName = 'testupdated';
        conObj.phone = '12876786523';
        conObj.NSP_Client_Reference__c = true;
        conObj.NSP_Reference_Products__c = 'Applicant Tracking';
        conObj.NSP_Reference_Type__c  = 'Client Testimonial';
        conObj.pse__Salesforce_User__c = userinfo.getUserId();
        update conObj;
        
        Contact conObj2 = new Contact();
        conObj2.Id  = contactList[6].Id;
        conObj2.phone = '2287678652 ext 123';
        update conObj2; 
        
        Test.stopTest();
        System.assertEquals(conObj.LastName,'testupdated');
    }

    @isTest
    static void testSalesOffice(){
        
         User currentUser = [SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c 
                            FROM user
                             WHERE Id =:UserInfo.getUserId()];
         currentUser.NSP_Sales_Office__c = '301';
         currentUser.NSP_SalesRegion__c = 'Central 1';
         currentUser.NSP_SalesDivision__c = 'Central';
         update currentUser;
        
        Account acc = New Account(Name = TEST_ACCOUNT, AccountNumber = '12345');
        insert acc;

        List<Contact>  contactList = New List<Contact>();

        for(integer idx = 0; idx < 5; idx++) {
            contactList.add(New Contact(FirstName = 'FName'+idx, LastName = 'LName'+idx, AccountId = acc.Id));
        }

        contactList.add(New Contact(FirstName = 'FName', LastName = 'LName', AccountId = acc.Id,phone = '8987678652'));
		contactList.add(New Contact(FirstName = 'FName T', LastName = 'LNameT', AccountId = acc.Id,phone = '1987678654',NSP_Client_Reference__c = true,NSP_Reference_Products__c = 'Applicant Tracking',NSP_Reference_Type__c  = 'Client Testimonial'));

        // Start Test
        Test.startTest();
        if(contactList.size() > 0) {
            insert contactList;
        }
        Test.stopTest();
        System.assert(contactList.size() > 0);
        
    }
    
     /**
    * @Description: This test method is used to check new Recordtype assignment
    * @Created date: 12/14/2022. 
    * @return void             
    */  
    @isTest
    static void newRecordTypeTest(){ 
        Contact assertPossitiveCon = [SELECT Id, recordTypeId FROM Contact WHERE FirstName = 'newRecordType' LIMIT 1];
        Contact assertNegativeCon = [SELECT Id, recordTypeId FROM Contact WHERE FirstName = 'oldRecordType' LIMIT 1];
        Test.startTest();
        
        Test.stopTest();
        system.assertNotEquals(assertNegativeCon.RecordTypeId, NSP_ContactTriggerHelper.NEW_CON_REC_TYPE_ID); // Negative Test
        system.assertEquals(assertPossitiveCon.RecordTypeId, NSP_ContactTriggerHelper.RESOURCE_REC_TYPE_ID); // Positive Test
    }
    /**
* @Description: This test method is used to check updateWorkPhoneEmailOnACR
* @Created date: 12/14/2022. 
* @return void             
*/  
    @isTest
    static void updateWorkPhoneEmailOnACRTest(){
        String accQuery = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS).addFilter('Name', TEST_ACCOUNT).addLimit(1).build();
        Account acc =  Database.query(accQuery);
        String conQuery = new NSP_QueryBuilder('Contact', CONTACT_FIELDS).addFilter('FirstName', 'newRecordType').addLimit(1).build();
        Contact getContact =  Database.query(conQuery);
        getContact.NSP_Work_Phone__c = '1231231231';
        getContact.NSP_Work_Email__c = 'test@gmail.com';
        Test.startTest();
        database.update(getContact);
        Test.stopTest();
        String acrQuery = new NSP_QueryBuilder('AccountContactRelation', ACR_FIELDS).addFilter('ContactId', getContact.Id).addLimit(1).build();
        AccountContactRelation acr =  Database.query(acrQuery);
        system.assertEquals(acr.NSP_Work_Email__c, 'test@gmail.com');
    } 
    
    /**
* @Description: This test method is used to check updateWorkPhoneEmailOnACR
* @Created date: 12/14/2022. 
* @return void             
*/  
    @isTest
    static void updateWorkPhoneEmailOnACRNegativeTest(){
        String accQuery = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS).addFilter('Name', TEST_ACCOUNT).addLimit(1).build();
        Account acc =  Database.query(accQuery);
        String conQuery = new NSP_QueryBuilder('Contact', CONTACT_FIELDS).addFilter('FirstName', 'newRecordType').addLimit(1).build();
        Contact getContact =  Database.query(conQuery);
        getContact.NSP_Work_email__c = 'test123@gmail.com';
        Test.startTest();
        database.update(getContact);
        Test.stopTest();
        String acrQuery = new NSP_QueryBuilder('AccountContactRelation', ACR_FIELDS).addFilter('AccountId', acc.Id).addLimit(1).build();
        AccountContactRelation acr =  Database.query(acrQuery);
        system.assertNotEquals(acr.NSP_Work_Email__c, 'test@gmail.com'); // Negative Test
    } 
    
        @isTest
    public static void updateContact(){
        Test.startTest();
		Account acc = New Account(Name = TEST_ACCOUNT2, AccountNumber = '123456');
        insert acc;
        Contact cont = [SELECT Id, AccountId, Account.Name FROM Contact WHERE Account.Name =: TEST_ACCOUNT LIMIT 1];
        cont.AccountId = acc.Id;
        update cont;
        Test.stopTest();
        System.assertEquals(1,[SELECT count() FROM Contact WHERE AccountId =: acc.Id]);
        
    }
}