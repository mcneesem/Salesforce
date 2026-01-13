@isTest
private class FileUploadControllerTest {
    private static final String accName = 'Test Account 01';
    private static final String accAIMS = '123400';
    private static final String caseName = 'Case';
    private static final String testsubject = 'TEST1';
    private static final String contPER = '12367';
    private static final String assetName = 'Testing';
    private static final String bps = 'BPS';
    private static final String userName = 'testimportcsv';
    private static final String userName2 = '@insperity.com';
    private static final String userEmail = 'testcase@insperity.com';
    private static final String milliseconds = String.valueOf(DateTime.now().millisecond()); 
    private static final String groupName ='TestingImport';
    private static final String category = 'H&W Reporting & Compliance';
    private static final String subCat = 'Offer of Coverage letter';
    private static final String detail = 'Letters';
    private static final String csvTitle = 'TestCSV.csv';
    private static final String permSetName = 'Upload_Cases_via_CSV';
    private static final String enUs = 'en_US';
    private static final String timeZone = 'America/Los_Angeles';
    private static final String csvContent = 'SL No,Contact,Account,Asset,Category,Sub Category,Detail,Owner,Origin,Priority,Status,Substatus,Resolution,Subject,Date Opened,Due Date,Closed Date,Confidential,Quick Rate,Record Type,Description\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST1,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,BPS,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,,Other,Medium,Closed,Resolved,Approved,TEST1,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,BPS,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST2,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,DOL Audits,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST3,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,Wage Claims,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST4,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,NSP_RET_Time_Tracking,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST5,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,NSP_WX_IMPL,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST6,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,RET Time Tracking,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST7,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,ITA CQA,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST8,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,PEO,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST9,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,WX IMPL,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST10,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,Dunning Case,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Closed,Approved,TEST11,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,NSP_RET_Time_Tracking,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Resolved,TEST12,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,NSP_WX_IMPL,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Closed,Closed,Resolved,Approved,TEST13,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,RET Time Tracking,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Closed,Medium,Closed,Resolved,Approved,TEST14,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,ITA CQA,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST15,06/24/2023,06/24/2023,08/27/2023,TRUE,Closed,PEO,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST16,TRUE,06/24/2023,08/27/2023,TRUE,Neutral,NSP_WX_IMPL,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST17,06/24/2023,TRUE,08/27/2023,TRUE,Neutral,NSP_WX_IMPL,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST18,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,NSP_WX_IMPL,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST19,06/24/2023,06/24/2023,TRUE,TRUE,Neutral,NSP_WX_IMPL,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,test@insperity.com,Other,Medium,Closed,Resolved,Approved,TEST20,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,BPS,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,test@test.com,Other,Medium,Closed,Resolved,Approved,TEST21,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,BPS,Testing\n'
        + '1,12367,8687,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST22,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,BPS,Testing\n'
        + '1,12367,123400,78668,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST23,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,BPS,Testing\n'
        + '1,8688,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST24,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,BPS,Testing\n'
        + '1,12367,123400,123400,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST25,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,BPS,Testing\n'
        + '1,12367,,,H&W Reporting & Compliance,Offer of Coverage letter,Letters,TestingImport,Other,Medium,Closed,Resolved,Approved,TEST26,06/24/2023,06/24/2023,08/27/2023,TRUE,Neutral,NSP_WX_IMPL,Testing';  
    @TestSetup
    private static void testData() {
        //Insert Account
        Account oAccount1 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        oAccount1.Name = accName;
        oAccount1.NSP_AIMS_Client__c = accAIMS;
        insert oAccount1;
        
        //Insert Contact
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.AccountId = oAccount1.Id;
        newContact.NSP_Per_ID__c = contPER;
        insert newContact;
        
        //Insert Asset
        Asset newAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        newAsset.Name = assetName;
        newAsset.NSP_Client__c = accAIMS;
        newAsset.AccountId = oAccount1.Id;
        insert newAsset;
        
        
        Profile profileobj = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        //Insert User
        String orgId = UserInfo.getOrganizationId();
        User testUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        testUser.userName = userName + milliseconds + userName2;
        testUser.Email = userEmail;
        testUser.profileid = profileobj.Id;
        testUser.timezonesidkey= timeZone;
        testUser.languagelocalekey= enUs;
        testUser.localesidkey= enUs;
        insert testUser;
        //Insert Category/SubCategory/Detail
        List<NSP_Category_Sub_Category_Mapping__c> catSubcatRecords = new List<NSP_Category_Sub_Category_Mapping__c>{ 
            new NSP_Category_Sub_Category_Mapping__c(NSP_Category__c = category, 
                                                     NSP_Subcategory__c = subCat, 
                                                     NSP_Detail__c = detail,
                                                    NSP_Display_confidential_popup__c = true)};
        insert catSubcatRecords;
        //Insert ContentVersion
        Blob csvBlob = Blob.valueOf(csvContent);
        ContentVersion contentVersion = new ContentVersion(
            Title = csvTitle,
            PathOnClient = csvTitle,
            VersionData = csvBlob,
            IsMajorVersion = true
        );
        insert contentVersion;
        
        //Insert ContentDocumentLink
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = oAccount1.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id= :contentVersion.Id].ContentDocumentId,
            ShareType = 'V'
        );
        
        insert contentDocumentLink;
    }
    
    @IsTest
    private static void testLoadData() {
        ContentDocument contentDocument = [SELECT Id FROM ContentDocument WHERE Title =: csvTitle LIMIT 1];
        User user=[Select Id , Name , Email  from User WHERE Email =: userEmail Limit 1];
        Test.startTest();
        PermissionSet ps = [SELECT Id 
                            FROM PermissionSet 
                            WHERE Name =: permSetName];
        insert new PermissionSetAssignment(AssigneeId = user.id, PermissionSetId = ps.Id);
        List <PermissionSetAssignment> psa = [SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :user.Id];
        System.runAs(user){
            //Insert Group
            Group newGroup = (Group)NSP_TestExtendedDataFactory.createSObject(new Group(), 'NSP_TestDataFactory.GroupDefaults', false);
            newGroup.Name = groupName;
            newGroup.Type='Queue';
            insert newGroup;
            
            QueuesObject testQueue = new QueueSObject(QueueID = newGroup.id, SObjectType = caseName);
            insert testQueue;
            
            Case_Import_Tool_Settings__c settings =  Case_Import_Tool_Settings__c.getInstance( UserInfo.getUserId());
            settings.SetupOwnerId = user.id;
            settings.UploadViaCsvMaxSize__c = 500;
            settings.Batch_Size_Case_Import__c = 50;
            upsert settings;
            FileUploadController.hasPermission();
            FileUploadController.loadData(contentDocument.Id);
        }
        Test.stopTest();
        List<Case> cases = [SELECT Id FROM Case WHERE subject =: testsubject ];
        System.AssertEquals(1, cases.size());
    }
}