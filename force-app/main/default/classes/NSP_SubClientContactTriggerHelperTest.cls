@isTest
private class NSP_SubClientContactTriggerHelperTest {

    private static final List<String> CONTACT_FIELDS = new List<String>{'Id','LastName'};

    @testSetup
    private Static Void TestData() {
        Account accoutObject = new Account();
        accoutObject.Name = 'Test Account';
        insert accoutObject;

        Contact con = new Contact();
        con.AccountId = accoutObject.Id ;
        con.LastName = 'Test con';
        insert con;

        Asset ass = new Asset();
        ass.Name='Test ';
        ass.AccountId = accoutObject.Id ;
        insert ass ;

        NSP_Sub_Client__c scIns = new NSP_Sub_Client__c ();
        scIns.Name = 'Test';
        scIns.NSP_Account__c = accoutObject.Id ;
        scIns.NSP_Asset__c = ass.Id ;
        insert scIns ;

        NSP_Sub_Client_Contact__c subClientContact = new NSP_Sub_Client_Contact__c();
        subClientContact.NSP_Employee_Status__c = 'TERMINATED';
        subClientContact.NSP_Sub_Client__c = scIns.Id;
        subClientContact.NSP_Contact__c = con.Id;
        subClientContact.NSP_On_Site_Supervisor__c = false;
        subClientContact.NSP_Payroll_Contact__c = false;
        subClientContact.NSP_HR_Contact__c = false;
        subClientContact.NSP_Background_Contact__c = false;
        subClientContact.NSP_Is_Primary__c = true;
        insert subClientContact ;

        NSP_Sub_Client_Contact__c subClientContact1 = new NSP_Sub_Client_Contact__c();
        subClientContact1.NSP_Employee_Status__c = 'PRIMED';
        subClientContact1.NSP_Sub_Client__c = scIns.Id;
        subClientContact1.NSP_Contact__c = con.Id;
        subClientContact1.NSP_On_Site_Supervisor__c = false;
        subClientContact1.NSP_Payroll_Contact__c = false;
        subClientContact1.NSP_HR_Contact__c = false;
        subClientContact1.NSP_Background_Contact__c = false;
        subClientContact1.NSP_Is_Primary__c = true;
        insert subClientContact1 ;

        NSP_Payroll__c pdsIns = new NSP_Payroll__c ();
        pdsIns.NSP_Sub_Client_Name__c = scIns.Id ;
        insert pdsIns;

        Id recordTypeID = NSP_GenericRecordType.getRecordTypeId('NSP_ReportRequest__c','NSP_DevelopmentReport');
        NSP_ReportRequest__c reportrequest = (NSP_ReportRequest__c)NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), 'NSP_TestDataFactory.ReportRequestDefaults', false);
        reportrequest.RecordTypeId = recordTypeID;
        reportrequest.NSP_IsDraft__c=false;
        reportrequest.name='test';
        reportrequest.NSP_WSEE__c = con.Id;
        insert reportrequest;

    }

    @isTest
    private static void shouldUpdatePaperLessBatchDate() {
        SubClientContactTriggerSettings__c settings = SubClientContactTriggerSettings__c.getOrgDefaults();
        settings.IsEnabledDeleteAddresses__c = True;
        upsert settings;

        Test.StartTest();
        List<NSP_Sub_Client_Contact__c> subClientContacts = [SELECT Id, NSP_Employee_Status__c , NSP_Paperless_Batch_Date__c FROM NSP_Sub_Client_Contact__c WHERE NSP_Employee_Status__c = 'TERMINATED'  LIMIT 1];
        subClientContacts[0].NSP_Employee_Status__c = 'HIRED';
        Update subClientContacts;

        List<NSP_Sub_Client_Contact__c> subClientContactPrimeds = [SELECT Id, NSP_Employee_Status__c , NSP_Paperless_Batch_Date__c FROM NSP_Sub_Client_Contact__c WHERE NSP_Employee_Status__c = 'PRIMED'  LIMIT 1];
        subClientContactPrimeds[0].NSP_Employee_Status__c = 'HIRED';
        Update subClientContactPrimeds;
        Test.stopTest();
        System.assert(subClientContacts[0].NSP_Paperless_Batch_Date__c == System.today());
    }

    @isTest
    private static Void updatePDSContactRelatedFieldsBasedOnSCCTest() {
        Test.StartTest();
        // get Existing Sub Client Contact For Update
        NSP_Sub_Client_Contact__c subClientContact = [SELECT Id, NSP_On_Site_Supervisor__c, NSP_Payroll_Contact__c, NSP_HR_Contact__c, NSP_Background_Contact__c, NSP_Employee_Status__c FROM NSP_Sub_Client_Contact__c WHERE NSP_Employee_Status__c = 'TERMINATED'  LIMIT 1];
        subClientContact.NSP_On_Site_Supervisor__c = true;
        subClientContact.NSP_Payroll_Contact__c = true;
        subClientContact.NSP_HR_Contact__c = true;
        subClientContact.NSP_Background_Contact__c = true;
        update subClientContact;

        Test.stopTest();
        NSP_Sub_Client_Contact__c subClientCon = [SELECT Id, NSP_Contact__c, NSP_On_Site_Supervisor__c FROM NSP_Sub_Client_Contact__c WHERE NSP_On_Site_Supervisor__c = true LIMIT 1];
        NSP_Payroll__c pds = [SELECT Id ,NSP_HR_Contact__c FROM NSP_Payroll__c WHERE NSP_HR_Contact__c != null];
        System.assert(subClientCon.NSP_Contact__c == pds.NSP_HR_Contact__c);
    }

    @isTest
    private static void updateRelatedWizardEmployeeStatusTest() {
     List<String> subClientConFields = new List<String>{'Id','NSP_Employee_Status__c', 'NSP_Status_Date__c', 'NSP_Contact__c', 'NSP_Is_Primary__c'};
        String query = new NSP_QueryBuilder('NSP_Sub_Client_Contact__c', subClientConFields)
                          .addLimit(1).build();
        List<NSP_Sub_Client_Contact__c> subClientCon = Database.query(query);
        Test.startTest();
        subClientCon[0].NSP_Employee_Status__c = NSP_ServiceConstants.FUTURE_HIRED_STATUS;
        update subClientCon[0];
        Test.stopTest();
        String conQuery = new NSP_QueryBuilder('Contact', CONTACT_FIELDS).addFilter('LastName', 'Test con').addLimit(1).build();
        Contact getContact =  Database.query(conQuery);
        List<String> repReqFields = new List<String>{'Id', 'NSP_WSEE__c'};
        String repreqQuery = new NSP_QueryBuilder('NSP_ReportRequest__c', repReqFields).addFilter('NSP_WSEE__c', getContact.Id)
                          .addLimit(1).build();
        List<NSP_ReportRequest__c> repReqRecord = Database.query(repreqQuery);
        System.assertEquals(getContact.Id, repReqRecord[0].NSP_WSEE__c);
    }

}
//