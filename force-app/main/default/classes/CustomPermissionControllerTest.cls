@isTest(isParallel=True) public class CustomPermissionControllerTest {
    private static final String CLASS_NAME = ' ~ CustomPermissionControllerTest';
    private static final Boolean ENABLE_testCustomPermissionController = True;
    private static final Boolean ENABLE_testGetMissingPermissionError = True;

    @isTest static void testPermissionsDirectoryController() {
        String METHOD_NAME = 'testPermissionsDirectoryController';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testCustomPermissionController ) {
            Test.startTest();
            //
            String customPermissionName = 'View_Permissions_Directory';
            Map<Id,User> permittedUsersMap = CustomPermissionController.getPermittedUsersMap( customPermissionName );
            Assert.isTrue( permittedUsersMap != null );
            //
            // check an permitted user that is the current user...
            String currentUserId = UserInfo.getUserId();
            Boolean isUserPermitted = CustomPermissionController.checkUserPermission( customPermissionName , currentUserId );
            Assert.isTrue( isUserPermitted == permittedUsersMap.keySet().contains( currentUserId ) );
            //
            // check an permitted user that is not the current user...
            if ( permittedUsersMap.keySet().size() > 0 ) {
                List<User> permittedUsers = [
                    SELECT Id
                    FROM User
                    WHERE (
                        ( Id IN :permittedUsersMap.keySet() )
                        AND ( Id != :currentUserId )
                    )
                    LIMIT 1
                ];
                if ( permittedUsers.size() > 0 ) {
                    User permittedUser = permittedUsers[0];
                    isUserPermitted = CustomPermissionController.checkUserPermission( customPermissionName , permittedUser.Id );
                    Assert.isTrue( isUserPermitted == permittedUsersMap.keySet().contains( permittedUser.Id ) );
                }
            }
            //
            // check an unpermitted user that is not the current user...
            List<User> unpermittedUsers = [
                SELECT Id
                FROM User
                WHERE (
                    ( NOT Id IN :permittedUsersMap.keySet() )
                    AND ( Id != :currentUserId )
                )
                LIMIT 1
            ];
            if ( unpermittedUsers.size() > 0 ) {
                User unpermittedUser = unpermittedUsers[0];
                isUserPermitted = CustomPermissionController.checkUserPermission( customPermissionName , unpermittedUser.Id );
                Assert.isTrue( isUserPermitted == permittedUsersMap.keySet().contains( unpermittedUser.Id ) );
            }
            //
            Test.stopTest();
        }
    }

    @isTest private static void testGetMissingPermissionError() {
        String METHOD_NAME = 'testGetMissingPermissionError';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testGetMissingPermissionError ) {
            Test.startTest();
            String customPermissionName = 'View_Permissions_Directory';
            CustomPermission permission = CustomPermissionController.getCustomPermission( customPermissionName );
            Assert.isTrue( permission != null );
            Assert.isTrue( String.isNotBlank( permission.MasterLabel ) );
            String missingPermissionError = CustomPermissionController.getMissingPermissionError( customPermissionName );
            Assert.isTrue( String.isNotBlank( missingPermissionError ) );
            Assert.isTrue( missingPermissionError.startsWith( 'Missing Permission' ) );
            Assert.isTrue( missingPermissionError == 'Missing Permission: ' + permission.MasterLabel );
            Test.stopTest();
        }
    }
}
//