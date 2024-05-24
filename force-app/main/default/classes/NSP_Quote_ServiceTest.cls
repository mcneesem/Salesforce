/**
* Represents test class for NSP_Quote_Service
* Created by : Tejas
* Created Date : 20/Dec/2021
*/
@isTest
public without sharing class NSP_Quote_ServiceTest {
    @testSetup
    static void testData() {
        //Account creation
        Account accoutObject = new Account();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('NSP_Partner_Client').getRecordTypeId();
        accoutObject.Name = 'Test Account';
        accoutObject.recordTypeId=partnerRecordTypeId;
        accoutObject.DNB_Connect_DUNS_Number__c = '876543987';
        //Inserting account object
        insert accoutObject;
        
        Account accoutObject1 = new Account();
        accoutObject1.Name = 'Test Account1';
        
        //Inserting account object
        insert accoutObject1;
        
        //Contact creation        
        Contact contactObject = new Contact();
        contactObject.lastname = 'TestContact';
        contactObject.email = 'test@test.com';
        contactObject.AccountId=accoutObject1.id;
        //Inserting contact object
        insert contactObject;
        
        //AccountContactRelation  creation
        AccountContactRelation AccountContactRelationObject = new AccountContactRelation();
        AccountContactRelationObject.accountid= accoutObject.Id;
        AccountContactRelationObject.ContactId = contactObject.Id;
        AccountContactRelationObject.NSP_Is_Primary__c = true;
        insert AccountContactRelationObject;
    }
    @isTest
    public static void getDocusignUrlTest(){
        String DOCUSIGN_AID=System.Label.NSP_Docusign_Account_Id;
        string sUrl = NSP_Quote_Service.getDocuSignUrl('testRecordId','testTemplateId','testName','testAccountName',DOCUSIGN_AID);
        System.assertEquals(true, sUrl.contains('testAccountName'));
    }
    @isTest
    public static void validateCustomerSignerTest(){
        Test.startTest();    
        List<Contact> contactList = [SELECT Id FROM Contact];
        List<Account> accountList = [SELECT Id FROM Account WHERE Name = 'Test Account'];    
        Boolean isContractUpdated= NSP_Quote_Service.validateCustomerSigner(accountList[0].Id,contactList[0].Id);
        System.assert(isContractUpdated);    
        Test.stopTest();   
    }
}