@isTest
private class UserPublicGroupMembershipServiceTest {

    // Utility: create a Queue (Group) and add a GroupMember for a specific User
    private static GroupMember createGroupAndMembership(User targetUser, String developerName, String displayName) {
        Group publicGroup = new Group(
            Name = displayName,
            DeveloperName = developerName,
            Type = 'Regular'
        );
        insert publicGroup;

        GroupMember groupMembership = new GroupMember(
            GroupId = publicGroup.Id,
            UserOrGroupId = targetUser.Id
        );
        insert groupMembership;
        return groupMembership;
    }

    // Utility: create a standard test user with meaningful field values
    private static User createStandardTestUser() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Long nowMillis = System.currentTimeMillis();
        String uniqueSuffix = String.valueOf(nowMillis);

        User standardUser = new User(
            FirstName = 'Group',
            LastName = 'Member',
            Alias = 'gmember',
            Email = 'group.member+' + uniqueSuffix + '@example.com',
            Username = 'group.member.' + uniqueSuffix + '@example.com',
            CommunityNickname = 'group_member_' + uniqueSuffix,
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
    private static void getGroupMembershipsByUser_whenMembershipExists_returnsMappedRows() {
        // Arrange
        User testUser = createStandardTestUser();
        List<PermissionSet> psets = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'Public_Group_Membership_View'
            LIMIT 1
        ];
        System.Assert.areNotEqual( null , psets , 'Should not return null' );
        System.Assert.areEqual( 1 , psets.size() , 'Expected exactly one PermissionSet row' );
        PermissionSet ps = psets[0];
        PermissionSetAssignment psa = new PermissionsetAssignment( AssigneeId = testUser.Id, permissionSetId =ps.id);
        insert psa;
        GroupMember createdMembership = createGroupAndMembership(testUser, 'Test_Queue_Dev', 'Test Queue');
        System.runAs(testUser){
            // Act
            Test.startTest();
            List<UserQueueMembershipService.Member> memberRows = UserPublicGroupMembershipService.getPublicGroupMembershipsByUser(testUser.Id);
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
            System.Assert.areEqual('Public Group', firstRow.reasonForMembership, 'Reason should map as implemented');
        }
    }

}
//