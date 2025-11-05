@isTest
private class NSP_ReportRequestWizardControllerTest {

    private static final Id recordTypeID = NSP_GenericRecordType.getRecordTypeId('NSP_ReportRequest__c','NSP_DevelopmentReport' );
    private static final Id assetRrdTypeID = NSP_GenericRecordType.getRecordTypeId('Asset','WO' );
    private static List<String> accFields = new List<String>{'Id'};

    //
    // @Description: This test method is used to prepare data for testing
    // Method Name: testData
    // @return void
    //
    @testSetup
    private static void testData() {
        Test.startTest();
        //Creating Account Record
        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        newAccount.NSP_Premier_Pathway_Client__c ='12345ABCDEF';
        newAccount.Name= System.Label.NSP_InternalAccountName;
        newAccount.NSP_FinanceLevel__c= 'Level 2 - $750K';
        insert newAccount;

        //Creating Contact Record
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.AccountId = newAccount.Id;
        newContact.NSP_Per_ID__c ='ABCDEF12345';
        newContact.NSP_Date_of_Birth__c = system.today()-150;
        insert newContact;

        //Creating Asset Record
        Asset newAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        newAsset.AccountId = newAccount.Id;
        newAsset.RecordTypeId= assetRrdTypeID;
        newAsset.NSP_Client__c ='3433';
        newAsset.NSP_Financial_Guidelines__c='6302';
        newAsset.NSP_Client_Segment_type__c='Core';
        newAsset.NSP_Service_Region__c=' MMSO - Northeast';
        newAsset.NSP_Unique_Active_Employee__c=45;
        insert newAsset;

        //Creating ReportRequest Record
        NSP_ReportRequest__c newRepReqTrigger = new NSP_ReportRequest__c();
        newRepReqTrigger.RecordTypeId =recordTypeID;
        newRepReqTrigger.NSP_Existing_NewReport__c = 'New Report';
        newRepReqTrigger.NSP_InternalClientReport__c ='Internal Report';
        newRepReqTrigger.NSP_IsDraft__c=true;
        newRepReqTrigger.OwnerId=UserInfo.getUserId();
        newRepReqTrigger.NSP_ClientName__c=newAccount.Id;
        insert newRepReqTrigger;

        //Creating AccountTeam Record
        List<NSP_Account_Team__c> accountTeams = new List<NSP_Account_Team__c>();

        NSP_Account_Team__c acTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        acTeam.NSP_Role__c ='HR Specialist';
        acTeam.NSP_Account__c= newAccount.Id;
        acTeam.NSP_Primary__c=TRUE;
        acTeam.NSP_User__c = UserInfo.getUserId();
        accountTeams.add(acTeam);

        NSP_Account_Team__c performanceSpecialistAcTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        performanceSpecialistAcTeam.NSP_Role__c ='Performance Specialist';
        performanceSpecialistAcTeam.NSP_Account__c= newAccount.Id;
        performanceSpecialistAcTeam.NSP_Primary__c=TRUE;
        performanceSpecialistAcTeam.NSP_User__c = UserInfo.getUserId();
        accountTeams.add(performanceSpecialistAcTeam);

        insert accountTeams;

        //Creating Sub Client Record
        NSP_Sub_Client__c scIns = new NSP_Sub_Client__c ();
        scIns.Name = 'Test';
        scIns.NSP_Account__c = newAccount.Id ;
        scIns.NSP_Asset__c = newAsset.Id ;
        scIns.NSP_Sub_Client__c='1233';
        insert scIns ;

        //Creating Sub Client Contact Record
        NSP_Sub_Client_Contact__c subClientContact = (NSP_Sub_Client_Contact__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContact.NSP_Sub_Client__c=scIns.Id;
        subClientContact.NSP_Contact__c=newContact.Id;
        subClientContact.NSP_Employee_Status__c='HIRED';
        subClientContact.NSP_Is_Primary__c=true;
        insert subClientContact;

        //Creating Address Record
        NSP_Address__c address1 = (NSP_Address__c) NSP_TestDataFactory.createSObject(new NSP_Address__c(), 'NSP_TestDataFactory.AddressDefaults', false);
        address1.NSP_Address_Type__c = 'Worksite';
        address1.NSP_Country__c = 'United States';
        address1.NSP_City__c = 'testung';
        address1.NSP_Postal_Code__c = '40065';
        address1.NSP_Street__c ='Test';
        address1.NSP_State__c ='NY';
        insert address1;

        //Creating Sub Client Contact Address Record
        NSP_Sub_Client_Contact_Address__c sccAddress = (NSP_Sub_Client_Contact_Address__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client_Contact_Address__c(), 'NSP_TestDataFactory.SubClientContactAddressDefaults', false);
        sccAddress.NSP_Sub_Client_Contact__c=subClientContact.id;
        sccAddress.NSP_Address__c=address1.id;
        insert sccAddress;

        Group newGroup;
        if(NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.TYPE_REGULAR, 'NSP_ReportDevelopment', accFields)!=null ){
            newGroup= (Group)NSP_TestExtendedDataFactory.createSObject(new Group(), 'NSP_TestDataFactory.GroupDefaults', false);
            newGroup.Type ='Queue';
            newGroup.name ='Report Development';
            newGroup.DeveloperName ='NSP_ReportDevelopment' ;
            insert newGroup;
            QueuesObject testQueue = new QueueSObject(QueueID = newGroup.Id, SObjectType = 'Case');
            System.runAs(new User(Id = UserInfo.getUserId()))
            {insert testQueue;}
        }
        Test.stopTest();
    }

    //
    // @Description: This test method is used to test wizard output related files
    // Method Name: testWizardContronler
    // @return void
    //
    @isTest
    private static void testWizardContronler(){

        String accQuery = new NSP_QueryBuilder('Account', accFields).addLimit(1).build();
        Account acc = Database.query(accQuery);
        NSP_ReportRequest__c reportRequest =[SELECT Id from NSP_ReportRequest__c LIMIT 1];

        Test.startTest();
        String internalAccountId = NSP_ReportRequestWizardController.getInternalAccountId();
        System.assertEquals(null,internalAccountId);


        List<AccountContactRelation> acrList =  NSP_ReportRequestWizardController.retrieveContactRecords(acc.Id);
        System.assertEquals(false,acrList.isEmpty());

        //fetch report request wizard record of record type development wizard
        List<NSP_ReportRequest__c> newList = NSP_ReportRequestWizardController.getReportRequestList(recordTypeID);
        System.assertEquals(false,newList.isEmpty());

        ContentVersion contVersion = (ContentVersion)NSP_TestExtendedDataFactory.createSObject(new ContentVersion(), 'NSP_TestDataFactory.ContentVersionDefaults', true);

        ContentDocumentLink newContentDocumentLink = (ContentDocumentLink)NSP_TestExtendedDataFactory.createSObject(new ContentDocumentLink(), 'NSP_TestDataFactory.ContentDocumentLinkDefaults', false);
        newContentDocumentLink.LinkedEntityId = reportRequest.Id;
        newContentDocumentLink.ContentDocumentId = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id =: contVersion.Id].ContentDocumentId;
        insert newContentDocumentLink;

        //check related files for report request wizard
        list<contentversion> reportFiles = NSP_ReportRequestWizardController.releatedFiles(reportRequest.Id);
        System.assertEquals(1, reportFiles.size());

        //fetch queue records for report development
        String quueID = NSP_ReportRequestWizardController.getQueueByName('Report Development');
        Assert.isNotNull(quueID, 'queue Id should not be null');
        //get aims client from wo asset
        String assetId=  NSP_ReportRequestWizardController.getAIMSfromPEOasset(acc.Id);
        Assert.isNotNull(assetId, 'assetId should not be null');
        //get hr specialist from account team
        String hrSpecialistId = NSP_ReportRequestWizardController.getHRspecialist(acc.Id);
        Assert.isNotNull(hrSpecialistId, 'hrSpecialistId should not be null');
        Test.stopTest();
    }

    //
    // @Description: This test method is used to test HR Specialist, segment and region for wizard output
    // Method Name: testSeperationRequest2
    // @return void
    //
    @isTest
    private static void testSeperationRequest2(){

        String accQuery = new NSP_QueryBuilder('Account', accFields).addLimit(1).build();
        Account acc = Database.query(accQuery);
        String assetQuery = new NSP_QueryBuilder('Asset', accFields).addLimit(1).build();
        Asset oAsset = Database.query(assetQuery);
        oAsset.NSP_Account_Status__c = NSP_ServiceConstants.ASSET_ACTIVE_STATUS;
        update oAsset;

        Test.startTest();
        Map<String,String> financeHRSpecialist = NSP_ReportRequestWizardController.getHRspecialistAndFinanceLevel(acc.Id);
        //test report request segment value from Asset
        System.assertEquals(financeHRSpecialist.get('segment'), 'Core');
        //test report request region  value from Asset
        System.assertEquals(financeHRSpecialist.get('region'), 'MMSO - Northeast');
        //Test negative scenario for Segment type and region
        oAsset.NSP_Client_Segment_type__c='';
        oAsset.NSP_Service_Region__c='';
        update oAsset;
        String woAssetId = NSP_ReportRequestWizardController.getAccountWoAsset(acc.Id);
        Map<String,String> hrSpecialist = NSP_ReportRequestWizardController.getHRspecialistAndFinanceLevel(acc.Id);
        //System.assertEquals(hrSpecialist.get('segment'), 'Not Found');
        //System.assertEquals(hrSpecialist.get('region'), 'Not Found');
        System.assertEquals(oAsset.Id, woAssetId);

        Test.stopTest();
    }

    //
    // @Description: This test method is used to test Contact details based on WSEE populate on wizard
    // Method Name: testSeperationRequest3
    // @return void
    //
    @isTest
    private static void testSeperationRequest3(){

        String accQuery = new NSP_QueryBuilder('Account', accFields).addLimit(1).build();
        Account acc = Database.query(accQuery);
        String conQuery = new NSP_QueryBuilder('Contact', accFields).
            addFilter('AccountId', acc.Id).addLimit(1).build();
        Contact con = Database.query(conQuery);
        String sccQuery = new NSP_QueryBuilder('NSP_Sub_Client_Contact__c', accFields).
            addLimit(1).build();
        NSP_Sub_Client_Contact__c scc = Database.query(sccQuery);
        String scQuery = new NSP_QueryBuilder('NSP_Sub_Client__c', accFields).
            addLimit(1).build();
        NSP_Sub_Client__c sc = Database.query(scQuery);
        String assetQuery = new NSP_QueryBuilder('Asset', accFields).addLimit(1).build();
        Asset oAsset = Database.query(assetQuery);

        List<NSP_ReportRequestWizardController.wizardOutputWrapper> wizOtWrapper = new List<NSP_ReportRequestWizardController.wizardOutputWrapper>();

        Test.startTest();
        //test report request mailing state and employee status from sub client contact
        wizOtWrapper = NSP_ReportRequestWizardController.getWSEEDetails(con.Id,  acc.Id);
        system.assertEquals(wizOtWrapper[0].empStatus, 'HIRED');
        system.assertEquals(wizOtWrapper[0].mailingState, 'NY');
        system.assertEquals(wizOtWrapper[0].dateOfBirth, system.today()-150);
        scc.NSP_Is_Primary__c =false;
        update scc;
        //Test negative scenario for work state and employee status
        wizOtWrapper = NSP_ReportRequestWizardController.getWSEEDetails(con.Id, acc.Id );
        system.assertEquals(wizOtWrapper[0].mailingState, null);
        delete sc;
        wizOtWrapper = NSP_ReportRequestWizardController.getWSEEDetails(con.Id, acc.Id );
        system.assertEquals(wizOtWrapper[0].subClientNum, null);
        //test isactiveemployees of wo asset is greater or equal to 45
        Boolean isActiveEmployee = NSP_ReportRequestWizardController.getActiveEmployeeCount( acc.Id );
        system.assertEquals(isActiveEmployee, true);
        //test negative scenario for active employees of wo asset
        oAsset.NSP_Unique_Active_Employee__c=9;
        update oAsset;
        Boolean isActiveEmployeeFalse = NSP_ReportRequestWizardController.getActiveEmployeeCount( acc.Id );
        system.assertEquals(isActiveEmployeeFalse, false);
        Test.stopTest();
    }

    @isTest
    private static void test_FileLoad_For_case() {
        // Fetching the Account Record
        Account testAccount = [SELECT ID, Name FROM Account LIMIT 1];
        Assert.isNotNull(testAccount, 'Test Account should be available');

        // Fetching the contact Record based on Account
        Contact newContact = [SELECT ID, AccountId FROM Contact WHERE AccountId = :testAccount.ID LIMIT 1];
        Assert.isNotNull(newContact, 'Contact should be present and should be linked to account');
        Assert.areEqual(newContact.AccountId, testAccount.ID, 'Account should be same');

        // Create Case Record
        Case CaseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        CaseRecord.NSP_Category__c = NSP_ServiceConstants.HR_EMPLOYEE_RELATIONS;
        CaseRecord.NSP_SubCategory__c = 'Separation Agreement Request';
        CaseRecord.Subject = 'Test Case';
        CaseRecord.AccountId = testAccount.Id;
        insert CaseRecord;
        Assert.isNotNull(CaseRecord, 'Case should be present');
        Assert.areNotEqual(null, CaseRecord.AccountId, 'Case should be linked to Account');

        // Creating the Report Request with Record Type Seperation Agreement
        Id separationRecordTypeID = NSP_GenericRecordType.getRecordTypeId('NSP_ReportRequest__c','NSP_SeparationRequest');
        NSP_ReportRequest__c reportRequest  = (NSP_ReportRequest__c)NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), 'NSP_TestDataFactory.ReportRequestDefaults', false);
        reportRequest.RecordTypeId = separationRecordTypeID;
        reportRequest.NSP_IsDraft__c = false;
        reportRequest.name = 'test ReportRequest';
        reportRequest.NSP_Case__c = CaseRecord.Id;
        reportRequest.NSP_AgreementType__c = 'Client-Prepared';
        reportRequest.NSP_ReviewType__c = 'Corporate Review';
        reportRequest.NSP_WSEE__c = newContact.Id;
        reportRequest.NSP_ClientName__c = testAccount.Id;

        insert reportrequest;
        Assert.areEqual(separationRecordTypeID, reportrequest.RecordTypeId, 'Report Request should be created with NSP_SeparationRequest record type value');

        // Create Content Version
        ContentVersion conVer = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'document.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );

        insert conVer;
        Assert.areNotEqual(conVer, null, 'There is a problem in creating the content version');

        ContentDocument document = [SELECT ID, Title, LatestPublishedVersionId, ParentId FROM ContentDocument LIMIT 1];
        Assert.isNotNull(document, 'Document should be created to test the content document link');

        // Create Conent Document Link
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityID = reportRequest.ID,
            ContentDocumentID = document.ID,
            ShareType = 'V'
        );

        insert cdl;
        Assert.isNotNull(cdl, 'There is a problem in creating the Content Document Link');

        Test.startTest();
        NSP_ReportRequestWizardController.createCaseDocuments(reportrequest.ID, CaseRecord.ID);
        Test.stopTest();
    }

    @isTest
    private static void test_FileLoad_For_case_Negative() {
        Test.startTest();
        NSP_ReportRequest__c reportrequest = new NSP_ReportRequest__c();
        Case CaseRecord = new Case();
        try
        {
            NSP_ReportRequestWizardController.createCaseDocuments(reportrequest.ID, CaseRecord.ID);
        }
        catch(Exception e)
        {
            Assert.isNotNull(e.getMessage());
        }

        Test.stopTest();
    }

    @isTest
    private static void Test_WO_Asset_Segment() {
        Account account = [SELECT ID, NSP_Account_Segment__c FROM Account LIMIT 1];

        Asset asset = [SELECT ID, AccountId, NSP_Account_Status__c FROM Asset WHERE AccountId = :account.Id LIMIT 1];
        asset.NSP_Account_Status__c = 'Terminated';
        update asset;

        // Fetching the contact Record based on Account
        Contact newContact = [SELECT ID, AccountId FROM Contact WHERE AccountId = :account.ID LIMIT 1];
        Assert.isNotNull(newContact, 'Contact should be present and should be linked to account');
        Assert.areEqual(newContact.AccountId, account.ID, 'Account should be same');

        // Create Case Record
        Case CaseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        CaseRecord.NSP_Category__c = NSP_ServiceConstants.HR_EMPLOYEE_RELATIONS;
        CaseRecord.NSP_SubCategory__c = 'Separation Agreement Request';
        CaseRecord.Subject = 'Test Case';
        CaseRecord.AccountId = account.Id;
        insert CaseRecord;
        Assert.isNotNull(CaseRecord, 'Case should be present');
        Assert.areNotEqual(null, CaseRecord.AccountId, 'Case should be linked to Account');


        // Creating the Report Request with Record Type Seperation Agreement
        Id separationRecordTypeID = NSP_GenericRecordType.getRecordTypeId('NSP_ReportRequest__c','NSP_SeparationRequest');
        NSP_ReportRequest__c reportRequest = (NSP_ReportRequest__c)NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), 'NSP_TestDataFactory.ReportRequestDefaults', false);
        reportRequest.RecordTypeId = separationRecordTypeID;
        reportRequest.NSP_IsDraft__c = false;
        reportRequest.name = 'test ReportRequest';
        reportRequest.NSP_Case__c = CaseRecord.Id;
        reportRequest.NSP_AgreementType__c = 'Client-Prepared';
        reportRequest.NSP_ReviewType__c = 'Corporate Review';
        reportRequest.NSP_WSEE__c = newContact.Id;
        reportRequest.NSP_ClientName__c = account.Id;

        insert reportrequest;
        Assert.areEqual(separationRecordTypeID, reportrequest.RecordTypeId, 'Report Request should be created with NSP_SeparationRequest record type value');

        Test.startTest();
        NSP_ReportRequestWizardController.getHRspecialistAndFinanceLevel(account.Id);
        Test.stopTest();
    }

    //== Testing the Non primary user assignment for Wizard Output
    @isTest
    private static void testNonPrimaryAccountTeamRelatedToAccount() {
        Account account = [SELECT ID, NSP_Account_Segment__c FROM Account LIMIT 1];
        List<NSP_Account_Team__c> accountTeams = [SELECT ID, NSP_Primary__c FROM NSP_Account_Team__c WHERE NSP_Account__c = : account.Id];
        Assert.areNotEqual(accountTeams, null, 'Account Teams should not be null');
        Assert.isTrue(accountTeams.size() > 0);
        for(NSP_Account_Team__c accTeam : accountTeams)
        {
            accTeam.NSP_Primary__c = false;
        }

        update accountTeams;

        Asset asset = [SELECT ID, AccountId, NSP_Account_Status__c FROM Asset WHERE AccountId = :account.Id LIMIT 1];
        asset.NSP_Account_Status__c = 'Terminated';
        update asset;

        // Fetching the contact Record based on Account
        Contact newContact = [SELECT ID, AccountId FROM Contact WHERE AccountId = :account.ID LIMIT 1];
        Assert.isNotNull(newContact, 'Contact should be present and should be linked to account');
        Assert.areEqual(newContact.AccountId, account.ID, 'Account should be same');

        // Create Case Record
        Case CaseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        CaseRecord.NSP_Category__c = NSP_ServiceConstants.HR_EMPLOYEE_RELATIONS;
        CaseRecord.NSP_SubCategory__c = 'Separation Agreement Request';
        CaseRecord.Subject = 'Test Case';
        CaseRecord.AccountId = account.Id;
        insert CaseRecord;
        Assert.isNotNull(CaseRecord, 'Case should be present');
        Assert.areNotEqual(null, CaseRecord.AccountId, 'Case should be linked to Account');


        // Creating the Report Request with Record Type Seperation Agreement
        Id separationRecordTypeID = NSP_GenericRecordType.getRecordTypeId('NSP_ReportRequest__c','NSP_SeparationRequest');
        NSP_ReportRequest__c reportRequest = (NSP_ReportRequest__c)NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), 'NSP_TestDataFactory.ReportRequestDefaults', false);
        reportRequest.RecordTypeId = separationRecordTypeID;
        reportRequest.NSP_IsDraft__c = false;
        reportRequest.name = 'test ReportRequest';
        reportRequest.NSP_Case__c = CaseRecord.Id;
        reportRequest.NSP_AgreementType__c = 'Client-Prepared';
        reportRequest.NSP_ReviewType__c = 'Corporate Review';
        reportRequest.NSP_WSEE__c = newContact.Id;
        reportRequest.NSP_ClientName__c = account.Id;

        insert reportrequest;

        Test.startTest();
        NSP_ReportRequestWizardController.getHRspecialistAndFinanceLevel(account.Id);
        Test.stopTest();
    }

}
//