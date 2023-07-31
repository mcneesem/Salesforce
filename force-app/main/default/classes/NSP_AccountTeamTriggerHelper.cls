/**
* Represents the NSP_Account_Team__c trigger helper which handles the logic with all objects.
* Created by : Hemali
* Date : 24/08/2021
*/
public class NSP_AccountTeamTriggerHelper {
    
    private static final String NSP_ACCOUNT_TEAM_TRIGGER_HELPER = 'NSP_AccountTeamTriggerHelper';
    
    /**
* Iterates throught the list of new NSP_Account_Team__c and passes the required attributes to other methods.
* @param newList List of New NSP_Account_Team__c.
*
* @return void
*                
*/
    
    public void beforeInsertDirector(List<NSP_Account_Team__c> newList) {
        try{
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
            
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
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
            if(userMap.containsKey(accountTeamMemberObj.NSP_User__c) && (accountTeamMemberObj.NSP_PER_ID__c == null && accountTeamMemberObj.NSP_User__c != null)) {
                accountTeamMemberObj.NSP_PER_ID__c = userMap.get(accountTeamMemberObj.NSP_User__c).EmployeeNumber;
            }
            if(employeeIdMap.containsKey(accountTeamMemberObj.NSP_PER_ID__c)){
                accountTeamMemberObj.NSP_sales_Office__c = employeeIdMap.get(accountTeamMemberObj.NSP_PER_ID__c).NSP_sales_Office__c;
            }
        }
    }
    
    
    /**
* Iterates throught the list of new NSP_Account_Team__c and passes the required attributes to other methods.
* @param newList List of New NSP_Account_Team__c.
* @param newMap List of New NSP_Account_Team__c.
* @return void
*                
*/
    
    public void afterInsertDirector(List<NSP_Account_Team__c> newList, Map<Id, NSP_Account_Team__c> newMap) {
        try{
            List<Account> accountList = new List<Account>();
            List<AccountTeamMember> accountTeamMemberList = new List<AccountTeamMember>();
            Map<Id,NSP_Account_Team__c> mapAccountIdtoAccountTeam = new Map<Id,NSP_Account_Team__c>();
            
            for(NSP_Account_Team__c accTeamMemberObj : newList) {
                //insert AccountTeamMeber
                AccountTeamMember accountTeamMemberObj = new AccountTeamMember();
                accountTeamMemberObj.AccountId = accTeamMemberObj.NSP_Account__c;
                accountTeamMemberObj.AccountAccessLevel = NSP_IntegrationConstants.ACCOUNTACCESSLEVELEDIT;
                accountTeamMemberObj.TeamMemberRole = NSP_IntegrationConstants.TEAMMEMBERROLE;
                accountTeamMemberObj.UserId = accTeamMemberObj.NSP_User__c;
                accountTeamMemberList.add(accountTeamMemberObj);
                
                //update Account
                Account accountObj = new Account();
                accountObj.Id = accTeamMemberObj.NSP_Account__c;
                accountObj.NSP_Ready_for_Integration_Sync__c = true;
                accountList.add(accountObj);
                
                /*STY-03187: Checking if NSP_Role__c field in AccountTeam object is WX/WA Benefits Specialist or WA/WX Payroll Specialist or
401k Plan Consultant then mapping AccountId and accountTeamObject */
                if(String.isNotBlank(accTeamMemberObj.NSP_Role__c) && 
                   (accTeamMemberObj.NSP_Role__c == NSP_ServiceConstants.WXWA_BENEFITS || 
                    accTeamMemberObj.NSP_Role__c == NSP_ServiceConstants.WXWA_PAYROLL ||
                    accTeamMemberObj.NSP_Role__c == NSP_ServiceConstants.PLAN_CONSULTANT)){
                        mapAccountIdtoAccountTeam.put(accTeamMemberObj.NSP_Account__c, accTeamMemberObj);
                    }
            }
            
            if(accountTeamMemberList.size() > 0){
                insert accountTeamMemberList;
            }
            
            if(accountList.size() > 0){
                update accountList;                    
            }
            
            //Checking if map of accountId and Account Team is greater than zero or not
            if(mapAccountIdtoAccountTeam.size()>0 && !mapAccountIdtoAccountTeam.isEmpty()){
                updateAccountTeamNameToAssetName(mapAccountIdtoAccountTeam);
            }
            
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException(NSP_ACCOUNT_TEAM_TRIGGER_HELPER,'afterInsertDirector',ex.getMessage());
        }
    }
    
    /*STY-03187: 
* Description: update the account team userId to asset to respective NSP_WX_WA_Benefits_Specialist__c
NSP_WX_WA_Benefits_Specialist__c, and NSP_Retirement_Service_Plan_Name__c field based on AccountTeam record role
* When: 13/10/2022
* @param: mapAccountTeamId map of AccountId and AccountTeamObject
* @return void
*/
    
    public void updateAccountTeamNameToAssetName(Map < Id, NSP_Account_Team__c > mapAccountIdtoAccountTeam) {
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
                                    } else if (accountTeamObject.NSP_Role__c == NSP_ServiceConstants.PLAN_CONSULTANT && String.isNotBlank(accountTeamObject.NSP_User__c)) {
                                        assetObject.NSP_Retirement_Service_Plan_Name__c = accountTeamObject.NSP_User__c;
                                    }
                                    listAssetObject.add(assetObject);
                                }
        
        //updating Asset object field 
        try {
            if (listAssetObject.size() > 0) {
                Database.update(listAssetObject);
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_ACCOUNT_TEAM_TRIGGER_HELPER, 'updateAccountTeamNameToAssetName', ex.getMessage());
        }
    }
    
    /**
* Iterates throught the list of new NSP_Account_Team__c and passes the required attributes to other methods.
* @param newMap Map of NSP_Account_Team__c.
* @param oldMap Map of NSP_Account_Team__c.
* @return void
*                
*/
    
    public void beforeUpdateDirector(Map<Id, NSP_Account_Team__c> newMap,Map<Id, NSP_Account_Team__c> oldMap) {
        try{
            //Added as part of STY-03667
            Set<Id> accountIdSet = new Set<Id>();
            List<NSP_Account_Team__c> newAcctTeamList=new  List<NSP_Account_Team__c>();
            //Added as part of DF-02431
            Id profileId = userinfo.getProfileId();
            String profileName = [SELECT Id, Name from Profile WHERE Id =: profileId].Name;
            Set<String> accountTeamMemberUserIdSet = new Set<String>();
            List<NSP_Account_Team__c> newAccountTeamList=new  List<NSP_Account_Team__c>();

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
               
           }
           
           //update per id if User on account team changes
            if(accountTeamMemberUserIdSet.size() > 0){
                updatePerIdonUserUpdate(newAccountTeamList, accountTeamMemberUserIdSet);
            } 
            
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException(NSP_ACCOUNT_TEAM_TRIGGER_HELPER,'beforeUpdateDirector',ex.getMessage());
        }
        
    }
    
    /**
* Iterates throught the list of new NSP_Account_Team__c and passes the required attributes to other methods.
* @param newMap Map of NSP_Account_Team__c.
* @param oldMap Map of NSP_Account_Team__c.
* @return void
*                
*/
    
    public void afterUpdateDirector(Map<Id, NSP_Account_Team__c> newMap,Map<Id, NSP_Account_Team__c> oldMap) {
        try{
            Set<Id> accountIdSetToUpdateResyncFLag = new Set<Id>();
            NSP_SObjectUpdateTriggerHelper sObjectUpdateObj = new NSP_SObjectUpdateTriggerHelper();
            accountIdSetToUpdateResyncFLag.addAll(sObjectUpdateObj.fetchUpdFieldsLst(NSP_IntegrationConstants.SOBJECT_ACCOUNTTEAM, newMap, oldMap));
            Map<Id,NSP_Account_Team__c> mapAccountIdtoAccountTeam = new Map<Id,NSP_Account_Team__c>();
            
            /*STY-03187 : Checking if NSP_Role__c field in AccountTeam object is WX/WA Benefits Specialist or WA/WX Payroll Specialist or
401k Plan Consultant then mapping AccountId and accountTeamObject */
            for(NSP_Account_Team__c accTeamMemberObj : newMap.values()) {
                
                if(String.isNotBlank(accTeamMemberObj.NSP_Role__c) && 
                   (accTeamMemberObj.NSP_Role__c != oldMap.get(accTeamMemberObj.Id).NSP_Role__c || 
                    accTeamMemberObj.NSP_User__c != oldMap.get(accTeamMemberObj.Id).NSP_User__c) &&
                   (accTeamMemberObj.NSP_Role__c == NSP_ServiceConstants.WXWA_BENEFITS ||
                    accTeamMemberObj.NSP_Role__c == NSP_ServiceConstants.WXWA_PAYROLL ||
                    accTeamMemberObj.NSP_Role__c == NSP_ServiceConstants.PLAN_CONSULTANT)){
                        mapAccountIdtoAccountTeam.put(accTeamMemberObj.NSP_Account__c, accTeamMemberObj);
                    }
            }
            
            if(accountIdSetToUpdateResyncFLag.size() > 0){
                List<Account> updateAccountList = new List<Account>();
                for(Id accountId : accountIdSetToUpdateResyncFLag){
                    Account accountObj = new Account(); 
                    accountObj.NSP_Ready_for_Integration_Sync__c = true;
                    accountObj.Id = accountId; 
                    updateAccountList.add(accountObj);
                }
                if(updateAccountList.size() > 0){
                    update updateAccountList;                    
                }
            }
            //Checking if map of accountId and Account Team is greater than zero or not
            if(mapAccountIdtoAccountTeam.size()>0 && !mapAccountIdtoAccountTeam.isEmpty()){
                updateAccountTeamNameToAssetName(mapAccountIdtoAccountTeam);
            }
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }
    
    /***********************************************************************************************
    * MethodName  : updateProjectTaskEmailFields 
    * Description : Method to update Project Task Email field
    * Params	  : List<NSP_Account_Team__c> newList, Map<Id, NSP_Account_Team__c> oldMap
    * 
    * ********************************************************************************************/
    public static void updateProjectTaskEmailFields(List<NSP_Account_Team__c> newList, Map<Id, NSP_Account_Team__c> oldMap){
        set<Id> setAccountIds = new set<Id>();   
        Map<String,set<String>> mapAccTeamEmails = new Map<String,set<String>>();
        Map<String,NSP_Account_Team__c> mapAccTeamCLHR = new Map<String,NSP_Account_Team__c>();
        List<pse__Project_Task__c> lstProjectTask = new List<pse__Project_Task__c>();
        
        List<NSP_Account_Team__c> lstAccTeams = new List<NSP_Account_Team__c>();
        for(NSP_Account_Team__c accTeam: newList){
            if((oldMap == null && accTeam.NSP_Account__c!=null) || (oldMap!=null && accTeam.NSP_Account__c!=null && (oldMap.get(accTeam.Id).NSP_Account__c != accTeam.NSP_Account__c || accTeam.NSP_Role__c!=oldMap.get(accTeam.Id).NSP_Role__c))){
                setAccountIds.add(accTeam.NSP_Account__c);
            }
        }
        
        if(!setAccountIds.isEmpty()){
            lstAccTeams =  getAccountTeamRecords(setAccountIds);
            mapAccTeamEmails = getCCAccountTeams(lstAccTeams);
            mapAccTeamCLHR = getAccountTeams(lstAccTeams);
        }
        
        if(!mapAccTeamCLHR.isempty()){
            for(pse__Project_Task__c proj : [SELECT Id,NSP_CC_Emails__c,NSP_Client_Liaison_Name__c,NSP_HR_Specialist_Email__c,NSP_AccountId__c,
                                             NSP_HR_Specialist_Name__c,NSP_Client_Liaison_Email__c FROM pse__Project_Task__c WHERE NSP_AccountId__c IN:setAccountIds]){
                if(mapAccTeamEmails.containsKey(proj.NSP_AccountId__c) && mapAccTeamEmails.get(proj.NSP_AccountId__c)!=null){
                    List<String> ccEmails = new List<String>();
                    ccEmails.addAll(mapAccTeamEmails.get(proj.NSP_AccountId__c));
                    proj.NSP_CC_Emails__c = String.join(ccEmails, ',');
                }
                if(mapAccTeamCLHR.containsKey(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)){
                    proj.NSP_Client_Liaison_Name__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_First_Name__c +' '+mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_Last_Name__c;
                    proj.NSP_Client_Liaison_Email__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_Email__c;
                    proj.NSP_HR_Specialist_Name__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_First_Name__c +' '+mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_Last_Name__c;
                    proj.NSP_HR_Specialist_Email__c =  mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_Email__c;
                }else if(mapAccTeamCLHR.containsKey(NSP_ServiceConstants.CLIENT_LIAISION)){
                    proj.NSP_Client_Liaison_Name__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.CLIENT_LIAISION)?.NSP_First_Name__c +' '+mapAccTeamCLHR?.get(NSP_ServiceConstants.CLIENT_LIAISION)?.NSP_Last_Name__c;
                    proj.NSP_Client_Liaison_Email__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.CLIENT_LIAISION)?.NSP_Email__c;
                    proj.NSP_HR_Specialist_Name__c = '';proj.NSP_HR_Specialist_Email__c ='';
                }else if(mapAccTeamCLHR.containsKey(NSP_ServiceConstants.HRSpecialist)){
                    proj.NSP_HR_Specialist_Name__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.HRSpecialist)?.NSP_First_Name__c +' '+mapAccTeamCLHR?.get(NSP_ServiceConstants.HRSpecialist)?.NSP_Last_Name__c;
                    proj.NSP_HR_Specialist_Email__c =  mapAccTeamCLHR?.get(NSP_ServiceConstants.HRSpecialist)?.NSP_Email__c;
                    proj.NSP_Client_Liaison_Name__c = '';proj.NSP_Client_Liaison_Email__c = '';
                }
                lstProjectTask.add(proj);
            }
        }
        
        if(!lstProjectTask.isEmpty()){
            update lstProjectTask;
        }
    }
    
    /***********************************************************************************************
    * MethodName  : getCCAccountTeams 
    * Description : Method to get CC account team
    * Params	  : List<NSP_Account_Team__c> accTeamRecords
    * 
    * ********************************************************************************************/
    private static Map<String,set<String>> getCCAccountTeams(List<NSP_Account_Team__c> accTeamRecords){
        Map<String,set<String>> mapAccTeamEmails = new Map<String,set<String>>();
        for(NSP_Account_Team__c accTeam: accTeamRecords){
            if(mapAccTeamEmails.containsKey(accTeam.NSP_Account__c)){
                mapAccTeamEmails.get(accTeam.NSP_Account__c).add(accTeam.NSP_Email__c);
            }else{
                mapAccTeamEmails.put(accTeam.NSP_Account__c,new set<String>{accTeam.NSP_Email__c});
            }
        }
        return mapAccTeamEmails;
    }
    
    /***********************************************************************************************
    * MethodName  : getAccountTeamRecords 
    * Description : Method to get account team records
    * Params	  : Set<Id> setAccountIds
    * 
    * ********************************************************************************************/
    private static List<NSP_Account_Team__c> getAccountTeamRecords(Set<Id> setAccountIds){
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
    
    /***********************************************************************************************
* MethodName: showErrorOnPrimaryCheckRole 
* Description : Method for showing error on Account Team when primary checkbox is checked for same role
* Params:       List<NSP_Account_Team__c> newList, Map<Id, NSP_Account_Team__c> oldMap
* 
* ********************************************************************************************/
    public void showErrorOnPrimaryCheckRole(Set<Id> accountIdSet, List<NSP_Account_Team__c> newList) {
        
        
        
        try{
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
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_ACCOUNT_TEAM_TRIGGER_HELPER, 'showErrorOnPrimaryCheckRole', ex.getMessage());
        }
    }

    
    /** 
    * @MethodName: updateAssetServiceRegion
    * @Description: This method is used to update Asset Fields on after Insert
    * @param : List<NSP_Account_Team__c> newAccTeam, Map<Id, NSP_Account_Team__c> oldMap
    * @createdDate : 11/30/2022
    * @Defect : STY-02108
    * @return void                          
    */
    
    public static void updateAssetServiceRegion(List<NSP_Account_Team__c> newAccTeam, Map<Id, NSP_Account_Team__c> oldMap ){
        //Get Record Type Id
        Id woRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE );
        Set<Id> accIds = new Set<Id>();
        Map<Id, NSP_Account_Team__c> accountTeams = new  Map<Id, NSP_Account_Team__c>();
        //Filter record based on Insert or Update
        for(NSP_Account_Team__c accTeam : newAccTeam) {
            if(oldMap == null && accTeam.NSP_Account__c != null || oldMap != null && accTeam.NSP_Role__c != oldMap.get(accTeam.Id).NSP_Role__c) {                    
                 accIds.add(accTeam.NSP_Account__c);
             }            
        }
        //Get Account Team's User Serice Region field for Insert case
        if(!accIds.isEmpty()) {            
            for(NSP_Account_Team__c accountTeam : [SELECT Id, NSP_User__r.NSP_Service_Region__c, NSP_Role__c , NSP_Account__c FROM NSP_Account_Team__c 
                                                   WHERE Id =: newAccTeam AND NSP_User__c != null AND NSP_Role__c != null AND NSP_Role__c = 'Manager, HR Services']) {
                accountTeams.put(accountTeam.NSP_Account__c, accountTeam);
            }
        }
        
        //Update Asset on Insert Or Update based on AccountTeams Map
        updateAssetRegion(accIds, woRecordTypeId, accountTeams);
        
    }
    
    /** 
    * @MethodName: updateAssetRegion
    * @Description: This method is used to update Asset Fields on after Insert
    * @param : Set<Id> accIds, Id woRecordTypeId,  Map<Id, NSP_Account_Team__c> accountTeams
    * @createdDate : 11/30/2022
    * @Defect : STY-02108
    * @return void                          
    */
    private static void updateAssetRegion(Set<Id> accIds, Id woRecordTypeId,  Map<Id, NSP_Account_Team__c> accountTeams) {
        List<Asset> assetToBeUpdated = new List<Asset>();
        //Get All Active asset for the account
        for(Asset asset : [SELECT Id, RecordTypeId, NSP_Service_Region__c, AccountId From Asset WHERE RecordTypeId =:woRecordTypeId AND AccountId =:accIds AND NSP_Account_Status__c = 'Active']){
            //When new Role is equal to Manager, HR Services
            if(accountTeams.containsKey(asset.AccountId) && accountTeams.get(asset.AccountId).NSP_Role__c == 'Manager, HR Services') {
                asset.NSP_Service_Region__c = accountTeams.get(asset.AccountId).NSP_User__r.NSP_Service_Region__c;
                assetToBeUpdated.add(asset);
            }else {
                //When new Role is not equal to Manager, HR Services
                asset.NSP_Service_Region__c = null;
                assetToBeUpdated.add(asset);
            }
        }       
        
        if(!assetToBeUpdated.isEmpty()) {
            update assetToBeUpdated;
        }
    }

    /** 
    * @MethodName: updatePerIdonUserUpdate
    * @Description: This method is used to update per Id on user Update
    * @param : List<NSP_Account_Team__c> newList, Set<String> accountTeamMemberUserIdSet
    * @createdDate : 04/27/2023
    * @Defect : DF-03716
    * @return void                          
    */
    public void updatePerIdonUserUpdate(List<NSP_Account_Team__c> newList, Set<String> accountTeamMemberUserIdSet){
        
        Map<ID, User> userMap = new Map<ID, User>([SELECT Id, EmployeeNumber,NSP_sales_Office__c FROM User WHERE Id IN: accountTeamMemberUserIdSet]);
        for(NSP_Account_Team__c accountTeamMemberObj : newList) {
            if(userMap.containsKey(accountTeamMemberObj.NSP_User__c) && accountTeamMemberObj.NSP_User__c != null) {
                accountTeamMemberObj.NSP_PER_ID__c = userMap.get(accountTeamMemberObj.NSP_User__c).EmployeeNumber;
            }
        }
    }

        /***********************************************************************************************
    * MethodName  : validationOnDeletionOfAccountTeam
    * Description : This Method describes about the adding validation on deletion of Account Team Members created by Integration users
    * Params      : List<NSP_Account_Team__c> accTeamOldList
    * Story       : DF-03948
    * createdDate : 5/6/2023
    * ********************************************************************************************/
    public static void validationOnDeletionOfAccountTeam(Map<Id, NSP_Account_Team__c> oldMap){
        try{ 
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
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException(NSP_ACCOUNT_TEAM_TRIGGER_HELPER, 'validationOnDeletionOfAccountTeam', ex.getMessage());
        }
    }
}