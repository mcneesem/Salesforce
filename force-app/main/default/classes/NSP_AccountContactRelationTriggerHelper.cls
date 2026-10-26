public with sharing class NSP_AccountContactRelationTriggerHelper {
    // test w/ NSP_AccountContactRelationHelperTest (77%)

    //
    // Iterates throught the list of new AccountContactRelation and passes the required attributes to other methods.
    // @param newList List of New AccountContactRelation.
    // @param newMap List of New AccountContactRelation.
    // @return void
    //
    public void afterInsertDirector( List<AccountContactRelation> newList , Map<Id,AccountContactRelation> newMap ) {
        try {
            Set<Id> portalIds = new Set<Id>();
            Set<Id> accountIdSet = new Set<Id>();
            Map<Id,AccountContactRelation> conIdACRMap = new Map<Id,AccountContactRelation>();
            for ( AccountContactRelation accConObj : newList ) {
                if ( accConObj.Enable_Portal_Client__c ) {
                    portalIds.add( accConObj.Id );
                }
                if ( accConObj.NSP_Is_Primary__c && accConObj.IsActive ) {
                    accountIdSet.add( accConObj.AccountId );
                }
                if ( accConObj.isDirect ) {
                    conIdACRMap.put( accConObj.contactId , accConObj );
                }
            }
            if ( !CustomPermissionController.checkUserPermission( 'Bypass_AccountContactRelation_Directors' , UserInfo.getUserId() ) ) {
                if ( !conIdACRMap.isEmpty() ) {
                    this.updateWorkPhoneEmailOnContact( conIdACRMap );
                }
                IntegrationSyncController.setReadyForIntegrationSync( accountIdSet );
            }
            PortalClientSharing.enqueueJob( portalIds );
        } catch ( Exception e ) {
            NSP_AccountContactRelationTriggerHelper.handleException( e , 'afterInsertDirector' );
        }
    }

    //
    // Iterates throught the list of new AccountContactRelation and passes the required attributes to other methods.
    // @param newList List of New AccountContactRelation.
    // @param newMap List of New AccountContactRelation.
    // @return void
    //
    public void afterUpdateDirector( Map<Id,AccountContactRelation> newMap , Map<Id,AccountContactRelation> oldMap ) {
        try {
            Set<Id> portalIds = new Set<Id>();
            Map<Id,AccountContactRelation> contactOldMap = new Map<Id,AccountContactRelation>();
            Map<Id,AccountContactRelation> contactNewMap = new Map<Id,AccountContactRelation>();
            Map<Id,AccountContactRelation> conIdACRMap = new Map<Id,AccountContactRelation>();
            AccountContactRelation oldACR;
            for ( AccountContactRelation acr : newMap.values() ) {
                oldACR = oldMap.get( acr.Id );
                if ( acr.Enable_Portal_Client__c != oldACR.Enable_Portal_Client__c ) {
                    portalIds.add( acr.Id );
                }
                if( ( acr.NSP_Is_Primary__c && ( oldACR.NSP_Is_Primary__c != acr.NSP_Is_Primary__c ) )
                    || ( acr.IsActive && ( oldACR.IsActive != acr.IsActive ) )
                    )
                {
                    contactOldMap.put( acr.Id , oldACR );
                    contactNewMap.put( acr.Id , newMap.get( acr.Id ) );
                }
                // Added as part of STY-02840
                if ( ( ( acr.isDirect == true )
                        && ( ( oldACR.NSP_Work_Phone__c != acr.NSP_Work_Phone__c )
                            || ( oldACR.NSP_Work_Email__c != acr.NSP_Work_Email__c )
                            || ( oldACR.NSP_Employee_Status__c != acr.NSP_Employee_Status__c )
                            || ( oldACR.NSP_Status_Date__c != acr.NSP_Status_Date__c )
                            || ( oldACR.NSP_Job_Title__c != acr.NSP_Job_Title__c )
                            )
                        )
                    || ( ( acr.isDirect == true )
                        && ( oldACR.isDirect != acr.isDirect )
                        )
                    )
                {
                    conIdACRMap.put( acr.ContactId , acr );
                }
            }
            if ( !CustomPermissionController.checkUserPermission( 'Bypass_AccountContactRelation_Directors' , UserInfo.getUserId() ) ) {
                Set<Id> accountIdSetToUpdateResyncFlag = new Set<Id>();
                NSP_SObjectUpdateTriggerHelper sObjectUpdateObj = new NSP_SObjectUpdateTriggerHelper();
                accountIdSetToUpdateResyncFlag = sObjectUpdateObj.fetchUpdFieldsLst(
                    NSP_IntegrationConstants.SOBJECT_ACCOUNTCONTACTRELATION ,
                    contactNewMap ,
                    contactOldMap
                );
                IntegrationSyncController.setReadyForIntegrationSync( accountIdSetToUpdateResyncFlag );
                if ( !conIdACRMap.isEmpty() ) {
                    this.updateWorkPhoneEmailOnContact( conIdACRMap );
                }
            }
            PortalClientSharing.enqueueJob( portalIds );
        } catch ( Exception e ) {
            NSP_AccountContactRelationTriggerHelper.handleException( e , 'afterUpdateDirector' );
        }
    }

    //
    // MethodName: beforeUpsertDirector
    // Description: This method will add the validation to not to create more than One ACR for an Account
    // Params: List<AccountContactRelation> newList
    //
    public static void beforeUpsertDirector( List<AccountContactRelation> newList ) {
        try {
            if (!CustomPermissionController.checkUserPermission( 'Bypass_Primary_Contact_Validation', UserInfo.getUserId() )){
                Set<Id> accountIdSet = new Set<Id>();
                for(AccountContactRelation accConObj : newList){
                    if(accConObj.NSP_Is_Primary__c){
                        accountIdSet.add(accConObj.AccountId);
                    }
                }
                Map<Id,AccountContactRelation> accountContactRelationMap= new Map<Id,AccountContactRelation>([Select Id ,ContactId ,NSP_Is_Primary__c, AccountId from AccountContactRelation WHERE AccountId IN:accountIdSet AND NSP_Is_Primary__c = True ]);
                for(AccountContactRelation accConObj : newList){
                    if(accountContactRelationMap.size() > 0 && !accountContactRelationMap.containsKey(accConObj.Id)  ){
                           accConObj.NSP_Is_Primary__c.addError(System.label.NSP_PrimaryContactValidation);
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_AccountContactRelationTriggerHelper.handleException( e , 'beforeUpsertDirector' );
        }
    }

    //
    // MethodName: updateJobTitleofContact
    // Description : This method will update the contact job title from ACR
    // Params: AccountContactRelation newMap and oldMap
    //
    public void afterInsertJobTitle( List<AccountContactRelation> newList , Map<Id,AccountContactRelation> newMap ) {
        Set<Id> contactIdSet = new Set<Id>();
        for(AccountContactRelation accConObj : newList){
            if(accConObj.NSP_Job_Title__c!=null ){
                contactIdSet.add(accConObj.ContactId);
            }
        }
        updateJobTitleofContact(contactIdSet);
    }

    //
    // Iterates throught the list of new AccountContactRelation and passes the required attributes to other methods.
    // @param newList List of New AccountContactRelation.
    // @param newMap List of New AccountContactRelation.
    // @return void
    //
    public void afterUpdateJobTitle( Map<Id,AccountContactRelation> newMap , Map<Id,AccountContactRelation> oldMap ) {
        Set<Id> contactIdSet = new Set<Id>();
        for(AccountContactRelation accConObj : newMap.values()){
            if(accConObj.NSP_Job_Title__c!=oldMap.get(accConObj.Id).NSP_Job_Title__c ){
                contactIdSet.add(accConObj.ContactId);
            }
        }
    }

    public void updateJobTitleofContact( Set<Id> contactIdset ) {
        Map<Id, String> mapOfcontactJobTitles = new Map<Id,String>();
        List<Contact> contactList = new List<Contact>();
        try{
            if(!contactIdSet.isEmpty()){
                for(AccountContactRelation accConObj : [SELECT Id,ContactId, NSP_Job_Title__c FROM AccountContactRelation WHERE ContactId in:contactIdSet and NSP_Job_Title__c!=null ]){
                    mapOfcontactJobTitles.put(accConObj.ContactId,accConObj.NSP_Job_Title__c);
                }
            }
            if(!mapOfcontactJobTitles.isEmpty()){
                for(Contact con: [SELECT Id, NSP_Job_Title__c FROM Contact WHERE Id in:contactIdset]){
                    con.NSP_Job_Title__c=mapOfcontactJobTitles.get(con.Id);
                    contactList.add(con);
                }
            }
            if(!contactList.isEmpty()){
                update contactList;
            }
        } catch ( Exception e ) {
            NSP_AccountContactRelationTriggerHelper.handleException( e , 'updateJobTitleofContact' );
        }
    }

    //
    // @description getUserIdProfileNames description
    // @param userIds created or Updated userids
    // @return mapofuserids with the Profileid and ProfileName
    //
    private static Map<Id,User> getUserIdProfileNames( Set<Id> userIds ) {
        return new Map<Id,User>(
            [
                SELECT Id , Name , ProfileId , Profile.Name
                FROM User
                WHERE ( Id IN :userIds )
            ]
        );
    }

    //
    // @description as Service user restrict ACR deletion if it is createdby IntegrationUser and as CommunityAccess value.
    // @param  lstAccConRelations trigger.Old values of AccountContactRelationshipRecords
    //
    public static void restrictDeletingACR( List<AccountContactRelation> lstAccConRelations ) {
        try {
            Set < Id > userIds = new Set < Id > {
                UserInfo.getUserId()
            };
            List < String > lstServiceProfiles = new List < String > {
                NSP_ServiceConstants.PEOSERVICE,
                NSP_ServiceConstants.RT,
                NSP_ServiceConstants.CONTACTCENTER,
                NSP_ServiceConstants.BPSSERVICE,
                NSP_ServiceConstants.SYSTEM_ADMINISTRATOR
            };
            for (AccountContactRelation acr: lstAccConRelations) {
                userIds.add(acr.CreatedbyId);
                userIds.add(acr.LastModifiedById);
            }
            //throw a validation when service user tries to delete ACR with has not createdBy or UpdatedBy Integration user
            Map<Id,User> mapOfusers = getUserIdProfileNames(userIds);
            for (AccountContactRelation acr: lstAccConRelations) {
                User currentUser = mapOfusers.get(UserInfo.getUserId());
                if (String.isNotBlank(acr.NSP_Community_Access__c) && lstServiceProfiles.contains(currentUser.Profile.Name) &&
                    (mapOfusers.get(acr.CreatedById)?.Profile?.Name != NSP_ServiceConstants.INTEGRATION_USER || mapOfusers.get(acr.LastModifiedById)?.Profile?.Name != NSP_ServiceConstants.INTEGRATION_USER)
                    )
                {
                    acr.addError(label.NSP_ACR_DeleteValidation); // DEPRECATED
                } else if (String.isBlank(acr.NSP_Community_Access__c) && lstServiceProfiles.contains(currentUser.Profile.Name) &&
                    (mapOfusers.get(acr.CreatedById)?.Profile?.Name == NSP_ServiceConstants.INTEGRATION_USER  || mapOfusers.get(acr.LastModifiedById)?.Profile?.Name == NSP_ServiceConstants.INTEGRATION_USER)
                    )
                {
                    acr.addError(label.NSP_No_Access); // DEPRECATED
                }
            }
        } catch ( Exception e ) {
            NSP_AccountContactRelationTriggerHelper.handleException( e , 'restrictDeletingACR' );
        }
    }

    //
    // @MethodName: updateWorkPhoneEmailOnContact
    // @Description: This method describes to update the Contact when ever Contact's Email and Work Phone.
    // @param : Map<Id, AccountContactRelation> ConIdACRMap
    // @createdDate : 12/14/2022
    // @Story : STY-02840
    // @return void
    //
    public static void updateWorkPhoneEmailOnContact( Map<Id,AccountContactRelation> ConIdACRMap ) {
        try {
            List<Contact> conList = new List<Contact>();
            Id integrationProfileId = '00e4x0000012vOHAAY'; // Profile: Integration User
            List<Contact> contactList = [
                SELECT
                    Id, NSP_Work_email__c, NSP_Work_Phone__c, CreatedById, NSP_Employee_Status__c,
                    NSP_Status_Date__c, NSP_Job_Title__c, CreatedBy.ProfileId
                FROM Contact
                WHERE (
                    Id IN :ConIdACRMap.keySet()
                    AND CreatedBy.ProfileId != :integrationProfileId
                    AND NSP_isContactInsertion__c != True
                )
            ];
            for(Contact con : contactList){
                AccountContactRelation acr = ConIdACRMap.get(con.Id);
                con.NSP_Work_email__c = acr.NSP_Work_Email__c;
                con.NSP_Work_Phone__c = acr.NSP_Work_Phone__c;
                con.NSP_Employee_Status__c = acr.NSP_Employee_Status__c;
                con.NSP_Status_Date__c = acr.NSP_Status_Date__c;
                con.NSP_Job_Title__c = acr.NSP_Job_Title__c;
                conList.add(con);
            }
            if ( !conList.isEmpty() ) {
                update conList ;  // Do not change to Database.update...
            }
        } catch ( Exception e ) {
            NSP_AccountContactRelationTriggerHelper.handleException( e , 'updateWorkPhoneEmailOnContact' );
        }
    }

    //
    // @MethodName: createPlatformEventForACR
    // @Description: This method is used to Create Platform Event on after Insert Or Update
    // @param :List<AccountContactRelation> newList, Map<Id, AccountContactRelation> oldMap
    // @createdDate : 12/12/2022
    // @Defect : STY-03783 AND STY-03782
    // @return void
    //
    // DEPRECATED
    public static void createPlatformEventForACR( List<AccountContactRelation> newList , Map<Id,AccountContactRelation> oldMap ) {
        List<NSP_Community_Access_Event__e> communityEventToBeInserted = new  List<NSP_Community_Access_Event__e>();
        List<AccountContactRelation> updatedList = [
            SELECT Id, Account.NSP_AIMS_Client__c, AccountId, ContactId, Contact.NSP_PER_ID__c,NSP_Community_Access__c
            FROM AccountContactRelation
            WHERE Id IN: newList
        ];
        // get exist ACR Ids
        for(AccountContactRelation acr : updatedList) {
            //After Insert and Community Access is PEO Projects
            if( (oldMap == null && (acr.NSP_Community_Access__c == NSP_ServiceConstants.peoCommunityAccess)) ||
                (oldMap != null && acr.NSP_Community_Access__c != oldMap.get(acr.Id).NSP_Community_Access__c && acr.NSP_Community_Access__c == NSP_ServiceConstants.peoCommunityAccess)
                )
            {
                NSP_Community_Access_Event__e communityEvent = New NSP_Community_Access_Event__e();
                communityEvent.NSP_AIMS_Client__c = acr.Account.NSP_AIMS_Client__c;
                communityEvent.NSP_Community_Access__c = acr.NSP_Community_Access__c;
                communityEvent.NSP_PER_ID__c = acr.Contact.NSP_PER_ID__c;
                communityEvent.NSP_Operation__c = 'Add';
                communityEventToBeInserted.add(communityEvent);
            }
            if((oldMap != null && oldMap.get(acr.Id).NSP_Community_Access__c == NSP_ServiceConstants.peoCommunityAccess && acr.NSP_Community_Access__c != NSP_ServiceConstants.peoCommunityAccess)
                )
            {
                NSP_Community_Access_Event__e communityEvent = New NSP_Community_Access_Event__e();
                communityEvent.NSP_AIMS_Client__c = acr.Account.NSP_AIMS_Client__c;
                communityEvent.NSP_Community_Access__c = acr.NSP_Community_Access__c;
                communityEvent.NSP_PER_ID__c = acr.Contact.NSP_PER_ID__c;
                communityEvent.NSP_Operation__c = 'Remove';
                communityEventToBeInserted.add(communityEvent);
            }
        }
        if ( !communityEventToBeInserted.isEmpty() ) { // DEPRECATED
            List<Database.SaveResult> results = EventBus.publish( communityEventToBeInserted );
            NSP_ErrorLogHandler.logResults(
                NSP_AccountContactRelationTriggerHelper.class.getName() ,
                'createPlatformEventForACR' ,
                results
            );
        }
    }

    //
    // Iterates throught the list of old AccountContactRelation and passes the required attributes to other methods.
    // @param lstAccConRelations List of  AccountContactRelation.
    // @return void
    //
    public static void afterDeleteDirector( List<AccountContactRelation> lstAccConRelations ) {
        Set<Id> portalIds = new Set<Id>();
        for ( AccountContactRelation acr : lstAccConRelations ) {
            if ( acr.Enable_Portal_Client__c ) {
                portalIds.add( acr.AccountId );
            }
        }
        PortalClientSharing.enqueueJob( portalIds );
    }

    //
    // Method Name : getLoggedInUserProfile
    // Description : STY-02849/DF-05013 Method to get loggedin user profile
    // @return List<Profile>
    //
    public static List<Profile> getLoggedInUserProfile() {
        List<String> profileFields = new List<String>{'Id','Name'};
        String queryProfile = new NSP_QueryBuilder('Profile', profileFields)
            .addFilter('Id', UserInfo.getProfileId())
            .setSecurityEnforce(false)
            .build();
        return Database.query(queryProfile);
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_AccountContactRelationTriggerHelper.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_AccountContactRelationTriggerHelper.class.getName() ,
            methodName ,
            e
        );
    }

}
//