@isTest
private class NSP_EventTriggerHelperTest {
    private static final String DISCOVERY_CALL = 'Discovery Call';
    
    @testSetup
    private static void setupTestData(){
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
        Lead leadObject = (Lead)NSP_TestExtendedDataFactory.createSObject(new Lead(), 'NSP_TestDataFactory.LeadDefaults', false);
        leadObject.firstname='Test';
        leadObject.lastname='Lead';
        leadObject.Company = 'TestClass';
        leadObject.NumberOfEmployees =152;
        leadObject.Email = 'testlead1@testlead1.com';
        leadObject.PostalCode = '10001';
        leadObject.DNB_Connect_DUNS_Number__c  = '876543987';
        //Adding lead object to the list
        leadList.add(leadObject);
        Database.insert(leadList);

        //Creating new SFS User
        User newUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        newUser.firstname = 'Test SFS User';
        newUser.NSP_Salesforce_Field_Service__c = 'Resource';
        newUser.NSP_Dispatch_Region__c = 'Central';
        insert newUser;
        
        
        //New Test Event 
        Event newEvent = new Event();
        newEvent.Subject = 'Test Subject For Event RA';
        newEvent.DurationInMinutes = 60;
        newEvent.ActivityDateTime = system.today();
        newEvent.StartDateTime = system.today();
        newEvent.NSP_Event_Subtype__c = DISCOVERY_CALL;
        insert newEvent;
        
        //Insert User
        User userRecord1 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id,
            LastName = 'TestClassUser',
            Email = 'testuser1@insperity.com',
            Username = 'testuser1@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            );
        insert userRecord1; 
        //Insert Service Resource
        ServiceResource serRec = new ServiceResource();
        serRec.RelatedRecordId = userRecord1.Id;
        serRec.ResourceType = 'T';
        serRec.IsActive = True;
        serRec.Name = 'Test';
        insert serRec;
        
        //Insert Resource Absence
        ResourceAbsence resObject = new ResourceAbsence();
        resObject.Type = 'Meeting';
        resObject.ResourceId = serRec.Id;
        resObject.Start = system.today();
        resObject.End = system.today().addDays(1);
        resObject.Event_Id__c = newEvent.Id;
        Insert resObject;
        
        Id eventRecordType = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Core_Sales_Event_RT')?.getRecordTypeId();
        User tUser =  NSP_TestHelper.createUser(false);
        tUser.Phone = '(112)6475261 ext415';
        tUser.Username = 'jsmith@test.com.abc'+System.currentTimeMillis();
        tUser.NSP_Service_Region__c = 'MMSO - Southeast';
        tUser.NSP_Salesforce_Field_Service__c = NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_DISPATCHER_RESOURCE;
        tUser.NSP_Dispatch_Region__c = NSP_ServiceConstants.CHILD_DISPATCH_REGION;
        insert tUser;
        Event newEventRec = new Event();
        newEventRec.OwnerId = tUser.Id;
        newEventRec.Subject = 'Test Subject For Event Rec';
        newEventRec.DurationInMinutes = 60;
        newEventRec.ActivityDateTime = system.today();
        newEventRec.StartDateTime = system.today();
        newEventRec.IsRecurrence = true;
        newEventRec.RecurrenceStartDateTime = system.today();
        newEventRec.RecurrenceEndDateOnly = System.today()+30;
        newEventRec.RecurrenceType = 'RecursDaily';
        newEventRec.RecurrenceInterval = 2; // This means that the event will wait 1 day before recurring again
        newEventRec.IsAllDayEvent =false;
        newEventRec.DurationInMinutes =60;
        newEventRec.RecordTypeId = eventRecordType;
        system.runAs(tUser){
            insert newEventRec; 
        }
        
        //Insert Resource Absence
        ResourceAbsence resObject1 = new ResourceAbsence();
        resObject1.Type = 'Meeting';
        resObject1.ResourceId = serRec.Id;
        resObject1.Start = system.today();
        resObject1.End = system.today().addDays(1);
        resObject1.Event_Id__c = newEventRec.Id;
        Insert resObject1;
        
        User tUser2 =  NSP_TestHelper.createUser(false);
        tUser2.Phone = '(112)6475261 ext415';
        tUser2.Username = 'jroy@test.com.abc'+System.currentTimeMillis();
        tUser2.NSP_Service_Region__c = 'MMSO - Southeast';
        tUser2.NSP_Salesforce_Field_Service__c = NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_DISPATCHER_RESOURCE;
        tUser2.NSP_Dispatch_Region__c = NSP_ServiceConstants.CHILD_DISPATCH_REGION;
        insert tUser2;

        EventRelation er = new EventRelation();
        er.RelationId= tUser2.Id;
        er.EventId = newEventRec.Id;
        er.IsInvitee = true;
        insert er; 
        
        Event newEventRec1 = new Event();
        newEventRec1.OwnerId = tUser2.Id;
        newEventRec1.Subject = 'Test Subject For Event Rec';
        newEventRec1.DurationInMinutes = 60;
        newEventRec1.ActivityDateTime = system.today();
        newEventRec1.StartDateTime = system.today();
        newEventRec1.IsRecurrence = true;
        newEventRec1.RecurrenceStartDateTime = system.today();
        newEventRec1.RecurrenceEndDateOnly = System.today()+30;
        newEventRec1.RecurrenceType = 'RecursDaily';
        newEventRec1.RecurrenceInterval = 2; // This means that the event will wait 1 day before recurring again
        newEventRec1.IsAllDayEvent =false;
        newEventRec1.DurationInMinutes =60;
        newEventRec1.RecordTypeId = eventRecordType;
        system.runAs(tUser2){
            insert newEventRec1; 
        }
        NSP_EventTriggerHelper.testHandleException( null , null );
    }
    
        
    /**
    * @Description: This test method is used to cover negatvie scenrio for outlook event type conversion of updateOutlookEvents method
    * @Created date: 5/12/2022. 
    * @return void             
    * Note we can only cover negative scenario for updateOutlookEvents method beacuse we cannot update IsRecurrence2 field
    */
    @isTest
    private static void updateOoutlookevent(){
        List<String> eventField = new List<String>{'Id', 'WhatId'};
        List<String> idField = new List<String>{'Id'};
        //Get sfsUser user rec
        String accquery = new NSP_QueryBuilder('Account', idField)
                            .addFilter('Name', 'Test Account').addLimit(1).build();
        Account accTest = Database.query(accquery);
        
        String conquery = new NSP_QueryBuilder('Contact', idField)
                            .addFilter('LastName', 'Test con').addLimit(1).build();
        Contact conTest = Database.query(conquery);
        
        User sfsUser = [SELECT Id FROM User WHERE firstname = 'Test SFS User' LIMIT 1];
        
        //New Test Event 
        Event newEvent = new Event();
        newEvent.OwnerId = sfsUser.Id;
        newEvent.Subject = 'Test Subject For Event';
        newEvent.DurationInMinutes = 60;
        newEvent.ActivityDateTime = system.today();
        newEvent.StartDateTime     = system.today();
        newEvent.NSP_Event_Subtype__c = DISCOVERY_CALL;
        newEvent.WhoId = conTest.Id;
        newEvent.WhatId = accTest.Id;
        String con1query = new NSP_QueryBuilder('Contact', idField)
                            .addFilter('LastName', 'Test con1').addLimit(1).build();
        Contact conTest1 = Database.query(con1query);

        //when
        Test.startTest();
        insert newEvent;
        newEvent.WhoId = conTest1.Id;
        update newEvent;
        Test.stopTest();
        //then
        String query = new NSP_QueryBuilder('Event', eventField)
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
    private static void updateActivityDate(){
        List<String> eventField = new List<String>{'Id', 'WhatId'};
        List<String> idField = new List<String>{'Id'};
        //Get sfsUser user rec and lead rec
        String userquery = new NSP_QueryBuilder('User', idField)
                            .addFilter('firstname ', 'Test SFS User').addLimit(1).build();
        User sfsUser = Database.query(userquery);
        String leadquery = new NSP_QueryBuilder('Lead', idField)
                            .addFilter('FirstName ', 'Test').addLimit(1).build();
        Lead leadTest = Database.query(leadquery);

        //New Test Event 2
        Event newEvent2 = (Event)NSP_TestExtendedDataFactory.createSObject(new Event(), 'NSP_TestDataFactory.EventDefaults', false);
        newEvent2.OwnerId = sfsUser.Id;
        newEvent2.Subject = 'Test Subject For Event 2';
        newEvent2.DurationInMinutes = 65;
        newEvent2.NSP_Event_Subtype__c = DISCOVERY_CALL;
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
        String query = new NSP_QueryBuilder('Event', eventField)
                            .addFilter('Subject', 'Test Subject For Event 2').addLimit(1).build();
        Event  eventRec = Database.query(query);
        System.assertequals(null,eventRec.WhatId);
    }
    
    /**
    * @Description: This test method is used to cover afterDelete
    * @return void  
    */
    @isTest
    private static void afterDeleteTest(){
        Test.startTest();
        List<Event> eventList = [SELECT ID, Subject FROM Event WHERE Subject = 'Test Subject For Event Rec' LIMIT 1];
        if(eventList.size() > 0){
            DELETE eventList[0];
        }
        Test.stopTest();
    }
    
    
    /**
    * @Description: This test method is used to cover updateResourceAbsenceDate
    * @return void  
    */
    @isTest
    private static void resyncTest(){
        Test.startTest();
        List<Event> eventList = [SELECT ID, Subject, IsRecurrence, StartDateTime FROM Event WHERE Subject = 'Test Subject For Event Rec' AND IsRecurrence = true LIMIT 1];
        if(eventList.size() > 0){
            eventList[0].StartDateTime = System.today().addDays(1);
        }
        update eventList[0];
        Test.stopTest();
    }
    
    @isTest
    private static void eventRelationCreation(){
        Test.startTest();
        List<Event> eventList = [SELECT ID, Subject, IsRecurrence, StartDateTime FROM Event WHERE Subject = 'Test Subject For Event Rec' LIMIT 1];
        List<User> userList = [SELECT ID, NSP_Service_Region__c FROM User where NSP_Service_Region__c = 'MMSO - Southeast' AND Phone = '(112)6475261 ext495'];
        if(eventList.size() > 0 && userList.size() > 0){
            EventRelation er = new EventRelation();
            er.RelationId= userList[0].Id;
            er.EventId = eventList[0].Id;
            er.IsInvitee = True;
            insert er;
        }
        Test.stopTest();
    }

    @IsTest 
    private static void testEventCreatorTitle() {
        
        Test.startTest();
        List<User> user = [SELECT Id, Title FROM User WHERE Profile.Name = 'System Administrator' AND title != null LIMIT 1];
        if(user != null && user.size() == 1) {
            System.runAs(user[0]) {
                Lead testLead = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Company = 'Test Company',
                Email = 'testlead@testcompany.com',
                OwnerId = user[0].Id
                );
                insert testLead;
    
                // Create Event with Discovery Call subtype and Open status
                DateTime testtime = System.now();
                Id eventRecTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Core_Sales_Event_RT').getRecordTypeId();
                Event testEvent = new Event(
                WhoId = testLead.Id,    
                OwnerId = user[0].Id,
                NSP_Lead__c = testLead.Id,
                RecordTypeId = eventRecTypeId,
                NSP_Event_Type__c = 'Core Sales',
                NSP_Event_Subtype__c = 'Discovery Call',
                NSP_Status__c = 'Open',
                ActivityDateTime = testtime,
                StartDateTime = testtime,
                EndDateTime = testtime,
                ActivityDate = System.today()
                );
                insert testEvent;

                Test.stopTest();
                Event event = [SELECT id, Creator_Title__c FROM Event WHERE id = :testEvent.id ];
                System.assertEquals(user[0].title, event.Creator_Title__c);

            }
       }       
    }

}