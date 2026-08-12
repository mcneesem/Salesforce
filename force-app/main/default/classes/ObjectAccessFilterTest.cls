@isTest
private class ObjectAccessFilterTest {
    // test w/ ObjectAccessFilterTest (100%)

    @isTest
    private static void filterEditableRecords_withEditableRecords_returnsRecords() {
        Account testAccount = new Account( Name = 'Test Account' );
        insert testAccount;

        ObjectAccessFilter.FilterInput input = new ObjectAccessFilter.FilterInput();
        input.records = new List<SObject>{ [SELECT Id FROM Account WHERE Id = :testAccount.Id] };
        input.maxRecords = 100;

        Test.startTest();
        List<ObjectAccessFilter.FilterResult> results = ObjectAccessFilter.filterEditableRecords(
            new List<ObjectAccessFilter.FilterInput>{ input }
        );
        Test.stopTest();

        System.Assert.areEqual( 1, results.size(), 'Expected one result wrapper' );
        System.Assert.isFalse( results[0].isTruncated, 'Should not be truncated' );
        System.Assert.isNotNull( results[0].editableRecords, 'Editable records should not be null' );
        System.Assert.areEqual( 1, results[0].editableRecords.size(), 'Running user should be able to edit own account' );
    }

    @isTest
    private static void filterEditableRecords_withEmptyList_returnsEmptyResult() {
        ObjectAccessFilter.FilterInput input = new ObjectAccessFilter.FilterInput();
        input.records = new List<SObject>();
        input.maxRecords = 100;

        Test.startTest();
        List<ObjectAccessFilter.FilterResult> results = ObjectAccessFilter.filterEditableRecords(
            new List<ObjectAccessFilter.FilterInput>{ input }
        );
        Test.stopTest();

        System.Assert.areEqual( 1, results.size(), 'Expected one result wrapper' );
        System.Assert.isFalse( results[0].isTruncated, 'Should not be truncated' );
        System.Assert.isTrue( results[0].editableRecords.isEmpty(), 'Should return empty list' );
    }

    @isTest
    private static void filterEditableRecords_withNullInputs_returnsEmptyList() {
        Test.startTest();
        List<ObjectAccessFilter.FilterResult> results = ObjectAccessFilter.filterEditableRecords( null );
        Test.stopTest();

        System.Assert.isTrue( results.isEmpty(), 'Null input should return empty results' );
    }

    @isTest
    private static void filterEditableRecords_exceedsMax_truncatesAndFlags() {
        List<Account> accounts = new List<Account>();
        for ( Integer i = 0; i < 5; i++ ) {
            accounts.add( new Account( Name = 'Bulk Test ' + i ) );
        }
        insert accounts;

        List<SObject> queried = [SELECT Id FROM Account WHERE Id IN :accounts];

        ObjectAccessFilter.FilterInput input = new ObjectAccessFilter.FilterInput();
        input.records = queried;
        input.maxRecords = 3;

        Test.startTest();
        List<ObjectAccessFilter.FilterResult> results = ObjectAccessFilter.filterEditableRecords(
            new List<ObjectAccessFilter.FilterInput>{ input }
        );
        Test.stopTest();

        System.Assert.areEqual( 1, results.size(), 'Expected one result wrapper' );
        System.Assert.isTrue( results[0].isTruncated, 'Should flag truncation when input exceeds max' );
        System.Assert.isTrue( results[0].editableRecords.size() <= 3, 'Should process at most maxRecords' );
    }

    @isTest
    private static void filterEditableRecords_defaultMax_usedWhenNull() {
        Account testAccount = new Account( Name = 'Default Max Test' );
        insert testAccount;

        ObjectAccessFilter.FilterInput input = new ObjectAccessFilter.FilterInput();
        input.records = new List<SObject>{ [SELECT Id FROM Account WHERE Id = :testAccount.Id] };
        input.maxRecords = null;

        Test.startTest();
        List<ObjectAccessFilter.FilterResult> results = ObjectAccessFilter.filterEditableRecords(
            new List<ObjectAccessFilter.FilterInput>{ input }
        );
        Test.stopTest();

        System.Assert.areEqual( 1, results.size(), 'Expected one result wrapper' );
        System.Assert.isFalse( results[0].isTruncated, 'Should not be truncated with default max' );
        System.Assert.areEqual( 1, results[0].editableRecords.size(), 'Should return the editable record' );
    }

}