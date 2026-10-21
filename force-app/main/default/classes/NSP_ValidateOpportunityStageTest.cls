@isTest
private class NSP_ValidateOpportunityStageTest {

    //Test Setup Method to populate test data
    @testSetup
    private static void setupData(){

        Account acnt=NSP_TestHelper.createAccount(true);
        Contact cntct=NSP_TestHelper.createContact(true);

        Opportunity opp=NSP_TestHelper.createOpenOpportunity(acnt.Id,'New Product',false);
        opp.StageName = 'Prospecting';
        opp.NSP_Number_of_Employees__c=50;
        opp.NSP_BidNumber__c='123';
        opp.NSP_PrimaryProduct__c = 'WS';
        opp.NSP_Partner__c=acnt.Id;
        insert opp;

        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId = cntct.Id
        );
        insert ocr;

        Id baseCheckListRecordTypeId = Schema.SObjectType.NSP_Checklist__c.getRecordTypeInfosByDeveloperName().get('Base').getRecordTypeId();
        NSP_Checklist__c stpCheckList = new NSP_Checklist__c(
            RecordTypeId = baseCheckListRecordTypeId,
            Checklist_Type__c = 'Sold To Paid',
            NSP_Opportunity__c = opp.Id,
            NSP_Requested_First_Pay_Date__c = system.today(),
            Status__c = 'Completed'
        );
        insert stpCheckList;

        List<SObject> sOList = new List<SObject>();
        Id eventRecTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Core_Sales_Event_RT').getRecordTypeId();
        Id taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Core_Sales_Task_RT').getRecordTypeId();

        User userRecordInt = [Select Id, Email from User where Id = '0054x0000057MPSAA2'];

        Task taskRec1 = new Task(
            Subject = 'Business Profile Started',
            WhatId = opp.Id,
            NSP_Task_Type__c = 'Core Sales',
            RecordTypeId = taskRecTypeId,
            Status = 'Completed'
        );
        sOList.add(taskRec1);

        Event eventRec = new Event(
            Subject = 'Discovery Call',
            WhatId = opp.Id,
            RecordTypeId = eventRecTypeId,
            StartDateTime=system.now(),
            EndDateTime=system.now()+( 15/1440),
            NSP_Event_Subtype__c = NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY,
            NSP_Status__c='Open'
        );
        sOList.add(eventRec);

        //Task and Events Insert
        if(userRecordInt != null) {
            System.runAs(userRecordInt){
                insert sOList;
            }
        }

        Test.startTest();
        blng__BillingRule__c objBillingRule = NSP_TestHelper.createBillingRule();
        blng__RevenueRecognitionRule__c objRevRecRule =  NSP_TestHelper.createRevrecRule('1');
        blng__TaxRule__c objTaxRule = NSP_TestHelper.createRevTaxRule();
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.blng__BillingRule__c = objBillingRule.id;
        objproduct.blng__RevenueRecognitionRule__c = objRevRecRule.Id;
        objproduct.blng__TaxRule__c = objTaxRule.Id;
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.blng__BillingRule__c = objBillingRule.Id;
        objproduct.blng__RevenueRecognitionRule__c = objRevRecRule.Id;
        objproduct.blng__TaxRule__c = objTaxRule.Id;
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c ='YES';
        insert objproduct;
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);

        //create quote
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(acnt.Id,opp.Id,true);

        // create quote lines
        List<SBQQ__Quoteline__c> qlines = NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);

        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        update objQuote;

        //insert OpportunityLineItem
        OpportunityLineItem OLI = new OpportunityLineItem();
        OLI.OpportunityId = opp.Id;
        OLI.Product2Id = objproduct.Id;
        OLI.Quantity = 1;
        OLI.UnitPrice = 1;
        insert OLI;
        Test.stopTest();

        // Create NSP_Employee_Split__c records
        NSP_Employee_Split__c splitRecord1 = new NSP_Employee_Split__c( NSP_Opportunity__c = opp.Id, NSP_Number_of_Employees__c = 25, NSP_Percent_Split__c = 50 );
        NSP_Employee_Split__c splitRecord2 = new NSP_Employee_Split__c( NSP_Opportunity__c = opp.Id, NSP_Number_of_Employees__c = 25, NSP_Percent_Split__c = 50 );
        insert new List<NSP_Employee_Split__c>{ splitRecord1, splitRecord2 };
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User userRecord1 = new User(
            ProfileId = adminProfile.Id,
            LastName = 'TestClassUser',
            Email = 'testuser1@insperity.com',
            Username = 'testuser1@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            NSP_Sales_Office_Membership__c = '301',
            LocaleSidKey = 'en_US'
        );
        insert userRecord1;

        User userRecord2 = new User(
            ProfileId = adminProfile.Id,
            LastName = 'TestClassUser',
            Email = 'testuser2@insperity.com',
            Username = 'testuser2@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            NSP_Sales_Office_Membership__c = '301',
            LocaleSidKey = 'en_US'
        );
        insert userRecord2;

        // Creating Groups
        Group gp1= new Group();
        gp1.Name='0302 Phoenix 2';
        Group gp2= new Group();
        gp2.Name='0601 Denver 1';
        // Inserting groups
        List<Group> groups= new List<Group>{gp1, gp2};
        Insert groups;
    }

    @isTest
    private static void testValidateOpportunityStageDC() {
        Test.startTest();
        List<Opportunity> oppList = [SELECT Id , OwnerId FROM Opportunity WHERE NSP_BidNumber__c = '123' LIMIT 1];
        Opportunity opty = oppList[0];
        opty.StageName = 'Data Collection';
        try{
            update opty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }
        Test.stopTest();

        // Check for expected errors or state changes
        Opportunity updatedOpportunity = [SELECT Id, StageName FROM Opportunity WHERE Id = :oppList[0].Id];
        System.assertEquals('Prospecting', updatedOpportunity.StageName, 'Stage should remain unchanged.');
    }

    @isTest
    private static void testValidateOpportunityStageAnalysis() {
        Test.startTest();
        List<Opportunity> oppList = [SELECT Id , OwnerId FROM Opportunity WHERE NSP_BidNumber__c = '123' LIMIT 1];
        Opportunity opty = oppList[0];
        opty.NSP_PrimaryProduct__c = 'Performance Management';
        opty.NSP_Number_of_Employees__c = 0;
        opty.StageName = 'Analysis';
        try{
            update opty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }
        Test.stopTest();

        // Check for expected errors or state changes
        Opportunity updatedOpportunity = [SELECT Id, StageName FROM Opportunity WHERE Id = :oppList[0].Id];
        System.assertEquals('Prospecting', updatedOpportunity.StageName, 'Stage should remain unchanged.');
    }

    @isTest
    private static void testValidateOpportunityStageProposal() {
        Test.startTest();
        List<Opportunity> oppList = [SELECT Id , OwnerId FROM Opportunity WHERE NSP_BidNumber__c = '123' LIMIT 1];
        Opportunity opty = oppList[0];
        opty.NSP_PrimaryProduct__c = 'WO';
        opty.StageName = 'Proposal';
        try{
            update opty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }
        Test.stopTest();

        // Check for expected errors or state changes
        Opportunity updatedOpportunity = [SELECT Id, StageName FROM Opportunity WHERE Id = :oppList[0].Id];
        System.assertEquals('Prospecting', updatedOpportunity.StageName, 'Stage should remain unchanged.');
    }

    @isTest
    private static void testValidateOpportunityStageClosing() {
        Test.startTest();
        List<Opportunity> oppList = [SELECT Id , OwnerId FROM Opportunity WHERE NSP_BidNumber__c = '123' LIMIT 1];
        Opportunity opty = oppList[0];
        opty.NSP_PrimaryProduct__c = 'WO';
        opty.StageName = 'Closing';
        try{
            update opty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }
        Test.stopTest();

        // Check for expected errors or state changes
        Opportunity updatedOpportunity = [SELECT Id, StageName FROM Opportunity WHERE Id = :oppList[0].Id];
        System.assertEquals('Prospecting', updatedOpportunity.StageName, 'Stage should remain unchanged.');
    }

    @isTest
    private static void testValidateOpportunityStageBooking() {
        Test.startTest();
        List<Opportunity> oppList = [SELECT Id , OwnerId FROM Opportunity WHERE NSP_BidNumber__c = '123' LIMIT 1];
        Opportunity opty = oppList[0];
        opty.NSP_PrimaryProduct__c = 'HRScale';
        opty.StageName = 'Booking';
        try{
            update opty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }
        Test.stopTest();

        // Check for expected errors or state changes
        Opportunity updatedOpportunity = [SELECT Id, StageName FROM Opportunity WHERE Id = :oppList[0].Id];
        System.assertEquals('Booking', updatedOpportunity.StageName, 'Stage should remain unchanged.');
    }

    @isTest
    private static void testValidateOpportunityStageCW() {
        Test.startTest();
        List<Opportunity> oppList = [SELECT Id , OwnerId FROM Opportunity WHERE NSP_BidNumber__c = '123' LIMIT 1];
        Opportunity opty = oppList[0];
        opty.NSP_PrimaryProduct__c = 'HR Consulting Services';
        opty.StageName = 'Closed Won';
        try{
            update opty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }
        Test.stopTest();

        // Check for expected errors or state changes
        Opportunity updatedOpportunity = [SELECT Id, StageName FROM Opportunity WHERE Id = :oppList[0].Id];
        System.assertEquals('Closed Won', updatedOpportunity.StageName, 'Stage should change.');
    }

    @isTest
    private static void testValidateOpportunityStageCL() {
        Test.startTest();
        List<Opportunity> oppList = [SELECT Id , OwnerId FROM Opportunity WHERE NSP_BidNumber__c = '123' LIMIT 1];
        Opportunity opty = oppList[0];
        opty.NSP_PrimaryProduct__c = 'WA';
        opty.StageName = 'Closed Lost';
        try{
            update opty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }
        Test.stopTest();

        // Check for expected errors or state changes
        Opportunity updatedOpportunity = [SELECT Id, StageName FROM Opportunity WHERE Id = :oppList[0].Id];
        System.assertEquals('Prospecting', updatedOpportunity.StageName, 'Stage should remain unchanged.');
    }

    @isTest
    private static void test_evaluateQuoteExistingQuote() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE StageName != NULL AND SBQQ__PrimaryQuote__c != null LIMIT 1][0];
        SBQQ__Quote__c oppQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id LIMIT 1][0];

        Test.startTest();
        NSP_ValidateOpportunityStage.evaluateQuoteExistingQuote( opp , oppQuote );
        Test.stopTest();
    }

    @isTest
    private static void test_getSalesOfficeGroup() {
        List<String> salesOfficeMembership = new List<String>{ '301' };

        Test.startTest();
        NSP_ValidateOpportunityStage.getSalesOfficeGroup( UserInfo.getUserId() , salesOfficeMembership );
        Test.stopTest();
    }

    @isTest
    private static void test_Booleans() {
        Test.startTest();

        Boolean permCheck1 = NSP_ValidateOpportunityStage.hasCLSOOppOwnerPermission;
        Boolean permCheck2 = NSP_ValidateOpportunityStage.hasCLSOOppPermission;
        Boolean permCheck3 = NSP_ValidateOpportunityStage.hasAllowCLMMPerm;
        Boolean permCheck4 = NSP_ValidateOpportunityStage.hasAllowCLRETPerm;
        Boolean permCheck5 = NSP_ValidateOpportunityStage.hasAllowCLInsurancePerm;
        Boolean permCheck6 = NSP_ValidateOpportunityStage.hasAllowCLRecruitingPerm;
        Boolean permCheck7 = NSP_ValidateOpportunityStage.hasAllowCLTechnologyPerm;
    }

    @isTest
    private static void testCheckCondition() {
        Date today = Date.today();
        test.startTest();

        // Test Date
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition(today, 'TODAY', 'EQUALS'));
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition(today, null, 'IS_NOT_BLANK'));
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition(null, null, 'IS_BLANK'));

        // Test Double
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition(1.0, '1.0', 'EQUALS'));
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition(1.0, '2.0', 'DOES_NOT_EQUAL'));
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition(1.0, 'Field Value: NSP_Number_of_Employees__c', 'DOES_NOT_EQUAL'));

        // Test Integer
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition(1, '1', 'EQUALS'));
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition(1, '2', 'DOES_NOT_EQUAL'));
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition(1, '2', 'LESS_THAN_OR_EQUALS'));
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition(3, '2', 'GREATER_THAN_OR_EQUALS'));

        // Test String
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition('test', 'test', 'EQUALS'));
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition('test', 'test2', 'DOES_NOT_EQUAL'));
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition('test22', 'test2', 'CONTAINS'));
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition('test', 'test2', 'DOES_NOT_CONTAIN'));
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition('test2', 'test2', 'IS_IN'));
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition('test', 'test2', 'IS_NOT_IN'));

        // Test Boolean
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition(true, 'true', 'EQUALS'));
        System.assertEquals(true, NSP_ValidateOpportunityStage.checkCondition(false, 'true', 'DOES_NOT_EQUAL'));
        test.stopTest();
    }

    @isTest
    private static void evaluateClosedLost_PublicGroup(){
        test.startTest();
        List<Opportunity> oppList=[Select Id,OWNER.USERROLE.DeveloperName,StageName, NSP_Sales_Office__c FROM Opportunity WHERE NSP_BidNumber__c = '123' LIMIT 1];
        Opportunity oppty = oppList[0];
        List<User> userRecord2List = [SELECT Id FROM User WHERE Email = 'testuser2@insperity.com' Limit 1];
        User userRecord2 = userRecord2List[0];
        userRecord2.UserRoleId = [SELECT Id FROM UserRole WHERE Name= 'District Administrator'][0].Id;
        update userRecord2;
        // adding Users to groups
        List<Group> GroupList =[Select id from Group where Name='0302 Phoenix 2'];
        Group gp1 = GroupList[0];
        GroupMember bpagm = new GroupMember (UserOrGroupId = userRecord2.Id, GroupId = gp1.Id);
        List<GroupMember> groupMemberList= new List<GroupMember>{bpagm};
            // Inserting Group Members
            Insert groupMemberList;

        System.runAs(userRecord2){
            if(oppty!=null){
                try{
                    oppty.StageName='Closed Lost';
                    Update oppty;
                }catch(Exception ex){
                    ex.getStackTraceString();
                }

            }
        }
        test.stopTest();
    }

    @isTest
    private static void evaluateClosedLost_PublicGroup2(){
        test.startTest();
        List<Opportunity> oppList=[Select Id,OWNER.USERROLE.DeveloperName,StageName, NSP_Sales_Office__c FROM Opportunity WHERE NSP_BidNumber__c = '123' LIMIT 1];
        Opportunity oppty = oppList[0];

        List<User> userRecord1List = [SELECT Id FROM User WHERE Email = 'testuser1@insperity.com' Limit 1];
        User userRecord1 = userRecord1List[0];
        userRecord1.NSP_Sales_Office_Membership__c = '302';
        update userRecord1;
        List<User> userRecord2List = [SELECT Id FROM User WHERE Email = 'testuser2@insperity.com' Limit 1];
        User userRecord2 = userRecord2List[0];
        userRecord2.UserRoleId = [SELECT Id FROM UserRole WHERE Name= 'District Administrator'][0].Id;
        update userRecord2;
        // adding Users to groups
        List<Group> GroupList =[Select id from Group where Name='0302 Phoenix 2'];
        Group gp1 = GroupList[0];
        GroupMember bpagm = new GroupMember (UserOrGroupId = userRecord2.Id, GroupId = gp1.Id);
        List<GroupMember> groupMemberList= new List<GroupMember>{bpagm};
            // Inserting Group Members
            Insert groupMemberList;
        System.runAs(userRecord2){
            if(oppty!=null){
                try{
                    oppty.StageName='Closed Lost';
                    Update oppty;
                }catch(Exception ex){
                    ex.getStackTraceString();
                }

            }
        }
        test.stopTest();
    }

    @isTest
    private static void isStageNameNull(){
        test.startTest();

        boolean inserted = false;
        Opportunity opp = new Opportunity(Name = 'Test Opportunity');
        List<Opportunity> oppList = new  List<Opportunity>();
        oppList.add(opp);

        try {
            NSP_ValidateOpportunityStage.validateOpportunityStage(oppList);
            insert oppList;
            inserted = true;
        } catch(Exception e) {
            e.getStackTraceString();
        }

        Assert.areEqual(false, inserted, 'StageName is missing');
        test.stopTest();
    }
}
//