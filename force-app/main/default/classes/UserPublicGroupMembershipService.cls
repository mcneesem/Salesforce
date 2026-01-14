public with sharing class UserPublicGroupMembershipService {
    // test w/ UserPublicGroupMembershipServiceTest (100%)

    //
    // Service: fetch a user's Group memberships and return lightweight rows for LWC consumption.
    //

    // Returns public group membership rows for the provided User Id.
    // Inputs: recordId = User Id. If null, returns an empty list.
    // Output: List<UserQueueMembershipService.Member> (never null). Cacheable for LWC.
    @AuraEnabled(cacheable=true)
    public static List<UserQueueMembershipService.Member> getPublicGroupMembershipsByUser( Id recordId ) {
        List<UserQueueMembershipService.Member> records = new List<UserQueueMembershipService.Member>();
        Boolean hasAccess = schema.SObjectType.GroupMember.isAccessible();
        Boolean hasPermission = CustomPermissionController.checkUserPermission(
            'Public_Group_Membership_View' ,
            UserInfo.getUserId()
        );
        if ( recordId != null && hasAccess && hasPermission ) {
            records = UserQueueMembershipService.buildMembers(
                UserQueueMembershipService.selectGroupMemberships(
                    recordId ,
                    'Regular'
                )
            );
        }
        return records;
    }

}
//