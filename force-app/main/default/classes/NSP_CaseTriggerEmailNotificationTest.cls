@isTest
private class NSP_CaseTriggerEmailNotificationTest {
    private static final String ACCOUNTDEFAULTS = 'NSP_TestDataFactory.AccountDefaults';
    private static final String CASEDEFAULTS  = 'NSP_TestDataFactory.CaseDefaults';
    private static final Id bpsProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', NSP_ServiceConstants.PROJECT_BPS_RECORDTYPE);
    private static final Id WOAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
    private static final Id PEO_RECORDTYPE = NSP_GenericRecordType.getRecordTypeId('Case', NSP_ServiceConstants.PEO);

    private static final String REQUEST_NOT_COMPLETE_TEMPLATE = 'NSP_Report_Dev_Case_Request_Not_Complete_Email';
    private static final String REFERRED_TO_EXISTING_TEMPLATE = 'NSP_Report_Dev_Case_Referred_to_Existing_Email';
    private static final String AWAITING_VERIFICATION_TEMPLATE = 'NSP_Report_Dev_Case_Awaiting_Verification_Email';
    private static final String MIGRATION_COMPLETE_TEMPLATE = 'NSP_Report_Dev_Case_Wire_Migration_Complete_Email';

    private static final List<String> PROJECT_FIELDS = new List<String>{
        'Id',
        'Name',
        'pse__Start_Date__c',
        'Templates_Used__c',
        'Peer_Review__c'
    };
    private static final List<String> CASE_FIELDS = new List<String>{
        'Id',
        'NSP_CorporateEmployeeEE__c', 'AccountId', 'ContactId'
    };
    @testSetup
    private static void testData() {
        Email_Deliverability_Settings__c emailSetting = new Email_Deliverability_Settings__c();
        insert emailSetting;

        List<Case> caseList = new List<Case>();
        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), ACCOUNTDEFAULTS, true);
        Account assetAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), ACCOUNTDEFAULTS, false);
        assetAccount.Name = 'Test Asset';
        insert assetAccount;

        //create new contact
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.Account = newAccount;
        newContact.NSP_Work_email__c = 'test123@efg.com';
        insert newContact;

        Asset woAssetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        woAssetRecord.AccountId = assetAccount.Id;
        woAssetRecord.NSP_Account_Status__c = NSP_ServiceConstants.AIMS_STATUS;
        woAssetRecord.RecordTypeId = WOAssetRecordTypeId;
        woAssetRecord.NSP_Client_Segment_type__c = NSP_ServiceConstants.CoreAssetSegment;
        Database.insert(woAssetRecord, false);

        NSP_Category_Sub_Category_Mapping__c newCat = (NSP_Category_Sub_Category_Mapping__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Category_Sub_Category_Mapping__c(), 'NSP_TestDataFactory.CatSubCatMappingDefaults', false);
        newCat.NSP_UserTitle__c = 'Benefits Manager';
        newCat.NSP_Category__c = NSP_ServiceConstants.CATEGORY_ADAPTION;
        newCat.NSP_Subcategory__c = NSP_ServiceConstants.SUB_CATEGORY_CLAIM;
        newCat.NSP_Detail__c = 'Login';
        newCat.NSP_isActive__c=True;
        newCat.NSP_Asset_Record_Types__c='WO';
        newCat.NSP_RecordType__c='PEO';
        newCat.NSP_Public_Groups_To_Share__c = 'All Data Visibility';
        Database.insert(newCat);

        pse__Proj__c bpsProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        bpsProject.RecordTypeId = bpsProjectRecordTypeId;
        bpsProject.Templates_Used__c = NSP_ServiceConstants.ITA_IMPLEMENTATION;
        bpsProject.pse__Project_Status__c = 'Active';
        bpsProject.Project_Implementer__c = userinfo.getUserId();
        bpsProject.pse__Is_Active__c = true;
        insert bpsProject;

        //Creating case for Report dev Notification testing
        Case asssetCaseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        asssetCaseRecord.NSP_Category__c = 'Adaption';
        asssetCaseRecord.NSP_SubCategory__c = 'Claim';
        asssetCaseRecord.Subject = 'Test Report Dev Notifications';
        asssetCaseRecord.AccountId = newAccount.Id;
        caseList.add(asssetCaseRecord);

        Case nCorpCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        nCorpCase.contactId = newContact.Id;
        nCorpCase.AccountId = newAccount.Id;
        nCorpCase.NSP_CorporateEmployeeEE__c = true;
        caseList.add(nCorpCase);

        Case newCaseWithCon = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        newCaseWithCon.contactId = newContact.Id;
        newCaseWithCon.NSP_Category__c = NSP_ServiceConstants.HW_SECTION_125;
        caseList.add(newCaseWithCon);
        Case newCaseWithOutCon = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        caseList.add(newCaseWithOutCon);

        // Parent ITA CQA Case
        Case itaCqaCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        itaCqaCase.RecordTypeId =NSP_GenericRecordType.getRecordTypeId('Case', NSP_ServiceConstants.NSP_ITA_CQA);
        itaCqaCase.NSP_CQA_Resulting_Severity__c = NSP_ServiceConstants.L1_CA_ACCURALS_MISCALCULATION;
       	itaCqaCase.Project__c = bpsProject.Id;
        caseList.add(itaCqaCase);

        //To get case recordtypeId
        //Id recordTypeIdWxImpl = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.CASE_OBJECT_NAME,NSP_ServiceConstants.WX_IMPL);
        //create HCM case Creation
        Case hcmCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        hcmCase.Subject = NSP_ServiceConstants.HCM_TEST_CASE_SUBJECT;
        hcmCase.NSP_Opened_Date__c = Date.Today();
        hcmCase.Status = NSP_ServiceConstants.OPEN;
      	caseList.add(hcmCase);

		//Creating case for Report dev Notification testing
        Case caseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        caseRecord.NSP_Category__c = NSP_ServiceConstants.CASE_CATEGORY_SERVICE_OPERATIONS;
        caseRecord.NSP_SubCategory__c = NSP_ServiceConstants.CASE_SUB_CATEGORY_REQUEST_CUSTOMIZED_REPORT;
        caseRecord.Subject = 'Test Report Dev Notifications';
        caseRecord.AccountId = newAccount.Id;
        caseRecord.NSP_Opened_Date__c = Date.Today();
        caseList.add(caseRecord);

        //Creating BPS case
        Id recordTypeIdBPS = NSP_GenericRecordType.getRecordTypeId('Case','BPS');
        Case bpsCaseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        bpsCaseRecord.RecordTypeId = recordTypeIdBPS;
        bpsCaseRecord.Subject = 'Test BPS Case';
        bpsCaseRecord.AccountId = newAccount.Id;
        bpsCaseRecord.Type = 'Congruex';
       	caseList.add(bpsCaseRecord);

        // WgaeClaims Case
        Id recordTypeIdPEO = NSP_GenericRecordType.getRecordTypeId('Case', NSP_ServiceConstants.PEO);
        Case wageClaimsCaseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        wageClaimsCaseRecord.RecordTypeId = recordTypeIdPEO;
        wageClaimsCaseRecord.Subject = 'Test WageClaims Case';
        wageClaimsCaseRecord.AccountId = newAccount.Id;
        wageClaimsCaseRecord.NSP_Category__c = NSP_ServiceConstants.FLSA_CATEGORY;
        wageClaimsCaseRecord.NSP_SubCategory__c = NSP_ServiceConstants.CASE_SUB_CATEGORY_WAGE_CLAIMS;
       	caseList.add(wageClaimsCaseRecord);

        Database.insert(caseList);

        // child ITA CQA Case
        Case childItaCqaCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        childItaCqaCase.RecordTypeId = NSP_GenericRecordType.getRecordTypeId('Case', NSP_ServiceConstants.NSP_ITA_CQA);
        childItaCqaCase.NSP_CQA_Resulting_Severity__c = NSP_ServiceConstants.L1_CA_ACCURALS_MISCALCULATION;
        childItaCqaCase.ParentId = itaCqaCase.Id;
        insert childItaCqaCase;

        //create case contact
        NSP_Case_Contacts__c caseContact = (NSP_Case_Contacts__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Case_Contacts__c(), 'NSP_TestDataFactory.caseContactDefaults', false);
        caseContact.NSP_Contact__c = newContact.Id;
        caseContact.NSP_Case__c = bpsCaseRecord.Id;
        caseContact.NSP_IsPrimary__c = true;
        INSERT caseContact;

        User PEOUSER = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'PEO Service'][0].Id,
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
        insert PEOUSER;
        List<String> fields = new List<String>{'Id', 'Type','DeveloperName'};
           System.runAs ( new User(Id = UserInfo.getUserId()) ) {
        Id groupId = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.TYPE_REGULAR, NSP_ServiceConstants.SECTION_125_PRIVATE_CASE_VISIBILTY, fields).Id;
        GroupMember grpMem = new GroupMember (UserOrGroupId = userInfo.getUserId(), GroupId = groupId);
        List<GroupMember> groupMemberList= new List<GroupMember>{grpMem};
            // Inserting Group Members
            Insert groupMemberList;
           }
    }

    @isTest
    private static void testsendRequestNotCompleteMail() {
        List<Case> caseList = new List<Case>();
        Test.startTest();
        User getPeoUser = [SELECT Id,Email FROM user WHERE Email = 'testuser@insperity.com' ];
        System.runAs (getPeoUser) {
            Case case1 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
            case1.NSP_Category__c = NSP_ServiceConstants.BEN_SERVICE_CLAIMS;
            case1.NSP_Confidential__c = true;
            caseList.add(case1);
            database.insert(caseList);

            caseList = [SELECT Id, CreatedById,OwnerId  FROM Case WHERE Id =: caseList[0].Id limit 1];
            case1.NSP_Confidential__c = false;
            case1.NSP_Category__c = NSP_ServiceConstants.HR_EMPLOYEE_RELATIONS;
            database.update(case1);
        }
        NSP_CaseTriggerEmailNotification.sendRequestNotCompleteMail(caseList);
        Test.stopTest();
    }

    @isTest
    private static void testsendReferredToExistingEmail() {
        List<Case> caseList = new List<Case>();
        Test.startTest();
        User getPeoUser = [SELECT Id,Email FROM user WHERE Email = 'testuser@insperity.com' ];
        System.runAs (getPeoUser) {
            Case case1 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
            case1.NSP_Category__c = NSP_ServiceConstants.BEN_SERVICE_CLAIMS;
            case1.NSP_Confidential__c = true;
            caseList.add(case1);
            database.insert(caseList);

            caseList = [SELECT Id, CreatedById,OwnerId  FROM Case WHERE Id =: caseList[0].Id limit 1];
            case1.NSP_Confidential__c = false;
            case1.NSP_Category__c = NSP_ServiceConstants.HR_EMPLOYEE_RELATIONS;
            database.update(case1);
        }
        NSP_CaseTriggerEmailNotification.sendReferredToExistingEmail(caseList);
        Test.stopTest();
    }

    @isTest
    private static void testsendAwaitingVerificationEmail() {
        List<Case> caseList = new List<Case>();
        Test.startTest();
        User getPeoUser = [SELECT Id,Email FROM user WHERE Email = 'testuser@insperity.com' ];
        System.runAs (getPeoUser) {
            Case case1 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
            case1.NSP_Category__c = NSP_ServiceConstants.BEN_SERVICE_CLAIMS;
            case1.NSP_Confidential__c = true;
            caseList.add(case1);
            database.insert(caseList);

            caseList = [SELECT Id, CreatedById,OwnerId,NSP_Category__c  FROM Case WHERE Id =: caseList[0].Id limit 1];
            case1.NSP_Confidential__c = false;
            case1.NSP_Category__c = NSP_ServiceConstants.HR_EMPLOYEE_RELATIONS;
            database.update(case1);
        }
        NSP_CaseTriggerEmailNotification.sendAwaitingVerificationEmail(caseList);
        system.assertEquals(caseList[0].NSP_Category__c, NSP_ServiceConstants.BEN_SERVICE_CLAIMS);
        Test.stopTest();
    }

    @isTest
    private static void testsendMigrationCompleteEmail() {
        List<Case> caseList = new List<Case>();
        Test.startTest();
        User getPeoUser = [SELECT Id,Email FROM user WHERE Email = 'testuser@insperity.com' ];
        System.runAs (getPeoUser) {
            Case case1 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
            case1.NSP_Category__c = NSP_ServiceConstants.BEN_SERVICE_CLAIMS;
            case1.NSP_Confidential__c = true;
            caseList.add(case1);
            database.insert(caseList);

            caseList = [SELECT Id, CreatedById,OwnerId  FROM Case WHERE Id =: caseList[0].Id limit 1];
            case1.NSP_Confidential__c = false;
            case1.NSP_Category__c = NSP_ServiceConstants.HR_EMPLOYEE_RELATIONS;
            database.update(case1);
        }
        NSP_CaseTriggerEmailNotification.sendMigrationCompleteEmail(caseList);
        Test.stopTest();
    }

}
//