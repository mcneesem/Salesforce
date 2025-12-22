@isTest
private with sharing class NSP_NotificatonIESAlertsBatch_Test {

    @testSetup
    private static void createTestData() {

        Account accIns = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        accIns.Name = 'Test';
        accIns.Phone = '11223344';
        insert accIns;

        Contact conIns = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        conIns.AccountId = accIns.Id;
        conIns.pse__Salesforce_User__c = UserInfo.getUserId();
        conIns.NSP_Work_email__c = 'abctestexamplyxyz@test.com.abc';
        insert conIns;

        Test.startTest();
        Id recordTypeWOId = SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();
        Asset assetIns = (Asset) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetIns.Name = 'Test';
        assetIns.NSP_Company_Name__c = 'Test1';
        assetIns.Status = 'Active';
        assetIns.NSP_Service_Package__c = 'WO - Full BUndle';
        assetIns.ContactId = conIns.Id;
        assetIns.AccountId = accIns.Id;
        assetIns.RecordTypeId = recordTypeWOId;
        insert assetIns;

        NSP_Sub_Client__c subClientIns = (NSP_Sub_Client__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', false);
        subClientIns.Name = 'Test1';
        subClientIns.NSP_Asset__c = assetIns.Id ;
        subClientIns.NSP_Account__c = accIns.Id ;
        insert subClientIns ;
        Test.stopTest();

    }

    @isTest
    private static void testNotificatonIESAlertsBatchScheduler() {
        DateTime runtime = System.now().addDays( 1 );
        String cronExp = '0 0 0 ' + runtime.day() + ' ' + runtime.month() + ' ? ' + runtime.year();
        Test.startTest();
        String jobId = System.schedule('NSP_NotificatonIESAlertsBatchSchedule',
                                       cronExp,
                                       new NSP_NotificatonIESAlertsBatch ()
                                      );

        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,
                          NextFireTime
                          FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same
        System.assertEquals(cronExp,  ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
    }

    @isTest
    private static void terminatedEmailTemplateA() {
        //GIVEN
        Asset asset = Database.Query(new NSP_QueryBuilder( 'Asset', new List<String>{'Id', 'NSP_Account_Status__c'}).addLimit(1).build());

        asset.NSP_Account_Status__c = 'Active';
        update asset;

        NSP_Sub_Client__c subClientIns = Database.Query(new NSP_QueryBuilder( 'NSP_Sub_Client__c', new List<String>{'Id'}).addLimit(1).build());

        List<NSP_Sub_Client_Contact__c> lstSubClientContact = new List<NSP_Sub_Client_Contact__c>();
        NSP_Sub_Client_Contact__c subClientContact = (NSP_Sub_Client_Contact__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContact.NSP_Sub_Client__c= subClientIns.Id;
        subClientContact.NSP_Employee_Status__c= 'FMLA';
        subClientContact.NSP_Background_Contact__c= True;
        lstSubClientContact.add(subClientContact);
        NSP_Sub_Client_Contact__c subClientContact1 = (NSP_Sub_Client_Contact__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContact1.NSP_Sub_Client__c= subClientIns.Id;
        subClientContact1.NSP_Employee_Status__c = 'FMLA';
        subClientContact1.NSP_Background_Contact__c= True;
        lstSubClientContact.add(subClientContact1);
        insert lstSubClientContact;

        try {
            //WHEN
            for(NSP_Sub_Client_Contact__c scc : lstSubClientContact){
                scc.NSP_Employee_Status__c = 'TERMINATED';
            }

            Test.startTest();
            Database.update(lstSubClientContact);
            Database.executeBatch(new NSP_NotificatonIESAlertsBatch(), 100);
            //THEN
            Test.stopTest();
            //System.assertEquals(1, NSP_NotificatonIESAlertsBatch.emailLimits, 'An email should be sent');

        } catch(Exception ex){
            System.assert(false, 'Should not throw error.');
        }
    }

    @isTest
    private static void terminatedEmailTemplateB()v{
        //GIVEN
        Asset asset = Database.Query(new NSP_QueryBuilder( 'Asset', new List<String>{'Id', 'NSP_Account_Status__c'}).addLimit(1).build());

        asset.NSP_Account_Status__c = 'TERMINATED';
        update asset;

        Contact contact = Database.Query(new NSP_QueryBuilder( 'Contact', new List<String>{'Id'}).addLimit(1).build());


        NSP_Sub_Client__c subClientIns = Database.Query(new NSP_QueryBuilder( 'NSP_Sub_Client__c', new List<String>{'Id'}).addLimit(1).build());

        List<NSP_Sub_Client_Contact__c> lstSubClientContact = new List<NSP_Sub_Client_Contact__c>();
        NSP_Sub_Client_Contact__c subClientContact = (NSP_Sub_Client_Contact__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContact.NSP_Sub_Client__c= subClientIns.Id;
        subClientContact.NSP_Employee_Status__c= 'FMLA';
        subClientContact.NSP_Contact__c = contact.Id;
        subClientContact.NSP_Background_Contact__c= True;
        lstSubClientContact.add(subClientContact);
        NSP_Sub_Client_Contact__c subClientContact1 = (NSP_Sub_Client_Contact__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContact1.NSP_Sub_Client__c= subClientIns.Id;
        subClientContact1.NSP_Employee_Status__c= 'FMLA';
        subClientContact1.NSP_Contact__c = contact.Id;
        subClientContact1.NSP_Background_Contact__c= True;
        lstSubClientContact.add(subClientContact1);

        insert lstSubClientContact;
        try {
            //WHEN
            for(NSP_Sub_Client_Contact__c scc : lstSubClientContact){
                scc.NSP_Employee_Status__c = 'TERMINATED';
            }

            Test.startTest();
            Database.update(lstSubClientContact);
            Database.executeBatch(new NSP_NotificatonIESAlertsBatch(), 100);
            //THEN
            Test.stopTest();
            //System.assertEquals(1, NSP_NotificatonIESAlertsBatch.emailLimits, 'An email should be sent');

        } catch(Exception ex){
            System.assert(false, 'Should not throw error.');
        }
    }

    @isTest
    private static void terminatedEmailTemplateC() {
        //GIVEN
        Asset asset = Database.Query(new NSP_QueryBuilder( 'Asset', new List<String>{'Id', 'NSP_Account_Status__c'}).addLimit(1).build());

        asset.NSP_Account_Status__c = 'Active';
        update asset;

        NSP_Sub_Client__c subClientIns = Database.Query(new NSP_QueryBuilder( 'NSP_Sub_Client__c', new List<String>{'Id'}).addLimit(1).build());

        List<NSP_Sub_Client_Contact__c> lstSubClientContact = new List<NSP_Sub_Client_Contact__c>();
        NSP_Sub_Client_Contact__c subClientContact = (NSP_Sub_Client_Contact__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContact.NSP_Sub_Client__c= subClientIns.Id;
        subClientContact.NSP_Employee_Status__c= 'PRIMED';
        subClientContact.NSP_Background_Contact__c= True;
        lstSubClientContact.add(subClientContact);
        NSP_Sub_Client_Contact__c subClientContact1 = (NSP_Sub_Client_Contact__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContact1.NSP_Sub_Client__c= subClientIns.Id;
        subClientContact1.NSP_Employee_Status__c= 'PRIMED';
        subClientContact1.NSP_Background_Contact__c= True;
        lstSubClientContact.add(subClientContact1);

        insert lstSubClientContact;

        try {
            //WHEN

            Test.startTest();
            for(NSP_Sub_Client_Contact__c scc : lstSubClientContact){
                scc.NSP_Employee_Status__c = 'L.O.A.';
            }
            Database.update(lstSubClientContact);
            Database.executeBatch(new NSP_NotificatonIESAlertsBatch(), 100);
            //THEN

            Test.stopTest();
            //System.assertEquals(1, NSP_NotificatonIESAlertsBatch.emailLimits, 'An email should be sent');

        } catch(Exception ex){
            System.assert(false, 'Should not throw error.');
        }
    }

    @isTest
    private static void terminatedEmailTemplateD() {
        //GIVEN
        Asset asset = Database.Query(new NSP_QueryBuilder( 'Asset', new List<String>{'Id', 'NSP_Account_Status__c'}).addLimit(1).build());

        asset.NSP_Account_Status__c = 'Active';
        update asset;

        NSP_Sub_Client__c subClientIns = Database.Query(new NSP_QueryBuilder( 'NSP_Sub_Client__c', new List<String>{'Id'}).addLimit(1).build());

        List<NSP_Sub_Client_Contact__c> lstSubClientContact = new List<NSP_Sub_Client_Contact__c>();
        NSP_Sub_Client_Contact__c subClientContact = (NSP_Sub_Client_Contact__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContact.NSP_Sub_Client__c= subClientIns.Id;
        subClientContact.NSP_Employee_Status__c= 'L.O.A.';
        subClientContact.NSP_Background_Contact__c= True;
        lstSubClientContact.add(subClientContact);

        NSP_Sub_Client_Contact__c subClientContact1 = (NSP_Sub_Client_Contact__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContact1.NSP_Sub_Client__c= subClientIns.Id;
        subClientContact1.NSP_Employee_Status__c= 'L.O.A.';
        subClientContact1.NSP_Background_Contact__c= True;
        lstSubClientContact.add(subClientContact1);

        insert lstSubClientContact;
        try {
            //WHEN
            Test.startTest();
            for(NSP_Sub_Client_Contact__c scc : lstSubClientContact){
                scc.NSP_Employee_Status__c = 'PRIMED';
            }
            Database.update(lstSubClientContact);
            Database.executeBatch(new NSP_NotificatonIESAlertsBatch(), 100);
            //THEN
            Test.stopTest();
            //System.assertEquals(1, NSP_NotificatonIESAlertsBatch.emailLimits, 'An email should be sent');

        } catch(Exception ex){
            System.assert(false, 'Should not throw error.');
        }
    }

    @isTest
    private static void terminatedEmailTemplateE() {
        //GIVEN
        Asset asset = Database.Query(new NSP_QueryBuilder( 'Asset', new List<String>{'Id', 'NSP_Account_Status__c'}).addLimit(1).build());

        asset.NSP_Account_Status__c = 'Active';
        update asset;

        NSP_Sub_Client__c subClientIns = Database.Query(new NSP_QueryBuilder( 'NSP_Sub_Client__c', new List<String>{'Id'}).addLimit(1).build());

        List<NSP_Sub_Client_Contact__c> lstSubClientContact = new List<NSP_Sub_Client_Contact__c>();
        NSP_Sub_Client_Contact__c subClientContact = (NSP_Sub_Client_Contact__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContact.NSP_Sub_Client__c= subClientIns.Id;
        subClientContact.NSP_Employee_Status__c= 'PRIMED';
        subClientContact.NSP_Background_Contact__c= True;
        lstSubClientContact.add(subClientContact);
        NSP_Sub_Client_Contact__c subClientContact1 = (NSP_Sub_Client_Contact__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContact1.NSP_Sub_Client__c= subClientIns.Id;
        subClientContact1.NSP_Employee_Status__c= 'PRIMED';
        subClientContact1.NSP_Background_Contact__c= True;
        lstSubClientContact.add(subClientContact1);

        insert lstSubClientContact;
        try {
            //WHEN
            for(NSP_Sub_Client_Contact__c scc : lstSubClientContact){
                scc.NSP_Employee_Status__c = 'FMLA';
            }
            Database.update(lstSubClientContact);
            Test.startTest();
            NSP_NotificatonIESAlertsBatch batchJob = new NSP_NotificatonIESAlertsBatch();
            Database.executeBatch(batchJob);
            //THEN
            Test.stopTest();
            //System.assertEquals(1, NSP_NotificatonIESAlertsBatch.emailLimits, 'An email should be sent');

        } catch(Exception excep){
            System.assert(false, 'Should not throw error.');
        }
    }

    @isTest
    private static void terminatedEmailTemplateF() {
        //GIVEN
        Asset asset = Database.Query(new NSP_QueryBuilder( 'Asset', new List<String>{'Id', 'NSP_Account_Status__c'}).addLimit(1).build());

        asset.NSP_Account_Status__c = 'Active';
        update asset;

        NSP_Sub_Client__c subClientIns = Database.Query(new NSP_QueryBuilder( 'NSP_Sub_Client__c', new List<String>{'Id'}).addLimit(1).build());

        List<NSP_Sub_Client_Contact__c> lstSubClientContact = new List<NSP_Sub_Client_Contact__c>();
        NSP_Sub_Client_Contact__c subClientContact = (NSP_Sub_Client_Contact__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContact.NSP_Sub_Client__c= subClientIns.Id;
        subClientContact.NSP_Employee_Status__c= 'FMLA';
        subClientContact.NSP_Background_Contact__c= True;
        lstSubClientContact.add(subClientContact);
        NSP_Sub_Client_Contact__c subClientContact1 = (NSP_Sub_Client_Contact__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContact1.NSP_Sub_Client__c= subClientIns.Id;
        subClientContact1.NSP_Employee_Status__c= 'FMLA';
        subClientContact1.NSP_Background_Contact__c= True;
        lstSubClientContact.add(subClientContact1);

        insert lstSubClientContact;
        //WHEN

        for(NSP_Sub_Client_Contact__c scc : lstSubClientContact){
            scc.NSP_Employee_Status__c = 'PRIMED';
        }
        Database.update(lstSubClientContact);
        Test.startTest();
        Database.executeBatch(new NSP_NotificatonIESAlertsBatch(), 100);
        //THEN
        Test.stopTest();
        //System.assertEquals(1, NSP_NotificatonIESAlertsBatch.emailLimits, 'An email should be sent');
    }

    @isTest
    private static void terminatedEmailTemplateG() {
        //GIVEN
        Asset asset = Database.Query(new NSP_QueryBuilder( 'Asset', new List<String>{'Id', 'NSP_Account_Status__c'}).addLimit(1).build());

        asset.NSP_Account_Status__c = 'TERMINATED';
        update asset;

        NSP_Sub_Client__c subClientIns = Database.Query(new NSP_QueryBuilder( 'NSP_Sub_Client__c', new List<String>{'Id'}).addLimit(1).build());

        List<NSP_Sub_Client_Contact__c> lstSubClientContact = new List<NSP_Sub_Client_Contact__c>();
        NSP_Sub_Client_Contact__c subClientContact = (NSP_Sub_Client_Contact__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContact.NSP_Sub_Client__c= subClientIns.Id;
        subClientContact.NSP_Employee_Status__c= 'TERMINATED';
        subClientContact.NSP_Background_Contact__c= True;
        lstSubClientContact.add(subClientContact);

        NSP_Sub_Client_Contact__c subClientContact1 = (NSP_Sub_Client_Contact__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContact1.NSP_Sub_Client__c= subClientIns.Id;
        subClientContact1.NSP_Employee_Status__c= 'TERMINATED';
        subClientContact1.NSP_Background_Contact__c= True;
        lstSubClientContact.add(subClientContact1);

        insert lstSubClientContact;
        try {
            //WHEN
            Test.startTest();
            for(NSP_Sub_Client_Contact__c scc : lstSubClientContact){
                scc.NSP_Employee_Status__c = 'PRIMED';
            }
            Database.update(lstSubClientContact);
            Database.executeBatch(new NSP_NotificatonIESAlertsBatch(), 100);
            //THEN
            Test.stopTest();
            //System.assertEquals(1, NSP_NotificatonIESAlertsBatch.emailLimits, 'An email should be sent');

        } catch(Exception ex){
            System.assert(false, 'Should not throw error.');
        }
    }

    @isTest
    private static void terminatedEmailTemplateNegativeCase() {
        //WHEN
        Test.startTest();
        Database.executeBatch(new NSP_NotificatonIESAlertsBatch(), 100);
        //THEN
        System.assertEquals(0, NSP_NotificatonIESAlertsBatch.emailLimits, 'An email should not be sent');
        Test.stopTest();
    }

}
//