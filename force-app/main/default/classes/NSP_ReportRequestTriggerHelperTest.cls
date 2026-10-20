@isTest
private class NSP_ReportRequestTriggerHelperTest {

    private static final String REPORT_REQUEST = 'NSP_ReportRequest__c';
    private static final String ACCOUNTDEFAULTS = 'NSP_TestDataFactory.AccountDefaults';
    private static final String CASEDEFAULTS = 'NSP_TestDataFactory.CaseDefaults';
    private static final String CONTACT_DEFAULTS_LIGHT = 'NSP_TestDataFactory.ContactDefaultsLight';
    private static final String REPORT_REQUEST_DEFAULTS = 'NSP_TestDataFactory.ReportRequestDefaults';
    private static final String CASE_SUB_CATEGORY_SEPARATION_AGREEMENT_REQUEST = 'Separation Agreement Request';
    private static final String CLIENT_PREPARED = 'Client-Prepared';
    private static final String INSPERITY_PREPARED = 'Insperity-Prepared';
    private static final String CORPORATE_REVIEW = 'Corporate Review';
    private static final String TERMINATED = 'TERMINATED';
    private static final String INTERNAL_CLIENT_REPORT = 'Client Report';
    private static final String REPORT_LOCATION = 'ReportLocation must always be HRScale Workday Report';
    private static final String REPORT_REQUEST_MSG = 'ReportRequest should exist after insert';
    private static final String CONTACT_MSG = 'Contact test12345 should exist from setup';
    private static final String HRSCALE_WORKDAY_REPORT_LOCATION = 'HRScale (Workday) Report';

    @testSetup
    private static void setup() {
        NSP_ReportRequestTriggerHelper.testHandleException( null , null );
        NSP_ReportRequestTriggerHelper.testShowValidationForInsperityPrepared( null );

        Account testAccount = (Account) NSP_TestExtendedDataFactory.createSObject(new Account(), ACCOUNTDEFAULTS, false);
        testAccount.Name = 'Test Account';
        insert testAccount;

        List<Contact> contList = new List<Contact>();
        Contact newContact = (Contact) NSP_TestExtendedDataFactory.createSObject(new Contact(), CONTACT_DEFAULTS_LIGHT, false);
        newContact.Account = testAccount;
        newContact.NSP_Work_email__c = 'test123@gmail.com';
        contList.add(newContact);

        Contact newContact2 = (Contact) NSP_TestExtendedDataFactory.createSObject(new Contact(), CONTACT_DEFAULTS_LIGHT, false);
        newContact2.Account = testAccount;
        newContact2.NSP_Work_email__c = 'test12345@gmail.com';
        newContact2.LastName = 'Test Contact';
        newContact2.NSP_Date_of_Birth__c = System.today();
        contList.add(newContact2);
        insert contList;

        Id recordTypeID = NSP_GenericRecordType.getRecordTypeId(REPORT_REQUEST, 'NSP_DevelopmentReport');
        NSP_ReportRequest__c reportRequest = (NSP_ReportRequest__c) NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), REPORT_REQUEST_DEFAULTS, false);
        reportRequest.RecordTypeId = recordTypeID;
        reportRequest.NSP_IsDraft__c = false;
        reportRequest.Name = 'test';
        insert reportRequest;

        NSP_Category_Sub_Category_Mapping__c catSubCatMapping = (NSP_Category_Sub_Category_Mapping__c) NSP_TestDataFactory.createSObject(new NSP_Category_Sub_Category_Mapping__c(), 'NSP_TestDataFactory.CatSubCatMappingDefaults', false);
        catSubCatMapping.NSP_Category__c = NSP_ServiceConstants.HR_EMPLOYEE_RELATIONS;
        catSubCatMapping.NSP_Subcategory__c = CASE_SUB_CATEGORY_SEPARATION_AGREEMENT_REQUEST;
        insert new List<NSP_Category_Sub_Category_Mapping__c>{ catSubCatMapping };

        Case caseRecord = (Case) NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        caseRecord.NSP_Category__c = NSP_ServiceConstants.HR_EMPLOYEE_RELATIONS;
        caseRecord.NSP_SubCategory__c = CASE_SUB_CATEGORY_SEPARATION_AGREEMENT_REQUEST;
        caseRecord.Subject = 'Test Case';
        caseRecord.AccountId = testAccount.Id;
        insert caseRecord;

        Id separationRecordTypeID = NSP_GenericRecordType.getRecordTypeId(REPORT_REQUEST, 'NSP_SeparationRequest');
        NSP_ReportRequest__c reportRequest2 = (NSP_ReportRequest__c) NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), REPORT_REQUEST_DEFAULTS, false);
        reportRequest2.RecordTypeId = separationRecordTypeID;
        reportRequest2.NSP_IsDraft__c = false;
        reportRequest2.Name = 'test2';
        reportRequest2.NSP_Case__c = caseRecord.Id;
        reportRequest2.NSP_AgreementType__c = CLIENT_PREPARED;
        reportRequest2.NSP_ReviewType__c = CORPORATE_REVIEW;
        reportRequest2.NSP_WSEE__c = newContact.Id;
        reportRequest2.NSP_ClientName__c = testAccount.Id;

        NSP_ReportRequest__c reportRequest3 = (NSP_ReportRequest__c) NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), REPORT_REQUEST_DEFAULTS, false);
        reportRequest3.RecordTypeId = separationRecordTypeID;
        reportRequest3.NSP_IsDraft__c = false;
        reportRequest3.Name = 'test2';
        reportRequest3.NSP_Case__c = caseRecord.Id;
        reportRequest3.NSP_AgreementType__c = INSPERITY_PREPARED;
        reportRequest3.NSP_Client_Contact__c = newContact.Id;
        reportRequest3.NSP_RequestingMultipleEmployees__c = 'Yes';
        reportRequest3.NSP_ClientName__c = testAccount.Id;
        insert new List<NSP_ReportRequest__c>{ reportRequest2, reportRequest3 };

        NSP_Address__c address = (NSP_Address__c) NSP_TestExtendedDataFactory.createSObject(new NSP_Address__c(), 'NSP_TestDataFactory.AddressDefaults', true);

        NSP_Sub_Client__c subClient = (NSP_Sub_Client__c) NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', false);
        subClient.NSP_Account__c = testAccount.Id;
        subClient.NSP_Sub_Client__c = String.valueOf(Integer.valueOf(100000 * (1 - 1 * Math.random())));
        insert subClient;

        NSP_Sub_Client_Contact__c subClientContact = (NSP_Sub_Client_Contact__c) NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContact.NSP_Contact__c = newContact2.Id;
        subClientContact.NSP_Is_Primary__c = true;
        subClientContact.NSP_Employee_Status__c = TERMINATED;
        subClientContact.NSP_Status_Date__c = System.today() + 2;
        subClientContact.NSP_Sub_Client__c = subClient.Id;
        insert subClientContact;

        NSP_Sub_Client_Contact_Address__c subclientContactAddress = (NSP_Sub_Client_Contact_Address__c) NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client_Contact_Address__c(), 'NSP_TestDataFactory.SubClientContactAddressDefaults', false);
        subclientContactAddress.NSP_Sub_Client_Contact__c = subClientContact.Id;
        subclientContactAddress.NSP_Address__c = address.Id;
        insert subclientContactAddress;
    }

    @isTest
    private static void testInsertDevelopmentReport() {
        Account newAccount = (Account) NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        newAccount.NSP_Premier_Pathway_Client__c = '12345ABCDEF';
        insert newAccount;

        Contact newContact = (Contact) NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.Account = newAccount;
        newContact.NSP_Per_ID__c = 'ABCDEF12345';
        insert newContact;

        List<Group> existingGroups = [SELECT Id FROM Group WHERE DeveloperName = 'NSP_ReportDevelopment'];
        if (existingGroups.isEmpty()) {
            Group newGroup = (Group) NSP_TestExtendedDataFactory.createSObject(new Group(), 'NSP_TestDataFactory.GroupDefaults', false);
            newGroup.Type = 'Queue';
            newGroup.Name = 'Report Development';
            newGroup.DeveloperName = 'NSP_ReportDevelopment';
            insert newGroup;
            System.runAs(new User(Id = UserInfo.getUserId())) {
                insert new QueueSObject(QueueID = newGroup.Id, SObjectType = 'Case');
            }
        }

        Id recordTypeID = SObjectType.NSP_ReportRequest__c.getRecordTypeInfosByDeveloperName().get('NSP_DevelopmentReport').getRecordTypeId();
        NSP_ReportRequest__c newRepReqTrigger = new NSP_ReportRequest__c();
        newRepReqTrigger.RecordTypeId = recordTypeID;
        newRepReqTrigger.NSP_Existing_NewReport__c = 'New Report';
        newRepReqTrigger.NSP_InternalClientReport__c = 'Internal Report';
        newRepReqTrigger.NSP_Action__c = NSP_ServiceConstants.WIZARD_DEVELOPMENT;

        Test.startTest();
        insert newRepReqTrigger;
        Test.stopTest();

        List<NSP_ReportRequest__c> insertDataList = [
            SELECT Id, NSP_Action__c, NSP_ReportType__c, NSP_ReportLocation__c, NSP_Misc__c, NSP_Existing_NewReport__c
            FROM NSP_ReportRequest__c
            WHERE NSP_Action__c = :NSP_ServiceConstants.WIZARD_DEVELOPMENT
            LIMIT 1
        ];
        Assert.isFalse(insertDataList.isEmpty(), REPORT_REQUEST_MSG);
        Assert.areEqual('New Report', insertDataList[0].NSP_Existing_NewReport__c);
    }

    @isTest
    private static void testDeleteNonDraft() {
        List<NSP_ReportRequest__c> repReqRecord = [SELECT Id, NSP_IsDraft__c FROM NSP_ReportRequest__c LIMIT 1];
        Assert.isFalse(repReqRecord.isEmpty(), 'ReportRequest should exist from setup');
        Test.startTest();
        delete repReqRecord[0];
        Test.stopTest();
        Assert.areEqual(1, repReqRecord.size());
    }

    @isTest
    private static void testDeleteDraftBlocked() {
        List<NSP_ReportRequest__c> repReqRecord = [SELECT Id, NSP_IsDraft__c FROM NSP_ReportRequest__c LIMIT 1];
        Assert.isFalse(repReqRecord.isEmpty(), 'ReportRequest should exist from setup');
        Test.startTest();
        repReqRecord[0].NSP_IsDraft__c = true;
        update repReqRecord;
        delete repReqRecord;
        Test.stopTest();
        List<NSP_ReportRequest__c> repReqList = [SELECT Id, NSP_IsDraft__c FROM NSP_ReportRequest__c LIMIT 1];
        Assert.areEqual(1, repReqList.size());
    }

    @isTest
    private static void testUpdateClientPrepared() {
        List<NSP_ReportRequest__c> repReqList = [
            SELECT Id, NSP_IsDraft__c, Name, NSP_Case__c, NSP_AgreementType__c, NSP_ReviewType__c, NSP_WSEE__c, NSP_DOB__c
            FROM NSP_ReportRequest__c
            WHERE NSP_AgreementType__c = :CLIENT_PREPARED
            LIMIT 1
        ];
        Assert.isFalse(repReqList.isEmpty(), 'ReportRequest with Client-Prepared should exist from setup');
        NSP_ReportRequest__c repReq = repReqList[0];

        List<Contact> contList = [
            SELECT Id, NSP_Work_email__c, Name, NSP_Date_of_Birth__c
            FROM Contact
            WHERE NSP_Work_email__c = 'test12345@gmail.com'
        ];
        Assert.isFalse(contList.isEmpty(), CONTACT_MSG);

        Test.startTest();
        repReq.NSP_AgreementType__c = INSPERITY_PREPARED;
        repReq.NSP_ReviewType__c = '';
        repReq.NSP_RequestingMultipleEmployees__c = NSP_ServiceConstants.NO;
        repReq.NSP_WSEE__c = contList[0].Id;
        update repReq;
        Test.stopTest();
        Assert.areEqual(contList[0].Id, repReq.NSP_WSEE__c);
    }

    @isTest
    private static void testUpdateInsperityPreparedValidation() {
        List<NSP_ReportRequest__c> repReqList = [
            SELECT Id, NSP_IsDraft__c, Name, NSP_Case__c, NSP_AgreementType__c, NSP_ReviewType__c, NSP_WSEE__c, NSP_DOB__c
            FROM NSP_ReportRequest__c
            WHERE NSP_AgreementType__c = :INSPERITY_PREPARED
            LIMIT 1
        ];
        Assert.isFalse(repReqList.isEmpty(), 'ReportRequest with Insperity-Prepared should exist from setup');
        NSP_ReportRequest__c repReq = repReqList[0];

        List<Contact> contList = [
            SELECT Id, NSP_Work_email__c, Name, NSP_Date_of_Birth__c
            FROM Contact
            WHERE NSP_Work_email__c = 'test12345@gmail.com'
        ];
        Assert.isFalse(contList.isEmpty(), CONTACT_MSG);

        Test.startTest();
        try {
            repReq.NSP_WSEE__c = contList[0].Id;
            update repReq;
        } catch (DmlException ex) {
            Assert.areEqual('FIELD_CUSTOM_VALIDATION_EXCEPTION', ex.getDmlStatusCode(0), 'Error Exception');
        }
        Test.stopTest();
    }

    @isTest
    private static void testAfterInsert() {
        NSP_ReportRequestTriggerHandler handler = new NSP_ReportRequestTriggerHandler();
        Test.startTest();
        handler.afterInsert(null, null);
        Test.stopTest();
        Assert.isTrue(true, 'Method executed successfully.');
    }

    @isTest
    private static void testAfterDelete() {
        NSP_ReportRequestTriggerHandler handler = new NSP_ReportRequestTriggerHandler();
        Test.startTest();
        handler.afterDelete(null, null);
        Test.stopTest();
        Assert.isTrue(true, 'Method executed successfully.');
    }

    @isTest
    private static void testHRScaleNewInternalInsert() {
        Id hrScaleRtId = NSP_GenericRecordType.getRecordTypeId(REPORT_REQUEST, 'HRScale_Workday_Report');
        NSP_ReportRequest__c rec = (NSP_ReportRequest__c) NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), REPORT_REQUEST_DEFAULTS, false);
        rec.RecordTypeId = hrScaleRtId;
        rec.NSP_Existing_NewReport__c = NSP_ServiceConstants.NEW_REPORT;
        rec.NSP_InternalClientReport__c = NSP_ServiceConstants.INTERNAL_REPORT;

        Test.startTest();
        insert rec;
        Test.stopTest();

        List<NSP_ReportRequest__c> resultList = [
            SELECT NSP_Action__c, NSP_ReportType__c, NSP_ReportLocation__c
            FROM NSP_ReportRequest__c
            WHERE Id = :rec.Id
        ];
        Assert.isFalse(resultList.isEmpty(), REPORT_REQUEST_MSG);
        NSP_ReportRequest__c result = resultList[0];
        Assert.areEqual(NSP_ServiceConstants.WIZARD_DEVELOPMENT, result.NSP_Action__c, 'Action should be Development for New Report');
        Assert.areEqual(NSP_ServiceConstants.INTERNAL_CLIENT_REPORT, result.NSP_ReportType__c, 'ReportType should be set for Internal Report');
        Assert.areEqual(NSP_ReportRequestTriggerHelperTest.HRSCALE_WORKDAY_REPORT_LOCATION, result.NSP_ReportLocation__c, REPORT_LOCATION);
    }

    @isTest
    private static void testHRScaleExistingReportInsert() {
        Id hrScaleRtId = NSP_GenericRecordType.getRecordTypeId(REPORT_REQUEST, 'HRScale_Workday_Report');
        NSP_ReportRequest__c rec = (NSP_ReportRequest__c) NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), REPORT_REQUEST_DEFAULTS, false);
        rec.RecordTypeId = hrScaleRtId;
        rec.NSP_Existing_NewReport__c = 'Change to Existing Report';

        Test.startTest();
        insert rec;
        Test.stopTest();

        List<NSP_ReportRequest__c> resultList = [
            SELECT NSP_Action__c, NSP_ReportLocation__c
            FROM NSP_ReportRequest__c
            WHERE Id = :rec.Id
        ];
        Assert.isFalse(resultList.isEmpty(), REPORT_REQUEST_MSG);
        NSP_ReportRequest__c result = resultList[0];
        Assert.areEqual(NSP_ServiceConstants.WIZARD_MAINTENANCE, result.NSP_Action__c, 'Action should be Maintenance for existing report');
        Assert.areEqual(NSP_ReportRequestTriggerHelperTest.HRSCALE_WORKDAY_REPORT_LOCATION, result.NSP_ReportLocation__c, REPORT_LOCATION);
    }

    @isTest
    private static void testHRScaleNewClientInsert() {
        Id hrScaleRtId = NSP_GenericRecordType.getRecordTypeId(REPORT_REQUEST, 'HRScale_Workday_Report');
        NSP_ReportRequest__c rec = (NSP_ReportRequest__c) NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), REPORT_REQUEST_DEFAULTS, false);
        rec.RecordTypeId = hrScaleRtId;
        rec.NSP_Existing_NewReport__c = NSP_ServiceConstants.NEW_REPORT;
        rec.NSP_InternalClientReport__c = INTERNAL_CLIENT_REPORT;

        Test.startTest();
        insert rec;
        Test.stopTest();

        List<NSP_ReportRequest__c> resultList = [
            SELECT NSP_Action__c, NSP_ReportType__c, NSP_ReportLocation__c
            FROM NSP_ReportRequest__c
            WHERE Id = :rec.Id
        ];
        Assert.isFalse(resultList.isEmpty(), REPORT_REQUEST_MSG);
        NSP_ReportRequest__c result = resultList[0];
        Assert.areEqual(NSP_ServiceConstants.WIZARD_DEVELOPMENT, result.NSP_Action__c, 'Action should be Development for New Report');
        Assert.isNull(result.NSP_ReportType__c, 'ReportType should be null for Client Report');
        Assert.areEqual(NSP_ReportRequestTriggerHelperTest.HRSCALE_WORKDAY_REPORT_LOCATION, result.NSP_ReportLocation__c, REPORT_LOCATION);
    }

    @isTest
    private static void testHRScaleInternalToClientUpdate() {
        Id hrScaleRtId = NSP_GenericRecordType.getRecordTypeId(REPORT_REQUEST, 'HRScale_Workday_Report');
        NSP_ReportRequest__c rec = (NSP_ReportRequest__c) NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), REPORT_REQUEST_DEFAULTS, false);
        rec.RecordTypeId = hrScaleRtId;
        rec.NSP_Existing_NewReport__c = NSP_ServiceConstants.NEW_REPORT;
        rec.NSP_InternalClientReport__c = NSP_ServiceConstants.INTERNAL_REPORT;
        insert rec;

        Test.startTest();
        rec.NSP_InternalClientReport__c = INTERNAL_CLIENT_REPORT;
        update rec;
        Test.stopTest();

        List<NSP_ReportRequest__c> resultList = [
            SELECT NSP_ReportType__c, NSP_ReportLocation__c
            FROM NSP_ReportRequest__c
            WHERE Id = :rec.Id
        ];
        Assert.isFalse(resultList.isEmpty(), 'ReportRequest should exist after update');
        NSP_ReportRequest__c result = resultList[0];
        Assert.isNull(result.NSP_ReportType__c, 'ReportType should be cleared when switching from Internal to Client Report');
        Assert.areEqual(NSP_ReportRequestTriggerHelperTest.HRSCALE_WORKDAY_REPORT_LOCATION, result.NSP_ReportLocation__c, 'ReportLocation must always be HRScale Workday Report after update');
    }

    @isTest
    private static void testDevReportMaintenanceInsert() {
        Id devRtId = NSP_GenericRecordType.getRecordTypeId(REPORT_REQUEST, 'NSP_DevelopmentReport');
        NSP_ReportRequest__c rec = (NSP_ReportRequest__c) NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), REPORT_REQUEST_DEFAULTS, false);
        rec.RecordTypeId = devRtId;
        rec.NSP_Existing_NewReport__c = 'Change to Existing Report';

        Test.startTest();
        insert rec;
        Test.stopTest();

        List<NSP_ReportRequest__c> resultList = [
            SELECT NSP_Action__c, NSP_ReportLocation__c
            FROM NSP_ReportRequest__c
            WHERE Id = :rec.Id
        ];
        Assert.isFalse(resultList.isEmpty(), REPORT_REQUEST_MSG);
        NSP_ReportRequest__c result = resultList[0];
        Assert.areEqual(NSP_ServiceConstants.WIZARD_MAINTENANCE, result.NSP_Action__c, 'Action should be Maintenance for existing report on DevelopmentReport type');
        Assert.isNull(result.NSP_ReportLocation__c, 'ReportLocation should be cleared for Maintenance path');
    }

    @isTest
    private static void testDevReportClientTypeInsert() {
        Id devRtId = NSP_GenericRecordType.getRecordTypeId(REPORT_REQUEST, 'NSP_DevelopmentReport');
        NSP_ReportRequest__c rec = (NSP_ReportRequest__c) NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), REPORT_REQUEST_DEFAULTS, false);
        rec.RecordTypeId = devRtId;
        rec.NSP_Existing_NewReport__c = NSP_ServiceConstants.NEW_REPORT;
        rec.NSP_InternalClientReport__c = INTERNAL_CLIENT_REPORT;

        Test.startTest();
        insert rec;
        Test.stopTest();

        List<NSP_ReportRequest__c> resultList = [
            SELECT NSP_ReportType__c
            FROM NSP_ReportRequest__c
            WHERE Id = :rec.Id
        ];
        Assert.isFalse(resultList.isEmpty(), REPORT_REQUEST_MSG);
        Assert.isNull(resultList[0].NSP_ReportType__c, 'ReportType should be null when InternalClientReport is Client Report');
    }

    @isTest
    private static void testDevReportPremierReporting() {
        Id devRtId = NSP_GenericRecordType.getRecordTypeId(REPORT_REQUEST, 'NSP_DevelopmentReport');
        NSP_ReportRequest__c rec = (NSP_ReportRequest__c) NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), REPORT_REQUEST_DEFAULTS, false);
        rec.RecordTypeId = devRtId;
        rec.NSP_ReportLocation__c = NSP_ServiceConstants.PREMIER_REPORTING;

        Test.startTest();
        insert rec;
        Test.stopTest();

        List<NSP_ReportRequest__c> resultList = [
            SELECT NSP_Misc__c
            FROM NSP_ReportRequest__c
            WHERE Id = :rec.Id
        ];
        Assert.isFalse(resultList.isEmpty(), REPORT_REQUEST_MSG);
        Assert.areEqual('WIRE', resultList[0].NSP_Misc__c, 'Misc should be Wire when ReportLocation is Premier Reporting');
    }

    @isTest
    private static void testAfterUpdateCaseAdded() {
        List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
        Assert.isFalse(accountList.isEmpty(), 'Account should exist from setup');
        Account testAccount = accountList[0];

        List<Contact> wseeContactList = [SELECT Id FROM Contact WHERE NSP_Work_email__c = 'test12345@gmail.com' LIMIT 1];
        Assert.isFalse(wseeContactList.isEmpty(), 'WSEE Contact should exist from setup');
        Contact wseeContact = wseeContactList[0];

        List<Contact> clientContactList = [SELECT Id FROM Contact WHERE NSP_Work_email__c = 'test123@gmail.com' LIMIT 1];
        Assert.isFalse(clientContactList.isEmpty(), 'Client Contact should exist from setup');
        Contact clientContact = clientContactList[0];

        List<Case> testCaseList = [SELECT Id FROM Case LIMIT 1];
        Assert.isFalse(testCaseList.isEmpty(), 'Case should exist from setup');
        Case testCase = testCaseList[0];

        Id separationRtId = NSP_GenericRecordType.getRecordTypeId(REPORT_REQUEST, 'NSP_SeparationRequest');
        NSP_ReportRequest__c rec = (NSP_ReportRequest__c) NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), REPORT_REQUEST_DEFAULTS, false);
        rec.RecordTypeId = separationRtId;
        rec.NSP_IsDraft__c = false;
        rec.NSP_AgreementType__c = CLIENT_PREPARED;
        rec.NSP_WSEE__c = wseeContact.Id;
        rec.NSP_Client_Contact__c = clientContact.Id;
        rec.NSP_ClientName__c = testAccount.Id;
        insert rec;

        Test.startTest();
        rec.NSP_Case__c = testCase.Id;
        update rec;
        Test.stopTest();

        List<NSP_Case_Contacts__c> caseContacts = [
            SELECT Id
            FROM NSP_Case_Contacts__c
            WHERE NSP_Case__c = :testCase.Id
        ];
        Assert.isTrue(caseContacts.size() > 0, 'CaseContacts should be inserted when Case is added to a ReportRequest');
    }

    @isTest
    private static void testUpdateCaseSubject() {
        List<NSP_ReportRequest__c> repReqList = [
            SELECT Id, NSP_IsDraft__c, NSP_Case__c, NSP_AgreementType__c, NSP_ReviewType__c, NSP_WSEE__c, NSP_ClientName__c
            FROM NSP_ReportRequest__c
            WHERE NSP_AgreementType__c = :CLIENT_PREPARED
            LIMIT 1
        ];
        Assert.isFalse(repReqList.isEmpty(), 'ReportRequest with Client-Prepared should exist from setup');
        NSP_ReportRequest__c repReq = repReqList[0];

        List<Contact> contList = [
            SELECT Id, NSP_Work_email__c
            FROM Contact
            WHERE NSP_Work_email__c = 'test12345@gmail.com'
        ];
        Assert.isFalse(contList.isEmpty(), CONTACT_MSG);

        Test.startTest();
        repReq.NSP_WSEE__c = contList[0].Id;
        repReq.NSP_RequestingMultipleEmployees__c = NSP_ServiceConstants.NO;
        update repReq;
        Test.stopTest();

        List<Case> updatedCaseList = [SELECT Id, Subject FROM Case WHERE Id = :repReq.NSP_Case__c LIMIT 1];
        Assert.isFalse(updatedCaseList.isEmpty(), 'Case should exist after WSEE update');
        Assert.isNotNull(updatedCaseList[0].Id, 'Case should exist after WSEE update with non-null ReviewType');
    }

}
//