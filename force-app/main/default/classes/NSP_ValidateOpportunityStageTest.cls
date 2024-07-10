/* **************************************************************************************************   
Component Name :  NSP_ValidateOpportunityStageTest class
Version              :  1.0                                                                          
Created Date         :  October 10, 2021                                                             
Function             :  This class is used for Validate Opportunity Stage tests.
Story                :                                                                             
Modification Log     :                                                                               
*   Harsha           October 10, 2021          First Iteration
*
***************************************************************************************************
*/

@isTest
private class NSP_ValidateOpportunityStageTest {
    //Test Setup Method to populate test data
    @testSetup
    private static void setupData(){
        
        //NSP_hotfix_Switch__c setting = new NSP_hotfix_Switch__c();
        //setting.Is_Enabled_WO_WS_Stage_Entry__c = true;
        //insert setting;
        
        Account acnt=NSP_TestHelper.createAccount(true);
        Contact cntct=NSP_TestHelper.createContact(true);

        Opportunity opp=NSP_TestHelper.createOpenOpportunity(acnt.Id,'New Business',false);
        opp.StageName = 'Prospecting';
        opp.NSP_Number_of_Employees__c=12;
        opp.NSP_BidNumber__c='123';
        opp.NSP_PrimaryProduct__c = 'WS';
        opp.NSP_Partner__c=acnt.Id;
        insert opp;

        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId = cntct.Id
        );
        insert ocr;

        Id soldToCheckListRecordTypeId = Schema.SObjectType.NSP_Checklist__c.getRecordTypeInfosByDeveloperName().get('NSP_Sold_to_Paid_Checklist').getRecordTypeId();
        NSP_Checklist__c stpCheckList = new NSP_Checklist__c(
            RecordTypeId = soldToCheckListRecordTypeId,
            NSP_Opportunity__c = opp.Id,
            NSP_Requested_First_Pay_Date__c = system.today(),
            Status__c = 'Completed'
        );
        insert stpCheckList;

        Opportunity opp1=NSP_TestHelper.createOpenOpportunity(acnt.Id,'New Business',false);
        opp1.StageName = 'Proposal';
        opp1.NSP_PrimaryProduct__c = 'WX';
        opp1.NSP_Partner__c=acnt.Id;
        try{            
            insert opp1;
        }catch(Exception ex){
            ex.getStackTraceString();
        }

        Opportunity opp2=NSP_TestHelper.createOpenOpportunity(acnt.Id,'New Product',false);
        opp2.StageName = 'Prospecting';
        opp2.NSP_BidNumber__c='unique123';
        opp2.NSP_PrimaryProduct__c = 'WO';
        try{            
            insert opp2;
        }catch(Exception ex){
            ex.getStackTraceString();
        }

        OpportunityContactRole ocr2 = new OpportunityContactRole(
            OpportunityId = opp2.Id,
            ContactId = cntct.Id
        );
        insert ocr2;

        //Adding Tasks and Events to lists.
        List<SObject> sOList = new List<SObject>();
        Id taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Core_Sales_Task_RT').getRecordTypeId();

        // Test data for Close Lost Scenario
        User userRecordInt = new User(
            ProfileId = [SELECT Profile_ID__c, Profile_Name__c FROM NSP_Profile_Detail__mdt WHERE Profile_Name__c = 'Integration User'][0].Profile_ID__c,
            LastName = 'TestClassUser',
            Email = 'testuserint@insperity.com',
            Username = 'testuserint@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            NSP_Sales_Office_Membership__c = '301',
            LocaleSidKey = 'en_US'
        );
        insert userRecordInt;

        Task taskRec1 = new Task(
            Subject = 'Business Profile Started',
            WhatId = opp.Id,
            NSP_Task_Type__c = 'Core Sales',
            RecordTypeId = taskRecTypeId,
            Status = 'Completed'
        );
        sOList.add(taskRec1);
        
        Task taskRec2 = new Task(
            Subject = 'Bid Sent to Pricing and Review',
            WhatId = opp2.Id,
            NSP_Task_Type__c = 'Core Sales',
            RecordTypeId = taskRecTypeId,
            Status = 'Open'
        );
        sOList.add(taskRec2);
        
        Task taskRec3 = new Task(
            Subject = 'Bid Generated in AIMS',
            WhatId = opp2.Id,
            NSP_Task_Type__c = 'Core Sales',
            RecordTypeId = taskRecTypeId,
            Status = 'Completed'
        );
        sOList.add(taskRec3);
        
        Task taskRecOld = new Task(
            Subject = 'Discovery Call',
            WhatId = opp.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = taskRecTypeId,
            NSP_Task_Subtype__c = 'Client Meeting',
            NSP_Status__c='Completed'
        );
        sOList.add(taskRecOld);
        
        Task taskRecOld3 = new Task(
            Subject = 'WO Business Profile',
            WhatId = opp.Id,
            NSP_Task_Type__c = 'Core Sales',
            RecordTypeId = taskRecTypeId,
            NSP_Task_Subtype__c = 'WO Proposal',
            NSP_Status__c='Open'
        );
        sOList.add(taskRecOld3);
        
        Task taskRecOld2 = new Task(
            Subject = 'Discovery Call',
            WhatId = opp2.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = taskRecTypeId,
            NSP_Task_Subtype__c = 'Client Meeting',
            NSP_Status__c='Open'
        );
        sOList.add(taskRecOld2);

        Id eventRecTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Core_Sales_Event_RT').getRecordTypeId();

        Event eventRecOld = new Event(
            Subject = 'Discovery Call',
            WhatId = opp.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = eventRecTypeId,
            StartDateTime=system.now(),
            EndDateTime=system.now()+( 15/1440),
            NSP_Event_Subtype__c = NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY,
            NSP_Status__c='Open'
        );
        sOList.add(eventRecOld);

        Event eventRec = new Event(
            Subject = 'Discovery Call',
            WhatId = opp2.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = eventRecTypeId,
            StartDateTime=system.now(),
            EndDateTime=system.now()+( 15/1440),
            NSP_Event_Subtype__c = NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY,
            NSP_Status__c='Open'
        );
        sOList.add(eventRec);

        Event eventRec1 = new Event(
            Subject = 'Discovery Call',
            WhatId = opp1.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = eventRecTypeId,
            StartDateTime=system.now(),
            EndDateTime=system.now()+( 15/1440),
            NSP_Event_Subtype__c = NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY,
            NSP_Status__c='Open'
        );
        sOList.add(eventRec1);
        
        Event eventRec2 = new Event(
            Subject = 'Discovery Call',
            WhatId = opp2.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = eventRecTypeId,
            StartDateTime=system.now(),
            EndDateTime=system.now()+( 15/1440),
            NSP_Event_Subtype__c = NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY,
            NSP_Status__c='Completed'
        );
        sOList.add(eventRec2);
        
        //Task and Events Insert
        System.runAs(userRecordInt){
        	insert sOList;
        }
        
        Test.startTest();
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(acnt.Id,'New Product',true);
        objOpprtunity.NSP_BidNumber__c='unique12345';
        update objOpprtunity;
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
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(acnt.Id,objOpprtunity.Id,true);
        // create quote lines
        List<SBQQ__Quoteline__c> qlines = NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        //objQuote.NSP_Billing_Address__c = [SELECT id from NSP_Address__c where NSP_Address_Type__c = 'Bill To' AND NSP_Related_Site__c =: acnt.Id ].Id;
        update objQuote;        

        //insert OpportunityLineItem        
        OpportunityLineItem OLI = new OpportunityLineItem();
        OLI.OpportunityId = objOpprtunity.Id; //Opportunity Id has to be assigned
        OLI.Product2Id = objproduct.Id; //PriceBookEntry Id for that Product should be assigned.
        OLI.Quantity = 1;
        OLI.UnitPrice = 1;
        insert OLI;

        // Test data for Close Lost Scenario
        User userRecord1 = new User(
            ProfileId = [SELECT Profile_ID__c, Profile_Name__c FROM NSP_Profile_Detail__mdt WHERE Profile_Name__c = 'System Administrator'][0].Profile_ID__c,
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

        Opportunity opp3=NSP_TestHelper.createOpenOpportunity(acnt.Id,'New Business',false);
        opp3.StageName = 'Discovery';
        opp3.NSP_Number_of_Employees__c=200;
        opp3.NSP_BidNumber__c='123987';
        opp3.NSP_PrimaryProduct__c = 'WO';
        opp3.NSP_Partner__c=acnt.Id;
        opp3.ownerid= userRecord1.id;
        opp3.NSP_Sales_Office__c = '302';
        opp3.NSP_Mid_Market_Sales_Email__c='test@test.com';
        insert opp3; 
        OpportunityTeamMember oppMember = new OpportunityTeamMember();
        oppMember.OpportunityId = opp3.id;
        oppMember.UserId = UserInfo.getUserId();
        oppMember.TeamMemberRole = 'Business Performance Advisor';
        insert oppMember;   
        Test.stopTest();
        User userRecord2 = new User(
            ProfileId = [SELECT Profile_ID__c, Profile_Name__c FROM NSP_Profile_Detail__mdt WHERE Profile_Name__c = 'System Administrator'][0].Profile_ID__c,
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
    // Test for validations when Opportunity stage is set to Closing
    @isTest
    private static void checkOpptyStage(){
        test.startTest();
        NSP_hotfix_Switch__c setting = new NSP_hotfix_Switch__c();
        setting.Is_Enabled_WO_WS_Stage_Entry__c = true;
        insert setting;

        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE StageName != NULL AND NSP_PrimaryProduct__c = 'WS' limit 1];
        Opportunity oppty = oppList[0];
        oppty.StageName='Analysis';
        try{
            update oppty; 
        }catch(Exception ex){
            ex.getStackTraceString();
        }

        oppty.NSP_PrimaryProduct__c = '';
        oppty.Type = '';
        oppty.NSP_Bid_Status__c = 'Approved';
        oppty.StageName = 'Proposal';
        try{
            update oppty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }

        oppty.StageName = 'Closing';
        try{
            update oppty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }

        oppty.StageName = 'Closed Won';
        try{
            update oppty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }
        test.stopTest();
        System.assertEquals('Closed Won', oppty.StageName);
    }

    @isTest
    private static void checkOpptyStage2(){
        test.startTest();
        NSP_hotfix_Switch__c setting = new NSP_hotfix_Switch__c();
        setting.Is_Enabled_WO_WS_Stage_Entry__c = true;
        insert setting;

        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE StageName != NULL and NSP_PrimaryProduct__c = 'WX' limit 1];
        Opportunity oppty = oppList[0];
        oppty.NSP_Number_of_Employees__c=25;
        oppty.StageName='Analysis';        
        oppty.Type = 'New Product';
        try{
            update oppty; 
        }catch(Exception ex){
            ex.getStackTraceString();
        }

        oppty.NSP_PrimaryProduct__c = '';
        oppty.Type = '';
        oppty.StageName = 'Proposal';
        try{
            update oppty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }

        oppty.StageName = 'Closing';
        try{
            update oppty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }

        oppty.StageName = 'Closed Won';
        try{
            update oppty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }
        test.stopTest();
        System.assertEquals('Closed Won', oppty.StageName);
    }
    // Test for validations when Opportunity stage is set to Closing
    @isTest
    private static void checkOpptyStage3(){
        test.startTest();
        NSP_hotfix_Switch__c setting = new NSP_hotfix_Switch__c();
        setting.Is_Enabled_WO_WS_Stage_Entry__c = false;
        insert setting;

        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE StageName != NULL AND NSP_PrimaryProduct__c = 'WS' limit 1];
        Opportunity oppty = oppList[0];
        oppty.StageName='Analysis';
        try{
            update oppty; 
        }catch(Exception ex){
            ex.getStackTraceString();
        }

        oppty.NSP_PrimaryProduct__c = '';
        oppty.Type = '';
        oppty.NSP_Bid_Status__c = 'Approved';
        oppty.StageName = 'Proposal';
        try{
            update oppty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }

        oppty.StageName = 'Closing';
        try{
            update oppty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }

        oppty.StageName = 'Closed Won';
        try{
            update oppty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }
        test.stopTest();
        System.assertEquals('Closed Won', oppty.StageName);
    }

    @isTest
    private static void checkOpptyStage4(){
        test.startTest();
        NSP_hotfix_Switch__c setting = new NSP_hotfix_Switch__c();
        setting.Is_Enabled_WO_WS_Stage_Entry__c = false;
        insert setting;

        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE StageName != NULL and NSP_PrimaryProduct__c = 'WX' limit 1];
        Opportunity oppty = oppList[0];
        oppty.NSP_Number_of_Employees__c=25;
        oppty.StageName='Analysis';        
        oppty.Type = 'New Product';
        try{
            update oppty; 
        }catch(Exception ex){
            ex.getStackTraceString();
        }

        oppty.NSP_PrimaryProduct__c = '';
        oppty.Type = '';
        oppty.StageName = 'Proposal';
        try{
            update oppty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }

        oppty.StageName = 'Closing';
        try{
            update oppty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }

        oppty.StageName = 'Closed Won';
        try{
            update oppty;
        }catch(Exception ex){
            ex.getStackTraceString();
        }
        test.stopTest();
        System.assertEquals('Closed Won', oppty.StageName);
    }
    
    // Test for open Discovery activity on Discovery stage
    @isTest
    private static void checkOpenDiscoveryActivities(){
        test.startTest();
        NSP_hotfix_Switch__c setting = new NSP_hotfix_Switch__c();
        setting.Is_Enabled_WO_WS_Stage_Entry__c = true;
        insert setting;

        List<Opportunity> oppList = [SELECT Id, StageName FROM Opportunity WHERE NSP_BidNumber__c = 'unique123' limit 1];
        Opportunity oppty = oppList[0];
        
        if(oppty!=null){
            oppty.StageName='Discovery';
            try{
                update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
        }
        test.stopTest();
        System.assertEquals('Discovery', oppty.StageName);
    }
    
    // Test for completed Discovery activity on Data Collection stage
    @isTest
    private static void checkCompletedDiscoveryActivities(){
        test.startTest();
        NSP_hotfix_Switch__c setting = new NSP_hotfix_Switch__c();
        setting.Is_Enabled_WO_WS_Stage_Entry__c = true;
        insert setting;

        List<Opportunity> oppList = [SELECT Id, StageName, NSP_PrimaryProduct__c FROM Opportunity WHERE NSP_BidNumber__c = 'unique123' limit 1];
        Opportunity oppty = oppList[0];

        if(oppty!=null){
            oppty.StageName='Data Collection';
            oppty.NSP_PrimaryProduct__c = '';
            try{
                update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
            oppty.NSP_PrimaryProduct__c = 'WO';
            try{
                update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
        }
        test.stopTest();
        System.assertEquals('Data Collection', oppty.StageName);
    }
    
    @isTest
    private static void checkAnalysisStage(){
        test.startTest();
        NSP_hotfix_Switch__c setting = new NSP_hotfix_Switch__c();
        setting.Is_Enabled_WO_WS_Stage_Entry__c = true;
        insert setting;

        List<Opportunity> oppList = [SELECT Id, StageName, NSP_Bid_Status__c, NSP_BidNumber__c FROM Opportunity WHERE NSP_BidNumber__c = 'unique123' limit 1];
        Opportunity oppty = oppList[0];

        if(oppty!=null){
            oppty.StageName='Analysis';
            try{
                update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
        }
        test.stopTest();
        System.assertEquals('Analysis', oppty.StageName);
    }
    
    @isTest
    private static void checkAnalysisStageOld(){
        test.startTest();
        List<Opportunity> oppList = [SELECT Id, StageName, NSP_Bid_Status__c, NSP_BidNumber__c FROM Opportunity WHERE NSP_BidNumber__c = 'unique123' limit 1];
        Opportunity oppty = oppList[0];

        if(oppty!=null){
            oppty.StageName='Analysis';
            try{
                update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
        }
        test.stopTest();
        System.assertEquals('Analysis', oppty.StageName);
    }
    
    @isTest
    private static void checkProposalStage(){
        test.startTest();
        NSP_hotfix_Switch__c setting = new NSP_hotfix_Switch__c();
        setting.Is_Enabled_WO_WS_Stage_Entry__c = true;
        insert setting;

        List<Opportunity> oppList = [SELECT Id,OwnerId,NSP_Sales_Office__c FROM Opportunity WHERE NSP_BidNumber__c = 'unique123' limit 1];
        Opportunity oppty = oppList[0];

        if(oppty!=null){
            oppty.StageName='Proposal';
            oppty.NSP_Bid_Status__c = 'Approved';
            oppty.NSP_PrimaryProduct__c = 'WO';
            oppty.Type = 'New Product';
            try{
                update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
        }
        test.stopTest();
        System.assertEquals('Proposal', oppty.StageName);
    }
    
    @isTest
    private static void checkProposalStageOld(){
        test.startTest();
        List<Opportunity> oppList = [SELECT Id,OwnerId,NSP_Sales_Office__c FROM Opportunity WHERE NSP_BidNumber__c = 'unique123' limit 1];
        Opportunity oppty = oppList[0];

        if(oppty!=null){
            oppty.StageName='Proposal';
            oppty.NSP_Bid_Status__c = 'Approved';
            oppty.Type = 'New Product';
            try{
                update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
        }
        test.stopTest();
        System.assertEquals('Proposal', oppty.StageName);
    }

    @isTest
    private static void checkQuoteCriteria(){
        test.startTest();
        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE NSP_BidNumber__c='unique12345' limit 1];
        Opportunity oppty = oppList[0];

        if(oppty!=null){
            oppty.NSP_PrimaryProduct__c = 'WX';
            oppty.StageName='Proposal';
            oppty.NSP_BidNumber__c = '';
            oppty.Type = 'New Product';
            try{
                update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }

            oppty.NSP_PrimaryProduct__c = 'HR Consulting Services';
            try{
                update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
        }
        test.stopTest();
        System.assertEquals('Proposal', oppty.StageName);
    }

    @isTest
    private static void checkQuoteCriteria1(){
        test.startTest();
        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE NSP_BidNumber__c='unique12345' limit 1];
        Opportunity oppty = oppList[0];
        if(oppty!=null){
            oppty.NSP_PrimaryProduct__c = 'HR Consulting Services';
            oppty.StageName='Proposal';
            oppty.NSP_BidNumber__c = '';
            oppty.Type = 'New Product';
            try{
                update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
        }
        test.stopTest();
        System.assertEquals('Proposal', oppty.StageName);
    }

    @isTest
    private static void checkClosingStage(){
        test.startTest();
        NSP_hotfix_Switch__c setting = new NSP_hotfix_Switch__c();
        setting.Is_Enabled_WO_WS_Stage_Entry__c = true;
        insert setting;

        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE NSP_BidNumber__c='unique12345' limit 1];
        Opportunity oppty = oppList[0];
        if(oppty!=null){
            oppty.NSP_PrimaryProduct__c = 'WS';
            oppty.StageName='Closing';
            oppty.NSP_Order_Generated__c = true;
            oppty.Type = 'New Product';
            try{
                update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
        }
        test.stopTest();
        System.assertEquals('Closing', oppty.StageName);
    }

    @isTest
    private static void checkClosingStage2(){
        test.startTest();
        NSP_hotfix_Switch__c setting = new NSP_hotfix_Switch__c();
        setting.Is_Enabled_WO_WS_Stage_Entry__c = true;
        insert setting;

        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE NSP_BidNumber__c='unique12345' limit 1];
        Opportunity oppty = oppList[0];
        if(oppty!=null){
            oppty.NSP_PrimaryProduct__c = 'HR Consulting Services';
            oppty.StageName='Closing';
            oppty.NSP_Order_Generated__c = false;
            oppty.Type = 'New Product';
            try{
                update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
        }
        test.stopTest();
        System.assertEquals('Closing', oppty.StageName);
    }

    @isTest
    private static void checkClosingStageOld(){
        test.startTest();

        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE NSP_BidNumber__c='unique12345' limit 1];
        Opportunity oppty = oppList[0];
        if(oppty!=null){
            oppty.NSP_PrimaryProduct__c = 'HR Consulting Services';
            oppty.StageName='Closing';
            oppty.NSP_Order_Generated__c = false;
            oppty.Type = 'New Product';
            try{
                update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
        }
        test.stopTest();
        System.assertEquals('Closing', oppty.StageName);
    }

    @isTest
    private static void evalClosedWonStageCriteria(){
        test.startTest();
        NSP_hotfix_Switch__c setting = new NSP_hotfix_Switch__c();
        setting.Is_Enabled_WO_WS_Stage_Entry__c = true;
        insert setting;

        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE NSP_BidNumber__c='unique123' limit 1];
        Opportunity oppty = oppList[0];
        if(oppty!=null){
            oppty.NSP_PrimaryProduct__c = 'WO';
            oppty.StageName='Closed Won';
            oppty.Type = 'New Product';
            try{
                update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
        }
        test.stopTest();
        System.assertEquals('Closed Won', oppty.StageName);
    }

    @isTest
    private static void evalClosedWonStageCriteriaOld(){
        test.startTest();
        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE NSP_BidNumber__c='unique123' limit 1];
        Opportunity oppty = oppList[0];
        if(oppty!=null){
            oppty.NSP_PrimaryProduct__c = 'WO';
            oppty.StageName='Closed Won';
            oppty.Type = 'New Product';
            try{
                update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
        }
        test.stopTest();
        System.assertEquals('Closed Won', oppty.StageName);
    }

    @isTest
    private static void checkclosedWonStage(){
        test.startTest();
        List<OpportunityLineItem> opptyLineItemList = [SELECT Name,Opportunity.accountId,NSP_Product_Name__c,NSP_AccountId__c,NSP_AccountName__c,NSP_AssetProductLine__c,
                                                       NSP_EmployeesAtSignature__c,NSP_Pricing_Model__c,
                                                       NSP_Reserve__c,NSP_TransitionType__c,
                                                       Product2Id,Quantity,UnitPrice,NSP_Opportunity_Booked_Date__c,NSP_Signed_Delivery_Order_Date__c,
                                                       NSP_ProductType__c,NSP_ProductBundle__c,//if its required on Asset then we create a formula for it
                                                       NSP_Original_Sold_EE_Count__c,NSP_Primary_Product__c from OpportunityLineItem limit 1];

        New NSP_SrcToTargetObjectDataMover(null,'OppAsset') ;//initialize the class
        List<SObject> newlist = NSP_SrcToTargetObjectDataMover.getSourceDatainTarget( opptyLineItemList);
        test.stopTest();
        system.assertNotEquals(null, newlist);
    }

    @isTest
    private static void checkclosedWonStage1(){
        test.startTest();
        List<OpportunityLineItem> opptyLineItemList = [SELECT Name,Opportunity.accountId,NSP_Product_Name__c,NSP_AccountId__c,NSP_AccountName__c,
                                                       Product2Id,Quantity,UnitPrice,NSP_Opportunity_Booked_Date__c,NSP_Signed_Delivery_Order_Date__c,
                                                       NSP_ProductType__c,NSP_ProductBundle__c,//if its required on Asset then we create a formula for it
                                                       NSP_Original_Sold_EE_Count__c,NSP_Primary_Product__c from OpportunityLineItem limit 1];
        
        
        List<String> fieldsToQueryList = new List<String>();
        fieldsToQueryList.add('Id');
        Map<String,String> filterMap = new Map<String,String>();
        filterMap.put('Name','testAsset, test Asset1');
        New NSP_SrcToTargetObjectDataMover(null,'OppAsset') ;
        try{
            NSP_SrcToTargetObjectDataMover.constructSourceQuery(fieldsToQueryList,filterMap);
        }catch(Exception ex){
            ex.getStackTraceString();
        }
        test.stopTest();
        system.assertEquals('Id',fieldsToQueryList[0]);
    }
    @isTest
    private static void evaluateClosedLostStageCriteria_Test(){
        test.startTest();
        List<Opportunity> oppList=[Select Id,OWNER.USERROLE.DeveloperName,StageName FROM Opportunity WHERE StageName='Discovery' Limit 1];
        Opportunity oppty = oppList[0];
        
        if(oppty!=null){
            oppty.StageName='Closed Lost';
            //oppty.Loss_Reason__c='';
            try{
                update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
            
        }
        test.stopTest();
    }
    @isTest
    private static void evaluateClosedLostStageCriteria2_Test(){
        test.startTest();
        List<Opportunity> oppList=[Select Id,OWNER.USERROLE.DeveloperName,StageName FROM Opportunity WHERE StageName='Discovery' and NSP_BidNumber__c='123987' Limit 1];
        Opportunity oppty = oppList[0];
        
        if(oppty!=null){
            try{            
                oppty.StageName='Closed Lost';
                //oppty.Loss_Reason__c='';
                Update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
            
        }
        test.stopTest();
    }
    @isTest
    private static void evaluateClosedLost_BPC_Test(){
        test.startTest();
        List<Opportunity> oppList=[Select Id,OWNER.USERROLE.DeveloperName,StageName FROM Opportunity WHERE StageName='Discovery' and NSP_BidNumber__c='123987' Limit 1];
        Opportunity oppty = oppList[0];
        
        List<User> userRecord1List = [SELECT Id FROM User WHERE Email = 'testuser1@insperity.com' Limit 1];
        User userRecord1 = userRecord1List[0];
        userRecord1.UserRoleId = [SELECT Id FROM UserRole WHERE Name= 'Business Performance Consultant'][0].Id;
        update userRecord1;
        List<User> userRecord2List = [SELECT Id FROM User WHERE Email = 'testuser2@insperity.com' Limit 1];
        User userRecord2 = userRecord2List[0];
        userRecord2.UserRoleId = [SELECT Id FROM UserRole WHERE Name= 'MidMarket Administrator'][0].Id;
        update userRecord2;
        System.runAs(userRecord2){
            if(oppty!=null){
                try{            
                    oppty.StageName='Closed Lost';
                    //oppty.Loss_Reason__c='';
                    Update oppty;
                }catch(Exception ex){
                    ex.getStackTraceString();
                }
                
            }
        }
        test.stopTest();
    }
    @isTest
    private static void evaluateClosedLost_RSC_Test(){
        test.startTest();
        List<Opportunity> oppList=[Select Id,OWNER.USERROLE.DeveloperName,StageName FROM Opportunity WHERE StageName='Discovery' and NSP_BidNumber__c='123987' Limit 1];
        Opportunity oppty = oppList[0];
        List<User> userRecord1List = [SELECT Id FROM User WHERE Email = 'testuser1@insperity.com' Limit 1];
        User userRecord1 = userRecord1List[0];
        userRecord1.UserRoleId = [SELECT Id FROM UserRole WHERE Name= 'Retirement Sales Consultant'][0].Id;
        update userRecord1;
        List<User> userRecord2List = [SELECT Id FROM User WHERE Email = 'testuser2@insperity.com' Limit 1];
        User userRecord2 = userRecord2List[0];
        userRecord2.UserRoleId = [SELECT Id FROM UserRole WHERE Name= 'Retirement Sales Manager'][0].Id;
        update userRecord2;
        System.runAs(userRecord2){
            if(oppty!=null){
                try{            
                    oppty.StageName='Closed Lost';
                    //oppty.Loss_Reason__c='';
                    Update oppty;
                }catch(Exception ex){
                    ex.getStackTraceString();
                }
                
            }
        }
        test.stopTest();
    }
    @isTest
    private static void evaluateClosedLost_IC_Test(){
        test.startTest();
        List<Opportunity> oppList=[Select Id,OWNER.USERROLE.DeveloperName,StageName FROM Opportunity WHERE StageName='Discovery' and NSP_BidNumber__c='123987' Limit 1];
        Opportunity oppty = oppList[0];
        List<User> userRecord1List = [SELECT Id FROM User WHERE Email = 'testuser1@insperity.com' Limit 1];
        User userRecord1 = userRecord1List[0];
        userRecord1.UserRoleId = [SELECT Id FROM UserRole WHERE Name= 'Insurance Sales'][0].Id;
        update userRecord1;
        List<User> userRecord2List = [SELECT Id FROM User WHERE Email = 'testuser2@insperity.com' Limit 1];
        User userRecord2 = userRecord2List[0];
        userRecord2.UserRoleId = [SELECT Id FROM UserRole WHERE Name= 'Insurance Sales Manager'][0].Id;
        update userRecord2;
        System.runAs(userRecord2){
            if(oppty!=null){
                try{            
                    oppty.StageName='Closed Lost';
                    //oppty.Loss_Reason__c='';
                    Update oppty;
                }catch(Exception ex){
                    ex.getStackTraceString();
                }
                
            }
        }
        test.stopTest();
    }
    @isTest
    private static void evaluateClosedLost_RS_Test(){
        test.startTest();
        List<Opportunity> oppList=[Select Id,OWNER.USERROLE.DeveloperName,StageName FROM Opportunity WHERE StageName='Discovery' and NSP_BidNumber__c='123987' Limit 1];
        Opportunity oppty = oppList[0];
        
        List<User> userRecord1List = [SELECT Id FROM User WHERE Email = 'testuser1@insperity.com' Limit 1];
        User userRecord1 = userRecord1List[0];
        userRecord1.UserRoleId = [SELECT Id FROM UserRole WHERE Name= 'Recruiting Sales'][0].Id;
        update userRecord1;
        List<User> userRecord2List = [SELECT Id FROM User WHERE Email = 'testuser2@insperity.com' Limit 1];
        User userRecord2 = userRecord2List[0];
        userRecord2.UserRoleId = [SELECT Id FROM UserRole WHERE Name= 'Recruiting Manager'][0].Id;
        update userRecord2;
        System.runAs(userRecord2){
            if(oppty!=null){
                try{            
                    oppty.StageName='Closed Lost';
                    //oppty.Loss_Reason__c='';
                    Update oppty;
                }catch(Exception ex){
                    ex.getStackTraceString();
                }
                
            }
        }
        test.stopTest();
    }
    @isTest
    private static void evaluateClosedLost_TS_Test(){
        test.startTest();
        List<Opportunity> oppList=[Select Id,OWNER.USERROLE.DeveloperName,StageName FROM Opportunity WHERE StageName='Discovery' and NSP_BidNumber__c='123987' Limit 1];
        Opportunity oppty = oppList[0];
        
        List<User> userRecord1List = [SELECT Id FROM User WHERE Email = 'testuser1@insperity.com' Limit 1];
        User userRecord1 = userRecord1List[0];
        userRecord1.UserRoleId = [SELECT Id FROM UserRole WHERE Name= 'Technology Sales'][0].Id;
        update userRecord1;
        List<User> userRecord2List = [SELECT Id FROM User WHERE Email = 'testuser2@insperity.com' Limit 1];
        User userRecord2 = userRecord2List[0];
        userRecord2.UserRoleId = [SELECT Id FROM UserRole WHERE Name= 'BPS Sales Manager'][0].Id;
        update userRecord2;
        System.runAs(userRecord2){
            if(oppty!=null){
                try{            
                    oppty.StageName='Closed Lost';
                    //oppty.Loss_Reason__c='';
                    Update oppty;
                }catch(Exception ex){
                    ex.getStackTraceString();
                }
                
            }
        }
        test.stopTest();
    }
    @isTest
    private static void evaluateClosedLost_AS_Test(){
        test.startTest();
        List<Opportunity> oppList=[Select Id,OWNER.USERROLE.DeveloperName,StageName FROM Opportunity WHERE StageName='Discovery' and NSP_BidNumber__c='123987' Limit 1];
        Opportunity oppty = oppList[0];
        List<User> userRecord2List = [SELECT Id FROM User WHERE Email = 'testuser2@insperity.com' Limit 1];
        User userRecord2 = userRecord2List[0];
        userRecord2.UserRoleId = [SELECT Id FROM UserRole WHERE Name= 'MidMarket Administrator'][0].Id;
        update userRecord2;
        
        System.runAs(userRecord2){
            if(oppty!=null){
                try{            
                    oppty.StageName='Closed Lost';
                    //oppty.Loss_Reason__c='';
                    Update oppty;
                }catch(Exception ex){
                    ex.getStackTraceString();
                }
                
            }
        }
        test.stopTest();
    }
    @isTest
    private static void evaluateClosedLost_PublicGroup(){
        test.startTest();
        List<Opportunity> oppList=[Select Id,OWNER.USERROLE.DeveloperName,StageName, NSP_Sales_Office__c FROM Opportunity WHERE StageName='Discovery' and NSP_BidNumber__c='123987' Limit 1];
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
                    //oppty.Loss_Reason__c='';
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
        List<Opportunity> oppList=[Select Id,OWNER.USERROLE.DeveloperName,StageName, NSP_Sales_Office__c FROM Opportunity WHERE StageName='Discovery' and NSP_BidNumber__c='123987' Limit 1];
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
                    //oppty.Loss_Reason__c='';
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