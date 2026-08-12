@isTest
private class SubClientAssetStateSyncActionTest {

    @testSetup
    private static void createTestData() {
        // Account creation
        Account accountRecord = new Account();
        accountRecord.Name = 'Test Account';
        insert accountRecord;

        // Asset creation
        Id woRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'WO' );      
        Asset assetRecord = new Asset();
        assetRecord.Name = 'Test Asset';
        assetRecord.AccountId = accountRecord.Id;
        assetRecord.RecordTypeId = woRecordTypeId;
        insert assetRecord;

        // Sub Client creation
        NSP_Sub_Client__c subClient = new NSP_Sub_Client__c();
        subClient.Name = 'Test Sub Client';
        subClient.NSP_Account__c = accountRecord.Id;
        subClient.NSP_Asset__c = assetRecord.Id;
        insert subClient;

        // Sub Client Contact creation
        NSP_Sub_Client_Contact__c subClientContact = new NSP_Sub_Client_Contact__c();
        subClientContact.NSP_Sub_Client__c = subClient.Id;
        subClientContact.NSP_Paid_Non_Paid__c = 'Paid WSEE';
        subClientContact.NSP_Employee_Status__c = 'HIRED';
        insert subClientContact;

        // Address creation
        NSP_Address__c addressRecord = new NSP_Address__c();
        addressRecord.Name = 'Test Address';
        addressRecord.NSP_Related_Site__c = accountRecord.Id;
        addressRecord.NSP_Legal_Name__c = 'Billing';
        addressRecord.NSP_Street__c = 'Test Address AZ';
        addressRecord.NSP_Country__c = 'United States';
        addressRecord.NSP_State__c = 'AZ';
        addressRecord.NSP_Postal_Code__c = '12345';
        addressRecord.NSP_Source__c = 'AIMS';
        addressRecord.NSP_Address_Type__c = 'Worksite';
        insert addressRecord;

        // Sub Client Contact Address creation
        NSP_Sub_Client_Contact_Address__c contactAddress = new NSP_Sub_Client_Contact_Address__c();
        contactAddress.Name = 'Test Contact Address';
        contactAddress.NSP_Address__c = addressRecord.Id;
        contactAddress.NSP_Sub_Client_Contact__c = subClientContact.Id;
        insert contactAddress;
    }

    @isTest
    private static void resyncStatesOfOperationsTest() {
        List<Asset> assetRecords = new List<Asset>();
        assetRecords = [
            SELECT Id
            FROM Asset
            WHERE Name = 'Test Asset'
            LIMIT 1
        ];
        Assert.isNotNull(assetRecords, 'Asset list should not be null.');
        Assert.isFalse(assetRecords.isEmpty(), 'Test Asset should exist.');    
        List<Id> inputs = new List<Id>{ assetRecords[0].Id };
        
        Test.startTest();
        List<Boolean> results = SubClientAssetStateSyncAction.invoke(inputs);
        Test.stopTest();
        
        Assert.isNotNull( results, 'A response list should be returned.' );
        Assert.areEqual( 1, results.size(), 'One response should be returned for one input.' );
        Assert.isTrue( results[0], 'The resynchronisation should complete successfully.' );
        List<Asset> updatedAssets = new List<Asset>();
        updatedAssets = [
            SELECT Id, NSP_States_of_Operations__c
            FROM Asset
            WHERE Id = :assetRecords[0].Id
        ];
        Assert.isNotNull( updatedAssets, 'Updated Asset list should not be null.' );
        Assert.isFalse( updatedAssets.isEmpty(), 'Updated Asset should exist.' );
        Assert.areEqual( 'AZ;', updatedAssets[0].NSP_States_of_Operations__c, 'The Asset should contain the eligible state.' );
        List<NSP_Sub_Client__c> updatedSubClients = new List<NSP_Sub_Client__c>();
        updatedSubClients = [
            SELECT Id, NSP_States_of_Operations__c
            FROM NSP_Sub_Client__c
            WHERE NSP_Asset__c = :assetRecords[0].Id
            LIMIT 1
        ];
        Assert.isNotNull( updatedSubClients, 'Updated Sub Client list should not be null.' );
        Assert.isFalse( updatedSubClients.isEmpty(), 'Updated Sub Client should exist.' );
        Assert.areEqual( 'AZ;', updatedSubClients[0].NSP_States_of_Operations__c, 'The Sub Client should contain the eligible state.' );
    }

    @isTest
    private static void shouldReturnEmptyResponseForEmptyInputs() {
        List<Id> inputs = new List<Id>();

        Test.startTest();
        List<Boolean> results = SubClientAssetStateSyncAction.invoke(inputs);
        Test.stopTest();

        Assert.isNotNull( results, 'The response should not be null.' );
        Assert.areEqual( 0, results.size(), 'No response should be returned for an empty input list.' );
    }

    @isTest
    private static void shouldReturnEmptyResponseForNullInputs() {
        Test.startTest();
        List<Boolean> results = SubClientAssetStateSyncAction.invoke(null);
        Test.stopTest();

        Assert.isNotNull( results, 'The response should not be null.' );
        Assert.areEqual( 0, results.size(), 'No response should be returned when the input list is null.' );
    }
}