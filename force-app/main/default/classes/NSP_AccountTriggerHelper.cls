public class NSP_AccountTriggerHelper {
    // test w/ NSP_AccountTriggerHelperTest, NSP_AccountContactRelationHelperTest, NSP_AccountContactServiceHelperTest (80%)
    // test w/ NSP_AccountTriggerHelperTest, NSP_LeadTriggerHelperTest (79%)
    // test w/ NSP_AccountTriggerHelperTest (78%)
    // test w/ NSP_AccountContactRelationHelperTest (34%)
    // test w/ NSP_AccountContactServiceHelperTest (38%)
    // test w/ NSP_OpportunityTriggerHelperTest (30%)

    private static Set<String> lockedSalesSegments = new Set<String>{
        NSP_SalesConstants.MIDMARKET_SALES ,
        NSP_SalesConstants.WS ,
        NSP_SalesConstants.ENTERPRISE_SALES
    };
    private static final Id PARTNER_RECORDTYPE_ID = NSP_GenericRecordType.getRecordTypeId( 'Account' , 'NSP_Partner_Client' );
    private static final String DA_ROLE = 'District Administrator';
    //Added as part of 128176
    private static List<String> salesRoles = System.Label.Sales_Roles.split( ',' );
    // Added as part of 194459
    private static List<String> MMRoles = System.Label.NSP_MidMarket_Roles.split( ',' );
    // Added as part of 215091
    private static Boolean hasPartnerLoyaltyPermission = CustomPermissionController.checkUserPermission( 'Account_Partner_Update_Loyalty_from_SO' , UserInfo.getUserId() );
    private static Boolean hasPartnerMMPermission = CustomPermissionController.checkUserPermission( 'Account_Partner_MidMarket_Seller' , UserInfo.getUserId() );

    // Iterates throught the list of new Account and passes the required attributes to other methods.
    public void beforeInsertDirector( List<Account> newList ) {
        try {
            List<Account> bpaAccountList = new List<Account>();
            Set<String> salesOfficeSet = new Set<String>();
            List<Account> acctListToStampDocusignTemplateId = new List<Account>();
            for ( Account accountObj: newList ) {
                // populate CPM and LA based on Sales office of loggedin BPA
                if ( accountObj.RecordTypeId == PARTNER_RECORDTYPE_ID ) {
                    accountObj.NSP_Partner_Lifecycle__c = NSP_SalesConstants.EVALUATION;
                }
                if ( ( accountObj.RecordTypeId == PARTNER_RECORDTYPE_ID )
                    && hasPartnerLoyaltyPermission
                    && String.isNotBlank( NSP_AccountTriggerHelper.currentUserSalesOffice )
                    )
                {
                    bpaAccountList.add( accountObj );
                    salesOfficeSet.add( NSP_AccountTriggerHelper.currentUserSalesOffice );
                }
                this.checkPartner( accountObj );
                // create list to populate docusign template id for merge on demand templates
                if ( !String.isBlank( accountObj.NSP_Template_Selection__c ) ) {
                    acctListToStampDocusignTemplateId.add( accountObj );
                }
                // bypass sales segment - ADO-334282
                Boolean hasBypassSalesSegment = CustomPermissionController.checkUserPermission( 'Bypass_Sales_Segment' , UserInfo.getUserId() );
                if ( !( hasBypassSalesSegment && lockedSalesSegments.contains( accountObj.NSP_Account_Segment__c ) ) ) {
                    NSP_AccountTriggerHelper.updateAccountSegment( accountObj );
                }
            }
            this.assignReadyForIntegrationSync( newList ); // DEPRECATED
            if ( !bpaAccountList.isEmpty() ) {
                NSP_AccountTriggerHelper.setChannelPartnerAndLoyaltyAdvisor( bpaAccountList , salesOfficeSet );
            }
            this.setDummyUsers( acctListToStampDocusignTemplateId );
            this.setSalesOfficeDetails( newList , null );
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'beforeInsertDirector' );
        }
    }

    // Prevent LimitExceptions: Too many SOQL queries: 101
    private static String currentUserSalesOffice {
        private get {
            if ( currentUserSalesOffice == null ) {
                List<User> currentUserDetails = [
                    SELECT
                        Id ,
                        Name ,
                        UserRole.Name ,
                        ToLabel(NSP_Sales_Office__c)
                    FROM User
                    WHERE ( Id = :Userinfo.getUserId() )
                ];
                String local = '';
                if ( ( currentUserDetails != null ) && !currentUserDetails.isEmpty() ) {
                    local = currentUserDetails[0].NSP_Sales_Office__c;
                }
                currentUserSalesOffice = local;
            }
            return currentUserSalesOffice;
        }
        private set;
    }

    private void checkPartner(Account accountObj){
        if ( ( accountObj.RecordTypeId==PARTNER_RECORDTYPE_ID )
             && ( hasPartnerMMPermission )
           )
        {
            accountObj.NSP_Channel_Program_Manager__c = System.Label.NSP_CPM_USER;
        }
    }

    //
    // Iterates throught the Account map and identifies the records that needs to worked based on various criterias.
    // @param accountNewMap Map of New Account.
    // @param accountOldMap Map of Old Account.
    // @return void
    //
    //
    //Moved out of beforeUpdateDirector to fix SOQL issue _ DF-04068
    public void accountUpdate( Map<Id,Account> accountNewMap , Map<Id,Account> accountOldMap ) {
        try {
            Boolean isSalesManager = ( UserInfo.getProfileId() == '00e4x0000012vORAAY' ); // Sales Manager
            List<PermissionSetAssignment> getPermSet = new List<PermissionSetAssignment>();
            if ( isSalesManager ) {
                getPermSet = [
                    SELECT
                        Id ,
                        PermissionSetId ,
                        PermissionSet.Name ,
                        AssigneeId
                    FROM PermissionSetAssignment
                    WHERE (
                        ( Assignee.IsActive = true )
                        AND ( AssigneeId = :UserInfo.getUserId() )
                        AND (
                            PermissionSetId IN (
                                SELECT ParentId
                                FROM ObjectPermissions
                                WHERE (
                                    ( SObjectType = 'Account' )
                                    AND ( PermissionsModifyAllRecords = true )
                                )
                            )
                        )
                    )
                ];
            }
            Boolean hasNamedAccountGroupBypass = CustomPermissionController.checkUserPermission(
                'Named_Account_Group_Bypass_Restrictions',
                UserInfo.getUserId()
            );
            Boolean hasAllowUpdateMMRole = CustomPermissionController.checkUserPermission(
                'Allow_Update_MidMarket_Role',
                UserInfo.getUserId()
            );
            //Added as part of 128176
            // Modified on 02/2023-part of 194459- Bypass for MM roles
            if ( !hasNamedAccountGroupBypass
                && !hasAllowUpdateMMRole
                && isSalesManager
                && ( !getPermSet.isEmpty() || Test.isRunningTest() )
                )
            {
                this.restrictAccountChange( accountNewMap , accountOldMap , null );
            }
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'accountUpdate' );
        }
    }

    // Iterates through the Account map and identifies the records that needs to worked based on various criterias.
    public void beforeUpdateDirector( Map<Id,Account> accountNewMap , Map<Id,Account> accountOldMap ) {
        try {
            List<Account> accountList = new List<Account>();
            List<Account> accountownerChangedList = new List<Account>();
            List<Account> partnerAccountList = new List<Account>();
            Set<Id> userIdsSet = new Set<Id>();
            List<Account> acctListToStampDocusignTemplateId = new List<Account>();
            //Iterating over the new Account map
            for ( Id accountId : accountNewMap.keySet() ) {
                Account newAccount = accountNewMap.get( accountId );
                Account oldAccount = accountOldMap.get( accountId );
                if ( String.isNotBlank( newAccount.NSP_Account_Status__c )
                    && newAccount.NSP_Account_Status__c.equals( NSP_SalesConstants.ACTIVE )
                    && ( newAccount.NSP_Account_Status__c != oldAccount.NSP_Account_Status__c )
                    )
                {
                    accountList.add( newAccount );
                }
                if ( newAccount.OwnerId != oldAccount.OwnerId ) {
                    accountownerChangedList.add( newAccount );
                }
                //  Adding Enterpise sales segment - ADO-334282
                if ( ( newAccount.NumberOfEmployees != oldAccount.NumberOfEmployees )
                    && !lockedSalesSegments.contains( oldAccount.NSP_Account_Segment__c )
                    )
                {
                    NSP_AccountTriggerHelper.updateAccountSegment( newAccount );
                }
                //create list to populate docusign template id for merge on demand templates
                if ( !String.isBlank( newAccount.NSP_Template_Selection__c )
                    && ( newAccount.NSP_Template_Selection__c != oldAccount.NSP_Template_Selection__c )
                    )
                {
                    acctListToStampDocusignTemplateId.add( newAccount );
                }
                //cherwel ticket 556472
                if ( ( newAccount.NSP_Partner_Lifecycle__c != oldAccount.NSP_Partner_Lifecycle__c )
                    && ( newAccount.NSP_Partner_Lifecycle__c == NSP_SalesConstants.ONBOARDING )
                    )
                {
                    newAccount.NSP_Onboarding_Contract_Date__c = System.today();
                }
            }

            if ( !accountList.isEmpty() ) {
                this.setAccountStage( accountList );
            }
            if ( !accountownerChangedList.isEmpty() ) {
                this.setAccountStageWhenOwnerChanged( accountownerChangedList );
            }
            this.assignReadyForIntegrationSync( accountNewMap , accountOldMap ); // DEPRECATED
            this.setDummyUsers( acctListToStampDocusignTemplateId );
            this.setSalesOfficeDetails( accountNewMap.values() , accountOldMap );
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'beforeUpdateDirector' );
        }
    }

    // Iterates through the list of new Account and passes the required attributes to other methods.
    public void afterInsertDirector( List<Account> newList , Map<Id,Account> newMap ) {
        try {
            // Iterating Trigger.new to feed the Account Id to Event List
            Set<Id> integrationSyncIds = new Set<Id>();
            for ( Account accObj : newList ) {
                integrationSyncIds = this.collectIntegrationSyncIds( accObj , integrationSyncIds ); // DEPRECATED
            }
            // Send the list to publish event bus
            this.publishIntegrationSyncEvents( // DEPRECATED
                integrationSyncIds ,
                NSP_AccountTriggerHelper.isEnabledIntegrationAccountEvent
            );
            // publish sync events for all new accounts...
            this.publishNewRecords( newList );
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'afterInsertDirector' );
        }
    }

    // Iterates throught the list of new Account and passes the required attributes to other methods.
    public void afterUpdateDirector( Map<Id,Account> newMap , Map<Id,Account> oldMap ) {
        try {
            List<Account> accountList = new List<Account>(); // list to store accounts to handle Tasks when Partner contract is generated
            Map<Id,DateTime> accountTeamMDeleteMap = new Map<Id,DateTime>();
            Map<Id,String> accountTeamMDelete = new Map<Id,String>();
            //Added for User Story - 194644
            List<Account> updateAddressAccountList = new List<Account>();
            Set<Id> integrationSyncIds = new Set<Id>();
            for ( Account accObj : newMap.values() ) {
                integrationSyncIds = this.collectIntegrationSyncIds( accObj , integrationSyncIds ); // DEPRECATED
                Account oldAccount = oldMap.get( accObj.Id );
                if ( ( accObj.NSP_Partner_Lifecycle__c != oldAccount.NSP_Partner_Lifecycle__c )
                    && ( accObj.RecordTypeId == PARTNER_RECORDTYPE_ID )
                    && ( ( accObj.NSP_Partner_Lifecycle__c == NSP_SalesConstants.ACTIVE )
                        || ( accObj.NSP_Partner_Lifecycle__c == NSP_SalesConstants.ONBOARDING )
                        )
                    )
                {
                    accountList.add( accObj );
                }
                //Added for User Story - 194644
                if ( ( accObj.BillingCity != oldAccount.BillingCity )
                    || ( accObj.BillingState != oldAccount.BillingState )
                    || ( accObj.BillingCountry != oldAccount.BillingCountry )
                    || ( accObj.BillingStreet != oldAccount.BillingStreet )
                    || ( accObj.BillingStateCode != oldAccount.BillingStateCode )
                    || ( accObj.BillingPostalCode != oldAccount.BillingPostalCode)
                    )
                {
                    updateAddressAccountList.add( accObj );
                }
            }
            // Send the list to publish event bus
            this.publishIntegrationSyncEvents( // DEPRECATED
                integrationSyncIds ,
                NSP_AccountTriggerHelper.isEnabledIntegrationAccountEvent
            );
            // publish sync events for critically modified accounts...
            this.publishCriticalRecords( newMap , oldMap );
            NSP_OpportunityTriggerHelperFunctions.updateOppOwnerPremier( newMap , oldMap );

            if ( !accountList.isEmpty() ) {
                NSP_AccountTriggerHelper.handleTaskForPartnerContracts( accountList );
            }
            if ( !updateAddressAccountList.isEmpty() ) {
                NSP_AccountTriggerHelper.updateAddressOnCheckList( updateAddressAccountList , newMap );
            }
            NSP_AccountTriggerHelper.updateAGMPayrollEmployees( newMap , oldMap );
            NSP_AccountTriggerHelper.updateAGMNumberOfEmployees( newMap , oldMap );
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'afterUpdateDirector' );
        }
    }

    public void setAccountStage(List < Account > accountList) {
        for (Account accountObj: accountList) {
            List < String > profileList = Label.NSP_Sales_Profiles.split(',');
            if (profileList.contains(accountObj.NSP_Account_Owners_Profile__c)) {
                if (String.isNotBlank(accountObj.NSP_Stage__c) && (accountObj.NSP_Stage__c.equalsIgnoreCase(NSP_SalesConstants.STR_NEW) ||
                        accountObj.NSP_Stage__c.equalsIgnoreCase(NSP_SalesConstants.AVAILABLE))) {
                    accountObj.NSP_Stage__c = NSP_SalesConstants.ASSIGNED;
                }
            } else {
                if (String.isNotBlank(accountObj.NSP_Stage__c) && (accountObj.NSP_Stage__c.equalsIgnoreCase(NSP_SalesConstants.STR_NEW))) {
                    accountObj.NSP_Stage__c = NSP_SalesConstants.AVAILABLE;
                }
            }
        }
    }

    public void setAccountStageWhenOwnerChanged(List < Account > accountList) {
        for (Account accountObj: accountList) {
            List < String > profileList = Label.NSP_Sales_Profiles.split(',');
            if (profileList.contains(accountObj.NSP_Account_Owners_Profile__c)) {
                if (String.isNotBlank(accountObj.NSP_Stage__c) && accountObj.NSP_Stage__c.equals(NSP_SalesConstants.AVAILABLE)) {
                    accountObj.NSP_Stage__c = NSP_SalesConstants.ASSIGNED;
                }
            }
        }
    }

    //
    // Integration Sync Methods
    //

    // DEPRECATED
    // Account-before-insert
    private void assignReadyForIntegrationSync( List<Account> records ) {
        // sync cloned accounts...
        if ( NSP_AccountTriggerHelper.isEnabledDmlAccounts
            && ( records != null )
            && !records.isEmpty()
            )
        {
            for ( Account record : records ) {
                if ( record.isClone() ) {
                    record.NSP_Ready_for_Integration_Sync__c = true; // DEPRECATED
                }
            }
        }
    }

    // DEPRECATED
    // Account-before-update
    private void assignReadyForIntegrationSync( Map<Id,Account> accountNewMap , Map<Id,Account> accountOldMap ) {
        if ( NSP_AccountTriggerHelper.isEnabledDmlAccounts ) {
            // sync accounts with critical field changes...
            Set<Id> accountIdSetToUpdateResyncFlag = new Set<Id>();
            NSP_SObjectUpdateTriggerHelper sObjectUpdateObj = new NSP_SObjectUpdateTriggerHelper();
            accountIdSetToUpdateResyncFlag.addAll(
                sObjectUpdateObj.fetchUpdFieldsLst(
                    'Account' ,
                    (Map<Id,sObject>)accountNewMap ,
                    (Map<Id,sObject>)accountOldMap
                )
            );
            if ( !accountIdSetToUpdateResyncFlag.isEmpty() ) {
                for ( Id recordId : accountIdSetToUpdateResyncFlag ) {
                    accountNewMap.get( recordId ).NSP_Ready_for_Integration_Sync__c = true; // DEPRECATED
                }
            }
        }
    }

    // DEPRECATED
    // Account-after-insert
    // Account-after-update
    private Set<Id> collectIntegrationSyncIds( Account record , Set<Id> syncIds ) {
        if ( NSP_AccountTriggerHelper.isEnabledDmlAccounts
            && ( syncIds != null )
            && ( record != null )
            && record.NSP_Ready_for_Integration_Sync__c // DEPRECATED
            )
        {
            syncIds.add( record.Id );
        }
        return syncIds;
    }

    // Account-after-insert
    private void publishNewRecords( List<Account> records ) {
        // publish sync events for all new accounts...
        if ( !NSP_AccountTriggerHelper.isEnabledDmlAccounts ) {
            Set<Id> syncIds = new Set<Id>();
            if ( ( records != null ) && !records.isEmpty() ) {
                for ( Account record : records ) {
                    syncIds.add( record.Id );
                }
            }
            this.publishIntegrationSyncEvents(
                syncIds ,
                NSP_AccountTriggerHelper.isEnabledIntegrationAccountEvent ,
                false
            );
        }
    }

    // Account-after-update
    private void publishCriticalRecords( Map<Id,Account> accountNewMap , Map<Id,Account> accountOldMap ) {
        // publish sync events for critically modified accounts...
        if ( !NSP_AccountTriggerHelper.isEnabledDmlAccounts ) {
            this.publishIntegrationSyncEvents(
                this.identifyCriticalRecordIds( accountNewMap , accountOldMap ) ,
                NSP_AccountTriggerHelper.isEnabledIntegrationAccountEvent ,
                false
            );
        }
    }

    // identify accounts with critical field changes...
    private Set<Id> identifyCriticalRecordIds( Map<Id,Account> accountNewMap , Map<Id,Account> accountOldMap ) {
        Set<Id> criticalRecordIds = new Set<Id>();
        if ( ( accountNewMap != null ) && ( accountOldMap != null ) ) {
            NSP_SObjectUpdateTriggerHelper sObjectUpdateObj = new NSP_SObjectUpdateTriggerHelper();
            criticalRecordIds.addAll(
                sObjectUpdateObj.fetchUpdFieldsLst(
                    'Account' ,
                    (Map<Id,sObject>)accountNewMap ,
                    (Map<Id,sObject>)accountOldMap
                )
            );
        }
        return criticalRecordIds;
    }

    // AccountContactRelation-after-insert
    // AccountContactRelation-after-update
    // AccountTeamMember-after-insert
    // AccountTeamMember-after-update
    // NSP_Account_Team__c-after-insert
    // NSP_Account_Team__c-after-update
    // Contact-before-update
    public static void setReadyForIntegrationSync( Set<Id> syncIds ) {
        if ( ( syncIds != null ) && !syncIds.isEmpty() ) {
            if ( NSP_AccountTriggerHelper.isEnabledDmlRelatedAccounts ) {
                List<Account> records = new List<Account>();
                for ( Id syncId : syncIds ) {
                    Account record = new Account();
                    record.Id = syncId;
                    record.NSP_Ready_for_Integration_Sync__c = true;
                    records.add( record );
                }
                if ( !records.isEmpty() ) {
                    Database.update( records );
                }
            } else {
                NSP_AccountTriggerHelper helper = new NSP_AccountTriggerHelper();
                helper.publishIntegrationSyncEvents(
                    syncIds ,
                    NSP_AccountTriggerHelper.isEnabledIntegrationAccountEvent ,
                    false
                );
            }
        }
    }

    // DEPRECATED
    // Account-after-insert
    // Account-after-update
    private void publishIntegrationSyncEvents( Set<Id> syncIds , Boolean isEnabled ) {
        if ( NSP_AccountTriggerHelper.isEnabledDmlAccounts ) {
            this.publishIntegrationSyncEvents(
                syncIds ,
                isEnabled ,
                true
            );
        }
    }

    private void publishIntegrationSyncEvents( Set<Id> syncIds , Boolean isEnabled , Boolean isEnabledDml ) {
        if ( isEnabled
            && ( syncIds != null )
            && !syncIds.isEmpty()
            )
        {
            List<sObject> eventList = new List<sObject>();
            List<Account> records = new List<Account>();
            for ( Id syncId : syncIds ) {
                eventList.add(
                    new Integration_Account_Event__e(
                        Id__c=syncId
                    )
                );
                if ( isEnabledDml ) {
                    records.add(
                        new Account(
                            Id=syncId
                        )
                    );
                }
            }
            this.publishEventBus( eventList , records );
        }
    }

    private void publishEventBus( List<sObject> eventList ) {
        this.publishEventBus( eventList , null );
    }

    // Iterates throught the event list publish the records in event bus.
    private void publishEventBus( List<sObject> eventList , List<Account> records ) {
        try {
            if ( ( eventList != null ) && !eventList.isEmpty() ) {
                // Publishing records Event
                List<Database.SaveResult> results = EventBus.publish( eventList );
                NSP_ErrorLogHandler.logResults(
                    NSP_AccountTriggerHelper.class.getName() ,
                    'publishEventBus:publish' ,
                    results
                );
            }
            if ( ( records != null ) && !records.isEmpty() ) {
                List<Account> updateResyncFlagAccountList = new List<Account>();
                for ( Account record : records ) {
                    Account tempRecord = new Account();
                    tempRecord.Id = record.Id;
                    tempRecord.NSP_Ready_for_Integration_Sync__c = false; // DEPRECATED
                    updateResyncFlagAccountList.add( tempRecord );
                }
                if ( !updateResyncFlagAccountList.isEmpty() ) {
                    List<Database.SaveResult> results = Database.update( updateResyncFlagAccountList , false );
                    NSP_ErrorLogHandler.logResults(
                        NSP_AccountTriggerHelper.class.getName() ,
                        'publishEventBus:update' ,
                        results
                    );
                }
            }
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'publishEventBus' );
        }
    }

    //
    // Custom Settings
    //

    private static PlatformEventSettings__c platformEventSettings {
        private get {
            if ( platformEventSettings == null ) {
                platformEventSettings = PlatformEventSettings__c.getInstance( UserInfo.getUserId() );
            }
            return platformEventSettings;
        }
        private set;
    }

    private static Boolean isEnabledDmlAccounts {
        private get {
            if ( isEnabledDmlAccounts == null ) {
                Boolean local = false;
                if ( NSP_AccountTriggerHelper.platformEventSettings != null ) {
                    local = NSP_AccountTriggerHelper.platformEventSettings.IsEnabled_DmlAccounts__c;
                }
                isEnabledDmlAccounts = local;
            }
            return isEnabledDmlAccounts;
        }
        private set;
    }

    private static Boolean isEnabledDmlRelatedAccounts {
        private get {
            if ( isEnabledDmlRelatedAccounts == null ) {
                Boolean local = false;
                if ( NSP_AccountTriggerHelper.platformEventSettings != null ) {
                    local = NSP_AccountTriggerHelper.platformEventSettings.IsEnabled_DmlRelatedAccounts__c;
                }
                isEnabledDmlRelatedAccounts = local;
            }
            return isEnabledDmlRelatedAccounts;
        }
        private set;
    }

    private static Boolean isEnabledIntegrationAccountEvent {
        private get {
            if ( isEnabledIntegrationAccountEvent == null ) {
                Boolean local = false;
                if ( NSP_AccountTriggerHelper.platformEventSettings != null ) {
                    local = NSP_AccountTriggerHelper.platformEventSettings.IsEnabled_IntegrationAccountEvent__c;
                }
                isEnabledIntegrationAccountEvent = local;
            }
            return isEnabledIntegrationAccountEvent;
        }
        private set;
    }

    private static Boolean isEnabledIntegrationAccountDeleteEvent {
        private get {
            if ( isEnabledIntegrationAccountDeleteEvent == null ) {
                Boolean local = false;
                if ( NSP_AccountTriggerHelper.platformEventSettings != null ) {
                    local = NSP_AccountTriggerHelper.platformEventSettings.IsEnabled_IntegrationAccountDeleteEvent__c;
                }
                isEnabledIntegrationAccountDeleteEvent = local;
            }
            return isEnabledIntegrationAccountDeleteEvent;
        }
        private set;
    }

    //
    //
    //

    public void restrictDelete( List<Account> records , Map<Id,Account> deprecated ) {
        if ( ( records != null ) && !records.isEmpty() ) {
            Boolean hasPermissionDelete = CustomPermissionController.checkUserPermission(
                'Allow_Delete_Accounts' ,
                UserInfo.getUserId()
            );
            if ( !hasPermissionDelete ) {
                for ( Account record : records ) {
                    record.addError( System.Label.CANNOT_DELETE_ACCOUNT );
                }
            }
        }
    }

    //
    // Description: Method updates Address on CheckList
    // @Param : List of New Accounts: accountsList, newMap
    // @return type: void
    // User Story - 194644
    // Created By- Ruchi   Date- 12/17/2022
    //
    private static void updateAddressOnCheckList( List<Account> accountList , Map<Id, Account> newMap ) {
        try {
            List<NSP_Checklist__c> checklistToUpdate = new List<NSP_Checklist__c>();
            List<NSP_Checklist__c> checklistList = [
                SELECT
                    Id ,
                    NSP_Account_Billling_City__c ,
                    NSP_Billing_Postal_Code__c ,
                    NSP_Account_Billing_State__c ,
                    NSP_Account_Billing_Country__c ,
                    NSP_Account_Billing_Street__c ,
                    NSP_Account_Billing_State_Code__c ,
                    NSP_Opportunity__c ,
                    NSP_Opportunity__r.AccountId
                FROM NSP_Checklist__c
                WHERE ( NSP_Opportunity__r.AccountId = :accountList )
            ];
            // Only query team members when the running user does not have the bypass permission
            Boolean hasBypassPermission = FeatureManagement.checkPermission( 'Bypass_Restrict_Checklist_To_Opportunity_Team_Members' );
            Set<Id> teamMemberOpportunityIds = new Set<Id>();
            if ( !hasBypassPermission ) {
                Set<Id> opportunityIds = new Set<Id>();
                for ( NSP_Checklist__c cl : checklistList ) {
                    if ( cl.NSP_Opportunity__c != null ) {
                        opportunityIds.add( cl.NSP_Opportunity__c );
                    }
                }
                if ( !opportunityIds.isEmpty() ) {
                    for ( OpportunityTeamMember otm : [
                                SELECT OpportunityId
                                FROM OpportunityTeamMember
                                WHERE (
                                    ( OpportunityId = :opportunityIds )
                                    AND ( UserId = :UserInfo.getUserId() )
                                )
                            ]
                        )
                    {
                        teamMemberOpportunityIds.add( otm.OpportunityId );
                    }
                }
            }
            if ( !checklistList.isEmpty() ) {
                for ( NSP_Checklist__c updateChecklist : checklistList ) {
                    // prevent DmlExceptions: FIELD_CUSTOM_VALIDATION_EXCEPTION, You can not edit this checklist, you are not a team member of the related opportunity.
                    // see Flow: Checklist_Before_Update_Restrict_Checklist_To_Opportunity_Team_Members
                    // Allow if: bypass permission granted OR no opportunity on checklist OR user is an opp team member
                    if ( hasBypassPermission
                        || ( ( teamMemberOpportunityIds != null )
                            && ( updateChecklist.NSP_Opportunity__c != null )
                            && teamMemberOpportunityIds.contains( updateChecklist.NSP_Opportunity__c )
                            )
                        )
                    {
                        Account acc = newMap.get( updateChecklist.NSP_Opportunity__r.AccountId );
                        updateChecklist.NSP_Account_Billling_City__c = acc.BillingCity;
                        updateChecklist.NSP_Account_Billing_State__c = acc.BillingState;
                        updateChecklist.NSP_Account_Billing_Country__c = acc.BillingCountry;
                        updateChecklist.NSP_Account_Billing_Street__c = acc.BillingStreet;
                        updateChecklist.NSP_Billing_Postal_Code__c = acc.BillingPostalCode;
                        updateChecklist.NSP_Account_Billing_State_Code__c = acc.BillingStateCode;
                        checklistToUpdate.add( updateChecklist );
                    }
                }
            }
            if ( !checklistToUpdate.isEmpty() ) {
                update checklistToUpdate;
            }
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'updateAddressOnCheckList' );
        }
    }

    //
    // Description: Method takes all Account records WHERE partner lifecycle is
    // set to Onboarding or Active and creates a new task or marks existing task complete based on
    // partner lifecycle value
    // @Param : List of New Accounts: accountsList
    // @return type: void
    //
    public static void handleTaskForPartnerContracts( List<Account> accountList ) {
        List<Task> tasksToUpsert = new List<Task>();
        Set<Id> accountIdsSet = new Set<Id>();
        for ( Account accountRecord : accountList ) {
            if ( accountRecord.NSP_Partner_Lifecycle__c == NSP_SalesConstants.ONBOARDING ) {
                Task taskRecord = new Task(
                    Subject=NSP_SalesConstants.PARTNER_CONTRACT_GENERATED ,
                    WhatId=accountRecord.Id ,
                    OwnerId=accountRecord.OwnerId ,
                    NSP_Task_type__c=NSP_SalesConstants.CHANNELS ,
                    NSP_Task_Subtype__c=NSP_SalesConstants.PARTNER_AGREEMENT ,
                    Status=NSP_SalesConstants.OPEN
                );
                taskRecord.NSP_Task_type__c = NSP_SalesConstants.CHANNELS;
                tasksToUpsert.add( taskRecord );
            } else if ( accountRecord.NSP_Partner_Lifecycle__c == NSP_SalesConstants.ACTIVE ) {
                accountIdsSet.add( accountRecord.Id );
            }
        }
        if ( !accountIdsSet.isEmpty() ) {
            List<Task> taskstoUpdate = [
                SELECT
                    Id ,
                    Subject ,
                    Status ,
                    NSP_Task_type__c ,
                    NSP_Task_Subtype__c
                FROM Task
                WHERE (
                    ( WhatId IN :accountIdsSet )
                    AND ( NSP_Task_type__c = :NSP_SalesConstants.CHANNELS )
                    AND ( NSP_Task_Subtype__c = :NSP_SalesConstants.PARTNER_AGREEMENT )
                    AND ( Status != :NSP_SalesConstants.COMPLETED )
                )
            ];
            for ( Task taskRecord : taskstoUpdate ) {
                taskRecord.Status = NSP_SalesConstants.COMPLETED;
                tasksToUpsert.add( taskRecord );
            }
        }
        if ( !tasksToUpsert.isEmpty() ) {
            try {
                upsert tasksToUpsert;
            } catch ( Exception e ) {
                NSP_AccountTriggerHelper.handleException( e , 'handleTaskForPartnerContracts' );
            }
        }
    }

    // populate CPM and LA on Account on insertion based on BPA sales office group
    public static void setChannelPartnerAndLoyaltyAdvisor( List<Account> accList , Set<String> salesOfficeSet ) {
        Map<String,String> grpIdGrpMemMap = new Map<String,String>();
        Map<String,String> grpNameCPMUserMap = new Map<String,String>();
        Map<String,String> grpNameLAUserMap = new Map<String,String>();
        try {
            //mapping userId and group Name
            for ( GroupMember gMem : [
                        SELECT GroupId , Group.Name , UserOrGroupId
                        FROM GroupMember
                        WHERE ( group.Name IN :salesOfficeSet )
                    ]
                )
            {
                if ( String.valueOf( gMem.UserOrGroupId ).startsWith( '005' ) ) {
                    grpIdGrpMemMap.put( gMem.UserOrGroupId , gMem.group.Name );
                }
            }
            if ( !grpIdGrpMemMap.isEmpty() ) {
                //mapping  group Name and userId
                for ( User getUser: [
                            SELECT Id , UserRoleId , UserRole.Name
                            FROM User
                            WHERE (
                                ( Id IN :grpIdGrpMemMap.keySet() )
                                AND (
                                    ( UserRole.Name = 'Loyalty Advisor' )
                                    OR ( UserRole.Name = 'Channel Program Manager' )
                                )
                            )
                        ]
                    )
                {
                    if ( getUser.UserRole.Name == 'Loyalty Advisor' ) {
                        grpNameLAUserMap.put( grpIdGrpMemMap.get( getUser.Id ) , getUser.Id );
                    } else if ( getUser.UserRole.Name == 'Channel Program Manager') {
                        grpNameCPMUserMap.put( grpIdGrpMemMap.get( getUser.Id ) , getUser.Id );
                    }
                }
                for ( Account ac : accList ) {
                    if ( !grpNameLAUserMap.isEmpty()
                        && String.isNotBlank( NSP_AccountTriggerHelper.currentUserSalesOffice )
                        && grpNameLAUserMap.containsKey( NSP_AccountTriggerHelper.currentUserSalesOffice )
                        )
                    {
                        ac.NSP_Loyalty_Advisor__c = grpNameLAUserMap.get( NSP_AccountTriggerHelper.currentUserSalesOffice );
                    }
                    if ( !grpNameCPMUserMap.isEmpty()
                        && String.isNotBlank( NSP_AccountTriggerHelper.currentUserSalesOffice )
                        && grpNameCPMUserMap.containsKey( NSP_AccountTriggerHelper.currentUserSalesOffice )
                        )
                    {
                        ac.NSP_Channel_Program_Manager__c = grpNameCPMUserMap.get( NSP_AccountTriggerHelper.currentUserSalesOffice );
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'setChannelPartnerAndLoyaltyAdvisor' );
        }
    }

    //
    // Based on the number of employees, Account segmentation field is populated.
    // param accountObject
    // returns void
    //
    private static void updateAccountSegment( Account accountObject ) {
        if ( accountObject != null ) {
            if ( Account_Segment_Threshold_Settings__c.getInstance( UserInfo.getUserId() ).Is_Enabled__c ) {
                accountObject.NSP_Account_Segment__c = NSP_LeadTriggerHelper.getSalesSegment( accountObject.NumberOfEmployees );
            } else {
                if ( accountObject.NumberOfEmployees > Integer.valueOf( System.Label.NSP_MidMarket_Threshold ) ) {
                    accountObject.NSP_Account_Segment__c = System.Label.NSP_Account_Segment_MidMarket;
                } else if ( ( accountObject.NumberOfEmployees > Integer.valueOf( System.Label.NSP_Emerging_Growth_Threshold_Employees ) )
                    && ( accountObject.NumberOfEmployees <= Integer.valueOf( System.Label.NSP_MidMarket_Threshold ) )
                    )
                {
                    accountObject.NSP_Account_Segment__c = System.Label.NSP_Account_Segment_Emerging_Growth;
                } else if (accountObject.NumberOfEmployees != null) {
                    accountObject.NSP_Account_Segment__c = System.Label.NSP_Account_Segment_Core_Sales;
                }
            }
        }
    }

    //
    // Description: This method sets signer to dummy user
    // BPA to Account owner if role is BPA
    // @param: accountList
    // @return: void
    // Modification History:
    // -------------------------------------------------------------------------------------
    // author           | Date              | Description
    // -------------------------------------------------------------------------------------
    // Harsha Khiroya           12/22/2021           created this new method
    //
    public void setDummyUsers( List<Account> accountList ) {
        try {
            if ( ( accountList != null ) && !accountList.isEmpty() ) {
                for ( Account accountObj : accountList ) {
                    // if Account owner is BPA
                    // set BPA as owner or set as dummy user -- UPDATE: Dummy User retired; just leave NSP_BPA__c unassigned
                    if ( ( accountObj.NSP_BPA__c == null )
                        && NSP_AccountTriggerHelper.templSelectUpdPermittedUserMap.keySet().contains( accountObj.OwnerId )
                        )
                    {
                        accountObj.NSP_BPA__c = accountObj.OwnerId;
                    }
                }
            }
        } catch ( Exception e ){
            NSP_AccountTriggerHelper.handleException( e , 'setDummyUsers' );
        }
    }

    // Restricts users assigned with Account View All/Modify All ps to Edit Accounts outside Sales Office.
    public void restrictAccountChange( Map<Id,Account> accountNewMap , Map<Id,Account> accountOldMap , User deprecated ) {
        try {
            List<String> loggedInUserGrpName = this.selectLoggedInUserGroupName();
            Map<String,String> accOwnerSalesOfficeMap = this.selectAccountOwnerSalesOfficeMap( accountOldMap );
            Set<Id> accountTeamMemberId = this.selectAccountTeamMemberIds( accountNewMap );
            Id availableUserId = '0054x000008PgqNAAS'; // 'Available' User Id...
            for ( Account acc : accountNewMap.values() ) {
                Account oldRecord = accountOldMap.get( acc.Id );
                Boolean isAllowAssignAvailable = (
                    ( acc.OwnerId != availableUserId )
                    && ( CustomPermissionController.checkUserPermission( 'Account_Allow_Assign_Available' , UserInfo.getUserId() ) )
                );
                Boolean isValidCurrentUser = (
                    (
                        !loggedInUserGrpName.isEmpty()
                        && loggedInUserGrpName.contains( accOwnerSalesOfficeMap.get( oldRecord.ownerId ) )
                    )
                    || accountTeamMemberId.contains( UserInfo.getUserId() )
                    || accOwnerSalesOfficeMap.containsKey( UserInfo.getUserId() )
                );
                Boolean isBypassedAllowed = (
                    CustomPermissionController.checkUserPermission( 'Allow_Update_MidMarket_Role' , UserInfo.getUserId() )
                    || CustomPermissionController.checkUserPermission( 'Auto_Create_Opportunity_From_Account' , UserInfo.getUserId() )
                );
                Boolean isAllowUpdate = this.isAllowedAccountChange(
                    this.isAllowedFieldChanges( acc , oldRecord ) ,
                    ( oldRecord.OwnerId == availableUserId ) ,
                    isAllowAssignAvailable ,
                    accOwnerSalesOfficeMap.isEmpty() ,
                    isBypassedAllowed ,
                    isValidCurrentUser
                );
                if ( !isAllowUpdate ) {
                    acc.addError( System.Label.NSP_AccountTriggerError );
                }
            }
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'restrictAccountChange' );
        }
    }

    // helper method to defeat sonar cognitive complexity...
    private Boolean isAllowedFieldChanges( Account newRecord , Account oldRecord ) {
        Boolean response = false;
        if ( ( newRecord != null ) && ( oldRecord != null ) ) {
            response = (
                ( newRecord.NSP_Last_Updated__c != oldRecord.NSP_Last_Updated__c )
                || ( newRecord.NSP_AIMS_Renewal_Date__c != oldRecord.NSP_AIMS_Renewal_Date__c ) // ignore changes to Roll-Up Summary...
                || ( newRecord.Total_PEPM__c != oldRecord.Total_PEPM__c ) // ignore changes to Roll-Up Summary...
                || ( newRecord.Count_of_Pending_Oppty__c != oldRecord.Count_of_Pending_Oppty__c ) // ignore changes to Roll-Up Summary...
                || ( newRecord.Count_of_Closed_Won_Oppty__c != oldRecord.Count_of_Closed_Won_Oppty__c ) // ignore changes to Roll-Up Summary...
                || ( newRecord.Zip_Based_Location__c != oldRecord.Zip_Based_Location__c )
                || ( newRecord.dnb_exclude_company__c != oldRecord.dnb_exclude_company__c )
                || ( ( newRecord.NSP_Sales_Service_Account_Status__c != oldRecord.NSP_Sales_Service_Account_Status__c )
                    && ( newRecord.NSP_Sales_Service_Account_Status__c == 'Prospecting' )
                    )
            );
        }
        return response;
    }

    // helper method to defeat sonar cognitive complexity...
    private Boolean isAllowedAccountChange(
        Boolean isAllowedBypass ,
        Boolean isAvailablePreviousOwner ,
        Boolean isAllowAssignAvailable ,
        Boolean isEmptyAccountOwnerSalesOfficeMap ,
        Boolean isBypassedAllowed ,
        Boolean isValidCurrentUser
        )
    {
        Boolean isAllowed = isAllowedBypass;
        if ( isAvailablePreviousOwner
            && isAllowAssignAvailable
            )
        {
            isAllowed = true;
        } else if (
            ( isEmptyAccountOwnerSalesOfficeMap )
            || ( isBypassedAllowed )
            || ( isValidCurrentUser )
            )
        {
            isAllowed = true;
        }
        return isAllowed;
    }

    private List<String> selectLoggedInUserGroupName() {
        List<String> response = new List<String>();
        for ( GroupMember member: [
                    SELECT Id , GroupId , Group.Name , UserOrGroupId
                    FROM GroupMember
                    WHERE ( UserOrGroupId = :Userinfo.getUserId() )
                ]
            )
        {
            response.add( member.Group.Name );
        }
        return response;
    }

    private Map<String,String> selectAccountOwnerSalesOfficeMap( Map<Id,Account> oldMap ) {
        Map<String,String> response = new Map<String,String>();
        if ( ( oldMap != null ) && !oldMap.isEmpty() ) {
            for ( Account acc : [
                        SELECT
                            Id ,
                            OwnerId ,
                            Owner.UserRoleId ,
                            Owner.UserRole.Name ,
                            ToLabel( Owner.NSP_Sales_Office__c ) ,
                            ToLabel( Owner.NSP_Sales_Office_Membership__c )
                        FROM Account
                        WHERE (
                            ( Id IN :oldMap.keySet() )
                            AND ( OwnerId IN :NSP_AccountTriggerHelper.ownerUpdatePermittedUserMap.keySet() )
                        )
                    ]
                )
            {
                response.put(
                    acc.OwnerId ,
                    acc.Owner.NSP_Sales_Office__c
                );
            }
        }
        return response;
    }

    private Set<Id> selectAccountTeamMemberIds( Map<Id,Account> newMap ) {
        Set<Id> response = new Set<Id>();
        for ( NSP_Account_Team__c accTeam : [
                    SELECT
                        Id ,
                        NSP_User__c ,
                        NSP_Account__c
                    FROM NSP_Account_Team__c
                    WHERE ( NSP_Account__c = :newMap.keySet() )
                ]
            )
        {
            response.add( accTeam.NSP_User__c );
        }
        return response;
    }

    // sets sales office details from user
    public void setSalesOfficeDetails( List<Account> newList , Map<Id,Account> accountOldMap ) {
        Set<Id> ownerIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<String> salesOfficeSet = new Set<String>();
        Map<Id,String> newSalesOffice = new Map<Id,String>();
        for ( Account newAccount : newList ) {
            Account oldAccount = ( ( accountOldMap != null ) ? accountOldMap.get( newAccount.Id ) : null );
            if ( ( Trigger.isInsert || ( newAccount.OwnerId != oldAccount.OwnerId ) )
                && ( newAccount.OwnerId != null )
                )
            {
                ownerIdSet.add( newAccount.OwnerId );
                if ( newAccount.Id  != null ) {
                    accountIdSet.add( newAccount.Id );
                }
            } else if ( Trigger.isUpdate
                && !System.isQueueable()
                && String.isNotBlank( newAccount.NSP_Sales_Office__c )
                && ( ( newAccount.NSP_Sales_Office__c != oldAccount.NSP_Sales_Office__c )
                    || ( newAccount.NSP_Sales_Division__c != oldAccount.NSP_Sales_Division__c )
                    || ( newAccount.NSP_SalesRegion__c != oldAccount.NSP_SalesRegion__c )
                    )
                )
            {
                salesOfficeSet.add( newAccount.NSP_Sales_Office__c );
            }
        }
        Map<Id,Id> oldAccountOwner = new Map<Id,Id>();
        Map<Id,Map<String,String>> accountSalesOffice = new Map<Id,Map<String,String>>();
        Map<Id,Id> newAccountOwner = new Map<Id,Id>();
        if ( !ownerIdSet.isEmpty() ) {
            Map<Id,User> userIdMap = new Map<Id,User>(
                [
                    SELECT
                        Id ,
                        NSP_SalesDivision__c ,
                        NSP_Sales_Office__c ,
                        NSP_SalesRegion__c
                    FROM User
                    WHERE (
                        ( Id IN :ownerIdSet )
                        AND ( NSP_Sales_Office__c != null )
                    )
                ]
            );
            Set<Id> accountWithActiveAssetSet = new Set<Id>();
            for ( Asset eachAsset : [
                        SELECT Id , AccountId
                        FROM Asset
                        WHERE (
                            ( AccountId IN :accountIdSet )
                            AND (
                                ( Status = 'Active' )
                                OR ( NSP_Account_Status__c = 'Active' )
                            )
                        )
                    ]
                )
            {
                accountWithActiveAssetSet.add( eachAsset.AccountId );
            }
            for ( Account newAccount : newList ) {
                Account oldAccount = ( ( accountOldMap != null ) ? accountOldMap.get( newAccount.Id ) : null );
                if ( ( Trigger.isInsert
                        || ( ( newAccount.OwnerId != oldAccount.OwnerId )
                            && !accountWithActiveAssetSet.contains( newAccount.Id )
                            )
                        )
                    && ( newAccount.OwnerId != null )
                    && userIdMap.containsKey( newAccount.OwnerId )
                    )
                {
                    user eachUser = userIdMap.get(newAccount.OwnerId);
                    newAccount.NSP_SalesRegion__c = eachUser.NSP_SalesRegion__c;  // sales region
                    newAccount.NSP_Sales_Division__c = eachUser.NSP_SalesDivision__c; // sales division
                    newAccount.NSP_Sales_Office__c = eachUser.NSP_Sales_Office__c; // sales office
                    //  301313 - Opportunity Sales Office not Update on Reassign Account
                    if ( Trigger.isUpdate ) {
                        newSalesOffice.put( newAccount.Id , newAccount.NSP_Sales_Office__c );
                        oldAccountOwner.put( newAccount.Id , oldAccount.OwnerId );
                        accountSalesOffice.put(
                            newAccount.Id ,
                            new Map<String,String> {
                                'office' => newAccount.NSP_Sales_Office__c ,
                                'division' => newAccount.NSP_Sales_Division__c ,
                                'region' => newAccount.NSP_SalesRegion__c
                            }
                        );
                        newAccountOwner.put( newAccount.Id , newAccount.OwnerId );
                    }
                }
            }
        }
        if ( !salesOfficeSet.isEmpty() ) {
            Map<String,NSP_Sales_Office_Mapping__c> salesOfficeToMappingMap = new Map<String,NSP_Sales_Office_Mapping__c>();
            for ( NSP_Sales_Office_Mapping__c eachMapping : [
                        SELECT
                            Id ,
                            NSP_Sales_Office__c ,
                            NSP_Sales_Division__c ,
                            NSP_Sales_Region__c
                        FROM NSP_Sales_Office_Mapping__c
                        WHERE (
                            ( NSP_Sales_Office__c IN :salesOfficeSet )
                            AND ( isActive__c = true )
                        )
                    ]
                )
            {
                salesOfficeToMappingMap.put( eachMapping.NSP_Sales_Office__c , eachMapping );
            }
            for ( Account newAccount : newList ) {
                Account oldAccount = ( ( accountOldMap != null ) ? accountOldMap.get( newAccount.Id ) : null );
                if ( Trigger.isUpdate
                    && String.isNotBlank( newAccount.NSP_Sales_Office__c )
                    && salesOfficeToMappingMap.containsKey( newAccount.NSP_Sales_Office__c )
                    && ( ( newAccount.NSP_Sales_Office__c != oldAccount.NSP_Sales_Office__c )
                        || ( newAccount.NSP_Sales_Division__c != oldAccount.NSP_Sales_Division__c )
                        || ( newAccount.NSP_SalesRegion__c != oldAccount.NSP_SalesRegion__c )
                        )
                    )
                {
                    NSP_Sales_Office_Mapping__c officeMapping = salesOfficeToMappingMap.get( newAccount.NSP_Sales_Office__c );
                    newAccount.NSP_Sales_Division__c = officeMapping.NSP_Sales_Division__c;
                    newAccount.NSP_SalesRegion__c = officeMapping.NSP_Sales_Region__c;
                }
            }
        }
        if ( !newSalesOffice.isEmpty() ) {
            NSP_AccountTriggerHelper.updateRelatedOpportunity( newSalesOffice , oldAccountOwner );
            // ADO-219422
            // When the Acccount owner is updated using the native Salesforce feature "Change Account Owner",
            // no triggers are fired, so we need to update the Sales Office on the related records (contacts, events, tasks)
            NSP_AccountTriggerHelper.updateRelateContacts( accountSalesOffice , oldAccountOwner );
            NSP_AccountTriggerHelper.updateRelatedActivities( accountSalesOffice , oldAccountOwner , newAccountOwner );
        }
    }

    //
    // Description: This method creates the list of contacts to be updated
    // @param: accountSalesOffice
    // @param: accountOwner
    // @return: void
    //
    private static void updateRelateContacts( Map<Id,Map<String,String>> accountSalesOffice , Map<Id,Id> accountOwner ) {
        Map<Id,Map<String,String>> contactSalesOffice = new Map<Id,Map<String,String>>();
        if ( ( accountSalesOffice != null )
            && !accountSalesOffice.isEmpty()
            && ( accountOwner != null )
            && !accountOwner.isEmpty()
            )
        {
            for ( Contact contact : [
                        SELECT Id , AccountId , OwnerId , NSP_Sales_Office__c , NSP_Sales_Division__c , NSP_Sales_Region__c
                        FROM Contact
                        WHERE ( AccountId IN :accountSalesOffice.keySet() )
                    ]
                )
            {
                if ( accountOwner.containsKey( contact.AccountId )
                    && contact.OwnerId == accountOwner.get( contact.AccountId )
                    )
                {
                    contactSalesOffice.put(
                        contact.Id ,
                        accountSalesOffice.get( contact.AccountId )
                    );
                }
            }
        }
        if ( !contactSalesOffice.isEmpty()
            && ( Limits.getFutureCalls() < Limits.getLimitFutureCalls() )
            )
        {
            NSP_AccountTriggerHelper.updateRelatedContactsAsync( JSON.serialize( contactSalesOffice ) );
        }
    }

    //
    // Description: This method async updates the sales office on related contacts
    // @param: strContactSalesOffice
    // @return: void
    //
    @future
    private static void updateRelatedContactsAsync( String strContactSalesOffice ) {
        try {
            Map<Id,Map<String,String>> contactSalesOffice = (Map<Id,Map<String,String>>)JSON.deserialize(
                strContactSalesOffice ,
                Map<Id,Map<String,String>>.class
            );
            List<Contact> updateContacts = new List<Contact>();
            if ( ( contactSalesOffice != null ) && !contactSalesOffice.isEmpty() ) {
                for ( Contact contact : [
                            SELECT Id , AccountId , OwnerId , NSP_Sales_Office__c , NSP_Sales_Division__c , NSP_Sales_Region__c
                            FROM Contact
                            WHERE ( Id IN :contactSalesOffice.keySet() )
                        ]
                    )
                {
                    if ( contactSalesOffice.containsKey( contact.Id ) ) {
                        Map<String,String> salesOffice = contactSalesOffice.get( contact.Id );
                        contact.NSP_Sales_Office__c = salesOffice.get( 'office' );
                        contact.NSP_Sales_Division__c = salesOffice.get( 'division' );
                        contact.NSP_Sales_Region__c = salesOffice.get( 'region' );
                        updateContacts.add( contact );
                    }
                }
            }
            if ( !updateContacts.isEmpty() ) {
                update updateContacts;
            }
        } catch( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'updateRelatedContactsAsync' );
        }
    }

    //
    // Description: This method created the list of related activities to be updated
    // @param: accountSalesOffice
    // @param: oldAccountOwner
    // @param: newAccountOwner
    // @return: void
    //
    private static void updateRelatedActivities(
        Map<Id,Map<String,String>> accountSalesOffice ,
        Map<Id,Id> oldAccountOwner ,
        Map<Id,Id> newAccountOwner
        )
    {
        Map<Id,Map<String,String>> eventSalesOffice = new Map<Id,Map<String,String>>();
        Map<Id,Map<String,String>> taskSalesOffice = new Map<Id,Map<String,String>>();
        if ( ( accountSalesOffice != null )
            && !accountSalesOffice.isEmpty()
            && ( oldAccountOwner != null )
            && !oldAccountOwner.isEmpty()
            )
        {
            for ( Event event : [
                        SELECT Id , AccountId , OwnerId , NSP_Sales_Office__c , NSP_Sales_Division__c , NSP_Sales_Region__c
                        FROM Event
                        WHERE (
                            ( AccountId IN :accountSalesOffice.keySet() )
                            AND ( OwnerId IN :oldAccountOwner.values() )
                        )
                    ]
                )
            {
                if ( oldAccountOwner.containsKey( event.AccountId )
                    && event.OwnerId == oldAccountOwner.get( event.AccountId )
                    )
                {
                    eventSalesOffice.put(
                        event.Id ,
                        accountSalesOffice.get( event.AccountId )
                    );
                }
            }
            for ( Task task : [
                        SELECT Id , AccountId , OwnerId , NSP_Sales_Office__c , NSP_Sales_Division__c , NSP_Sales_Region__c
                        FROM Task
                        WHERE (
                            ( AccountId IN :accountSalesOffice.keySet() )
                            AND ( OwnerId IN :oldAccountOwner.values() )
                        )
                    ]
                )
            {
                if ( oldAccountOwner.containsKey( task.AccountId )
                    && task.OwnerId == oldAccountOwner.get( task.AccountId )
                    )
                {
                    taskSalesOffice.put(
                        task.Id ,
                        accountSalesOffice.get( task.AccountId )
                    );
                }
            }
        }
        if ( ( !eventSalesOffice.isEmpty() || !taskSalesOffice.isEmpty() )
            && Limits.getFutureCalls() < Limits.getLimitFutureCalls()
            )
        {
            NSP_AccountTriggerHelper.updateRelatedActivitiesAsync(
                JSON.serialize( eventSalesOffice ) ,
                JSON.serialize( taskSalesOffice ) ,
                JSON.serialize( newAccountOwner )
            );
        }
    }

    //
    // Description: This method async updates the sales office on related activities
    // @param: strEventSalesOffice
    // @param: strTaskSalesOffice
    // @param: strNewAccountOwner
    // @return: void
    //
    @future
    private static void updateRelatedActivitiesAsync( String strEventSalesOffice , String strTaskSalesOffice ,  String strNewAccountOwner ) {
        try {
            Map<Id,Map<String,String>> eventSalesOffice = (Map<Id,Map<String,String>>)JSON.deserialize(
                strEventSalesOffice ,
                Map<Id,Map<String,String>>.class
            );
            Map<Id,Map<String,String>> taskSalesOffice = (Map<Id,Map<String,String>>)JSON.deserialize(
                strTaskSalesOffice ,
                Map<Id,Map<String,String>>.class
            );
            Map<Id,Id> newAccountOwner = (Map<Id,Id>)JSON.deserialize(
                strNewAccountOwner ,
                Map<Id,Id>.class
            );
            List<Event> updateEvents = new List<Event>();
            if ( ( newAccountOwner != null )
                && ( eventSalesOffice != null )
                && !eventSalesOffice.isEmpty()
                )
            {
                // Prevent DmlExceptions ~ UNKNOWN_EXCEPTION, Can't edit events created by cadences. These events are auto-updated as prospects advance through the cadence
                // ~ use same isCadenceEventFormula leveraged in Flows...
                // ~ ignore Subject LIKE '%Cadence%'
                for ( Event event : [
                            SELECT
                                Id ,
                                AccountId ,
                                OwnerId ,
                                NSP_Sales_Office__c ,
                                NSP_Sales_Division__c ,
                                NSP_Sales_Region__c
                            FROM Event
                            WHERE (
                                ( Id IN :eventSalesOffice.keySet() )
                                AND ( NOT Subject LIKE '%Cadence%' )
                            )
                        ]
                    )
                {
                    //  Verify if event owner has been updated
                    if ( newAccountOwner.containsKey( event.AccountId )
                        && event.OwnerId == newAccountOwner.get( event.AccountId )
                        )
                    {
                        Map<String,String> salesOffice = eventSalesOffice.get( event.Id );
                        event.NSP_Sales_Office__c = salesOffice.get( 'office' );
                        event.NSP_Sales_Division__c = salesOffice.get( 'division' );
                        event.NSP_Sales_Region__c = salesOffice.get( 'region' );
                        updateEvents.add( event );
                    }
                }
            }
            if ( !updateEvents.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( updateEvents , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AccountTriggerHelper.class.getName() ,
                    'updateRelatedActivitiesAsync:update:Event' ,
                    results
                );
            }
            List<Task> updateTasks = new List<Task>();
            if ( ( newAccountOwner != null )
                && ( taskSalesOffice != null )
                && !taskSalesOffice.isEmpty()
                )
            {
                // Prevent DmlExceptions ~ UNKNOWN_EXCEPTION, Can't edit tasks created by cadences. These tasks are auto-updated as prospects advance through the cadence
                // ~ use same isCadenceTaskFormula leveraged in Flows...
                // ~ ignore TaskSubtype == 'Cadence'
                // ~ ignore Subject LIKE '%Cadence%'
                for ( Task task : [
                            SELECT
                                Id ,
                                AccountId ,
                                OwnerId ,
                                NSP_Sales_Office__c ,
                                NSP_Sales_Division__c ,
                                NSP_Sales_Region__c
                            FROM Task
                            WHERE (
                                ( Id IN :taskSalesOffice.keySet() )
                                AND ( TaskSubtype != 'Cadence' )
                                AND ( NOT Subject LIKE '%Cadence%' )
                            )
                        ]
                    )
                {
                    //  Verify if task owner has been updated
                    if ( newAccountOwner.containsKey( task.AccountId )
                        && task.OwnerId == newAccountOwner.get( task.AccountId )
                        )
                    {
                        Map<String,String> salesOffice = taskSalesOffice.get( task.Id );
                        task.NSP_Sales_Office__c = salesOffice.get( 'office' );
                        task.NSP_Sales_Division__c = salesOffice.get( 'division' );
                        task.NSP_Sales_Region__c = salesOffice.get( 'region' );
                        updateTasks.add( task );
                    }
                }
            }
            if ( !updateTasks.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( updateTasks , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AccountTriggerHelper.class.getName() ,
                    'updateRelatedActivitiesAsync:update:Task' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'updateRelatedActivitiesAsync' );
        }
    }

    //
    // Description: This method updates the Opportunity Sales Office when Account is reassigned
    // @param: accountSalesOffice
    // @return: void
    //
    private static void updateRelatedOpportunity( Map<Id,String> newSalesOffice , Map<Id,Id> oldAccountUserId ) {
        try {
            Map<Id,String> oppsChangeOffice = new Map<Id,String>();
            if ( ( newSalesOffice != null ) && !newSalesOffice.isEmpty() ) {
                List<Opportunity> opps = [
                    SELECT Id , OwnerId , AccountId , NSP_Sales_Office__c
                    FROM Opportunity
                    WHERE (
                        ( StageName != 'Closed Lost' )
                        AND ( StageName != 'Closed Won' )
                        AND ( StageName != 'Closing' )
                        AND ( AccountId IN :newSalesOffice.keySet() )
                    )
                ];
                for ( Opportunity opp : opps ) {
                    //  If Opportunity owner is the same as Account owner then update the Sales Office
                    if ( opp.OwnerId == oldAccountUserId.get( opp.AccountId ) ) {
                        oppsChangeOffice.put( opp.Id , newSalesOffice.get( opp.AccountId ) );
                    }
                }
            }
            //  Update Sales Office, adding extra condition checking the limits
            if ( !oppsChangeOffice.isEmpty()
                && ( Limits.getFutureCalls() < Limits.getLimitFutureCalls() )
                )
            {
                NSP_AccountTriggerHelper.updateRelatedOpportunityAsync( JSON.serialize( oppsChangeOffice ) );
            }
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'updateRelatedOpportunity' );
        }
    }

    @future
    private static void updateRelatedOpportunityAsync( String soppsChangeOffice ) {
        try {
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            Map<Id,String> oppsChangeOffice = (Map<Id,String>)JSON.deserialize(
                soppsChangeOffice ,
                Map<Id,String>.class
            );
            List<Opportunity> opps = [
                SELECT Id , NSP_Sales_Office__c
                FROM Opportunity
                WHERE ( Id IN :oppsChangeOffice.keySet() )
            ];
            for ( Opportunity opp : opps ) {
                opp.NSP_Sales_Office__c = oppsChangeOffice.get( opp.Id );
                oppsToUpdate.add( opp );
            }
            if ( !oppsToUpdate.isEmpty() ) {
                update oppsToUpdate;
            }
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'updateRelatedOpportunityAsync' );
        }
    }

    // Publishes events for Accounts deleted by merge.
    public void afterDeleteDirector( List<Account> oldList , Map<Id,Account> oldMap ) {
        try {
            List<Integration_Account_Delete_Event__e> accountDeleteEventList = New List<Integration_Account_Delete_Event__e>();
            // Iterating Trigger.new to feed the Account Id to Event List
            for ( Account accObj : oldList ) {
                if ( accObj.MasterRecordId != null ) { // result of Account merge
                    accountDeleteEventList.add(
                        new Integration_Account_Delete_Event__e(
                            Id__c=accObj.Id ,
                            MasterRecordId__c=accObj.MasterRecordId
                        )
                    );
                }
            }
            // Send the list to publish event bus
            if ( !accountDeleteEventList.isEmpty()
                && NSP_AccountTriggerHelper.isEnabledIntegrationAccountDeleteEvent
                )
            {
                this.publishEventBus( accountDeleteEventList );
            }
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'afterDeleteDirector' );
        }
    }

    // update field Payroll Employee Of Account Group Member From Payroll Employee Of Account
    public static void updateAGMPayrollEmployees( Map<Id,Account> newMap , Map<Id,Account> oldMap ) {
        try {
            List<NSP_Account_Group_Member__c> accGroupMemberToBeUpdated = new List<NSP_Account_Group_Member__c>();
            Map<Id,Decimal> accPayrollByIds = new Map<Id,Decimal>();
            // put accountId By Payroll Employees in Map
            for ( Account accList : newMap.values() ) {
                if ( accList.NSP_Payroll_employee__c != oldMap.get( accList.Id ).NSP_Payroll_employee__c ) {
                    accPayrollByIds.put( accList.Id , accList.NSP_Payroll_employee__c );
                }
            }
            // update Account Group Member field Payroll Employees From Account field Payroll Employees
            if ( !accPayrollByIds.isEmpty() ) {
                for ( NSP_Account_Group_Member__c accGroMember : [
                            SELECT Id , NSP_Member_Account__c , NSP_Payroll_Employees__c
                            FROM NSP_Account_Group_Member__c
                            WHERE ( NSP_Member_Account__c = :accPayrollByIds.keySet() )
                        ]
                    )
                {
                    if ( accGroMember.NSP_Payroll_Employees__c != accPayrollByIds.get( accGroMember.NSP_Member_Account__c ) ) {
                        accGroMember.NSP_Payroll_Employees__c = accPayrollByIds.get( accGroMember.NSP_Member_Account__c );
                        accGroupMemberToBeUpdated.add( accGroMember );
                    }
                }
            }
            if ( !accGroupMemberToBeUpdated.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( accGroupMemberToBeUpdated , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AccountTriggerHelper.class.getName() ,
                    'updateAGMPayrollEmployees:update' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'updateAGMPayrollEmployees' );
        }
    }

    // update field NumberOfEmployees_Sales on Account Group Member from NumberOfEmployees of Account
    public static void updateAGMNumberOfEmployees( Map<Id,Account> newMap , Map<Id,Account> oldMap ) {
        try {
            Map<Id,Integer> accEmployeesByIds = new Map<Id,Integer>();
            // put accountId By NumberOfEmployees in Map - only when value changes
            if ( ( newMap != null ) && ( oldMap != null ) ) {
                for ( Account accList : newMap.values() ) {
                    Account oldAccount = oldMap.containsKey( accList.Id ) ? oldMap.get( accList.Id ) : null;
                    if ( ( oldAccount != null )
                        && ( ( accList.NumberOfEmployees != oldAccount.NumberOfEmployees )
                          || ( accList.Sales_Set_Membership__c != oldAccount.Sales_Set_Membership__c ) ) ) {
                        accEmployeesByIds.put( accList.Id , accList.NumberOfEmployees );
                    }
                }
            }
            // move the Account Group Member update off the synchronous trigger path
            if ( !accEmployeesByIds.isEmpty() ) {
                NSP_AccountTriggerHelper.updateAGMNumberOfEmployeesAsync( JSON.serialize( accEmployeesByIds ) );
            }
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'updateAGMNumberOfEmployees' );
        }
    }

    // update Account Group Member field NumberOfEmployees_Sales from Account field NumberOfEmployees
    @future
    private static void updateAGMNumberOfEmployeesAsync( String strAccEmployeesByIds ) {
        try {
            Map<Id,Integer> accEmployeesByIds = (Map<Id,Integer>) JSON.deserialize( strAccEmployeesByIds , Map<Id,Integer>.class );
            List<NSP_Account_Group_Member__c> accGroupMemberToBeUpdated = new List<NSP_Account_Group_Member__c>();
            if ( !accEmployeesByIds.isEmpty() ) {
                for ( NSP_Account_Group_Member__c accGroMember : [
                            SELECT Id , NSP_Member_Account__c , NumberOfEmployees_Sales__c
                            FROM NSP_Account_Group_Member__c
                            WHERE ( NSP_Member_Account__c = :accEmployeesByIds.keySet() )
                        ]
                    )
                {
                    if ( accGroMember.NumberOfEmployees_Sales__c != accEmployeesByIds.get( accGroMember.NSP_Member_Account__c ) ) {
                        accGroMember.NumberOfEmployees_Sales__c = accEmployeesByIds.get( accGroMember.NSP_Member_Account__c );
                        accGroupMemberToBeUpdated.add( accGroMember );
                    }
                }
            }
            if ( !accGroupMemberToBeUpdated.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( accGroupMemberToBeUpdated , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AccountTriggerHelper.class.getName() ,
                    'updateAGMNumberOfEmployeesAsync:update' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'updateAGMNumberOfEmployeesAsync' );
        }
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_AccountTriggerHelper.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_AccountTriggerHelper.class.getName() ,
            methodName ,
            e
        );
    }

    private static Map<Id,User> ownerUpdatePermittedUserMap {
        private get {
            if ( ownerUpdatePermittedUserMap == null ) {
                ownerUpdatePermittedUserMap = CustomPermissionController.getPermittedUsersMap( 'Account_Owner_Restrict_Update' );
            }
            return ownerUpdatePermittedUserMap;
        }
        private set;
    }

    private static Map<Id,User> templSelectUpdPermittedUserMap {
        private get {
            if ( templSelectUpdPermittedUserMap == null ) {
                templSelectUpdPermittedUserMap = CustomPermissionController.getPermittedUsersMap( 'Template_Selection_Owner_Update' );
            }
            return templSelectUpdPermittedUserMap;
        }
        private set;
    }

}
//
