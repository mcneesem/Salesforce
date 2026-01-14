public with sharing class UserQueueMembershipService {
    // test w/ UserQueueMembershipServiceTest (100%)

    //
    // Service: fetch a user's Queue memberships and return lightweight rows for LWC consumption.
    //

    // DTO exposed to UI for each queue membership row.
    // id = GroupMember.Id, groupId = Group.Id, queueDeveloperName = Group.DeveloperName, queueName = Group.Name
    // reasonForMembership is currently set to Queue Member as a placeholder.
    public class Member {
        @AuraEnabled public Id id; // GroupMember Id
        @AuraEnabled public Id groupId;
        @AuraEnabled public String groupDeveloperName;
        @AuraEnabled public String groupName;
        @AuraEnabled public String reasonForMembership;
    }

    // Returns queue membership rows for the provided User Id.
    // Inputs: recordId = User Id. If null, returns an empty list.
    // Output: List<QueueMembershipRow> (never null). Cacheable for LWC.
    @AuraEnabled(cacheable=true)
    public static List<Member> getQueueMembershipsByUser( Id recordId ) {
        List<Member> records = new List<Member>();
        Boolean hasAccess = schema.SObjectType.GroupMember.isAccessible();
        Boolean hasPermission = CustomPermissionController.checkUserPermission(
            'Queue_Membership_View' ,
            UserInfo.getUserId()
        );
        if ( ( recordId != null ) && hasAccess && hasPermission ) {
            records = UserQueueMembershipService.buildMembers(
                UserQueueMembershipService.selectGroupMemberships(
                    recordId ,
                    'Queue'
                )
            );
        }
        return records;
    }

    // Helper: SOQL to retrieve Queue GroupMember rows for the given User.
    // Inputs: recordId = User Id. If null, returns empty list.
    // Output: List<GroupMember> of queue memberships (never null).
    public static List<GroupMember> selectGroupMemberships( Id recordId , String groupType ) {
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

    // Mapper: converts queried GroupMember rows into QueueMembershipRow DTOs for UI.
    // Filters: Group.Type == 'Queue', UserOrGroupId != null, GroupId != null,
    //          and at least one of Group.Name or Group.DeveloperName is not blank.
    // Input: records from SOQL (may be null/empty).
    // Output: List<QueueMembershipRow> (never null).
    @TestVisible
    public static List<Member> buildMembers( List<GroupMember> records ) {
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
                    if ( record.Group.Type == 'Queue' ) {
                        wrapper.reasonForMembership = 'Queue Member';
                    } else if ( record.Group.Type == 'Regular' ) {
                        wrapper.reasonForMembership = 'Group Member';
                    }
                    response.add( wrapper );
                }
            }
        }
        return response;
    }

}
//