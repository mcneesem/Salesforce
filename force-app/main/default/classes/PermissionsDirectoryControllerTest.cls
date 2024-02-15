@isTest(isParallel=True) public class PermissionsDirectoryControllerTest {
    private static final String CLASS_NAME = ' ~ PermissionsDirectoryControllerTest';
    private static final Boolean ENABLE_testPermissionsDirectoryControllerUserPermissions = True;
    private static final Boolean ENABLE_testPermissionsDirectoryControllerObjectPermissions = True;
    private static final Boolean ENABLE_testPermissionsDirectoryControllerCustomPermissions = True;

    private static User getPermissionsDirectoryUser() {
        List<SetupEntityAccess> setupEntities = [
            SELECT ParentId
            FROM SetupEntityAccess
            WHERE (
                SetupEntityId IN (
                    SELECT Id
                    FROM CustomPermission
                    WHERE DeveloperName = 'View_Permissions_Directory'
                )
            )
        ];
        Set<Id> permisisonSetIds = new Set<Id>();
        for ( SetupEntityAccess setupEntity : setupEntities ) {
            permisisonSetIds.add( setupEntity.ParentId );
        }
        // find users with "View Permissions Directory" Custom Permission...
        List<User> permissionsDirectoryUsers = [
            SELECT Id , Name
            FROM User
            WHERE (
                ( IsActive = True )
                AND ( Id IN ( SELECT AssigneeId FROM PermissionSetAssignment WHERE ( PermissionSetId IN :permisisonSetIds ) ) )
            )
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
        Assert.isTrue( permissionsDirectoryUsers != null );
        Assert.isTrue( permissionsDirectoryUsers.size() > 0 );
        return permissionsDirectoryUsers[0];
    }

    @isTest private static void testPermissionsDirectoryControllerUserPermissions() {
        String METHOD_NAME = 'testPermissionsDirectoryControllerUserPermissions';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testPermissionsDirectoryControllerUserPermissions ) {
            testPermissionsDirectoryControllerAsUser(
                getPermissionsDirectoryUser() ,
                'UserPermissions'
            );
        }
    }

    @isTest private static void testPermissionsDirectoryControllerObjectPermissions() {
        String METHOD_NAME = 'testPermissionsDirectoryControllerObjectPermissions';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testPermissionsDirectoryControllerObjectPermissions ) {
            testPermissionsDirectoryControllerAsUser(
                getPermissionsDirectoryUser() ,
                'ObjectPermissions'
            );
        }
    }

    @isTest private static void testPermissionsDirectoryControllerCustomPermissions() {
        String METHOD_NAME = 'testPermissionsDirectoryControllerCustomPermissions';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testPermissionsDirectoryControllerCustomPermissions ) {
            testPermissionsDirectoryControllerAsUser(
                getPermissionsDirectoryUser() ,
                'CustomPermissions'
            );
        }
    }

    private static void testPermissionsDirectoryControllerAsUser( User testUser , String permissionType ) {
        String METHOD_NAME = 'testPermissionsDirectoryControllerAsUser';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ testUser=' + testUser );
        if ( testUser != null ) {
            Test.startTest();
            Boolean isAccessible = False;
            List<PermissionsDirectoryController.AuraPermission> response = null;
            System.runAs( testUser ) {
                isAccessible = PermissionsDirectoryController.isAccessible();
                response = (List<PermissionsDirectoryController.AuraPermission>)PermissionsDirectoryController.getPermissions(
                    UserInfo.getUserId() ,
                    permissionType
                );
            }
            Assert.isTrue( isAccessible );
            Assert.isTrue( response != null );
            Test.stopTest();
        }
    }

}
//