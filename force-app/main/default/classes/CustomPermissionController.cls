public with sharing class CustomPermissionController {
    // test w/ CustomPermissionControllerTest (96%)
    private static final String CLASS_NAME = ' ~ CustomPermissionController';
    
    // check if a given User has been granted a named Custom Permission..
    // ~ when userId is the current User, respect FeatureManagement without impacting SOQL limits...
    // ~ otherwise, check the PermittedUsersMap for a matching key-value pair...
    public static Boolean checkUserPermission( String customPermissionName , String userId ) {
        String METHOD_NAME = 'checkUserPermission';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        Boolean isUserPermitted = False;
        if ( userId == UserInfo.getUserId() ) {
            // 0 SOQL queries required...
            isUserPermitted = FeatureManagement.checkPermission( customPermissionName );
        } else {
            if ( String.isNotBlank( userId )
                && ( userId InstanceOf Id )
                && ( Id.valueOf( userId ).getSObjectType() == User.getSObjectType() )
               )
            {
                // 2 SOQL queries required...
                Map<Id,User> permittedUsersMap = CustomPermissionController.getPermittedUsersMap( customPermissionName );
                if ( ( permittedUsersMap != null )
                    && ( permittedUsersMap.keySet().contains( userId ) )
                    && ( permittedUsersMap.get( userId ) != null )
                   )
                {
                    isUserPermitted = True;
                }
            }
        }
        System.debug( DEBUG_PREFIX + ' ~ isUserPermitted( ' + customPermissionName + ' , ' + userId + ' )=' + isUserPermitted );
        return isUserPermitted;
    }

    // builds a Map of all active Users granted a Custom Permission...
    // ~ includes all grants, both via Profile and Permission Set...
    // ~ Map( User.Id ==> User )
    public static Map<Id,User> getPermittedUsersMap( String customPermissionName ) {
        String METHOD_NAME = 'getPermittedUsersMap';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        Map<Id,User> permittedUsersMap = new Map<Id,User>();
        if ( String.isNotBlank( customPermissionName ) ) {
            // grab the relationships (SetupEntityAccess) between the CustomPermission:PermissionSet and the CustomPermission:Profile
            // ~ SetupEntityAccess.Parent is always a PermissionSet...
            // ~ a PermissionSet sometimes has a Profile...
            // SOQL_LIMIT++
            List<SetupEntityAccess> setupEntityAccessList = [
                SELECT
                ParentId , // PermissionSet relationships only have Parent values...
                Parent.ProfileId // Profile relationships also have Parent.ProfileId values...
                FROM SetupEntityAccess 
                WHERE SetupEntityId IN (
                    SELECT Id 
                    FROM CustomPermission 
                    WHERE ( DeveloperName = :customPermissionName )
                )
            ];
            // determine the complete Set of PermissionSets that have access granted...
            // ~ some PermissionSets are really Profile PermissionSets...
            Set<Id> permissionSetIds = new Set<Id>();
            for ( SetupEntityAccess setupEntityAccess : setupEntityAccessList ) {
                permissionSetIds.add( setupEntityAccess.ParentId );
            }
            // the complete Set of User with access granted via PermissionSetAssignment...
            // ~ this includes grants via Profile PermissionSetAssignments...
            // SOQL_LIMIT++
            List<User> permittedUsers = [
                SELECT Id , UserName
                FROM User
                WHERE (
                    ( IsActive = True )
                    AND (
                        Id IN (
                            SELECT AssigneeId
                            FROM PermissionSetAssignment
                            WHERE ( PermissionSetId IN :permissionSetIds )
                        )
                    )
                )
            ];
            // convert List into the complete Map of permitted User's...
            permittedUsersMap = new Map<Id,User>( permittedUsers );
        }
        System.debug( DEBUG_PREFIX + ' ~ permittedUsersMap( ' + customPermissionName + ' )=' + permittedUsersMap );
        return permittedUsersMap;
    }

    // build error message for missing custom permission...
    public static String getMissingPermissionError( String developerName ) {
        String missingPermissionError = 'Missing Permission';
        CustomPermission record = CustomPermissionController.getCustomPermission( developerName );
        if ( ( record != null )
            && String.isNotBlank( record.MasterLabel )
           )
        {
            missingPermissionError = missingPermissionError + ': ' + record.MasterLabel;
        }
        return missingPermissionError;
    }

    public static CustomPermission getCustomPermission( String developerName ) {
        String METHOD_NAME = 'getCustomPermission';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        CustomPermission record = null;
        if ( String.isNotBlank( developerName )
            && ( CustomPermissionController.customPermissionsMap != null )
           )
        {
            if ( CustomPermissionController.customPermissionsMap.containsKey( developerName ) ) {
                record = CustomPermissionController.customPermissionsMap.get( developerName );
            } else {
                List<CustomPermission> records = [
                    SELECT Id , DeveloperName , MasterLabel
                    FROM CustomPermission
                    WHERE ( DeveloperName = :developerName )
                    LIMIT 1
                ];
                if ( ( records != null )
                    && ( records.size() > 0 )
                   )
                {
                    record = records[0];
                    CustomPermissionController.customPermissionsMap.put( developerName , record );
                }
            }
        }
        System.debug( DEBUG_PREFIX + ' ~ CustomPermission( ' + developerName + ' )=' + record );
        return record;
    }
    
    private static Map<String,CustomPermission> customPermissionsMap {
        private get {
            if ( customPermissionsMap == null ) {
                customPermissionsMap = new Map<String,CustomPermission>();
            }
            return customPermissionsMap;
        }
        private set;
    }

}
//