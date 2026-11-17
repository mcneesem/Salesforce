public with sharing class NSP_AccountTeamMemberTriggerHelper {
    // test w/ NSP_AccountTeamMemberTriggerHelperTest (91%)

    //
    // Iterates throught the list of new AccountTeamMember and passes the required attributes to other methods.
    // @param newList List of New AccountTeamMember.
    // @return void
    //
    public void beforeInsertDirector( List<AccountTeamMember> newList ) {
        try{
            boolean integrationUser = false;
            Id profileId = userinfo.getProfileId();
            List<Profile> profileList = [Select Id,Name FROM Profile WHERE Id=:profileId LIMIT 1];

            if(profileList[0].Name == System.Label.NSP_Integration_Profile_Name){
                integrationUser =true;
            }

            Set<Id> accountTeamMemberUserIdSet = new Set<Id>();
            Set<String> accountTeamMemberEmployeePerIdSet = new Set<String>();
            Set<String> accountTeamMemberAIMSClientSet = new Set<String>();

            for(AccountTeamMember accountTeamMemberObj : newList) { // test
                if(integrationUser){
                    if(!String.isBlank(accountTeamMemberObj.NSP_Employee_Per_ID__c)){
                        accountTeamMemberEmployeePerIdSet.add(accountTeamMemberObj.NSP_Employee_Per_ID__c);
                    }
                    if(!String.isBlank(accountTeamMemberObj.NSP_AIMS_Client__c)){
                        accountTeamMemberAIMSClientSet.add(accountTeamMemberObj.NSP_AIMS_Client__c);
                    }
                }
                else{
                    accountTeamMemberUserIdSet.add(accountTeamMemberObj.UserId);
                }
            }

            //get employee per id from user
            if(!integrationUser && accountTeamMemberUserIdSet.size() > 0 ){
                populateEmployeePerIdOnATMBasedOnUserId(newList,accountTeamMemberUserIdSet);
            }

            //get employee per id from user
            if(integrationUser && (accountTeamMemberEmployeePerIdSet.size() > 0 || accountTeamMemberAIMSClientSet.size() > 0) ){
                populateEmployeePerIdOnATMBasedOnEmployeePerId(newList,accountTeamMemberEmployeePerIdSet,accountTeamMemberAIMSClientSet);
            }
        } catch ( Exception e ) {
            NSP_AccountTeamMemberTriggerHelper.handleException( e , 'beforeInsertDirector' );
        }
    }

    //
    // Iterates throught the list of new AccountTeamMember and passes the required attributes to other methods.
    // @param newList List of New AccountTeamMember.
    // @param newMap List of New AccountTeamMember.
    // @return void
    //
    public void afterInsertDirector( List<AccountTeamMember> newList , Map<Id,AccountTeamMember> newMap ) {
        try {
            Set<Id> accountIdSet = new Set<Id>();
            for ( AccountTeamMember accTeamMemberObj : newList ) {
                accountIdSet.add( accTeamMemberObj.AccountId );
            }
            IntegrationSyncController.setReadyForIntegrationSync( accountIdSet );
        } catch ( Exception e ) {
            NSP_AccountTeamMemberTriggerHelper.handleException( e , 'afterInsertDirector' );
        }
    }

    //
    // Iterates throught the list of new AccountTeamMember and passes the required attributes to other methods.
    // @param newMap Map of AccountTeamMember.
    // @param oldMap Map of AccountTeamMember.
    // @return void
    //
    public void beforeUpdateDirector( Map<Id,AccountTeamMember> newMap , Map<Id,AccountTeamMember> oldMap ) {
	}

    //
    // Iterates throught the list of new AccountTeamMember and passes the required attributes to other methods.
    // @param newMap Map of AccountTeamMember.
    // @param oldMap Map of AccountTeamMember.
    // @return void
    //
    public void afterUpdateDirector( Map<Id,AccountTeamMember> newMap , Map<Id,AccountTeamMember> oldMap ) {
        try {
            Set<Id> accountIdSetToUpdateResyncFlag = new Set<Id>();
            NSP_SObjectUpdateTriggerHelper sObjectUpdateObj = new NSP_SObjectUpdateTriggerHelper();
            accountIdSetToUpdateResyncFlag.addAll(
                sObjectUpdateObj.fetchUpdFieldsLst(
                    NSP_IntegrationConstants.SOBJECT_ACCOUNTTEAMMEMBER ,
                    newMap ,
                    oldMap
                )
            );
            IntegrationSyncController.setReadyForIntegrationSync( accountIdSetToUpdateResyncFlag );
        } catch ( Exception e ) {
            NSP_AccountTeamMemberTriggerHelper.handleException( e , 'afterUpdateDirector' );
        }
    }
    /**
     * Iterates throught the AccountTeamMember to populate Employee_Per_Id based on User Id
     * @param newList of New AccountTeamMember.
     * @param accountTeamMemberUserIdSet of AccountTeamMember user id.
     * @return void
     *
     */

    public static void populateEmployeePerIdOnATMBasedOnUserId(List<AccountTeamMember> newList,Set<Id> accountTeamMemberUserIdSet) {
        Map<ID, User> userMap = new Map<ID, User>([SELECT Id, NSP_Employee_Per_ID__c FROM User WHERE Id in: accountTeamMemberUserIdSet]);

        for(AccountTeamMember accountTeamMemberObj : newList) {
            accountTeamMemberObj.NSP_Employee_Per_ID__c = userMap.get(accountTeamMemberObj.UserId).NSP_Employee_Per_ID__c;
        }

    }

    /**
     * Iterates throught the AccountTeamMember to populate Employee_Per_Id based on User Id
     * @param newList of New AccountTeamMember.
     * @param accountTeamMemberUserIdSet of AccountTeamMember user id.
     * @return void
     *
     */

    public static void populateEmployeePerIdOnATMBasedOnEmployeePerId(List<AccountTeamMember> newList,Set<String> accountTeamMemberEmployeePerIdSet,Set<String> atmAIMSClientNumberSet) {
        Map<String, User> userMap = new Map<String, User>();
        Map<String, Account> accountMap = new Map<String, Account>();
        if(accountTeamMemberEmployeePerIdSet.size() > 0){
            List<User> userList = [SELECT Id, NSP_Employee_Per_ID__c FROM User WHERE NSP_Employee_Per_ID__c in: accountTeamMemberEmployeePerIdSet];
                for(User oUser : userList){
                    userMap.put(oUser.NSP_Employee_Per_ID__c,oUser);
                }
        }

        if(atmAIMSClientNumberSet.size() > 0){
            List<Account> accountList = [SELECT Id, NSP_AIMS_Client__c FROM Account WHERE NSP_AIMS_Client__c in: atmAIMSClientNumberSet];
            for(Account oAccount : accountList){
                accountMap.put(oAccount.NSP_AIMS_Client__c,oAccount);
            }
        }

        for(AccountTeamMember accountTeamMemberObj : newList) {
            if(userMap.containsKey(accountTeamMemberObj.NSP_Employee_Per_ID__c)){
            	accountTeamMemberObj.userId = userMap.get(accountTeamMemberObj.NSP_Employee_Per_ID__c).Id;
            }
            if(accountMap.containsKey(accountTeamMemberObj.NSP_AIMS_Client__c)){
                accountTeamMemberObj.accountId = accountMap.get(accountTeamMemberObj.NSP_AIMS_Client__c).Id;
            }
        }

    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_AccountTeamMemberTriggerHelper.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_AccountTeamMemberTriggerHelper.class.getName() ,
            methodName ,
            e
        );
    }

}
//