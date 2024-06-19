/**
* @description  :  Helper class for ACR trigger.
* @date 07/11/2022
* Author : Nischay Jindal
* Name : NSP_AccountContactServiceHelper
* Modification History
* Rahul Singh        May  24 2023        Modified as part of DF-04216
*/
public class NSP_AccountContactServiceHelper {
    // test w/ NSP_AccountContactServiceHelperTest (95%)

    /***********************************************************************************************
    * MethodName: createExternalUser
    * Description : This Method will create the Portal user and update the User Permissions
    * Params:       Map<Id, AccountContactRelation> newACRMap,Map<Id, AccountContactRelation> oldACRMap
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    public static void createExternalUser(Map<Id, AccountContactRelation> newACRMap,Map<Id, AccountContactRelation> oldACRMap){
        Set<Id> acrContactIdSet = new set<Id>();
        List<User> newUserList = new List<User>();
        Map<Id,Contact> contactMap = new Map<Id,Contact>();
        Set<Id> userIdSet = new Set<Id>();
        Set<Id> deactivateUserId = new Set<Id>();
        Map<Id,String> mapContactIdUserPerm = new Map<Id,String>();
        Map<Id,Id> mapContactIdUserId = new Map<Id,Id>();
        Map<Id,String> mapConIdCommAccess = new Map<Id,String>();
        Set<Id> removePermUserIdSet = new Set<Id>();
        Set<Id> reactivatedUserIdSet = new Set<Id>();
        Map<Id,Id> mapContactIdInactiveUserId = new Map<Id,Id>();
        Map<Id,String> mapContactIdUserDeactive = new Map<Id,String>();
        Set<String> permissionSetNameSet = new Set<String>();
        Set<Id> permissionIdSet = new Set<Id>();
        Set<Id> inactiveUserIdSet = new Set<Id>();
        try{
            Id communityUserProfileId = [SELECT Id  FROM Profile WHERE Name = :NSP_ServiceConstants.communityUserProfilePlus ].Id;
            // fetching all the permission set from the metadata
            Map<String, NSP_Assign_permission_set_to_Community__mdt> assignPermSetMap = NSP_Assign_permission_set_to_Community__mdt.getAll();
            for(NSP_Assign_permission_set_to_Community__mdt permSet:assignPermSetMap.values() ){
                if(permSet.NSP_Permission_Set_Name__c!=null){
                    permissionSetNameSet.add(permSet.NSP_Permission_Set_Name__c);
                }
            }
            // creating set of Permission Set Id required to be assigned to Comm User
            for(PermissionSet permSet:[SELECT Id FROM PermissionSet WHERE Name IN:permissionSetNameSet ] ){
                permissionIdSet.add(permSet.Id);
            }
            for(AccountContactRelation acr:newACRMap.values()){
                // create new portal user or activating existing user
                if(acr.NSP_Community_Access__c != null && acr.NSP_Community_Access__c.contains(NSP_ServiceConstants.peoCommunityAccess)){
                    acrContactIdSet.add(acr.ContactId);
                }
                // deactivate Portal User && removing project Permissions from portal user
                else if(acr.NSP_Community_Access__c == null && oldACRMap.get(acr.Id).NSP_Community_Access__c!= null ){
                    acrContactIdSet.add(acr.ContactId);
                    mapContactIdUserPerm.put(acr.ContactId,NSP_ServiceConstants.RemovePermission);
                    mapContactIdUserDeactive.put(acr.ContactId,NSP_ServiceConstants.DeactivateUser);
                }
            }
            
            // fetching list of ACR's for given contact Id
            
            List <AccountContactRelation> acrList = [SELECT Id , ContactId ,NSP_Community_Access__c FROM AccountContactRelation WHERE ContactId IN:acrContactIdSet AND NSP_Community_Access__c != Null ];
            // creating a map of contact Id and Peo Project Communities
            for(AccountContactRelation acr:acrList){
                if(acr.NSP_Community_Access__c.Contains(NSP_ServiceConstants.peoCommunityAccess)){
                    mapConIdCommAccess.put(acr.ContactId,acr.NSP_Community_Access__c);  
                }
            }
            // fetching active portal users  
            for(User user :[SELECT Id ,ContactId , IsActive FROM User WHERE Profile.Name =: NSP_ServiceConstants.communityUserProfilePlus AND  ContactId IN:acrContactIdSet ]){
                if(user.IsActive){
                    // creating list of Users needs to inserted
                    mapContactIdUserId.put(user.ContactId,user.Id);
                    
                    // creating a list of users needs to be daectivated                
                    if(acrList.isEmpty() && mapContactIdUserDeactive.containsKey(user.ContactId) && mapContactIdUserDeactive.get(user.ContactId) ==NSP_ServiceConstants.DeactivateUser  ){
                        
                        deactivateUserId.add(user.Id);
                    }
                    // creating a list of users where project permission needs to be removed
                    
                    if(!mapConIdCommAccess.containsKey(user.ContactId) && mapContactIdUserPerm.containsKey(user.ContactId) && mapContactIdUserPerm.get(user.ContactId) == NSP_ServiceConstants.RemovePermission){
                        removePermUserIdSet.add(user.Id);
                    }  
                }
                // reactivating the existing user  
                else if(!user.IsActive ) {
                    reactivatedUserIdSet.add(user.Id);
                    mapContactIdInactiveUserId.put(user.ContactId, user.Id);
                }
            }
            // creating Users for Contacts
            for(Contact con :[SELECT Id ,NSP_Preferred_First_Name__c ,FirstName, LastName, NSP_Work_email__c, NSP_Per_ID__c FROM Contact  WHERE  Id  IN: acrContactIdSet]){
                // creating Community User
                if( (mapContactIdUserId.isEmpty() && mapContactIdInactiveUserId.isEmpty() ) || (!mapContactIdUserId.containsKey(con.Id) && !mapContactIdInactiveUserId.containsKey(con.Id)) ){
                    User commUser = createUser(con , communityUserProfileId);
                    commUser.FederationIdentifier= con.NSP_Per_ID__c;
                    newUserList.add(commUser);
                }
                // reactivate deactivated portal Users
                else if(mapContactIdInactiveUserId.containsKey(con.Id)){
                    inactiveUserIdSet.add(mapContactIdInactiveUserId.get(con.Id));
                }
            }
            if(!inactiveUserIdSet.isEmpty()){
                System.enqueueJob( new NSP_portalUserUpdate( reactivatedUserIdSet,true,permissionIdSet,removePermUserIdSet,permissionIdSet));
            }
            if(!newUserList.isEmpty()){
                insert newUserList;
                for(User usr:newUserList){
                    userIdSet.add(usr.Id);
                }
                assignPermissionControl(userIdSet);
                // assigning user Perm
                assignUserPerm(userIdSet,permissionIdSet );
            }    
            // removing permission set and deactivating the users 
            if(!deactivateUserId.isEmpty()){
                System.enqueueJob( new NSP_portalUserUpdate( deactivateUserId,false,permissionIdSet,removePermUserIdSet,permissionIdSet) );
            }
            if(!removePermUserIdSet.isEmpty()){
                removePermissionControlForDeactivatedUsers(deactivateUserId);
            }
            
            
            if(!reactivatedUserIdSet.isEmpty()){
                assignPermissionControl(reactivatedUserIdSet);
            }
            
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountContactServiceHelper.class.getName() ,
                'createExternalUser' ,
                e
            );
        }
    }
    
    /***********************************************************************************************
    * MethodName: removeUserPermissions
    * Description : This Method removes the Project Community Permission from User
    * ********************************************************************************************/
    @future
    public static void removeUserPermissions(Set<Id> userIdSet, Set<Id>permIdSet){
        List<PermissionSetAssignment> deleteUserPermList = new List<PermissionSetAssignment>();
        for(PermissionSetAssignment psa:[Select Id,PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId IN:userIdSet ] ){
            if(permIdSet.contains(psa.PermissionSetId)){
                deleteUserPermList.add(psa);
            }
        }
        if(!deleteUserPermList.isEmpty()){
            delete deleteUserPermList; 
        }
    }
    
    /***********************************************************************************************
    * MethodName: createUser
    * Description : This Method creates new portal user
    * ********************************************************************************************/
    private static User createUser(Contact contact , Id communityUserProfileId){
        String lastName=  contact.LastName.replaceAll( '\\s+', '_');
        String userName= contact.NSP_Work_email__c +'.'+ lastName;
        String alias =  NSP_ServiceConstants.userAlias + contact.LastName.substring(0, 2) ;
        String communityNickname = contact.NSP_Preferred_First_Name__c != null && contact.NSP_Per_ID__c != null? contact.NSP_Preferred_First_Name__c.substring(0, 1) + contact.LastName + contact.NSP_Per_ID__c : alias;
        User portalUser = new User();
        portalUser.UserName = userName;
        portalUser.FirstName = contact.NSP_Preferred_First_Name__c;//Modified as part of DF-04216
        portalUser.LastName = contact.LastName;
        portalUser.Alias = alias ;
        portalUser.CommunityNickname = communityNickname;
        portalUser.email = contact.NSP_Work_email__c;
        portalUser.ContactId = contact.Id;
        portalUser.ProfileId = communityUserProfileId;
        portalUser.EmailEncodingKey = 'UTF-8';
        portalUser.TimeZoneSidKey = 'America/Los_Angeles';
        portalUser.LocaleSidKey = 'en_US';
        portalUser.LanguageLocaleKey = 'en_US';
        return portalUser;
    }
    
    /***********************************************************************************************
    * MethodName: assignUserPerm
    * Description : This Method assigns Project Community Permissions to User
    * ********************************************************************************************/  
    @future
    public static void assignUserPerm(Set<Id> userIdSet , Set<Id>permIdSet){
        createUserPerm( userIdSet , permIdSet);
    }
    
    public static void createUserPerm(Set<Id> userIdSet , Set<Id>permIdSet){
        List<PermissionSetAssignment> permissionSetList = new List<PermissionSetAssignment>();
        for(Id usrId:userIdSet){
            for(Id prjCommPermId:permIdSet){
                PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = prjCommPermId, AssigneeId = usrId);
                permissionSetList.add(psa);
            }
        }
        if(!permissionSetList.isEmpty()){
            insert permissionSetList;
        }
    }
    
    /***********************************************************************************************
    * MethodName: getDefaultRegion
    * Description : This Method to get the defaultRegion
    * ********************************************************************************************/  
    @testvisible
    private static pse__Region__c getDefaultRegion(){
        String regionQuery = new NSP_QueryBuilder('pse__Region__c', new List<String>{'Id', 'Name' })
            .addFilter('Name', NSP_ServiceConstants.UnitedStatesRegion)
            .addLimit(1)
            .build();
        return Database.query(regionQuery);
    }
    
    /***********************************************************************************************
    * MethodName: assignPermissionControl
    * Description : This Method is to assign Permission control
    * ********************************************************************************************/  
    @future
    public static void assignPermissionControl(Set<Id> userSet){
        List<pse__Permission_Control__c> lstpermControl = new List<pse__Permission_Control__c>();
        pse__Region__c region = getDefaultRegion();
        for(Id userId : userSet){
            pse__Permission_Control__c  permissionControl = new pse__Permission_Control__c();
            permissionControl.pse__Region__c = region.Id;
            permissionControl.pse__User__c = userId;
            permissionControl.pse__View_Task_Manager__c = True;
            permissionControl.pse__Edit_Task_Manager__c = True;
            lstpermControl.add(permissionControl);
        }
        if(!lstpermControl.isEmpty()) {
            List<Database.UpsertResult> results = Database.upsert(lstpermControl, false);
            NSP_ErrorLogHandler.logResults(
                NSP_AccountContactServiceHelper.class.getName() ,
                'assignPermissionControl' ,
                results
            );
        }
    }
    
    /***********************************************************************************************
    * MethodName: assignPermissionControl
    * Description : This Method is to removePermissionControlForDeactivatedUsers
    * ********************************************************************************************/  
    @testvisible
    public static void removePermissionControlForDeactivatedUsers(Set<Id> deactivateUserId){
        String permissionControlQuery = new NSP_QueryBuilder('pse__Permission_Control__c', new List<String>{'Id'})
            .addFilter('pse__User__c', new List<Id>(deactivateUserId), NSP_QueryBuilder.Operator.INCLUDES)
            .build();
        List<pse__Permission_Control__c> lstRecords = Database.query(permissionControlQuery);
        Database.DeleteResult[] results = Database.Delete(lstRecords,false);
        NSP_ErrorLogHandler.logResults(
            NSP_AccountContactServiceHelper.class.getName() ,
            'removePermissionControlForDeactivatedUsers' ,
            results
        );
    }
}