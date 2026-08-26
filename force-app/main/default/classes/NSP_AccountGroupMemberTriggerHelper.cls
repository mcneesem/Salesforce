public with sharing class NSP_AccountGroupMemberTriggerHelper {
    // test w/ NSP_AccountGroupMemberTriggerHelperTest (87%)

    private static final Id woAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'WO' );
    private static final Id automaticallyCreatedAccountGroupRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'NSP_Account_Group__c' , 'Automatically_Created' );
    private static final Id wxAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'NSP_Asset_Product' );

    //
    // @Description  : Iterates throught the list of new Account GroupMembers
    // @param        : List<NSP_Account_Group_Member__c> newList, Map<Id, NSP_Account_Group_Member__c> newMap
    // @return       : void
    //
    public static void afterInsertDirector( List<NSP_Account_Group_Member__c> newList , Map<Id,NSP_Account_Group_Member__c> newMap ) {
        try {
            defaultPrimaryFirstAccountGroupMember( newList );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountGroupMemberTriggerHelper.class.getName() ,
                'afterInsertDirector' ,
                e
            );
        }
    }

    //
    // @Description  : Iterates throught the list and map of old Account GroupMembers
    // @param        : List<sObject> oldList , Map<Id, sObject> oldMap
    // @return       : void
    //
    public static void afterDeleteDirector( List<NSP_Account_Group_Member__c> oldList , Map<Id,NSP_Account_Group_Member__c> oldMap ) {
        try {
            NSP_AccountGroupMemberTriggerHelper.updatePrimaryForLastGroupMember( oldList , oldMap );
            NSP_AccountGroupMemberTriggerHelper.createSelfGroupForAccount( oldList );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountGroupMemberTriggerHelper.class.getName() ,
                'afterDeleteDirector' ,
                e
            );
        }
    }

    private static void createSelfGroupForAccount( List<NSP_Account_Group_Member__c> oldList ) {
        if ( AccountGroupMemberTriggerSettings__c.getInstance( UserInfo.getUserId() ).IsEnabled__c
            && ( oldList != null )
            && !oldList.isEmpty()
            )
        {
            Set<Id> growthForecastAccountIds = NSP_AccountGroupMemberTriggerHelper.getGrowthForecastAccountIds( oldList );
            Set<Id> accountHasWO = NSP_AccountGroupMemberTriggerHelper.getWoAssetAccountIds( growthForecastAccountIds );
            Map<Id, List<NSP_Account_Group__c>> groupsToCreate = NSP_AccountGroupMemberTriggerHelper.collectGroups(
                oldList ,
                accountHasWO
            );
            NSP_AccountGroupMemberTriggerHelper.insertGroupsAndMembers( groupsToCreate );
        }
    }

    private static Set<Id> getGrowthForecastAccountIds( List<NSP_Account_Group_Member__c> oldList ){
        Set<Id> result = new Set<Id>() ;
        if ( ( oldList != null ) && !oldList.isEmpty() ){
            for ( NSP_Account_Group_Member__c agm : oldList ) {
                if ( ( agm != null )
                    && ( agm.NSP_Type__c == NSP_ServiceConstants.GROWTH_FORECAST )
                    && ( agm.NSP_Member_Account__c != null )
                    )
                {
                    result.add( agm.NSP_Member_Account__c );
                }
            }
        }
        return result;
    }

    private static Map<Id,List<NSP_Account_Group__c>> collectGroups( List<NSP_Account_Group_Member__c> oldList , Set<Id> accountHasWO ){
        Map<Id,List<NSP_Account_Group__c>> result = new Map<Id,List<NSP_Account_Group__c>>() ;
        if ( oldList != null ){
            for ( NSP_Account_Group_Member__c agm : oldList ) {
                if ( ( agm != null ) && !agm.Bypass_Self_Group_Creation__c ) {
                    Map<Id,List<NSP_Account_Group__c>> groupsForAccount = NSP_AccountGroupMemberTriggerHelper.createSelfGroup(
                        agm.Id ,
                        agm.NSP_Member_Account__c ,
                        agm.NSP_Type__c ,
                        agm.NSP_Account_Name__c ,
                        accountHasWO
                    );
                    if ( ( groupsForAccount != null ) && !groupsForAccount.isEmpty() ) {
                        result.putAll( groupsForAccount );
                    }
                }
            }
        }
        return result;
    }

    private static void insertGroupsAndMembers ( Map<Id,List<NSP_Account_Group__c>> allGroupsToCreate ) {
        List<NSP_Account_Group__c> groups = new List<NSP_Account_Group__c>();
        List<NSP_Account_Group_Member__c> members = new List<NSP_Account_Group_Member__c>();
        if ( ( allGroupsToCreate != null ) && !allGroupsToCreate.isEmpty() ) {
            groups = NSP_AccountGroupMemberTriggerHelper.collectGroups( allGroupsToCreate,groups );
            if ( ( groups != null ) && !groups.isEmpty() ) {
                NSP_AccountGroupMemberTriggerHelper.insertWithLogging(
                    groups ,
                    'NSP_Account_Group__c'
                );
                members = NSP_AccountGroupMemberTriggerHelper.collectMembers(
                    allGroupsToCreate ,
                    members
                );
                if ( ( members != null ) && !members.isEmpty() ){
                    NSP_AccountGroupMemberTriggerHelper.insertWithLogging(
                        members ,
                        'NSP_Account_Group_Member__c'
                    );
                }
            }
        }
    }

    private static void insertWithLogging( List<SObject> records , String message ) {
        try {
            List<Database.SaveResult> results = Database.insert( records , false );
            NSP_ErrorLogHandler.logResults(
                NSP_AccountGroupMemberTriggerHelper.class.getName() ,
                'insertWithLogging:insert:' + message ,
                results
            );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountGroupMemberTriggerHelper.class.getName() ,
                'insertWithLogging:' + message ,
                e
            );
        }
    }

    private static List<NSP_Account_Group__c> collectGroups(
        Map<Id,List<NSP_Account_Group__c>> allGroupsToCreate ,
        List<NSP_Account_Group__c> groups
        )
    {
        if ( groups == null ) {
            groups = new List<NSP_Account_Group__c>();
        }
        if ( ( allGroupsToCreate != null ) && !allGroupsToCreate.isEmpty() ) {
            for ( List<NSP_Account_Group__c> lst : allGroupsToCreate.values() ) {
                if ( !lst.isEmpty() ){
                    groups.addAll( lst );
                }
            }
        }
        return groups;
    }

    private static List<NSP_Account_Group_Member__c> collectMembers(
        Map<Id,List<NSP_Account_Group__c>> allGroupsToCreate ,
        List<NSP_Account_Group_Member__c> members
        )
    {
        if ( members == null ) {
            members = new List<NSP_Account_Group_Member__c>();
        }
        if ( ( allGroupsToCreate != null ) && !allGroupsToCreate.isEmpty() ) {
            for ( Id accId : allGroupsToCreate.keySet() ) {
                members = NSP_AccountGroupMemberTriggerHelper.addMembersForAccount(
                    accId ,
                    allGroupsToCreate.get( accId ) ,
                    members
                );
            }
        }
        return members;
    }

    private static List<NSP_Account_Group_Member__c> addMembersForAccount(
        Id accId ,
        List<NSP_Account_Group__c> grpList ,
        List<NSP_Account_Group_Member__c> members
        )
    {
        if ( ( grpList != null ) && !grpList.isEmpty()) {
            for ( NSP_Account_Group__c grp : grpList ) {
                if ( ( accId != null )
                    && ( grp != null )
                    && ( grp.Id != null )
                    )
                {
                    members.add(
                        new NSP_Account_Group_Member__c(
                            NSP_Member_Account__c = accId ,
                            NSP_Group__c = grp.Id ,
                            NSP_Primary__c = true
                        )
                    );
                }
            }
        }
        return members;
    }

    private static Set<Id> getWoAssetAccountIds( Set<Id> accountIds ) {
        Set<Id> result = new Set<Id>() ;
        if ( ( accountIds != null ) && !accountIds.isEmpty() ) {
            for ( Asset a : [
                        SELECT AccountId
                        FROM Asset
                        WHERE (
                            ( AccountId IN :accountIds )
                            AND ( RecordTypeId = :NSP_AccountGroupMemberTriggerHelper.woAssetRecordTypeId )
                        )
                    ]
                )
            {
                result.add( a.AccountId );
            }
        }
        return result;
    }

    private static Map<Id,List<NSP_Account_Group__c>> createSelfGroup(
        Id accountGrpMember ,
        Id accountId ,
        String nspType ,
        String accName ,
        Set<Id> accountHasWO
        )
    {
        Map<Id,List<NSP_Account_Group__c>> result = new Map<Id,List<NSP_Account_Group__c>>();
        if ( ( accountGrpMember != null )
            && ( accountId != null )
            && ( ( nspType == NSP_ServiceConstants.GROWTH_FORECAST )
                || ( nspType == NSP_ServiceConstants.ACCOUNT_HEALTH )
                || ( nspType == NSP_ServiceConstants.RENEWAL_PROBABILITY )
            )
            && !( ( nspType == NSP_ServiceConstants.GROWTH_FORECAST )
                && ( ( accountHasWO == null ) || !accountHasWO.contains( accountId ) )
                )
            )
        {
            NSP_Account_Group__c grp = new NSP_Account_Group__c(
                RecordTypeId = NSP_AccountGroupMemberTriggerHelper.automaticallyCreatedAccountGroupRecordTypeId ,
                Name = nspType ,
                NSP_Account__c = accName ,
                NSP_Type__c = nspType
            );
            result = NSP_AccountGroupMemberTriggerHelper.addToMap(
                result ,
                accountId ,
                grp
            );
        }
        return result;
    }

    private static Map<Id,List<NSP_Account_Group__c>> addToMap(
        Map<Id,List<NSP_Account_Group__c>> accMap ,
        Id accId ,
        NSP_Account_Group__c accGroup
        )
    {
        if ( accMap == null ) {
            accMap = new Map<Id,List<NSP_Account_Group__c>>();
        }
        if ( ( accId != null ) && ( accGroup != null ) ) {
            if ( !accMap.containsKey( accId ) ) {
                accMap.put(
                    accId ,
                    new List<NSP_Account_Group__c>()
                );
            }
            accMap.get( accId ).add( accGroup );
        }
        return accMap;
    }

    //
    // Iterates throught the list of new Account GroupMembers and old Account GroupMembers
    // @param newList List of New Account Group Members.
    // @return void
    //
    public void afterInsertIsPrimary( List<NSP_Account_Group_Member__c> newList , Map<Id,NSP_Account_Group_Member__c> oldMap ) {
        try {
            Map<String,String> mapAccIdGrp = new Map<String,String>();
            //check if primary is changed will update the new Primary Account group Member
            for ( NSP_Account_Group_Member__c accGrpM : newList ) {
                if ( ( ( oldMap == null ) && accGrpM.NSP_Primary__c )
                    || ( ( oldMap != null ) && accGrpM.NSP_Primary__c && ( accGrpM.NSP_Primary__c != oldMap.get( accGrpM.Id ).NSP_Primary__c ) )
                    )
                {
                    mapAccIdGrp.put( accGrpM.NSP_Group__c , accGrpM.NSP_Member_Account__c );
                }
            }
            //update the Account Group with the Primary Account
            if ( !mapAccIdGrp.isEmpty() ) {
                updatePrimaryAccounts( mapAccIdGrp );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountGroupMemberTriggerHelper.class.getName() ,
                'afterInsertIsPrimary' ,
                e
            );
        }
    }

    //
    // Find all the group Name will be update with account if primary is checked
    // @param mapAccIdGrp of groupId and Account.
    // @return void
    //
    private void updatePrimaryAccounts( Map<String,String> mapAccIdGrp ) {
        List<NSP_Account_Group__c> lstOfAccGrps = new List<NSP_Account_Group__c>();
        List<NSP_Account_Group_Member__c> lstOfAccGrpsMembrs = new List<NSP_Account_Group_Member__c>();
        if ( mapAccIdGrp != null ) {
            Map<Id,Account> mapAccounts = new Map<Id,Account>([
                SELECT Id , Name
                FROM Account
                WHERE ( Id IN :mapAccIdGrp.values() )
            ]);
            lstOfAccGrps = updateAccountGroups(mapAccIdGrp, mapAccounts);
            lstOfAccGrpsMembrs = updateGroupMembers(mapAccIdGrp);
        }
        if (!lstOfAccGrps.isEmpty()) {
            Database.SaveResult[] results = Database.update( lstOfAccGrps , false );
            NSP_ErrorLogHandler.logResults(
                NSP_AccountGroupMemberTriggerHelper.class.getName() ,
                'updatePrimaryAccounts:NSP_Account_Group__c' ,
                results
            );
        }
        if (!lstOfAccGrpsMembrs.isEmpty()) {
            Database.SaveResult[] results = Database.update( lstOfAccGrpsMembrs , false );
            NSP_ErrorLogHandler.logResults(
                NSP_AccountGroupMemberTriggerHelper.class.getName() ,
                'updatePrimaryAccounts:NSP_Account_Group_Member__c' ,
                results
            );
        }
    }

    private List<NSP_Account_Group__c> updateAccountGroups(Map<String, String> mapAccIdGrp, Map<Id, Account> mapAccounts) {
        List<NSP_Account_Group__c> lstOfAccGrps = new List<NSP_Account_Group__c>();
        if ( ( mapAccIdGrp != null )
            && !mapAccIdGrp.isEmpty()
            && ( mapAccounts != null )
            && !mapAccounts.isEmpty()
            )
        {
            Boolean hasBypassPermission = CustomPermissionController.checkUserPermission(
                'Bypass_Termination_Reason_Rules' ,
                UserInfo.getUserId()
            );
            for ( NSP_Account_Group__c accGrp : [
                        SELECT
                            Id ,
                            NSP_Account__c ,
                            NSP_Type__c ,
                            Primary_Term_Reason__c ,
                            Sub_Term_Reason__c ,
                            Termination_Key_Points__c ,
                            Eligible_To_Return_To_Insperity_At_Time__c ,
                            Termination_Anticipated__c ,
                            Did_Client_Go_To_A_Competitor__c ,
                            Why_Why_Not__c ,
                            Competitor__c ,
                            Other_Competitor__c ,
                            Account__r.WO_Asset__r.NSP_Written_Term_recd__c
                        FROM NSP_Account_Group__c
                        WHERE (
                            ( Id IN :mapAccIdGrp.keyset() )
                            AND ( NSP_Type__c != :NSP_ServiceConstants.TYPECONTROLLEDGROUP )
                        )
                    ]
                )
            {
                Id accountId = mapAccIdGrp.get( accGrp.Id );
                Boolean violatesPrimaryTerminationReasonRule = (
                    !hasBypassPermission
                    && ( accGrp.Account__r != null )
                    && ( accGrp.Account__r.WO_Asset__r != null )
                    && accGrp.Account__r.WO_Asset__r.NSP_Written_Term_recd__c
                    && ( accGrp.NSP_Type__c == 'Renewal Probability' )
                    && this.hasIncompleteTerminationInfo( accGrp )
                );
                if ( ( accountId != null )
                    && mapAccounts.containsKey( accountId )
                    && ( mapAccounts.get( accountId ) != null )
                    && !violatesPrimaryTerminationReasonRule
                    )
                {
                    accGrp.NSP_Account__c = mapAccounts.get( accountId ).Name;
                    accGrp.Account__c = accountId;
                    lstOfAccGrps.add( accGrp );
                }
            }
        }
        return lstOfAccGrps;
    }

    private Boolean hasIncompleteTerminationInfo( NSP_Account_Group__c accGrp ) {
        return (
            ( accGrp != null )
            && (
                String.isBlank( accGrp.Primary_Term_Reason__c )
                || String.isBlank( accGrp.Sub_Term_Reason__c )
                || String.isBlank( accGrp.Termination_Key_Points__c )
                || String.isBlank( accGrp.Eligible_To_Return_To_Insperity_At_Time__c )
                || String.isBlank( accGrp.Termination_Anticipated__c )
                || String.isBlank( accGrp.Did_Client_Go_To_A_Competitor__c )
                || String.isBlank( accGrp.Why_Why_Not__c )
                || ( ( accGrp.Did_Client_Go_To_A_Competitor__c == 'Yes' ) && String.isBlank( accGrp.Competitor__c ) )
                || ( ( accGrp.Competitor__c == 'Other' ) && String.isBlank( accGrp.Other_Competitor__c ) )
            )
        );
    }

    private List<NSP_Account_Group_Member__c> updateGroupMembers(Map<String, String> mapAccIdGrp) {
        List<NSP_Account_Group_Member__c> lstOfAccGrpsMembrs = new List<NSP_Account_Group_Member__c>();
        if(mapAccIdGrp != null){
            for ( NSP_Account_Group_Member__c accGrpMem : [
                        SELECT Id , NSP_Primary__c , NSP_Group__r.NSP_Type__c
                        FROM NSP_Account_Group_Member__c
                        WHERE (
                            ( NSP_Group__c IN :mapAccIdGrp.keyset() )
                            AND ( NSP_Member_Account__c NOT IN :mapAccIdGrp.values() )
                            AND ( NSP_Primary__c = true )
                            AND ( NSP_Group__r.NSP_Type__c != :NSP_ServiceConstants.TYPECONTROLLEDGROUP )
                        )
                    ]
                )
            {
                accGrpMem.NSP_Primary__c = false;
                lstOfAccGrpsMembrs.add( accGrpMem );
            }
        }
        return lstOfAccGrpsMembrs;
    }

    //
    // List of AccountGroupMember to Account and Group Relation Duplicate validations
    // @param mapAccIdGrp of groupId and Account.
    // @return void
    //
    public void validateDuplicapteGroupMembers( List<NSP_Account_Group_Member__c> lstAccGrpMembers ) {
        try {
            Map<String,String> mapAccountIdGroupId = new Map<String,String>();
            for(NSP_Account_Group_Member__c accGrpMem : lstAccGrpMembers){
                mapAccountIdGroupId.put(accGrpMem.NSP_Member_Account__c,accGrpMem.NSP_Group__c);
            }
            Map<Id,NSP_Account_Group_Member__c> mapExistingGrpMembs = new Map<Id,NSP_Account_Group_Member__c>();
            //Query existing Account and Group Relation if already exists
            for(NSP_Account_Group_Member__c accGrpMem: [SELECT Id,NSP_Member_Account__c,NSP_Group__c  FROM NSP_Account_Group_Member__c WHERE NSP_Member_Account__c IN:mapAccountIdGroupId.keySet() AND NSP_Group__c IN: mapAccountIdGroupId.values()]){
                mapExistingGrpMembs.put(accGrpMem.NSP_Member_Account__c,accGrpMem);
            }
            for(NSP_Account_Group_Member__c accGrpMem : lstAccGrpMembers){
                //If already exists throw validation
                if(mapExistingGrpMembs.containsKey(accGrpMem.NSP_Member_Account__c) && mapExistingGrpMembs.get(accGrpMem.NSP_Member_Account__c).NSP_Group__c == accGrpMem.NSP_Group__c){
                    accGrpMem.addError(label.NSP_AccountGroupMemberDuplicateEntryMessage);
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountGroupMemberTriggerHelper.class.getName() ,
                'validateDuplicapteGroupMembers' ,
                e
            );
        }
    }

    //
    // AccountGroupMember -> validation for WXAccountGroup Members on delete
    // @param  List<NSP_Account_Group_Member__c> lstAccGrpMembers
    // @return void
    //
    public void preventDeleteForWXAccountGroupMembers(List<NSP_Account_Group_Member__c> lstAccGrpMembers){
        User getUser  = [SELECT Id, Profile.Name From User WHERE Id =:userinfo.getUserId()];
        for (NSP_Account_Group_Member__c accGrpMember : lstAccGrpMembers) {
            if(isWxAccountGroupMember(accGrpMember) && getUser.Profile.Name != 'Integeration User'){
                accGrpMember.addError(label.NSP_AccountGroupErrorMessage);
            }
        }
    }

    //
    // AccountGroupMember -> check is it valid AccountGroup Member to Delete
    // @param  NSP_Account_Group_Member__c accGrpMember
    // @return Boolean
    //
    private boolean isWxAccountGroupMember(NSP_Account_Group_Member__c accGrpMember){
        String profileName = [Select Id,Name from Profile WHERE Id=:userinfo.getProfileId()]?.Name;
        return (
            accGrpMember.NSP_Type__c == NSP_ServiceConstants.ISOLVED
            && (profileName == NSP_ServiceConstants.PEOSERVICE
                || profileName == NSP_ServiceConstants.CONTACTCENTER
                || profileName == NSP_ServiceConstants.BPSSERVICE
                || profileName == NSP_ServiceConstants.RT
                || profileName == NSP_ServiceConstants.PEO
                || profileName == NSP_ServiceConstants.BPS
                )
            );
    }

    //
    // Description: This method is used to update Payroll Employee Of Account Group Member from Payroll Employee Of Account
    // @param: Map <Id, Account> newMap, Map <Id, Account> oldMap
    // @return: void
    //
    public static void updateAGMAccountPayrollEmployees(List<NSP_Account_Group_Member__c> newList, Map <Id, NSP_Account_Group_Member__c> oldMap) {
        Map<Id, Decimal> accPayrollByIds = new Map<Id, Decimal>();
        Set<Id> accIds = New Set<Id>();
        // Get exesting account Id vased on change of account or new AGM
        for(NSP_Account_Group_Member__c accGMList : newList) {
            if((oldMap == null  && accGMList.NSP_Member_Account__c != null) || (oldMap != null && accGMList.NSP_Member_Account__c !=null
             && accGMList.NSP_Member_Account__c != oldMap.get(accGMList.Id).NSP_Member_Account__c)) {
                accIds.add(accGMList.NSP_Member_Account__c);
            }
        }
        if(!accIds.isEmpty()) {
            for(Account acc : [SELECT Id, NSP_Payroll_employee__c FROM Account WHERE Id =:accIds ]) {
                accPayrollByIds.put(acc.Id, acc.NSP_Payroll_employee__c);
            }
         }
        if(!accPayrollByIds.isEmpty()) {
            for(NSP_Account_Group_Member__c accGroMember : newList ) {
               // update Account Group Member field Payroll Employees From Account field Payroll Employees
                if(accPayrollByIds.containsKey(accGroMember.NSP_Member_Account__c)  && accPayrollByIds.get(accGroMember.NSP_Member_Account__c) != null && accGroMember.NSP_Payroll_Employees__c != accPayrollByIds.get(accGroMember.NSP_Member_Account__c)){
                    accGroMember.NSP_Payroll_Employees__c = accPayrollByIds.get(accGroMember.NSP_Member_Account__c);
                } else {
                    //if Account has blank Payroll Employee
                    accGroMember.NSP_Payroll_Employees__c = null;
                }
            }
        }
    }

    //
    // @MethodName : updatePrimaryForLastGroupMember
    // @Description: This method will update the last member of Account Group as Primary
    // @param      : List<NSP_Account_Group_Member__c> oldList, Map<Id, NSP_Account_Group_Member__c> oldMap
    // @Story      : STY-03316
    // @return     : void
    //
    public static void updatePrimaryForLastGroupMember( List<NSP_Account_Group_Member__c> oldList , Map<Id,NSP_Account_Group_Member__c> oldMap ) {
        try {
            Map<String,String> wxGrpIdWithAccountId = new Map<String,String>();
            Map<String,String> mapAccIdGrp = new Map<String,String>();
            List<NSP_Account_Group__c> lstOfAccGrps = new List<NSP_Account_Group__c>();
            List<NSP_Account_Group__c> lstOfAccGrpsToUpdate = new List<NSP_Account_Group__c>();
            List<NSP_Account_Group_Member__c> lstOfAccGrpsMembrs = new List<NSP_Account_Group_Member__c>();
            List<NSP_Account_Group_Member__c> lstOfNonPrimaryAccGrpMembrs = new List<NSP_Account_Group_Member__c>();
            for(NSP_Account_Group_Member__c accGrpM: oldList){
                if(oldMap != null && accGrpM.NSP_Primary__c == true && accGrpM.NSP_Type__c != NSP_ServiceConstants.ISOLVED){
                    mapAccIdGrp.put(accGrpM.NSP_Group__c, accGrpM.NSP_Member_Account__c);
                } else if(accGrpM.NSP_Primary__c == true && accGrpM.NSP_Type__c == NSP_ServiceConstants.ISOLVED){
                    wxGrpIdWithAccountId.put(accGrpM.NSP_Group__c, accGrpM.NSP_Member_Account__c);
                }
            }
            if(!wxGrpIdWithAccountId.isEmpty()){
                updatePrimaryAccountForWxAccountGroup(wxGrpIdWithAccountId);
            }
            //Setting Account Group Name to update with Primary Account Group Member Name
            lstOfAccGrps = setAccountGroupName(mapAccIdGrp);
            //Update the Account Group Member record to primary which is associated to that group
            for(NSP_Account_Group_Member__c accGrpMem: [
                        SELECT Id , NSP_Primary__c , NSP_Group__r.NSP_Account__c
                        FROM NSP_Account_Group_Member__c
                        WHERE (
                            NSP_Group__c IN :mapAccIdGrp.keyset()
                            AND NSP_Primary__c = false
                            AND NSP_Group__r.NSP_Type__c != :NSP_ServiceConstants.TYPECONTROLLEDGROUP
                        )
                    ]
                )
            {
                lstOfNonPrimaryAccGrpMembrs.add(accGrpMem);
                accGrpMem.NSP_Primary__c = true;
                lstOfAccGrpsMembrs.add(accGrpMem);
            }
            //Remove Account Name from Account Group Name if there is no Primary Group Member in Account Group
            if(!lstOfNonPrimaryAccGrpMembrs.isEmpty() || lstOfNonPrimaryAccGrpMembrs.isEmpty()){
                lstOfAccGrpsToUpdate = removeAccountNameFromGroupName(mapAccIdGrp.keyset());
            }
            //Update Account Group Name if there is not Primary Group Member in Account Group
            if ( !lstOfAccGrpsToUpdate.isEmpty() ) {
                Database.SaveResult[] results = Database.update( lstOfAccGrpsToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AccountGroupMemberTriggerHelper.class.getName() ,
                    'updatePrimaryForLastGroupMember:NSP_Account_Group__c:1' ,
                    results
                );
            }
            //Update Account Group Name with Primary Group Member Name in it if there is any Primary Group Member in Account Group
            if ( !lstOfAccGrps.isEmpty() ) {
                Database.SaveResult[] results = Database.update( lstOfAccGrps , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AccountGroupMemberTriggerHelper.class.getName() ,
                    'updatePrimaryForLastGroupMember:NSP_Account_Group__c:2' ,
                    results
                );
            }
            //Update last Account Group Member to a Primary Group Member in the Account Group
            if ( !lstOfAccGrpsMembrs.isEmpty() && ( lstOfAccGrpsMembrs.size() == 1 ) ) {
                Database.SaveResult[] results = Database.update( lstOfAccGrpsMembrs , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AccountGroupMemberTriggerHelper.class.getName() ,
                    'updatePrimaryForLastGroupMember:NSP_Account_Group_Member__c' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountGroupMemberTriggerHelper.class.getName() ,
                'updatePrimaryForLastGroupMember' ,
                e
            );
        }
    }

    //
    // @MethodName : updatePrimaryAccountForWxAccountGroup
    // @Description: This method for testing WX Account Group
    //    if primary account is deleted from Account Group Member then Assign the Primary
    //    Account i.e from Asset WX child lowest Number as Primary Group Member
    // @param      : wxGrpIdWithAccountId
    // @Story      : DF-05135
    // @return     : void
    //
    private static void updatePrimaryAccountForWxAccountGroup( Map<String,String> wxGrpIdWithAccountId ) {
        Map<String, Id> wxParentIdWithAccountId = new Map<String, Id>();
        List<NSP_Account_Group_Member__c> lstGrpMembers= new List<NSP_Account_Group_Member__c>();
        Map<Id, Set<Id>> grpIdWithAccounts = new Map<Id, Set<Id>>();
        Map<String, NSP_Account_Group_Member__c> acctWithGrpMember = new Map<String, NSP_Account_Group_Member__c>();
        Map<Id, Id> grpIdWithAccId = new Map<Id, Id>();
        if(!wxGrpIdWithAccountId.isEmpty()){
            for(NSP_Account_Group__c accGrp : [
                        SELECT
                            Id ,
                            (
                                SELECT
                                    Id ,
                                    NSP_Group__c ,
                                    NSP_Member_Account__c
                                FROM Account_Group_Members__r
                            )
                        FROM NSP_Account_Group__c
                        WHERE ( Id IN :wxGrpIdWithAccountId.keySet() )
                    ]
                )
            {
                if(!grpIdWithAccounts.containsKey(accGrp.Id)) {
                    grpIdWithAccounts.put(accGrp.Id, new Set<Id>());
                }
                for(NSP_Account_Group_Member__c accGrpMber : accGrp.Account_Group_Members__r) {
                    grpIdWithAccounts.get(accGrp.Id).add(accGrpMber.NSP_Member_Account__c);
                    acctWithGrpMember.put(accGrpMber.NSP_Group__c+'_'+accGrpMber.NSP_Member_Account__c, accGrpMber);
                }
            }
        }
        if(!wxGrpIdWithAccountId.isEmpty()) {
            for ( Asset asset: [
                        SELECT AccountId , NSP_WX_WA_Parent_ID__c , NSP_WX_WA_CHILD_ID__c
                        FROM Asset
                        WHERE (
                            AccountId IN (
                                SELECT NSP_Member_Account__c
                                FROM NSP_Account_Group_Member__c
                                WHERE NSP_Group__c IN :wxGrpIdWithAccountId.keySet()
                            )
                            AND NSP_WX_WA_Parent_ID__c != NULL
                            AND NSP_WX_WA_CHILD_ID__c != NULL
                            AND RecordTypeId = :NSP_AccountGroupMemberTriggerHelper.wxAssetRecordTypeId
                            AND AccountId NOT IN :wxGrpIdWithAccountId.values()
                            AND (
                                Status != :NSP_ServiceConstants.ASSETBLACKOUT
                                OR Status != :NSP_ServiceConstants.TERMINATED
                            )
                        )
                        ORDER BY NSP_WX_WA_Parent_ID__c , NSP_WX_WA_CHILD_ID__c ASC NULLS LAST
                    ]
                )
            {
                if ( !wxParentIdWithAccountId.containsKey( asset.NSP_WX_WA_Parent_ID__c ) ) {
                    wxParentIdWithAccountId.put(
                        asset.NSP_WX_WA_Parent_ID__c ,
                        asset.AccountId
                    );
                }
            }
        }
        if(!grpIdWithAccounts.isEmpty()) {
            for(Id grpId : grpIdWithAccounts.keySet()) {
                for(String parentId : wxParentIdWithAccountId.keySet()) {
                    Set<Id> accts = grpIdWithAccounts.get(grpId);
                    if(accts.retainAll(new Set<Id>{ wxParentIdWithAccountId.get(parentId) })) {
                        grpIdWithAccId.put(grpId, wxParentIdWithAccountId.get(parentId));
                        break;
                    }
                }
            }
        }
        if(!grpIdWithAccId.isEmpty()) {
            for(String grpId : grpIdWithAccId.keySet()) {
                Id accountId = grpIdWithAccId.get(grpId);
                NSP_Account_Group_Member__c accGrpMbr = acctWithGrpMember.get(grpId+'_'+accountId);
                accGrpMbr.NSP_Primary__c = true;
                lstGrpMembers.add(accGrpMbr);
            }
        }
        if ( !lstGrpMembers.isEmpty() ) {
            Database.SaveResult[] results = Database.update( lstGrpMembers , false );
            NSP_ErrorLogHandler.logResults(
                NSP_AccountGroupMemberTriggerHelper.class.getName() ,
                'updatePrimaryAccountForWxAccountGroup' ,
                results
            );
        }
    }

    //
    // @MethodName : removeAccountNameFromGroupName
    // @Description: This method will remove Account Name from Group Name
    // @param      : Map<String,String> mapAccIdGrp
    // @Story      : STY-03316
    // @return     : void
    //
    public static List<NSP_Account_Group__c> removeAccountNameFromGroupName(Set<String> accGrpIdSet){
        List<NSP_Account_Group__c> lstOfAccGrpsToUpdate = new List<NSP_Account_Group__c>();
        for(NSP_Account_Group__c accGroup: [SELECT Id, Name, NSP_Type__c, NSP_Account__c, NSP_Tag__c FROM NSP_Account_Group__c WHERE Id IN:accGrpIdSet]){
            String groupName = '';
            if(String.isNotBlank(accGroup.NSP_Account__c) && accGroup.Name.contains(' - '+accGroup.NSP_Account__c)){
                groupName = accGroup.Name.remove(' - '+accGroup.NSP_Account__c);
            }
            accGroup.Name = groupName;
            lstOfAccGrpsToUpdate.add(accGroup);
        }
        return lstOfAccGrpsToUpdate;
    }

    //
    // @MethodName : setAccountGroupName
    // @Description: This method will set Account Group Name
    // @param      : Map<String,String> mapAccIdGrp
    // @Story      : STY-03316
    // @return     : void
    //
    public static List<NSP_Account_Group__c> setAccountGroupName( Map<String,String> mapAccIdGrp ) {
        List<NSP_Account_Group__c> lstOfAccGrps = new List<NSP_Account_Group__c>();
        if ( ( mapAccIdGrp != null ) && !mapAccIdGrp.isEmpty() ) {
            String query = new NSP_QueryBuilder(
                    'Account' ,
                    new List<String>{ 'Id' , 'Name' }
                )
                .addFilter(
                    'Id' ,
                    mapAccIdGrp.values() ,
                    NSP_QueryBuilder.Operator.INCLUDES
                )
                .build();
            List<Account> accountList = (List<Account>)Database.query( query );
            Map<Id,Account> mapAccounts = new Map<Id,Account>( accountList );
            for ( NSP_Account_Group__c accGrp : [
                        SELECT Id , NSP_Account__c
                        FROM NSP_Account_Group__c
                        WHERE (
                            ( Id IN :mapAccIdGrp.keyset() )
                            AND ( NSP_Type__c != :NSP_ServiceConstants.TYPECONTROLLEDGROUP )
                        )
                    ]
                )
            {
                if ( mapAccIdGrp.containskey( accGrp.Id )
                    && ( mapAccIdGrp.get( accGrp.Id ) != null )
                    && ( mapAccounts != null )
                    && mapAccounts.containskey( mapAccIdGrp.get( accGrp.Id ) )
                    && ( mapAccounts.get( mapAccIdGrp.get( accGrp.Id ) ) != null )
                    )
                {
                    accGrp.NSP_Account__c = mapAccounts.get( mapAccIdGrp.get( accGrp.Id ) ).Name;
                    accGrp.Account__c = mapAccIdGrp.get( accGrp.Id );
                    lstOfAccGrps.add( accGrp );
                }
            }
        }
        return lstOfAccGrps;
    }

    //
    // @MethodName : defaultPrimaryFirstAccountGroupMember
    // @Description: This method will update First Account Group Member as primary
    // @param      : List<NSP_Account_Group_Member__c> accGrpMemList
    // @Story      : STY-03316
    // @return     : void
    //
    public static void defaultPrimaryFirstAccountGroupMember( List<NSP_Account_Group_Member__c> accGrpMemList ) {
        try {
            Map<String,String> mapAccIdGrp = new Map<String,String>();
            List<NSP_Account_Group__c> lstOfAccGrps = new List<NSP_Account_Group__c>();
            List<NSP_Account_Group_Member__c> accGrpMemberList = new List<NSP_Account_Group_Member__c>();
            List<NSP_Account_Group_Member__c> accGrpMemberListToUpdate = new List<NSP_Account_Group_Member__c>();
            for(NSP_Account_Group_Member__c accGrpMem : accGrpMemList){
                if(accGrpMem.NSP_Group__c != null && accGrpMem.NSP_Primary__c == false && accGrpMem.NSP_Group__r.NSP_Type__c != NSP_ServiceConstants.TYPECONTROLLEDGROUP){
                    mapAccIdGrp.put(accGrpMem.NSP_Group__c, accGrpMem.NSP_Member_Account__c);
                }
            }
            if(mapAccIdGrp != null){
                List<String> accGrpMemFields = new List<String>{'Id','Name', 'NSP_Group__c','NSP_Primary__c','NSP_Group__r.NSP_Type__c'};
                String accGrpMemQuery = new NSP_QueryBuilder('NSP_Account_Group_Member__c', accGrpMemFields)
                                .addFilter('NSP_Group__c', new List<String>(mapAccIdGrp.keyset()), NSP_QueryBuilder.Operator.INCLUDES).build();
                accGrpMemberList = (List<NSP_Account_Group_Member__c>)Database.query(accGrpMemQuery);
            }
            //Setting Account Group Name to update with Primary Account Group Member Name
            lstOfAccGrps = setAccountGroupName(mapAccIdGrp);
            //Update the Account Group Member record to primary which is associated to that group
            if(!accGrpMemberList.isEmpty() && accGrpMemberList.size() == 1){
                for(NSP_Account_Group_Member__c accGrpMem : accGrpMemberList){
                    if(accGrpMem.NSP_Primary__c == false && accGrpMem.NSP_Group__r.NSP_Type__c != NSP_ServiceConstants.TYPECONTROLLEDGROUP){
                        accGrpMem.NSP_Primary__c = true;
                        accGrpMemberListToUpdate.add(accGrpMem);
                    }
                }
            }
            //Update Account Group Name with Primary Group Member Name in it if there is any Primary Group Member in Account Group
            if ( !lstOfAccGrps.isEmpty() && ( accGrpMemberListToUpdate.size() == 1 ) ) {
                Database.SaveResult[] results = Database.update( lstOfAccGrps , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AccountGroupMemberTriggerHelper.class.getName() ,
                    'defaultPrimaryFirstAccountGroupMember:NSP_Account_Group__c' ,
                    results
                );
            }
            //Update first Account Group Member to a Primary Group Member in the Account Group
            if ( !accGrpMemberListToUpdate.isEmpty() && ( accGrpMemberListToUpdate.size() == 1 ) ) {
                Database.SaveResult[] results = Database.update( accGrpMemberListToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AccountGroupMemberTriggerHelper.class.getName() ,
                    'defaultPrimaryFirstAccountGroupMember:NSP_Account_Group_Member__c' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountGroupMemberTriggerHelper.class.getName() ,
                'defaultPrimaryFirstAccountGroupMember' ,
                e
            );
        }
    }

    //
    // @MethodName : preventAccountGroupsDeleting
    // @Description: This method will restrict account Groups that has only one group
    // @param      : List<NSP_Account_Group_Member__c> accGrpMemList
    // @Story      : STY-04122
    // @return     : void
    //
    public static void preventAccountGroupsDeleting( List<NSP_Account_Group_Member__c> lstAccGrpMembers ) {
        Set<String> adminProfileIds = new Set<String>{
            '00e4x000001r0zsAAA' , // System Administrator
            '00e4x000001dm3lAAA' // System Admin Lite
        };
        Boolean isAdmin = adminProfileIds.contains( UserInfo.getProfileId() );
        List<String> lstGrpTypes = new List<String>{
            NSP_ServiceConstants.ACCOUNT_HEALTH ,
            NSP_ServiceConstants.RENEWAL_PROBABILITY ,
            NSP_ServiceConstants.GROWTH_FORECAST
        };
        for ( NSP_Account_Group_Member__c accGroupMembr : lstAccGrpMembers ) {
            if ( lstGrpTypes.contains( accGroupMembr.NSP_Type__c )
                && !isAdmin
                && !accGroupMembr.NSP_ByPassValidation__c
                && accGroupMembr.NSP_Primary__c
                )
            {
                accGroupMembr.addError( label.NSP_AccountCannotRemoveFromSelfGroup );
            }
        }
    }
}
//