/* Description : Test class for NSP_SAEmail_DateTimeController
    Date        : 06/08/2023 */
    @IsTest
    public class NSP_SAEmail_DateTimeControllerTest {
        @IsTest
        static void testGetFormattedDatetime() {
            NSP_SAEmail_DateTimeController controller = new NSP_SAEmail_DateTimeController();
            controller.date_time = DateTime.newInstanceGmt(2023, 6, 8, 10, 30, 0);
            controller.defined_format = 'MM/dd/yyyy hh:mm aa';
            String formattedDatetime = controller.getFormattedDatetime();
            System.assertNotEquals(null, formattedDatetime);
        }
        
        @IsTest
        static void testGetStartTime() {
            NSP_SAEmail_DateTimeController controller = new NSP_SAEmail_DateTimeController();
            controller.date_time = DateTime.newInstanceGmt(2023, 6, 8, 9, 0, 0);
            String startTime = controller.getStartTime();
               System.assertNotEquals(null, startTime);
        }
        
        @IsTest
        static void testGetEndTime() {
            NSP_SAEmail_DateTimeController controller = new NSP_SAEmail_DateTimeController();
            controller.endDate = DateTime.newInstanceGmt(2023, 6, 8, 18, 30, 0);
            String endTime = controller.getEndTime();
            System.assertNotEquals(null, endTime);
        }
    }