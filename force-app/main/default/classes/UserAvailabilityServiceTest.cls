@IsTest
private class UserAvailabilityServiceTest {

    // Utility: create a user for runAs
    private static User newUser(String aliasPrefix) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        return new User(
            Alias = aliasPrefix.left(8),
            Email = aliasPrefix + '@example.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = aliasPrefix,
            LastName = 'Tester',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = aliasPrefix + '.' + System.now().getTime() + '@example.com',
            ProfileId = p.Id
        );
    }

    @TestSetup
    static void setupData() {
        // Ensure default business hours exist and are queryable
        BusinessHours bh = [
            SELECT Id
            FROM BusinessHours
            WHERE IsDefault = true
            LIMIT 1
        ];

        // Create two test Users we may assign to the Permission Set
        User u1 = newUser('u1tester');
        User u2 = newUser('u2tester');
        insert new List<User>{ u1, u2 };

        // Assign Permission Set in a separate transaction context via runAs to avoid MIXED_DML
        PermissionSet sePs;
        try {
            sePs = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Sales_Engineer_WO' LIMIT 1];
        } catch (Exception ex) {
            sePs = null;
        }

        if (sePs != null) {
            // Use an admin-like context (the created user) to perform setup object DML separately
            System.runAs(u1) {
                insert new PermissionSetAssignment(AssigneeId = u1.Id, PermissionSetId = sePs.Id);
            }
            System.runAs(u2) {
                insert new PermissionSetAssignment(AssigneeId = u2.Id, PermissionSetId = sePs.Id);
            }
        }

        // Do NOT insert non-setup objects (like Event) here for the runAs users to avoid mixed DML.
        // Event inserts will occur inside tests.
        // However, we can insert an event for the running test context user for getCountsMatrix test.
        Datetime startDt = Datetime.now().addDays(1);
        Datetime endDt   = startDt.addMinutes(60);
        insert new Event(
            OwnerId = UserInfo.getUserId(),
            Subject = 'Busy Slot',
            StartDateTime = startDt,
            EndDateTime = endDt
        );
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
        List<Date> dates = UserAvailabilityService.getBusinessDates(bh.Id, 7);
        Test.stopTest();

        System.assertNotEquals(null, dates, 'Business dates should not be null');
        System.assert(dates.size() > 0, 'At least one business date should be returned');
    }

    @IsTest
    static void testGetCountsMatrix() {
        Test.startTest();
        List<List<Integer>> matrix = UserAvailabilityService.getCountsMatrix(UserInfo.getUserId(), 30);
        Test.stopTest();

        System.assertNotEquals(null, matrix, 'Counts matrix should not be null');
        System.assert(matrix.size() > 0, 'Matrix should contain at least one row');
        for (List<Integer> row : matrix) {
            System.assert(row.size() <= 7, 'Each row should represent up to 7 business days');
        }
    }

    @IsTest
    static void testGetCountsMatrixWithNulls() {
        Test.startTest();
        List<List<Integer>> matrix = UserAvailabilityService.getCountsMatrix(null, null);
        Test.stopTest();

        System.assertNotEquals(null, matrix, 'Matrix should still be returned even with null inputs');
    }

    @IsTest
    static void testGetAggregateCountsMatrix() {
        // Insert events for exactly one permissioned user (if PS exists) to exercise both busy and empty lists
        PermissionSet sePs;
        try {
            sePs = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Sales_Engineer_WO' LIMIT 1];
        } catch (Exception ex) {
            sePs = null;
        }

        // Fetch users that might have been created in @TestSetup
        List<User> users = [SELECT Id, Username FROM User WHERE Username LIKE 'u%tester.%@example.com' ORDER BY Username ASC LIMIT 2];

        if (sePs != null && users.size() == 2) {
            User u1 = users[0];
            // Insert a busy event for u1 only. This is non-setup DML and is separate from PSA DML done in @TestSetup.
            insert new Event(
                OwnerId = u1.Id,
                Subject = 'User1 Busy',
                StartDateTime = Datetime.now().addDays(1).addHours(8),
                EndDateTime = Datetime.now().addDays(1).addHours(9)
            );
        }

        Test.startTest();
        List<List<Integer>> aggregate = UserAvailabilityService.getAggregateCountsMatrix(30);
        Test.stopTest();

        System.assertNotEquals(null, aggregate, 'Aggregate matrix should not be null');
        for (List<Integer> row : aggregate) {
            System.assert(row.size() <= 7, 'Each row should represent up to 7 business days');
            for (Integer cell : row) {
                System.assertNotEquals(null, cell, 'Aggregated cell entries should never be null');
                System.assert(cell >= 0, 'Aggregated availability counts should be non-negative');
            }
        }
    }

    @IsTest
    static void testGetAggregateCountsMatrix_NoUsersInPermSet() {
        // If the PS does not exist in this org, the method short-circuits; ensure it still returns a valid matrix.
        PermissionSet sePs;
        try {
            sePs = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Sales_Engineer_WO' LIMIT 1];
        } catch (Exception ex) {
            sePs = null;
        }

        if (sePs == null) {
            Test.startTest();
            List<List<Integer>> aggregate = UserAvailabilityService.getAggregateCountsMatrix(15);
            Test.stopTest();

            System.assertNotEquals(null, aggregate, 'Aggregate matrix should not be null even when no users match the permission set');
            for (List<Integer> row : aggregate) {
                System.assert(row.size() <= 7, 'Each row should represent up to 7 business days');
            }
        }
    }
}