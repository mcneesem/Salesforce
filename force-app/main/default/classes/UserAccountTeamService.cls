public with sharing class UserAccountTeamService {
    // test w/ UserAccountTeamServiceTest (100%)
    // Major Test covering class: UserAccountTeamServiceTest

    // DTO
    public class TeamMember {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public Id ownerId { get; set; }
        @AuraEnabled public Id userId { get; set; }
        @AuraEnabled public String userName { get; set; }
        @AuraEnabled public String teamMemberRole { get; set; }
        @AuraEnabled public String accountAccessLevel { get; set; }
        @AuraEnabled public String opportunityAccessLevel { get; set; }
        @AuraEnabled public String caseAccessLevel { get; set; }
        @AuraEnabled public String contactAccessLevel { get; set; }
    }

    // Public API (AuraEnabled) delegates to singleton for easy testability and separation of concerns
    @AuraEnabled(cacheable=true)
    public static List<TeamMember> getTeamMembersByOwner(Id ownerId) {
        return UserAccountTeamService.doGetTeamMembersByOwner(ownerId);
    }

    // Instance method to encapsulate orchestration
    private static List<TeamMember> doGetTeamMembersByOwner(Id ownerId) {
        // single exit point
        List<TeamMember> output = new List<TeamMember>();
        List<UserAccountTeamMember> teamMembers = new List<UserAccountTeamMember>();

        // guard checks without early returns
        Boolean hasOwner = (ownerId != null);
        Boolean hasAccess = Schema.sObjectType.UserAccountTeamMember.isAccessible();
        Boolean hasPermission = CustomPermissionController.checkUserPermission(
            'Default_Account_Team_View' , 
            UserInfo.getUserId()
            );

        if (hasOwner && hasAccess && hasPermission) {
            teamMembers = UserAccountTeamService.queryTeamMembersByOwner(ownerId);
        }

        output = UserAccountTeamService.mapTeamMembers(teamMembers);
        return output;
    }

    // Query method (separated from mapping)
    @TestVisible
    private static List<UserAccountTeamMember> queryTeamMembersByOwner(Id ownerId) {
        // single exit point
        List<UserAccountTeamMember> result = new List<UserAccountTeamMember>();
        if (ownerId != null) {
            result = [
                SELECT Id,
                       OwnerId,
                       TeamMemberRole,
                       AccountAccessLevel,
                       OpportunityAccessLevel,
                       CaseAccessLevel,
                       ContactAccessLevel,
                       UserId,
                       User.Name
                FROM UserAccountTeamMember
                WHERE OwnerId = :ownerId
            ];
        }
        return result;
    }

    // Mapping method (separated from query)
    @TestVisible
    private static List<TeamMember> mapTeamMembers(List<UserAccountTeamMember> members) {
        // single exit point
        List<TeamMember> outList = new List<TeamMember>();
        if (members != null && !members?.isEmpty()) {
            for (UserAccountTeamMember member : members) {
                TeamMember dto = new TeamMember();
                dto.id = member.Id;
                dto.ownerId = member.OwnerId;
                dto.userId = member.UserId;
                dto.userName = (member.User != null ? member.User.Name : '');
                dto.teamMemberRole = member.TeamMemberRole;
                dto.accountAccessLevel = member.AccountAccessLevel;
                dto.opportunityAccessLevel = member.OpportunityAccessLevel;
                dto.caseAccessLevel = member.CaseAccessLevel;
                dto.contactAccessLevel = member.ContactAccessLevel;
                outList.add(dto);
            }
        }
        return outList;
    }

    // Expose page size from Hierarchy Custom Setting
    @AuraEnabled(cacheable=true)
    public static Integer getPageSize() {
        // Default if not configured
        Integer defaultSize = 1;
        try {
            UserDefaultAccountTeamSettings__c customSetting = UserDefaultAccountTeamSettings__c.getOrgDefaults();
            if (customSetting != null && customSetting?.PageSize__c != null) {
                // PageSize__c can be numeric or text; coerce to Integer safely
                defaultSize = customSetting.PageSize__c.intValue();
                // Guard against invalid values. Page size must be greater than zero...
                if (defaultSize < 1) {
                    defaultSize = 1;
                }
            }
        } catch (Exception e) {
            // Swallow and fall back to default
        }
        return defaultSize;
    }
}