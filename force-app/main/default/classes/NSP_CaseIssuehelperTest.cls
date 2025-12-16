/**
* @description  :   Test class for NSP_CaseIssuehelper .
* @date 01/27/2023
* Author : Nischay Jindal
* Name : NSP_CaseIssuehelperTestTest(94%)
*/
@isTest
public class NSP_CaseIssuehelperTest {
    
    private static final String ACCOUNTDEFAULTS = 'NSP_TestDataFactory.AccountDefaults';
    private static final String CASEDEFAULTS  = 'NSP_TestDataFactory.CaseDefaults';
    private static final Id bpsProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', NSP_ServiceConstants.PROJECT_BPS_RECORDTYPE);
    private static final Id bpsRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(NSP_ServiceConstants.BPS).getRecordTypeId();//11/10/2023-Suhas Added -STY-234800
    private static final List<String> PROJECT_FIELDS = new List<String>{
        'Id',
            'Name',
            'pse__Start_Date__c',
            'Templates_Used__c',
            'Peer_Review__c'      
            };
    private static final List<String> CASE_FIELDS = new List<String>{
        'Id',
            'NSP_CorporateEmployeeEE__c', 'AccountId', 'ContactId'
            };

    /***********************************************************************************************
    * MethodName: testData
    * Description : Setting the Test Data
    * ********************************************************************************************/                
    @testSetup
    static void testData() {
        Email_Deliverability_Settings__c emailSetting = new Email_Deliverability_Settings__c();
        insert emailSetting;

        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), ACCOUNTDEFAULTS, true);
        //create new contact
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.Account = newAccount;
        newContact.NSP_Work_email__c = 'test123@efg.com';
        insert newContact;
        
        NSP_Case_Issue__c caseIssue = (NSP_Case_Issue__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Case_Issue__c(), false); 
        caseIssue.Name = 'TestIssue';
        caseIssue.NSP_Rating__c ='Neutral';
        insert caseIssue;
        
        Case cs = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);        
        cs.contactId = newContact.Id;
        cs.AccountId = newAccount.Id;
        cs.RecordTypeId = bpsRecordTypeId;//11/10/2023-Suhas Added -STY-234800
        cs.NSP_Case_Issue__c = caseIssue.Id;
        insert cs;
        
    }
    /***********************************************************************************************
    * MethodName: validateCaseClosedStatus
    * Description : Unit test for validateCaseClosedStatus 
    * ********************************************************************************************/
    @isTest
    private static void validateCaseClosedStatus(){
        List<String> caseIssueFields = new List<String>{
            'Id',
            'NSP_Status__c',
            'NSP_Rating__c'
        };
        String caseIssueQuery = new NSP_QueryBuilder('NSP_Case_Issue__c', caseIssueFields)
                         .addFilter('NSP_Rating__c', 'Neutral').addLimit(1).setSecurityEnforce(false).build();
        NSP_Case_Issue__c caseIssue = Database.query(caseIssueQuery);

        List<String> caseFields = new List<String>{
            'Id',
            'NSP_Case_Issue__c',
            'contactId',
            'Status',
            'NSP_Rating__c'
        };
        String caseQuery = new NSP_QueryBuilder('CASE', caseFields).addLimit(1).setSecurityEnforce(false).build();
        Case cs = Database.query(caseQuery);
        caseIssue.NSP_Status__c ='Closed';
        try{
            Test.startTest();
            //update Case Issue
            update caseIssue;
            Test.stopTest();
        }
        catch(Exception ex){
            Boolean isExpectedExceptionThrown =  ex.getMessage().contains(label.NSP_CaseIssueNotification) ? true : false;
            System.assertEquals(isExpectedExceptionThrown, true);
        }   
        
    }
    /***********************************************************************************************
    * MethodName: validateCaseClosedStatusTest
    * Description : Unit test for validateCaseClosedStatus 
    * ********************************************************************************************/
    @isTest
    private static void validateCaseClosedStatusTest(){
        List<String> caseIssueFields = new List<String>{
            'Id',
            'NSP_Status__c',
            'NSP_Rating__c'
        };
        String caseIssueQuery = new NSP_QueryBuilder('NSP_Case_Issue__c', caseIssueFields)
                         .addFilter('NSP_Rating__c', 'Neutral').addLimit(1).setSecurityEnforce(false).build();
        NSP_Case_Issue__c caseIssue = Database.query(caseIssueQuery);

        List<String> caseFields = new List<String>{
            'Id',
            'NSP_Case_Issue__c',
            'contactId',
            'Status',
            'NSP_Case_Sub_Status__c',
            'NSP_Rating__c'
        };
        String caseQuery = new NSP_QueryBuilder('CASE', caseFields).addLimit(1).setSecurityEnforce(false).build();
        Case cs = Database.query(caseQuery);

        EmailMessage eMsg = (EmailMessage)NSP_TestExtendedDataFactory.createSObject(new EmailMessage(), false);
        eMsg.FromAddress = 'test@test.com';
        eMsg.ToAddress= 'test@xyz.com';
        eMsg.Subject = 'Test email Subject';
        eMsg.HtmlBody = 'Test email body';
        eMSg.Incoming = False;
        eMSg.RelatedToId = caseIssue.id;
        insert eMSg;

        caseIssue.NSP_Status__c ='Closed';        
        Test.startTest();
        //update Case Issue
         update caseIssue;
        Test.stopTest();
        Case closeCase = Database.query(caseQuery);
        system.assertEquals(closeCase.Status, 'Closed');
        system.assertEquals(closeCase.NSP_Case_Sub_Status__c, 'Closed');//11/10/2023-Suhas Added -STY-234800
    }

    @IsTest
    static void beforeDelete() {
        new NSP_CaseIssueHandler().beforeDelete(null, null);
         System.assert(new NSP_CaseIssueHandler().beforeDelete(null, null) == null);
    }
    @IsTest
    static void afterDelete() {
        new NSP_CaseIssueHandler().afterDelete(null, null);
         System.assert(new NSP_CaseIssueHandler().afterDelete(null, null) == null);
    }
}