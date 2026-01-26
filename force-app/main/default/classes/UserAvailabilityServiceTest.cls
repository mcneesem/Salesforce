@IsTest
private class UserAvailabilityServiceTest {

    @TestSetup
    static void setupData() {
        // Get default business hours (always exists)
        BusinessHours bh = [
            SELECT Id
            FROM BusinessHours
            WHERE IsDefault = true
            LIMIT 1
        ];

        // Create a test event for the running user
        Datetime startDt = Datetime.now().addDays(1);
        Datetime endDt   = startDt.addMinutes(60);

        Event e = new Event(
            OwnerId = UserInfo.getUserId(),
            Subject = 'Busy Slot',
            StartDateTime = startDt,
            EndDateTime = endDt
        );
        insert e;
    }

    @IsTest
    static void testGetBusinessDates() {

        BusinessHours bh = [
            SELECT Id
            FROM BusinessHours
            WHERE IsDefault = true
            LIMIT 1
        ];

        Test.startTest();
        List<Date> dates =
            UserAvailabilityService.getBusinessDates(bh.Id, 7);
        Test.stopTest();

        System.assertNotEquals(
            null,
            dates,
            'Business dates should not be null'
        );
        System.assert(
            dates.size() > 0,
            'At least one business date should be returned'
        );
    }

    @IsTest
    static void testGetCountsMatrix() {

        Test.startTest();
        List<List<Integer>> matrix =
            UserAvailabilityService.getCountsMatrix(
                UserInfo.getUserId(),
                30
            );
        Test.stopTest();

        System.assertNotEquals(
            null,
            matrix,
            'Counts matrix should not be null'
        );

        // Matrix rows represent time slots
        System.assert(
            matrix.size() > 0,
            'Matrix should contain at least one row'
        );

        // Each row should have up to 7 days
        for (List<Integer> row : matrix) {
            System.assert(
                row.size() <= 7,
                'Each row should represent up to 7 business days'
            );
        }
    }

    @IsTest
    static void testGetCountsMatrixWithNulls() {

        Test.startTest();
        List<List<Integer>> matrix =
            UserAvailabilityService.getCountsMatrix(null, null);
        Test.stopTest();

        System.assertNotEquals(
            null,
            matrix,
            'Matrix should still be returned even with null inputs'
        );
    }
}