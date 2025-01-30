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
                this.assignPermissionSetLicense( userList );
                this.assignPermissionSetToUser( userList );
                this.assignPermissionSetGroupToUser( userList );
                this.addUserToPublicGroup( userList );
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
                    if (isUserEligibleForUpdate(usr, oldMap) )
                    {
                        userList.add( usr );
                        userToremovePerm.add( usr.Id );
                    }
                }
            }
            
            if (shouldHandleRemoval(userToRemovePerm, oldMap)) {
                handleRemoval(userToremovePerm, oldMap, 'PermissionSet');
                handleRemoval(userToremovePerm, oldMap, 'Group');
                handleRemoval(userToremovePerm, oldMap, 'PermissionSetLicense');
            }
            if ( !userList.isEmpty() ){
                this.assignPermissionSetLicense( userList );
                this.assignPermissionSetToUser( userList );
                this.assignPermissionSetGroupToUser( userList );
                this.addUserToPublicGroup( userList );
            }
        }
    }
    private Boolean shouldHandleRemoval(Set<Id> userToRemovePerm, Map<Id, User> oldMap) {
        return UserOnboardingToolSettings__c.getInstance(UserInfo.getUserId()).IsEnabledRemoval__c &&
            userToRemovePerm != null && !userToRemovePerm.isEmpty() &&
            oldMap != null;
    }
    private Boolean isUserEligibleForUpdate(User usr, Map<Id, User> oldMap) {
        if (oldMap == null || oldMap.get(usr.Id) == null) {
            return false;
        }
        
        User oldUser = oldMap.get(usr.Id);
        return usr.Run_Permission_Automation__c &&
            String.isNotBlank(usr.Business_Title__c) &&
            usr.IsActive &&
            (oldUser.Run_Permission_Automation__c != usr.Run_Permission_Automation__c ||
             oldUser.Business_Title__c != usr.Business_Title__c ||
             oldUser.IsActive != usr.IsActive);
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
    // @parameters: List of users
    // @return: void
    // Entry Method
    //
    
    private void assignPermissionSetToUser(List<User> newList ) {
        if(newList != null && !newList.isEmpty()){
            processUserAssignments(newList, 'PermissionSet');
        }
    }
    
    private void assignPermissionSetGroupToUser(List<User> newList ) {
        if(newList != null && !newList.isEmpty()){
            processUserAssignments(newList, 'PermissionSetGroup');
        }
    }
    
    private void addUserToPublicGroup(List<User> newList ) {
        if(newList != null && !newList.isEmpty()){
            processUserAssignments(newList, 'Group');
        }
    }
    
    private void assignPermissionSetLicense(List<User> newList ) {
        if(newList != null && !newList.isEmpty()){
            processUserAssignments(newList, 'PermissionSetLicense');
        }
    }
    
    private void processUserAssignments(
        List<User> newList,
        String entityType
    ) {
        List<User_Onboarding_Detail__mdt> details = new List<User_Onboarding_Detail__mdt>();
        Map<String, List<String>> titleToEntityMap = new Map<String, List<String>> ();
        Set<String> entityNames = new Set<String>();
        Map<String, Id> entityNameToIdMap = new Map<String, Id>();
        Map<Id, String> userToEntityMap = new Map<Id, String>();
        try {            
            // Retrieve user onboarding details
            if(newList != null && !newList.isEmpty()) {
                details = getUserOnboardingDetails(newList);
            }            
            // Build a mapping of user titles to entity developer names
            if(!details.isEmpty()) {
                titleToEntityMap = buildTitleToEntityMap(details, entityType);
            }
            // Fetch entity developer names
            if(!titleToEntityMap.isEmpty()) {
                entityNames = extractEntityNames(titleToEntityMap);
            }
            if(!entityNames.isEmpty()) {
                entityNameToIdMap = fetchEntityIdsByName(entityNames, entityType);
            }
            // Build user-to-entity mapping
            if(!entityNameToIdMap.isEmpty() && !titleToEntityMap.isEmpty()) {
                userToEntityMap = buildUserToEntityMap(newList, titleToEntityMap, entityNameToIdMap);
            }
            // Assign entities to users
            if (!userToEntityMap.isEmpty()) {
                assignEntitiesToUsers(userToEntityMap, entityType);
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                UserOnboardingTriggerHelper.class.getName(),
                'processUserAssignments - ' + entityType,
                e
            );
        }
    }
    
    private void handleRemoval(Set<Id> ids, Map<Id, User> oldMap, String entityType) {
        if(entityType != null){
            if (entityType == 'PermissionSet') {
                removePermission(ids, oldMap);
            } else if (entityType == 'Group') {
                removeGroups(ids, oldMap);
            } else if ( entityType == 'PermissionSetLicense') {
                removePermissionSetLicense(ids, oldMap);
            }
        }
    }
    
    private static Map<String, List<String>> buildTitleToEntityMap(
        List<User_Onboarding_Detail__mdt> details,
        String entityType
    ) {
        Map<String, List<String>> titleToPermissionMap = new Map<String, List<String>>();
        if(details != null && !details.isEmpty()){
            for (User_Onboarding_Detail__mdt detail : details) {
                if (String.isNotBlank(detail.Title__c)) {
                    if(entityType == 'PermissionSet') {
                        titleToPermissionMap.put(detail.Title__c, detail.Permission_Set_Name__c.split(','));
                    } else if(entityType == 'PermissionSetGroup') {
                        titleToPermissionMap.put(detail.Title__c, detail.Permission_Set_Group_Name__c.split(','));
                    } else if(entityType == 'Group') {
                        titleToPermissionMap.put(detail.Title__c, detail.Queue_Name__c.split(','));
                    } else if(entityType == 'PermissionSetLicense') {
                        titleToPermissionMap.put(detail.Title__c, detail.Permission_Set_License__c.split(','));
                    }
                }
            }
        }
        return titleToPermissionMap;
    }
    
    private Set<String> extractEntityNames(Map<String, List<String>> titleToEntityMap) {
        Set<String> entityNames = new Set<String>();
        if(titleToEntityMap != null && !titleToEntityMap.isEmpty()){
            for (List<String> names : titleToEntityMap.values()) {
                entityNames.addAll(names);
            }
        }
        return entityNames;
    }
    private Map<String, Id> fetchEntityIdsByName(Set<String> names, String entityType) {
        Map<String, Id> nameToIdMap = new Map<String, Id>();
        
        if (isInputValid(names, entityType)) {
            nameToIdMap = fetchEntityData(names, entityType);
        }
        
        return nameToIdMap;
    }
    
    private Boolean isInputValid(Set<String> names, String entityType) {
        return entityType != null && names != null && !names.isEmpty();
    }
    
    private Map<String, Id> fetchEntityData(Set<String> names, String entityType) {
        Map<String, Id> nameToIdMap = new Map<String, Id>();
        
        if (entityType == 'PermissionSet') {
            for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN :names]) {
                nameToIdMap.put(ps.Name, ps.Id);
            }
        } else if (entityType == 'PermissionSetGroup') {
            for (PermissionSet ps : [
                SELECT Id, PermissionSetGroup.DeveloperName
                FROM PermissionSet
                WHERE PermissionSetGroupId IN (
                    SELECT Id FROM PermissionSetGroup WHERE DeveloperName IN :names
                )
            ]) {
                nameToIdMap.put(ps.PermissionSetGroup.DeveloperName, ps.Id);
            }
        } else if (entityType == 'Group') {
            for (Group userGroup : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :names]) {
                nameToIdMap.put(userGroup.DeveloperName, userGroup.Id);
            }
        } else if (entityType == 'PermissionSetLicense') {
            for (PermissionSetLicense psl : [SELECT Id, DeveloperName FROM PermissionSetLicense WHERE DeveloperName IN :names]) {
                nameToIdMap.put(psl.DeveloperName, psl.Id);
            }
        }
        
        return nameToIdMap;
    }
    
    
    private Map<Id, String> buildUserToEntityMap(
        List<User> users,
        Map<String, List<String>> titleToEntityMap,
        Map<String, Id> entityNameToIdMap
    ) {
        Map<Id, String> userToEntityMap = new Map<Id, String>();
        if (users != null && !users.isEmpty() && titleToEntityMap != null && entityNameToIdMap != null){
            for (User eachuser : users) {
                if (String.isNotBlank(eachuser.Business_Title__c) &&
                    titleToEntityMap.containsKey(eachuser.Business_Title__c)) {
                        
                        for (String entityName : titleToEntityMap.get(eachuser.Business_Title__c)) {
                            addEntityToUserMap(entityName, userToEntityMap, entityNameToIdMap, eachUser );
                        }
                    }
            }
        }
        return userToEntityMap;
    }
    
    private void addEntityToUserMap(
        String entityName,
        Map<Id, String> userToEntityMap,
        Map<String, Id> entityNameToIdMap,
        user eachUser
    ) {
        //do not remove this if
        if (entityNameToIdMap.containsKey(entityName)) {
            if (userToEntityMap.containsKey(eachuser.Id)) {
                userToEntityMap.put(
                    eachuser.Id,
                    userToEntityMap.get(eachuser.Id) + ',' + entityNameToIdMap.get(entityName)
                );
            } else {
                userToEntityMap.put(eachuser.Id, entityNameToIdMap.get(entityName));
            }
        }
        
    }
    
    private void assignEntitiesToUsers(Map<Id, String> userToEntityMap, String entityType) {
        if(entityType != null ){
            if( entityType == 'PermissionSet') {
                UserOnboardingTriggerHelper.assignPermission(userToEntityMap);
            }
            else if( entityType == 'PermissionSetGroup') {
                UserOnboardingTriggerHelper.assignPermission(userToEntityMap);
            }
            else if( entityType == 'Group') {
                UserOnboardingTriggerHelper.assignGroups(userToEntityMap);
            }
            else if( entityType == 'PermissionSetLicense'){
                UserOnboardingTriggerHelper.permissionSetLicenseAssignment(userToEntityMap);
            }
        }
    }
    
    //
    // @MethodName: assignPermission
    // @Description: Assign Permission Set
    // @param Map keyed on UserId containing comma-separated values of PermissionSetIds
    // @return void
    //
    // *****************
    
    private static List<PermissionSetAssignment> createAssignments(Map<Id, String> inputMap) {
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        
        if (inputMap != null && !inputMap.isEmpty()) {
            for (Id assigneeId : inputMap.keySet()) {
                List<String> permissionSetIds = inputMap.get(assigneeId).split(',');
                for (String permissionSetId : permissionSetIds) {
                    assignments.add(new PermissionSetAssignment(AssigneeId = assigneeId, PermissionSetId = permissionSetId));
                }
            }
        }
        
        return assignments;
    }
    
    private static List<GroupMember> createAssignmentsForGroups(Map<Id, String> inputMap) {
        List<GroupMember> memberships = new List<GroupMember>();
        
        if (inputMap != null && !inputMap.isEmpty()) {
            for (Id memberId : inputMap.keySet()) {
                List<String> groupIds = inputMap.get(memberId).split(',');
                for (String groupId : groupIds) {
                    memberships.add(new GroupMember(UserOrGroupId = memberId, GroupId = groupId));
                }
            }
        }
        
        return memberships;
    }
    
    private static List<PermissionSetLicenseAssign> createAssignmentsForLicenses(Map<Id, String> inputMap) {
        List<PermissionSetLicenseAssign> assignments = new List<PermissionSetLicenseAssign>();
        
        if (inputMap != null && !inputMap.isEmpty()) {
            for (Id assigneeId : inputMap.keySet()) {
                List<String> permissionSetLicenseIds = inputMap.get(assigneeId).split(',');
                for (String permissionSetLicenseId : permissionSetLicenseIds) {
                    assignments.add(new PermissionSetLicenseAssign(AssigneeId = assigneeId, PermissionSetLicenseId = Id.valueOf(permissionSetLicenseId)));
                }
            }
        }
        
        return assignments;
    }
    
    private static void assignPermission(Map<Id, String> assigneeToPSMap) {
        List<PermissionSetAssignment> assignments = createAssignments(assigneeToPSMap);
        
        if (!assignments.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(assignments, false);
            Integer errorCount = 0;
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    errorCount++;
                    for(Database.Error err : sr.getErrors()) {
                        UserOnboardingQueuable.createErrorLog(UserOnboardingTriggerHelper.class.getName(), 'assignPermission', err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
            if (errorCount == 0 ){
                UserOnboardingQueuable.createErrorLog(UserOnboardingTriggerHelper.class.getName(), 'assignPermission', 'No error in Permission Set/ Permission Set Group Assignment.');
            }
        }
    }
    
    private static void assignGroups(Map<Id, String> memberToGroupMap) {
        List<GroupMember> memberships = createAssignmentsForGroups(memberToGroupMap);
        
        if (!memberships.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(memberships, false);
            Integer errorCount = 0;
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        UserOnboardingQueuable.createErrorLog(UserOnboardingTriggerHelper.class.getName(), 'assignGroups', err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
            if (errorCount == 0 ){
                UserOnboardingQueuable.createErrorLog(UserOnboardingTriggerHelper.class.getName(), 'assignGroups', 'No error in Queue/Public Group assignment.');
            }
        }
    }
    
    private static void permissionSetLicenseAssignment(Map<Id, String> assigneeToPSLMap) {
        List<PermissionSetLicenseAssign> assignments = createAssignmentsForLicenses(assigneeToPSLMap);
        
        if (!assignments.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(assignments, false);
            Integer errorCount = 0;
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        UserOnboardingQueuable.createErrorLog(UserOnboardingTriggerHelper.class.getName(), 'permissionSetLicenseAssignment', err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
            if (errorCount == 0 ){
                UserOnboardingQueuable.createErrorLog(UserOnboardingTriggerHelper.class.getName(), 'permissionSetLicenseAssignment', 'No error in Permission Set License assignment.');
            }
        }
    }
    
    
    private List<PermissionSetAssignment> filterPermissionAssignments(
        Set<Id> assigneeIds,
        Map<Id, User> oldMap,
        Map<String, List<String>> entityMap,
        Map<String, List<String>> entitypsgMap
    ) {
        List<PermissionSetAssignment> filteredAssignments = new List<PermissionSetAssignment>();
        for (PermissionSetAssignment assignment : [
            SELECT Id, AssigneeId, PermissionSet.Name, PermissionSetGroup.DeveloperName, Assignee.Business_Title__c
            FROM PermissionSetAssignment
            WHERE AssigneeId IN :assigneeIds
        ]) {
            String oldBusinessTitle = oldMap.get(assignment.AssigneeId).Business_Title__c;
            
            if ((entityMap.containsKey(oldBusinessTitle) &&
                 entityMap.get(oldBusinessTitle).contains(assignment.PermissionSet.Name)) ||
                (entitypsgMap != null && entitypsgMap.containsKey(oldBusinessTitle) &&
                 entitypsgMap.get(oldBusinessTitle).contains(assignment.PermissionSetGroup.DeveloperName))) {
                     filteredAssignments.add(assignment);
                 }
        }
        return filteredAssignments;
    }
    
    private List<PermissionSetLicenseAssign> filterAssignments(
        Set<Id> assigneeIds,
        Map<Id, User> oldMap,
        Map<String, List<String>> entityMap
    ) {
        List<PermissionSetLicenseAssign> filteredAssignments = new List<PermissionSetLicenseAssign>();
        for (PermissionSetLicenseAssign assignment : [
            SELECT Id, AssigneeId, PermissionSetLicense.DeveloperName, Assignee.Business_Title__c
            FROM PermissionSetLicenseAssign
            WHERE AssigneeId IN :assigneeIds
        ]) {
            String oldBusinessTitle = oldMap.get(assignment.AssigneeId).Business_Title__c;
            
            if (entityMap.containsKey(oldBusinessTitle) &&
                entityMap.get(oldBusinessTitle).contains(assignment.PermissionSetLicense.DeveloperName)) {
                    filteredAssignments.add(assignment);
                }
        }
        return filteredAssignments;
    }
    
    private List<GroupMember> filtergroupAssignments(
        Set<Id> memberIds,
        Map<Id, User> oldMap,
        Map<String, List<String>> groupMap
    ) {
        List<GroupMember> filteredAssignments = new List<GroupMember>();
        for (GroupMember membership : [
            SELECT Id, Group.DeveloperName, UserOrGroupId, UserOrGroup.Business_Title__c
            FROM GroupMember
            WHERE UserOrGroupId IN :memberIds
        ]) {
            String oldBusinessTitle = oldMap.get(membership.UserOrGroupId).Business_Title__c;
            
            if (groupMap.containsKey(oldBusinessTitle) &&
                groupMap.get(oldBusinessTitle).contains(membership.Group.DeveloperName)) {
                    filteredAssignments.add(membership);
                }
        }
        return filteredAssignments;
    }
    private void removePermission(Set<Id> assigneeIds, Map<Id, User> oldMap) {
        List<User_Onboarding_Detail__mdt> details = new List<User_Onboarding_Detail__mdt>();
        if(oldMap != null){
            details = getUserOnboardingDetails(oldMap.values());
        }
        Map<String, List<String>> permissionSetMap = createPermissionSetMap(details);
        Map<String, List<String>> permissionSetGroupMap = createPermissionSetGroupMap(details);
        
        List<PermissionSetAssignment> assignmentsToDelete = filterPermissionAssignments(assigneeIds, oldMap, permissionSetMap, permissionSetGroupMap);
        
        if (!assignmentsToDelete.isEmpty()) {
            List<Database.DeleteResult> results = Database.delete(assignmentsToDelete, false);
            Integer errorCount = 0;
            for (Database.DeleteResult sr : results) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        UserOnboardingQueuable.createErrorLog(UserOnboardingTriggerHelper.class.getName(), 'removePermission', err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
            if (errorCount == 0 ){
                UserOnboardingQueuable.createErrorLog(UserOnboardingTriggerHelper.class.getName(), 'removePermission', 'No error in Permission Set/ Permission Set Group Deletion.');
            }
        }
    }
    private void removeGroups(Set<Id> memberIds, Map<Id, User> oldMap) {
        List<User_Onboarding_Detail__mdt> details = new List<User_Onboarding_Detail__mdt>();
        if(oldMap != null){
            details = getUserOnboardingDetails(oldMap.values());
        }
        
        Map<String, List<String>> groupMap = createGroupMap(details);
        
        List<GroupMember> membershipsToDelete = filtergroupAssignments(memberIds, oldMap, groupMap);
        
        if (!membershipsToDelete.isEmpty()) {
            List<Database.DeleteResult> results = Database.delete(membershipsToDelete, false);
            Integer errorCount = 0;
            for (Database.DeleteResult sr : results) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        UserOnboardingQueuable.createErrorLog(UserOnboardingTriggerHelper.class.getName(), 'removeGroups', err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
            if (errorCount == 0 ){
                UserOnboardingQueuable.createErrorLog(UserOnboardingTriggerHelper.class.getName(), 'removeGroups', 'No error in Group deletion.');
            }
        }
    }
    
    private void removePermissionSetLicense(Set<Id> assigneeIds, Map<Id, User> oldMap) {
        List<User_Onboarding_Detail__mdt> details = new List<User_Onboarding_Detail__mdt>();
        if(oldMap != null){
            details = getUserOnboardingDetails(oldMap.values());
        }
        
        Map<String, List<String>> permissionSetLicenseMap = createPermissionLicenceMap(details);
        
        List<PermissionSetLicenseAssign> assignmentsToDelete = filterAssignments(assigneeIds, oldMap, permissionSetLicenseMap);
        
        if (!assignmentsToDelete.isEmpty()) {
            List<Database.DeleteResult> results = Database.delete(assignmentsToDelete, false);
            Integer errorCount = 0;
            for (Database.DeleteResult sr : results) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        UserOnboardingQueuable.createErrorLog(UserOnboardingTriggerHelper.class.getName(), 'removePermissionSetLicense', err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
            if (errorCount == 0 ){
                UserOnboardingQueuable.createErrorLog(UserOnboardingTriggerHelper.class.getName(), 'removePermissionSetLicense', 'No error in Permission Set License deletion.');
            }
        }
    }
    
    
    
    private static Map<String, List<String>> createMap(List<User_Onboarding_Detail__mdt> details, String fieldName) {
        Map<String, List<String>> resultMap = new Map<String, List<String>>();
        if (details != null && !details.isEmpty()) {
            for (User_Onboarding_Detail__mdt detail : details) {
                String value = (String) detail.get(fieldName);
                if (String.isNotBlank(value)) {
                    resultMap.put(detail.Title__c, value.split(','));
                }
            }
        }
        return resultMap;
    }
    private static Map<String, List<String>> createPermissionSetMap(List<User_Onboarding_Detail__mdt> details) {
        return createMap(details, 'Permission_Set_Name__c');
    }
    
    private static Map<String, List<String>> createPermissionSetGroupMap(List<User_Onboarding_Detail__mdt> details) {
        return createMap(details, 'Permission_Set_Group_Name__c');
    }
    
    private static Map<String, List<String>> createGroupMap(List<User_Onboarding_Detail__mdt> details) {
        return createMap(details, 'Queue_Name__c');
    }
    
    private static Map<String, List<String>> createPermissionLicenceMap(List<User_Onboarding_Detail__mdt> details) {
        return createMap(details, 'Permission_Set_License__c');
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