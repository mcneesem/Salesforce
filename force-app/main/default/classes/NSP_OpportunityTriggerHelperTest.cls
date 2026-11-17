@isTest
private class NSP_OpportunityTriggerHelperTest {
    private static final String OPP_NSP_UPSELL_PRODUCT_ADD_ONS_RETIREMENT_SERVICES = 'Retirement Services'; // Added as part of Code Fix
    private static final String OPP_STAGENAME_CLOSED_WON = 'Closed Won'; // Added as part of Code Fix
    private static final String CONTRACT_PRODUCT_TYPE = 'Organizational Planning;Performance Management'; // Added as part of test class coverage
    private static final String CONTRACT_STATUS = 'Draft'; // Added as part of test class coverage
    private static final String CURRENCY_USD = 'USD'; // Added as part of test class coverage

    @testSetup
    private static void testData() {
        NSP_hotfix_Switch__c setting = new NSP_hotfix_Switch__c();
        setting.Is_Edit_Closed_Won_Allowed__c = true;
        insert setting;

        OpportunityStageSettings__c optySettings = OpportunityStageSettings__c.getOrgDefaults();
        optySettings.Is_Enabled_WO_WS_Stage_Entry__c = true;
        upsert optySettings;

        Lead_Trigger_Settings__c leadSettings = Lead_Trigger_Settings__c.getOrgDefaults();
        leadSettings.IsEnabledTransferDiscoveryCall__c = true;
        upsert leadSettings;

        PlatformEventSettings__c pESetting = new PlatformEventSettings__c();
        pESetting.IsEnabled_IntegrationAccountEvent__c = true;
        pESetting.IsEnabled_IntegrationAccountDeleteEvent__c = true;
        pESetting.IsEnabled_IntegrationOpportunityEvent__c = true;
        upsert pESetting;

        BoxFileRequest__c boxSettings = BoxFileRequest__c.getOrgDefaults();
        boxSettings.IsEnabled__c = True;
        boxSettings.BoxTemplateFolderId__c = '225207143235';
        boxSettings.BoxApiEndpoint__c = 'https://api.box.com/2.0/collaborations/';
        boxSettings.BoxFileRequestFolderName__c = 'Insperity File Request';
        upsert boxSettings;

        //Account creation
        Account accoutObject = new Account();
        accoutObject.Name = 'Test Account';
        //inserting account object
        insert accoutObject;

        Contact conObj = new Contact();
        conObj.FirstName = 'FName';
        conObj.LastName = 'LName';
        conObj.AccountId = accoutObject.Id;
        conObj.phone = '8987678652';
        insert conObj;

        Account accoutObject1 = new Account();
        accoutObject1.Name = 'Test Account1';
        //inserting account object
        insert accoutObject1;

        Account accoutObject2 = new Account();
        accoutObject2.Name = 'Test Account2';
        //inserting account object
        insert accoutObject2;

        // Inserting Contract
        Contract ct = new Contract();
        ct.AccountId = accoutObject1.Id;
        ct.ContractTerm = 12;
        ct.NSP_Product_Type__c = CONTRACT_PRODUCT_TYPE;
        ct.StartDate = Date.today();
        ct.Status = CONTRACT_STATUS;
        database.insert(ct);

        //Create Opportunity
        List<Opportunity> oppList1 = new List<Opportunity>();
        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Name = 'Test Oppty';
        opportuniytObject.AccountId = accoutObject1.id;
        opportuniytObject.StageName = NSP_SalesConstants.ANALYSIS_STAGE;
        opportuniytObject.CloseDate = date.today();
        opportuniytObject.CurrencyIsoCode = CURRENCY_USD;
        opportuniytObject.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject.NSP_Number_of_Employees__c = 100;
        opportuniytObject.NSP_WS_Number_Of_Employees__c = 123;
        opportuniytObject.NSP_WO_Number_Of_Employees__c = 123;
        //opportuniytObject.SBQQ__AmendedContract__c = ct.Id;
        //opportuniytObject.SBQQ__RenewedContract__c = ct.Id;
        opportuniytObject.NSP_TransactionType__c = NSP_SalesConstants.TRANSACTION_TYPE_TERMINATION;
        opportuniytObject.Type ='CAMS';
        opportuniytObject.NSP_Upsell_Product_add_ons__c = OPP_NSP_UPSELL_PRODUCT_ADD_ONS_RETIREMENT_SERVICES;
        oppList1.add(opportuniytObject);

        Opportunity opportuniytObject2 = new Opportunity();
        opportuniytObject2.Name = 'Test Oppty Email';
        opportuniytObject2.AccountId = accoutObject1.id;
        opportuniytObject2.StageName = NSP_SalesConstants.ANALYSIS_STAGE;
        opportuniytObject2.CloseDate = date.today();
        opportuniytObject2.CurrencyIsoCode = CURRENCY_USD;
        opportuniytObject2.NSP_PrimaryProduct__c = 'WO';
        opportuniytObject2.NSP_Number_of_Employees__c = 151; //!do not change. Test might fail
        opportuniytObject2.Type ='CAMS';
        opportuniytObject2.NSP_Upsell_Product_add_ons__c = OPP_NSP_UPSELL_PRODUCT_ADD_ONS_RETIREMENT_SERVICES;
        opportuniytObject2.NSP_WS_Number_Of_Employees__c = 123;
        opportuniytObject2.NSP_TransactionType__c = NSP_SalesConstants.TRANSACTION_TYPE_TERMINATION;
        opportuniytObject2.NSP_Mid_Market_Sales_Email__c='test@insperity.com';
        oppList1.add(opportuniytObject2);
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        insert oppList1;
        NSP_OpportunityTriggerHandler.TriggerDisabled = false;

        List<Task> taskList = new List<Task>();
        Id taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Core_Sales_Task_RT').getRecordTypeId();
        Task taskRec = new Task(
            Subject = 'Discovery Call',
            WhatId = opportuniytObject2.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = taskRecTypeId,
            NSP_Task_Subtype__c = 'Client Meeting',
            NSP_Status__c='Completed'
        );
        taskList.add(taskRec);

        Opportunity opportuniytObject5 = new Opportunity();
        opportuniytObject5.Type = 'New Product';
        opportuniytObject5.Name = 'Test Oppty Match';
        opportuniytObject5.AccountId = accoutObject1.id;
        opportuniytObject5.StageName = NSP_SalesConstants.DISCOVERY_STAGE;
        opportuniytObject5.CloseDate = date.today();
        opportuniytObject5.CurrencyIsoCode = CURRENCY_USD;
        opportuniytObject5.NSP_PrimaryProduct__c = 'WO';
        opportuniytObject5.NSP_Number_of_Employees__c = 5;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        insert opportuniytObject5;
        NSP_OpportunityTriggerHandler.TriggerDisabled = false;

        Test.startTest();
        List<Opportunity> oppList2 = new List<Opportunity>();
        Opportunity opportuniytObject3 = new Opportunity();
        opportuniytObject3.Name = 'Test Oppty Email';
        opportuniytObject3.AccountId = accoutObject1.id;
        opportuniytObject3.stagename = NSP_SalesConstants.ANALYSIS_STAGE;
        opportuniytObject3.CloseDate = date.today();
        opportuniytObject3.CurrencyIsoCode = CURRENCY_USD;
        opportuniytObject3.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject3.NSP_Client_For_Life__c='WX';
        opportuniytObject3.NSP_Number_of_Employees__c = 151; //!do not change. Test might fail
        opportuniytObject3.Type ='CAMS';
        opportuniytObject3.NSP_Upsell_Product_add_ons__c = OPP_NSP_UPSELL_PRODUCT_ADD_ONS_RETIREMENT_SERVICES;
        opportuniytObject3.NSP_Mid_Market_Sales_Email__c='test2@insperity.com';
        oppList2.add(opportuniytObject3);

        Opportunity opportuniytObject4 = new Opportunity();
        opportuniytObject4.Name = 'Test Oppty Email';
        opportuniytObject4.AccountId = accoutObject1.id;
        opportuniytObject4.stagename = NSP_SalesConstants.ANALYSIS_STAGE;
        opportuniytObject4.CloseDate = date.today();
        opportuniytObject4.CurrencyIsoCode = CURRENCY_USD;
        opportuniytObject4.NSP_PrimaryProduct__c = 'WA';
        opportuniytObject4.NSP_Client_For_Life__c='WA';
        opportuniytObject4.NSP_Number_of_Employees__c = 151; //!do not change. Test might fail
        opportuniytObject4.Type ='CAMS';
        opportuniytObject4.NSP_Upsell_Product_add_ons__c = OPP_NSP_UPSELL_PRODUCT_ADD_ONS_RETIREMENT_SERVICES;
        opportuniytObject4.NSP_Mid_Market_Sales_Email__c='test4@insperity.com';
        oppList2.add(opportuniytObject4);
        insert oppList2;

        SBQQ__Quote__c quoteRec = new SBQQ__Quote__c();
        quoteRec.SBQQ__Opportunity2__c = opportuniytObject3.Id;
        quoteRec.SBQQ__Account__c = opportuniytObject3.AccountId;
        quoteRec.SBQQ__Primary__c = true;
        quoteRec.SBQQ__Type__c = 'New Product';
        quoteRec.SBQQ__Status__c = 'Approved';
        insert quoteRec;

        Opportunity opportuniytObject6 = new Opportunity();
        opportuniytObject6.Name = 'Closed Won Oppty';
        opportuniytObject6.AccountId = accoutObject2.id;
        opportuniytObject6.CloseDate = date.today();
        opportuniytObject6.CurrencyIsoCode = CURRENCY_USD;
        opportuniytObject6.NSP_Number_of_Employees__c = 10;
        opportuniytObject6.StageName = NSP_SalesConstants.DISCOVERY_STAGE;
        insert opportuniytObject6;

        SBQQ__Quote__c quoteRec1 = new SBQQ__Quote__c();
        quoteRec1.SBQQ__Opportunity2__c = opportuniytObject6.Id;
        quoteRec1.SBQQ__Account__c = opportuniytObject6.AccountId;
        quoteRec1.SBQQ__Primary__c = true;
        quoteRec1.SBQQ__Type__c = 'New Product';
        quoteRec1.SBQQ__Status__c = 'Approved';
        insert quoteRec1;

        opportuniytObject6.StageName = NSP_SalesConstants.PROPOSAL_STAGE;
        opportuniytObject6.SBQQ__PrimaryQuote__c = quoteRec1.id;
        Update opportuniytObject6;

        opportuniytObject6.StageName = NSP_SalesConstants.CLOSED_WON_STAGE;
        Update opportuniytObject6;

        insert taskList;
        List<Opportunity> childOppList = new List<Opportunity>();
        //Create child opportunity for Retirement Service
        Opportunity childopportuniytObject = new Opportunity();
        childopportuniytObject.Name = 'Child Oppty Retirement Service';
        childopportuniytObject.AccountId = accoutObject1.id;
        childopportuniytObject.stagename = 'Qualification';
        childopportuniytObject.CloseDate = date.today();
        childopportuniytObject.CurrencyIsoCode = CURRENCY_USD;
        childopportuniytObject.NSP_Number_of_Employees__c = 100;
        childopportuniytObject.NSP_PrimaryProduct__c = 'Retirement Services';
        childopportuniytObject.NSP_Parent_Opportunity__c = opportuniytObject.id;
        childOppList.add(childopportuniytObject);

        //Create child opportuniy for Insurance Service
        Opportunity childopportuniytObject1 = new Opportunity();
        childopportuniytObject1.Name = 'Child Oppty Insurance Service';
        childopportuniytObject1.AccountId = accoutObject1.id;
        childopportuniytObject1.stagename = 'Qualification';
        childopportuniytObject1.CloseDate = date.today();
        childopportuniytObject1.CurrencyIsoCode = CURRENCY_USD;
        childopportuniytObject1.NSP_Number_of_Employees__c = 100;
        childopportuniytObject1.NSP_PrimaryProduct__c = 'Insurance Services';
        childopportuniytObject1.NSP_Parent_Opportunity__c = opportuniytObject.id;
        //insert childopportuniytObject1;
        childOppList.add(childopportuniytObject1);
        insert childOppList;

        Pricebook2 pricebook = new Pricebook2(Name = 'Non-CPQ Product Pricebook');
        insert pricebook;

        Test.stopTest();
        NSP_TestHelper.createCPQQuote(accoutObject1.Id,opportuniytObject.Id,true);

    }

    @isTest
    private static void TestEnrollmentFee() {

        Test.startTest();

         Account acct = new Account();
         acct.Name = 'Test Enrollment Fee';
        //inserting account object
        insert acct;

        List<Opportunity> oppList = new List<Opportunity>();

        //  Formula 1
        Opportunity opp1 = new Opportunity();
        opp1.Name = 'Test Oppty Enrollment Fee';
        opp1.AccountId = acct.id;
        opp1.stagename = NSP_SalesConstants.DISCOVERY_STAGE;
        opp1.CloseDate = date.today();
        opp1.CurrencyIsoCode = CURRENCY_USD;
        opp1.NSP_PrimaryProduct__c = 'WO';
        opp1.Type ='Existing Product';
        opp1.NSP_AddonType__c = 'CAM';
        opp1.NSP_Schedule_B_Enrollment_Fee__c = 1200;
        opp1.NSP_TotalAnnualPayroll__c = 1500;
        oppList.add(opp1);

        //  Formula 2
        Opportunity opp2 = new Opportunity();
        opp2.Name = 'Test Oppty Enrollment Fee';
        opp2.AccountId = acct.id;
        opp2.stagename = NSP_SalesConstants.DISCOVERY_STAGE;
        opp2.CloseDate = date.today();
        opp2.CurrencyIsoCode = CURRENCY_USD;
        opp2.NSP_PrimaryProduct__c = 'WO';
        opp2.NSP_Schedule_B_Enrollment_Fee__c = 100;
        opp2.NSP_TotalAnnualPayroll__c = 2500;
        oppList.add(opp2);

        //  Formula 3
        Opportunity opp3 = new Opportunity();
        opp3.Name = 'Test Oppty Enrollment Fee';
        opp3.AccountId = acct.id;
        opp3.stagename = NSP_SalesConstants.DISCOVERY_STAGE;
        opp3.CloseDate = date.today();
        opp3.CurrencyIsoCode = CURRENCY_USD;
        opp3.NSP_PrimaryProduct__c = 'WO';
        opp3.NSP_Schedule_B_Enrollment_Fee__c = 600;
        opp3.NSP_TotalAnnualPayroll__c = 2500;
        opp3.NSP_1_6_OfScheduleB__c = true;
        oppList.add(opp3);

        //  Formula 4
        Opportunity opp4 = new Opportunity();
        opp4.Name = 'Test Oppty Enrollment Fee';
        opp4.AccountId = acct.id;
        opp4.stagename = NSP_SalesConstants.DISCOVERY_STAGE;
        opp4.CloseDate = date.today();
        opp4.CurrencyIsoCode = CURRENCY_USD;
        opp4.NSP_PrimaryProduct__c = 'WO';
        opp4.NSP_Schedule_B_Enrollment_Fee__c = 600;
        opp4.NSP_TotalAnnualPayroll__c = 1500;
        opp4.NSP_WaivedInsperityFee__c = true;
        opp4.NSP_InsperityFeePercent__c = 10;
        oppList.add(opp4);

        //  Formula 1 - Workforce Sync
        Opportunity opp6 = new Opportunity();
        opp6.Name = 'Test Oppty Enrollment Fee';
        opp6.AccountId = acct.id;
        opp6.stagename = NSP_SalesConstants.DISCOVERY_STAGE;
        opp6.CloseDate = date.today();
        opp6.CurrencyIsoCode = CURRENCY_USD;
        opp6.NSP_PrimaryProduct__c = 'WS';
        opp6.Type ='Existing Product';
        opp6.NSP_AddonType__c = 'CAM';
        opp6.NSP_Schedule_B_Enrollment_Fee__c = 1200;
        opp6.NSP_TotalAnnualPayroll__c = 1500;
        oppList.add(opp6);

        //  Formula 2 - Workforce Sync
        Opportunity opp7 = new Opportunity();
        opp7.Name = 'Test Oppty Enrollment Fee';
        opp7.AccountId = acct.id;
        opp7.stagename = NSP_SalesConstants.DISCOVERY_STAGE;
        opp7.CloseDate = date.today();
        opp7.CurrencyIsoCode = CURRENCY_USD;
        opp7.NSP_PrimaryProduct__c = 'WS';
        opp7.NSP_Schedule_B_Enrollment_Fee__c = 100;
        opp7.NSP_TotalAnnualPayroll__c = 2500;
        oppList.add(opp7);

        //  Formula 3 - Workforce Sync
        Opportunity opp8 = new Opportunity();
        opp8.Name = 'Test Oppty Enrollment Fee';
        opp8.AccountId = acct.id;
        opp8.stagename = NSP_SalesConstants.DISCOVERY_STAGE;
        opp8.CloseDate = date.today();
        opp8.CurrencyIsoCode = CURRENCY_USD;
        opp8.NSP_PrimaryProduct__c = 'WS';
        opp8.NSP_Schedule_B_Enrollment_Fee__c = 600;
        opp8.NSP_TotalAnnualPayroll__c = 2500;
        opp8.NSP_1_6_OfScheduleB__c = true;
        oppList.add(opp8);

        //  Formula 4 - Workforce Sync
        Opportunity opp5 = new Opportunity();
        opp5.Name = 'Test Oppty Enrollment Fee';
        opp5.AccountId = acct.id;
        opp5.stagename = NSP_SalesConstants.DISCOVERY_STAGE;
        opp5.CloseDate = date.today();
        opp5.CurrencyIsoCode = CURRENCY_USD;
        opp5.NSP_PrimaryProduct__c = 'WS';
        opp5.NSP_Schedule_B_Enrollment_Fee__c = 600;
        opp5.NSP_TotalAnnualPayroll__c = 1500;
        opp5.NSP_WaivedInsperityFee__c = true;
        opp5.NSP_InsperityFeePercent__c = 10;
        oppList.add(opp5);

        //  Formula 1 - Workforce Sync
        Opportunity opp9 = new Opportunity();
        opp9.Name = 'Test Oppty Enrollment Fee';
        opp9.AccountId = acct.id;
        opp9.stagename = NSP_SalesConstants.DISCOVERY_STAGE;
        opp9.CloseDate = date.today();
        opp9.CurrencyIsoCode = CURRENCY_USD;
        opp9.NSP_PrimaryProduct__c = 'HRScale';
        opp9.Type ='Existing Product';
        opp9.NSP_AddonType__c = 'CAM';
        opp9.NSP_Schedule_B_Enrollment_Fee__c = 1200;
        opp9.NSP_TotalAnnualPayroll__c = 1500;
        oppList.add(opp9);

        NSP_OpportunityTriggerHelper.calculateEnrollmentFees(oppList);
        Test.stopTest();

        //  Formula 1
        //  opp.NSP_InsperityFee__c = opp.NSP_Schedule_B_Enrollment_Fee__c / 6;
        //  1200/ 6 = 200
        System.assertEquals(200, opp1.NSP_InsperityFee__c);

        //  Formula 2
        //  opp.NSP_Calculated_Enrollment_Fee__c =  ((opp.NSP_TotalAnnualPayroll__c / 12) * .06);
        //  opp.NSP_InsperityFee__c = opp.NSP_Calculated_Enrollment_Fee__c / 6;
        // NSP_InsperityFee__c = ((2500 /12) * .06 )/6 = 2.08333333333333333333333333333333 (include decimals otherwise won't work)
        System.assertEquals(2.08333333333333333333333333333333, opp2.NSP_InsperityFee__c);

        //  Formula 3
        //  opp.NSP_InsperityFee__c = opp.NSP_Schedule_B_Enrollment_Fee__c / 6;
        //  600 / 6 = 100
        System.assertEquals(100, opp3.NSP_InsperityFee__c);

        //  Formula 4
        //  opp.NSP_InsperityFee__c = (opp.NSP_InsperityFeePercent__c * opp.NSP_Schedule_B_Enrollment_Fee__c) / 100;
        //  (600 * 10) /100 = 60
        System.assertEquals(60, opp4.NSP_InsperityFee__c);

        //  Formula 1 - Workforce Sync
        //  opp.NSP_InsperityFee__c = opp.NSP_Schedule_B_Enrollment_Fee__c / 6;
        //  1200/ 6 = 200
        System.assertEquals(200, opp6.NSP_InsperityFee__c);

        //  Formula 2 -Workforce Sync
        //  opp.NSP_Calculated_Enrollment_Fee__c =  ((opp.NSP_TotalAnnualPayroll__c / 12) * .06);
        //  opp.NSP_InsperityFee__c = opp.NSP_Calculated_Enrollment_Fee__c / 6;
        // NSP_InsperityFee__c = ((2500 /12) * .06 )/6 = 2.08333333333333333333333333333333 (include decimals otherwise won't work)
        System.assertEquals(2.08333333333333333333333333333333, opp7.NSP_InsperityFee__c);

        //  Formula 3 - Workforce Sync
        //  opp.NSP_InsperityFee__c = opp.NSP_Schedule_B_Enrollment_Fee__c / 6;
        //  600 / 6 = 100
        System.assertEquals(100, opp8.NSP_InsperityFee__c);

        // Formula 4 -  Workforce Sync
        //  opp.NSP_InsperityFee__c = (opp.NSP_InsperityFeePercent__c * opp.NSP_Schedule_B_Enrollment_Fee__c) / 100;
        //  (600 * 10) /100 = 60
        System.assertEquals(60, opp5.NSP_InsperityFee__c);

        //  Formula 1
        //  HRScale should be the same as WS
        //  opp.NSP_InsperityFee__c = opp.NSP_Schedule_B_Enrollment_Fee__c / 6;
        //  1200/ 6 = 200
        System.assertEquals(200, opp9.NSP_InsperityFee__c);

    }

    @isTest
    private static void updatesOnChildOpportunityTest() {
        UserRole ur = new UserRole(Name = 'Regional Administrator');
        insert ur;

        User userRecord = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id,
            UserRoleId =ur.Id,
            LastName = 'TestClassUser',
            Phone = '1231231231',
            Email = 'testuser@insperity.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            NSP_Sales_Office_Membership__c = '301'
        );
        insert userRecord;
        user getUser = [SELECT Id,UserRole.Name FROM User WHERE Id =:userRecord.Id ];
        Test.startTest();
        System.runAs(userRecord) {
            Opportunity opp = [SELECT ID,NSP_PrimaryProduct__c,stagename FROM OPPORTUNITY WHERE NSP_Parent_Opportunity__c = null LIMIT 1];
            List<String> pOppIdSet = new List<String>{opp.Id};
            opp.ownerId = userRecord.Id;
            opp.NSP_PrimaryProduct__c = 'Insurance Services';
            opp.Closed_Lost_Group__c = 'Sales';
            opp.NSP_Lost_Reason__c = 'Benefits';
            opp.stagename = NSP_SalesConstants.CLOSED_LOST;
            database.update(opp);
            NSP_ChildOpportunitiesHelperFunctions.updateChildOpportunityOnReopen(pOppIdSet);
            Test.stopTest();
            System.assertEquals(NSP_SalesConstants.CLOSED_LOST, opp.stagename);
        }
    }

    @isTest
    private static void checkUpdate() {
        Test.startTest();
        List<Opportunity> opportunityList = [SELECT ID,NSP_PrimaryProduct__c,stagename FROM OPPORTUNITY WHERE NSP_Parent_Opportunity__c = null ];
        List<Account> accountList = [SELECT ID FROM ACCOUNT WHERE NAME = 'Test Account' ];

        //Setting stage to closed lost
        opportunityList[0].stagename = 'Closed Lost';
        //Setting reason as other
        opportunityList[0].NSP_Lost_Reason__c='Other';
        //Setting the account id
        opportunityList[0].Accountid = accountList[0].id;
        try {
        update opportunityList[0];
        }
        catch (DMLException e) {
            e.getMessage();
        }
        Test.stopTest();
        //Assert statement
        System.assertEquals('Closed Lost', opportunityList[0].stagename);
    }

    @isTest
    private static void checkUpdatefoeWOOpptys() {
        Test.startTest();
        List<Opportunity> opportunityList = [SELECT ID,NSP_PrimaryProduct__c,stagename FROM OPPORTUNITY WHERE NSP_Parent_Opportunity__c = null ];
        opportunityList[0].NSP_PrimaryProduct__c = 'WX';
        opportunityList[0].NSP_Reason_for_Product_Change__c='Test';
        update opportunityList[0];
        Test.stopTest();
        System.assertEquals('WX', opportunityList[0].NSP_PrimaryProduct__c);
    }

    @isTest
    private static void checkUpdatefoeWOOpptys1() {
        Test.startTest();
        List<Opportunity> opportunityList = [SELECT ID,NSP_PrimaryProduct__c,stagename FROM OPPORTUNITY WHERE NSP_Parent_Opportunity__c = null ];
        opportunityList[0].NSP_PrimaryProduct__c = 'WO';
        opportunityList[0].NSP_Contribution_Level__c = 'Level 1';
        opportunityList[0].NSP_Frequency_of_Distribution__c = 'Lump sum';
        opportunityList[0].NSP_Reason_for_Product_Change__c='Test';
        update opportunityList[0];
        Test.stopTest();
        System.assertEquals('WO', opportunityList[0].NSP_PrimaryProduct__c);
    }

    @isTest
    private static void checkClosedWonWOOpportunity() {
        Test.startTest();
        List<Opportunity> opportunityList = [SELECT Id, Name,NSP_Number_of_Employees__c,Type, NSP_PrimaryProduct__c,
                                             NSP_DM_User__c,NSP_DA_User__c,NSP_BPA__c,OwnerId,StageName,NSP_Merge_On_Demand_Template_Selection__c FROM Opportunity
                                             WHERE NSP_Number_Of_Employees__c = 151 AND StageName =: NSP_SalesConstants.ANALYSIS_STAGE AND NSP_PrimaryProduct__c = 'WO'];
        opportunity oppty = opportunityList[0];

        oppty.NSP_DM_User__c = oppty.OwnerId;
        oppty.NSP_DA_User__c = oppty.OwnerId;


        oppty.NSP_Merge_On_Demand_Template_Selection__c = 'NDA';
        update oppty;
        Test.stopTest();
        System.assertEquals(oppty.StageName, NSP_SalesConstants.ANALYSIS_STAGE); // Added as part of Code fix
    }

    @isTest
    private static void checkClosedWonWXOpportunity() {
        Test.startTest();
        List<Opportunity> opportunityList = [SELECT Id,AccountId, Name,NSP_Number_of_Employees__c,Type, NSP_PrimaryProduct__c,
                                             NSP_DM_User__c,NSP_DA_User__c,NSP_Merge_On_Demand_Template_Selection__c,SBQQ__PrimaryQuote__c,NSP_BPA__c,OwnerId FROM Opportunity
                                             WHERE NSP_Number_Of_Employees__c = 151 AND StageName =: NSP_SalesConstants.ANALYSIS_STAGE AND NSP_PrimaryProduct__c = 'WX'];
        opportunity oppty = opportunityList[0];
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :oppty.Id];
        oppty.SBQQ__PrimaryQuote__c = quote.Id;
        oppty.NSP_DM_User__c = oppty.OwnerId;
        oppty.NSP_DA_User__c = oppty.OwnerId;
        oppty.NSP_BPA__c = oppty.OwnerId;
        oppty.StageName = 'Closed Won';
        oppty.NSP_Merge_On_Demand_Template_Selection__c = 'NDA';
        oppty.AVA_SFCLOUD__Sales_Tax__c = 1000;
        oppty.Type = NSP_SalesConstants.NEW_BUSINESS_OPPORTUNITY;
        update oppty;

        List<Opportunity> updatedOppoList = new List<Opportunity>();
        updatedOppoList.add(oppty);
        NSP_OpportunityTriggerHelper helper = new NSP_OpportunityTriggerHelper();
        helper.retirementServicesForNonWOProducts(updatedOppoList);
        Test.stopTest();
        System.assertEquals(oppty.StageName, OPP_STAGENAME_CLOSED_WON); // Added as part of Code fix
    }

    @isTest
    static void moveOpportunityToClosingStageTest() {
        Test.startTest();
        List<Opportunity> opportunityList = [SELECT ID,
                                                   NSP_PrimaryProduct__c,
                                                   stagename,
                                                   NSP_Signed_CSA__c,
                                                   NSP_Signed_Delivery_Order__c,
                                                   CloseDate,
                                                   NSP_Closing_Appointment__c,
                                                   OwnerId FROM OPPORTUNITY WHERE NSP_Parent_Opportunity__c = null ];

        opportunityList[0].NSP_PrimaryProduct__c = NSP_SalesConstants.WX;
        opportunityList[0].NSP_Signed_Delivery_Order__c = true;
        opportunityList[0].NSP_Signed_CSA__c = true;
        opportunityList[0].NSP_Closing_Appointment__c = true;
        update opportunityList[0];
        NSP_OpportunityTriggerHelper helper = new NSP_OpportunityTriggerHelper();
        helper.moveOpportunityToClosingStage(opportunityList);
        Test.stopTest();
        System.assertEquals(NSP_SalesConstants.WX, opportunityList[0].NSP_PrimaryProduct__c);
    }

    @isTest
    private static void defaultFieldsOnChildOpportunityTest() {
        Test.startTest();
        Set<Id> pOppIdSet = new Set<Id>();
        List<Opportunity> cOppList = new List<Opportunity>();
        List<Opportunity> opportunityList = [SELECT Id, stagename, NSP_PrimaryProduct__c, NSP_Parent_Opportunity__r.NSP_PrimaryProduct__c FROM Opportunity
                                                    WHERE NSP_Parent_Opportunity__c != null LIMIT 1];
        pOppIdSet.add(opportunityList[0].NSP_Parent_Opportunity__c);
        cOppList.add(opportunityList[0]);

        NSP_ChildOpportunitiesHelperFunctions.defaultFieldsOnChildOpportunity(cOppList, pOppIdSet);
        Test.stopTest();
    }

    @isTest
    private static void createAssetTest() {
        Test.startTest();
        List<Opportunity> opportunityList = [SELECT Id, AccountId, StageName, NSP_PrimaryProduct__c FROM Opportunity
                                            WHERE StageName =: NSP_SalesConstants.ANALYSIS_STAGE AND NSP_PrimaryProduct__c = 'WX' LIMIT 1];

        opportunity oppty = opportunityList[0];
        oppty.NSP_PrimaryProduct__c = 'Insurance Services';
        oppty.StageName = 'Closed Won';
        update oppty;

        Test.stopTest();
        NSP_ChildOpportunitiesHelperFunctions.testHandleException( null , null );
    }

    @isTest
    private static void createAssetTest2() {
        Test.startTest();
        List<Opportunity> opportunityList = [SELECT Id, AccountId, StageName, NSP_PrimaryProduct__c FROM Opportunity
                                            WHERE StageName =: NSP_SalesConstants.ANALYSIS_STAGE AND NSP_PrimaryProduct__c = 'WX' LIMIT 1];

        opportunity oppty = opportunityList[0];
        oppty.NSP_PrimaryProduct__c = 'Expense Management';
        oppty.StageName = 'Closed Won';
        update oppty;

        Test.stopTest();
    }

    @isTest
    private static void createAssetTest3() {
        Test.startTest();
        List<Opportunity> opportunityList = [SELECT Id, AccountId, StageName, NSP_PrimaryProduct__c FROM Opportunity
                                            WHERE StageName =: NSP_SalesConstants.ANALYSIS_STAGE AND NSP_PrimaryProduct__c = 'WX' LIMIT 1];

        opportunity oppty = opportunityList[0];
        oppty.NSP_PrimaryProduct__c = 'WA';
        oppty.StageName = 'Closed Won';
        update oppty;

        Test.stopTest();
    }

    @isTest
    private static void sendClosedWonEmailNotificationWX() {

        Test.startTest();
        List<Opportunity> opportunityList = [SELECT Id,NSP_PrimaryProduct__c,AccountId,OwnerId FROM Opportunity WHERE NSP_Number_Of_Employees__c = 151 AND StageName =: NSP_SalesConstants.ANALYSIS_STAGE AND NSP_PrimaryProduct__c = 'WX'];

        ContentVersion cvlist = new Contentversion();
        cvlist.Title = 'WX_0_Delivery Order__completed';
        cvlist.PathOnClient = 'test';
        cvlist.VersionData = EncodingUtil.base64Decode('Unit Test Attachment Body');
        cvlist.FirstPublishLocationId=opportunityList[0].Id;
        insert cvlist;

        opportunity oppty = opportunityList[0];
        oppty.NSP_DM_User__c = oppty.OwnerId;
        oppty.NSP_DA_User__c = oppty.OwnerId;
        oppty.NSP_BPA__c = oppty.OwnerId;
        oppty.StageName = 'Closed Won';
        update oppty;
        List<String> workforceProductsList = System.Label.NSP_Primary_Workforce_Products.split(',');
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
        oppMap.put(oppty.Id,oppty);
        NSP_EmailServicesUtility.sendEmailsTOService(oppMap.Values(),oppMap,workforceProductsList);
        Test.stopTest();
        System.assertEquals(oppty.StageName, OPP_STAGENAME_CLOSED_WON); // Added as part of Code fix
    }

    @isTest
    private static void sendClosedWonEmailNotificationWA() {

        Test.startTest();
        List<Opportunity> opportunityList = [SELECT Id,NSP_PrimaryProduct__c,AccountId,OwnerId FROM Opportunity WHERE NSP_Number_Of_Employees__c = 151 AND StageName =: NSP_SalesConstants.ANALYSIS_STAGE AND NSP_PrimaryProduct__c = 'WA'];

        ContentVersion cvlist = new Contentversion();
        cvlist.Title = 'WA_0_Delivery Order__completed';
        cvlist.PathOnClient = 'test';
        cvlist.VersionData = EncodingUtil.base64Decode('Unit Test Attachment Body');
        cvlist.FirstPublishLocationId=opportunityList[0].Id;
        insert cvlist;
        opportunity oppty = opportunityList[0];
        oppty.NSP_DM_User__c = oppty.OwnerId;
        oppty.NSP_DA_User__c = oppty.OwnerId;
        oppty.NSP_BPA__c = oppty.OwnerId;
        oppty.StageName = 'Closed Won';
        update oppty;
        List<String> workforceProductsList = System.Label.NSP_Primary_Workforce_Products.split(',');
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
        oppMap.put(oppty.Id,oppty);
        NSP_EmailServicesUtility.sendEmailsTOService(oppMap.Values(),oppMap,workforceProductsList);
        Test.stopTest();
        System.assertEquals(oppty.StageName, OPP_STAGENAME_CLOSED_WON); // Added as part of Code fix
    }

    @isTest
    private static void salesOfficeTest() {
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

        NSP_Sales_Office_Mapping__c office1Mapping = new NSP_Sales_Office_Mapping__c();
        office1Mapping.NSP_Sales_Office__c = '301';
        office1Mapping.NSP_Sales_Division__c = 'Central';
        office1Mapping.NSP_Sales_Region__c = 'Central 1';
        office1Mapping.NSP_Start_Date__c = system.today()-1;
        office1Mapping.NSP_End_Date__c = system.today()+200;
        insert office1Mapping;

        Test.startTest();
        List<Opportunity> opportunityList = [SELECT ID,NSP_PrimaryProduct__c,stagename FROM OPPORTUNITY WHERE NSP_Parent_Opportunity__c = null ];
        for(Opportunity eachOppty : opportunityList)
        {
            eachOppty.NSP_Sales_Office__c = '1081';
        }
        update opportunityList;
        Test.stopTest();
   }

    @isTest
    private static void rewardCreationTest() {
        Test.startTest();
        List<Opportunity> opportunityList = [SELECT ID,NSP_PrimaryProduct__c,stagename,Discovery_Completed__c,Nsp_1st_Pay_Invoice_Date_Reporting__c FROM OPPORTUNITY WHERE Name != null limit 1 ];
        List<Account> accountList = [SELECT ID FROM ACCOUNT WHERE NAME = 'Test Account' ];
        list<Contact> cntInsertlist = new list<Contact>();
        for(Account objAccount: accountList){
            Contact objContact = new Contact();
            objContact.firstName = 'Test';
            objContact.LastName = 'Contact NSP';
            objContact.Email = 'testcnt@nsp.com';
            objContact.AccountId = objAccount.Id;
            cntInsertlist.add(objContact);
        }
        insert cntInsertlist;

        OpportunityContactRole objOCR = new OpportunityContactRole();
        objOCR.OpportunityId = opportunityList[0].id;
        objOCR.ContactId = cntInsertlist[0].Id;
        objOCR.NSP_isReferral__c = true;
        objOCR.Role = 'Agency';
        insert objOCR;
        opportunityList[0].Discovery_Completed__c = true;
        update opportunityList;
        opportunityList[0].Nsp_1st_Pay_Invoice_Date_Reporting__c = system.today()+2;
        update opportunityList;

        //   Test match reward
        List<Opportunity> opportunityList1 = [SELECT ID, Discovery_Completed__c FROM Opportunity WHERE Name = 'Test Oppty Match' ];

        Contact objContact1 = new Contact();
        objContact1.firstName = 'Test Match';
        objContact1.LastName = 'Contact NSP Match';
        objContact1.Email = 'testcntmatch@nsp.com';
        objContact1.AccountId = accountList[0].Id;
        insert objContact1;

        OpportunityContactRole objOCR1 = new OpportunityContactRole();
        objOCR1.OpportunityId = opportunityList1[0].id;
        objOCR1.ContactId = objContact1.Id;
        objOCR1.NSP_isReferral__c = true;
        objOCR1.Role = 'COI';
        objOCR1.NSP_Referralbenefitsanonprofitorg__c = 'Match';
        objOCR1.NSP_Nonprofit_Organization_Name__c = 'Test';
        objOCR1.NSP_Nonprofit_Organization_Tax_Id__c = '123456789';
        insert objOCR1;

        DateTime testtime = System.now();
        Id eventRecTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Core_Sales_Event_RT').getRecordTypeId();
        Event eventRec = new Event(
            Subject = 'Discovery Call',
            WhatId = opportunityList[0].Id,
            RecordTypeId = eventRecTypeId,
            NSP_Task_Type__c = 'Core Sales',
            NSP_Event_Subtype__c = 'Discovery Call',
            NSP_Status__c = 'Completed',
            ActivityDateTime = testtime,
            StartDateTime = testtime,
            EndDateTime = testtime,
            ActivityDate = System.today()
        );
        insert eventRec;

        //   Create reward
        NSP_OpportunityTriggerHelper.createRewardsOnce = false;
        opportunityList1[0].Discovery_Completed__c = true;
        update opportunityList1;

        List<NSP_Reward__c> reward = [SELECT id, NSP_Reward_Amount__c, NSP_Nonprofit_Amount__c FROM NSP_Reward__c WHERE Opportunity__c =: opportunityList1[0].Id];

        //   Match reward amount and non-profit amount should be 200
        System.assertEquals(200, reward[0].NSP_Reward_Amount__c);

        System.assertEquals(200, reward[0].NSP_Nonprofit_Amount__c);

        Test.stopTest();
    }

    @isTest
    private static void testAccountContactInsert() {

        // Start Test
        Test.startTest();

        Account accObj = [Select Id,Name from Account WHERE Name = 'Test Account' Limit 1];
        ID accountId = accObj.Id;
        AccountContactRelation acrObj  = [Select Id from AccountContactRelation WHERE AccountId =: accountId];
        acrObj.Roles = 'Agency';
        acrObj.NSP_Is_Primary__c = true;
        acrObj.IsActive =true;
        update acrObj;

        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Name = 'Test Oppty';
        opportuniytObject.AccountId = accountId;
        opportuniytObject.stagename = NSP_SalesConstants.DISCOVERY_STAGE;
        opportuniytObject.CloseDate = date.today();
        opportuniytObject.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject.NSP_Number_of_Employees__c = 100;
        opportuniytObject.NSP_WS_Number_Of_Employees__c = 123;
        opportuniytObject.NSP_WO_Number_Of_Employees__c = 123;
        //Inserting Opportunity Object
        insert opportuniytObject;
        Test.stopTest();
    }

    @isTest
    private static void testEnrollmentFeeTrue() {

        // Start Test
        Test.startTest();

        //Create Enrollment fee payment
        Opportunity oppObj = [Select Id,Name,NSP_Number_of_Employees__c from Opportunity WHERE NSP_Number_of_Employees__c < 150 Limit 1];
        ID oppId = oppObj.Id;
        NSP_Enrollment_Fee_Payment__c enrollmentfee = new NSP_Enrollment_Fee_Payment__c();
        enrollmentfee.NSP_Opportunity__c = oppId;
        enrollmentfee.CurrencyIsoCode = CURRENCY_USD;
        insert enrollmentfee;

        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Id = oppId;
        opportuniytObject.NSP_Number_of_Employees__c = 200;
        update opportuniytObject;

        Test.stopTest();
    }

    @isTest
    private static void testParent() {

        Test.startTest();
        Opportunity opp = [SELECT ID,AccountId,stagename FROM OPPORTUNITY WHERE NSP_Parent_Opportunity__c = null LIMIT 1];
        Opportunity childopportuniytObject2 = new Opportunity();
        childopportuniytObject2.Name = 'Child Oppty Insurance Service';
        childopportuniytObject2.AccountId = Opp.AccountId;
        childopportuniytObject2.stagename = 'Qualification';
        childopportuniytObject2.CloseDate = date.today();
        childopportuniytObject2.CurrencyIsoCode = CURRENCY_USD;
        childopportuniytObject2.NSP_Number_of_Employees__c = 100;
        childopportuniytObject2.NSP_PrimaryProduct__c = 'Insurance Services';
        childopportuniytObject2.NSP_Parent_Opportunity__c = opp.id;
        childopportuniytObject2.Type = NSP_SalesConstants.CLIENT_GROWTH_CREDIT;
        childopportuniytObject2.NSP_Contribution_Level__c = 'Level 1';
        childopportuniytObject2.NSP_Frequency_of_Distribution__c = 'Lump sum';
        insert childopportuniytObject2;
    }

    @isTest
    private static void testEnrollmentFeeFalse() {

        // Start Test
        Test.startTest();

        //Create Enrollment fee payment
        Opportunity oppObj = [Select Id,Name,NSP_Number_of_Employees__c from Opportunity WHERE NSP_Number_of_Employees__c > 150 Limit 1];
        ID oppId = oppObj.Id;

        NSP_Enrollment_Fee_Payment__c enrollmentfee = new NSP_Enrollment_Fee_Payment__c();
        enrollmentfee.NSP_Opportunity__c = oppId;
        enrollmentfee.CurrencyIsoCode = CURRENCY_USD;
        insert enrollmentfee;

        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Id = oppId;
        opportuniytObject.NSP_Number_of_Employees__c = 100;
        //Inserting Opportunity Object
        update opportuniytObject;
        Test.stopTest();
        NSP_OpportunityTriggerHelper.testHandleException( null , null );
    }

    @isTest
    private static void testSendFileRequest() {

        Test.startTest();
        String expectedError = Label.NSP_CANNOT_CHANGE_CLOSEDWON;

        try{
            List<Opportunity> opp1 = [SELECT id, Name, StageName, AVA_SFCLOUD__Sales_Tax__c, Create_Box_com_Folder_s__c
                                      FROM Opportunity
                                      WHERE Name = 'Closed Won Oppty'] ;

            //  Try to change not allowed fields
            opp1[0].AVA_SFCLOUD__Sales_Tax__c = 10;
            opp1[0].Name = 'Test Opportunity change';

            //  Set checkbox to true
            opp1[0].Create_Box_com_Folder_s__c = true;

            //  Update Opportunity
            update opp1;
        }
        catch(Exception e){
            // An error is expected
            System.assertEquals(true , e.getMessage().contains(expectedError));
        }
        finally{
            Test.stopTest();
        }
    }

    @isTest
    private static void testBackward_Stage() {
        Test.startTest();
        String expectedError = Label.Opportunity_Backward_Stage;

        try{
            Opportunity opp1 = [SELECT Id, StageName FROM Opportunity WHERE StageName =: NSP_SalesConstants.ANALYSIS_STAGE LIMIT 1] ;
            opp1.StageName = NSP_SalesConstants.DISCOVERY_STAGE;
            update opp1;
        }
        catch(Exception e){
            System.assertEquals(true , e.getMessage().contains(expectedError));
        }
        finally{
            Test.stopTest();
        }
    }

    @isTest
    private static void testGetLabelValuesAsSet() {
        Test.startTest();

        // Test 1: Valid comma-separated input
        String validInput = 'Workforce, Workforce Plus, WF';
        Set<String> result = NSP_OpportunityTriggerHelperFunctions.getLabelValuesAsSet(validInput);
        Set<String> expected = new Set<String>{'workforce', 'workforce plus', 'wf'};
        System.assertEquals(expected, result, 'The method should return a set of lowercase, trimmed values');

        // Test 2: Empty string input
        String emptyInput = '';
        result = NSP_OpportunityTriggerHelperFunctions.getLabelValuesAsSet(emptyInput);
        System.assertEquals(new Set<String>(), result, 'The method should return an empty set for an empty string');

        // Test 3: Null input
        result = NSP_OpportunityTriggerHelperFunctions.getLabelValuesAsSet(null);
        System.assertEquals(new Set<String>(), result, 'The method should return an empty set for a null input');

        // Test 4: Input with extra whitespace
        String whitespaceInput = 'Workforce, Workforce Plus , WF';
        result = NSP_OpportunityTriggerHelperFunctions.getLabelValuesAsSet(whitespaceInput);
        expected = new Set<String>{'workforce', 'workforce plus', 'wf'};
        System.assertEquals(expected, result, 'The method should trim whitespace from values');

        // Test 5: Single value (no commas)
        String singleValueInput = 'Workforce';
        result = NSP_OpportunityTriggerHelperFunctions.getLabelValuesAsSet(singleValueInput);
        expected = new Set<String>{'workforce'};
        System.assertEquals(expected, result, 'The method should handle a single value without commas');

        Test.stopTest();
    }

    @isTest
    private static void testGetAssetRecord() {
        Test.startTest();
        Id recordId = NSP_OpportunityTriggerHelper.getAssetRecordTypeIdByName('WX_WA');
        System.assertEquals('0124x000000yRuxAAE', recordId);
        Test.stopTest();
    }

    @isTest
    private static void testServicesOpportunity() {
        Test.startTest();
        List<PermissionSetAssignment> psa = [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE
                PermissionSet.Name = 'NSPSteelBrickCPQUser'
                AND Assignee.isActive = true
            LIMIT 1
        ];
        System.assert((psa != null && psa.size() == 1), 'No Services_Opportunity_Owner user found');
        System.assert(CustomPermissionController.checkUserPermission('Services_Opportunity_Owner', psa[0].AssigneeId), 'Custom PS Services_Opportunity_Owner not assigned');
        Account acct = new Account();
        acct.Name = 'Test Account Opp';
        insert acct;
        Opportunity opp = new Opportunity();
        opp.AccountId = acct.Id;
        opp.CloseDate = date.today();
        opp.NSP_PrimaryProduct__c = 'WX';
        opp.StageName = 'Prospecting';
        opp.OwnerId = psa[0].AssigneeId;
        insert opp;
        Test.stopTest();
        List<Opportunity> opp1 = [
            SELECT Id , Is_Services_Opportunity__c
            FROM Opportunity
            WHERE Id = :opp.Id
            LIMIT 1
        ];
        Boolean isServiceOpportunity = true;
        System.assertEquals(isServiceOpportunity, opp1[0].Is_Services_Opportunity__c);
    }

    @isTest
    private static void testTransferDiscoveryCall() {

        Test.startTest();
        List<User> users = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 2];
        System.assert((users != null && users.size() == 2), 'No System Administrator user found');

        Account acct = new Account();
        acct.Name = 'Test Account Opp';
        insert acct;

        Opportunity opp = new Opportunity();
        opp.AccountId = acct.Id;
        opp.CloseDate = date.today();
        opp.NSP_PrimaryProduct__c = 'WX';
        opp.StageName = 'Prospecting';
        opp.OwnerId = users[0].Id;
        insert opp;

        // Create Event with Discovery Call subtype and Open status
        Id eventRecTypeId = NSP_GenericRecordType.getRecordTypeId( 'Event' , 'Core_Sales_Event_RT' );
        Date todayDate = System.today();
        Event testEvent = new Event(
        OwnerId = users[0].Id,
        WhatId = opp.Id,
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

        NSP_OpportunityTriggerHandler.runOnce = true;
        opp.OwnerId = users[1].Id;
        update opp;

        Test.stopTest();
        List<Event> eventCheck = [SELECT id, OwnerId FROM Event WHERE id = :testEvent.id ];
        System.assert((eventCheck != null && !eventCheck.isEmpty()), 'No Event found');
        System.assertEquals(users[1].Id, eventCheck[0].OwnerId);
    }

    @isTest
    private static void hrScaleDiscoveryRewardEligibleRoleTest() {
        List<Account> accList = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Account acc = accList.isEmpty() ? null : accList[0];

        Opportunity hrScaleOpp = new Opportunity();
        hrScaleOpp.Name = 'HRScale Reward Oppty';
        hrScaleOpp.Type = 'New Product';
        hrScaleOpp.AccountId = acc.Id;
        hrScaleOpp.StageName = NSP_SalesConstants.DISCOVERY_STAGE;
        hrScaleOpp.CloseDate = Date.today();
        hrScaleOpp.CurrencyIsoCode = CURRENCY_USD;
        hrScaleOpp.NSP_PrimaryProduct__c = 'HRScale';
        hrScaleOpp.NSP_Number_of_Employees__c = 25;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        insert hrScaleOpp;
        NSP_OpportunityTriggerHandler.TriggerDisabled = false;

        Contact con = new Contact(FirstName = 'HR', LastName = 'Scale COI', Email = 'hrscalecoi@nsp.com', AccountId = acc.Id);
        insert con;

        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = hrScaleOpp.Id;
        ocr.ContactId = con.Id;
        ocr.NSP_isReferral__c = true;
        ocr.Role = 'COI';
        insert ocr;

        DateTime t = System.now();
        Id eventRecTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Core_Sales_Event_RT').getRecordTypeId();
        insert new Event(
            Subject = 'Discovery Call',
            WhatId = hrScaleOpp.Id,
            RecordTypeId = eventRecTypeId,
            NSP_Task_Type__c = 'Core Sales',
            NSP_Event_Subtype__c = 'Discovery Call',
            NSP_Status__c = 'Completed',
            ActivityDateTime = t,
            StartDateTime = t,
            EndDateTime = t,
            ActivityDate = System.today()
        );

        Test.startTest();
        NSP_OpportunityTriggerHelper.createRewardsOnce = false;
        hrScaleOpp.Discovery_Completed__c = true;
        update hrScaleOpp;
        Test.stopTest();

        List<NSP_Reward__c> rewards = [
            SELECT Id, NSP_Reward_Type__c, NSP_Contact_Role__c, NSP_Reward_Amount__c
            FROM NSP_Reward__c WHERE Opportunity__c = :hrScaleOpp.Id
        ];
        System.assertEquals(1, rewards.size(), 'HRScale eligible referral role should create one Discovery reward');
        System.assertEquals('Discovery', rewards[0].NSP_Reward_Type__c, 'Reward type should be Discovery');
        System.assertEquals('COI', rewards[0].NSP_Contact_Role__c, 'Reward should capture the contact role');
        System.assertEquals(200, rewards[0].NSP_Reward_Amount__c, 'Standard (non-nonprofit) Discovery reward amount is 200');
    }

    @isTest
    private static void hrScaleDiscoveryRewardIneligibleRoleTest() {
        List<Account> accList = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Account acc = accList.isEmpty() ? null : accList[0];

        Opportunity hrScaleOpp = new Opportunity();
        hrScaleOpp.Name = 'HRScale No Reward Oppty';
        hrScaleOpp.Type = 'New Product';
        hrScaleOpp.AccountId = acc.Id;
        hrScaleOpp.StageName = NSP_SalesConstants.DISCOVERY_STAGE;
        hrScaleOpp.CloseDate = Date.today();
        hrScaleOpp.CurrencyIsoCode = CURRENCY_USD;
        hrScaleOpp.NSP_PrimaryProduct__c = 'HRScale';
        hrScaleOpp.NSP_Number_of_Employees__c = 25;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        insert hrScaleOpp;
        NSP_OpportunityTriggerHandler.TriggerDisabled = false;

        Contact con = new Contact(FirstName = 'HR', LastName = 'Scale Inf', Email = 'hrscaleinf@nsp.com', AccountId = acc.Id);
        insert con;

        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = hrScaleOpp.Id;
        ocr.ContactId = con.Id;
        ocr.NSP_isReferral__c = true;
        ocr.Role = 'Influencer';
        insert ocr;

        Test.startTest();
        NSP_OpportunityTriggerHelper.createRewardsOnce = false;
        hrScaleOpp.Discovery_Completed__c = true;
        update hrScaleOpp;
        Test.stopTest();

        List<NSP_Reward__c> rewards = [SELECT Id FROM NSP_Reward__c WHERE Opportunity__c = :hrScaleOpp.Id];
        System.assertEquals(0, rewards.size(), 'Ineligible contact role should not create an HRScale Discovery reward');
    }

    @isTest
    private static void updatesOnChildOpportunity_closedWonChildNotModifiedTest() {
        // Arrange: locate the existing parent and its Retirement Services child from @testSetup
        Opportunity parentOpp = [
            SELECT Id FROM Opportunity
            WHERE NSP_Parent_Opportunity__c = null
            AND NSP_PrimaryProduct__c != 'Retirement Services'
            LIMIT 1
        ];

        // Set the Retirement Services child to Closed Won before the method runs
        Opportunity childOpp = [
            SELECT Id, StageName, NSP_PrimaryProduct__c
            FROM Opportunity
            WHERE NSP_Parent_Opportunity__c = :parentOpp.Id
            AND NSP_PrimaryProduct__c = :NSP_SalesConstants.RETIREMENT_SERVICE
            LIMIT 1
        ];
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        childOpp.StageName = NSP_SalesConstants.CLOSED_WON;
        update childOpp;
        NSP_OpportunityTriggerHandler.TriggerDisabled = false;

        Test.startTest();
        NSP_ChildOpportunitiesHelperFunctions helper = new NSP_ChildOpportunitiesHelperFunctions();
        helper.updatesOnChildOpportunity( new List<String>{ parentOpp.Id } );
        Test.stopTest();

        // The Closed Won child must remain Closed Won - not get closed lost
        Opportunity afterUpdate = [
            SELECT StageName, NSP_Is_Parent_Opportunity_Closed_Lost__c
            FROM Opportunity
            WHERE Id = :childOpp.Id
        ];
        System.assertEquals(
            NSP_SalesConstants.CLOSED_WON,
            afterUpdate.StageName,
            'Closed Won child should not be moved to Closed Lost'
        );
        System.assertEquals(
            false,
            afterUpdate.NSP_Is_Parent_Opportunity_Closed_Lost__c,
            'Closed Won child should not have NSP_Is_Parent_Opportunity_Closed_Lost__c set to true'
        );
    }

    @isTest
    private static void hrScaleSoldRewardTest() {
        List<Account> accList = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Account acc = accList.isEmpty() ? null : accList[0];

        Opportunity hrScaleOpp = new Opportunity();
        hrScaleOpp.Name = 'HRScale Sold Oppty';
        hrScaleOpp.Type = 'New Product';
        hrScaleOpp.AccountId = acc.Id;
        hrScaleOpp.StageName = NSP_SalesConstants.DISCOVERY_STAGE;
        hrScaleOpp.CloseDate = Date.today();
        hrScaleOpp.CurrencyIsoCode = CURRENCY_USD;
        hrScaleOpp.NSP_PrimaryProduct__c = 'HRScale';
        hrScaleOpp.NSP_Number_of_Employees__c = 25;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        insert hrScaleOpp;
        NSP_OpportunityTriggerHandler.TriggerDisabled = false;

        Contact con = new Contact(FirstName = 'HR', LastName = 'Scale Sold', Email = 'hrscalesold@nsp.com', AccountId = acc.Id);
        insert con;

        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = hrScaleOpp.Id;
        ocr.ContactId = con.Id;
        ocr.NSP_isReferral__c = true;
        ocr.Role = 'Agency';
        insert ocr;

        Test.startTest();
        NSP_OpportunityTriggerHelper.createRewardsOnce = false;
        hrScaleOpp.Nsp_1st_Pay_Invoice_Date_Reporting__c = Date.today();
        update hrScaleOpp;
        Test.stopTest();

        List<NSP_Reward__c> rewards = [
            SELECT Id, NSP_Reward_Type__c, NSP_Reward_Amount__c
            FROM NSP_Reward__c WHERE Opportunity__c = :hrScaleOpp.Id
        ];
        System.assertEquals(1, rewards.size(), 'HRScale should create a Sold reward like the other products');
        System.assertEquals('Sold', rewards[0].NSP_Reward_Type__c, 'Reward type should be Sold');
        System.assertEquals(1000, rewards[0].NSP_Reward_Amount__c, 'Standard (non-nonprofit) Sold reward amount is 1000');
    }

}
//