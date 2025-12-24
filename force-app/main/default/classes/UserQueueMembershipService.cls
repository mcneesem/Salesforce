// Service: fetch a user's Queue memberships and return lightweight rows for LWC consumption.
public with sharing class UserQueueMembershipService {
    // test w/ UserGroupMembershipServiceTest (100%)
    // Major Test covering class: UserGroupMembershipServiceTest
    
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
        List<Member> retrunQueueMemberships = new List<Member>();
        
        Boolean hasAccess = schema.SObjectType.GroupMember.isAccessible();
        Boolean hasPermission = CustomPermissionController.checkUserPermission(
            'Queue_Membership_View' ,
            UserInfo.getUserId()
        );
        
        if ( recordId != null && hasAccess && hasPermission ) {
            List<GroupMember> groupMembers = selectGroupMemberships( recordId, 'Queue' );
            if ( groupMembers != null && !groupMembers.isEmpty() ) {
                retrunQueueMemberships = buildMembers( groupMembers );     
            }
        }
        
        return retrunQueueMemberships;
    }
    
    // Helper: SOQL to retrieve Queue GroupMember rows for the given User.
    // Inputs: recordId = User Id. If null, returns empty list.
    // Output: List<GroupMember> of queue memberships (never null).
    @TestVisible
    private static List<GroupMember> selectGroupMemberships( Id recordId , String groupType ) {
        List<GroupMember> groupMembers = new List<GroupMember>();
        
        if( recordId != null ) {
            
            groupMembers =  [
                SELECT Id,
                GroupId,
                Group.DeveloperName,
                Group.Name,
                Group.Type,
                UserOrGroupId,
                UserOrGroup.ManagerId,
                SystemModstamp
                FROM GroupMember
                WHERE Group.Type = :groupType
                AND UserOrGroupId = :recordId
                ORDER BY Group.Name
            ];
        }
        
        return groupMembers;
    }
    
    // Mapper: converts queried GroupMember rows into QueueMembershipRow DTOs for UI.
    // Filters: Group.Type == 'Queue', UserOrGroupId != null, GroupId != null,
    //          and at least one of Group.Name or Group.DeveloperName is not blank.
    // Input: groupMembers from SOQL (may be null/empty).
    // Output: List<QueueMembershipRow> (never null).
    @TestVisible
    private static List<Member> buildMembers( List<GroupMember> groupMembers ) {
        List<Member> returnQueueMembers = new List<Member>();
        if ( groupMembers != null && !groupMembers.isEmpty() ) {
            
            for ( GroupMember groupMemberRec : groupMembers ) {
                if( (groupMemberRec.Group.Type == 'Queue') && (groupMemberRec.UserOrGroupId != null) && (groupMemberRec.GroupId != null) && 
                   ( ( string.isNotBlank( groupMemberRec.Group.Name )) || (string.isNotBlank( groupMemberRec.Group.DeveloperName )) 
                   ) 
                  ) {
                      Member queueMembrRec = new Member();
                      queueMembrRec.id = groupMemberRec.Id;
                      queueMembrRec.groupId = groupMemberRec.GroupId;
                      queueMembrRec.groupDeveloperName = groupMemberRec.Group.DeveloperName;
                      queueMembrRec.groupName = groupMemberRec.Group.Name;
                      queueMembrRec.reasonForMembership = 'Queue Member'; // leave blank
                      returnQueueMembers.add( queueMembrRec );
                  }
            }
        }
        return returnQueueMembers;
    }
}