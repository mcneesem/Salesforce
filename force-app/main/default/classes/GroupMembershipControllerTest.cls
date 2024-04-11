@isTest private class GroupMembershipControllerTest {
    private static final String CLASS_NAME = ' ~ GroupMembershipControllerTest';
    private static final Boolean ENABLE_testGroupMembershipController = True;

    private static User getManageQueueMembershipUser() {
        List<SetupEntityAccess> setupEntities = [
            SELECT ParentId
            FROM SetupEntityAccess
            WHERE (
                SetupEntityId IN (
                    SELECT Id
                    FROM CustomPermission
                    WHERE DeveloperName = 'Manage_Queue_Membership'
                )
            )
        ];
        Set<Id> permisisonSetIds = new Set<Id>();
        for ( SetupEntityAccess setupEntity : setupEntities ) {
            permisisonSetIds.add( setupEntity.ParentId );
        }
        // find users with "Manage Queue Membership" Custom Permission...
        List<User> manageQueueMembershipUsers = [
            SELECT Id , Name
            FROM User
            WHERE (
                ( IsActive = True )
                AND ( Id IN ( SELECT AssigneeId FROM PermissionSetAssignment WHERE ( PermissionSetId IN :permisisonSetIds ) ) )
            )
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
        Assert.isTrue( manageQueueMembershipUsers != null );
        Assert.isTrue( manageQueueMembershipUsers.size() > 0 );
        return manageQueueMembershipUsers[0];
    }

    @isTest private static void testGroupMembershipController() {
        String METHOD_NAME = ' ~ testGroupMembershipController';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testGroupMembershipController ) {
            //
            List<Group> queues = [
                SELECT Id
                FROM Group
                WHERE ( Type = 'Queue' )
                ORDER BY Name ASC 
                LIMIT 2
            ];
            String groupIdsLong = '';
            for ( Group queue : queues ) {
                groupIdsLong += String.valueOf( queue.Id ) + ',';
            }
            groupIdsLong = groupIdsLong.removeEnd( ',' );
            //
            User testUser = getManageQueueMembershipUser();
            //
            Test.startTest();
            Boolean eventPublished = False;
            System.runAs( testUser ) {
                GroupMembershipEvent__e platformEvent = new GroupMembershipEvent__e();
                platformEvent.UserId__c = testUser.Id;
                platformEvent.GroupIdsLong__c = groupIdsLong;
                List<GroupMembershipEvent__e> platformEvents = new List<GroupMembershipEvent__e>();
                platformEvents.add( platformEvent );
                List<Database.SaveResult> publishResults = EventBus.publish( platformEvents );
                for ( Database.SaveResult publishResult : publishResults ) {
                    if ( publishResult.isSuccess() ) {
                        eventPublished = True;
                    }
                }
            }
            Test.stopTest();
        }
    }

}
//