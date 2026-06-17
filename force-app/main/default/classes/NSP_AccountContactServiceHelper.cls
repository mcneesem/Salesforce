public with sharing class NSP_AccountContactServiceHelper {
    // test w/ NSP_AccountContactServiceHelperTest (84%)

    // DEPRECATED ~ See Apex: PortalProvisionAction, PortalClientSharing

    // create the Portal user and update the User Permissions
    // DEPRECATED
    public static void createExternalUser( Map<Id,AccountContactRelation> newACRMap , Map<Id,AccountContactRelation> oldACRMap ) {
        Set<Id> acrContactIdSet = new set<Id>();
        List<User> newUserList = new List<User>();
        Set<Id> userIdSet = new Set<Id>();
        Set<Id> deactivateUserId = new Set<Id>();
        Map<Id,String> mapContactIdUserPerm = new Map<Id,String>();
        Map<Id,Id> mapContactIdUserId = new Map<Id,Id>();
        Map<Id,String> mapConIdCommAccess = new Map<Id,String>();
        Set<Id> removePermUserIdSet = new Set<Id>();
        Set<Id> reactivatedUserIdSet = new Set<Id>();
        Map<Id,Id> mapContactIdInactiveUserId = new Map<Id,Id>();
        Map<Id,String> mapContactIdUserDeactive = new Map<Id,String>();
        Set<Id> permissionIdSet = new Set<Id>();
        Set<Id> inactiveUserIdSet = new Set<Id>();
        try {
            Id communityUserProfileId = [
                SELECT Id
                FROM Profile
                WHERE ( Name = 'Customer Community Plus User' )
            ].Id;
            // fetching all the permission set from the metadata
            Map<String,NSP_Assign_permission_set_to_Community__mdt> assignPermSetMap = NSP_Assign_permission_set_to_Community__mdt.getAll();
            for ( NSP_Assign_permission_set_to_Community__mdt permSet : assignPermSetMap.values() ) {
                permissionIdSet.add( permSet.Permission_Set_Id__c );
            }
            for ( AccountContactRelation acr : newACRMap.values() ) {
                if ( ( acr.NSP_Community_Access__c != null )
                    && acr.NSP_Community_Access__c.contains( 'PEO Projects' )
                    )
                {
                    // create new portal user or activating existing user
                    acrContactIdSet.add( acr.ContactId );
                } else if( ( acr.NSP_Community_Access__c == null )
                    && ( oldACRMap.get( acr.Id ).NSP_Community_Access__c != null )
                    )
                {
                    // deactivate Portal User && removing project Permissions from portal user
                    acrContactIdSet.add( acr.ContactId );
                    mapContactIdUserPerm.put( acr.ContactId , 'RemovePermission' );
                    mapContactIdUserDeactive.put( acr.ContactId , 'DeactivateUser' );
                }
            }
            // fetching list of ACR's for given contact Id
            List<AccountContactRelation> acrList = [
                SELECT
                    Id ,
                    ContactId ,
                    NSP_Community_Access__c
                FROM AccountContactRelation
                WHERE (
                    ( ContactId IN :acrContactIdSet )
                    AND ( NSP_Community_Access__c != null )
                )
            ];
            // creating a map of contact Id and Peo Project Communities
            for ( AccountContactRelation acr : acrList ) {
                if ( acr.NSP_Community_Access__c.contains( 'PEO Projects' ) ) {
                    mapConIdCommAccess.put( acr.ContactId , acr.NSP_Community_Access__c );
                }
            }
            // fetching active portal users
            for ( User portalUser : [
                        SELECT
                            Id ,
                            ContactId ,
                            IsActive
                        FROM User
                        WHERE (
                            ( Profile.Name = 'Customer Community Plus User' )
                            AND ( ContactId IN :acrContactIdSet )
                        )
                    ]
                )
            {
                if ( portalUser.IsActive ) {
                    // creating list of Users to be inserted
                    mapContactIdUserId.put( portalUser.ContactId , portalUser.Id );
                    // creating a list of users to be deactivated
                    if ( acrList.isEmpty()
                        && mapContactIdUserDeactive.containsKey( portalUser.ContactId )
                        && ( mapContactIdUserDeactive.get( portalUser.ContactId ) == 'DeactivateUser' )
                        )
                    {
                        deactivateUserId.add( portalUser.Id );
                    }
                    // creating a list of users where project permission needs to be removed
                    if ( !mapConIdCommAccess.containsKey( portalUser.ContactId )
                        && mapContactIdUserPerm.containsKey( portalUser.ContactId )
                        && ( mapContactIdUserPerm.get( portalUser.ContactId ) == 'RemovePermission' )
                        )
                    {
                        removePermUserIdSet.add( portalUser.Id );
                    }
                } else if ( !portalUser.IsActive ) {
                    // reactivating the existing user
                    reactivatedUserIdSet.add( portalUser.Id );
                    mapContactIdInactiveUserId.put( portalUser.ContactId , portalUser.Id );
                }
            }
            // creating Users for Contacts
            for ( Contact con : [
                        SELECT
                            Id ,
                            NSP_Preferred_First_Name__c ,
                            FirstName ,
                            LastName ,
                            NSP_Work_email__c ,
                            NSP_Per_ID__c
                        FROM Contact
                        WHERE ( Id IN :acrContactIdSet )
                    ]
                )
            {
                if ( ( mapContactIdUserId.isEmpty() && mapContactIdInactiveUserId.isEmpty() )
                    || ( !mapContactIdUserId.containsKey( con.Id ) && !mapContactIdInactiveUserId.containsKey( con.Id ) )
                    )
                {
                    // creating Community User
                    User commUser = NSP_AccountContactServiceHelper.createUser( con , communityUserProfileId );
                    commUser.FederationIdentifier = con.NSP_Per_ID__c;
                    newUserList.add( commUser );
                } else if( mapContactIdInactiveUserId.containsKey( con.Id ) ) {
                    // reactivate deactivated portal Users
                    inactiveUserIdSet.add( mapContactIdInactiveUserId.get( con.Id ) );
                }
            }
            if ( !inactiveUserIdSet.isEmpty() ) {
                NSP_portalUserUpdate.enqueueJob( // queueable
                    reactivatedUserIdSet ,
                    true ,
                    permissionIdSet ,
                    removePermUserIdSet ,
                    permissionIdSet
                );
            }
            if ( !newUserList.isEmpty() ) {
                insert newUserList;
                userIdSet = (new Map<Id,SObject>(newUserList)).keySet();
                NSP_AccountContactServiceHelper.assignPermissionControl( userIdSet ); // future
                NSP_AccountContactServiceHelper.assignUserPerm( userIdSet , permissionIdSet ); // future
            }
            // removing permission set and deactivating the users
            if ( !deactivateUserId.isEmpty() ) {
                NSP_portalUserUpdate.enqueueJob( // queueable
                    deactivateUserId ,
                    false ,
                    permissionIdSet ,
                    removePermUserIdSet ,
                    permissionIdSet
                );
            }
            if ( !removePermUserIdSet.isEmpty() ) {
                NSP_AccountContactServiceHelper.removePermissionControlForDeactivatedUsers( deactivateUserId );
            }
            if ( !reactivatedUserIdSet.isEmpty() ) {
                NSP_AccountContactServiceHelper.assignPermissionControl( reactivatedUserIdSet ); // future
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountContactServiceHelper.class.getName() ,
                'createExternalUser' ,
                e
            );
        }
    }

    // removes the Project Community Permission from User
    // NSP_portalUserUpdate
    // DEPRECATED
    @future
    public static void removeUserPermissions( Set<Id> userIdSet , Set<Id> permIdSet ) {
        List<PermissionSetAssignment> deleteUserPermList = new List<PermissionSetAssignment>();
        for ( PermissionSetAssignment psa : [
                    SELECT Id , PermissionSetId
                    FROM PermissionSetAssignment
                    WHERE ( AssigneeId IN :userIdSet )
                ]
            )
        {
            if ( permIdSet.contains( psa.PermissionSetId ) ) {
                deleteUserPermList.add( psa );
            }
        }
        if ( !deleteUserPermList.isEmpty() ) {
            delete deleteUserPermList;
        }
    }

    // creates new portal user
    private static User createUser( Contact record , Id communityUserProfileId ) {
        String lastName =  record.LastName.replaceAll( '\\s+' , '_' );
        String userName = record.NSP_Work_email__c + '.' + lastName;
        String alias = 'Insp' + record.LastName.substring( 0 , 2 );
        String communityNickname = alias;
        if ( ( record.NSP_Preferred_First_Name__c != null ) && ( record.NSP_Per_ID__c != null ) ) {
            communityNickname = record.NSP_Preferred_First_Name__c.substring( 0 , 1 ) + record.LastName + record.NSP_Per_ID__c;
        }
        User portalUser = new User();
        portalUser.UserName = userName;
        portalUser.FirstName = record.NSP_Preferred_First_Name__c;
        portalUser.LastName = record.LastName;
        portalUser.Alias = alias;
        portalUser.CommunityNickname = communityNickname;
        portalUser.Email = record.NSP_Work_email__c;
        portalUser.ContactId = record.Id;
        portalUser.ProfileId = communityUserProfileId;
        portalUser.EmailEncodingKey = 'UTF-8';
        portalUser.TimeZoneSidKey = 'America/Los_Angeles';
        portalUser.LocaleSidKey = 'en_US';
        portalUser.LanguageLocaleKey = 'en_US';
        return portalUser;
    }

    // assigns Project Community Permissions to User
    private static void assignUserPerm( Set<Id> userIdSet , Set<Id> permIdSet ) {
        NSP_AccountContactServiceHelper.assignUserPermFuture( userIdSet , permIdSet);
    }

    @future
    private static void assignUserPermFuture( Set<Id> userIdSet , Set<Id> permIdSet ) {
        NSP_AccountContactServiceHelper.createUserPerm( userIdSet , permIdSet);
    }

    // NSP_portalUserUpdate
    // DEPRECATED
    public static void createUserPerm( Set<Id> userIdSet , Set<Id> permIdSet ) {
        try {
            List<PermissionSetAssignment> permissionSetList = new List<PermissionSetAssignment>();
            for ( Id usrId : userIdSet ) {
                for ( Id prjCommPermId : permIdSet ) {
                    PermissionSetAssignment psa = new PermissionSetAssignment(
                        PermissionSetId=prjCommPermId ,
                        AssigneeId=usrId
                    );
                    permissionSetList.add( psa );
                }
            }
            if ( !permissionSetList.isEmpty() ) {
                insert permissionSetList;
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountContactServiceHelper.class.getName() ,
                'createUserPerm' ,
                e
            );
        }
    }

    private static pse__Region__c getDefaultRegion() {
        String regionQuery = new NSP_QueryBuilder(
                'pse__Region__c' ,
                new List<String>{ 'Id' , 'Name' }
            )
            .addFilter( 'Name' , NSP_ServiceConstants.UnitedStatesRegion )
            .addLimit( 1 )
            .build()
            ;
        return Database.query( regionQuery );
    }

    private static void assignPermissionControl( Set<Id> userSet ) {
        NSP_AccountContactServiceHelper.assignPermissionControlFuture( userSet );
    }

    @future
    private static void assignPermissionControlFuture( Set<Id> userSet ) {
        try {
            List<pse__Permission_Control__c> lstpermControl = new List<pse__Permission_Control__c>();
            pse__Region__c region = NSP_AccountContactServiceHelper.getDefaultRegion();
            for ( Id userId : userSet ) {
                pse__Permission_Control__c  permissionControl = new pse__Permission_Control__c();
                permissionControl.pse__Region__c = region.Id;
                permissionControl.pse__User__c = userId;
                permissionControl.pse__View_Task_Manager__c = true;
                permissionControl.pse__Edit_Task_Manager__c = true;
                lstpermControl.add( permissionControl );
            }
            if ( !lstpermControl.isEmpty() ) {
                List<Database.UpsertResult> results = Database.upsert( lstpermControl , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AccountContactServiceHelper.class.getName() ,
                    'assignPermissionControlFuture:upsert' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountContactServiceHelper.class.getName() ,
                'assignPermissionControlFuture' ,
                e
            );
        }
    }

    private static void removePermissionControlForDeactivatedUsers( Set<Id> deactivateUserId ) {
        NSP_AccountContactServiceHelper.removePermissionControlForDeactivatedUsersInternal( deactivateUserId );
    }

    private static void removePermissionControlForDeactivatedUsersInternal( Set<Id> deactivateUserId ) {
        String permissionControlQuery = new NSP_QueryBuilder(
                'pse__Permission_Control__c' ,
                new List<String>{ 'Id' }
            )
            .addFilter( 'pse__User__c' , new List<Id>( deactivateUserId ) , NSP_QueryBuilder.Operator.INCLUDES )
            .build()
            ;
        List<pse__Permission_Control__c> lstRecords = Database.query( permissionControlQuery );
        Database.DeleteResult[] results = Database.delete( lstRecords , false );
        NSP_ErrorLogHandler.logResults(
            NSP_AccountContactServiceHelper.class.getName() ,
            'removePermissionControlForDeactivatedUsersInternal' ,
            results
        );
    }

}
//