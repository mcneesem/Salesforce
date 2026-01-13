public with sharing class UserPublicGroupMembershipService {
    // test w/ UserPublicGroupMembershipServiceTest (97%)

    //
    // Service: fetch a user's Group memberships and return lightweight rows for LWC consumption.
    //

    // DTO exposed to UI for each Group membership row.
    // id = GroupMember.Id, groupId = Group.Id, queueDeveloperName = Group.DeveloperName, groupName = Group.Name
    // reasonForMembership is currently set to Group Member as a placeholder.
    public class Member {
        @AuraEnabled public Id id; // GroupMember Id
        @AuraEnabled public Id groupId;
        @AuraEnabled public String groupDeveloperName;
        @AuraEnabled public String groupName;
        @AuraEnabled public String reasonForMembership;
    }

    // Helper: SOQL to retrieve GroupMember rows for the given User.
    // Inputs: recordId = User Id. If null, returns empty list.
    // Output: List<GroupMember> of Group memberships (never null).
    @TestVisible
    private static List<GroupMember> selectGroupMemberships( Id recordId , String groupType ) {
        List<GroupMember> records = new List<GroupMember>();
        if ( recordId != null ) {
            records = [
                SELECT
                    Id ,
                    GroupId ,
                    Group.DeveloperName ,
                    Group.Name ,
                    Group.Type ,
                    UserOrGroupId ,
                    UserOrGroup.ManagerId ,
                    SystemModstamp
                FROM GroupMember
                WHERE (
                    ( Group.Type = :groupType )
                    AND ( UserOrGroupId = :recordId )
                )
                ORDER BY Group.Name
            ];
        }
        return records;
    }

    // Mapper: converts queried GroupMember rows into GroupMembershipRow DTOs for UI.
    // Filters: Group.Type == 'Regular', UserOrGroupId != null, GroupId != null,
    //          and at least one of Group.Name or Group.DeveloperName is not blank.
    // Input: records from SOQL (may be null/empty).
    // Output: List<Member> (never null).
    @TestVisible
    private static List<Member> buildMembers( List<GroupMember> records ) {
        List<Member> response = new List<Member>();
        if ( records != null && !records.isEmpty() ) {
            for ( GroupMember record : records ) {
                if ( ( record.GroupId != null )
                    && ( record.Group != null )
                    && ( record.UserOrGroupId != null )
                    && ( String.isNotBlank( record.Group.Name )
                        || String.isNotBlank( record.Group.DeveloperName )
                        )
                    )
                {
                    Member wrapper = new Member();
                    wrapper.id = record.Id;
                    wrapper.groupId = record.GroupId;
                    wrapper.groupDeveloperName = record.Group.DeveloperName;
                    wrapper.groupName = record.Group.Name;
                    if ( record.Group.Type == 'Regular' ) {
                        wrapper.reasonForMembership = 'Public Group';
                    }
                    response.add( wrapper );
                }
            }
        }
        return response;
    }

    // Returns public group membership rows for the provided User Id.
    // Inputs: recordId = User Id. If null, returns an empty list.
    // Output: List<Member> (never null). Cacheable for LWC.
    @AuraEnabled(cacheable=true)
    public static List<Member> getPublicGroupMembershipsByUser( Id recordId ) {
        List<Member> retrunPublicGroupMemberships = new List<Member>();
        
        Boolean hasAccess = schema.SObjectType.GroupMember.isAccessible();
        Boolean hasPermission = CustomPermissionController.checkUserPermission(
            'Public_Group_Membership_View' ,
            UserInfo.getUserId()
        );
        
        if ( recordId != null && hasAccess && hasPermission ) {
            List<GroupMember> groupMembers = selectGroupMemberships( recordId, 'Regular' );
            if ( groupMembers != null && !groupMembers.isEmpty() ) {
                retrunPublicGroupMemberships = buildMembers( groupMembers );     
            }
        }
        
        return retrunPublicGroupMemberships;
    }
}