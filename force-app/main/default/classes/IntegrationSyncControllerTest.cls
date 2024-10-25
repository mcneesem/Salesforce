@isTest private class IntegrationSyncControllerTest {
    
    @testSetup private static void prepare() {
        //
        PlatformEventSettings__c settings = PlatformEventSettings__c.getOrgDefaults();
        settings.IsEnabled_IntegrationAccountEvent__c = true;
        upsert settings;
        //
        Account sharedAccount = new Account(
            Name='sharedAccount'
        );
        insert sharedAccount;
        //
    }

    @isTest private static void testIntegrationSync() {
        Test.startTest();
        List<Account> records = [ SELECT Id , MasterRecordId FROM Account ];
        Map<Id,Account> recordsMap = new Map<Id,Account>( records );
        IntegrationSyncController.assignReadyForIntegrationSync( records );
        IntegrationSyncController.setReadyForIntegrationSync( recordsMap.keySet() );
        IntegrationSyncController.publishIntegrationAccountEvents( recordsMap.keySet() );
        IntegrationSyncController.publishIntegrationAccountEvents( records );
        Test.stopTest();
    }

}
//