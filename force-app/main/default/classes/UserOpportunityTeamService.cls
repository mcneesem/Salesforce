public with sharing class UserOpportunityTeamService {
    // test w/ UserOpportunityTeamServiceTest (95%)
    // Major Test covering class: UserOpportunityTeamServiceTest

    // DTO
    public class TeamMember {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public Id ownerId { get; set; }
        @AuraEnabled public Id userId { get; set; }
        @AuraEnabled public String userName { get; set; }
        @AuraEnabled public string teamMemberRole { get; set; }
        @AuraEnabled public string opportunityAccessLevel { get; set; }
    }

    // public API (Aura Enabled) delegates to private methods
    @AuraEnabled(cacheable=true)
    public static List<TeamMember> getTeamMembersByOwner(Id ownerId) {
        return UserOpportunityTeamService.doGetTeamMembersByOwner(ownerId);
    }

    // Instance method to encapsulate orchestration
    @TestVisible
    private static List<TeamMember> doGetTeamMembersByOwner(Id ownerId) {
        // single exit point
        List<TeamMember> output = new List<TeamMember>();
        List<UserTeamMember> teamMembers = new List<UserTeamMember>();

        // guard checks without early returns
        Boolean hasOwner = (ownerId != null);
        Boolean hasAccess = Schema.SObjectType.UserTeamMember.isAccessible();
        Boolean hasPermission = CustomPermissionController.checkUserPermission(
            'Default_Opportunity_Team_View',
            UserInfo.getUserId()
        );

        if (hasOwner && hasAccess && hasPermission) {
            teamMembers = UserOpportunityTeamService.queryTeamMembersByOwner(ownerId);
        }
        output = UserOpportunityTeamService.mapTeamMmebers(teamMembers);

        return output;
    }

    // Query method (separated from mapping)
    @TestVisible
    private static List<UserTeamMember> queryTeamMembersByOwner(Id ownerId) {
        // single exit point
        List<UserTeamMember> result = new List<UserTeamMember>();

        // guard checks without early returns
        if (ownerId != null) {
            result = [
                SELECT Id,
                       UserId,
                       OwnerId,
                       OpportunityAccessLevel,
                       TeamMemberRole,
                       User.Name
                FROM UserTeamMember
                WHERE OwnerId = :ownerId
            ];
        }

        return result;
    }

    // Mapping method (separated from query)
    @TestVisible
    private static List<TeamMember> mapTeamMmebers(List<UserTeamMember> members) {
        // single exit point
        List<TeamMember> outputList = new List<TeamMember>();
        if (members != null && !members.isEmpty()) {
            for (UserTeamMember member : members) {
                TeamMember tm = new TeamMember();
                tm.id = member.Id;
                tm.ownerId = member.OwnerId;
                tm.userId = member.UserId;
                tm.userName = (member.User != null) ? member.User.Name : '';
                tm.teamMemberRole = member.TeamMemberRole;
                tm.opportunityAccessLevel = member.OpportunityAccessLevel;
                outputList.add(tm);
            }
        }
        return outputList;
    }

    // Expose page size from Hierarchy custom setting.
    @AuraEnabled(cacheable=true)
    public static Integer getPageSize() {
        // Default if not configured
        Integer defaultSize = 1;

        try {
            UserDefaultOpportunityTeamSettings__c customSetting = UserDefaultOpportunityTeamSettings__c.getOrgDefaults();
            if (customSetting != null && customSetting.PageSize__c != null) {
                // PageSize__c can be numeric or text; coerce to Integer safely
                defaultSize = customSetting.PageSize__c.intValue();
                // Guard against negative or zero values. Page Size must be greater than zero...
                if (defaultSize < 1) {
                    defaultSize = 1;
                }
            }
        } catch (Exception e) {
            System.debug('UserOpportunityTeamService.getPageSize: ' + e.getMessage());
        }

        return defaultSize;
    }
}
