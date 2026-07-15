@isTest
private class UserAvailabilityFlowTest {

    @testSetup
    private static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u1 = new User(
            Alias = 'flowu1',
            Email = 'flowu1@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'FlowOne',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago',
            Username = 'flowu1' + String.valueOf( Datetime.now().getTime() ) + '@example.com',
            ProfileId = p.Id
        );
        insert u1;

        User u2 = new User(
            Alias = 'flowu2',
            Email = 'flowu2@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'FlowTwo',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago',
            Username = 'flowu2' + String.valueOf( Datetime.now().getTime() ) + '@example.com',
            ProfileId = p.Id
        );
        insert u2;

        // u1 -> 2 events, u2 -> 0 events (today, GMT noon to stay inside the day window)
        Date gmtToday = Datetime.now().dateGmt();
        Datetime base = Datetime.newInstanceGmt(
            gmtToday.year(), gmtToday.month(), gmtToday.day(), 12, 0, 0
        );
        insert new List<Event>{
            new Event( OwnerId = u1.Id, StartDateTime = base,             EndDateTime = base.addHours(1) ),
            new Event( OwnerId = u1.Id, StartDateTime = base.addHours(2), EndDateTime = base.addHours(3) )
        };

        Schedule_Seller_Settings__c scheduleSettings = new Schedule_Seller_Settings__c();
        scheduleSettings.SetupOwnerId = UserInfo.getOrganizationId();
        scheduleSettings.Name = 'TestFlow';
        insert scheduleSettings;
    }

    @isTest
    private static void testGetUsers_withValidInput() {
        List<User> users = [
            SELECT Id FROM User WHERE Username LIKE 'flowu%' ORDER BY CreatedDate ASC
        ];
        System.assertEquals( 2, users.size(), 'Expect two test users' );

        List<Id> userIds = new List<Id>();
        for ( User u : users ) {
            userIds.add( u.Id );
        }

        UserAvailabilityFlow.UserAvailabilityInput input = new UserAvailabilityFlow.UserAvailabilityInput();
        input.userIds = userIds;
        input.selectedDate = Datetime.now().dateGmt();

        Test.startTest();
        List<List<User>> results = UserAvailabilityFlow.getUsers(
            new List<UserAvailabilityFlow.UserAvailabilityInput>{ input }
        );
        Test.stopTest();

        System.assertNotEquals( null, results, 'Results should not be null' );
        System.assertEquals( 1, results.size(), 'Outer list should contain one element' );
        System.assertEquals( 2, results[0].size(), 'Both users should be returned' );
    }

    @isTest
    private static void testGetUsers_nullAndEmptyInputs() {
        // Input with null userIds and null date -> skips sort, returns empty inner list
        UserAvailabilityFlow.UserAvailabilityInput emptyInput =
            new UserAvailabilityFlow.UserAvailabilityInput();

        Test.startTest();
        List<List<User>> nullResults = UserAvailabilityFlow.getUsers( null );
        List<List<User>> emptyResults = UserAvailabilityFlow.getUsers(
            new List<UserAvailabilityFlow.UserAvailabilityInput>()
        );
        List<List<User>> skippedResults = UserAvailabilityFlow.getUsers(
            new List<UserAvailabilityFlow.UserAvailabilityInput>{ emptyInput }
        );
        Test.stopTest();

        System.assertNotEquals( null, nullResults, 'Null inputs should return non-null list' );
        System.assertEquals( 0, nullResults.size(), 'Null inputs should return empty outer list' );

        System.assertEquals( 0, emptyResults.size(), 'Empty inputs should return empty outer list' );

        System.assertEquals( 1, skippedResults.size(), 'One input should yield one outer element' );
        System.assertEquals( 0, skippedResults[0].size(), 'Missing userIds/date should yield empty inner list' );
    }
}