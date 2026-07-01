@isTest
private class FindDuplicatesActionTest {

    @isTest
    private static void testFindDuplicatesAction() {
        Contact contact1 = new Contact(FirstName = 'John', LastName = 'Doe', Email='John.Doe@email.com');
        insert contact1;

        Contact contact2 = new Contact(FirstName = 'John', LastName = 'Doe', Email='John.Doe@email.com');

        FindDuplicatesAction.FindDuplicatesRequest request = new FindDuplicatesAction.FindDuplicatesRequest();
        request.record = contact2;

        List<FindDuplicatesAction.FindDuplicatesRequest> requests = new List<FindDuplicatesAction.FindDuplicatesRequest>();
        requests.add(request);

        List<FindDuplicatesAction.FindDuplicatesResponse> response = FindDuplicatesAction.invoke(requests);

        System.assertEquals( true , ( response != null ) , 'Response should not be null' );
        System.assertEquals( true , !response.isEmpty() , 'Response should not be empty' );
        System.assertEquals( true , ( response[0] != null ) , 'First response should not be null' );
        System.assertEquals( true , ( response[0].duplicateIds != null ) , 'List of duplicates should not be null' );
        System.assertEquals( true , !response[0].duplicateIds.isEmpty() , 'List of duplicates should not be empty' );
    }
}