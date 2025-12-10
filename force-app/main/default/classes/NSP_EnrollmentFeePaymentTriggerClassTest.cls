@isTest
private class NSP_EnrollmentFeePaymentTriggerClassTest {

    @testSetup
    private static void setupTestData() {
        EnrollmentFeePaymentSharingSettings__c settings = EnrollmentFeePaymentSharingSettings__c.getOrgDefaults();
        settings.IsEnabled__c = true;
        settings.IsEnabledLogResults__c = true;
        upsert settings;

        //insert account record
        Account account_Obj = new Account(Name = 'Test Account');
        Insert account_Obj;
        //insert opportunity record
        List<Opportunity> optys = new List<Opportunity>();
        Opportunity opportunity_Obj = new Opportunity(Name = 'Test Oppty',AccountId = account_Obj.id,stagename = NSP_SalesConstants.ANALYSIS_STAGE,CloseDate = date.today(),CurrencyIsoCode = 'USD',NSP_PrimaryProduct__c = 'WX',NSP_Number_of_Employees__c = 100,NSP_WS_Number_Of_Employees__c = 123,NSP_WO_Number_Of_Employees__c = 123,NSP_TransactionType__c = NSP_SalesConstants.TRANSACTION_TYPE_TERMINATION,Type ='CAMS');
        optys.add(opportunity_Obj);
        Opportunity opportunity_Obj1 = new Opportunity(Name = 'Test Oppty Midmarket',AccountId = account_Obj.id,stagename = NSP_SalesConstants.ANALYSIS_STAGE,CloseDate = date.today(),CurrencyIsoCode = 'USD',NSP_PrimaryProduct__c = 'WX',NSP_Number_of_Employees__c = 170,NSP_WS_Number_Of_Employees__c = 123,NSP_WO_Number_Of_Employees__c = 123,NSP_TransactionType__c = NSP_SalesConstants.TRANSACTION_TYPE_TERMINATION,Type ='CAMS', NSP_Mid_Market_Sales_Email__c='testmidm@insperity.com',NSP_MidMarketNationalAccount__c='MidMarket');
        optys.add(opportunity_Obj1);
        Insert optys;
        //insert enrollment fee payment
        NSP_Enrollment_Fee_Payment__c nsp_enrollment_fee_payment_Obj = new NSP_Enrollment_Fee_Payment__c(NSP_Opportunity__c = opportunity_Obj.id, NSP_Payment_Amount__c = 100.00, NSP_Payment_Number__c = '1', NSP_Payment_Status__c = 'Paid');
        //NSP_Enrollment_Fee_Payment__c nsp_enrollment_fee_payment_Obj1 = new NSP_Enrollment_Fee_Payment__c(NSP_Opportunity__c = opportunity_Obj.id, NSP_Payment_Amount__c = 100.00, NSP_Payment_Number__c = '3', NSP_Payment_Status__c = 'Paid');
        Insert nsp_enrollment_fee_payment_Obj;

        //Insert User
        User userRecord = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id,
            LastName = 'TestClassUser',
            Phone = '1231231231',
            Email = 'testuser@insperity.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            NSP_Sales_Office_Membership__c = '301'
        );
        insert userRecord;
    }

    @isTest
    private static void test_sumofEnrollmentFee_UseCase1() {
        Test.startTest();

        List<Opportunity> opportunity_Obj  =  [SELECT Id,NSP_Enrollment_Fee_Payment_1__c,NSP_Enrollment_Fee_Payment_2__c,NSP_Enrollment_Fee_Payment_3__c,NSP_Enrollment_Fee_Payment_4__c,NSP_Enrollment_Fee_Payment_5__c,NSP_Enrollment_Fee_Payment_6__c from Opportunity WHERE NSP_Number_of_Employees__c < 150 Limit 1];
        System.assertEquals(true,opportunity_Obj.size()>0);
        List<NSP_Enrollment_Fee_Payment__c> nsp_enrollment_fee_payment_Obj  =  [SELECT NSP_Opportunity__c,NSP_Payment_Amount__c,NSP_Payment_Method__c,NSP_Payment_Number__c,NSP_Payment_Status__c from NSP_Enrollment_Fee_Payment__c Limit 1];
        System.assertEquals(true,nsp_enrollment_fee_payment_Obj.size()>0);
        Delete nsp_enrollment_fee_payment_Obj;
        NSP_EnrollmentFeePaymentTriggerClass.sumofEnrollmentFee(nsp_enrollment_fee_payment_Obj);

        Test.stopTest();
    }

    @isTest
    private static void test_sumofEnrollmentFee_UseCase2() {
        Test.startTest();

        List<Opportunity> opportunity_Obj  =  [SELECT Id,NSP_Enrollment_Fee_Payment_1__c,NSP_Enrollment_Fee_Payment_2__c,NSP_Enrollment_Fee_Payment_3__c,NSP_Enrollment_Fee_Payment_4__c,NSP_Enrollment_Fee_Payment_5__c,NSP_Enrollment_Fee_Payment_6__c from Opportunity WHERE NSP_Number_of_Employees__c < 150 Limit 1];
        System.assertEquals(true,opportunity_Obj.size()>0);
        List<NSP_Enrollment_Fee_Payment__c> nsp_enrollment_fee_payment_Obj  =  [SELECT NSP_Opportunity__c,NSP_Payment_Amount__c,NSP_Payment_Method__c,NSP_Payment_Number__c,NSP_Payment_Status__c from NSP_Enrollment_Fee_Payment__c Limit 1];
        System.assertEquals(true,nsp_enrollment_fee_payment_Obj.size()>0);

        nsp_enrollment_fee_payment_Obj[0].NSP_Payment_Number__c='2';
        nsp_enrollment_fee_payment_Obj[0].NSP_Payment_Amount__c = 100.00;
        Update nsp_enrollment_fee_payment_Obj[0];
        nsp_enrollment_fee_payment_Obj[0].NSP_Payment_Number__c='3';
        nsp_enrollment_fee_payment_Obj[0].NSP_Payment_Amount__c = 100.00;
        Update nsp_enrollment_fee_payment_Obj[0];
        nsp_enrollment_fee_payment_Obj[0].NSP_Payment_Number__c='4';
        nsp_enrollment_fee_payment_Obj[0].NSP_Payment_Amount__c = 100.00;
        Update nsp_enrollment_fee_payment_Obj[0];
        nsp_enrollment_fee_payment_Obj[0].NSP_Payment_Number__c='5';
        nsp_enrollment_fee_payment_Obj[0].NSP_Payment_Amount__c = 100.00;
        Update nsp_enrollment_fee_payment_Obj[0];
        nsp_enrollment_fee_payment_Obj[0].NSP_Payment_Number__c='6';
        nsp_enrollment_fee_payment_Obj[0].NSP_Payment_Amount__c = 100.00;
        Update nsp_enrollment_fee_payment_Obj[0];
        NSP_EnrollmentFeePaymentTriggerClass.sumofEnrollmentFee(nsp_enrollment_fee_payment_Obj);

        Test.stopTest();
    }

    @isTest
    private static void testEnrollmentFee() {
        Test.startTest();

        Opportunity oppObj = [Select Id,Name,NSP_Number_of_Employees__c from Opportunity WHERE NSP_Number_of_Employees__c > 150 Limit 1];
        Id oppId = oppObj.Id;
        NSP_Enrollment_Fee_Payment__c enrollmentfee = new NSP_Enrollment_Fee_Payment__c();
        enrollmentfee.NSP_Opportunity__c = oppId;
        enrollmentfee.CurrencyIsoCode = 'USD';
        insert enrollmentfee;

        Test.stopTest();
    }

    @isTest
    private static void testEnrollmentFeeMidMarket() {
        Test.startTest();

        Opportunity oppObj = [
            SELECT Id , Name , NSP_Number_of_Employees__c
            FROM Opportunity
            LIMIT 1
        ];
        Id oppId = oppObj.Id;
        NSP_Enrollment_Fee_Payment__c enrollmentfee = new NSP_Enrollment_Fee_Payment__c();
        enrollmentfee.NSP_Opportunity__c = oppId;
        enrollmentfee.CurrencyIsoCode = 'USD';
        insert enrollmentfee;

        Test.stopTest();
    }

    @isTest
    private static void testEnrollmentFeeShare() {
        Test.startTest();

        Opportunity oppObj = [Select Id,Name,NSP_Number_of_Employees__c from Opportunity WHERE NSP_Number_of_Employees__c > 150 Limit 1];
        Id oppId = oppObj.Id;

        user getUser = [SELECT Id FROM User WHERE LastName = 'TestClassUser'];

        NSP_Enrollment_Fee_Payment__c enrollmentfee = new NSP_Enrollment_Fee_Payment__c();
        enrollmentfee.NSP_Opportunity__c = oppId;
        enrollmentfee.CurrencyIsoCode = 'USD';
        insert enrollmentfee;

        NSP_Enrollment_Fee_Payment__Share efpShare = new NSP_Enrollment_Fee_Payment__Share();
        efpShare.ParentId = enrollmentfee.Id;
        efpShare.RowCause = NSP_SalesConstants.manualRowCause;
        efpShare.UserOrGroupId = getUser.Id;
        efpShare.AccessLevel = NSP_SalesConstants.readSharingAccess;
        insert efpShare;

        oppObj.StageName = 'Closed Lost';
        oppObj.Closed_Lost_Group__c = 'Service';
        oppObj.NSP_Lost_Reason__c = 'Other';
        update oppObj;

        Test.stopTest();
    }

}
//