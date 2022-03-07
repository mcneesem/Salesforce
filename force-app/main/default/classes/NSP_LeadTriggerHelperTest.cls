/**
* Represents test class for lead trigger helper
*/

@isTest(SeeAllData=false)
public class NSP_LeadTriggerHelperTest {
    public static final String LEADCONVERTRECORD_EMAIL ='Allstate@Allstate.com';
    public static final String LEADSTATUS ='Nurturing'; // Added as part of code scan fix
    /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    
    @testSetup
    static void testData() {
        
        //Create custom setting record for lead zip to city Mapping
        NSP_Zip_To_City_Mapping__c zipToCityCustomSetting = new NSP_Zip_To_City_Mapping__c();
        zipToCityCustomSetting.NSP_City__c = 'New York';
        zipToCityCustomSetting.NSP_Location_Name__c = 'New York';
        zipToCityCustomSetting.NSP_State__c = 'NY';
        zipToCityCustomSetting.NSP_Zip__c = '10001';
        
        //Creteing zip to city record
        insert zipToCityCustomSetting;
        
        //Create Office records
        NSP_Office__c officeObj =  new NSP_Office__c();
        officeObj.NSP_Last_Index_Used__c = 0;
        officeObj.Name ='New York';
        insert officeObj;
        
        //Creating User
        User userRecord = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id,
            LastName = 'TestClassUser',
            Email = 'testuser@test.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        //Inserting users that can be used in the test class data setup
        insert userRecord;
        
        //Create office assignment record
        NSP_Office_Assignment__c officeAssignmentObj =  new NSP_Office_Assignment__c();
        officeAssignmentObj.NSP_District_Administrator__c= userRecord.id;
        officeAssignmentObj.NSP_Location_Name__c=officeObj.id;
        officeAssignmentObj.NSP_Office_Number__c=1;
        officeAssignmentObj.Name = '3300 New York 1';
        //Inserting office assignment object
        Insert officeAssignmentObj;
        
        //Account creation
        Account accoutObject = new Account();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('NSP_Partner_Client').getRecordTypeId();
        accoutObject.Name = 'Test Account';
        accoutObject.recordTypeId=partnerRecordTypeId;
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
        
        //List to store Lead objects
        List<Lead> leadList = new List<Lead>();
        
        //Lead Creation
        Lead leadObject = new Lead();
        leadObject.firstname='Test';
        leadObject.lastname='Lead';
       
        leadObject.Company = 'TestClass';
       leadObject.NSP_Product_Interest__c = 'Full Service HR (Workforce Optimization)';
        leadObject.NumberOfEmployees =150;
        leadObject.Email = 'testlead1@testlead1.com';
        leadObject.PostalCode = '10001';
        leadObject.NSP_Partner__c =accoutObject.Id;
        leadObject.NSP_Lead_Stage__c  =null;      
        //Adding lead object to the list
        leadList.add(leadObject);

         // STY-01725
         Lead leadObject3 = new Lead();
         leadObject3.firstname='Mark';
         leadObject3.lastname='ZB';
         leadObject3.Company = 'FBook';
         leadObject3.Email = 'fbook@gmail.com';
         leadObject3.NSP_Partner__c =accoutObject.Id;
         leadObject3.NSP_Lead_Stage__c  =null;
         leadList.add(leadObject3);
        
        //Lead Creation
        Lead leadObject1 = new Lead();
        leadObject1.firstname='TestLead';
        leadObject1.lastname='Company';
        leadObject1.NSP_Product_Interest__c='Payroll & Human Capital Management(Workforce Acceleration)';
        leadObject1.NumberOfEmployees =160;
        leadObject1.Company = 'Allstate123';
        leadObject1.Email = LEADCONVERTRECORD_EMAIL;
        leadObject1.NSP_DC_DateTime__c = System.now();

        /* as part of STY-01725 */
        leadObject1.NSP_DC_SetDate__c =  date.today();
        Time myTime = Time.newInstance(1, 2, 3, 0);
        leadObject1.NSP_DC_SetTime__c = myTime;
        leadObject1.NSP_Assign_Lead__c = true;
        /* as part of STY-01725 */

        leadObject1.PostalCode = '10001';
        leadObject1.NSP_Partner__c =accoutObject.Id;
        leadObject1.NSP_Lead_Stage__c  =null;  
        leadObject1.NSP_Referred_By_COI__c=contactObject.Id;
        leadObject1.NSP_Referral_Source__c='COI';
        leadObject1.OwnerId = userRecord.Id;
        //Adding lead object to the list
        leadList.add(leadObject1);
        
        //Lead Creation
        Lead leadObject2 = new Lead();
        leadObject2.firstname='HelloTest';
        leadObject2.lastname='Employee';
       leadObject2.NSP_Product_Interest__c='Payroll & Human Capital Management(Workforce Acceleration)';
        //leadObject2.NumberOfEmployees =140;
        leadObject2.Company = 'tmp';
        leadObject2.Email = 'tmp@tmp.com';
        leadObject2.PostalCode = '10001';
        leadObject2.NSP_Partner__c =accoutObject.Id;
        leadObject2.NumberOfEmployees  =160;  
      //Adding lead object to the list 
        leadList.add(leadObject2);
        
        // Inserting lead object
        insert leadList;
    }
    
    /**
* Checks the lead stage
* @param N/A. 
* @return void                          
*/
    @isTest
    static void checkLeadStage() {
        //Querying to get get lead with last name as 
        List<Lead>  leadList = [SELECT id,nsp_fire_score__c FROM lead WHERE lastname = 'lead'];
        //Setting the fire score to greater than 80
        leadList[0].nsp_fire_score__c = 82;
        leadList[0].NSP_DC_DateTime__c = System.now();
        leadList[0].PostalCode = '769767';
        leadList[0].Lead_Owner_Auto_Assignment__c = false;
        //leadList[0].Company = 'ALLSTATE';
        leadList[0].NumberOfEmployees = 120;
        Test.startTest();
        //updating the lead record
        update leadList[0];

        system.assert(leadList[0].nsp_fire_score__c == 82,true);
        Test.stopTest();
        
    }
    
    @isTest
    public static void convertLeadTest(){
       
        Lead leadRecord = [SELECT Id, FirstName,OwnerId,NSP_Reason__c,Status, LastName, Email FROM Lead WHERE Email=:LEADCONVERTRECORD_EMAIL LIMIT 1];
        leadRecord.OwnerId=UserInfo.getUserId();
        update leadRecord;
        Task taskRecord = new Task(
            Subject='Discovery Call Task',
            NSP_Task_Type__c='Core Sales',
            NSP_Task_SubType__c='Discovery Call',
            OwnerId=UserInfo.getUserId(),
            WhoId=leadRecord.Id
        );
        
        insert taskRecord;
                
        database.leadConvert lc = new database.leadConvert();
        lc.setLeadId(leadRecord.id);
        Test.startTest();
        leadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());
        
        lc.setOpportunityName('Cole Swain');
        Test.stopTest();
    }
    
    @isTest
    public static void createTasksTest(){
        Test.startTest();
        Lead leadRecord = [SELECT Id, FirstName,OwnerId,LastName, Status, NSP_Reason__c FROM Lead WHERE LastName='Employee' LIMIT 1];
        leadRecord.OwnerId=UserInfo.getUserId();
        leadRecord.Status='Nurturing';
        leadRecord.NSP_Reason__c='Too early, Regen 18 months';
        update leadRecord;
        
        leadRecord.NSP_Reason__c='Too early, Regen 12 months';
        update leadRecord;
        Test.stopTest();
        system.assertEquals(LEADSTATUS, leadRecord.Status);
    }

    /**
* @Description: This test method is used to cover beforeUpdateDirector method for Mid Market Queue for Inbound user
* @Created date: 01/14/2021. 
* @Story : STY-01725
* @return void             
*                
*/
@isTest
public static void inBoundUserTest(){
    Lead leadObject = [SELECT Id, Company,NSP_DC_SetDate__c, NSP_Product_Interest__c,NumberOfEmployees,PostalCode, NSP_DC_SetTime__c,NSP_Assign_Lead__c FROM Lead 
                       WHERE Company = 'FBook'];
    User getUser = [SELECT Id, Name, Email FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
    getUser.UserRoleId = [SELECT Id, Name, DeveloperName FROM UserRole WHERE Name = 'Inbound Manager'][0].Id;
    Database.update(getUser);
    Test.startTest();
    System.runAs(getUser) {
        leadObject.NSP_DC_SetDate__c =  date.today();
        leadObject.NSP_Product_Interest__c = 'Full Service HR (Workforce Optimization)';
        leadObject.NumberOfEmployees =150;
        leadObject.PostalCode = '10001';
        Time myTime = Time.newInstance(1, 2, 3, 0);
        leadObject.NSP_DC_SetTime__c = myTime;
        leadObject.NSP_Assign_Lead__c = true;
        leadObject.Lead_Owner_Auto_Assignment__c = false;
        
        Database.update(leadObject);
        Test.stopTest();
        system.assertEquals(true, leadObject.NSP_Assign_Lead__c);
    }
}


/**
* @Description: This test method is used to cover beforeUpdateDirector method for round robin for Inbound user
* @Created date: 01/14/2021. 
* @Story : STY-01725
* @return void             
*                
*/
@isTest
public static void inBoundUserRoundRoboinTest(){
    Lead leadObject = [SELECT Id, Company,NSP_DC_SetDate__c, NSP_Product_Interest__c,NumberOfEmployees,PostalCode, NSP_DC_SetTime__c,NSP_Assign_Lead__c FROM Lead 
                       WHERE Company = 'FBook'];
    User getUser = [SELECT Id, Name, Email FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
    getUser.UserRoleId = [SELECT Id, Name, DeveloperName FROM UserRole WHERE Name = 'Inbound Manager'][0].Id;
    Database.update(getUser);
    
    System.runAs(getUser) {
        leadObject.NSP_DC_SetDate__c =  date.today();
        leadObject.NSP_Product_Interest__c = 'Full Service HR (Workforce Optimization)';
        leadObject.NumberOfEmployees = 100;
        leadObject.PostalCode = '10001';
        Time myTime = Time.newInstance(1, 2, 3, 0);
        leadObject.NSP_DC_SetTime__c = myTime;
        leadObject.NSP_Assign_Lead__c = true;
        leadObject.Lead_Owner_Auto_Assignment__c = false;
        Test.startTest();
        Database.update(leadObject);
        Test.stopTest();
        system.assertEquals(true, leadObject.NSP_Assign_Lead__c);
        
    }
}


/**
* @Description: This test method is used to cover beforeUpdateDirector method for Patroll HCM for Inbound user
* @Created date: 01/14/2021. 
* @Story : STY-01725
* @return void             
*                
*/
@isTest
public static void inBoundUserPayRollHCMTest(){
    Lead leadObject = [SELECT Id, Company,NSP_DC_SetDate__c, NSP_Product_Interest__c,NumberOfEmployees,PostalCode, NSP_DC_SetTime__c,NSP_Assign_Lead__c FROM Lead 
                       WHERE Company = 'FBook'];
    User getUser = [SELECT Id, Name, Email FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
    getUser.UserRoleId = [SELECT Id, Name, DeveloperName FROM UserRole WHERE Name = 'Inbound Manager'][0].Id;
    Database.update(getUser);
    
    System.runAs(getUser) {
        leadObject.NSP_DC_SetDate__c =  date.today();
        leadObject.NSP_Product_Interest__c = 'Payroll & Human Capital Management(Workforce Acceleration)';
        leadObject.NumberOfEmployees = 150;
        leadObject.PostalCode = '10001';
        Time myTime = Time.newInstance(1, 2, 3, 0);
        leadObject.NSP_DC_SetTime__c = myTime;
        leadObject.NSP_Assign_Lead__c = true;
        leadObject.Lead_Owner_Auto_Assignment__c = false;
        Test.startTest();
        Database.update(leadObject);
        Test.stopTest();
        system.assertEquals(true, leadObject.NSP_Assign_Lead__c);
    }
}



/**
* @Description: This test method is used to cover beforeInsertDirector method for Inbound user
* @Created date: 01/14/2021.
* @Story : STY-01725
* @return void             
*                
*/  
@isTest
public static void inBoundUserBeforeInsertTest(){
    
    User getUser = [SELECT Id, Name, Email FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
    getUser.UserRoleId = [SELECT Id, Name, DeveloperName FROM UserRole WHERE Name = 'Inbound Manager'][0].Id;
    Database.update(getUser);
    
    System.runAs(getUser) {
        Lead ldObj = new Lead();
        ldObj.firstname='mark';
        ldObj.lastname='mark';
        ldObj.NSP_Product_Interest__c='Payroll & Human Capital Management(Workforce Acceleration)';
        ldObj.NumberOfEmployees = 100;
        ldObj.Company = 'mark';
        ldObj.Email = 'mark@gmail.com';
        ldObj.NSP_DC_DateTime__c = System.now();
        ldObj.NSP_DC_SetDate__c =  date.today();
        Time myTime = Time.newInstance(1, 2, 3, 0);
        ldObj.NSP_DC_SetTime__c = myTime;
        ldObj.NSP_Assign_Lead__c = true;
        ldObj.PostalCode = '10001';
        ldObj.NSP_Lead_Stage__c  =null;  
        ldObj.NSP_Referral_Source__c='COI';
        Test.startTest();
        Database.insert(ldObj);
        Test.stopTest();
        system.assertEquals(true, ldObj.NSP_Assign_Lead__c);
    }
}
      
}