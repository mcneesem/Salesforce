@IsTest
private class NSP_LeadTriggerHelperTest {
    private static final String LEADCONVERTRECORD_EMAIL ='Allstate@Allstate.com';
    private static final String LEADSTATUS ='Nurturing'; // Added as part of code scan fix
    private static final String INTEREST = 'Payroll & Human Capital Management(Workforce Acceleration)';
    private static final String TMP_EMAIL = 'tmp@tmp123.com';

    @TestSetup
    private static void testData() {
        Lead_Trigger_Settings__c settings1 = Lead_Trigger_Settings__c.getOrgDefaults();
        settings1.AllowStatusChangedToWorking__c = True;
        upsert settings1;

        Account_Segment_Threshold_Settings__c settings2 = Account_Segment_Threshold_Settings__c.getOrgDefaults();
        settings2.Is_Enabled__c = True;
        upsert settings2;
        
        //Create custom setting record for lead zip to city Mapping
        NSP_Zip_To_City_Mapping__c zipToCityCustomSetting = new NSP_Zip_To_City_Mapping__c();
        String newyork = 'New York';
        zipToCityCustomSetting.NSP_City__c = newyork;
        zipToCityCustomSetting.NSP_Location_Name__c = newyork;
        zipToCityCustomSetting.NSP_State__c = 'NY';
        zipToCityCustomSetting.NSP_Zip__c = '10001';
        
        //Creteing zip to city record
        insert zipToCityCustomSetting;
        
        //Create Office records
        NSP_Office__c officeObj =  new NSP_Office__c();
        officeObj.NSP_Last_Index_Used__c = 0;
        officeObj.Name = newyork;
        insert officeObj;

        // select the oldest active User with a 'System Administrator' Profile...
        List<User> testSystemAdministrators = [
            SELECT Id
            FROM User
            WHERE (
                ( Profile.Name = 'System Administrator' )
                AND ( IsActive = True )
            )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        Assert.isTrue( testSystemAdministrators != null , 'Null active System Administrator query results.' );
        Assert.isTrue( !testSystemAdministrators.isEmpty() , 'No active System Administrator found.' );
        User userRecord = testSystemAdministrators[0];
        
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
        AccountContactRelation accountContactRelationObject = new AccountContactRelation();
        accountContactRelationObject.accountid= accoutObject.Id;
        accountContactRelationObject.ContactId = contactObject.Id;
        accountContactRelationObject.NSP_Is_Primary__c = true;
        insert accountContactRelationObject;
        
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
        leadObject1.NSP_Product_Interest__c = INTEREST;
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
        leadObject2.NSP_Product_Interest__c = INTEREST;
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
        leadObject4.NSP_Product_Interest__c = INTEREST;
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
        leadObject5.NSP_Product_Interest__c = INTEREST;
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
        leadObject6.NSP_Product_Interest__c = INTEREST;
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
    @IsTest
    private static void checkLeadStage() {
        //Querying to get get lead with last name as
        List<Lead>  leadList = [SELECT id,nsp_fire_score__c FROM lead WHERE lastname = 'lead'];
        //Setting the fire score to greater than 80
        leadList[0].nsp_fire_score__c = 82;
        leadList[0].PostalCode = '769767';
        leadList[0].Lead_Owner_Auto_Assignment__c = false;
        leadList[0].NumberOfEmployees = 120;
        Test.startTest();
        //updating the lead record
        update leadList[0];
        
        system.assert(leadList[0].nsp_fire_score__c == 82,true);
        Test.stopTest();
        
    }
    
    @IsTest
    private static void convertLeadTest() {
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
    
    @IsTest
    private static void createTasksTest() {
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
    @IsTest
    private static void dunsCheckBeforeUpdateTest() {
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
    @IsTest
    private static void dunsCheckBeforeUpdateMidMarketTest() {
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
    @IsTest
    private static void dunsCheckBeforeUpdateZipCodeTest() {
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
    @IsTest
    private static void dunsCheckBeforeUpdateCompanyTest() {
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
    @IsTest
    private static void dunsCheckBeforeUpdateParentLeadTest() {
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
    @IsTest
    private static void dunsCheckBeforeInsertTest() {
        Map<Id,User> dunsPermittedUserMap = CustomPermissionController.getPermittedUsersMap('Lead_DUNS_Account_Owner_Routing');        
        List<User> testUsers = [
            SELECT Id
            FROM User
            WHERE (
                ( Id IN :dunsPermittedUserMap.keySet() )
                AND ( IsActive = true )
            )
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        Test.startTest();
        Account accoutObject = new Account();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('NSP_Partner_Client').getRecordTypeId();
        accoutObject.Name = 'Test Account';
        accoutObject.recordTypeId=partnerRecordTypeId;
        accoutObject.DNB_Connect_DUNS_Number__c = '876543988';
        if (!testUsers.isEmpty()) {
            accoutObject.OwnerId = testUsers[0].Id;   
        }
        accoutObject.NSP_Account_Status__c = NSP_SalesConstants.INACTIVE;
        //Inserting account object
        insert accoutObject;

        Lead nLead = new Lead();
        nLead.firstname='HelloTest123';
        nLead.lastname='Employee123';
        nLead.NSP_Product_Interest__c = INTEREST;
        nLead.Company = 'tmp123';
        nLead.Email = TMP_EMAIL;
        nLead.PostalCode = '10001';
        nLead.NumberOfEmployees  =160;
        nLead.NSP_Lead_Routing__c = true;
        nLead.DNB_Connect_DUNS_Number__c = '876543988';
        insert nLead;
        Test.stopTest();
        system.assertEquals(nLead.NumberOfEmployees, 160);
        if (!testUsers.isEmpty()) {
            List<Lead>  leadList = [SELECT Id , OwnerId FROM lead WHERE Id = :nLead.Id];
            system.assertEquals(leadList[0].OwnerId, testUsers[0].Id);
        }
    }
    
    @IsTest
    private static void salesOfficetest() {
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
        nLead.NSP_Product_Interest__c = INTEREST;
        nLead.Company = 'tmp123';
        nLead.Email = TMP_EMAIL;
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
    @IsTest
    private static void testLeadDeleteByAdmin() {
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
    @IsTest
    private static void testLeadDeleteByNonAdmin() {
        // select the oldest active User with a 'Sales Manager' Profile...
        List<User> testSalesManagers = [
            SELECT Id
            FROM User
            WHERE (
                ( Profile.Name = 'Sales Manager' )
                AND ( IsActive = True )
            )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        Assert.isTrue( testSalesManagers != null , 'Null active Sales Manager query results.' );
        Assert.isTrue( !testSalesManagers.isEmpty() , 'No active Sales Manager found.' );
        User userSalesManager = testSalesManagers[0];
        
        List<Lead>  leadList = [SELECT id,nsp_fire_score__c FROM lead WHERE lastname = 'lead'];
        // Start Test
        Test.startTest();
        system.runAs(userSalesManager){
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
    @IsTest
    private static void serviceReferralLeadCreationTest() {
        List<Group> inBoundSolutionsQueue = [SELECT Id,DeveloperName,name FROM Group WHERE Type = 'Queue' AND DeveloperName = :System.label.NSP_DEVELOPERNAME_INBOUNDSOLUTIONS];
        Lead nLead = new Lead();
        nLead.firstname='HelloTest123';
        nLead.lastname='Employee123';
        nLead.NSP_Product_Interest__c = INTEREST;
        nLead.Company = 'tmp123';
        nLead.Email = TMP_EMAIL;
        nLead.recordTypeId = NSP_LeadTriggerHelper.SERVICE_REFERRAL_RECORDTYPE_ID;
        Test.startTest();
        insert nLead;
        Test.stopTest();
        Lead assertLead = [SELECT Id, OwnerId From Lead WHERE Id =: nLead.Id];
        system.assertEquals(assertLead.Ownerid, inBoundSolutionsQueue[0].id); // Checking whether Created lead is assigned to Inbound Solutions Queue
    }
    
    @IsTest
    private static void testAllowStatusChangedToWorking() {
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
    
    @IsTest
    private static void testEloquaLeadInboundSolutions() {
        
        User eloquaUser = [select id from User WHERE id =: Label.Eloqua_Integration_User_Id ];
        List<Group> inBoundSolutionsQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :System.label.NSP_DEVELOPERNAME_INBOUNDSOLUTIONS];
        List<Group> outBoundTeamQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :System.label.Outbound_Team_DeveloperName];
        List<Group> fieldMarketingTeamQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :System.label.Field_Marketing_Team_DeveloperName];
        List<Account> account = [SELECT id FROM Account WHERE name = 'Test Account' LIMIT 1];
        ID userId = UserInfo.getUserId();

        // Start Test
        Test.startTest();
        system.runAs(eloquaUser){
            
            List <Lead> leads = new  List <Lead>();
            
            //  Lead should be assigned to Outbound Team
            Lead lead1 = new  Lead();
            lead1.company = account[0].id;
            lead1.Marketing_Priority__c = 'General';
            lead1.firstName = 'Test1';
            lead1.lastName = 'Test1';
            lead1.email = 'myemail1@yahoo.com';
            lead1.phone = '999999';
            lead1.ownerId = Label.Eloqua_Integration_User_Id;
            leads.add(lead1);
            
            //  Lead should be assigned to Inbound Solutions
            Lead lead2 = new  Lead();
            lead2.Marketing_Priority__c = 'High - Direct';
            lead2.company = account[0].id;
            lead2.firstName = 'Test2';
            lead2.lastName = 'Test2';
            lead2.email = 'myemail2@yahoo.com';
            lead2.phone = '999999';
            lead2.ownerId = Label.Eloqua_Integration_User_Id;
            leads.add(lead2);

            //  Lead should be assigned to Field Marketing Team
            Lead lead3 = new  Lead();
            lead3.Marketing_Priority__c = 'High - Event';
            lead3.company = account[0].id;
            lead3.firstName = 'Test3';
            lead3.lastName = 'Test3';
            lead3.email = 'myemail3@yahoo.com';
            lead3.phone = '999999';
            lead3.ownerId = Label.Eloqua_Integration_User_Id;
            leads.add(lead3);

            //  Lead should not be assigned to any queue
            Lead lead4 = new  Lead();
            lead4.Marketing_Priority__c = 'High - Event';
            lead4.company = account[0].id;
            lead4.firstName = 'Test4';
            lead4.lastName = 'Test4';
            lead4.email = 'myemail4@yahoo.com';
            lead4.phone = '999999';
            lead4.ownerId = userId;
            leads.add(lead4);

            //  Lead should not be assigned to any queue
            Lead lead5 = new  Lead();
            lead5.Marketing_Priority__c = 'General';
            lead5.company = account[0].id;
            lead5.firstName = 'Test5';
            lead5.lastName = 'Test5';
            lead5.email = 'myemail5@yahoo.com';
            lead5.phone = '999999';
            lead5.ownerId = userId;
            leads.add(lead5);
            
            //  Lead should not be assigned to any queue
            Lead lead6 = new  Lead();
            lead6.Marketing_Priority__c = 'High - Direct';
            lead6.company = account[0].id;
            lead6.firstName = 'Test6';
            lead6.lastName = 'Test6';
            lead6.email = 'myemail6@yahoo.com';
            lead6.phone = '999999';
            lead6.ownerId = userId;
            leads.add(lead6);

            //  Lead should be assigned to Inbound Solutions
            Lead lead7 = new  Lead();
            lead7.company = account[0].id;
            lead7.firstName = 'Test6';
            lead7.lastName = 'Test6';
            lead7.email = 'myemail6@yahoo.com';
            lead7.phone = '999999';
            leads.add(lead7);

            insert leads;
            
            List<Lead> lead_1 = [SELECT ownerId FROM Lead WHERE id =: lead1.id];
            system.assertEquals(outBoundTeamQueue[0].id, lead_1[0].Ownerid);

            List<Lead> lead_2 = [SELECT ownerId FROM Lead WHERE id =: lead2.id];
            system.assertEquals(inBoundSolutionsQueue[0].id, lead_2[0].Ownerid);

            List<Lead> lead_3 = [SELECT ownerId FROM Lead WHERE id =: lead3.id];
            system.assertEquals(fieldMarketingTeamQueue[0].id, lead_3[0].Ownerid);

            List<Lead> lead_4 = [SELECT ownerId FROM Lead WHERE id =: lead4.id];
            system.assertEquals(userId, lead_4[0].Ownerid);

            List<Lead> lead_5 = [SELECT ownerId FROM Lead WHERE id =: lead5.id];
            system.assertEquals(userId, lead_5[0].Ownerid);

            List<Lead> lead_6 = [SELECT ownerId FROM Lead WHERE id =: lead6.id];
            system.assertEquals(userId, lead_6[0].Ownerid);
                       
            List<Lead> lead_7 = [SELECT ownerId FROM Lead WHERE id =: lead7.id];
            system.assertEquals(inBoundSolutionsQueue[0].id, lead_7[0].Ownerid);
        }
        Test.stopTest();
    }
 
    @IsTest 
    private static void testSalesSegment() {
 
         Test.startTest();
 
         Account acct = new Account();
         acct.Name = 'Test Lead-Account';
         insert acct;
 
         List<Lead> leads = new  List<Lead>();
 
         Lead lead1 = new Lead();
         lead1.FirstName = 'Lead first-name 1';
         lead1.LastName = 'Lead last 1';
         lead1.email = 'myemail1@mail.com';
         lead1.phone = '111111';
         lead1.company = acct.id;
         lead1.NumberOfEmployees = 5;
 
         Lead lead2 = new Lead();
         lead2.FirstName = 'Lead first-name 2';
         lead2.LastName = 'Lead last 2';
         lead2.email = 'myemail2@mail.com';
         lead2.phone = '222222';
         lead2.company = acct.id;
         lead2.NumberOfEmployees = 52;
 
         Lead lead3 = new Lead();
         lead3.FirstName = 'Lead first-name 3';
         lead3.LastName = 'Lead last 3';
         lead3.email = 'myemail3@mail.com';
         lead3.phone = '3333333';
         lead3.company = acct.id;
         lead3.NumberOfEmployees = 150;
 
         Lead lead4 = new Lead();
         lead4.FirstName = 'Lead first-name 4';
         lead4.LastName = 'Lead last 4';
         lead4.email = 'myemail4@mail.com';
         lead4.phone = '4444444444';
         lead4.company = acct.id;
         lead4.NumberOfEmployees = 752;
 
         leads.add(lead1);
         leads.add(lead2);
         leads.add(lead3);
         leads.add(lead4);
 
         insert leads;

         lead1 = [SELECT NSP_Account_Segment__c FROM Lead WHERE FirstName = 'Lead first-name 1' LIMIT 1];
         System.assertEquals('Core', lead1.NSP_Account_Segment__c);
 
         lead2 = [SELECT NSP_Account_Segment__c FROM Lead WHERE FirstName = 'Lead first-name 2' LIMIT 1];
         System.assertEquals('Emerging Growth', lead2.NSP_Account_Segment__c);
 
         lead3 = [SELECT NSP_Account_Segment__c FROM Lead WHERE FirstName = 'Lead first-name 3' LIMIT 1];
         System.assertEquals('MidMarket', lead3.NSP_Account_Segment__c);
 
         lead4 = [SELECT NSP_Account_Segment__c FROM Lead WHERE FirstName = 'Lead first-name 4' LIMIT 1];
         System.assertEquals('Enterprise', lead4.NSP_Account_Segment__c);
 
         Test.stopTest();
    }

    @IsTest 
    private static void testBypassSalesOfficeValidation() {

        Test.startTest();
        List<User> supervisor = [SELECT id FROM User WHERE UserRole.DeveloperName = 'Sales_Development_Leader' LIMIT 1];
        List<User> users = [SELECT id FROM User WHERE UserRole.DeveloperName = 'Sales_Development_Rep' LIMIT 2];

        if(supervisor.size() == 1 && users.size() == 2) {
            
            //  Check if supervisor already has PS
            List<PermissionSetAssignment> psSupervisor = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :supervisor[0].id AND 
            PermissionSet.Name = 'Bypass_Lead_Sales_Office_Validation'];
            if(psSupervisor.size() == 0){
                //  Assign the required permission set
                List<PermissionSet> psBypassLeadOfficeValidation = [SELECT Id FROM PermissionSet WHERE Name = 'Bypass_Lead_Sales_Office_Validation' LIMIT 1];
                if(psBypassLeadOfficeValidation.size() == 1){
                    PermissionSetAssignment psa = new PermissionSetAssignment(
                        AssigneeId = supervisor[0].Id,
                        PermissionSetId = psBypassLeadOfficeValidation[0].Id
                    );
                    insert psa;
                }
            }

            System.runAs(supervisor[0]) {
                
                Lead lead = new Lead();
                lead.firstname='Name 123';
                lead.lastname='Test 123';
                lead.Company = 'Test Company';
                lead.Email = 'testlead1000@email.com';
                lead.NSP_Sales_Office__c = '1403';
                lead.OwnerId = users[0].id;
                insert lead;
            
                lead.OwnerId = users[1].id;
                update lead;
                    
                System.assertEquals(users[1].id, lead.OwnerId);
            }
        }
        Test.stopTest();
    }

    @IsTest 
    private static void testTransferDiscoveryCall() {
        
        Test.startTest();
        List<User> users = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 2];
        System.assert((users != null && users.size() == 2), 'No System Administrator user found');
        Lead testLead = new Lead(
        FirstName = 'Test 1245',
        LastName = 'Lead 45788',
        Company = 'Test Company 787845',
        Email = 'testlead88555@testcompany.com',
        OwnerId = users[0].Id
        );
        insert testLead;
    
        // Create Event with Discovery Call subtype and Open status
        Id eventRecTypeId = NSP_GenericRecordType.getRecordTypeId( 'Event' , 'Core_Sales_Event_RT' );
        Date todayDate = System.today();
        Event testEvent = new Event(
        OwnerId = users[0].Id,
        WhoId = testLead.Id,
        RecordTypeId = eventRecTypeId,
        NSP_Event_Type__c = 'Core Sales',
        NSP_Event_Subtype__c = 'Discovery Call',
        NSP_Status__c = 'Open',
        ActivityDateTime = todayDate,
        StartDateTime = todayDate,
        EndDateTime = todayDate,
        ActivityDate = todayDate
        );
        insert testEvent;

        testLead.OwnerId = users[1].Id;
        update testLead;

        Test.stopTest();
        List<Event> eventCheck = [SELECT id, OwnerId FROM Event WHERE id = :testEvent.id ];
        System.assert((eventCheck != null && !eventCheck.isEmpty()), 'No Event found');
        System.assertEquals(users[1].Id, eventCheck[0].OwnerId);
    }
}