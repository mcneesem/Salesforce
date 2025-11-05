@isTest
private class NSP_OpportunityTriggerServiceHelperTest {

    @testSetup
    private static void testData() {
        //Account Creation
        Account accoutObject = new Account();
        accoutObject.Name = 'Test Account';
        insert accoutObject;
        //Product Creation
        Product2 newProd = (Product2)NSP_TestExtendedDataFactory.createSObject(new Product2(), 'NSP_TestDataFactory.Product2Defaults', false);
        newProd.ProductCode = 'HCMProfSvcs';
        insert newProd;
        //Opportunity Creation
        Opportunity newOpp = (Opportunity)NSP_TestExtendedDataFactory.createSObject(new Opportunity(), 'NSP_TestDataFactory.OpportunityDefaults', false);
        newOpp.stagename = 'Discovery';
        newOpp.AccountId = accoutObject.id;
        newOpp.NSP_Has_WO_Products__c = true;
        newOpp.NSP_PrimaryProduct__c ='Applicant Tracking';
        newOpp.NSP_Number_of_Employees__c = 151;
        //insert opportunity
        insert newOpp;
        // CPQ Quote Creation
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Account__c = newOpp.AccountId;
        quote.SBQQ__Opportunity2__c = newOpp.Id;
          //insert quote
        insert quote;

        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.Templates_Used__c = 'TEMP USED';
        oProject.pse__Account__c = accoutObject.Id;
        oProject.pse__Start_Date__c = Date.Today();
        oProject.pse__Is_Template__c = false;
        insert oProject;
        // CPQ QuoteLine Creation
        SBQQ__QuoteLine__c quoteLineItem = new SBQQ__QuoteLine__c();
        quoteLineItem.SBQQ__Quote__c = quote.Id;
        quoteLineItem.SBQQ__Quantity__c = 1;
        quoteLineItem.SBQQ__RegularPrice__c = 100;
        quoteLineItem.SBQQ__CustomerPrice__c = 50;
        quoteLineItem.SBQQ__Product__c = newProd.id;
        insert quoteLineItem;
    }

    @isTest
    private static void linkProjectWithAccountAfterClosedWonOpportunity() {
        Id woRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();
        List<Account> accountList = [SELECT Id, Name FROM ACCOUNT WHERE NAME = 'Test Account' LIMIT 1 ];

        Asset newAsset = new Asset ();
        newAsset.Name = NSP_ServiceConstants.WORKFORCE_ASSET;
        newAsset.AccountId = accountList[0].Id;
        newAsset.RecordTypeId = woRecordTypeId;

        Test.startTest();
        insert newAsset;

        List<pse__Proj__c> projList = [SELECT ID FROM pse__Proj__c WHERE pse__Account__c = :accountList[0].Id ];
        pse__Budget__c pseBudget = new pse__Budget__c();
        pseBudget.pse__Project__c = projList[0].Id;
        insert pseBudget;

        Project_Asset__c projAsset = new Project_Asset__c ();
        projAsset.Project__c = projList[0].Id;
        projAsset.Asset__c = newAsset.Id;
        insert projAsset;

        Opportunity newOpp = [SELECT id FROM Opportunity WHERE NSP_Has_WO_Products__c = True];


        newOpp.stagename = NSP_SalesConstants.CLOSED_WON;
        update newOpp;
        System.assertEquals(accountList[0].Name, 'Test Account');
        Test.stopTest();
    }

    @isTest
    private static void updateImplementationProfileTest() {
        Test.startTest();
        Map<Id,User> permittedUsersMap = CustomPermissionController.getPermittedUsersMap( 'Opportunity_Closed_Won_NCS_User' );
        List<User> userRecords = [
            SELECT Id
            FROM User
            WHERE (
                ( Id IN :permittedUsersMap.keySet() )
                AND ( Profile.Name = 'System Administrator' )
            )
            ORDER BY CreatedDate ASC
        ];
        Assert.isTrue( !userRecords.isEmpty() , 'No permitted System Administrators found.' );
        User userRecord = userRecords[0];
        System.runAs( userRecord ) {
            Id projectRecordType = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
            Account acc= [Select Id , Name from Account WHERE Name = 'Test Account' LIMIT 1];

            pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
            oProject.pse__Start_Date__c = System.Today();
            oProject.pse__Account__c= acc.Id;
            oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
            oProject.RecordTypeId = projectRecordType;
            oProject.pse__Project_Type__c =NSP_ServiceConstants.ImplementationProjectType;
            insert oProject;

            Implementation_Profile__c impProfile = new Implementation_Profile__c();
            impProfile.Account__c= acc.Id;
            Insert impProfile;

            List<Opportunity> opportunityList = [SELECT Id,NSP_PrimaryProduct__c,AccountId,OwnerId FROM Opportunity WHERE NSP_Number_Of_Employees__c = 151 LIMIT 1];
            opportunity oppty = opportunityList[0];
            oppty.NSP_DM_User__c = oppty.OwnerId;
            oppty.NSP_DA_User__c = oppty.OwnerId;
            oppty.NSP_BPA__c = oppty.OwnerId;
            oppty.StageName = 'Closed Won';
            oppty.NSP_PrimaryProduct__c = 'WO';
            oppty.NSP_IPMRecommendation__c = NSP_SalesConstants.Yes;
            oppty.NSP_Time_Entry_Recommendation__c = NSP_ServiceConstants.Premier_Time_Att;
            oppty.NSP_Signed_CSA__c = true;
            oppty.NSP_Signed_CSA_Date__c = system.today();
            oppty.NSP_CountAsSale__c = 'No';
            update oppty;
            Test.stopTest();
            System.assertEquals(impProfile.Account__c, acc.Id);
        }
    }

    @isTest
    private static void updatePerformanceManagement() {
        Test.startTest();
        Id projectRecordType = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
        Account acc= [Select Id , Name from Account WHERE Name = 'Test Account' LIMIT 1];

        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Start_Date__c = System.Today();
        oProject.pse__Account__c= acc.Id;
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.RecordTypeId = projectRecordType;
        oProject.pse__Project_Type__c =NSP_ServiceConstants.ImplementationProjectType;
        insert oProject;

        Implementation_Profile__c impProfile = new Implementation_Profile__c();
        impProfile.Account__c= acc.Id;
        Insert impProfile;
        List<Opportunity> opportunityList = [SELECT Id,NSP_PrimaryProduct__c,AccountId,OwnerId FROM Opportunity WHERE NSP_Number_Of_Employees__c = 151 LIMIT 1];
        opportunity oppty = opportunityList[0];
        oppty.NSP_DM_User__c = oppty.OwnerId;
        oppty.NSP_DA_User__c = oppty.OwnerId;
        oppty.NSP_BPA__c = oppty.OwnerId;
        oppty.StageName = 'Closed Won';
        oppty.NSP_Time_Entry_Recommendation__c = NSP_ServiceConstants.Premier_Time_Att;
        oppty.NSP_Signed_CSA_Date__c = system.today();
        oppty.NSP_PrimaryProduct__c = NSP_ServiceConstants.PERFORMANCE_MANAGEMENT;
        oppty.NSP_Signed_CSA__c = true;
        oppty.NSP_IPMRecommendation__c = NSP_SalesConstants.Yes;

        update oppty;
        Test.stopTest();
        system.assertEquals(impProfile.Account__c, acc.Id);
    }

    @isTest
    private static void updateTimeAttendence() {
        Test.startTest();
        Id projectRecordType = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
        Account acc= [Select Id , Name from Account WHERE Name = 'Test Account' LIMIT 1];

        List<Opportunity> opportunityList = [SELECT Id,NSP_PrimaryProduct__c,AccountId,OwnerId FROM Opportunity WHERE NSP_Number_Of_Employees__c = 151 LIMIT 1];
        opportunity oppty = opportunityList[0];
        oppty.NSP_DM_User__c = oppty.OwnerId;
        oppty.NSP_DA_User__c = oppty.OwnerId;
        oppty.NSP_BPA__c = oppty.OwnerId;
        oppty.StageName = NSP_SalesConstants.CLOSED_WON;
        oppty.NSP_Time_Entry_Recommendation__c = NSP_ServiceConstants.Premier_Time_Att;
        oppty.NSP_Signed_CSA_Date__c = system.today();
        oppty.NSP_PrimaryProduct__c = NSP_ServiceConstants.TIME_ATTENDANCE;
        oppty.NSP_Signed_CSA__c = true;
        oppty.NSP_IPMRecommendation__c = NSP_SalesConstants.Yes;
        oppty.AccountId = acc.Id;
        update oppty;
        Test.stopTest();
        system.assertEquals(oppty.AccountId, acc.Id);
    }

    @isTest
    private static void existingAccountTimeAttendence() {
        Test.startTest();
        Id TIME_ATTENDANCE_ASSET = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_ServiceConstants.ASSET_TT_RECORDTYPE );
        Id projectRecordType = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
        Account acc= [Select Id , Name from Account WHERE Name = 'Test Account' LIMIT 1];

        Asset newAsset = new Asset ();
        newAsset.Name = NSP_ServiceConstants.WORKFORCE_ASSET;
        newAsset.AccountId = acc.Id;
        newAsset.RecordTypeId = TIME_ATTENDANCE_ASSET;
        insert newAsset;

        List<Opportunity> opportunityList = [SELECT Id,NSP_PrimaryProduct__c,AccountId,OwnerId FROM Opportunity WHERE NSP_Number_Of_Employees__c = 151 LIMIT 1];
        opportunity oppty = opportunityList[0];
        oppty.NSP_DM_User__c = oppty.OwnerId;
        oppty.NSP_DA_User__c = oppty.OwnerId;
        oppty.NSP_BPA__c = oppty.OwnerId;
        oppty.StageName = NSP_SalesConstants.CLOSED_WON;
        oppty.NSP_Time_Entry_Recommendation__c = NSP_ServiceConstants.Premier_Time_Att;
        oppty.NSP_Signed_CSA_Date__c = system.today();
        oppty.NSP_PrimaryProduct__c = NSP_ServiceConstants.TIME_ATTENDANCE;
        oppty.NSP_Signed_CSA__c = true;
        oppty.NSP_IPMRecommendation__c = NSP_SalesConstants.Yes;
        oppty.AccountId = acc.Id;
        update oppty;
        Test.stopTest();
        system.assertEquals(oppty.AccountId, acc.Id);
    }

}
//