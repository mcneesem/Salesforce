@IsTest
public class UserAvailabilityFlowTest {
    
    public class MockUserAvailabilityService {
        public  List<Id> getAvailableUsersForWindow(
            Datetime startDT,
            Datetime endDT,
            String product,
            Integer stepMinutes
        ) {
            return new List<Id>{UserInfo.getUserId()};
        }
    }
    
    @IsTest
    static void testGetUsers_withValidInput() {
        // Prepare input
        UserAvailabilityInput input = new UserAvailabilityInput();
        input.startDT = Datetime.now();
        input.endDT = Datetime.now().addHours(1);
        input.product = 'TestProduct';
        input.stepMinutes = 30;
        
        Test.startTest();
        List<List<Id>> results = UserAvailabilityFlow.getUsers(new List<UserAvailabilityInput>{input});
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Outer list should contain one element');
    }
    
}