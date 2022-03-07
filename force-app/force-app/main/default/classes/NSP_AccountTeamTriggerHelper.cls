/**
 * Represents the NSP_Account_Team__c trigger helper which handles the logic with all objects.
 * Created by : Hemali
 * Date : 24/08/2021
 */
public class NSP_AccountTeamTriggerHelper {
    
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
            
            for(NSP_Account_Team__c accountTeamMemberObj : newList) {
                 if(!String.isBlank(accountTeamMemberObj.NSP_PER_ID__c)){
                        accountTeamMemberEmployeePerIdSet.add(accountTeamMemberObj.NSP_PER_ID__c);  
                        newAccountTeamList.add(accountTeamMemberObj);
                    }
            }
            
            //get employee per id from user
            if(accountTeamMemberEmployeePerIdSet.size() > 0){
            	populateEmployeePerIdOnATMBasedOnUserId(newAccountTeamList,accountTeamMemberEmployeePerIdSet);
            }
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }
    
    //populate employee id based on user id on Account Team
    public void populateEmployeePerIdOnATMBasedOnUserId(List<NSP_Account_Team__c> newList,Set<String> accountTeamIdSet){
        Map<String,User> employeeIdMap = new Map<String,User>(); 
        Map<ID, User> userMap = new Map<ID, User>([SELECT Id, NSP_Employee_Per_ID__c,NSP_sales_Office__c FROM User WHERE NSP_Employee_Per_ID__c IN: accountTeamIdSet]);
        
        for(User oUser : userMap.values()){
            employeeIdMap.put(oUser.NSP_Employee_Per_ID__c,oUser);
        }
        
        for(NSP_Account_Team__c accountTeamMemberObj : newList) {
            accountTeamMemberObj.NSP_User__c = employeeIdMap.get(accountTeamMemberObj.NSP_PER_ID__c).Id;
            accountTeamMemberObj.NSP_sales_Office__c = employeeIdMap.get(accountTeamMemberObj.NSP_PER_ID__c).NSP_sales_Office__c;
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
            
            for(NSP_Account_Team__c accTeamMemberObj : newList) {
                //insert AccountTeamMeber
                AccountTeamMember accountTeamMemberObj = new AccountTeamMember();
                accountTeamMemberObj.AccountId = accTeamMemberObj.NSP_Account__c;
                accountTeamMemberObj.AccountAccessLevel = NSP_IntegrationConstants.ACCOUNTACCESSLEVEL;
                accountTeamMemberObj.TeamMemberRole = NSP_IntegrationConstants.TEAMMEMBERROLE;
                accountTeamMemberObj.UserId = accTeamMemberObj.NSP_User__c;
                accountTeamMemberList.add(accountTeamMemberObj);
                
                //update Account
                Account accountObj = new Account();
                accountObj.Id = accTeamMemberObj.NSP_Account__c;
                accountObj.NSP_Ready_for_Integration_Sync__c = true;
                accountList.add(accountObj);
            }
            
            
            
            if(accountTeamMemberList.size() > 0){
                insert accountTeamMemberList;
            }
            
            if(accountList.size() > 0){
                update accountList;                    
            }
            
            
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_AccountTeamTriggerHelper','afterInsertDirector',ex.getMessage());
        }
    }
    
    /**
     * Iterates throught the list of new AccountTeam and passes the required attributes to other methods.
     * @param newMap Map of AccountTeam.
     * @param oldMap Map of AccountTeam.
     * @return void
     *                
     */

    public void beforeUpdateDirector(Map<Id, NSP_Account_Team__c> newMap,Map<Id, NSP_Account_Team__c> oldMap) {
        List<NSP_Account_Team__c> newAccountTeamList = new List<NSP_Account_Team__c>(); 
        Set<String> accountTeamMemberEmployeePerIdSet = new Set<String>(); 
        try{
        for(Id accountTeamId : newMap.keySet()){
            NSP_Account_Team__c newAccountTeam =  newMap.get(accountTeamId);
            NSP_Account_Team__c oldAccountTeam =  oldMap.get(accountTeamId);
            if(!String.isBlank(newAccountTeam.NSP_PER_ID__c) && newAccountTeam.NSP_PER_ID__c != oldAccountTeam.NSP_PER_ID__c){
                accountTeamMemberEmployeePerIdSet.add(newAccountTeam.NSP_PER_ID__c);  
                newAccountTeamList.add(newAccountTeam);
            }
            
        }
        if(accountTeamMemberEmployeePerIdSet.size() > 0){
            populateEmployeePerIdOnATMBasedOnUserId(newAccountTeamList,accountTeamMemberEmployeePerIdSet);
        }
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
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
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }
    
}