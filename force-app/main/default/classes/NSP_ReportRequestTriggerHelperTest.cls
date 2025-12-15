@isTest
private class NSP_ReportRequestTriggerHelperTest {

    private static final String REPORT_REQUEST = 'NSP_ReportRequest__c';
    private static final String ACCOUNTDEFAULTS = 'NSP_TestDataFactory.AccountDefaults';
    private static final String CASEDEFAULTS  = 'NSP_TestDataFactory.CaseDefaults';
    private static final String CONTACT_DEFAULTS_LIGHT = 'NSP_TestDataFactory.ContactDefaultsLight';
    private static final String CASE_SUB_CATEGORY_SEPARATION_AGREEMENT_REQUEST = 'Separation Agreement Request';
    private static final String REPORT_REQUEST_DEFAULTS = 'NSP_TestDataFactory.ReportRequestDefaults';
    private static final String CLIENT_PREPARED = 'Client-Prepared';
    private static final String INSPERITY_PREPARED = 'Insperity-Prepared';
    private static final String CORPORATE_REVIEW = 'Corporate Review';
    private static final String TERMINATED = 'TERMINATED';

    //setup
    @testSetup
    private static void setup() {
        NSP_ReportRequestTriggerHelper.testHandleException( null , null );
        NSP_ReportRequestTriggerHelper.testShowValidationForInsperityPrepared( null );

        Account testAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), ACCOUNTDEFAULTS, false);
        testAccount.Name = 'Test Account';
        insert testAccount;

        List<Contact> contList = new List<Contact>();
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), CONTACT_DEFAULTS_LIGHT, false);
        newContact.Account = testAccount;
        newContact.NSP_Work_email__c = 'test123@gmail.com';
        contList.add(newContact);

        Contact newContact2 = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), CONTACT_DEFAULTS_LIGHT, false);
        newContact2.Account = testAccount;
        newContact2.NSP_Work_email__c = 'test12345@gmail.com';
        newContact2.LastName = 'Test Contact';
        newContact2.NSP_Date_of_Birth__c = System.today();
        contList.add(newContact2);
        insert contList;

        Id recordTypeID = NSP_GenericRecordType.getRecordTypeId(REPORT_REQUEST,'NSP_DevelopmentReport');
        NSP_ReportRequest__c reportrequest = (NSP_ReportRequest__c)NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), REPORT_REQUEST_DEFAULTS, false);
        reportrequest.RecordTypeId = recordTypeID;
        reportrequest.NSP_IsDraft__c=false;
        reportrequest.name='test';
        insert reportrequest;

        List<NSP_Category_Sub_Category_Mapping__c> catSubCatMappingList = new List<NSP_Category_Sub_Category_Mapping__c>();
        NSP_Category_Sub_Category_Mapping__c catSubCatMapping = (NSP_Category_Sub_Category_Mapping__c) NSP_TestDataFactory.createSObject(new NSP_Category_Sub_Category_Mapping__c(), 'NSP_TestDataFactory.CatSubCatMappingDefaults', false);
        catSubCatMapping.NSP_Category__c = NSP_ServiceConstants.HR_EMPLOYEE_RELATIONS;
        catSubCatMapping.NSP_Subcategory__c = CASE_SUB_CATEGORY_SEPARATION_AGREEMENT_REQUEST;
        catSubCatMappingList.add(catSubCatMapping);
        insert catSubCatMappingList;

        Case CaseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        CaseRecord.NSP_Category__c = NSP_ServiceConstants.HR_EMPLOYEE_RELATIONS;
        CaseRecord.NSP_SubCategory__c = CASE_SUB_CATEGORY_SEPARATION_AGREEMENT_REQUEST;
        CaseRecord.Subject = 'Test Case';
        CaseRecord.AccountId = testAccount.Id;
        insert CaseRecord;

        List<NSP_ReportRequest__c> reportRequestList = new List<NSP_ReportRequest__c>();
        Id separationRecordTypeID = NSP_GenericRecordType.getRecordTypeId(REPORT_REQUEST,'NSP_SeparationRequest');
        NSP_ReportRequest__c reportrequest2 = (NSP_ReportRequest__c)NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), REPORT_REQUEST_DEFAULTS, false);
        reportrequest2.RecordTypeId = separationRecordTypeID;
        reportrequest2.NSP_IsDraft__c=false;
        reportrequest2.name='test2';
        reportrequest2.NSP_Case__c = CaseRecord.Id;
        reportrequest2.NSP_AgreementType__c = CLIENT_PREPARED;
        reportrequest2.NSP_ReviewType__c = CORPORATE_REVIEW;
        reportrequest2.NSP_WSEE__c = newContact.Id;
        reportrequest2.NSP_ClientName__c = testAccount.Id;
        reportRequestList.add(reportrequest2);

        NSP_ReportRequest__c reportrequest3 = (NSP_ReportRequest__c)NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), REPORT_REQUEST_DEFAULTS, false);
        reportrequest3.RecordTypeId = separationRecordTypeID;
        reportrequest3.NSP_IsDraft__c=false;
        reportrequest3.name='test2';
        reportrequest3.NSP_Case__c = CaseRecord.Id;
        reportrequest3.NSP_AgreementType__c = INSPERITY_PREPARED;
        reportrequest3.NSP_Client_Contact__c = newContact.Id;
        reportrequest3.NSP_RequestingMultipleEmployees__c = 'Yes';
        reportrequest3.NSP_ClientName__c = testAccount.Id;
        reportRequestList.add(reportrequest3);
        insert reportRequestList;

        NSP_Address__c address = (NSP_Address__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Address__c(), 'NSP_TestDataFactory.AddressDefaults', True);

        NSP_Sub_Client__c subClient = (NSP_Sub_Client__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', false);
        subClient.NSP_Account__c = testAccount.Id;
        subClient.NSP_Sub_Client__c = String.valueOf(Integer.valueOf((100000 * ( 1 -  1 * Math.random()))));
        insert subClient;

        NSP_Sub_Client_Contact__c subClientContact = (NSP_Sub_Client_Contact__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContact.NSP_Contact__c = newContact2.Id;
        subClientContact.NSP_Is_Primary__c = True;
        subClientContact.NSP_Employee_Status__c = TERMINATED;
        subClientContact.NSP_Status_Date__c = System.today()+2;
        subClientContact.NSP_Sub_Client__c= subClient.Id;
        insert subClientContact;

        NSP_Sub_Client_Contact_Address__c subclientContactAddress = (NSP_Sub_Client_Contact_Address__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client_Contact_Address__c(), 'NSP_TestDataFactory.SubClientContactAddressDefaults', false);
        subclientContactAddress.NSP_Sub_Client_Contact__c = subClientContact.Id;
        subclientContactAddress.NSP_Address__c = address.id;
        insert subclientContactAddress;
    }

    @isTest
    private static void testCaseTriggerOperation() {
        // create account details
        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        newAccount.NSP_Premier_Pathway_Client__c ='12345ABCDEF';
        //insert account
        insert newAccount;

        //create contact details
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.Account = newAccount;
        newContact.NSP_Per_ID__c ='ABCDEF12345';
        // insert conact
        insert newContact;

        //create group
        Group newGroup;
        if([Select ID from Group WHERE DeveloperName ='NSP_ReportDevelopment']?.size() == 0 ){
            newGroup= (Group)NSP_TestExtendedDataFactory.createSObject(new Group(), 'NSP_TestDataFactory.GroupDefaults', false);
            newGroup.Type ='Queue';
            newGroup.name ='Report Development';
            newGroup.DeveloperName ='NSP_ReportDevelopment' ;
            //insert group
            insert newGroup;

            //create queue and insert
            QueuesObject testQueue = new QueueSObject(QueueID = newGroup.id, SObjectType = 'Case');
            System.runAs(new User(Id = UserInfo.getUserId())){
            insert testQueue;}
        }

        Id recordTypeID = SObjectType.NSP_ReportRequest__c.getRecordTypeInfosByDeveloperName().get('NSP_DevelopmentReport').getRecordTypeId();

        //create report request
        NSP_ReportRequest__c newRepReqTrigger = new NSP_ReportRequest__c();
        newRepReqTrigger.RecordTypeId =recordTypeID;
        newRepReqTrigger.NSP_Existing_NewReport__c = 'New Report';
        newRepReqTrigger.NSP_InternalClientReport__c ='Internal Report';
        newRepReqTrigger.NSP_Action__c = NSP_ServiceConstants.WIZARD_DEVELOPMENT;
        // insert report request
        insert newRepReqTrigger;

        NSP_ReportRequest__c  insertData = [SELECT Id,NSP_Action__c,NSP_ReportType__c,NSP_ReportLocation__c,NSP_Misc__c, NSP_Existing_NewReport__c
                                            FROM NSP_ReportRequest__c WHERE NSP_Action__c =: NSP_ServiceConstants.WIZARD_DEVELOPMENT LIMIT 1];
        System.assertEquals(insertData.NSP_Existing_NewReport__c, 'New Report');
    }

    @isTest
    private static void testWizardDelete() {
        List<String> repReqFields = new List<String>{'Id','NSP_IsDraft__c'};
        String query = new NSP_QueryBuilder(REPORT_REQUEST, repReqFields)
                          .addLimit(1).build();
        List<NSP_ReportRequest__c> repReqRecord = Database.query(query);
        Test.startTest();
        delete repReqRecord[0];
        Test.stopTest();
        System.assertEquals(repReqRecord.size(),1);
    }

    @isTest
    private static void testWizardDeleteNegative() {
        List<String> repReqFields = new List<String>{'Id','NSP_IsDraft__c'};
        String query = new NSP_QueryBuilder(REPORT_REQUEST, repReqFields)
                          .addLimit(1).build();
        List<NSP_ReportRequest__c> repReqRecord = Database.query(query);
        Test.startTest();
        repReqRecord[0].NSP_IsDraft__c=true;
        update repReqRecord;
        delete repReqRecord;
        Test.stopTest();
        String repquery = new NSP_QueryBuilder(REPORT_REQUEST, repReqFields)
                          .addLimit(1).build();
        List<NSP_ReportRequest__c> repReqList = Database.query(repquery);
        Assert.areEqual(repReqList.size(),1);
    }

    @isTest
    private static void beforeUpdateTestClientPrepared() {
        List<String> repReqFields = new List<String>{'Id','NSP_IsDraft__c','Name','NSP_Case__c','NSP_AgreementType__c','NSP_ReviewType__c','NSP_WSEE__c','NSP_DOB__c'};
        String repReqQuery = new NSP_QueryBuilder('NSP_ReportRequest__c',repReqFields)
            .addFilter('NSP_AgreementType__c',CLIENT_PREPARED)
            .addLimit(1).build();
        NSP_ReportRequest__c repReq = Database.query(repReqQuery);
        List<String> contFields = new List<String>{'Id','NSP_Work_email__c','Name','NSP_Date_of_Birth__c'};
        String contQuery = new NSP_QueryBuilder('Contact',contFields)
            .addFilter('NSP_Work_email__c','test12345@gmail.com').build();
        List<Contact> contList = Database.query(contQuery);
        Test.startTest();
        repReq.NSP_AgreementType__c = INSPERITY_PREPARED;
        repReq.NSP_ReviewType__c = '';
        repReq.NSP_RequestingMultipleEmployees__c = NSP_ServiceConstants.NO;
        repReq.NSP_WSEE_SubClient_Parent_Client_if_None__c = '24334';
        repReq.NSP_WSEE__c = contList[0].Id;
        Update repReq;
        Test.stopTest();
        Assert.areEqual(contList[0].Id, repReq.NSP_WSEE__c);
    }

    @isTest
    private static void beforeUpdateTestInsperityPrepared() {
        List<String> repReqFields = new List<String>{'Id','NSP_IsDraft__c','Name','NSP_Case__c','NSP_AgreementType__c','NSP_ReviewType__c','NSP_WSEE__c','NSP_DOB__c'};
        String repReqQuery = new NSP_QueryBuilder('NSP_ReportRequest__c',repReqFields)
            .addFilter('NSP_AgreementType__c',INSPERITY_PREPARED)
            .addLimit(1).build();
        NSP_ReportRequest__c repReq = Database.query(repReqQuery);
        List<String> contFields = new List<String>{'Id','NSP_Work_email__c','Name','NSP_Date_of_Birth__c'};
        String contQuery = new NSP_QueryBuilder('Contact',contFields)
            .addFilter('NSP_Work_email__c','test12345@gmail.com').build();
        List<Contact> contList = Database.query(contQuery);
        Test.startTest();
        try{
            repReq.NSP_WSEE__c = contList[0].Id;
            Update repReq;
        }catch (DmlException ex) {
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION' , ex.getDmlStatusCode(0),'Error Exception');
        }
        Test.stopTest();
    }

    @isTest
    private static void afterInsert() {
        new NSP_ReportRequestTriggerHandler().afterInsert(null, null);
        System.assert(new NSP_ReportRequestTriggerHandler().afterInsert(null, null) == null);
    }

    @isTest
    private static void afterDelete() {
        new NSP_ReportRequestTriggerHandler().afterDelete(null, null);
         System.assert(new NSP_ReportRequestTriggerHandler().afterDelete(null, null) == null);
    }

}
//