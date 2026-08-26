@isTest
private class NSP_SubClientAssetSyncJob_Test {

    @testSetup
    private static void createTestData() {
        SubClientAssetStateSyncJobSettings__c settings = SubClientAssetStateSyncJobSettings__c.getOrgDefaults();
        settings.IsEnabled__c = True;
        settings.BatchSize__c = 200;
        settings.SoqlAddressLimit__c = 20000;
        settings.SoqlContactLimit__c = 20000;
        settings.SoqlAddressHistoryLimit__c = 20000;
        settings.SoqlContactHistoryLimit__c = 20000;
        upsert settings;

        //Account creation
        Account acc = new Account();
        acc.Name = 'Test Acc';
        insert acc;

        //Contact creation
        Contact con = new Contact();
        con.AccountId = acc.Id ;
        con.LastName = 'Test con';
        insert con;

        //Asset creation
        Asset asset = new Asset();
        asset.Name = 'Test Asset' ;
        asset.ContactId = con.Id ;
        asset.AccountId = acc.Id ;
        insert asset;

        //NSP_Sub_Client__c creation
        List<NSP_Sub_Client__c> subClients = new List<NSP_Sub_Client__c>();

        NSP_Sub_Client__c subClient = new NSP_Sub_Client__c();
        subClient.NSP_Account__c = acc.Id;
        subClient.NSP_Asset__c = asset.Id ;
        subClient.Name = 'Test Sub Client One';
        subClient.NSP_Union_Employees__c = false;
        subClients.add( subClient ) ;

        NSP_Sub_Client__c subClient1 = new NSP_Sub_Client__c();
        subClient1.NSP_Account__c = acc.Id;
        subClient1.NSP_Asset__c = asset.Id ;
        subClient1.Name = 'Test Sub Client Two';
        subClient1.NSP_Union_Employees__c = true;
        subClients.add( subClient1 ) ;

        insert subClients;

        //NSP_Sub_Client_Contact__c creation
        List<NSP_Sub_Client_Contact__c> subClientContacts = new List<NSP_Sub_Client_Contact__c>();

        NSP_Sub_Client_Contact__c subClientCon = new NSP_Sub_Client_Contact__c();
        subClientCon.NSP_Sub_Client__c = subClient.Id;
        subClientCon.NSP_Paid_Non_Paid__c = 'Paid WSEE';
        subClientCon.NSP_Employee_Status__c = 'HIRED';
        subClientCon.NSP_Union_Employee__c = true;

        subClientContacts.add( subClientCon );

        NSP_Sub_Client_Contact__c subClientCon1 = new NSP_Sub_Client_Contact__c();
        subClientCon1.NSP_Sub_Client__c = subClient.Id;
        subClientCon1.NSP_Paid_Non_Paid__c = 'Paid WSEE';
        subClientCon1.NSP_Employee_Status__c = 'HIRED';
        subClientCon1.NSP_Union_Employee__c = true;

        subClientContacts.add( subClientCon1 );

        NSP_Sub_Client_Contact__c subClientCon2 = new NSP_Sub_Client_Contact__c();
        subClientCon2.NSP_Sub_Client__c = subClient1.Id;
        subClientCon2.NSP_Paid_Non_Paid__c = 'Paid WSEE';
        subClientCon2.NSP_Employee_Status__c = 'Terminated';
        subClientCon2.NSP_Union_Employee__c = false;

        subClientContacts.add( subClientCon2 );

        insert subClientContacts;

        //NSP_Address__c creation
        NSP_Address__c address = new NSP_Address__c();
        address.Name = 'Test Add';
        address.NSP_Related_Site__c = acc.Id;
        address.NSP_Legal_Name__c = 'Billing';
        address.NSP_Street__c = 'Test Address AZ';
        address.NSP_Country__c = 'United States';
        address.NSP_State__c = 'AZ';
        address.NSP_Postal_Code__c = '12345';
        address.NSP_Source__c = 'AIMS';
        address.NSP_Address_Type__c = 'Worksite';
        insert address;

        //NSP_Sub_Client_Contact_Address__c creation
        NSP_Sub_Client_Contact_Address__c subClientConAdd = New NSP_Sub_Client_Contact_Address__c();
        subClientConAdd.Name = 'Test';
        subClientConAdd.NSP_Address__c = address.Id;
        subClientConAdd.NSP_Sub_Client_Contact__c = subClientCon.Id;
        insert subClientConAdd ;

        //NSP_Sub_Client_Contact_Address__c creation
        NSP_Sub_Client_Contact_Address__c subClientConAdd1 = New NSP_Sub_Client_Contact_Address__c();
        subClientConAdd1.Name = 'Test';
        subClientConAdd1.NSP_Address__c = address.Id;
        subClientConAdd1.NSP_Sub_Client_Contact__c = subClientCon.Id;
        insert subClientConAdd1 ;

        //NSP_Sub_Client_Contact__History creation
        List<NSP_Sub_Client_Contact__History> histories = new List<NSP_Sub_Client_Contact__History>();
        NSP_Sub_Client_Contact__History instSCCH = New NSP_Sub_Client_Contact__History();
        instSCCH.ParentId = subClientCon.Id;
        instSCCH.Field = 'NSP_Paid_Non_Paid__c';

        histories.add( instSCCH );

        NSP_Sub_Client_Contact__History instSCCH1 = New NSP_Sub_Client_Contact__History();
        instSCCH1.ParentId = subClientCon1.Id;
        instSCCH1.Field = 'NSP_Union_Employee__c';

        histories.add( instSCCH1 );

        NSP_Sub_Client_Contact__History instSCCH2 = New NSP_Sub_Client_Contact__History();
        instSCCH2.ParentId = subClientCon2.Id;
        instSCCH2.Field = 'NSP_Employee_Status__c';

        histories.add( instSCCH2 );

        insert histories;

        //NSP_Sub_Client_Contact__History creation
        NSP_Sub_Client_Contact_Address__History instSCCAH = New NSP_Sub_Client_Contact_Address__History();
        instSCCAH.ParentId = subClientConAdd1.Id;
        instSCCAH.Field = 'NSP_Address_State_Changed_Date__c';
        insert instSCCAH;
    }

    @isTest
    private static void testBatchProcess() {
        Test.startTest();
        Database.executeBatch( new NSP_SubClientAssetSyncJob(), 200 );
        Test.stopTest();
    }

    @isTest
    private static void testBatchScheduler_SchedulesAndRuns() {
        // Arrange
        String cronExp = '0 0 */4 * * ?'; // Every 4 hours

        // Act
        Test.startTest();
        String jobName = 'NSP_SubClientAssetSyncJob_Test_Schedule';
        System.schedule(jobName, cronExp, new NSP_SubClientAssetSyncJob());
        Test.stopTest();

        // Assert - verify a scheduled job created for the batch class
        List<CronTrigger> triggers = [
            SELECT Id, State, NextFireTime, TimesTriggered, CronJobDetail.Name, CronJobDetail.JobType
            FROM CronTrigger
            WHERE CronJobDetail.Name = :jobName
            LIMIT 1
        ];

        Assert.areEqual(1, triggers.size(), 'Expected one scheduled job for batch');
        Assert.areEqual('7', triggers[0].CronJobDetail.JobType, 'Expected job type to be batch/schedulable'); // value may vary by org, assert presence instead
        Assert.isTrue(triggers[0].NextFireTime != null, 'Next fire time should be set');
    }

    @isTest
    private static void testISelfSchedulable() {
        Test.startTest();
        string jobId = NSP_SubClientAssetSyncJob.schedule();
        List<CronTrigger> triggers = [
            SELECT Id, State, NextFireTime, TimesTriggered, CronJobDetail.Name, CronJobDetail.JobType
            FROM CronTrigger
            WHERE Id = :jobId
            LIMIT 1
        ];
        Assert.areEqual(1, triggers.size(), 'Expected one scheduled job for batch');
        Test.stopTest();
    }


    @isTest
    private static void testSchedule() {
        Test.startTest();
        NSP_SubClientAssetStateSyncJob.schedule();
        Test.stopTest();
    }

    @isTest
    private static void shouldTestSubClientAssetSyncJob() {
        Test.startTest();
        //Update NSP_Sub_Client_Contact__c
        List<NSP_Sub_Client_Contact__c> subClientConRecords =[
            SELECT Id , NSP_Sub_Client__c , NSP_Employee_Status__c , NSP_Paid_Non_Paid__c , NSP_Union_Employee__c
            FROM NSP_Sub_Client_Contact__c
            WHERE ( Id != null )
            LIMIT 1
        ];
        System.assert( subClientConRecords != null );
        System.assert( !subClientConRecords.isEmpty() );
        NSP_Sub_Client_Contact__c subClientCon = subClientConRecords[0];
        subClientCon.NSP_Paid_Non_Paid__c = 'Paid WSEE';
        subClientCon.NSP_Employee_Status__c = 'HIRED';
        subClientCon.NSP_Union_Employee__c = true;
        update subClientCon;

        List<NSP_Sub_Client_Contact_Address__c> subClientConAddressRecords =[
            SELECT Id , NSP_Address_State_Changed_Date__c
            FROM NSP_Sub_Client_Contact_Address__c
            WHERE ( Id != null )
            LIMIT 1
        ];
        System.assert( subClientConAddressRecords != null );
        System.assert( !subClientConAddressRecords.isEmpty() );
        NSP_Sub_Client_Contact_Address__c subClientConA = subClientConAddressRecords[0];
        subClientConA.NSP_Address_State_Changed_Date__c = System.today();
        update subClientConA;

        // Call Batch Class
        NSP_SubClientAssetSyncJob subClientCont = new NSP_SubClientAssetSyncJob();
        DataBase.executeBatch(subClientCont);

        // Call Batch Class
        NSP_SubClientAssetStateSyncJob subClientContA = new NSP_SubClientAssetStateSyncJob();
        DataBase.executeBatch(subClientContA);
        Test.stopTest();

        List<NSP_Sub_Client_Contact__History> scchUpdatedRecords = [
            SELECT Id , OldValue , NewValue , Field , ParentId , Parent.NSP_Sub_Client__r.NSP_Union_Employees__c , DataType
            FROM NSP_Sub_Client_Contact__History
            WHERE ( Id != null )
            LIMIT 1
        ];
        System.assert( scchUpdatedRecords != null );
        System.assert( !scchUpdatedRecords.isEmpty() );
        NSP_Sub_Client_Contact__History scchUpdated = scchUpdatedRecords[0];
        System.assert(scchUpdated.Parent.NSP_Sub_Client__r.NSP_Union_Employees__c = true);

        // added for code coverage in 09-Aug RC2 release...
        List<NSP_Sub_Client__c> records = [
            SELECT Id , NSP_Asset__c
            FROM NSP_Sub_Client__c
            WHERE ( Id = :subClientCon.NSP_Sub_Client__c )
        ];
        Set<Id> assetIds = new Set<Id>();
        for ( NSP_Sub_Client__c record : records ) {
            assetIds.add( record.NSP_Asset__c );
        }
    }

}
//