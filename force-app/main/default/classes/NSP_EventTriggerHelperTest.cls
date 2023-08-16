@isTest
public without sharing class NSP_EventTriggerHelperTest {
    
    @testSetup
    public static void setupTestData(){
        //Creating account
        List<Account> accList = new List<Account>();
		Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc.Name = 'Test Account';
        accList.add(acc);        
        Account acc1 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc1.Name = 'Test Account 1';
        accList.add(acc1); 
        Database.insert(accList);
        
        //Creating Contact
        List<Contact> conList = new List<Contact>();
        Contact con = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        con.LastName = 'Test con';
        con.AccountId = acc.Id;
        conList.add(con);
        Contact con1 = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        con1.LastName = 'Test con1';
        con1.AccountId = acc1.Id;
        conList.add(con1);
        Database.insert(conList);
        
        //Creating Lead
        List<Lead> leadList = new List<Lead>(); 
        Id referralLeadRecId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Referral').getRecordTypeId(); //Mani
        Lead leadObject = (Lead)NSP_TestExtendedDataFactory.createSObject(new Lead(), 'NSP_TestDataFactory.LeadDefaults', false);
        leadObject.firstname='Test';
        leadObject.lastname='Lead';
        leadObject.Company = 'TestClass';
        leadObject.NumberOfEmployees =152;
        leadObject.Email = 'testlead1@testlead1.com';
        leadObject.PostalCode = '10001';
        leadObject.DNBoptimizer__DNB_D_U_N_S_Number__c  = '876543987';
        //Adding lead object to the list
        leadList.add(leadObject);
        Database.insert(leadList);

        //Creating new SFS User
        User newUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        newUser.firstname = 'Test SFS User';
        newUser.NSP_Salesforce_Field_Service__c = 'Resource';
        newUser.NSP_Dispatch_Region__c = 'Central';
        insert newUser;
        
    }
    
        
    /**
    * @Description: This test method is used to cover negatvie scenrio for outlook event type conversion of updateOutlookEvents method
    * @Created date: 5/12/2022. 
    * @return void             
    * Note we can only cover negative scenario for updateOutlookEvents method beacuse we cannot update IsRecurrence2 field
    */
    @isTest
    public static void updateOoutlookevent(){
        List<String> EVENT_FIELD = new List<String>{'Id', 'WhatId'};
        List<String> ID_FIELD = new List<String>{'Id'};
        //Get sfsUser user rec
        String accquery = new NSP_QueryBuilder('Account', ID_FIELD)
                            .addFilter('Name', 'Test Account').addLimit(1).build();
        Account accTest = Database.query(accquery);
        
        String conquery = new NSP_QueryBuilder('Contact', ID_FIELD)
                            .addFilter('LastName', 'Test con').addLimit(1).build();
        Contact conTest = Database.query(conquery);
        
        User sfsUser = [SELECT Id FROM User WHERE firstname = 'Test SFS User' LIMIT 1];
        
        String acc1query = new NSP_QueryBuilder('Account', ID_FIELD)
                            .addFilter('Name', 'Test Account 1').addLimit(1).build();
        Account accTest1 = Database.query(acc1query);
        //New Test Event 
        Event newEvent = new Event();
        newEvent.OwnerId = sfsUser.Id;
        newEvent.Subject = 'Test Subject For Event';
        newEvent.DurationInMinutes = 60;
        newEvent.ActivityDateTime = system.today();
        newEvent.StartDateTime     = system.today();
        newEvent.NSP_Event_Subtype__c = 'Discovery Call';
        newEvent.WhoId = conTest.Id;
        newEvent.WhatId = accTest.Id;
	    String con1query = new NSP_QueryBuilder('Contact', ID_FIELD)
                            .addFilter('LastName', 'Test con1').addLimit(1).build();
        Contact conTest1 = Database.query(con1query);

        //when
        Test.startTest();
        insert newEvent;
        newEvent.WhoId = conTest1.Id;
        update newEvent;
        Test.stopTest();
        //then
        String query = new NSP_QueryBuilder('Event', EVENT_FIELD)
                            .addFilter('Subject', 'Test Subject For Event').addLimit(1).build();
        Event  eventRec = Database.query(query);
        System.assertequals(true,eventRec.WhatId != null);
    }

    /**
    * @Description: This test method is used to cover updateActivityDate
    * @Created date: 6/12/2023. 
    * @return void  
    */
    @isTest
    public static void updateActivityDate(){
        List<String> EVENT_FIELD = new List<String>{'Id', 'WhatId'};
        List<String> ID_FIELD = new List<String>{'Id'};
        //Get sfsUser user rec and lead rec
        String userquery = new NSP_QueryBuilder('User', ID_FIELD)
                            .addFilter('firstname ', 'Test SFS User').addLimit(1).build();
        User sfsUser = Database.query(userquery);
        String leadquery = new NSP_QueryBuilder('Lead', ID_FIELD)
                            .addFilter('FirstName ', 'Test').addLimit(1).build();
        Lead leadTest = Database.query(leadquery);

        //New Test Event 2
        Event newEvent2 = (Event)NSP_TestExtendedDataFactory.createSObject(new Event(), 'NSP_TestDataFactory.EventDefaults', false);
        newEvent2.OwnerId = sfsUser.Id;
        newEvent2.Subject = 'Test Subject For Event 2';
        newEvent2.DurationInMinutes = 65;
        newEvent2.NSP_Event_Subtype__c = 'Discovery Call';
        newEvent2.ActivityDateTime = system.today()-1;
        newEvent2.StartDateTime     = system.today()-1;
        insert newEvent2;
        newEvent2.ActivityDateTime = system.today();
        newEvent2.StartDateTime     = system.today();
        newEvent2.WhoId = leadTest.Id;
        //when
        Test.startTest();
        update newEvent2;
        Test.stopTest();
        //then
        String query = new NSP_QueryBuilder('Event', EVENT_FIELD)
                            .addFilter('Subject', 'Test Subject For Event 2').addLimit(1).build();
        Event  eventRec = Database.query(query);
        System.assertequals(null,eventRec.WhatId);
    }
}