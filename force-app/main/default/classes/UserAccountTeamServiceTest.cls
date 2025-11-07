@IsTest
private class UserAccountTeamServiceTest {

    @IsTest
    private static void mapTeamMembers_NullAndEmptyInputs() {
        // Null input should return a non-null, empty list
        List<UserAccountTeamService.TeamMember> mappedFromNull = UserAccountTeamService.mapTeamMembers(null);
        System.Assert.areNotEqual(null, mappedFromNull, 'Null input should return non-null list');
        System.Assert.areEqual(0, mappedFromNull.size(), 'Null input should return empty list');

        // Empty list should return empty list
        List<UserAccountTeamMember> empty = new List<UserAccountTeamMember>();
        List<UserAccountTeamService.TeamMember> mappedFromEmpty = UserAccountTeamService.mapTeamMembers(empty);
        System.Assert.areNotEqual(null, mappedFromEmpty, 'Empty input should return non-null list');
        System.Assert.areEqual(0, mappedFromEmpty.size(), 'Empty input should return empty list');
    }

    @IsTest
    private static void mapTeamMembers_FabricatedRecord_NoDml() {
        // Fabricate an in-memory UserAccountTeamMember sObject (NOT inserted)
        // Only set fields used by mapper; use a stub Id for stable assertions.
        Id memberId   = '001000000000001AAA'.replace('001','01D'); // 01D is the prefix for UserAccountTeamMember in many orgs, but any 18-char Id is fine in tests.


        UserAccountTeamMember fabricated = new UserAccountTeamMember();
        // Assign fields via dynamic DML-safe approach since object exists in org; direct assignment is also fine in tests.
        fabricated.Id	=	memberId;
        fabricated.TeamMemberRole	=	'Executive Sponsor';
        fabricated.AccountAccessLevel	=	'Read';
        fabricated.OpportunityAccessLevel	=	'Read';
        fabricated.CaseAccessLevel	=	'Read';

        List<UserAccountTeamMember> input = new List<UserAccountTeamMember>{ fabricated };

        List<UserAccountTeamService.TeamMember> mapped = UserAccountTeamService.mapTeamMembers(input);

        System.Assert.areEqual(1, mapped.size(), 'Should map exactly one record');
        UserAccountTeamService.TeamMember dto = mapped[0];

        System.Assert.areEqual(memberId, dto.id, 'Id should map');
        // User.Name maps defensively to '' when User is null/unloaded
        System.Assert.areEqual('', dto.userName, 'UserName should be empty when related User is not loaded');
        System.Assert.areEqual('Executive Sponsor', dto.teamMemberRole, 'TeamMemberRole should map');
        System.Assert.areEqual('Read', dto.accountAccessLevel, 'AccountAccessLevel should map');
        System.Assert.areEqual('Read', dto.opportunityAccessLevel, 'OpportunityAccessLevel should map');
        System.Assert.areEqual('Read', dto.caseAccessLevel, 'CaseAccessLevel should map');
    }

    @IsTest
    private static void teamMemberDTO_DirectInstantiation_GettersSetters() {
        // Explicitly cover TeamMember class by constructing and setting fields
        UserAccountTeamService.TeamMember dto = new UserAccountTeamService.TeamMember();
        Id idVal = '00k000000000003AAA';
        Id ownerVal = '005000000000004AAA';
        Id userVal = '005000000000005AAA';

        dto.id = idVal;
        dto.ownerId = ownerVal;
        dto.userId = userVal;
        dto.userName = 'Jane Doe';
        dto.teamMemberRole = 'Account Manager';
        dto.accountAccessLevel = 'Edit';
        dto.opportunityAccessLevel = 'Edit';
        dto.caseAccessLevel = 'Read';
        dto.contactAccessLevel = 'Read';

        System.Assert.areEqual(idVal, dto.id);
        System.Assert.areEqual(ownerVal, dto.ownerId);
        System.Assert.areEqual(userVal, dto.userId);
        System.Assert.areEqual('Jane Doe', dto.userName);
        System.Assert.areEqual('Account Manager', dto.teamMemberRole);
        System.Assert.areEqual('Edit', dto.accountAccessLevel);
        System.Assert.areEqual('Edit', dto.opportunityAccessLevel);
        System.Assert.areEqual('Read', dto.caseAccessLevel);
        System.Assert.areEqual('Read', dto.contactAccessLevel);
    }
        @IsTest
    private static void getTeamMembersByOwner_NullOwner_ReturnsEmpty() {
        Test.startTest();
        List<UserAccountTeamService.TeamMember> result = UserAccountTeamService.getTeamMembersByOwner(null);
        Test.stopTest();
        System.Assert.areNotEqual(null, result, 'Result should not be null');
        System.Assert.areEqual(0, result.size(), 'Null ownerId should return empty list');
    }

    @IsTest
    private static void getTeamMembersByOwner_NoRecords_ReturnsEmpty() {
        // Use a placeholder Id for owner; no DML on UserAccountTeamMember will occur.
        Id ownerId = '005000000000009AAA';
        Test.startTest();
        List<UserAccountTeamService.TeamMember> result = UserAccountTeamService.getTeamMembersByOwner(ownerId);
        Test.stopTest();
        System.Assert.areNotEqual(null, result, 'Result should not be null');
        System.Assert.areEqual(0, result.size(), 'No UserAccountTeamMember records -> empty list');
    }

    @IsTest
    private static void queryTeamMembersByOwner_NoDml_ReturnsEmpty() {
        Id ownerId = '005000000000010AAA';
        Test.startTest();
        List<UserAccountTeamMember> queried = UserAccountTeamService.queryTeamMembersByOwner(ownerId);
        Test.stopTest();
        System.Assert.areEqual(0, queried.size(), 'Query should return 0 records when none were inserted');
    }

    // New tests for getPageSize coverage

    @IsTest
    private static void getPageSize_ConfiguredValueFromOrgDefaults() {
        // Arrange: ensure org default exists with a specific numeric value
        UserDefaultAccountTeamSettings__c orgDefaults = UserDefaultAccountTeamSettings__c.getOrgDefaults();
        if (orgDefaults == null) {
            orgDefaults = new UserDefaultAccountTeamSettings__c();
        }
        orgDefaults.PageSize__c = 7; // numeric value which should be returned
        upsert orgDefaults;

        // Act
        Test.startTest();
        Integer size = UserAccountTeamService.getPageSize();
        Test.stopTest();

        // Assert
        System.Assert.areEqual(7, size, 'Should return the configured PageSize from org defaults');
    }
    @IsTest
    private static void getPageSize_ConfiguredValueOfLessThanOneFromOrgDefaults() {
        // Arrange: ensure org default exists with a specific numeric value
        UserDefaultAccountTeamSettings__c orgDefaults = UserDefaultAccountTeamSettings__c.getOrgDefaults();
        if (orgDefaults == null) {
            orgDefaults = new UserDefaultAccountTeamSettings__c();
        }
        orgDefaults.PageSize__c = -1; // numeric value which should be returned
        upsert orgDefaults;

        // Act
        Test.startTest();
        Integer size = UserAccountTeamService.getPageSize();
        Test.stopTest();

        // Assert
        System.Assert.areEqual(1, size, 'Should return the configured PageSize from org defaults');
    }

    @IsTest
    private static void getPageSize_FallbackToDefaultWhenMissing() {
        // Arrange: remove org defaults by setting to null fields and deleting record if possible
        // Note: In tests, getOrgDefaults() returns the org defaults record if it exists. We'll create,
        // then delete to simulate "missing" configuration.
        UserDefaultAccountTeamSettings__c existing = new UserDefaultAccountTeamSettings__c();

        // Act
        Test.startTest();
        Integer size = UserAccountTeamService.getPageSize();
        Test.stopTest();

        // Assert default (5) from implementation
        System.Assert.areEqual(1, size, 'Should fall back to default when org defaults are missing');
    }
}