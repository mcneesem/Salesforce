//
// Represents the User Onboarding trigger helper which handles all the permission assignment logic.
//
public with sharing class UserOnboardingTriggerHelper {
    // test w/ UserOnboardingTriggerHelperTest (87%)

    //
    // Iterates throught the list of new User and passes the required attributes to other methods.
    // @param newList List of New User.
    // @return void
    //
    public void beforeInsertUser( List<User> newList ) {
        if ( UserOnboardingToolSettings__c.getInstance( UserInfo.getUserId() ).IsEnabled__c ) {
            List<User> userList = new List<User>();
            if ( ( newList != null ) && !newList.isEmpty() ){
                for ( User usr : newList ) {
                    if ( String.isNotBlank( usr.Business_Title__c )
                        && usr.Run_Permission_Automation__c
                        )
                    {
                        usr.CompanyName = 'Insperity Services, L.P LE';
                        userList.add( usr );
                    }
                }
            }
            Map<String,String> mapOfUserTitleToProfileName = New Map<String,String>();
            Map<String,String> mapOfUserTitleToRoleName = New Map<String,String>();
            List<User_Onboarding_Detail__mdt> details = this.getUserOnboardingDetails( newList );
            if ( ( details != null ) && !details.isEmpty() ){
                for ( User_Onboarding_Detail__mdt detail : details ) {
                    mapOfUserTitleToProfileName.put( detail.Title__c , detail.Profile__c );
                    mapOfUserTitleToRoleName.put( detail.Title__c , detail.Role__c );
                }
            }
            if ( !userList.isEmpty() ) {
                if ( !mapOfUserTitleToProfileName.isEmpty() ) {
                    this.assignProfileToUser( userList , mapOfUserTitleToProfileName );
                }
                if ( !mapOfUserTitleToRoleName.isEmpty() ) {
                    this.assignRoleToUser( userList , mapOfUserTitleToRoleName );
                }
                this.assignExtraAccessToUser( userList , details );
            }
        }
    }

    //
    // Iterates throught the list of new User and passes the required attributes to other methods.
    // @param newMap List of New User.
    // @param oldMap List of the User record before update.
    // @return void
    //
    public void beforeUpdateUser( Map<Id,User> newMap , Map<Id,User> oldMap ) {
        if ( UserOnboardingToolSettings__c.getInstance( UserInfo.getUserId() ).IsEnabled__c ) {
            List<User> userList = new List<User>();
            if ( ( newMap != null ) && !newMap.isEmpty() ){
                for ( User usr: newMap.values() ) {
                    if ( ( oldMap != null ) && ( oldMap.get( usr.Id ) != null ) ){
                        User oldUser = oldMap.get( usr.Id );
                        if ( usr.Run_Permission_Automation__c
                            && String.isNotBlank( usr.Business_Title__c )
                            && usr.IsActive
                            && ( oldUser != null )
                            && (
                                ( oldUser.Run_Permission_Automation__c != usr.Run_Permission_Automation__c )
                                || ( oldUser.Business_Title__c != usr.Business_Title__c )
                                || ( oldUser.IsActive != usr.IsActive )
                                )
                            )
                        {
                            usr.CompanyName = 'Insperity Services, L.P LE';
                            userList.add( usr );
                        }
                    }
                }
            }
            Map<String,String> mapOfUserTitleToProfileName = New Map<String,String>();
            Map<String,String> mapOfUserTitleToRoleName = New Map<String,String>();
            List<User_Onboarding_Detail__mdt> details = this.getUserOnboardingDetails( userList );
            if ( ( details != null ) && !details.isEmpty() ){
                for ( User_Onboarding_Detail__mdt detail : details ) {
                    mapOfUserTitleToProfileName.put( detail.Title__c , detail.Profile__c );
                    mapOfUserTitleToRoleName.put( detail.Title__c , detail.Role__c );
                }
            }
            if ( !userList.isEmpty() ) {
                if ( !mapOfUserTitleToProfileName.isEmpty() ) {
                    this.assignProfileToUser( userList , mapOfUserTitleToProfileName );
                }
                if ( !mapOfUserTitleToRoleName.isEmpty() ) {
                    this.assignRoleToUser( userList , mapOfUserTitleToRoleName );
                }
                this.assignExtraAccessToUser( userList , details );
            }
        }
    }

    //
    // Iterates throught the list of new User and passes the required attributes to other methods.
    // @param newMap List of New User.
    // @param oldMap List of the User record after insert.
    // @return void
    //
    public void afterInsertUser( List<User> newList ) {
        if ( UserOnboardingToolSettings__c.getInstance( UserInfo.getUserId() ).IsEnabled__c ) {
            List<User> userList = new List<User>();
            if ( ( newList != null ) && !newList.isEmpty() ){
                for ( User usr : newList ) {
                    if ( String.isNotBlank( usr.Business_Title__c ) && usr.Run_Permission_Automation__c ) {
                        userList.add( usr );
                    }
                }
            }
            if ( !userList.isEmpty() ) {
                this.assignPermissionSetLicense( userList , null );
                this.assignPermissionSetToUser( userList , null );
                this.assignPermissionSetGroupToUser( userList );
                this.addUserToPublicGroup( userList , null );
            }
        }
    }

    //
    // Iterates throught the list of new User and passes the required attributes to other methods.
    // @param newMap List of New User.
    // @param oldMap List of the User record before update.
    // @return void
    //
    public void afterUpdateUser( Map<Id,User> newMap , Map<Id,User> oldMap ) {
        if ( UserOnboardingToolSettings__c.getInstance( UserInfo.getUserId() ).IsEnabled__c ) {
            List<User> userList = new List<User>();
            Set<Id> userToremovePerm = new Set<Id>();
            if ( ( newMap != null ) && !newMap.isEmpty() ){
                for ( User usr : newMap.values() ) {
                    if ( ( oldMap != null ) && ( oldMap.get( usr.Id ) != null ) ){
                        User oldUser = oldMap.get( usr.Id );
                        if ( usr.Run_Permission_Automation__c
                            && String.isNotBlank( usr.Business_Title__c )
                            && usr.IsActive
                            && ( oldUser != null )
                            && (
                                ( oldUser.Run_Permission_Automation__c != usr.Run_Permission_Automation__c )
                                || ( oldUser.Business_Title__c != usr.Business_Title__c )
                                || ( oldUser.IsActive != usr.IsActive )
                                )
                            )
                        {
                            userList.add( usr );
                            userToremovePerm.add( usr.Id );
                        }
                    }
                }
            }
            if ( !userList.isEmpty() ){
                this.assignPermissionSetLicense( userList , userToremovePerm );
                this.assignPermissionSetToUser( userList , userToremovePerm );
                this.assignPermissionSetGroupToUser( userList );
                this.addUserToPublicGroup( userList , userToremovePerm );
            }
        }
    }

    //
    // @description: Method to assign Profile on User Creation
    // @parameters: List of users
    // @return: void
    //
    private void assignProfileToUser( List<User> userList , Map<String,String> mapOfUserTitleToProfileName ) {
        try {
            Map<Id,Profile> profileMap = null;
            if ( ( mapOfUserTitleToProfileName != null ) && !mapOfUserTitleToProfileName.isEmpty() ){
                profileMap = new Map<Id,Profile>(
                    [
                        SELECT Id , Name
                        FROM Profile
                        WHERE ( Name IN :mapOfUserTitleToProfileName.values() )
                    ]
                );
            }
            Map<String,Id> profileNameToIdMap = new Map<String,Id>();
            if ( ( profileMap != null ) && !profileMap.isEmpty() ){
                for ( Profile record : profileMap.values() ) {
                    profileNameToIdMap.put(
                        record.Name ,
                        record.Id
                    );
                }
            }
            if ( ( userList != null )
                && !userList.isEmpty()
                && ( mapOfUserTitleToProfileName != null )
                && !mapOfUserTitleToProfileName.isEmpty()
                && ( profileNameToIdMap != null )
                && !profileNameToIdMap.isEmpty()
                )
            {
                for ( User eachUser : userList ) {
                    if ( mapOfUserTitleToProfileName.containsKey(eachUser.Business_Title__c)
                        && profileNameToIdMap.containsKey(mapOfUserTitleToProfileName.get(eachUser.Business_Title__c))
                        )
                    {
                        eachUser.ProfileId = profileNameToIdMap.get( mapOfUserTitleToProfileName.get( eachUser.Business_Title__c ) );
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                UserOnboardingTriggerHelper.class.getName() ,
                'assignProfileToUser' ,
                e
            );
        }
    }

    //
    // @description: Method to assign Role on User Creation
    // @parameters: List of users
    // @return: void
    //
    private void assignRoleToUser( List<User> userList , Map<String,String> mapOfUserTitleToRoleName ) {
        try {
            Map<Id,UserRole> userRoleMap = null;
            if ( ( mapOfUserTitleToRoleName != null ) && !mapOfUserTitleToRoleName.isEmpty() ){
                userRoleMap = new Map<Id,UserRole>(
                    [
                        SELECT Id , DeveloperName FROM
                        UserRole
                        WHERE ( DeveloperName IN :mapOfUserTitleToRoleName.values() )
                    ]
                );
            }
            Map<String,Id> roleNameToIdMap = new Map<String,Id>();
            if ( ( userRoleMap != null ) && !userRoleMap.isEmpty() ){
                for ( UserRole record : userRoleMap.values() ) {
                    roleNameToIdMap.put(
                        record.DeveloperName ,
                        record.Id
                    );
                }
            }
            if ( ( userList != null )
                && !userList.isEmpty()
                && ( mapOfUserTitleToRoleName != null )
                && !mapOfUserTitleToRoleName.isEmpty()
                && ( roleNameToIdMap != null )
                && !roleNameToIdMap.isEmpty()
                )
            {
                for ( User eachUser : userList ) {
                    if ( mapOfUserTitleToRoleName.containsKey( eachUser.Business_Title__c )
                        && roleNameToIdMap.containsKey( mapOfUserTitleToRoleName.get( eachUser.Business_Title__c ) )
                        )
                    {
                        eachUser.UserRoleId = roleNameToIdMap.get( mapOfUserTitleToRoleName.get( eachUser.Business_Title__c ) );
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                UserOnboardingTriggerHelper.class.getName() ,
                'assignRoleToUser' ,
                e
            );
        }
    }

    //
    // @description: Method to assign extra permission on User Creation
    // @parameters: List of users
    // @return: void
    //
    private void assignExtraAccessToUser( List<User> userList , List<User_Onboarding_Detail__mdt> details ){
        Map<String,String> mapOfUserTitleToDept = New Map<String,String>();
        Map<String,String> mapOfUserTitleToDiv = New Map<String,String>();
        Map<String,String> mapOfUserTitleToFFAccess = New Map<String,String>();
        Map<String,Boolean> mapOfUserTitleToIsFFUser = New Map<String,Boolean>();
        Map<String,String> mapOfUserTitleToCurated = New Map<String,String>();
        Map<String,String> mapOfUserTitleToRETGroup = New Map<String,String>();
        Map<String,String> mapOfUserTitleToRETDept = New Map<String,String>();
        Map<String,Boolean> mapOfUserTitleToKnowledge = new Map<String,Boolean>();
        Map<String,Boolean> mapOfUserTitleToMarketing = new Map<String,Boolean>();
        Map<String,Boolean> mapOfUserTitleToService = new Map<String,Boolean>();
        Map<String,Boolean> mapOfUserTitleToChat = new Map<String,Boolean>();
        try {
            if ( ( details != null ) && !details.isEmpty() ){
                for ( User_Onboarding_Detail__mdt detail : details ) {
                    mapOfUserTitleToDept.put( detail.Title__c , detail.Department__c );
                    mapOfUserTitleToDiv.put( detail.Title__c , detail.HR_Division__c );
                    mapOfUserTitleToFFAccess.put( detail.Title__c , detail.Financial_Force_User__c );
                    mapOfUserTitleToIsFFUser.put( detail.Title__c , detail.Is_FF_User__c );
                    mapOfUserTitleToCurated.put( detail.Title__c , detail.Curated_Picklist__c );
                    mapOfUserTitleToRETGroup.put( detail.Title__c , detail.RET_Groups__c );
                    mapOfUserTitleToRETDept.put( detail.Title__c , detail.RET_Department_list__c );
                    mapOfUserTitleToKnowledge.put( detail.Title__c , detail.Knowledge_User__c );
                    mapOfUserTitleToMarketing.put( detail.Title__c , detail.Marketing_User__c );
                    mapOfUserTitleToService.put( detail.Title__c , detail.Service_Cloud_User__c );
                    mapOfUserTitleToChat.put( detail.Title__c , detail.Chat_User__c );
                }
            }
            if ( ( userList != null ) && !userList.isEmpty() ) {
                for ( User eachUser : userList ) {
                    if ( String.isNotBlank( eachUser.Business_Title__c ) ) {
                        if ( mapOfUserTitleToKnowledge.containsKey( eachUser.Business_Title__c ) ) {
                            eachUser.UserPermissionsKnowledgeUser = mapOfUserTitleToKnowledge.get( eachUser.Business_Title__c );
                        }
                        if ( mapOfUserTitleToMarketing.containsKey( eachUser.Business_Title__c ) ) {
                            eachUser.UserPermissionsMarketingUser = mapOfUserTitleToMarketing.get( eachUser.Business_Title__c );
                        }
                        if ( mapOfUserTitleToService.containsKey( eachUser.Business_Title__c ) ) {
                            eachUser.UserPermissionsSupportUser = mapOfUserTitleToService.get( eachUser.Business_Title__c );
                        }
                        if ( mapOfUserTitleToChat.containsKey( eachUser.Business_Title__c ) ) {
                            eachUser.UserPermissionsLiveAgentUser = mapOfUserTitleToChat.get( eachUser.Business_Title__c );
                        }
                        if ( mapOfUserTitleToDept.containsKey( eachUser.Business_Title__c ) ) {
                            eachUser.Department = mapOfUserTitleToDept.get( eachUser.Business_Title__c );
                        }     
                        if ( mapOfUserTitleToDiv.containsKey( eachUser.Business_Title__c ) ) {
                            eachUser.HR_Division__c = mapOfUserTitleToDiv.get( eachUser.Business_Title__c );
                        }
                        if ( mapOfUserTitleToFFAccess.containsKey( eachUser.Business_Title__c ) ) {
                            eachUser.NSP_Financial_Force_User__c = mapOfUserTitleToFFAccess.get( eachUser.Business_Title__c );
                        }
                        if ( mapOfUserTitleToIsFFUser.containsKey( eachUser.Business_Title__c ) ) {
                            eachUser.NSP_IS_FF_User__c = mapOfUserTitleToIsFFUser.get( eachUser.Business_Title__c );
                        }
                        if ( mapOfUserTitleToCurated.containsKey( eachUser.Business_Title__c ) ) {
                            eachUser.NSP_Curated_Picklist_Role__c = mapOfUserTitleToCurated.get( eachUser.Business_Title__c );
                        }
                        if ( mapOfUserTitleToRETGroup.containsKey( eachUser.Business_Title__c ) ) {
                            eachUser.NSP_RET_Groups__c = mapOfUserTitleToRETGroup.get( eachUser.Business_Title__c );
                        }
                        if ( mapOfUserTitleToRETDept.containsKey( eachUser.Business_Title__c ) ) {
                            eachUser.NSP_RET_Department_list__c = mapOfUserTitleToRETDept.get( eachUser.Business_Title__c );
                        }
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                UserOnboardingTriggerHelper.class.getName() ,
                'assignExtraAccessToUser' ,
                e
            );
        }
    }

    //
    // @description: Method to assign permission set on User Creation
    // @parameters: List of users
    // @return: void
    //
    private void assignPermissionSetToUser( List<User> newList , Set<Id> assigneeIds ) {
        try {
            if ( UserOnboardingToolSettings__c.getInstance( UserInfo.getUserId() ).IsEnabledRemoval__c
                && ( assigneeIds != null )
                && !assigneeIds.isEmpty()
                )
            {
                this.removePermission( assigneeIds );
            }
            Map<String,List<String>> mapOfUserTitleToPermissionSetNames = new Map<String,List<String>>();
            List<User_Onboarding_Detail__mdt> details = this.getUserOnboardingDetails( newList );
            if ( ( details != null ) && !details.isEmpty() ) {
                for ( User_Onboarding_Detail__mdt detail : details ){
                    if ( String.isNotBlank( detail.Permission_Set_Name__c ) ) {
                        mapOfUserTitleToPermissionSetNames.put(
                            detail.Title__c ,
                            detail.Permission_Set_Name__c.split( ',' )
                        );
                    }
                }
            }
            Set<String> permissionSetNames = new Set<String>();
            if ( !mapOfUserTitleToPermissionSetNames.isEmpty() ) {
                for ( List<String> names : mapOfUserTitleToPermissionSetNames.values() ) {
                    permissionSetNames.addAll( names );
                }
            }
            Map<Id,PermissionSet> permissionSetMap = null;
            if ( !permissionSetNames.isEmpty() ) {
                
                permissionSetMap = new Map<Id,PermissionSet>(
                    [
                        SELECT Id , Name
                        FROM PermissionSet
                        WHERE ( Name IN :permissionSetNames )
                    ]
                );
            }
            Map<String,Id> permissionSetNameToIdMap = new Map<String,Id>();        
            if ( ( permissionSetMap != null ) && !permissionSetMap.isEmpty() ) {
                for ( PermissionSet record : permissionSetMap.values() ) {
                    permissionSetNameToIdMap.put(
                        record.Name ,
                        record.Id
                    );
                }
            }
            Map<Id,String> assigneeToPSMap = new Map<Id,String>();
            if ( ( newList != null ) && !newList.isEmpty() ) {
                for ( User assignee : newList ) {
                    if ( String.isNotBlank( assignee.Business_Title__c )
                        && mapOfUserTitleToPermissionSetNames.containsKey( assignee.Business_Title__c )
                        )
                    {
                        for ( String psNames : mapOfUserTitleToPermissionSetNames.get( assignee.Business_Title__c ) ) {
                            // serializing into Map<Id,String> because Map<Id,List<Id>> is not supported by future method...
                            // ~ Map keyed on UserId containing comma-separated values of PermissionSetIds
                            if ( permissionSetNameToIdMap.containsKey( psNames ) ) {
                                if ( assigneeToPSMap.containsKey( assignee.Id ) ) {
                                    assigneeToPSMap.put(
                                        assignee.Id ,
                                        assigneeToPSMap.get(assignee.Id) + ',' + permissionSetNameToIdMap.get( psNames )
                                    );
                                }else{
                                    assigneeToPSMap.put(
                                        assignee.Id ,
                                        permissionSetNameToIdMap.get( psNames )
                                    );
                                }
                            }
                        }
                    }
                }
            }
            if ( !assigneeToPSMap.isEmpty() ) {
                UserOnboardingTriggerHelper.assignPermission( assigneeToPSMap );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                UserOnboardingTriggerHelper.class.getName() ,
                'assignPermissionSetToUser' ,
                e
            );
        }
    }

    //
    // @description: Method to assign permission set group on User Creation
    // @parameters: List of users
    // @return: void
    //
    private void assignPermissionSetGroupToUser( List<User> newList ) {
        try{
            Map<String,List<String>> mapOfUserTitleToPermissionSetGroupDeveloperNames = new Map<String,List<String>>();
            List<User_Onboarding_Detail__mdt> details = this.getUserOnboardingDetails( newList );
            if ( ( details != null ) && !details.isEmpty() ) {
                for ( User_Onboarding_Detail__mdt detail : details ) {
                    if ( String.isNotBlank( detail.Permission_Set_Group_Name__c ) ) {
                        mapOfUserTitleToPermissionSetGroupDeveloperNames.put(
                            detail.Title__c ,
                            detail.Permission_Set_Group_Name__c.split( ',' )
                        );
                    }
                }
            }
            Set<String> permissionSetGroupDeveloperNames = new Set<String>(); 
            if ( !mapOfUserTitleToPermissionSetGroupDeveloperNames.isEmpty() ) {
                for ( List<String> str : mapOfUserTitleToPermissionSetGroupDeveloperNames.values()){
                    permissionSetGroupDeveloperNames.addAll(str);
                }
            }
            Map<Id,PermissionSet> permissionSetMap = null;
            if ( !permissionSetGroupDeveloperNames.isEmpty() ) {
                permissionSetMap = new Map<Id,PermissionSet>(
                    [
                        SELECT Id , PermissionSetGroup.DeveloperName
                        FROM PermissionSet
                        WHERE (
                            PermissionSetGroupId IN (
                                SELECT Id
                                FROM PermissionSetGroup
                                WHERE ( DeveloperName IN :permissionSetGroupDeveloperNames )
                            )
                        )
                    ]
                );
            }
            Map<String,Id> permissionSetGroupDeveloperNameToIdMap = new Map<String,Id>();
            if ( ( permissionSetMap != null ) && !permissionSetMap.isEmpty() ) {
                for ( PermissionSet eachPS : permissionSetMap.values() ) {
                    permissionSetGroupDeveloperNameToIdMap.put(
                        eachPS.PermissionSetGroup.DeveloperName ,
                        eachPS.Id
                    );
                }
            }
            Map<Id,String> assigneeToPSMap = new Map<Id,String>();
            if ( ( newList != null ) && !newList.isEmpty() ) {
                for ( User assignee : newList ) {
                    if ( String.isNotBlank( assignee.Business_Title__c )
                        && mapOfUserTitleToPermissionSetGroupDeveloperNames.containsKey( assignee.Business_Title__c )
                        )
                    {
                        for ( String psgDeveloperName : mapOfUserTitleToPermissionSetGroupDeveloperNames.get( assignee.Business_Title__c ) ) {
                            // serializing into Map<Id,String> because Map<Id,List<Id>> is not supported by future method...
                            // ~ Map keyed on UserId containing comma-separated values of PermissionSetIds
                            if ( permissionSetGroupDeveloperNameToIdMap.containsKey( psgDeveloperName ) ) {
                                if ( assigneeToPSMap.containsKey( assignee.Id ) ) {
                                    assigneeToPSMap.put(
                                        assignee.Id ,
                                        assigneeToPSMap.get( assignee.Id ) + ',' + permissionSetGroupDeveloperNameToIdMap.get( psgDeveloperName )
                                    );
                                }else{
                                    assigneeToPSMap.put(
                                        assignee.Id ,
                                        permissionSetGroupDeveloperNameToIdMap.get( psgDeveloperName )
                                    );
                                }
                            }
                        }
                    }
                }
            }
            if ( !assigneeToPSMap.isEmpty() ) {
                UserOnboardingTriggerHelper.assignPermission( assigneeToPSMap );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                UserOnboardingTriggerHelper.class.getName() ,
                'assignPermissionSetGroupToUser' ,
                e
            );
        }
    }

    //
    // @description: Method to add User to Public Group on User Creation
    // @parameters: List of users
    // @return: void
    //
    private void addUserToPublicGroup( List<User> newList , Set<Id> memberIds ) {
        try {
            if ( UserOnboardingToolSettings__c.getInstance( UserInfo.getUserId() ).IsEnabledRemoval__c
                && ( memberIds != null )
                && !memberIds.isEmpty()
                )
            {
                this.removeGroups( memberIds );
            }
            Map<String,List<String>> mapOfUserTitleToGroupDeveloperName = new Map<String,List<String>>();
            List<User_Onboarding_Detail__mdt> details = this.getUserOnboardingDetails( newList );
            if ( ( details != null ) && !details.isEmpty() ) {
                for ( User_Onboarding_Detail__mdt detail : details ) {
                    if ( String.isNotBlank( detail.Queue_Name__c ) ) {
                        mapOfUserTitleToGroupDeveloperName.put(
                            detail.Title__c ,
                            detail.Queue_Name__c.split( ',' )
                        );
                    }
                }
            }
            Set<String> groupDeveloperNames = new Set<String>();
            if ( !mapOfUserTitleToGroupDeveloperName.isEmpty() ) {
                for ( List<String> developerNames : mapOfUserTitleToGroupDeveloperName.values() ) {
                    groupDeveloperNames.addAll( developerNames );
                }
            }
            Map<Id,Group> groupMap = null;
            if ( !groupDeveloperNames.isEmpty() ) {
                groupMap = new Map<Id,Group>(
                    [
                        SELECT Id , DeveloperName
                        FROM Group
                        WHERE ( DeveloperName IN :groupDeveloperNames )
                    ]
                );
            }
            Map<String,Id> groupDeveloperNameToIdMap = new Map<String,Id>();
            if ( ( groupMap != null ) && !groupMap.isEmpty() ) {
                for ( Group record : groupMap.values() ) {
                    groupDeveloperNameToIdMap.put(
                        record.DeveloperName ,
                        record.Id
                    );
                }
            }
            Map<Id,String> memberToGroupMap = new Map<Id,String>();
            if ( ( newList != null ) && !newList.isEmpty() ) {
                for ( User member : newList ) {
                    if ( String.isNotBlank( member.Business_Title__c )
                        && mapOfUserTitleToGroupDeveloperName.containsKey( member.Business_Title__c )
                        )
                    {
                        for ( String groupDeveloperName : mapOfUserTitleToGroupDeveloperName.get( member.Business_Title__c ) ) {
                            // serializing into Map<Id,String> because Map<Id,List<Id>> is not supported by future method...
                            // ~ Map keyed on UserId containing comma-separated values of GroupIds
                            if ( groupDeveloperNameToIdMap.containsKey( groupDeveloperName ) ) {
                                if ( memberToGroupMap.containsKey( member.Id ) ) {
                                    memberToGroupMap.put(
                                        member.Id ,
                                        memberToGroupMap.get( member.Id ) + ',' + groupDeveloperNameToIdMap.get( groupDeveloperName )
                                    );
                                }else{
                                    memberToGroupMap.put(
                                        member.Id ,
                                        groupDeveloperNameToIdMap.get( groupDeveloperName )
                                    );
                                }
                            }
                        }
                    }
                }
            }
            if ( !memberToGroupMap.isEmpty() ) {
                UserOnboardingTriggerHelper.assignGroups( memberToGroupMap );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                UserOnboardingTriggerHelper.class.getName() ,
                'addUserToPublicGroup' ,
                e
            );
        }
    }

    //
    // @description: Assign Permission Set License To Users
    // @parameters: List of users
    // @return: void
    //
    private void assignPermissionSetLicense( List<User> newList , Set<Id> assigneeIds ){
        try {
            if ( UserOnboardingToolSettings__c.getInstance( UserInfo.getUserId() ).IsEnabledRemoval__c
                && ( assigneeIds != null )
                && !assigneeIds.isEmpty()
                )
            {
                this.removePermissionSetLicense( assigneeIds );
            }
            Map<String,List<String>> mapOfUserTitleToPermissionSetLicenseDeveloperNames = new Map<String,List<String>>();
            List<User_Onboarding_Detail__mdt> details = this.getUserOnboardingDetails( newList );
            if ( ( details != null ) && !details.isEmpty() ) {
                for ( User_Onboarding_Detail__mdt detail : details ) {
                    if ( String.isNotBlank( detail.Permission_Set_License__c ) ) {
                        mapOfUserTitleToPermissionSetLicenseDeveloperNames.put(
                            detail.Title__c ,
                            detail.Permission_Set_License__c.split( ',' )
                        );
                    }
                }
            }
            Set<String> permissionSetLicenseDeveloperNames = new Set<String>(); 
            if ( !mapOfUserTitleToPermissionSetLicenseDeveloperNames.isEmpty() ) {
                for ( List<String> developerNames : mapOfUserTitleToPermissionSetLicenseDeveloperNames.values() ) {
                    permissionSetLicenseDeveloperNames.addAll( developerNames );
                }
            }
            Map<Id,PermissionSetLicense> permissionSetLicenseMap = null;
            if ( !permissionSetLicenseDeveloperNames.isEmpty() ) {
                permissionSetLicenseMap = new Map<Id,PermissionSetLicense>(
                    [
                        SELECT Id , DeveloperName
                        FROM PermissionSetLicense
                        WHERE ( DeveloperName IN :permissionSetLicenseDeveloperNames )
                    ]
                );
            }
            Map<String,String> permissionSetLicenseDeveloperNameToIdMap = new Map<String,String>();        
            if ( ( permissionSetLicenseMap != null ) && !permissionSetLicenseMap.isEmpty() ) {
                for ( PermissionSetLicense license : permissionSetLicenseMap.values() ) {
                    permissionSetLicenseDeveloperNameToIdMap.put(
                        license.DeveloperName ,
                        String.valueOf( license.Id )
                    );
                }
            }
            Map<Id,String> assigneeToPSLMap = new Map<Id,String>();
            if ( ( newList != null ) && !newList.isEmpty() ) {
                for ( User assignee : newList ) {
                    if ( String.isNotBlank( assignee.Business_Title__c )
                        && mapOfUserTitleToPermissionSetLicenseDeveloperNames.containsKey( assignee.Business_Title__c )
                        )
                    {
                        for ( String permissionSetLicenseDeveloperName : mapOfUserTitleToPermissionSetLicenseDeveloperNames.get( assignee.Business_Title__c ) ) {
                            // serializing into Map<Id,String> because Map<Id,List<Id>> is not supported by future method...
                            // ~ Map keyed on UserId containing comma-separated values of PermissionSetLicenseIds...
                            if(permissionSetLicenseDeveloperNameToIdMap.containsKey(permissionSetLicenseDeveloperName)){
                                if ( assigneeToPSLMap.containsKey( assignee.Id ) ) {
                                    assigneeToPSLMap.put(
                                        assignee.Id ,
                                        assigneeToPSLMap.get( assignee.Id ) + ',' + permissionSetLicenseDeveloperNameToIdMap.get( permissionSetLicenseDeveloperName )
                                    );
                                } else {
                                    assigneeToPSLMap.put(
                                        assignee.Id ,
                                        permissionSetLicenseDeveloperNameToIdMap.get( permissionSetLicenseDeveloperName )
                                    );
                                }
                            }
                        }
                    }
                }
            }
            if ( !assigneeToPSLMap.isEmpty() ) {
                UserOnboardingTriggerHelper.permissionSetLicenseAssignment( assigneeToPSLMap );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                UserOnboardingTriggerHelper.class.getName() ,
                'assignPermissionSetLicense' ,
                e
            );
        }
    }

    //
    // @MethodName: assignPermission
    // @Description: Assign Permission Set
    // @param Map keyed on UserId containing comma-separated values of PermissionSetIds
    // @return void
    //
    @future
    private static void assignPermission( Map<Id,String> assigneeToPSMap ) {
        try {
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            if ( ( assigneeToPSMap != null ) && !assigneeToPSMap.isEmpty() ) {
                for ( Id assigneeId :assigneeToPSMap.keySet() ) {
                    List<String> permissionSetIds = assigneeToPSMap.get( assigneeId ).split( ',' );
                    if ( ( permissionSetIds != null ) && !permissionSetIds.isEmpty() ) {
                        for ( String permissionSetId : permissionSetIds ) {
                            PermissionSetAssignment assignment = new PermissionSetAssignment();
                            assignment.AssigneeId = assigneeId;
                            assignment.PermissionSetId = permissionSetId;
                            assignments.add( assignment );
                        }
                    }
                }
            }
            if ( ( assignments != null ) && !assignments.isEmpty() ) {
                List<Database.SaveResult> results = Database.insert( assignments , false );
                NSP_ErrorLogHandler.logSaveResult(
                    UserOnboardingTriggerHelper.class.getName() ,
                    'assignPermission' ,
                    results
                );
            }
        }catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                UserOnboardingTriggerHelper.class.getName() ,
                'assignPermission' ,
                e
            );
        }
    }

    //
    // @MethodName: removePermission
    // @Description: Remove Permission Set and PS Group
    // @param : Set<Id>
    // @return void
    //
    private void removePermission( Set<Id> assigneeIds ) {
        try {
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            if ( ( assigneeIds != null ) && !assigneeIds.isEmpty() ) {
                for ( PermissionSetAssignment assignment : [
                            SELECT Id , AssigneeId
                            FROM PermissionSetAssignment
                            WHERE ( AssigneeId IN :assigneeIds )
                        ]
                    )
                {
                    assignments.add( assignment );
                }
            }
            if ( ( assignments != null ) && !assignments.isEmpty() ) {
                List<Database.DeleteResult> results = Database.delete( assignments , false );
                NSP_ErrorLogHandler.logResults(
                    UserOnboardingTriggerHelper.class.getName() ,
                    'removePermission' ,
                    results
                );
            } 
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                UserOnboardingTriggerHelper.class.getName() ,
                'removePermission' ,
                e
            );
        }
    }

    //
    // Assign Public Group and Queue
    // @param Map keyed on UserId containing comma-separated values of GroupIds
    // @return void
    //
    @future
    private static void assignGroups( Map<Id,String> memberToGroupMap ) {
        try {
            List<GroupMember> memberships = new List<GroupMember>();
            if ( ( memberToGroupMap != null ) && !memberToGroupMap.isEmpty() ) {
                for ( Id memberId : memberToGroupMap.keySet() ) {
                    List<String> groupIds = memberToGroupMap.get( memberId ).split( ',' );
                    if ( ( groupIds != null ) && !groupIds.isEmpty() ) {
                        for ( String groupId : groupIds ) {
                            GroupMember membership = new GroupMember();
                            membership.GroupId = groupId;
                            membership.UserOrGroupId = memberId;
                            memberships.add( membership );
                        }
                    }
                }
            }
            if ( !memberships.isEmpty() ) {
                List<Database.SaveResult> results = Database.insert( memberships , false );
                NSP_ErrorLogHandler.logSaveResult(
                    UserOnboardingTriggerHelper.class.getName() ,
                    'assignGroups' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                UserOnboardingTriggerHelper.class.getName() ,
                'assignGroups' ,
                e
            );
        }
    }

    //
    // Remove Public Group and Queue
    // @param list that contains the userid
    // @return void
    //
    private void removeGroups( Set<Id> memberIds ) {
        try {
            List<GroupMember> memberships = new List<GroupMember>();
            if ( ( memberIds != null ) && !memberIds.isEmpty() ) {
                for ( GroupMember membership : [
                            SELECT Id , GroupId , UserOrGroupId
                            FROM GroupMember
                            WHERE ( UserOrGroupId IN :memberIds )
                        ]
                    )
                {
                    memberships.add( membership );
                }
            }
            if ( !memberships.isEmpty() ) {
                List<Database.DeleteResult> results = Database.delete( memberships , false );
                NSP_ErrorLogHandler.logResults(
                    UserOnboardingTriggerHelper.class.getName() ,
                    'removeGroups' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                UserOnboardingTriggerHelper.class.getName() ,
                'removeGroups' ,
                e
            );
        }
    }

    //
    // Permission Set License Assignment
    // @param Map keyed on UserId containing comma-separated values of PermissionSetLicenseIds
    // @return void
    //
    @future
    private static void permissionSetLicenseAssignment( Map<Id,String> assigneeToPSLMap ) {
        try {
            List<PermissionSetLicenseAssign> assignments = new List<PermissionSetLicenseAssign>();
            if ( ( assigneeToPSLMap != null ) && !assigneeToPSLMap.isEmpty() ) {
                for ( Id assigneeId : assigneeToPSLMap.keySet() ) {
                    List<String> permissionSetLicenseIds = assigneeToPSLMap.get( assigneeId ).split( ',' );
                    if ( ( permissionSetLicenseIds != null ) && !permissionSetLicenseIds.isEmpty() ) {
                        for ( String permissionSetLicenseId : permissionSetLicenseIds ) {
                            PermissionSetLicenseAssign assignment = new PermissionSetLicenseAssign();
                            assignment.AssigneeId = assigneeId;
                            assignment.PermissionSetLicenseId = Id.valueOf( permissionSetLicenseId );
                            assignments.add( assignment );
                        }
                    }
                }
            }
            if ( !assignments.isEmpty() ) {
                List<Database.SaveResult> results = Database.insert( assignments , false );
                NSP_ErrorLogHandler.logSaveResult(
                    UserOnboardingTriggerHelper.class.getName() ,
                    'permissionSetLicenseAssignment' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                UserOnboardingTriggerHelper.class.getName() ,
                'permissionSetLicenseAssignment' ,
                e
            );
        }
    }

    //
    // Remove Permission Set License Assignment
    // @param list that contains the userid
    // @return void
    //
    private void removePermissionSetLicense( Set<Id> assigneeIds ) {
        try {
            List<PermissionSetLicenseAssign> assignments = new List<PermissionSetLicenseAssign>();
            if ( ( assigneeIds != null ) && !assigneeIds.isEmpty() ) {
                for ( PermissionSetLicenseAssign assignment : [
                            SELECT Id , AssigneeId , PermissionSetLicenseId
                            FROM PermissionSetLicenseAssign
                            WHERE ( AssigneeId IN :assigneeIds )
                        ]
                    )
                {
                    assignments.add( assignment );
                }
            }
            if ( !assignments.isEmpty() ) {
                List<Database.DeleteResult> results = Database.delete( assignments , false );
                NSP_ErrorLogHandler.logResults(
                    UserOnboardingTriggerHelper.class.getName() ,
                    'removePermissionSetLicense' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                UserOnboardingTriggerHelper.class.getName() ,
                'removePermissionSetLicense' ,
                e
            );
        }
    }

    //
    // Method to get the List of User_Onboarding_Detail__mdt details
    // @param List<User>
    // @return List<User_Onboarding_Detail__mdt>
    //
    private List<User_Onboarding_Detail__mdt> getUserOnboardingDetails( List<User> records ) {
        List<User_Onboarding_Detail__mdt> details = new List<User_Onboarding_Detail__mdt>();
        Set<String> titles = new Set<String>();
        if ( ( records != null ) && !records.isEmpty() ) {
            for ( User record : records ) {
                if ( String.isNotBlank( record.Business_Title__c ) ) {
                    titles.add( record.Business_Title__c );
                }
            }
        }
        if ( !titles.isEmpty() ) {
            details = this.getUserOnboardingDetails( titles );
        }
        return details;
    }

    private List<User_Onboarding_Detail__mdt> getUserOnboardingDetails( Set<String> titles ) {
        List<User_Onboarding_Detail__mdt> details = new List<User_Onboarding_Detail__mdt>();
        if ( ( titles != null ) && !titles.isEmpty() ) {
            details = [
                SELECT
                    Title__c ,
                    Profile__c ,
                    Role__c ,
                    Department__c ,
                    HR_Division__c ,
                    Is_FF_User__c ,
                    Financial_Force_User__c ,
                    Curated_Picklist__c ,
                    RET_Groups__c ,
                    RET_Department_list__c ,
                    Knowledge_User__c ,
                    Marketing_User__c ,
                    Service_Cloud_User__c ,
                    Chat_User__c ,
                    Permission_Set_Group_Name__c ,
                    Permission_Set_License__c ,
                    Permission_Set_Name__c ,
                    Queue_Name__c
                FROM User_Onboarding_Detail__mdt
                WHERE ( Title__c IN :titles )
            ];
        }
        return details;
    }

}
//