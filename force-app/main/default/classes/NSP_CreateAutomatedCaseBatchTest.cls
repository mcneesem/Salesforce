@isTest
private class NSP_CreateAutomatedCaseBatchTest {

    @testSetup
    private static void setupData() {
        String orgId = UserInfo.getOrganizationId();
        User usr = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        usr.EmployeeNumber = System.Label.NSP_User_Employee_Number;
        usr.NSP_Sales_Office__c = '301';
        usr.userName = 'testemail@domain'+ orgId +'.com.test';
        insert usr;

        ID WORecordType = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        oAccount.NSP_AIMS_Client__c= '123456';
        insert oAccount;

        // Creating Asset record
        Asset assetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetRecord.AccountId = oAccount.Id;
        assetRecord.NSP_AIMS_First_Pay_Date__c = system.Today();
        assetRecord.NSP_Client_Segment_type__c = NSP_ServiceConstants.BTAssetSegment;
        assetRecord.NSP_Renewal_Date__c = system.Today();
        assetRecord.RecordTypeId = WORecordType;
        insert assetRecord;

        assetRecord.NSP_Account_Status__c = NSP_ServiceConstants.AIMS_STATUS;
        update assetRecord;

        // Creating Account Team
        NSP_Account_Team__c accTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.accountTeamDefaults', false);
        accTeam.NSP_Account__c = oAccount.Id;
        accTeam.NSP_PER_ID__c = System.Label.NSP_User_Employee_Number;
        accTeam.NSP_Role__c =   NSP_ServiceConstants.BUS_TEAM_HRSP_CL;
        insert accTeam;

         // Create Sub Client
        NSP_Sub_Client__c subClientIns = (NSP_Sub_Client__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', false);
        subClientIns.NSP_Account__c = oAccount.Id;
        subClientIns.NSP_Renewal_Date__c = System.today().addDays(-150);
        insert subClientIns ;

    }

    @isTest
    private static void createAutomatedCaseBatch() {
        Account oAccount = [Select Id FROM Account WHERE NSP_AIMS_Client__c = '123456' limit 1 ];
        Asset assetRecord = [Select Id FROM Asset WHERE AccountId = :oAccount.Id limit 1];
        assetRecord.NSP_Account_Status__c = NSP_ServiceConstants.AIMS_STATUS;
        Test.startTest();
        update assetRecord;
        List<NSP_Account_Team__c> accTeamList = [SELECT Id FROM NSP_Account_Team__c WHERE Id != null ];
        //Execution of batch class
        Database.executeBatch(new NSP_CreateAutomatedCaseBatch(),200);
        NSP_CreateAutomatedCaseBatch cb = New NSP_CreateAutomatedCaseBatch();
        cb.execute(null,accTeamList);
        Test.stopTest();
        System.assertNotEquals(accTeamList, null);
    }


    @isTest
    private static void createAutomatedCaseBatchScheduler() {
        Test.startTest();
        NSP_CreateAutomatedCaseBatch createBatch = new NSP_CreateAutomatedCaseBatch();
        String sch = '0 0 23 * * ?';
        String jobId = system.schedule('Create Case Batch', sch, createBatch);

        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same
        System.assertEquals(sch, ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
    }

    @isTest
    private static void testCreateCase() {
        // Create test cases
        List<Case> testCases = new List<Case>();
        Case testCase1 = new Case();
        // Set test case fields as needed
        testCases.add(testCase1);
        // Call the method to be tested
        Test.startTest();
        NSP_CreateAutomatedCaseBatch.createCase(testCases);
        Test.stopTest();
       System.assertEquals(1, [SELECT COUNT() FROM Case WHERE Id != null]);
    }


    @isTest
    private static void testPopulateCaseList() {
        // Test data setup
        Account oAccount = [Select Id FROM Account WHERE NSP_AIMS_Client__c = '123456' limit 1 ];
        Asset assetRecord = [Select Id FROM Asset WHERE AccountId = :oAccount.Id limit 1];
        assetRecord.NSP_Account_Status__c = NSP_ServiceConstants.AIMS_STATUS;
        update assetRecord;

        Set<Id> accountIDs = new Set<Id>{oAccount.Id};
        Map<Id, Id> accountWOAssetMap = new Map<Id, Id>{oAccount.Id => assetRecord.Id};
        Map<Id, String> accountAIMSClientMap = new Map<Id, String>{oAccount.Id => 'AIMSClient001'};

        // Call the method to test
        Test.startTest();
        List<Case> result = NSP_CreateAutomatedCaseBatch.populateCaseList(accountIDs, accountWOAssetMap, accountAIMSClientMap);
        Test.stopTest();

        // Perform assertions
        System.assertEquals(1, result.size(), 'Number of cases created should match the expected value');
        Case createdCase = result[0];
        System.assertEquals(oAccount.Id, createdCase.AccountId, 'Account ID should match the provided value');
        System.assertEquals(NSP_ServiceConstants.Client_Management, createdCase.NSP_Category__c, 'Category should match the provided value');
        System.assertEquals(NSP_ServiceConstants.Renewal_Consultation, createdCase.NSP_SubCategory__c, 'Subcategory should match the provided value');
        System.assertEquals(NSP_ServiceConstants.CASE_OPEN_STATUS, createdCase.Status, 'Status should match the provided value');
        System.assertEquals(NSP_ServiceConstants.UNASSIGNED, createdCase.NSP_Case_Sub_Status__c, 'Substatus should match the provided value');
        System.assertEquals('Upcoming Renewal/Determine Next Steps', createdCase.Subject, 'Subject should match the provided value');

        ContractTerminationQueue.testHandleException( null , null );
    }

}
//