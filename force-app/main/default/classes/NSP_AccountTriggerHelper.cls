//
// Represents the Account trigger helper which handles all the logic.
// -------------------------------------------------------------------------------------------------
// Modification History
//  ManiTeja           March 28 2022        As part of DF-01476, removed setChannelPartnerAndLoyaltyAdvisor reference to populate Loyalty Advisor and CPM based on state.
//  Rahul Singh        Sept  29 2022        Added as part of 569324 charwell request.
//  Ruchi              Oct   21 2022        Added as part of 128176.
//  Rahul Singh        Nov   29 2022        Modified as part of user story 191911
//
public class NSP_AccountTriggerHelper {
    // test w/ NSP_AccountTriggerHelperTest, NSP_AccountContactRelationHelperTest, NSP_AccountContactServiceHelperTest (80%)
    // test w/ NSP_AccountTriggerHelperTest, NSP_LeadTriggerHelperTest (79%)
    // test w/ NSP_AccountTriggerHelperTest (78%)
    // test w/ NSP_AccountContactRelationHelperTest (34%)
    // test w/ NSP_AccountContactServiceHelperTest (38%)

    private static Set<String> lockedSalesSegments = new Set<String>{
        NSP_SalesConstants.MIDMARKET_SALES ,
        NSP_SalesConstants.WS ,
        NSP_SalesConstants.ENTERPRISE_SALES
    };
    private static final Id PARTNER_RECORDTYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get( 'NSP_Partner_Client' ).getRecordTypeId();
    private static final string DA_ROLE = 'District Administrator';
    //Added as part of 128176
    public static List<string> salesRoles = System.Label.Sales_Roles.split(',');
    // Added as part of 194459
    public static List<string> MMRoles = System.Label.NSP_MidMarket_Roles.split(',');
    // Added as part of 215091
    private static Boolean hasPartnerLoyaltyPermission = CustomPermissionController.checkUserPermission('Account_Partner_Update_Loyalty_from_SO', UserInfo.getUserId());
    private static Boolean hasPartnerMMPermission = CustomPermissionController.checkUserPermission('Account_Partner_MidMarket_Seller', UserInfo.getUserId());

    //
    // Iterates throught the list of new Account and passes the required attributes to other methods.
    // @param newList List of New Accounts.
    // @return void
    //
    public void beforeInsertDirector( List<Account> newList ) {
        try {
            // Added as part of DF-01906
            List<Account> bpaAccountList = new List<Account>();
            Set<String> salesOfficeSet = new Set<String>();
            User userDetails = [SELECT Id, Name, UserRole.Name, ToLabel(NSP_Sales_Office__c) FROM User WHERE Id =: userinfo.getUserId()];
            // Added as part of DF-01906
            List<Account> acctListToStampDocusignTemplateId = new List<Account>();
            for ( Account accountObj: newList ) {
                // Added as part of DF-01906 to populate CPM and LA based on Sales office of loggedin BPA
                if ( accountObj.RecordTypeId == PARTNER_RECORDTYPE_ID ) {
                    accountObj.NSP_Partner_Lifecycle__c = NSP_SalesConstants.EVALUATION;
                }
                if ( ( accountObj.RecordTypeId==PARTNER_RECORDTYPE_ID )
                     && ( hasPartnerLoyaltyPermission )
                     && ( String.isNotBlank(userDetails.NSP_Sales_Office__c) )
                   )
                {
                    bpaAccountList.add(accountObj);
                    salesOfficeSet.add(userDetails.NSP_Sales_Office__c);
                }
                checkPartner( accountObj );
                //create list to populate docusign template id for merge on demand templates
                if ( !String.isBlank(accountObj.NSP_Template_Selection__c) ) {
                    acctListToStampDocusignTemplateId.add(accountObj);
                }
                //  Bypass sales segment - ADO-334282
                Boolean hasBypassSalesSegment = CustomPermissionController.checkUserPermission( 'Bypass_Sales_Segment' , UserInfo.getUserId() );
                if ( !( hasBypassSalesSegment && lockedSalesSegments.contains(accountObj.NSP_Account_Segment__c) ) ) {
                    updateAccountSegment( accountObj );
                }
                // update ready to sync to true whenever Account is cloned
                if ( accountObj.isClone() ) {
                    accountObj.NSP_Ready_for_Integration_Sync__c = true; // DEPRECATED
                }
            }
            if ( !bpaAccountList.isEmpty() ) {
                setChannelPartnerAndLoyaltyAdvisor(bpaAccountList, salesOfficeSet);
            }
            this.setDummyUsers( acctListToStampDocusignTemplateId );
            setSalesOfficeDetails(newList, null);
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'beforeInsertDirector' );
        }
    }

    private void checkPartner(Account accountObj){
        if ( ( accountObj.RecordTypeId==PARTNER_RECORDTYPE_ID )
             && ( hasPartnerMMPermission )
           )
        {
            accountObj.NSP_Channel_Program_Manager__c = system.label.NSP_CPM_USER;
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

    //
    // Iterates throught the Account map and identifies the records that needs to worked based on various criterias.
    // @param accountNewMap Map of New Account.
    // @param accountOldMap Map of Old Account.
    // @return void
    //
    public void beforeUpdateDirector( Map<Id,Account> accountNewMap , Map<Id,Account> accountOldMap ) {

        try {
            List<Account> accountList = new List<Account>();
            List<Account> accountownerChangedList = new List<Account>();
            List<Account> partnerAccountList = new List<Account>();
            Set<Id> userIdsSet = new Set<Id>();
            List<Account> acctListToStampDocusignTemplateId = new List<Account>();
            //Iterating over the new Account map
            for (Id accountId: accountNewMap.keySet()) {
                Account newAccount = accountNewMap.get(accountId);
                Account oldAccount = accountOldMap.get(accountId);
                if (String.isNotBlank(accountNewMap.get(accountId).NSP_Account_Status__c)) {
                    if (accountNewMap.get(accountId).NSP_Account_Status__c.equals(NSP_SalesConstants.ACTIVE) &&
                        (accountNewMap.get(accountId).NSP_Account_Status__c != accountOldMap.get(accountId).NSP_Account_Status__c)) {
                        accountList.add(accountNewMap.get(accountId));
                    }
                }
                if (accountNewMap.get(accountId).Ownerid != accountOldMap.get(accountId).Ownerid) {
                    accountownerChangedList.add(accountNewMap.get(accountId));
                }
                //  Adding Enterpise sales segment - ADO-334282
                if ( ( accountNewMap.get(accountId).NumberOfEmployees != accountOldMap.get(accountId).NumberOfEmployees )
                    && !lockedSalesSegments.contains( accountOldMap.get(accountId).NSP_Account_Segment__c )
                    )
                {
                    updateAccountSegment( accountNewMap.get(accountId) );
                }
                //create list to populate docusign template id for merge on demand templates
                if (!String.isBlank(newAccount.NSP_Template_Selection__c) &&
                    newAccount.NSP_Template_Selection__c != oldAccount.NSP_Template_Selection__c) {
                    acctListToStampDocusignTemplateId.add(newAccount);
                }
                //cherwel ticket 556472
                if (accountNewMap.get(accountId).NSP_Partner_Lifecycle__c != accountOldMap.get(accountId).NSP_Partner_Lifecycle__c && accountNewMap.get(accountId).NSP_Partner_Lifecycle__c == NSP_SalesConstants.ONBOARDING) {
                    newAccount.NSP_Onboarding_Contract_Date__c = system.today();
                }
            }

            if (accountList.size() > 0) {
                setAccountStage(accountList);
            }
            if (accountownerChangedList.size() > 0) {
                setAccountStageWhenOwnerChanged(accountownerChangedList);
            }
            //call updateTriggerclass for metadata check ad update integration sync field on account
            Set<Id> accountIdSetToUpdateResyncFlag = new Set<Id>();
            NSP_SObjectUpdateTriggerHelper sObjectUpdateObj = new NSP_SObjectUpdateTriggerHelper();
            accountIdSetToUpdateResyncFlag.addAll(
                sObjectUpdateObj.fetchUpdFieldsLst(
                    NSP_IntegrationConstants.SOBJECT_ACCOUNT ,
                    accountNewMap ,
                    accountOldMap
                )
            );
            if ( !accountIdSetToUpdateResyncFlag.isEmpty() ) {
                for ( Id accountId : accountIdSetToUpdateResyncFlag ) {
                    accountNewMap.get( accountId ).NSP_Ready_for_Integration_Sync__c = true;
                }
            }
            this.setDummyUsers( acctListToStampDocusignTemplateId );
            setSalesOfficeDetails(accountNewMap.values(), accountOldMap);
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'beforeUpdateDirector' );
        }
    }

    //
    // Iterates through the list of new Account and passes the required attributes to other methods.
    // @param newList List of New Account.
    // @param newMap List of New Account.
    // @return void
    //
    public void afterInsertDirector( List<Account> newList , Map<Id,Account> newMap ) {
        try {
            List<Integration_Account_Event__e> accountEventList = new List<Integration_Account_Event__e>();
            List<Account> updateResyncFlagAccountList = new List<Account>();
            // Iterating Trigger.new to feed the Account Id to Event List
            for ( Account accObj : newList ) {
                if ( accObj.NSP_Ready_for_Integration_Sync__c ) {
                    accountEventList.add( new Integration_Account_Event__e( Id__c=accObj.Id ) );
                    updateResyncFlagAccountList.add( accObj );
                }
            }
            // Send the list to publish event bus
            if ( !accountEventList.isEmpty()
                && PlatformEventSettings__c.getInstance( UserInfo.getUserId() ).IsEnabled_IntegrationAccountEvent__c
                )
            {
                this.publishEventBus( accountEventList , updateResyncFlagAccountList );
            }
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'afterInsertDirector' );
        }
    }

    /**
     * Iterates throught the list of new Account and passes the required attributes to other methods.
     * @param newMap List of New Account.
     * @param oldMap List of New Account.
     * @return void
     *
     */
    public void afterUpdateDirector( Map<Id,Account> newMap , Map<Id,Account> oldMap ) {
        try {
            List<Account> accountList = new List<Account>(); // list to store accounts to handle Tasks when Partner contract is generated
            Map<Id,DateTime> accountTeamMDeleteMap = new Map<Id,DateTime>();
            Map<Id,String> accountTeamMDelete = new Map<Id,String>();
            List<Integration_Account_Event__e> accountEvent = new List<Integration_Account_Event__e>();
            List<Account> updateAccountList = new List <Account>();
            //Added for User Story - 194644
            List<Account> updateAddressAccountList = new List<Account>();
            for (Account accObj: newMap.values()) {
                if ( accObj.NSP_Ready_for_Integration_Sync__c ) {
                    accountEvent.add(New Integration_Account_Event__e(Id__c = accObj.Id));
                    updateAccountList.add(accObj);
                }
                if ( ( accObj.NSP_Partner_Lifecycle__c != oldMap.get(accObj.Id).NSP_Partner_Lifecycle__c )
                    && ( accObj.RecordTypeId == PARTNER_RECORDTYPE_ID )
                    && (
                        ( accObj.NSP_Partner_Lifecycle__c == NSP_SalesConstants.ACTIVE )
                        || ( accObj.NSP_Partner_Lifecycle__c == NSP_SalesConstants.ONBOARDING )
                    )
                   )
                {
                    accountList.add(accObj);
                }
                //Added for User Story - 194644
                if ( ( accObj.BillingCity != oldMap.get(accObj.Id).BillingCity )
                    || ( accObj.BillingState != oldMap.get(accObj.Id).BillingState )
                    || ( accObj.BillingCountry != oldMap.get(accObj.Id).BillingCountry )
                    || ( accObj.BillingStreet != oldMap.get(accObj.Id).BillingStreet )
                    || ( accObj.BillingStateCode != oldMap.get(accObj.Id).BillingStateCode )
                    || ( accObj.BillingPostalCode != oldMap.get(accObj.Id).BillingPostalCode)
                   )
                {
                    updateAddressAccountList.add(accObj);
                }
            }
            if ( !Test.isRunningTest() ) {
                NSP_SObjectHistoryTrackingHelper.enqueueJob(
                    (Map<Id,sObject>)newMap ,
                    (Map<Id,sObject>)oldMap
                );
            }
            // Send the list to publish event bus
            if (updateAccountList.size() > 0) {
                if (PlatformEventSettings__c.getInstance(UserInfo.getUserId()).IsEnabled_IntegrationAccountEvent__c) {
                    this.publishEventBus( accountEvent , updateAccountList );
                }
            }
            NSP_OpportunityTriggerHelperFunctions.updateOppOwnerPremier(newMap, oldMap); //Added as part of 569324 charwell request.

            if (accountList.size() > 0) {
                handleTaskForPartnerContracts(accountList);
            }
            //Added for User Story - 194644
            if(updateAddressAccountList.size() > 0) {
                updateAddressOnCheckList(updateAddressAccountList, newMap);
            }
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

    /**
     * Iterates throught the event list publish the records in event bus.
     * @param eventList of New Account.
     * @param objectList of New Account.
     * @return void
     *
     */
    private void publishEventBus( List<SObject> eventList , List<Account> objectList ) {
        List < Account > updateResyncFlagAccountList = new List < Account > ();
        if (!eventList.isEmpty()) {
            // Publishing records Event
            List<Database.SaveResult> results = EventBus.publish( eventList );
            NSP_ErrorLogHandler.logResults(
                NSP_AccountTriggerHelper.class.getName() ,
                'publishEventBus' ,
                results
            );
            for (Account accObj: objectList) {
                Account tempAccObj = new Account();
                tempAccObj.Id = accObj.Id;
                tempAccObj.NSP_Ready_for_Integration_Sync__c = false;
                updateResyncFlagAccountList.add(tempAccObj);
            }
            if (updateResyncFlagAccountList.size() > 0) {
                update updateResyncFlagAccountList;
            }
        }
    }

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
    public static void updateAddressOnCheckList( List<Account> accountList , Map<Id, Account> newMap ) {
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
            if ( !checklistList.isEmpty() ) {
                // Iterating checklistList
                for ( NSP_Checklist__c updateChecklist : checklistList ) {
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

    //
    // Description: This method is used to populate CPM and LA on Account on insertion based on BPA sales office group
    // @Param : List of New Accounts: accountsList and salesOfficeSet
    // @return type: void
    // Defect: DF-01906
    //
    public static void setChannelPartnerAndLoyaltyAdvisor( List<Account> accList , Set<String> salesOfficeSet ) {
        Map < String, string > grpIdGrpMemMap = new Map < String, string > ();
        Map < String, string > grpNameCPMUserMap = new Map < String, string > ();
        Map < String, string > grpNameLAUserMap = new Map < String, string > ();
        try {
            User userDetails = [SELECT Id, Name, UserRole.Name, ToLabel(NSP_Sales_Office__c) FROM User WHERE Id =: userinfo.getUserId()];
            //mapping userId and group Name
            for (GroupMember gMem: [SELECT groupId, group.Name, UserOrGroupId FROM GroupMember WHERE group.Name IN: salesOfficeSet]) {
                if (String.valueOf(gMem.UserOrGroupId).startsWith('005')) {
                    grpIdGrpMemMap.put(gMem.UserOrGroupId, gMem.group.Name);
                }
            }
            if (!grpIdGrpMemMap.isEmpty()) {
                //mapping  group Name and userId
                for (User getUser: [SELECT Id, UserRoleId, userRole.Name FROM User
                                    WHERE (userRole.Name = 'Loyalty Advisor'
                                           OR userRole.Name = 'Channel Program Manager')
                                            AND Id IN: grpIdGrpMemMap.keySet()]){
                    if (getUser.userRole.Name == 'Loyalty Advisor') {
                        grpNameLAUserMap.put(grpIdGrpMemMap.get(getUser.Id), getUser.Id);
                    } else if (getUser.userRole.Name == 'Channel Program Manager') {
                        grpNameCPMUserMap.put(grpIdGrpMemMap.get(getUser.Id), getUser.Id);
                    }
                }
                for (Account ac: accList) {
                    if (!grpNameLAUserMap.isEmpty() && grpNameLAUserMap.containsKey(userDetails.NSP_Sales_Office__c)) {
                        ac.NSP_Loyalty_Advisor__c = grpNameLAUserMap.get(userDetails.NSP_Sales_Office__c);
                    }
                    if (!grpNameCPMUserMap.isEmpty() && grpNameCPMUserMap.containsKey(userDetails.NSP_Sales_Office__c)) {
                        ac.NSP_Channel_Program_Manager__c = grpNameCPMUserMap.get(userDetails.NSP_Sales_Office__c);
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
    // @param accountNewMap Map of New Account.
    // @param accountOldMap Map of Old Account.
    // @return void
    // Ticket 128176
    // author           | Date              | Description
    // -------------------------------------------------------------------------------------
    // Ruchi Roy         10/21/2022           Created this method
    // Ruchi Roy         11/17/2022           Modified this method for 190991
    // Rahul Singh       11/29/2022        Modified for user story 191911
    // Modified on 02/2023-part of 194459- Bypass for MM roles
    // Matt McNeese      05/26/2023        Modified for user story 215091
    public void restrictAccountChange( Map<Id,Account> accountNewMap , Map<Id,Account> accountOldMap , User deprecated ) {
        try {
            List<String> loggedInUserGrpName = this.selectLoggedInUserGroupName();
            Map<String, string> accOwnerSalesOfficeMap = this.selectAccountOwnerSalesOfficeMap( accountOldMap );
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
                Boolean isAllowUpdate = this.isAllowedAccountChange(
                    this.isAllowedFieldChanges( acc , oldRecord ) ,
                    ( oldRecord.OwnerId == availableUserId ) ,
                    isAllowAssignAvailable ,
                    accOwnerSalesOfficeMap.isEmpty() ,
                    CustomPermissionController.checkUserPermission( 'Allow_Update_MidMarket_Role' , UserInfo.getUserId() ) ,
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
                || ( newRecord.Zip_Based_Location__c != oldRecord.Zip_Based_Location__c )
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
        Boolean isValidCurrentUserRole ,
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
            || ( isValidCurrentUserRole )
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

    //
    // Description: This method sets sales office details from user
    // @param: accountList
    // @return: void
    //
    public void setSalesOfficeDetails( List<Account> newList , Map<Id,Account> accountOldMap ) {
        Set<Id> ownerIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<String> salesOfficeSet = new Set<String>();
        Map<Id,String> newSalesOffice = new Map<Id,String>();

        for(Account newAccount: newList){
            Account oldAccount = accountOldMap != null ? accountOldMap.get(newAccount.Id) : null;
            if((Trigger.isInsert || newAccount.OwnerId != oldAccount.OwnerId) && newAccount.OwnerId != null){
                ownerIdSet.add(newAccount.OwnerId);
                if(newAccount.Id  != null){
                    accountIdSet.add(newAccount.Id);
                }
            }
            else if(Trigger.isUpdate && string.isNotBlank(newAccount.NSP_Sales_Office__c) && !system.isQueueable() &&
                (newAccount.NSP_Sales_Office__c != oldAccount.NSP_Sales_Office__c ||
                    newAccount.NSP_Sales_Division__c != oldAccount.NSP_Sales_Division__c ||
                     newAccount.NSP_SalesRegion__c != oldAccount.NSP_SalesRegion__c )){
                salesOfficeSet.add(newAccount.NSP_Sales_Office__c);
            }
        }

        Map<Id,Id> oldAccountOwner = new Map<Id,Id>();
        Map<Id,Map<String,String>> accountSalesOffice = new Map<Id, Map<String,String>>();
        Map<Id,Id> newAccountOwner = new Map<Id,Id>();
        if(ownerIdSet.Size() > 0){
            Map<Id,User> userIdMap = new Map<Id,User>([SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c FROM user WHERE Id In :ownerIdSet AND NSP_Sales_Office__c != null ]);
            Set<Id> accountWithActiveAssetSet = new Set<Id>();
            for(Asset eachAsset : [SELECT id,AccountId from Asset WHERE (status = 'Active' OR NSP_Account_Status__c = 'Active') AND AccountId In : accountIdSet ]){
                accountWithActiveAssetSet.add(eachAsset.AccountId);
            }

            for(Account newAccount: newList){
                Account oldAccount = accountOldMap != null ? accountOldMap.get(newAccount.Id) : null;
                if((Trigger.isInsert || (newAccount.OwnerId != oldAccount.OwnerId && !accountWithActiveAssetSet.contains(newAccount.Id))) && newAccount.OwnerId != null && userIdMap.containsKey(newAccount.OwnerId) ){
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

         if(salesOfficeSet.Size() > 0){
            map < String, NSP_Sales_Office_Mapping__c > salesOfficeToMappingMap = new map < String, NSP_Sales_Office_Mapping__c > ();
            for (NSP_Sales_Office_Mapping__c eachMapping: [SELECT Id, NSP_Sales_Office__c, NSP_Sales_Division__c, NSP_Sales_Region__c
                                                            FROM NSP_Sales_Office_Mapping__c
                                                            WHERE NSP_Sales_Office__c In : salesOfficeSet AND isActive__c = true]){
                salesOfficeToMappingMap.put(eachMapping.NSP_Sales_Office__c, eachMapping);
            }

            for(Account newAccount: newList){
                Account oldAccount = accountOldMap != null ? accountOldMap.get(newAccount.Id) : null;
                if (Trigger.isUpdate && string.isNotBlank(newAccount.NSP_Sales_Office__c) &&
                    (newAccount.NSP_Sales_Office__c != oldAccount.NSP_Sales_Office__c ||
                        newAccount.NSP_Sales_Division__c != oldAccount.NSP_Sales_Division__c ||
                     newAccount.NSP_SalesRegion__c != oldAccount.NSP_SalesRegion__c )){
                    if(salesOfficeToMappingMap.containsKey(newAccount.NSP_Sales_Office__c)){
                        NSP_Sales_Office_Mapping__c officeMapping = salesOfficeToMappingMap.get(newAccount.NSP_Sales_Office__c);
                        newAccount.NSP_Sales_Division__c = officeMapping.NSP_Sales_Division__c;
                        newAccount.NSP_SalesRegion__c = officeMapping.NSP_Sales_Region__c;
                    }
                }
            }
        }
        if ( !newSalesOffice.isEmpty() ) {
            NSP_AccountTriggerHelper.updateRelatedOpportunity( newSalesOffice , oldAccountOwner );
            // AZD-219422
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

    //
    // Publishes events for Accounts deleted by merge.
    // @param oldList List of Account.
    // @param oldMap List of Account.
    // @return void
    // Story 199298
    // Author           | Date              | Description
    // -------------------------------------------------------------------------------------
    // Matt M.         01/19/2023           Created this method
    //
    public void afterDeleteDirector( List<Account> oldList , Map<Id,Account> oldMap ) {
        try {
            List<Integration_Account_Delete_Event__e> accountDeleteEventList = New List<Integration_Account_Delete_Event__e>();
            // Iterating Trigger.new to feed the Account Id to Event List
            for ( Account accObj : oldList ) {
                if ( accObj.MasterRecordId != null ) { // result of Account merge
                    accountDeleteEventList.add(
                        new Integration_Account_Delete_Event__e(
                            Id__c=accObj.Id,
                            MasterRecordId__c=accObj.MasterRecordId
                        )
                    );
                }
            }
            // Send the list to publish event bus
            if ( !accountDeleteEventList.isEmpty() ) {
                if ( PlatformEventSettings__c.getInstance( UserInfo.getUserId() ).IsEnabled_IntegrationAccountDeleteEvent__c ) { // see also "Trigger Switch" Custom Setting
                    this.publishEventBus( accountDeleteEventList , new List<Account>() );
                }
            }
        } catch ( Exception e ) {
            NSP_AccountTriggerHelper.handleException( e , 'afterDeleteDirector' );
        }
    }

    //
    // Description: This method create for update field Payroll Employee Of Account Group Member From Payroll Employee Of Account
    //
    // @param: Map <Id, Account> newMap, Map <Id, Account> oldMap
    // @return: void
    // Modification History:
    // -------------------------------------------------------------------------------------
    //  Date              | Description
    // -------------------------------------------------------------------------------------
    //  03/11/2022          created this new method added for STY-02846
    //
    public static void updateAGMPayrollEmployees( Map <Id, Account> newMap, Map <Id, Account> oldMap) {
        List<NSP_Account_Group_Member__c>  accGroupMemberToBeUpdated = new List<NSP_Account_Group_Member__c>();
        Map<Id, decimal> accPayrollByIds = new Map<Id, decimal>();

        // put accountId By Payroll Employees in Map
        for(Account accList : newMap.Values()) {
            if(accList.NSP_Payroll_employee__c != oldMap.get(accList.Id).NSP_Payroll_employee__c) {
                accPayrollByIds.put(accList.Id, accList.NSP_Payroll_employee__c);
            }
        }

        // update Account Group Member field Payroll Employees From Account field Payroll Employees
        if(!accPayrollByIds.isEmpty()) {
            for(NSP_Account_Group_Member__c accGroMember : [SELECT Id, NSP_Member_Account__c, NSP_Payroll_Employees__c FROM NSP_Account_Group_Member__c WHERE NSP_Member_Account__c =:accPayrollByIds.keySet()]) {
                if(accGroMember.NSP_Payroll_Employees__c != accPayrollByIds.get(accGroMember.NSP_Member_Account__c)) {
                    accGroMember.NSP_Payroll_Employees__c = accPayrollByIds.get(accGroMember.NSP_Member_Account__c);
                    accGroupMemberToBeUpdated.add(accGroMember);
                }
            }
        }
        if(!accGroupMemberToBeUpdated.isEmpty()) {
            update accGroupMemberToBeUpdated;
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