@isTest
private class NSP_EmailMessageTriggerHelperTest {
    private static final String CONTACTCENTER = 'contact_center@insperity.com';
    private static final String QUEUE = 'Queue';
    private static final String CONTACTCENTERQUEUE = 'NSP_ContactCenter';
    private static final Id BPS_RECORDTYPEID = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'BPS' );
    private static final Email_Address_to_Case_Owner_Mapping__mdt e2c_TimeAttendance = Email_Address_to_Case_Owner_Mapping__mdt.getInstance('Time_and_Attendance');

    @testSetup
    private static void setupTestData() {
        Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        newCase.NSP_Category__c = 'Adaption';
        newCase.NSP_SubCategory__c = 'Claim';
        insert newCase;
    }

    @isTest
    private static void markResponseAfterCloseTrueForPEOTest() {
        Test.startTest();
        Id casePEORecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'PEO' );
        Case caseRecord = [SELECT id, Status FROM  Case WHERE Status = 'Open' LIMIT 1];
        caseRecord.NSP_Rating__c = 'Neutral';
        caseRecord.Status = 'Closed';
        caseRecord.RecordTypeId = casePEORecordTypeId;
        caseRecord.NSP_Category__c = 'Adaption';
        caseRecord.NSP_SubCategory__c = 'Claim';
        update caseRecord;
        //Email message creation
        EmailMessage eMsg = new EmailMessage ();
        eMsg.FromAddress = 'test@test.com';
        eMsg.Incoming = True;
        eMsg.ToAddress= 'test@xyz.com';
        eMsg.Subject = 'Test email Subject';
        eMsg.HtmlBody = 'Test email body';
        eMsg.ParentId = caseRecord.id;
        //inserting Email message
        insert eMsg;
        Test.stopTest();

    }

    @isTest
    private static void markResponseAfterCloseTrueForPEOTest2() {
        Test.startTest();
        Id casePEORecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'PEO' );
        List<String> contactCenterEmailAddresses = System.Label.NSP_Contact_Center_Email_Addresses.toLowerCase().split( ',' );
        Case caseRecord = [SELECT id, Status FROM  Case WHERE Status = 'Open' LIMIT 1];
        caseRecord.NSP_Rating__c = 'Neutral';
        caseRecord.Status = 'Closed';
        caseRecord.RecordTypeId = casePEORecordTypeId;
        caseRecord.NSP_Category__c = 'Adaption';
        caseRecord.NSP_SubCategory__c = 'Claim';
        update caseRecord;
        //Email message creation
        EmailMessage eMsg = new EmailMessage ();
        eMsg.FromAddress = 'test@test.com';
        eMsg.Incoming = True;
        eMsg.ToAddress= contactCenterEmailAddresses[0];
        eMsg.Subject = 'Test email Subject';
        eMsg.HtmlBody = 'Test email body';
        eMsg.ParentId = caseRecord.id;

        //inserting Email message
        insert eMsg;
        Test.stopTest();
    }

    @isTest
    private static void reOpenCaseForBPSTest() {
        Test.startTest();
        Case_Settings__c settings = Case_Settings__c.getOrgDefaults();
        settings.BPS_Case_Tier_1_Categories_1__c = 'Integra';
        settings.BPS_Case_Tier_1_Categories_2__c = 'Test1';
        settings.BPS_Case_Tier_2_Categories__c = 'Test';
        settings.BPS_Case_Tier_1_Reopen_Days__c = 14;
        settings.BPS_Case_Tier_2_Reopen_Days__c = 30;
        upsert settings;
        //Story : AZD-328200 - added custom setting value as test data for this function.
        EmailMessageTriggerSettings__c asyncSwitchSetting = EmailMessageTriggerSettings__c.getOrgDefaults();
        asyncSwitchSetting.IsAfterInsertQueueableEnabled__c = false;
        upsert asyncSwitchSetting;
        Case caseRecord = [SELECT id, Status FROM Case WHERE Status = 'Open' LIMIT 1];
        caseRecord.NSP_Rating__c = 'Neutral';
        caseRecord.Status = 'Closed';
        caseRecord.RecordTypeId = BPS_RECORDTYPEID;
        caseRecord.NSP_Category__c = 'Integra';
        update caseRecord;
        //Email message creation
        EmailMessage eMsg = new EmailMessage ();
        eMsg.FromAddress = 'test@test.com';
        eMsg.Incoming = True;
        eMsg.ToAddress= 'test@xyz.com';
        eMsg.Subject = 'Test email Subject';
        eMsg.HtmlBody = 'Test email body';
        eMsg.ParentId = caseRecord.id;
        eMsg.TextBody = 'Test email Body';
        //inserting Email message
        insert eMsg;
        Case updatedCase = [SELECT Status FROM Case WHERE ID = : caseRecord.id];
        System.assertEquals('ReOpened', updatedCase.Status);
        Test.stopTest();
    }

    @isTest
    private static void createCaseForBPSTest() {
        Test.startTest();
        Case_Settings__c settings = Case_Settings__c.getOrgDefaults();
        settings.BPS_Case_Tier_1_Categories_1__c = 'Integra';
        settings.BPS_Case_Tier_1_Categories_2__c = 'Test1';
        settings.BPS_Case_Tier_2_Categories__c = 'Test';
        settings.BPS_Case_Tier_1_Reopen_Days__c = -1;
        settings.BPS_Case_Tier_2_Reopen_Days__c = -1;
        upsert settings;
        Case caseRecord = [SELECT id, Status FROM Case WHERE Status = 'Open' LIMIT 1];
        caseRecord.NSP_Rating__c = 'Neutral';
        caseRecord.Status = 'Closed';
        caseRecord.RecordTypeId = BPS_RECORDTYPEID;
        caseRecord.NSP_Category__c = 'Integra';
        update caseRecord;
        //Email message creation
        EmailMessage eMsg = new EmailMessage ();
        eMsg.FromAddress = 'test@test.com';
        eMsg.Incoming = True;
        eMsg.ToAddress= e2c_TimeAttendance.Email_Address__c;
        eMsg.CcAddress= 'test@xyz.com';
        eMsg.Subject = 'Test email Subject';
        eMsg.HtmlBody = 'Test email body';
        eMsg.ParentId = caseRecord.id;
        eMsg.TextBody = 'Test email Body';
        //inserting Email message
        insert eMsg;
        Test.stopTest();
    }

    @isTest
    private static void createCaseForBPSWithCCAddressTest() {
        Test.startTest();
        Case_Settings__c settings = Case_Settings__c.getOrgDefaults();
        settings.BPS_Case_Tier_1_Categories_1__c = 'Integra';
        settings.BPS_Case_Tier_1_Categories_2__c = 'Test1';
        settings.BPS_Case_Tier_2_Categories__c = 'Test';
        settings.BPS_Case_Tier_1_Reopen_Days__c = -1;
        settings.BPS_Case_Tier_2_Reopen_Days__c = -1;
        upsert settings;
        Case caseRecord = [SELECT id, Status FROM Case WHERE Status = 'Open' LIMIT 1];
        caseRecord.NSP_Rating__c = 'Neutral';
        caseRecord.Status = 'Closed';
        caseRecord.RecordTypeId = BPS_RECORDTYPEID;
        caseRecord.NSP_Category__c = 'Integra';
        update caseRecord;
        //Email message creation
        EmailMessage eMsg = new EmailMessage ();
        eMsg.FromAddress = 'test@test.com';
        eMsg.Incoming = True;
        eMsg.ToAddress= 'test@xyz.com';
        eMsg.CcAddress= e2c_TimeAttendance.Email_Address__c;
        eMsg.Subject = 'Test email Subject';
        eMsg.HtmlBody = 'Test email body';
        eMsg.ParentId = caseRecord.id;
        eMsg.TextBody = 'Test email Body';
        //inserting Email message
        insert eMsg;
        Test.stopTest();
    }

    @isTest
    private static void testrestrictEmailFromRestrictedSenders() {
        Test.startTest();
        try {
            List<String> caseFields = new List<String>{'Id','Status'};
            String query = new NSP_QueryBuilder('Case', caseFields)
                .addFilter('Status', NSP_ServiceConstants.CASE_OPEN_STATUS).build();
            Case caseRecord = Database.query(query);
            EmailMessage eMessage = new EmailMessage ();
            eMessage.FromAddress = 'viva-noreply@microsoft.com';
            eMessage.ToAddress = System.Label.NSP_Customer_Service_Email;
            eMessage.Subject = 'test';
            eMessage.Incoming = true;
            eMessage.ParentId = caseRecord.Id;
            INSERT eMessage;
        } catch ( Exception ex ){
            system.assertEquals(ex.getMessage(), 'Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, EmailMessage cannot be created as sender is from restricted list.: []');
        }
        Test.stopTest();
    }

    @isTest
    private static void testEmailMessageCreationWithoutRestrictedFromAddress() {
        Test.startTest();
        List<String> caseFields = new List<String>{'Id','Status'};
        String query = new NSP_QueryBuilder('Case', caseFields)
            .addFilter('Status', NSP_ServiceConstants.CASE_OPEN_STATUS).build();
        Case caseRecord = Database.query(query);
        EmailMessage eMessage = new EmailMessage ();
        eMessage.ToAddress = System.Label.NSP_Customer_Service_Email;
        eMessage.Subject = 'test';
        eMessage.Incoming = true;
        eMessage.FromAddress = 'test@test.com';
        eMessage.ParentId = caseRecord.Id;
        INSERT eMessage;
        System.assertEquals(1, [SELECT Count() FROM EmailMessage WHERE Id =: eMessage.Id]);
        Test.stopTest();
    }

    @isTest
    private static void testUpdateConfidentialCheckBoxForEmpScreening() {
        Test.startTest();
        List<String> caseFields = new List<String>{'Id', 'NSP_Confidential__c', 'NSP_Category__c'};
        String query = new NSP_QueryBuilder('Case', caseFields)
            .addFilter('Status', NSP_ServiceConstants.CASE_OPEN_STATUS)
            .addLimit(1).build();
        Case caseRecord = Database.query(query);
        EmailMessage eMessage = new EmailMessage ();
        eMessage.ToAddress = System.Label.NSP_Customer_Service_Email;
        eMessage.Subject = 'test';
        eMessage.Incoming = true;
        eMessage.FromAddress = 'test@test.com';
        eMessage.ParentId = caseRecord.Id;
        Database.insert(eMessage);
        System.assertEquals(false, caseRecord.NSP_Confidential__c);
        Test.stopTest();
    }

    @isTest
    private static void neagativTestUpdateConfidentialCheckBoxForEmpScreening() {
        Test.startTest();
        List<String> caseFields = new List<String>{'Id', 'NSP_Confidential__c', 'NSP_Category__c', 'Status'};
            String query = new NSP_QueryBuilder('Case', caseFields)
            .addFilter('Status', NSP_ServiceConstants.CASE_OPEN_STATUS)
            .addLimit(1).build();
        Case caseRecord = Database.query(query);
        EmailMessage eMessage = new EmailMessage ();
        eMessage.ToAddress = 'test.test@test.com';
        eMessage.Subject = 'test';
        eMessage.Incoming = true;
        eMessage.FromAddress = 'test@test.com';
        eMessage.ParentId = caseRecord.Id;
        Database.insert(eMessage);
        System.assertEquals(false, caseRecord.NSP_Confidential__c);
        Test.stopTest();
    }

    @isTest
    private static void sendEmailToHealthWelfareInternal() {
        Test.startTest();
        List<String> caseFields = new List<String>{'Id', 'NSP_Confidential__c', 'NSP_Category__c', 'Status'};
            String query = new NSP_QueryBuilder('Case', caseFields)
            .addFilter('Status', NSP_ServiceConstants.CASE_OPEN_STATUS)
            .addLimit(1).build();
        Case caseRecord = Database.query(query);
        EmailTemplate template = new EmailTemplate ();
        template.developerName = 'Test_Email_Template_Unique';
        template.FolderId=userInfo.getUserId();
        template.TemplateType='Text';
        template.Name='TestEmailTempalte_Unique';
        insert template;
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            EmailMessage eMessage = new EmailMessage ();
            eMessage.ToAddress = System.Label.NSP_Health_Welfare_Section_125;
            eMessage.Subject = 'test';
            eMessage.Incoming = true;
            eMessage.FromAddress = 'test@insperity.com';
            eMessage.ParentId = caseRecord.Id;
            Database.insert(eMessage);
        }
        system.assertEquals(caseRecord.Status, NSP_ServiceConstants.CASE_OPEN_STATUS);
        Test.stopTest();
    }

    @isTest
    private static void sendEmailToHealthWelfareExternal() {
        Test.startTest();
        List<String> lstHealthWelfareSection = System.Label.NSP_Health_Welfare_Section_125.toLowerCase().split( ',' );
        List<String> caseFields = new List<String>{'Id', 'NSP_Confidential__c', 'NSP_Category__c', 'Status'};
            String query = new NSP_QueryBuilder('Case', caseFields)
            .addFilter('Status', NSP_ServiceConstants.CASE_OPEN_STATUS)
            .addLimit(1).build();
        Case caseRecord = Database.query(query);
        EmailMessageTriggerSettings__c switchEnabled = EmailMessageTriggerSettings__c.getInstance( UserInfo.getUserId() );
        switchEnabled.IsHealthAndWelfareEmailMessageEnabled__c = false;
        upsert switchEnabled;
        EmailMessage eMessage = new EmailMessage ();
        eMessage.ToAddress = lstHealthWelfareSection[0];
        eMessage.Subject = 'test';
        eMessage.Incoming = true;
        eMessage.FromAddress = 'test@insperity.com';
        eMessage.ParentId = caseRecord.Id;
        Database.insert(eMessage);
        system.assertEquals(eMessage.Subject, 'test');
        Test.stopTest();
    }

    @isTest
    private static void sendEmailToHealthWelfareExternal2() {
        Test.startTest();
        List<String> lstHealthWelfareSection = System.Label.NSP_Health_Welfare_Section_125.toLowerCase().split( ',' );
        List<String> caseFields = new List<String>{'Id', 'NSP_Confidential__c', 'NSP_Category__c', 'Status'};
            String query = new NSP_QueryBuilder('Case', caseFields)
            .addFilter('Status', NSP_ServiceConstants.CASE_OPEN_STATUS)
            .addLimit(1).build();
        Case caseRecord = Database.query(query);
        EmailMessageTriggerSettings__c switchEnabled = EmailMessageTriggerSettings__c.getInstance( UserInfo.getUserId() );
        switchEnabled.IsHealthAndWelfareEmailMessageEnabled__c = false;
        upsert switchEnabled;
        EmailMessage eMessage = new EmailMessage ();
        eMessage.ToAddress = 'test.service@insperity.com';
        eMessage.Subject = 'test';
        eMessage.Incoming = true;
        eMessage.FromAddress = 'test@pwc.com';
        eMessage.ParentId = caseRecord.Id;
        Database.insert(eMessage);
        system.assertEquals(eMessage.Subject, 'test');
        Test.stopTest();
    }

    @isTest
    private static void negativesendEmailToHealthWelfareExternal() {
        Test.startTest();
        List<String> caseFields = new List<String>{'Id', 'NSP_Confidential__c', 'NSP_Category__c', 'Status'};
            String query = new NSP_QueryBuilder('Case', caseFields)
            .addFilter('Status', NSP_ServiceConstants.CASE_OPEN_STATUS)
            .addLimit(1).build();
        Case caseRecord = Database.query(query);
        EmailMessage eMessage = new EmailMessage ();
        eMessage.ToAddress = 'test.customer.service@test.com';
        eMessage.Subject = 'test';
        eMessage.Incoming = true;
        eMessage.FromAddress = 'test@pwc.com';
        eMessage.ParentId = caseRecord.Id;
        Database.insert(eMessage);
        system.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }

    @isTest
    private static void updateEmailMessageFieldsTest() {
        Test.startTest();
        Case nCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        nCase.NSP_Case_External_Id__c = '22778899';
        insert nCase;
        EmailMessage eMessage = new EmailMessage ();
        eMessage.ToAddress = 'test@insperity.com';
        eMessage.FromName = 'cases.345678_SB4.22778899_3456789.netsuite';
        eMessage.Subject = 'test';
        eMessage.Incoming = true;
        eMessage.ParentId = nCase.Id;
        eMessage.FromAddress = 'test@pwc.com';
        Database.insert(eMessage);
        List<EmailMessage> eMessageList = [SELECT Id, FromName ,ParentId ,CreatedDate From EmailMessage WHERE FromName = 'cases.345678_SB4.22778899_3456789.netsuite'];
        system.assert(eMessageList.size() > 0);
        Test.stopTest();
    }

    @isTest
    private static void markResponseAfterCloseMoreThanFiveForPEOTest() {
        Test.startTest();
        Account acc = new Account(Name = 'test acc');
        Id casePEORecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'PEO' );
        ID contactCenterQueueId = ([SELECT ID FROM Group WHERE Type = :QUEUE AND DeveloperNAME = :CONTACTCENTERQUEUE]).ID;
        Map<Case,EmailMessage> CaseToSubjectMap = new Map<Case,EmailMessage>();
        Map<Case,EmailMessage> ParentCaseToEmailMessageMap = new Map<Case,EmailMessage>();
        List<Case> caseList = new List<Case>();
        EmailMessageTriggerSettings__c messageTriggerSetting = EmailMessageTriggerSettings__c.getOrgDefaults();
        messageTriggerSetting.isRelatedEmailMessageEnabled__c = true;
        upsert messageTriggerSetting;
        Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        insert newCase;
        newCase.NSP_Rating__c = 'Neutral';
        newCase.Status = 'Closed';
        newCase.RecordTypeId = casePEORecordTypeId;
        newCase.NSP_Category__c = 'Adaption';
        newCase.NSP_SubCategory__c = 'Claim';
        newCase.NSP_Date_Closed__c = Date.Today().addDays(-10);
        newCase.AccountId = acc.Id;
        newCase.assetId = null;
        newCase.ContactId = null;
        newCase.NSP_Category__c = 'Test Category';
        newCase.NSP_SubCategory__c = 'Test Sub-Category';
        newCase.Priority = 'Test Priority';
        newCase.Origin = 'Test Origin';
        newCase.Subject = 'Test Subject';
        update newCase;
        Case caseRecord = [SELECT id, Status FROM  Case WHERE Status = 'Open' LIMIT 1];
        caseRecord.NSP_Rating__c = 'Neutral';
        caseRecord.Status = 'Closed';
        caseRecord.RecordTypeId = casePEORecordTypeId;
        caseRecord.NSP_Category__c = 'Adaption';
        caseRecord.NSP_SubCategory__c = 'Claim';
        caseRecord.NSP_Date_Closed__c = Date.Today().addDays(-10);
        caseRecord.AccountId = acc.Id;
        caseRecord.assetId = null;
        caseRecord.ContactId = null;
        caseRecord.NSP_Category__c = 'Test Category';
        caseRecord.NSP_SubCategory__c = 'Test Sub-Category';
        caseRecord.Priority = 'Test Priority';
        caseRecord.Origin = 'Test Origin';
        caseRecord.Subject = 'Test Subject';
        caseRecord.ParentId = newCase.Id;
        update caseRecord;
        //Email message creation
        EmailMessage eMsg = new EmailMessage ();
        eMsg.FromAddress = 'test@test.com';
        eMsg.Incoming = True;
        eMsg.ToAddress= 'integrasupport@insperity.com';
        eMsg.Subject = 'Test email Subject';
        eMsg.HtmlBody = 'Test email body';
        eMsg.ParentId = newCase.id;
        //inserting Email message
        insert eMsg;
        //Create ContentVersion Test Record
        ContentVersion content=new ContentVersion();
        content.Title='Test_Header_Picture1';
        content.PathOnClient='/' + content.Title + '.jpg';
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body');
        content.VersionData=bodyBlob;
        content.origin = 'H';
        //inserting Content Version record.
        insert content;
        // Create ContentDocumentLink Test Record
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=eMsg.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers';
        //inserting ContentDocumentLink record.
        insert contentlink;
        CaseToSubjectMap.put(caseRecord,eMsg);
        ParentCaseToEmailMessageMap.put(caseRecord,eMsg);
        caseList.add(caseRecord);
        NSP_EmailMessageTriggerHelper.createCaseFromEmail(CaseToSubjectMap, contactCenterQueueId, null, null);
        NSP_EmailMessageTriggerHelper.updateRelatedCaseOnEmailMessage(ParentCaseToEmailMessageMap,caseList);
        Test.stopTest();
    }

    @isTest
    private static void markResponseAfterCloseMoreThanFiveForPEOTest2() {
        Test.startTest();
        Account acc = new Account(Name = 'test acc');
        Id casePEORecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'PEO' );
        ID contactCenterQueueId = ([SELECT ID FROM Group WHERE Type = :QUEUE AND DeveloperNAME = :CONTACTCENTERQUEUE]).ID;
        Map<Case,EmailMessage> CaseToSubjectMap = new Map<Case,EmailMessage>();
        Map<Case,EmailMessage> ParentCaseToEmailMessageMap = new Map<Case,EmailMessage>();
        List<Case> caseList = new List<Case>();
        EmailMessageTriggerSettings__c messageTriggerSetting = EmailMessageTriggerSettings__c.getOrgDefaults();
        messageTriggerSetting.isRelatedEmailMessageEnabled__c = false;
        upsert messageTriggerSetting;
        Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        insert newCase;
        newCase.NSP_Rating__c = 'Neutral';
        newCase.Status = 'Closed';
        newCase.RecordTypeId = casePEORecordTypeId;
        newCase.NSP_Category__c = 'Adaption';
        newCase.NSP_SubCategory__c = 'Claim';
        newCase.NSP_Date_Closed__c = Date.Today().addDays(-10);
        newCase.AccountId = acc.Id;
        newCase.assetId = null;
        newCase.ContactId = null;
        newCase.NSP_Category__c = 'Test Category';
        newCase.NSP_SubCategory__c = 'Test Sub-Category';
        newCase.Priority = 'Test Priority';
        newCase.Origin = 'Test Origin';
        newCase.Subject = 'Test Subject';
        update newCase;
        Case caseRecord = [SELECT id, Status FROM  Case WHERE Status = 'Open' LIMIT 1];
        caseRecord.NSP_Rating__c = 'Neutral';
        caseRecord.Status = 'Closed';
        caseRecord.RecordTypeId = casePEORecordTypeId;
        caseRecord.NSP_Category__c = 'Adaption';
        caseRecord.NSP_SubCategory__c = 'Claim';
        caseRecord.NSP_Date_Closed__c = Date.Today().addDays(-10);
        caseRecord.AccountId = acc.Id;
        caseRecord.assetId = null;
        caseRecord.ContactId = null;
        caseRecord.NSP_Category__c = 'Test Category';
        caseRecord.NSP_SubCategory__c = 'Test Sub-Category';
        caseRecord.Priority = 'Test Priority';
        caseRecord.Origin = 'Test Origin';
        caseRecord.Subject = 'Test Subject';
        caseRecord.ParentId = newCase.Id;
        update caseRecord;
        //Email message creation
        EmailMessage eMsg = new EmailMessage ();
        eMsg.FromAddress = 'test@test.com';
        eMsg.Incoming = True;
        eMsg.ToAddress= 'integrasupport@insperity.com';
        eMsg.Subject = 'Test email Subject';
        eMsg.HtmlBody = 'Test email body';
        eMsg.ParentId = newCase.id;
        //inserting Email message
        insert eMsg;
        //Create ContentVersion Test Record
        ContentVersion content=new ContentVersion();
        content.Title='Test_Header_Picture1';
        content.PathOnClient='/' + content.Title + '.jpg';
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body');
        content.VersionData=bodyBlob;
        content.origin = 'H';
        //inserting Content Version record.
        insert content;
        // Create ContentDocumentLink Test Record
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=eMsg.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers';
        //inserting ContentDocumentLink record.
        insert contentlink;
        CaseToSubjectMap.put(caseRecord,eMsg);
        ParentCaseToEmailMessageMap.put(caseRecord,eMsg);
        caseList.add(caseRecord);
        NSP_EmailMessageTriggerHelper.createCaseFromEmail(CaseToSubjectMap, contactCenterQueueId, null, null);
        NSP_EmailMessageTriggerHelper.updateRelatedCaseOnEmailMessage(ParentCaseToEmailMessageMap,caseList);
        Test.stopTest();
    }

    @isTest
    private static void markResponseAfterCloseLessThanFiveForPEOTest() {
        Test.startTest();
        Id casePEORecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'PEO' );
        Case caseRecord = [SELECT id, Status FROM  Case WHERE Status = 'Open' LIMIT 1];
        caseRecord.NSP_Rating__c = 'Neutral';
        caseRecord.Status = 'Closed';
        caseRecord.RecordTypeId = casePEORecordTypeId;
        caseRecord.NSP_Category__c = 'Adaption';
        caseRecord.NSP_SubCategory__c = 'Claim';
        caseRecord.NSP_Date_Closed__c = Date.Today();
        update caseRecord;
        //Email message creation
        EmailMessage eMsg = new EmailMessage ();
        eMsg.FromAddress = 'test@test.com';
        eMsg.Incoming = True;
        eMsg.ToAddress= CONTACTCENTER;
        eMsg.Subject = 'Test email Subject';
        eMsg.HtmlBody = 'Test email body';
        eMsg.ParentId = caseRecord.id;
        //inserting Email message
        insert eMsg;
        Test.stopTest();

    }


    @isTest
    private static void markResponseAfterCloseWithSourceOutlook() {
        Test.startTest();
        Id casePEORecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'PEO' );
        EmailMessageTriggerSettings__c asyncSwitchSetting = EmailMessageTriggerSettings__c.getOrgDefaults();
        asyncSwitchSetting.IsAfterInsertQueueableEnabled__c = true;
        upsert asyncSwitchSetting;
        List<Case> caseRecordList = [SELECT id, Status FROM  Case WHERE Status = 'Open' LIMIT 1];
        System.assertNotEquals(null, caseRecordList);
        System.assertNotEquals(true, caseRecordList.isEmpty());
        Case caseRecord = caseRecordList[0];
        caseRecord.NSP_Rating__c = 'Neutral';
        caseRecord.Status = 'Closed';
        caseRecord.RecordTypeId = casePEORecordTypeId;
        caseRecord.NSP_Category__c = 'Adaption';
        caseRecord.NSP_SubCategory__c = 'Claim';
        caseRecord.NSP_Date_Closed__c = Date.Today();
        update caseRecord;
        //Email message creation
        EmailMessage eMsg = new EmailMessage ();
        eMsg.FromAddress = 'test@test.com';
        eMsg.Incoming = True;
        eMsg.ToAddress= CONTACTCENTER;
        eMsg.Subject = 'Test email Subject';
        eMsg.HtmlBody = 'Test email body';
        eMsg.ParentId = caseRecord.id;
        eMsg.Source = 'Email Integration App Manual';
        //inserting Email message
        insert eMsg;
        List<Case> updatedCase = [SELECT Status FROM Case WHERE ID = : caseRecord.id LIMIT 1];
        System.assertNotEquals(null, updatedCase);
        System.assertNotEquals(true, updatedCase.isEmpty());
        System.assertEquals('Closed', updatedCase[0].Status);
        Test.stopTest();
    }

}
//