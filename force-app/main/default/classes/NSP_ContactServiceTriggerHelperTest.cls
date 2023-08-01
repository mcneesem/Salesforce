/* 
*    Class Name  : NSP_ContactServiceTriggerHelperTest
*    @Description: Represents test class ContactServiceTriggerHelper of Service Stream.
*    @Date       : 05/11/2022
*/

@isTest
public with sharing class NSP_ContactServiceTriggerHelperTest {
    
    /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    @testSetup
    static void setupTestData(){
        //Creating Account
        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        insert newAccount;
        
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.AccountId = newAccount.Id;
        newContact.NSP_SSN__c = '123-45-6789';
        newContact.NSP_Date_Of_Birth__c = System.Today();
        Insert newContact;
      
    }
    
    /**
* INSERT : Test method to check if first name is populated on Preferred First Name
* @param N/A. 
* @return void                          
*/
    
    @isTest
    private static void populatePreferredFirstNameOnInsert() {
        // Query Account
        Account acc = [SELECT id FROM Account WHERE id != null LIMIT 1];
        
        //Creating Contact
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.Account = acc;
        
        test.startTest();
        insert newContact;
        
        //Query inserted Contact
        Contact con = [SELECT FirstName, NSP_Preferred_First_Name__c FROM Contact WHERE ID = : newContact.id];
        System.assertEquals(con.FirstName, 
                            con.NSP_Preferred_First_Name__c,
                            'Contact First Name will be populated on Preferred First Name');
        test.stopTest();
    }
    
    /**
* UPDATE : Test method to check if first name is populated on Preferred First Name
* @param N/A. 
* @return void                          
*/
    @isTest
    private static void populatePreferredFirstNameOnUpdate() {
        //Query Account
        Account acc = [SELECT id FROM Account WHERE Id != null LIMIT 1];
        
        // Creating Contact
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', true);
        newContact.AccountId = acc.Id;
        newContact.FirstName = 'Test';
        newContact.NSP_Preferred_First_Name__c = 'Test1';
        Update newContact;
        // Updating Contact
        newContact.NSP_Preferred_First_Name__c = '';
        newContact.FirstName = 'Test';
        update newContact;

        test.startTest();      
        //Query updated Contact
        Contact con = [SELECT FirstName, NSP_Preferred_First_Name__c FROM Contact WHERE ID = : newContact.id];
        System.assertEquals(con.FirstName, 
                            con.NSP_Preferred_First_Name__c,
                            'Contact First Name will be populated on Preferred First Name');
        test.stopTest();
    }
    
    @isTest
    private static void shouldUpdateSSNAndDOBOnUpdate() {
        
         test.startTest();
        
        //Query Contact And Update Contact
        Contact con = [SELECT FirstName, NSP_Date_Of_Birth__c, NSP_Preferred_First_Name__c,NSP_SSN_Masked__c,NSP_SSN_Unmasked__c, NSP_Date_Of_Birth_Masked__c,NSP_Date_Of_Birth_Unmasked__c FROM Contact WHERE Id != null LIMIT 1];
        
        con.NSP_SSN__c = '123-45-6789';
        con.NSP_Date_Of_Birth__c =  System.today() -30;
        update con;
        con.NSP_Date_Of_Birth__c = System.today()+30;
        update con;
        con.NSP_Date_Of_Birth__c =  System.today()-60;
        update con;
        con.NSP_Date_Of_Birth__c = System.today()+60;
        update con;
         con.NSP_Date_Of_Birth__c =  System.today() -90;
        update con;
        con.NSP_Date_Of_Birth__c = System.today()+90;
        update con;
        con.NSP_Date_Of_Birth__c =  System.today()-120;
        update con;
        con.NSP_Date_Of_Birth__c = System.today()+120;
        update con;
         con.NSP_Date_Of_Birth__c =  System.today() -150;
        update con;
        con.NSP_Date_Of_Birth__c = System.today()+150;
        update con;
        con.NSP_Date_Of_Birth__c =  System.today()-180;
        update con;
        con.NSP_Date_Of_Birth__c = System.today()+180;
        update con;
       
        System.assert(con.NSP_SSN_Masked__c.contains('X'));
        System.assert(con.NSP_SSN_Unmasked__c == null);
        System.assert(con.NSP_Date_Of_Birth_Masked__c != null);
        System.assert(con.NSP_Date_Of_Birth_Masked__c.contains('X'));
        System.assert(con.NSP_Date_Of_Birth_Unmasked__c == null);
        test.stopTest();
    }

    
        /**
    * UPDATE : Test method to check if Pin Validated turns to false when service request channel is set to blank
    * @param N/A. 
    * @return void                          
    */
    @isTest
    private static void populatePinValidatedOnUpdate() {
        //Query Account
        Account acc = [SELECT id FROM Account WHERE Name!=null LIMIT 1];
        
        // Creating Contact
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', true);
        newContact.AccountId = acc.Id;
        newContact.FirstName = 'Test';
        newContact.NSP_Preferred_First_Name__c = 'Test1';
        newContact.NSP_Service_Request_Channel__c = 'Phone';

        Update newContact;
        
        // Updating Contact
        newContact.NSP_Preferred_First_Name__c = '';
        newContact.FirstName = 'Test';
        newContact.NSP_Service_Request_Channel__c = '';
        update newContact;

        test.startTest();
        
        
        //Query updated Contact
        Contact con = [SELECT FirstName, NSP_Preferred_First_Name__c,NSP_Pin_Validated__c FROM Contact WHERE ID = : newContact.id];
        System.assertEquals(false, 
                            con.NSP_Pin_Validated__c,
                            'Pin Validated should be false');
        test.stopTest();
    }   
}