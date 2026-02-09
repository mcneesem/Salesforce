@IsTest
public class UserAvailabilityInputTest {
    
    @IsTest
    static void testUserAvailabilityInputFields() {
        // Create an instance and set values
        UserAvailabilityInput input = new UserAvailabilityInput();
        Datetime start = Datetime.now();
        Datetime endT = start.addHours(2);
        
        input.startDT = start;
        input.endDT = endT;
        input.product = 'TestProduct';
        input.stepMinutes = 15;
        
        // Assertions to verify values are stored correctly
        System.assertEquals(start, input.startDT, 'Start datetime should match');
        System.assertEquals(endT, input.endDT, 'End datetime should match');
        System.assertEquals('TestProduct', input.product, 'Product should match');
        System.assertEquals(15, input.stepMinutes, 'Step minutes should match');
    }
    
    @IsTest
    static void testUserAvailabilityInputDefaultValues() {
        // Create an instance without setting optional fields
        UserAvailabilityInput input = new UserAvailabilityInput();
        Datetime start = Datetime.now();
        Datetime endT = start.addHours(1);
        
        input.startDT = start;
        input.endDT = endT;
        
        // Required fields should be set
        System.assertEquals(start, input.startDT);
        System.assertEquals(endT, input.endDT);
        
        // Optional fields should remain null
        System.assertEquals(null, input.product, 'Product should be null by default');
        System.assertEquals(null, input.stepMinutes, 'Step minutes should be null by default');
    }
}