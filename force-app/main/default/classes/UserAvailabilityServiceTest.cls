@IsTest
public class UserAvailabilityServiceTest {

    @TestSetup
    static void setupData() {

        // Get existing Business Hours (cannot insert)
        BusinessHours bh = [
            SELECT Id
            FROM BusinessHours
            WHERE IsActive = true
            LIMIT 1
        ];

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u1 = new User(
            Alias = 'uone',
            Email = 'uone@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'One',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            ProfileId = p.Id,
            UserName = 'uone' + System.currentTimeMillis() + '@test.com'
        );

        User u2 = new User(
            Alias = 'utwo',
            Email = 'utwo@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Two',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            ProfileId = p.Id,
            UserName = 'utwo' + System.currentTimeMillis() + '@test.com'
        );

        insert new List<User>{ u1, u2 };

        Datetime startDT = System.now().addHours(1);
        Datetime endDT   = startDT.addHours(1);

        insert new List<Event>{
            new Event(
                OwnerId = u1.Id,
                Subject = 'Busy 1',
                StartDateTime = startDT,
                EndDateTime = endDT
            ),
            new Event(
                OwnerId = u2.Id,
                Subject = 'Busy 2',
                StartDateTime = startDT,
                EndDateTime = endDT
            )
        };
    }

    @IsTest
    static void testGetBusinessDates() {
        BusinessHours bh = [
            SELECT Id FROM BusinessHours WHERE IsActive = true LIMIT 1
        ];

        Test.startTest();
        List<Date> dates =
            UserAvailabilityService.getBusinessDates(bh.Id, 7);
        Test.stopTest();

        System.assertNotEquals(null, dates);
        System.assert(dates.size() <= 7);
    }

    @IsTest
    static void testGetCountsMatrix() {
        User u = [SELECT Id FROM User WHERE Alias = 'uone' LIMIT 1];

        Test.startTest();
        List<List<Integer>> matrix =
            UserAvailabilityService.getCountsMatrix(u.Id);
        Test.stopTest();

        System.assert(matrix.size() > 0);
    }

    @IsTest
    static void testGetAggregateCountsMatrix() {
        Test.startTest();
        List<List<Integer>> matrix =
            UserAvailabilityService.getAggregateCountsMatrix('Schedule_Seller_HR360');
        Test.stopTest();

        System.assertNotEquals(null, matrix);
    }

    @IsTest
    static void testGetAvailableUsersForWindow() {
        Datetime startDT = System.now().addHours(3);
        Datetime endDT   = startDT.addHours(1);

        Test.startTest();
        List<Id> users =
            UserAvailabilityService.getAvailableUsersForWindow(
                startDT, endDT, 'Schedule_Seller_HR360'
            );
        Test.stopTest();

        System.assertNotEquals(null, users);
    }
}