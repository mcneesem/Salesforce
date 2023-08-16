@isTest
private class NSP_sObjectOperationControllerTest {
    @TestSetup
    static void setupData(){
        List<Account> accounts = new List<Account>();
        for (Integer intgr = 0; intgr < 5; intgr++) {
            Account acc = (Account) NSP_TestDataFactory.createSObject(new Account());
            acc.Name = 'Test ' + intgr;
            accounts.add(acc);
        }

        insert accounts;
    }

    /**
     * This method validates the search results returned by searchRecordsByFilters method.
     */
    @isTest
    static void searchRecordsByFiltersReturnsOnlyValidResults() {
        // GIVEN
        String searchConfig = '{"searchTerm": "Test 1","preSelectedRecs": "[]" , "objectApiName": "Account", "searchCategory": "Name", "resultSize":10 , "additionalInfoField":"BillingAddress,CurrencyIsoCode"}';

        // WHEN
        List<NSP_LookupOption> results = NSP_sObjectOperationController.searchRecordsByFilters(searchConfig);

        // THEN
        System.assertEquals(1, results.size());
        System.assertEquals('Test 1', results[0].label);
    }

    @isTest
    static void searchRecordsByFiltersReturnsEmptyArrayWhenNoResultAvailable() {
        // GIVEN
        String searchConfig = '{"searchTerm": "Test 12","preSelectedRecs": "[]" , "objectApiName": "Account", "searchCategory": "Name", "resultSize":10 }';

        // WHEN
        List<NSP_LookupOption> results = NSP_sObjectOperationController.searchRecordsByFilters(searchConfig);

        // THEN
        System.assertEquals(0, results.size(), 'Result should be empty when record not available with the given search term.');
    }

    @isTest
    static void upsertAndDeleteRecordsCreateNewRecords(){
        // GIVEN
        List<String> recordsToInsert = new List<String>{ '{ "LastName": "Test 1" }' , '{ "LastName": "Test 2" }' };
        Map<String, List<String>> recordsToUpsertMap = new Map<String, List<String>>{ 'Contact' => recordsToInsert };

        // WHEN
        String contactSelectionQuery = new NSP_QueryBuilder('Contact').build();
        System.assertEquals(0, Database.query(contactSelectionQuery).size(), 'No Contact record should exist.');
        NSP_sObjectOperationController.upsertAndDeleteRecords(recordsToUpsertMap, new Map<String, List<String>>());

        // THEN
        System.assertEquals(2, Database.query(contactSelectionQuery).size(), '2 Contact records should exist.');
    }

    @isTest
    static void upsertAndDeleteRecordsDeleteRecords(){
        // GIVEN
        String accountSelectionQuery = new NSP_QueryBuilder('Account').build();
        List<Account> accounts = (List<Account>) Database.query(accountSelectionQuery);

        // Validate existing records
        System.assertEquals(5, accounts.size(), 'Should return all the 5 accounts which we have created in test setup method');

        List<String> recordsToDelete = new List<String>{ '{ "Id": "' + accounts[0].Id + '" }' , '{ "Id": "' + accounts[1].Id + '" }' };
        Map<String, List<String>> recordsToDeleteMap = new Map<String, List<String>>{ 'Account' => recordsToDelete };

        // WHEN
        NSP_sObjectOperationController.upsertAndDeleteRecords(new Map<String, List<String>>(), recordsToDeleteMap);

        // THEN
        System.assertEquals(3, Database.query(accountSelectionQuery).size(), '3 Account records should exist.');
    }

    @isTest
    static void upsertAndDeleteRecordsInsertAndDeleteRecords(){
        // GIVEN
        String accountSelectionQuery = new NSP_QueryBuilder('Account').build();
        String contactSelectionQuery = new NSP_QueryBuilder('Contact').build();

        List<Account> accounts = (List<Account>) Database.query(accountSelectionQuery);
        List<String> recordsToInsert = new List<String>{ '{ "LastName": "Test 1" }' , '{ "LastName": "Test 2" }' };
        Map<String, List<String>> recordsToUpsertMap = new Map<String, List<String>>{ 'Contact' => recordsToInsert };

        // Validate existing records
        System.assertEquals(5, accounts.size(), 'Should return all the 5 accounts which we have created in test setup method');
        System.assertEquals(0, Database.query(contactSelectionQuery).size(), 'No Contact record should exist.');

        List<String> recordsToDelete = new List<String>{ '{ "Id": "' + accounts[0].Id + '" }' , '{ "Id": "' + accounts[1].Id + '" }' };
        Map<String, List<String>> recordsToDeleteMap = new Map<String, List<String>>{ 'Account' => recordsToDelete };

        // WHEN
        NSP_sObjectOperationController.upsertAndDeleteRecords(recordsToUpsertMap, recordsToDeleteMap);

        // THEN
        System.assertEquals(3, Database.query(accountSelectionQuery).size(), '3 Account records should exist.');
        System.assertEquals(2, Database.query(contactSelectionQuery).size(), '2 Contact records should exist.');
    }

    @isTest
    static void upsertAndDeleteRecordsNoRecordInsertedOrDeletedWhenBothMapsAreEmpty(){
        // GIVEN, 
        String accountSelectionQuery = new NSP_QueryBuilder('Account').build();
        String contactSelectionQuery = new NSP_QueryBuilder('Contact').build();

        // WHEN
        NSP_sObjectOperationController.upsertAndDeleteRecords(new Map<String, List<String>>(), new Map<String, List<String>>());

        // THEN
        System.assertEquals(5, Database.query(accountSelectionQuery).size(), '5 Account records should exist.');
        System.assertEquals(0, Database.query(contactSelectionQuery).size(), '0 Contact records should exist.');
    }
}