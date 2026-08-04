public with sharing class NSP_AccountTeamTriggerHelper {
    // test w/ NSP_AccountTeamTriggerTest (79%)

    // Iterates throught the list of new NSP_Account_Team__c and passes the required attributes to other methods.
    public void beforeInsertDirector( List<NSP_Account_Team__c> newList ) {
        try {
            List<NSP_Account_Team__c> newAccountTeamList = new List<NSP_Account_Team__c>();
            Set<String> accountTeamMemberEmployeePerIdSet = new Set<String>();
            Set<String> accountTeamMemberUserIdSet = new Set<String>();
            //Added as part of STY-03667
            Set<Id> accountIdSet = new Set<Id>();
            List<NSP_Account_Team__c> newAcctTeamList=new  List<NSP_Account_Team__c>();
            //Added as part of DF-02431
            Id profileId = userinfo.getProfileId();
            String profileName = [SELECT Id, Name from Profile WHERE Id =: profileId].Name;


            for(NSP_Account_Team__c accountTeamMemberObj : newList) {
                 if(!String.isBlank(accountTeamMemberObj.NSP_PER_ID__c) || accountTeamMemberObj.NSP_User__c != null){
                    accountTeamMemberEmployeePerIdSet.add(accountTeamMemberObj.NSP_PER_ID__c);
                    accountTeamMemberUserIdSet.add(accountTeamMemberObj.NSP_User__c);
                    newAccountTeamList.add(accountTeamMemberObj);
                }
                //Added as part of STY-03667
                //Profile Bypass logic added as part of DF-02431
                if(accountTeamMemberObj.NSP_Account__c!=null && accountTeamMemberObj.NSP_Primary__c &&
                   String.isNotBlank(profileName) && !profileName.containsIgnoreCase(System.label.NSP_Integration_User_Profile_Name)){

                    accountIdSet.add(accountTeamMemberObj.NSP_Account__c);
                    newAcctTeamList.add(accountTeamMemberObj);
                }
            }
            //Added as part of STY-03667
            if(!accountIdSet.isEmpty() && !newAcctTeamList.isEmpty()){
                showErrorOnPrimaryCheckRole(accountIdSet,newAcctTeamList ) ;
            }

            //get employee per id from user
            if(accountTeamMemberEmployeePerIdSet.size() > 0 || accountTeamMemberUserIdSet.size() > 0){
                populateEmployeePerIdOnATMBasedOnUserId(newAccountTeamList, accountTeamMemberEmployeePerIdSet, accountTeamMemberUserIdSet);
            }

        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountTeamTriggerHelper.class.getName() ,
                'beforeInsertDirector' ,
                e
            );
        }
    }

    //populate employee id based on user id on Account Team
    // Updated based on DF-02375
    public void populateEmployeePerIdOnATMBasedOnUserId(List<NSP_Account_Team__c> newList,Set<String> accountTeamIdSet, Set<String> accountTeamMemberUserIdSet){
        Map<String,User> employeeIdMap = new Map<String,User>();
        Map<ID, User> userMap = new Map<ID, User>([SELECT Id, EmployeeNumber,NSP_sales_Office__c FROM User WHERE (EmployeeNumber IN: accountTeamIdSet OR Id IN: accountTeamMemberUserIdSet)]);

        for(User oUser : userMap.values()){
            employeeIdMap.put(oUser.EmployeeNumber,oUser);
        }

        for(NSP_Account_Team__c accountTeamMemberObj : newList) {
            if(employeeIdMap.containsKey(accountTeamMemberObj.NSP_PER_ID__c) && (accountTeamMemberObj.NSP_PER_ID__c != null && accountTeamMemberObj.NSP_User__c == null)) {
                accountTeamMemberObj.NSP_User__c = employeeIdMap.get(accountTeamMemberObj.NSP_PER_ID__c).Id;
            }
            if(!employeeIdMap.containsKey(accountTeamMemberObj.NSP_PER_ID__c) && (accountTeamMemberObj.NSP_PER_ID__c != null && accountTeamMemberObj.NSP_User__c != null)){
                accountTeamMemberObj.NSP_User__c = null;
            }
            if(userMap.containsKey(accountTeamMemberObj.NSP_User__c) && (accountTeamMemberObj.NSP_PER_ID__c == null && accountTeamMemberObj.NSP_User__c != null)) {
                accountTeamMemberObj.NSP_PER_ID__c = userMap.get(accountTeamMemberObj.NSP_User__c).EmployeeNumber;
            }
            if(employeeIdMap.containsKey(accountTeamMemberObj.NSP_PER_ID__c)){
                accountTeamMemberObj.NSP_sales_Office__c = employeeIdMap.get(accountTeamMemberObj.NSP_PER_ID__c).NSP_sales_Office__c;
            }
        }
    }

    //
    // Iterates throught the list of new NSP_Account_Team__c and passes the required attributes to other methods.
    // @param newList List of New NSP_Account_Team__c.
    // @param newMap List of New NSP_Account_Team__c.
    // @return void
    //
    public void afterInsertDirector( List<NSP_Account_Team__c> newList , Map<Id,NSP_Account_Team__c> newMap ) {
        try {
            // collect the active Users in the List of inserted NSP_Account_Team__c records...
            Set<Id> userIds = new Set<Id>();
            for ( NSP_Account_Team__c record : newList ) {
                userIds.add( record.NSP_User__c );
            }
            Boolean isEnabledCheckActiveUsers = AccountTeamTriggerSettings__c.getInstance( UserInfo.getUserId() ).IsEnabledCheckActiveUsers__c;
            Map<Id,User> activeUsers = null;
            if ( isEnabledCheckActiveUsers ) {
                activeUsers = new Map<Id,User>([
                    SELECT Id
                    FROM User
                    WHERE (
                        ( Id IN :userIds )
                        AND ( IsActive = true )
                    )
                ]);
            }
            // process the new NSP_Account_Team__c records...
            Set<Id> accountIdSet = new Set<Id>();
            List<AccountTeamMember> accountTeamMemberList = new List<AccountTeamMember>();
            Map<Id,NSP_Account_Team__c> mapAccountIdtoAccountTeam = new Map<Id,NSP_Account_Team__c>();
            for ( NSP_Account_Team__c accTeamMemberObj : newList ) {
                // prepare to sync Account...
                accountIdSet.add( accTeamMemberObj.NSP_Account__c );
                // prevent DmlException INACTIVE_OWNER_OR_USER by only creating new AccountTeamMember records for active Users...
                if ( !isEnabledCheckActiveUsers
                    || ( ( activeUsers != null ) && activeUsers.containsKey( accTeamMemberObj.NSP_User__c ) )
                    )
                {
                    AccountTeamMember accountTeamMemberObj = new AccountTeamMember();
                    accountTeamMemberObj.AccountId = accTeamMemberObj.NSP_Account__c;
                    accountTeamMemberObj.AccountAccessLevel = NSP_IntegrationConstants.ACCOUNTACCESSLEVELEDIT;
                    accountTeamMemberObj.TeamMemberRole = NSP_IntegrationConstants.TEAMMEMBERROLE;
                    accountTeamMemberObj.UserId = accTeamMemberObj.NSP_User__c;
                    accountTeamMemberList.add( accountTeamMemberObj );
                }
                // STY-03187: Checking if NSP_Role__c field in AccountTeam object is WX/WA Benefits Specialist
                // or WA/WX Payroll Specialist or 401k Plan Consultant then mapping AccountId and accountTeamObject
                if ( String.isNotBlank( accTeamMemberObj.NSP_Role__c )
                    && (
                        accTeamMemberObj.NSP_Role__c == NSP_ServiceConstants.WXWA_BENEFITS
                        || accTeamMemberObj.NSP_Role__c == NSP_ServiceConstants.WXWA_PAYROLL
                        || accTeamMemberObj.NSP_Role__c == NSP_ServiceConstants.PLAN_CONSULTANT
                    )
                )
                {
                    mapAccountIdtoAccountTeam.put( accTeamMemberObj.NSP_Account__c , accTeamMemberObj );
                }
            }
            // insert the new AccountTeamMember records...
            if ( !accountTeamMemberList.isEmpty() ) {
                List<Database.SaveResult> results = Database.insert( accountTeamMemberList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AccountTeamTriggerHelper.class.getName() ,
                    'afterInsertDirector:insert' ,
                    results
                );
            }
            // ready to sync Accounts...
            IntegrationSyncController.setReadyForIntegrationSync( accountIdSet );
            // update the Asset name based on the current account team...
            if ( !mapAccountIdtoAccountTeam.isEmpty() ) {
                updateAccountTeamNameToAssetName( mapAccountIdtoAccountTeam );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountTeamTriggerHelper.class.getName() ,
                'afterInsertDirector' ,
                e
            );
        }
    }

    // update the account team userId to asset to respective NSP_WX_WA_Benefits_Specialist__c
    // NSP_WX_WA_Benefits_Specialist__c, and NSP_Retirement_Service_Plan_Name__c field based on AccountTeam record role
    public void updateAccountTeamNameToAssetName( Map<Id,NSP_Account_Team__c> mapAccountIdtoAccountTeam ) {
        Boolean switchEnabled = AccountTeamTriggerSettings__c.getInstance(UserInfo.getUserId()).IsRetServiceNameChangeEnabled__c;
        List < Asset > listAssetObject = new List < Asset > ();

        //Iterating Asset object based on AccountId
        for (Asset assetObject: [SELECT ID, AccountId,
                                 NSP_WA_WX_Payroll_Specialist__c,
                                 NSP_WX_WA_Benefits_Specialist__c,
                                 NSP_Retirement_Service_Plan_Name__c
                                 FROM Asset
                                 WHERE AccountId IN: mapAccountIdtoAccountTeam.keySet()
                                ]) {
                                    NSP_Account_Team__c accountTeamObject = mapAccountIdtoAccountTeam.get(assetObject.AccountId);
                                    //Populated assert object depending on role field
                                    if (accountTeamObject.NSP_Role__c == NSP_ServiceConstants.WXWA_BENEFITS && String.isNotBlank(accountTeamObject.NSP_User__c)) {
                                        assetObject.NSP_WX_WA_Benefits_Specialist__c = accountTeamObject.NSP_User__c;
                                    } else if (accountTeamObject.NSP_Role__c == NSP_ServiceConstants.WXWA_PAYROLL && String.isNotBlank(accountTeamObject.NSP_User__c)) {
                                        assetObject.NSP_WA_WX_Payroll_Specialist__c = accountTeamObject.NSP_User__c;
                                    } else if (switchEnabled && accountTeamObject.NSP_Role__c == NSP_ServiceConstants.PLAN_CONSULTANT && String.isNotBlank(accountTeamObject.NSP_User__c)) {
                                        assetObject.NSP_Retirement_Service_Plan_Name__c = accountTeamObject.NSP_User__c;
                                    }
                                    listAssetObject.add(assetObject);
                                }

        //updating Asset object field
        try {
            if (listAssetObject.size() > 0) {
                Database.update(listAssetObject);
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountTeamTriggerHelper.class.getName() ,
                'updateAccountTeamNameToAssetName' ,
                e
            );
        }
    }

    // Iterates throught the list of new NSP_Account_Team__c and passes the required attributes to other methods.
    public void beforeUpdateDirector( Map<Id,NSP_Account_Team__c> newMap , Map<Id,NSP_Account_Team__c> oldMap ) {
        try {
            //Added as part of STY-03667
            Set<Id> accountIdSet = new Set<Id>();
            List<NSP_Account_Team__c> newAcctTeamList=new  List<NSP_Account_Team__c>();
            //Added as part of DF-02431
            Id profileId = userinfo.getProfileId();
            String profileName = [SELECT Id, Name from Profile WHERE Id =: profileId].Name;
            Set<String> accountTeamMemberUserIdSet = new Set<String>();
            List<NSP_Account_Team__c> newAccountTeamList=new  List<NSP_Account_Team__c>();
            Set<String> perIdSet = new Set<String>();
            List<NSP_Account_Team__c> perIdActTeamList=new  List<NSP_Account_Team__c>();

            //Profile Bypass logic added as part of DF-02431
            if(String.isNotBlank(profileName) && !profileName.containsIgnoreCase(System.label.NSP_Integration_User_Profile_Name)){
                for(NSP_Account_Team__c accTeam : newMap.values()) {
                  if(accTeam.NSP_Account__c!=null && accTeam.NSP_Primary__c
                     && (oldMap.get(accTeam.Id).NSP_Primary__c!=accTeam.NSP_Primary__c
                       || oldMap.get(accTeam.Id).NSP_Role__c!=accTeam.NSP_Role__c
                       || oldMap.get(accTeam.Id).NSP_Account__c!=accTeam.NSP_Account__c) ){

                           accountIdSet.add(accTeam.NSP_Account__c);
                           newAcctTeamList.add(accTeam);
                  }
                }
            }


            if(!accountIdSet.isEmpty() && !newAcctTeamList.isEmpty()){
                showErrorOnPrimaryCheckRole(accountIdSet,newAcctTeamList ) ;
            }
            for(NSP_Account_Team__c accountTeamMemberObj : newMap.values()) {
                if(accountTeamMemberObj.NSP_User__c != null && accountTeamMemberObj.NSP_User__c != oldMap.get(accountTeamMemberObj.Id).NSP_User__c){
                   accountTeamMemberUserIdSet.add(accountTeamMemberObj.NSP_User__c);
                   newAccountTeamList.add(accountTeamMemberObj);
               }
                if(accountTeamMemberObj.NSP_PER_ID__c != oldMap.get(accountTeamMemberObj.Id).NSP_PER_ID__c
                   && (String.isBlank(accountTeamMemberObj.NSP_PER_ID__c) || '0'.equals(accountTeamMemberObj.NSP_PER_ID__c))
                  ){
                    accountTeamMemberObj.NSP_User__c = null;
                }
                else if(!String.isBlank(accountTeamMemberObj.NSP_PER_ID__c)
                        &&accountTeamMemberObj.NSP_PER_ID__c != oldMap.get(accountTeamMemberObj.Id).NSP_PER_ID__c){
                             perIdActTeamList.add(accountTeamMemberObj);
                            perIdSet.add(accountTeamMemberObj.NSP_PER_ID__c);
                        }
                if(perIdSet.size()>0){
                    populateUserIdOnATMBasedOnPerId(perIdActTeamList, perIdSet);
                }

           }

           //update per id if User on account team changes
            if(accountTeamMemberUserIdSet.size() > 0){
                updatePerIdonUserUpdate(newAccountTeamList, accountTeamMemberUserIdSet);
            }

        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountTeamTriggerHelper.class.getName() ,
                'beforeUpdateDirector' ,
                e
            );
        }
    }

    // This Method populates NSP User if there is a change on the PER Id.
    public void populateUserIdOnATMBasedOnPerId( List<NSP_Account_Team__c> acctTeamList , Set<String> perIdSet ) {
        Map<String,User> employeeIdMap = new Map<String,User>();
        Map<ID, User> userMap = new Map<ID, User>([SELECT Id, EmployeeNumber FROM User WHERE EmployeeNumber IN: perIdSet]);

        for(User oUser : userMap.values()){
            employeeIdMap.put(oUser.EmployeeNumber,oUser);
        }

        for(NSP_Account_Team__c accountTeamMemberObj : acctTeamList) {
            if(employeeIdMap.containsKey(accountTeamMemberObj.NSP_PER_ID__c) && (accountTeamMemberObj.NSP_PER_ID__c != null)){
                accountTeamMemberObj.NSP_User__c = employeeIdMap.get(accountTeamMemberObj.NSP_PER_ID__c).Id;
            }else{
                accountTeamMemberObj.NSP_User__c = null;
            }
        }
    }

    //
    // Iterates throught the list of new NSP_Account_Team__c and passes the required attributes to other methods.
    // @param newMap Map of NSP_Account_Team__c.
    // @param oldMap Map of NSP_Account_Team__c.
    // @return void
    //
    public void afterUpdateDirector( Map<Id,NSP_Account_Team__c> newMap , Map<Id,NSP_Account_Team__c> oldMap ) {
        try{
            Set<Id> accountIdSet = new Set<Id>();
            Map<String,Id> newRolesMap = new Map<String,Id>();
            Map<Id,NSP_Account_Team__c> mapAccountIdtoAccountTeam = new Map<Id,NSP_Account_Team__c>();
            // STY-03187 : Checking if NSP_Role__c field in AccountTeam object is WX/WA Benefits Specialist
            // or WA/WX Payroll Specialist or 401k Plan Consultant then mapping AccountId and accountTeamObject
            for ( NSP_Account_Team__c accTeamMemberObj : newMap.values() ) {
                accountIdSet.add( accTeamMemberObj.NSP_Account__c );
                if ( String.isNotBlank( accTeamMemberObj.NSP_Role__c ) ) {
                    newRolesMap.put(
                        accTeamMemberObj.NSP_Role__c ,
                        accTeamMemberObj.NSP_User__c
                    );
                }
                if ( String.isNotBlank( accTeamMemberObj.NSP_Role__c )
                    && ( ( accTeamMemberObj.NSP_Role__c != oldMap.get(accTeamMemberObj.Id).NSP_Role__c )
                        || ( accTeamMemberObj.NSP_User__c != oldMap.get(accTeamMemberObj.Id).NSP_User__c )
                    )
                    && ( ( accTeamMemberObj.NSP_Role__c == NSP_ServiceConstants.WXWA_BENEFITS )
                        || ( accTeamMemberObj.NSP_Role__c == NSP_ServiceConstants.WXWA_PAYROLL )
                        || ( accTeamMemberObj.NSP_Role__c == NSP_ServiceConstants.PLAN_CONSULTANT )
                    )
                )
                {
                    mapAccountIdtoAccountTeam.put(
                        accTeamMemberObj.NSP_Account__c ,
                        accTeamMemberObj
                    );
                }
            }
            if ( !accountIdSet.isEmpty()
                && ( newRolesMap != null )
                && ( oldMap != null )
                && ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() )
                && AccountTeamTriggerSettings__c.getInstance( UserInfo.getUserId() ).IsEnabledTermFormLookUps__c
                )
            {
                System.enqueueJob(
                    new TermFormLookUpsQueueable(
                        accountIdSet ,
                        newRolesMap ,
                        oldMap.values()
                    )
                );
            }
            Set<Id> accountIdSetToUpdateResyncFlag = new Set<Id>();
            NSP_SObjectUpdateTriggerHelper sObjectUpdateObj = new NSP_SObjectUpdateTriggerHelper();
            accountIdSetToUpdateResyncFlag.addAll(
                sObjectUpdateObj.fetchUpdFieldsLst(
                    NSP_IntegrationConstants.SOBJECT_ACCOUNTTEAM ,
                    newMap ,
                    oldMap
                )
            );
            IntegrationSyncController.setReadyForIntegrationSync( accountIdSetToUpdateResyncFlag );

            //Checking if map of accountId and Account Team is greater than zero or not
            if ( !mapAccountIdtoAccountTeam.isEmpty() ) {
                updateAccountTeamNameToAssetName( mapAccountIdtoAccountTeam );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountTeamTriggerHelper.class.getName() ,
                'afterUpdateDirector' ,
                e
            );
        }
    }

    //
    // MethodName  : updateProjectTaskEmailFields
    // Description : Method to update Project Task Email field
    // Params  : List<NSP_Account_Team__c> newList, Map<Id, NSP_Account_Team__c> oldMap
    //
    public static void updateProjectTaskEmailFields( List<NSP_Account_Team__c> newList , Map<Id,NSP_Account_Team__c> oldMap ) {
        Set<Id> setAccountIds = new Set<Id>();
        Map<String,Set<String>> mapAccTeamEmails = new Map<String,Set<String>>();
        Map<String,NSP_Account_Team__c> mapAccTeamCLHR = new Map<String,NSP_Account_Team__c>();
        List<pse__Project_Task__c> lstProjectTask = new List<pse__Project_Task__c>();
        List<NSP_Account_Team__c> lstAccTeams = new List<NSP_Account_Team__c>();
        for ( NSP_Account_Team__c accTeam : newList ) {
            if ( ( ( oldMap == null )
                && ( accTeam.NSP_Account__c != null )
                )
                || ( ( oldMap != null )
                    && ( accTeam.NSP_Account__c != null )
                    && ( ( oldMap.get( accTeam.Id ).NSP_Account__c != accTeam.NSP_Account__c )
                        || ( accTeam.NSP_Role__c != oldMap.get( accTeam.Id ).NSP_Role__c )
                        )
                    )
                )
            {
                setAccountIds.add( accTeam.NSP_Account__c );
            }
        }
        if ( !setAccountIds.isEmpty() ) {
            lstAccTeams = NSP_AccountTeamTriggerHelper.getAccountTeamRecords( setAccountIds );
            mapAccTeamEmails = NSP_AccountTeamTriggerHelper.getCCAccountTeams( lstAccTeams );
            mapAccTeamCLHR = NSP_AccountTeamTriggerHelper.getAccountTeams( lstAccTeams );
        }
        if ( !mapAccTeamCLHR.isempty() ) {
            for ( pse__Project_Task__c proj : [
                        SELECT Id , NSP_CC_Emails__c , NSP_AccountId__c
                        FROM pse__Project_Task__c
                        WHERE ( NSP_AccountId__c IN :setAccountIds )
                    ]
                )
            {
                if ( mapAccTeamEmails.containsKey( proj.NSP_AccountId__c )
                    && ( mapAccTeamEmails.get( proj.NSP_AccountId__c ) != null )
                    )
                {
                    List<String> ccEmails = new List<String>();
                    ccEmails.addAll( mapAccTeamEmails.get( proj.NSP_AccountId__c ) );
                    proj.NSP_CC_Emails__c = String.join( ccEmails , ',' );
                }
                lstProjectTask.add( proj );
            }
        }
        if ( !lstProjectTask.isEmpty() ) {
            update lstProjectTask;
        }
    }

    private static Map<String,Set<String>> getCCAccountTeams( List<NSP_Account_Team__c> accTeamRecords ) {
        Map<String,Set<String>> mapAccTeamEmails = new Map<String,Set<String>>();
        for(NSP_Account_Team__c accTeam: accTeamRecords){
            if(mapAccTeamEmails.containsKey(accTeam.NSP_Account__c)){
                mapAccTeamEmails.get(accTeam.NSP_Account__c).add(accTeam.NSP_Email__c);
            }else{
                mapAccTeamEmails.put(accTeam.NSP_Account__c,new Set<String>{accTeam.NSP_Email__c});
            }
        }
        return mapAccTeamEmails;
    }

    private static List<NSP_Account_Team__c> getAccountTeamRecords( Set<Id> setAccountIds ) {
        List<String> lstAccTeamRoles = new List<String>{NSP_ServiceConstants.MANAGER_HRSERVICES,NSP_ServiceConstants.PAYROLL_SUPERVISOR,
            NSP_ServiceConstants.CLIENT_LIAISION,NSP_ServiceConstants.HRSpecialist,NSP_ServiceConstants.PayrollSpecialist,
            NSP_ServiceConstants.PERFOMANCE_SPECIALIST,NSP_ServiceConstants.SAFETY_CONSULTANT,NSP_ServiceConstants.BUS_TEAM_HRSP_CL,
            NSP_ServiceConstants.MID_MARKET_ACC_EX,NSP_ServiceConstants.NATIONAL_ACC_EX};
                return [SELECT Id,NSP_Email__c,NSP_Account__c,NSP_First_Name__c,NSP_Last_Name__c,NSP_Role__c FROM NSP_Account_Team__c
                        WHERE NSP_Account__c IN:setAccountIds AND NSP_Role__c IN:lstAccTeamRoles];
    }

    private static Map<String,NSP_Account_Team__c> getAccountTeams(List<NSP_Account_Team__c> accTeamRecords){
        Map<String,NSP_Account_Team__c> mapAccTeamCLHR = new Map<String,NSP_Account_Team__c>();
        for(NSP_Account_Team__c accTeam: accTeamRecords){
            if(accTeam.NSP_Role__c == NSP_ServiceConstants.BUS_TEAM_HRSP_CL){
                mapAccTeamCLHR.put(NSP_ServiceConstants.BUS_TEAM_HRSP_CL, accTeam);
            }
            if(accTeam.NSP_Role__c == NSP_ServiceConstants.CLIENT_LIAISION){
                mapAccTeamCLHR.put(NSP_ServiceConstants.CLIENT_LIAISION, accTeam);
            }
            if(accTeam.NSP_Role__c == NSP_ServiceConstants.HRSpecialist){
                mapAccTeamCLHR.put(NSP_ServiceConstants.HRSpecialist, accTeam);
            }
        }
        return mapAccTeamCLHR;
    }

    // shows error on Account Team when primary checkbox is checked for same role
    public void showErrorOnPrimaryCheckRole( Set<Id> accountIdSet , List<NSP_Account_Team__c> newList ) {
        try {
            if(!accountIdSet.isEmpty()){
                //list all existing primary checked account teams for the set of account id passed
                List<NSP_Account_Team__c> acctTeamList=[SELECT  NSP_Role__c,NSP_Account__c
                                                        FROM NSP_Account_Team__c
                                                        WHERE NSP_Primary__c=TRUE
                                                        AND NSP_Account__c in:accountIdSet];

                Set<string> acctRoleSet=new Set<string>();

                for(NSP_Account_Team__c acctTeam:acctTeamList){
                    //store string combination of account and account team role
                    acctRoleSet.add(acctTeam.NSP_Account__c+'_'+acctTeam.NSP_Role__c);
                }

                if(!acctRoleSet.isEmpty()){
                    for(NSP_Account_Team__c accTeam : newList) {
                        //iterate through new account team list and throw error if the primary is checked for same role
                        if(acctRoleSet.contains(accTeam.NSP_Account__c+'_'+accTeam.NSP_Role__c)){
                            accTeam.addError(System.Label.NSP_AccountTeam_Error);
                        }
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountTeamTriggerHelper.class.getName() ,
                'showErrorOnPrimaryCheckRole' ,
                e
            );
        }
    }

    // used to update Asset Fields on after Insert
    public static void updateAssetServiceRegion( List<NSP_Account_Team__c> newAccTeam , Map<Id,NSP_Account_Team__c> oldMap ) {
        //Get Record Type Id
        Id woRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE );
        Set<Id> accIds = new Set<Id>();
        Map<Id, NSP_Account_Team__c> accountTeams = new  Map<Id, NSP_Account_Team__c>();
        //Filter record based on Insert or Update
        for(NSP_Account_Team__c accTeam : newAccTeam) {
            if ( oldMap == null
                && accTeam.NSP_Account__c != null
                || ( oldMap != null
                    && (
                        ( accTeam.NSP_Role__c != oldMap.get(accTeam.Id).NSP_Role__c )
                        || ( accTeam.NSP_User__c != oldMap.get(accTeam.Id).NSP_User__c )
                    )
                )
            )
            {
                accIds.add(accTeam.NSP_Account__c);
            }
        }
        //Get Account Team's User Serice Region field for Insert case
        if(!accIds.isEmpty()) {
            for(NSP_Account_Team__c accountTeam : [
                        SELECT Id , NSP_User__r.NSP_Service_Region__c , NSP_Role__c , NSP_Account__c
                        FROM NSP_Account_Team__c
                        WHERE (
                            Id =: newAccTeam
                            AND NSP_User__c != null
                            AND NSP_Role__c != null
                            AND NSP_Role__c = 'Manager, HR Services'
                        )
                    ]
                )
            {
                accountTeams.put(accountTeam.NSP_Account__c, accountTeam);
            }
        }
        //Update Asset on Insert Or Update based on AccountTeams Map
        NSP_AccountTeamTriggerHelper.updateAssetRegion( accIds , accountTeams );
    }

    private static void updateAssetRegion( Set<Id> accIds , Map<Id,NSP_Account_Team__c> accountTeams ) {
        try {
            accIds = ( ( accIds == null ) ? new Set<Id>() : accIds );
            Id woRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'WO' );
            List<Asset> assetToBeUpdated = new List<Asset>();
            //Get All Active asset for the account
            for ( Asset asset : [
                        SELECT Id, RecordTypeId, NSP_Service_Region__c, AccountId
                        FROM Asset
                        WHERE (
                            ( RecordTypeId = :woRecordTypeId )
                            AND ( AccountId = :accIds )
                            AND ( NSP_Account_Status__c = 'Active' )
                        )
                    ]
                )
            {
                NSP_Account_Team__c accountTeam = null;
                if ( ( accountTeams != null )
                    && accountTeams.containsKey( asset.AccountId )
                    )
                {
                    accountTeam = accountTeams.get( asset.AccountId );
                }
                //When new Role is equal to Manager, HR Services
                if ( ( accountTeam != null )
                    && ( accountTeam.NSP_Role__c == 'Manager, HR Services' )
                    )
                {
                    asset.NSP_Service_Region__c = accountTeam.NSP_User__r.NSP_Service_Region__c;
                    assetToBeUpdated.add( asset );
                }
            }
            if ( !assetToBeUpdated.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( assetToBeUpdated , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AccountTeamTriggerHelper.class.getName() ,
                    'updateAssetRegion:update' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountTeamTriggerHelper.class.getName() ,
                'updateAssetRegion' ,
                e
            );
        }
    }

    // used to update per Id on user Update
    public void updatePerIdonUserUpdate( List<NSP_Account_Team__c> newList , Set<String> accountTeamMemberUserIdSet ) {
        Map<Id,User> userMap = new Map<Id,User>([SELECT Id, EmployeeNumber,NSP_sales_Office__c FROM User WHERE Id IN: accountTeamMemberUserIdSet]);
        for(NSP_Account_Team__c accountTeamMemberObj : newList) {
            if(userMap.containsKey(accountTeamMemberObj.NSP_User__c) && accountTeamMemberObj.NSP_User__c != null) {
                accountTeamMemberObj.NSP_PER_ID__c = userMap.get(accountTeamMemberObj.NSP_User__c).EmployeeNumber;
            }
        }
    }

    // describes about the adding validation on deletion of Account Team Members created by Integration users
    public static void validationOnDeletionOfAccountTeam( Map<Id,NSP_Account_Team__c> oldMap ) {
        try {
            List<String> profileFields = new List<String>{'Id','Name'};
            List<String> userProfileNames = new List<String>{NSP_ServiceConstants.SYSTEM_ADMINISTRATOR, NSP_ServiceConstants.INTEGRATION_USER, NSP_ServiceConstants.DATA_MIGRATION};
            List<Profile> integrationUser = new NSP_sObjectSelector('Profile').setSecurityEnforce(false).selectByName(NSP_ServiceConstants.INTEGRATION_USER, null, true);

            String queryProfile = new NSP_QueryBuilder('Profile', profileFields)
                .addFilter('Id', UserInfo.getProfileId()).setSecurityEnforce(false).build();
            List<Profile> loggedInUserProfileName = Database.query(queryProfile);

            Map<Id, Id> accTeamCreatedByIdProfileNameMap = new Map<Id, Id>();
            for(NSP_Account_Team__c acTeam :[SELECT Id, createdbyId, createdby.ProfileId FROM NSP_Account_Team__c WHERE Id IN: oldMap.keySet()]){
                accTeamCreatedByIdProfileNameMap.put(acTeam.createdById, acTeam.createdby.ProfileId);
            }

            for(NSP_Account_Team__c accTeam : oldmap.values()){
                if(accTeamCreatedByIdProfileNameMap.get(accTeam.createdById) == integrationUser[0].Id && !userProfileNames.contains(loggedInUserProfileName[0].Name)){
                    accTeam.addError(System.Label.NSP_Account_Team_Deletion_Validation);
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AccountTeamTriggerHelper.class.getName() ,
                'validationOnDeletionOfAccountTeam' ,
                e
            );
        }
    }

    //
    // @MethodName: updatePayrollDataSheetRecords
    // @Description: This method is used to update Payroll_Specialist__c field on Payroll Data sheet records
    // @param : List<NSP_Account_Team__c> newAccountTeamList, Map<Id,NSP_Account_Team__c> newMap, Map<Id,NSP_Account_Team__c> oldMap
    // @createdDate : 09/05/2024
    // @User story : 304232
    // @return void
    //
    public static void updatePayrollDataSheetRecords( List<NSP_Account_Team__c> newAccountTeamList , Map<Id,NSP_Account_Team__c> oldMap ) {
        Set<Id> accountIds = new Set<Id>();
        List<NSP_Payroll__c> lstOfPayrolls = new List<NSP_Payroll__c>();
        if ( ( newAccountTeamList != null ) && !newAccountTeamList.isEmpty() ) {
            // Loop through each accountteam member in the new list
            for ( NSP_Account_Team__c accountTeam : newAccountTeamList ) {
                if ( accountTeam.NSP_Account__c != null ) {
                    NSP_Account_Team__c oldAccountTeam = null;
                    if ( ( oldMap != null ) && oldMap.containsKey(accountTeam.Id) ) {
                        oldAccountTeam = oldMap.get( accountTeam.Id );
                    }
                    if ( ( accountTeam.NSP_Role__c == NSP_ServiceConstants.PayrollSpecialist )
                        || ( ( oldAccountTeam != null )
                            && ( ( oldAccountTeam.NSP_Role__c != accountTeam.NSP_Role__c )
                                || ( oldAccountTeam.NSP_Account__c != accountTeam.NSP_Account__c )
                                )
                            )
                        )
                    {
                        accountIds.add( accountTeam.NSP_Account__c );
                    }
                }
            }
        }
        if ( accountIds != null && !accountIds.isEmpty() ) {
            // Query the PDS records for the identified account IDs
            for ( NSP_Payroll__c pdsRecord : [
                        SELECT
                            Id , Name , NSP_Sub_Client_Name__c , Account__c , NSP_on_Site_Supervisor__c ,
                            NSP_Primary_Payroll_Contact__c , NSP_HR_Contact__c , NSP_Back_Up_Payroll_Contact__c ,
                            Back_Up_View_Payroll_Paperwork__c , Primary_View_Payroll_Paperwork__c ,
                            View_Payroll_Paperwork__c , On_Site_View_Payroll_Paperwork__c
                        FROM NSP_Payroll__c
                        WHERE ( Account__c IN :accountIds )
                    ]
                )
            {
                if ( pdsRecord.Account__c != null ) {
                    lstOfPayrolls.add( pdsRecord );
                }
            }
            if ( !lstOfPayrolls.isEmpty() ) {
                // Call the helper method to update fields after insert/update
                NSP_PayrollTriggerHelper payrollTriggerHelper = new NSP_PayrollTriggerHelper();
                payrollTriggerHelper.fieldUpdatesAfterInsertUpdate(
                    lstOfPayrolls ,
                    null ,
                    null ,
                    false
                );
            }
        }
    }

}
//