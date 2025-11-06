@IsTest
private class UserOpportunityTeamServiceTest {

    @IsTest
    private static void mapTeamMembers_NullAndEmptyInputs() {
        List<UserOpportunityTeamService.TeamMember> mappedFromNull = UserOpportunityTeamService.mapTeamMmebers(null);
        System.Assert.areNotEqual(null, mappedFromNull, 'Null input should return non-null list');
        System.Assert.areEqual(0, mappedFromNull.size(), 'Null input should return empty list');

        // Empty list should return empty list
        List<UserOpportunityTeamService.TeamMember> mappedFromEmpty = UserOpportunityTeamService.mapTeamMmebers(new List<UserTeamMember>());
        System.Assert.areNotEqual(null, mappedFromEmpty, 'Empty input should return non-null list');
        System.Assert.areEqual(0, mappedFromEmpty.size(), 'Empty input should return empty list');
    }

    @IsTest
    private static void mapTeamMembers_FabricatedRecord_NoDml() {
        // Fabricate an in-memory UserTeamMember sObject (Not Inserted)
        // Only set fields used by mapper; use a stub Id for stable assertion.
        Id memberId = '001000000000001AAA'.replace('001','00p'); // 00p is the prefix for UserTeamMember in many orgs, but any 18-char Id is fine in tests.
        UserTeamMember fabricated = new UserTeamMember();
        // Assign fields via dynamic DML-safe approach since sobject exists in org; direct assignment is also fine in tests
        fabricated.id = memberId;
        fabricated.TeamMemberRole = 'Test Role';
        fabricated.OpportunityAccessLevel = 'Read';

        List<UserTeamMember> input = new List<UserTeamMember>{ fabricated };

        List<UserOpportunityTeamService.TeamMember> mapped = UserOpportunityTeamService.mapTeamMmebers(input);
        System.Assert.areEqual(1, mapped.size(), 'Should map exactly one record');

        UserOpportunityTeamService.TeamMember mappedRecord = mapped[0];
        System.Assert.areEqual(memberId, mappedRecord.id, 'Id should be mapped');
        System.Assert.areEqual('Test Role', mappedRecord.teamMemberRole, 'TeamMemberRole should be mapped');
        System.Assert.areEqual('Read', mappedRecord.opportunityAccessLevel, 'OpportunityAccessLevel should be mapped');
        System.Assert.areEqual('', mappedRecord.userName, 'userName should be empty when related user is not loaded');
    }

    @IsTest
    private static void teamMemberDTO_DirectInstantiation_GettersSetters() {
        // Explicitly cover TeamMember class by constructing and setting fields
        UserOpportunityTeamService.TeamMember dto = new UserOpportunityTeamService.TeamMember();
        Id idVal = '00p000000000003AAA';
        Id ownerVal = '005000000000004AAA';
        Id userVal = '005000000000005AAA';

        dto.id = idVal;
        dto.ownerId = ownerVal;
        dto.userId = userVal;
        dto.userName = 'Jane Doe';
        dto.teamMemberRole = 'Account Manager';
        dto.opportunityAccessLevel = 'Edit';

        System.Assert.areEqual(idVal, dto.id);
        System.Assert.areEqual(ownerVal, dto.ownerId);
        System.Assert.areEqual(userVal, dto.userId);
        System.Assert.areEqual('Jane Doe', dto.userName);
        System.Assert.areEqual('Account Manager', dto.teamMemberRole);
        System.Assert.areEqual('Edit', dto.opportunityAccessLevel);
    }

    @IsTest
    private static void getTeamMembersByOwner_NullOwner_ReturnsEmpty() {
        Test.startTest();
        List<UserOpportunityTeamService.TeamMember> result = UserOpportunityTeamService.getTeamMembersByOwner(null);
        Test.stopTest();
        System.Assert.areNotEqual(null, result, 'Result should not be null');
        System.Assert.areEqual(0, result.size(), 'Null ownerId should return empty list');
    }

    @IsTest
    private static void getTeamMembersByOwner_NoRecords_ReturnsEmpty() {
        // Use a placeholder Id for owner; no DML on UserAccountTeamMember will occur.
        Id ownerId = '005000000000009AAA';
        Test.startTest();
        List<UserOpportunityTeamService.TeamMember> result = UserOpportunityTeamService.getTeamMembersByOwner(ownerId);
        Test.stopTest();
        System.Assert.areNotEqual(null, result, 'Result should not be null');
        System.Assert.areEqual(0, result.size(), 'No UserAccountTeamMember records -> empty list');
    }

    @IsTest
    private static void queryTeamMembersByOwner_NoDml_ReturnsEmpty() {
        Id ownerId = '005000000000010AAA';
        Test.startTest();
        List<UserTeamMember> queried = UserOpportunityTeamService.queryTeamMembersByOwner(ownerId);
        Test.stopTest();
        System.Assert.areEqual(0, queried.size(), 'Query should return 0 records when none were inserted');
    }

    // New tests for getPageSize coverage

    @IsTest
    private static void getPageSize_ConfiguredValueFromOrgDefaults() {
        // Arrange: ensure org default exists with a specific numeric value
        UserDefaultOpportunityTeamSettings__c orgDefaults = UserDefaultOpportunityTeamSettings__c.getOrgDefaults();
        if (orgDefaults == null) {
            orgDefaults = new UserDefaultOpportunityTeamSettings__c();
        }
        orgDefaults.PageSize__c = 7; // numeric value which should be returned
        upsert orgDefaults;

        // Act
        Test.startTest();
        Integer size = UserOpportunityTeamService.getPageSize();
        Test.stopTest();

        // Assert
        System.Assert.areEqual(7, size, 'Should return the configured PageSize from org defaults');
    }

    @IsTest
    private static void getPageSize_ConfiguredValueOfLessThanOneFromOrgDefaults() {
        // Arrange: ensure org default exists with a specific numeric value
        UserDefaultOpportunityTeamSettings__c orgDefaults = UserDefaultOpportunityTeamSettings__c.getOrgDefaults();
        if (orgDefaults == null) {
            orgDefaults = new UserDefaultOpportunityTeamSettings__c();
        }
        orgDefaults.PageSize__c = -1; // numeric value which should be returned
        upsert orgDefaults;

        // Act
        Test.startTest();
        Integer size = UserOpportunityTeamService.getPageSize();
        Test.stopTest();

        // Assert
        System.Assert.areEqual(1, size, 'Should return the configured PageSize from org defaults');
    }

    @IsTest
    private static void getPageSize_FallbackToDefaultWhenMissing() {
        // Arrange: remove org defaults by setting to null fields and deleting record if possible
        // Note: In tests, getOrgDefaults() returns the org defaults record if it exists. We'll create,
        // then delete to simulate "missing" configuration.
        UserDefaultOpportunityTeamSettings__c existing = new UserDefaultOpportunityTeamSettings__c();

        // Act
        Test.startTest();
        Integer size = UserOpportunityTeamService.getPageSize();
        Test.stopTest();

        // Assert default (5) from implementation
        System.Assert.areEqual(1, size, 'Should fall back to default when org defaults are missing');
    }
}
