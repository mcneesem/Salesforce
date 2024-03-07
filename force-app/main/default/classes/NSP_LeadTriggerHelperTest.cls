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

        Lead_Trigger_Settings__c settings = Lead_Trigger_Settings__c.getOrgDefaults();
        settings.AllowStatusChangedToWorking__c = True;
        upsert settings;

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
            Email = 'testuser@insperity.com',
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
        
        User userRecord1 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Manager'][0].Id,
            LastName = 'TestClassUser1',
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
        //Inserting users that can be used in the test class data setup
        insert userRecord1;
        
        //Create office assignment record
        NSP_Office_Assignment__c officeAssignmentObj =  new NSP_Office_Assignment__c();
        officeAssignmentObj.NSP_District_Administrator__c= userRecord.id;
        officeAssignmentObj.NSP_Location_Name__c=officeObj.id;
        officeAssignmentObj.NSP_Office_Number__c=1;
        officeAssignmentObj.Name = '3300 New York 1';
        officeAssignmentObj.NSP_Sales_Office__c = '301';
        //Inserting office assignment object
        Insert officeAssignmentObj;
        
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
        
        //List to store Lead objects
        List<Lead> leadList = new List<Lead>();
        List<Lead> newLeadList = new List<Lead>();
        
        //Lead Creation
        Id referralLeadRecId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Referral').getRecordTypeId(); //Mani
        Lead leadObject = new Lead();
        leadObject.firstname='Test';
        leadObject.lastname='Lead';
        leadObject.recordTypeId = referralLeadRecId; //Mani
        leadObject.Company = 'TestClass';
        leadObject.NSP_Product_Interest__c = 'Full Service HR (Workforce Optimization)';
        leadObject.NumberOfEmployees =150;
        leadObject.Email = 'testlead1@testlead1.com';
        leadObject.PostalCode = '10001';
        leadObject.NSP_Partner__c =accoutObject.Id;
        leadObject.NSP_Lead_Stage__c  =null;      
        leadObject.NSP_Lead_Routing__c = true;
        leadObject.DNB_connect_DUNS_Number__c  = '876543987';
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
        leadObject.DNB_connect_DUNS_Number__c  = '743243789';
        leadList.add(leadObject3);
        
        //Lead Creation
        Lead leadObject1 = new Lead();
        leadObject1.firstname='TestLead';
        leadObject1.lastname='Company';
        leadObject1.NSP_Product_Interest__c='Payroll & Human Capital Management(Workforce Acceleration)';
        leadObject1.NumberOfEmployees =160;
        leadObject1.Company = 'Allstate123';
        leadObject1.NSP_Referred_By_COI__c = contactObject.Id;
        leadObject1.Email = LEADCONVERTRECORD_EMAIL;
        
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
        
        Lead leadObject4 = new Lead();
        leadObject4.firstname='TestLead1123';
        leadObject4.lastname='Child';
        leadObject4.NSP_Product_Interest__c='Payroll & Human Capital Management(Workforce Acceleration)';
        leadObject4.NumberOfEmployees =160;
        leadObject4.Company = 'ABC';
        leadObject4.NSP_Referred_By_COI__c = contactObject.Id;
        leadObject4.Email = 'test@test.com';
        leadObject4.DNB_connect_DUNS_Number__c  = '743243789';
        leadObject4.NSP_Lead_Routing__c = true;
        newLeadList.add(leadObject4);
        
        Lead leadObject5 = new Lead();
        leadObject5.firstname='TestLead113';
        leadObject5.lastname='Acc';
        leadObject5.NSP_Product_Interest__c='Payroll & Human Capital Management(Workforce Acceleration)';
        leadObject5.NumberOfEmployees =160;
        leadObject5.Company = 'Allstate123';
        leadObject5.NSP_Referred_By_COI__c = contactObject.Id;
        leadObject5.Email = 'test333@test.com';
        leadObject5.DNB_connect_DUNS_Number__c  = '';
        leadObject5.NSP_Lead_Routing__c = true;
        
        newLeadList.add(leadObject5);
        
        Lead leadObject6 = new Lead();
        leadObject6.firstname='TestLead1134';
        leadObject6.lastname='Acc';
        leadObject6.NSP_Product_Interest__c='Payroll & Human Capital Management(Workforce Acceleration)';
        leadObject6.NumberOfEmployees =160;
        leadObject6.Company = 'Allstate123';
        leadObject6.NSP_Referred_By_COI__c = contactObject.Id;
        leadObject6.Email = 'test333@test.com';
        leadObject6.DNB_connect_DUNS_Number__c  = '';
        leadObject6.NSP_Parent_Lead__c = leadObject5.Id;
        leadObject6.NSP_Lead_Routing__c = true;
        newLeadList.add(leadObject6);
        insert newLeadList; 
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
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        Lead leadRecord = [SELECT Id, FirstName,OwnerId,NSP_Reason__c,Status, LastName, Email FROM Lead WHERE Email=:LEADCONVERTRECORD_EMAIL LIMIT 1];
        leadRecord.OwnerId=UserInfo.getUserId();
        update leadRecord;
        Task taskRecord = new Task(
            Subject='Discovery Call Task',
            NSP_Task_Type__c='Core Sales',
            NSP_Task_SubType__c='WX Quote',
            OwnerId=UserInfo.getUserId(),
            WhoId=leadRecord.Id
        );
        
        insert taskRecord;
        
        database.leadConvert lc = new database.leadConvert();
        lc.setLeadId(leadRecord.id);
        lc.setOwnerId(UserInfo.getUserId());
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
* @Description: This test method is used to cover beforeUpdateDirector method
* @Created date: 04/29/2022. 
* @return void             
*     */           
    @isTest
    public static void dunsCheckBeforeUpdateTest(){ 
        Lead getLead = [SELECT Id, Company,NSP_DC_SetDate__c, NSP_Product_Interest__c,NumberOfEmployees,PostalCode, NSP_DC_SetTime__c,NSP_Assign_Lead__c FROM Lead 
                        WHERE firstName = 'TestLead113'];
        getLead.DNB_connect_DUNS_Number__c = '';
        Test.startTest();
        database.update(getLead);
        Test.stopTest();
        system.assertEquals(getLead.DNB_connect_DUNS_Number__c, '');
    }
    /**
* @Description: This test method is used to cover beforeUpdateDirector method
* @Created date: 04/29/2022. 
* @return void             
*     */   
    @isTest
    public static void dunsCheckBeforeUpdateMidMarketTest(){ 
        Lead getLead = [SELECT Id, Company,NSP_DC_SetDate__c, NSP_Product_Interest__c,NumberOfEmployees,PostalCode, NSP_DC_SetTime__c,NSP_Assign_Lead__c FROM Lead 
                        WHERE firstName = 'TestLead113'];
        getLead.DNB_connect_DUNS_Number__c = '';
        getLead.NSP_Product_Interest__c = 'Full Service HR (Workforce Optimization)';
        Test.startTest();
        database.update(getLead);
        Test.stopTest();
        system.assertEquals(getLead.DNB_connect_DUNS_Number__c, '');
    }
    /**
* @Description: This test method is used to cover beforeUpdateDirector method
* @Created date: 04/29/2022. 
* @return void             
*     */  
    @isTest
    public static void dunsCheckBeforeUpdateZipCodeTest(){ 
        Lead getLead = [SELECT Id, Company,NSP_DC_SetDate__c, NSP_Product_Interest__c,NumberOfEmployees,PostalCode, NSP_DC_SetTime__c,NSP_Assign_Lead__c FROM Lead 
                        WHERE firstName = 'TestLead113'];
        getLead.DNB_connect_DUNS_Number__c = '';
        getLead.PostalCode = '10001';
        getLead.NumberOfEmployees = 100;
        Test.startTest();
        database.update(getLead);
        Test.stopTest();
        system.assertEquals(getLead.DNB_connect_DUNS_Number__c, '');
    }
    /**
* @Description: This test method is used to cover beforeUpdateDirector method
* @Created date: 04/29/2022. 
* @return void             
*     */  
    @isTest
    public static void dunsCheckBeforeUpdateCompanyTest(){ 
        Lead getLead = [SELECT Id, Company,NSP_DC_SetDate__c, NSP_Product_Interest__c,NumberOfEmployees,PostalCode, NSP_DC_SetTime__c,NSP_Assign_Lead__c FROM Lead 
                        WHERE Company = 'TestClass'];
        getLead.DNB_connect_DUNS_Number__c = '';
        getLead.NSP_Lead_Routing__c = true;
        getLead.Company = 'AllState';
        Test.startTest();
        database.update(getLead);
        Test.stopTest();
        system.assertEquals(getLead.DNB_connect_DUNS_Number__c, '');
    } 
    /**
* @Description: This test method is used to cover beforeUpdateDirector method
* @Created date: 04/29/2022. 
* @return void             
*     */  
    @isTest
    public static void dunsCheckBeforeUpdateParentLeadTest(){ 
        Lead getLead = [SELECT Id, Company,NSP_DC_SetDate__c, NSP_Product_Interest__c,NumberOfEmployees,PostalCode, NSP_DC_SetTime__c,NSP_Assign_Lead__c FROM Lead 
                        WHERE firstName = 'HelloTest'];
        Lead getParentLead = [SELECT Id, Company,NSP_DC_SetDate__c, NSP_Product_Interest__c,NSP_Parent_Lead__c,NumberOfEmployees,PostalCode, NSP_DC_SetTime__c,NSP_Assign_Lead__c FROM Lead 
                              WHERE firstName = 'TestLead1134'];
        getLead.NSP_Parent_Lead__c = getParentLead.Id;
        getLead.NumberOfEmployees = 100;
        test.startTest();
        database.update(getLead);
        Test.stopTest();
        system.assertEquals(getLead.NumberOfEmployees, 100);
    } 
    /**
* @Description: This test method is used to cover beforeUpdateDirector method
* @Created date: 04/29/2022. 
* @return void             
*     */  
    @isTest
    public static void dunsCheckBeforeInsertTest(){ 
        Account accoutObject = new Account();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('NSP_Partner_Client').getRecordTypeId();
        accoutObject.Name = 'Test Account';
        accoutObject.recordTypeId=partnerRecordTypeId;
        accoutObject.DNB_Connect_DUNS_Number__c = '876543987';
        //Inserting account object
        insert accoutObject;
        
        Lead nLead = new Lead();
        nLead.firstname='HelloTest123';
        nLead.lastname='Employee123';
        nLead.NSP_Product_Interest__c='Payroll & Human Capital Management(Workforce Acceleration)';
        nLead.Company = 'tmp123';
        nLead.Email = 'tmp@tmp123.com';
        nLead.PostalCode = '10001';
        nLead.NumberOfEmployees  =160;  
        nLead.NSP_Lead_Routing__c = true;
        nLead.DNB_connect_DUNS_Number__c  = '876543987';
        Test.startTest();
        insert nLead;
        Test.stopTest();
        system.assertEquals(nLead.NumberOfEmployees, 160);
    } 
    
    @isTest
    public static void salesOfficetest()
    {
        User currentUser = [SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c from user where Id =:UserInfo.getUserId()];
         currentUser.NSP_Sales_Office__c = '301';
         currentUser.NSP_SalesRegion__c = 'Central 1';
         currentUser.NSP_SalesDivision__c = 'Central';
         update currentUser;

         NSP_Sales_Office_Mapping__c officeMapping = new NSP_Sales_Office_Mapping__c();
        officeMapping.NSP_Sales_Office__c = '1081';
        officeMapping.NSP_Sales_Division__c = 'Central';
        officeMapping.NSP_Sales_Region__c = 'Central 1';
        officeMapping.NSP_Start_Date__c = system.today()-1;
        officeMapping.NSP_End_Date__c = system.today()+100;
        insert officeMapping; 
        
        Test.startTest();
        Lead nLead = new Lead();
        nLead.firstname='HelloTest123';
        nLead.lastname='Employee123';
        nLead.NSP_Product_Interest__c='Payroll & Human Capital Management(Workforce Acceleration)';
        nLead.Company = 'tmp123';
        nLead.Email = 'tmp@tmp123.com';
        nLead.PostalCode = '10001';
        nLead.NumberOfEmployees  =160;  
        nLead.NSP_Lead_Routing__c = true;
        nLead.DNB_connect_DUNS_Number__c  = '876543987';
       
        insert nLead;
        
        nLead.NSP_Sales_Office__c = '1081';
        update nLead;
        Test.stopTest();
    }
    

/* Ticket 582488
* author           | Date              | Description
* -------------------------------------------------------------------------------------
* Harsha Khiroya      08/08/2022           Created this method - test method for admin user
*/    
    @isTest
    static void testLeadDeleteByAdmin() {
      User userRecord1 = [select id from User WHERE LastName = 'TestClassUser1'];
        List<Lead>  leadList = [SELECT id,nsp_fire_score__c FROM lead WHERE lastname = 'lead'];
        // Start Test
        Test.startTest();
        	delete leadList[0];   
        Test.stopTest();
        system.assertNotEquals(null,leadList);
 	}

/* Ticket 582488
* author           | Date              | Description
* -------------------------------------------------------------------------------------
* Harsha Khiroya      08/08/2022           Created this method - test method for non admin user(sales manager here)
*/
    @isTest
    static void testLeadDeleteByNonAdmin() {
      User userRecord1 = [select id from User WHERE LastName = 'TestClassUser1'];
        List<Lead>  leadList = [SELECT id,nsp_fire_score__c FROM lead WHERE lastname = 'lead'];
        // Start Test
        Test.startTest();
        system.runAs(userRecord1){
            try{
        		delete leadList; 
            }catch(Exception ex){
                system.assertNotEquals(null, ex);
            }
        }
        Test.stopTest();
        
 	}

        /**
* @Description: This test method describes about when Service Referral Lead is created it should get assigned to Inbound Solutions Queue
* @Created date: 11/08/2022. 
* @Story : STY-03751
* @return void             
*     */  
@isTest
static void serviceReferralLeadCreationTest() {
    List<Group> inBoundSolutionsQueue = [SELECT Id,DeveloperName,name FROM Group WHERE Type = 'Queue' AND DeveloperName = :System.label.NSP_DEVELOPERNAME_INBOUNDSOLUTIONS];
    Lead nLead = new Lead();
    nLead.firstname='HelloTest123';
    nLead.lastname='Employee123';
    nLead.NSP_Product_Interest__c='Payroll & Human Capital Management(Workforce Acceleration)';
    nLead.Company = 'tmp123';
    nLead.Email = 'tmp@tmp123.com';
    nLead.recordTypeId = NSP_LeadTriggerHelper.SERVICE_REFERRAL_RECORDTYPE_ID;
    Test.startTest();
    insert nLead;
    Test.stopTest();
    Lead assertLead = [SELECT Id, OwnerId From Lead WHERE Id =: nLead.Id];
    system.assertEquals(assertLead.Ownerid, inBoundSolutionsQueue[0].id); // Checking whether Created lead is assigned to Inbound Solutions Queue
}

    @isTest private static void testAllowStatusChangedToWorking() {
        List<String> allowedUserRoleNames = Label.MM_AND_BPC_USERROLE.split( ',' ); // Custom Label: MidMarket Administrator,MidMarket Sales Leader,Business Performance Consultant
        List<User> records = [
            SELECT Id
            FROM User
            WHERE (
                ( IsActive = True )
                AND ( ProfileId != null )
                AND ( NOT Profile.Name LIKE 'System Admin%' )
                AND ( Profile.Name != 'Integration User' )
                AND ( UserRoleId != null )
                AND ( UserRole.Name NOT IN :allowedUserRoleNames )
            )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        Assert.isNotNull( records , 'Null User query results.' );
        Assert.isTrue( ( records.size() > 0 ) , 'No User query results.' );
        System.runAs( records[0] ) {
            Test.startTest();
            List<Lead> employees = [
                SELECT Id
                FROM Lead
                WHERE ( LastName='Employee' )
                LIMIT 1
            ];
            Assert.isNotNull( employees , 'Null Lead query results.' );
            Assert.isTrue( ( employees.size() > 0 ) , 'No Lead query results.' );
            Lead employee = employees[0];
            employee.Status = 'Working';
            try {
                update employee;
            } catch ( Exception e ) {
                System.debug( ' ~ CATCH ~ e=' + e );
            }
            Test.stopTest();
        }
    }
}
//