@isTest
private class UserAvailabilityFlowTest {
    
    @isTest
    private static void testGetUsers_withValidInput() {
        // Prepare input
        UserAvailabilityFlow.UserAvailabilityInput input = new UserAvailabilityFlow.UserAvailabilityInput();
        input.startDateTime = Datetime.now();
        input.endDateTime = Datetime.now().addHours(1);
        input.skill = 'TestProduct';
        
        Test.startTest();
        List<List<Id>> results = UserAvailabilityFlow.getUsers(new List<UserAvailabilityFlow.UserAvailabilityInput>{input});
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Outer list should contain one element');
    }
    
}