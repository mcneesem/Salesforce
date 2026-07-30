public with sharing class CustomPermissionController {
    // test w/ CustomPermissionControllerTest (100%)
    private static final String CLASS_NAME = ' ~ CustomPermissionController';

    // check if a given User has been granted a named Custom Permission..
    // ~ when userId is the current User, respect FeatureManagement without impacting SOQL limits...
    // ~ otherwise, check the PermittedUsersMap for a matching key-value pair...

    @InvocableMethod(label='Check User Permission' description='Check if a given User has been granted a named Custom Permission')
    public static List<UserPermResponse> checkUserPermission( List<UserPermRequest> requestList ) {
        List<UserPermResponse> responseList = new List<UserPermResponse>();
        for ( UserPermRequest request : requestList ) {
            UserPermResponse localResponse = new UserPermResponse();
            localResponse.hasPermission = false;
            if ( String.isNotBlank( request.customPermissionName )
                && String.isNotBlank( request.userId )
                )
            {
                localResponse.hasPermission = CustomPermissionController.checkUserPermission(
                    request.customPermissionName ,
                    request.userId
                );
            }
            responseList.add( localResponse );
        }
        return responseList;
    }

    public class UserPermRequest {
        @InvocableVariable(label='Permission Name' description='API Name of Custom Permission' required=true)
        public String customPermissionName;
        @InvocableVariable(label='User Id' description='Record Id of User to be checked' required=true)
        public String userId;
    }

    public class UserPermResponse {
        @InvocableVariable(label='hasPermission' description='User has named Permission' required=true)
        public Boolean hasPermission;
    }

    public static Boolean checkUserPermission( String customPermissionName , String userId ) {
        String methodName = 'checkUserPermission';
        String debugPrefix = CLASS_NAME + '.' + methodName;
        Boolean isUserPermitted = false;
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
                    isUserPermitted = true;
                }
            }
        }
        System.debug( debugPrefix + ' ~ isUserPermitted( ' + customPermissionName + ' , ' + userId + ' )=' + isUserPermitted );
        return isUserPermitted;
    }

    // builds a Map of all active Users granted a Custom Permission...
    // ~ includes all grants, both via Profile and Permission Set...
    // ~ Map( User.Id ==> User )
    public static Map<Id,User> getPermittedUsersMap( String customPermissionName ) {
        String methodName = 'getPermittedUsersMap';
        String debugPrefix = CLASS_NAME + '.' + methodName;
        Map<Id,User> permittedUsersMap = new Map<Id,User>();
        if ( String.isNotBlank( customPermissionName ) ) {
            if ( ( CustomPermissionController.customPermissionsPermittedUsersMap != null )
                && CustomPermissionController.customPermissionsPermittedUsersMap.containsKey( customPermissionName )
                )
            {
                // used cached response to prevent System.LimitException: Too many SOQL queries: 101
                permittedUsersMap = CustomPermissionController.customPermissionsPermittedUsersMap.get( customPermissionName );
            } else {
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
                        ( IsActive = true )
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
                // cache the response to prevent recalculation...
                CustomPermissionController.customPermissionsPermittedUsersMap.put( customPermissionName , permittedUsersMap );
            }
        }
        System.debug( debugPrefix + ' ~ permittedUsersMap( ' + customPermissionName + ' )=' + permittedUsersMap );
        return permittedUsersMap;
    }

    // map from CustomPermission.Name to map from User.Id to permitted User...
    // ~ Map( CustomPermission.Name ==> Map( User.Id ==> User ) )
    private static Map<String,Map<Id,User>> customPermissionsPermittedUsersMap {
        private get {
            if ( customPermissionsPermittedUsersMap == null ) {
                customPermissionsPermittedUsersMap = new Map<String,Map<Id,User>>();
            }
            return customPermissionsPermittedUsersMap;
        }
        private set;
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
        String methodName = 'getCustomPermission';
        String debugPrefix = CLASS_NAME + '.' + methodName;
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
        System.debug( debugPrefix + ' ~ CustomPermission( ' + developerName + ' )=' + record );
        return record;
    }

    // map from CustomPermission.Name to CustomPermission...
    // ~ Map( CustomPermission.Name ==> CustomPermission )
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