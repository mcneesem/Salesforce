@isTest
private class UserQueueMembershipServiceTest {

    // Utility: create a Queue (Group) and add a GroupMember for a specific User
    private static GroupMember createQueueAndMembership(User targetUser, String developerName, String displayName) {
        Group queueGroup = new Group(
            Name = displayName,
            DeveloperName = developerName,
            Type = 'Queue'
        );
        insert queueGroup;

        GroupMember queueMembership = new GroupMember(
            GroupId = queueGroup.Id,
            UserOrGroupId = targetUser.Id
        );
        insert queueMembership;
        return queueMembership;
    }

    // Utility: create a standard test user with meaningful field values
    private static User createStandardTestUser() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Long nowMillis = System.currentTimeMillis();
        String uniqueSuffix = String.valueOf(nowMillis);

        User standardUser = new User(
            FirstName = 'Queue',
            LastName = 'Member',
            Alias = 'qmember',
            Email = 'queue.member+' + uniqueSuffix + '@example.com',
            Username = 'queue.member.' + uniqueSuffix + '@example.com',
            CommunityNickname = 'queue_member_' + uniqueSuffix,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert standardUser;
        return standardUser;
    }

    @isTest
    private static void getQueueMembershipsByUser_whenRecordIdIsNull_returnsEmptyList() {
        Test.startTest();
        List<UserQueueMembershipService.Member> memberRows = UserQueueMembershipService.getQueueMembershipsByUser(Null);
        Test.stopTest();

        System.Assert.areNotEqual(null, memberRows, 'Method should never return null');
        System.Assert.areEqual(0, memberRows.size(), 'Null recordId should return empty list');
    }

    @isTest
    private static void getQueueMembershipsByUser_whenMembershipExists_returnsMappedRows() {
        // Arrange
        User testUser = createStandardTestUser();
        List<PermissionSet> psets = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'Queue_Membership_View'
            LIMIT 1
        ];
        System.Assert.areNotEqual( null , psets , 'Should not return null' );
        System.Assert.areEqual( 1 , psets.size() , 'Expected exactly one PermissionSet row' );
        PermissionSet ps = psets[0];
        PermissionSetAssignment psa = new PermissionsetAssignment( AssigneeId = testUser.Id, permissionSetId =ps.id);
        insert psa;
        GroupMember createdMembership = createQueueAndMembership(testUser, 'Test_Queue_Dev', 'Test Queue');
        System.runAs(testUser){
            // Act
            Test.startTest();
            List<UserQueueMembershipService.Member> memberRows = UserQueueMembershipService.getQueueMembershipsByUser(testUser.Id);
            Test.stopTest();

            // Assert
            System.Assert.areNotEqual(null, memberRows, 'Should not return null');
            System.Assert.areEqual(1, memberRows.size(), 'Expected exactly one membership row');

            UserQueueMembershipService.Member firstRow = memberRows[0];
            System.Assert.areEqual(createdMembership.Id, firstRow.id, 'GroupMember Id should map to DTO.id');
            System.Assert.areEqual(createdMembership.GroupId, firstRow.groupId, 'Group Id should map to DTO.groupId');

            Group relatedGroup = [SELECT Id, Name, DeveloperName FROM Group WHERE Id = :createdMembership.GroupId];
            System.Assert.areEqual(relatedGroup.Name, firstRow.groupName, 'Group.Name should map to DTO.queueName');
            System.Assert.areEqual(relatedGroup.DeveloperName, firstRow.groupDeveloperName, 'Group.DeveloperName should map to DTO.queueDeveloperName');
            System.Assert.areEqual('Queue Member', firstRow.reasonForMembership, 'Reason should map as implemented');
        }
    }

    @isTest
    private static void setAndGetQueueMemberRecords_filtersByTypeAndNameOrDeveloperName() {
        // Arrange
        User testUser = createStandardTestUser();

        Group validQueueWithBothNames = new Group(Name = 'Valid Queue 1', DeveloperName = 'Valid_Queue_1', Type = 'Queue');
        Group nonQueueGroup = new Group(Name = 'Public Group', DeveloperName = 'Public_Group', Type = 'Regular');
        insert new List<Group>{ validQueueWithBothNames, nonQueueGroup };

            GroupMember validQueueMembership = new GroupMember(GroupId = validQueueWithBothNames.Id, UserOrGroupId = testUser.Id);
        GroupMember nonQueueMembership = new GroupMember(GroupId = nonQueueGroup.Id, UserOrGroupId = testUser.Id);
        insert new List<GroupMember>{ validQueueMembership, nonQueueMembership };

            // Act (private method is @TestVisible)
            Test.startTest();
        List<UserQueueMembershipService.Member> resultRows = UserQueueMembershipService.buildMembers(new List<GroupMember>{
                validQueueMembership, nonQueueMembership
                    });
        Test.stopTest();

        // Assert
        System.Assert.areEqual(0, resultRows.size(), 'Only Queue type memberships with required fields should pass');

        Set<Id> returnedGroupMemberIds = new Set<Id>();
        for (UserQueueMembershipService.Member mappedRow : resultRows) {
            returnedGroupMemberIds.add(mappedRow.id);
            System.Assert.isTrue(mappedRow.groupId != null, 'GroupId should be populated');
            System.Assert.isTrue(String.isNotBlank(mappedRow.groupName) || String.isNotBlank(mappedRow.groupDeveloperName),
                                 'At least one of Name or DeveloperName must be non-blank');
        }
    }

    @isTest
    private static void queryQueueMembershipsByUser_whenRecordIdIsNull_returnsEmptyList() {
        Test.startTest();
        List<GroupMember> queriedMemberships = UserQueueMembershipService.selectGroupMemberships(null, 'Queue');
        Test.stopTest();

        System.Assert.areNotEqual(null, queriedMemberships, 'Private method should return non-null list');
        System.Assert.areEqual(0, queriedMemberships.size(), 'Null input should return an empty list');
    }

}
//