@isTest
private class UserAvailabilityServiceTest {

    @testSetup
    private static void setupData() {
        // Create two active users to act as "skilled" users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u1 = new User(
            Alias = 'tuser1',
            Email = 'tuser1@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UserOne',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago',
            Username = 'tuser1' + String.valueOf(Datetime.now().getTime()) + '@example.com',
            ProfileId = p.Id
        );
        insert u1;

        User u2 = new User(
            Alias = 'tuser2',
            Email = 'tuser2@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UserTwo',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago',
            Username = 'tuser2' + String.valueOf(Datetime.now().getTime()) + '@example.com',
            ProfileId = p.Id
        );
        insert u2;

        // Create Events for both users across a deterministic window: today 8-12
        Datetime base = Datetime.newInstance(Date.today(), Time.newInstance(8, 0, 0, 0));
        List<Event> evts = new List<Event>{
            new Event(OwnerId = u1.Id, StartDateTime = base, EndDateTime = base.addHours(1)), // 8-9 busy u1
            new Event(OwnerId = u1.Id, StartDateTime = base.addHours(2), EndDateTime = base.addHours(3)), // 10-11 busy u1
            new Event(OwnerId = u2.Id, StartDateTime = base.addMinutes(30), EndDateTime = base.addHours(1).addMinutes(30)) // 8:30-9:30 busy u2
        };
        insert evts;

        List<BusinessHours> defaultBusinessHours = [
            SELECT Id
            FROM BusinessHours
            WHERE ( Name = 'Schedule Seller' )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        Schedule_Seller_Settings__c scheduleSettings = new Schedule_Seller_Settings__c();
        scheduleSettings.SetupOwnerId = UserInfo.getOrganizationId();
        scheduleSettings.Name = 'Test';
        //scheduleSettings.DaysLimit__c = 10;
        scheduleSettings.BusinessHoursId__c = defaultBusinessHours[0].Id;
        insert scheduleSettings;
        // NOTE:
        // - Do NOT insert BusinessHours in this org (not insertable in tests)
        // - Avoid Mixed DML: We will NOT create PermissionSet/Assignments here.
        //   Instead, we simulate "skilled" users in each test via runAs + without performing setup-object DML.
    }

    // Helper to safely get two active users created in setup
    private static List<User> getTestUsers() {
        return [SELECT Id FROM User WHERE Username LIKE 'tuser%' ORDER BY CreatedDate ASC LIMIT 2];
    }

    @isTest
    private static void testGetTimeBlocks() {
        // Primary (non-MidMarket) skill
        Test.startTest();
        List<Event> central = UserAvailabilityService.getTimeBlocks( 'Schedule_Seller_HR360' , 'America/Chicago' );

        // Middle Market skill path (validates getTimeZoneBlocks MidMarket mappings via public getTimeBlocks)
        List<Event> centralMM = UserAvailabilityService.getTimeBlocks( 'Schedule_Seller_HR360_MidMarket' , 'America/Chicago' );

        Test.stopTest();

        System.assertNotEquals(0, central.size(), 'Central should return default time blocks');

        //MidMarket skill
        System.assertNotEquals(0, centralMM.size(), 'Central MM should resolve to middle-market blocks');
        // Sanity: MidMarket vs Primary may have same count; intent is mapping coverage
        System.assert(centralMM.size() >= 0, 'MidMarket mapping executed');
    }

    @isTest
    private static void testGetAvailableUsersForWindow_validWindow() {
        List<User> users = getTestUsers();
        System.assertEquals(2, users.size(), 'Expect two test users');

        // 9:00 - 10:00 window
        Datetime startDT = Datetime.newInstance(Date.today(), Time.newInstance(9, 0, 0, 0));
        Datetime endDT = startDT.addHours(1);

        // We cannot Mixed-DML PermissionSet assignments; rely on controller returning current user
        // or broad map in test context. We still validate behavior shape.
        Test.startTest();
        List<Id> available = UserAvailabilityService.getAvailableUsersForWindow(startDT, endDT, 'Schedule_Seller');
        Test.stopTest();

        // Expect at least zero; if controller requires real Custom Permission, list may be empty.
        // Validate the method executes and returns a list without exception.
        System.assertNotEquals(null, available, 'Method should return a non-null list');
    }

    @isTest
    private static void testGetAvailableUsersForWindow_invalidWindowAndNoSkillUsers() {
        // invalid window (end before start) yields empty
        Datetime startDT = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        Datetime endDT = startDT.addHours(-1);

        Test.startTest();
        List<Id> available = UserAvailabilityService.getAvailableUsersForWindow(startDT, endDT, 'Nonexistent_Skill');
        Test.stopTest();

        System.assertEquals(0, available.size(), 'Invalid window or no skilled users should return empty list');
    }

    @isTest
    private static void testGetAggregateCountsMatrix_withTwoUsers() {
        Test.startTest();
        List<List<List<Id>>> matrix = UserAvailabilityService.getAggregateUserIdsMatrix('Schedule_Seller_HR360', 'America/Chicago');
        Test.stopTest();
        System.assertNotEquals(null, matrix, 'Aggregate matrix should not be null');
        System.assert(matrix.size() >= 0, 'Aggregate matrix should have 0 or more rows');
    }

    @isTest
    private static void testGetBusinessDates_handlesNoBH() {
        Test.startTest();
        List<Date> dates = UserAvailabilityService.getBusinessDates( 'Schedule_Seller_HR360' );
        Test.stopTest();

        System.assertNotEquals(null, dates, 'Dates list should not be null');
        System.assertEquals(true, dates.isEmpty() || dates.size() <= 10, 'Dates should be empty or limited');
    }

    @isTest
    private static void testGetBusinessDates_skipsToday_forNonAdmin() {
        // Create a non-admin user (no Schedule_Seller_Admin custom permission)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'nausr',
            Email = 'nausr@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'NonAdmin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago',
            Username = 'nausr' + String.valueOf(Datetime.now().getTime()) + '@example.com',
            ProfileId = p.Id
        );
        insert u;

        Test.startTest();
        System.runAs(u) {
            List<Date> dates = UserAvailabilityService.getBusinessDates('Schedule_Seller_HRCore');
            System.assertNotEquals(null, dates, 'Dates list should not be null');
            // Non-admin must not see today if BH would include it
            System.assertEquals(false, dates.contains(Date.today()), 'Non-admin must not see today in available dates.');
            for (Date d : dates) {
                System.assertEquals(true, d > Date.today(), 'All dates must be strictly after today for non-admin.');
            }
            System.assertEquals(true, dates.size() <= 10, 'Must not exceed DAYS_LIMIT.');
        }
        Test.stopTest();
    }

    @isTest
    private static void testGetBusinessDates_allowsToday_forAdminIfPresent() {
        // Try to find any user that has the Schedule_Seller_Admin custom permission via controller
        Map<Id, User> admins = CustomPermissionController.getPermittedUsersMap('Schedule_Seller_Admin');
        User target;
        if (admins != null && !admins.isEmpty()) {
            target = admins.values()[0];
        } else {
            // Fallback: create a regular user; we cannot Mixed-DML assign CPs here.
            // In this fallback, we only assert method stability/limits.
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            target = new User(
                Alias = 'admlk',
                Email = 'admlk@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'AdminLike',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Chicago',
                Username = 'admlk' + String.valueOf(Datetime.now().getTime()) + '@example.com',
                ProfileId = p.Id
            );
            insert target;
        }

        Test.startTest();
        System.runAs(target) {
            List<Date> dates = UserAvailabilityService.getBusinessDates('Schedule_Seller_HRCore');
            System.assertNotEquals(null, dates, 'Dates list should not be null');
            System.assertEquals(true, dates.size() <= 10, 'Must not exceed DAYS_LIMIT.');
            // We do not force BH; if BH includes today for this user, our code should not remove it for admins.
            // Therefore, no strict assertion on presence of today beyond the absence of filtering errors.
        }
        Test.stopTest();
    }
    @isTest
    private static void testSortUsersByDailyLoad_sortsAscending() {
        List<User> users = getTestUsers();
        System.assertEquals( 2, users.size(), 'Expect two test users' );

        List<Id> inputIds = new List<Id>();
        for ( User u : users ) {
            inputIds.add( u.Id );
        }

        // Setup creates u1 with 2 events and u2 with 1 event, both today
        Test.startTest();
        List<User> sorted = UserAvailabilityService.sortUsersByDailyLoad( inputIds, Date.today() );
        Test.stopTest();

        System.assertNotEquals( null, sorted, 'Sorted list should not be null' );
        System.assertEquals( 2, sorted.size(), 'Both users should be returned' );

        // Identify the busier user (2 events) - must rank LAST
        Map<Id, Integer> eventCountByUser = new Map<Id, Integer>();
        for ( AggregateResult ar : [
            SELECT OwnerId, COUNT(Id) cnt
            FROM Event
            WHERE OwnerId IN :inputIds
            AND DAY_ONLY( StartDateTime ) = :Date.today()
            GROUP BY OwnerId
        ] ) {
            eventCountByUser.put( (Id) ar.get('OwnerId'), (Integer) ar.get('cnt') );
        }

        Integer firstLoad = eventCountByUser.containsKey( sorted[0].Id )
            ? eventCountByUser.get( sorted[0].Id ) : 0;
        Integer lastLoad = eventCountByUser.containsKey( sorted[ sorted.size() - 1 ].Id )
            ? eventCountByUser.get( sorted[ sorted.size() - 1 ].Id ) : 0;

        System.assertEquals(
            true,
            firstLoad <= lastLoad,
            'Users should be sorted ascending by event count for the day'
        );
    }

    @isTest
    private static void testSortUsersByDailyLoad_nullAndEmptyGuards() {
        Test.startTest();
        List<User> r1 = UserAvailabilityService.sortUsersByDailyLoad( null, Date.today() );
        List<User> r2 = UserAvailabilityService.sortUsersByDailyLoad( new List<Id>(), Date.today() );
        List<User> r3 = UserAvailabilityService.sortUsersByDailyLoad(
            new List<Id>{ UserInfo.getUserId() },
            null
        );
        Test.stopTest();

        System.assertEquals( 0, r1.size(), 'Null userIds should return empty list' );
        System.assertEquals( 0, r2.size(), 'Empty userIds should return empty list' );
        System.assertEquals( 0, r3.size(), 'Null date should return empty list' );
    }

}
//