@IsTest
public class UserAvailabilityFlowTest {
    
    public class MockUserAvailabilityService {
        public  List<Id> getAvailableUsersForWindow(
            Datetime startDT,
            Datetime endDT,
            String skill
        ) {
            return new List<Id>{UserInfo.getUserId()};
        }
    }
    
    @IsTest
    static void testGetUsers_withValidInput() {
        // Prepare input
        UserAvailabilityFlow.UserAvailabilityInput input = new UserAvailabilityFlow.UserAvailabilityInput();
        input.startDT = Datetime.now();
        input.endDT = Datetime.now().addHours(1);
        input.skill = 'TestProduct';
        
        Test.startTest();
        List<List<Id>> results = UserAvailabilityFlow.getUsers(new List<UserAvailabilityFlow.UserAvailabilityInput>{input});
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Outer list should contain one element');
    }
    
}