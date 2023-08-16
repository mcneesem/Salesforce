/**
* Represents the Account Group Member trigger helper which handles all the logic.
*/

public without sharing class NSP_AccountGroupMemberTriggerHelper {

    /**
    * @Description  : Iterates throught the list of new Account GroupMembers
    * @param        : List<NSP_Account_Group_Member__c> newList, Map<Id, NSP_Account_Group_Member__c> newMap 
    * @return       : void      
    *                
    */
    public static void afterInsertDirector(List<NSP_Account_Group_Member__c> newList, Map<Id, NSP_Account_Group_Member__c> newMap){
        try{
            defaultPrimaryFirstAccountGroupMember(newList);
        } catch(Exception exc){
            NSP_ErrorLogHandler.logSaveException('NSP_AccountGroupMemberTriggerHelper','afterInsertDirector', exc.getMessage());
        }
    }
    
    /**
    * @Description  : Iterates throught the list and map of old Account GroupMembers
    * @param        : List<sObject> oldList , Map<Id, sObject> oldMap
    * @return       : void      
    *                
    */
    public static void afterDeleteDirector(List<NSP_Account_Group_Member__c> oldList , Map<Id, NSP_Account_Group_Member__c> oldMap){
        try{
            updatePrimaryForLastGroupMember(oldList, oldMap);
        } catch(Exception exc){
            NSP_ErrorLogHandler.logSaveException('NSP_AccountGroupMemberTriggerHelper','afterDeleteDirector', exc.getMessage());
        }
    }
    
    /**
    * Iterates throught the list of new Account GroupMembers and old Account GroupMembers
    * @param newList List of New Account Group Members.  
    * @return void      
    *                
    */
    public void afterInsertIsPrimary(List<NSP_Account_Group_Member__c> newList, Map<Id, NSP_Account_Group_Member__c> oldMap) {
        Map<String,String> mapAccIdGrp = new Map<String,String>();
        
        try{ 
            //check if primary is changed will update the new Primary Account group Member
            for(NSP_Account_Group_Member__c accGrpM: newList){
                if((oldMap == null && accGrpM.NSP_Primary__c) || (oldMap!=null && accGrpM.NSP_Primary__c && accGrpM.NSP_Primary__c!=oldMap.get(accGrpM.Id).NSP_Primary__c)){
                    mapAccIdGrp.put(accGrpM.NSP_Group__c,accGrpM.NSP_Member_Account__c);
                }
            }
            //update the Account Group with the Primary Account
            if(!mapAccIdGrp.isEmpty()){
                updatePrimaryAccounts(mapAccIdGrp);
            }
            
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_AccountGroupMemberTriggerHelper','afterInsertIsPrimary',ex.getMessage());
        }
    }
    
    /**
    * Find all the group Name will be update with account if primary is checked
    * @param mapAccIdGrp of groupId and Account.  
    * @return void 
    */
    private void updatePrimaryAccounts(Map<String,String> mapAccIdGrp){
        List<NSP_Account_Group__c> lstOfAccGrps = new List<NSP_Account_Group__c>();
        List<NSP_Account_Group_Member__c> lstOfAccGrpsMembrs = new List<NSP_Account_Group_Member__c>();
        Map<Id,Account> mapAccounts = new Map<Id,Account>([SELECT Id,Name from Account WHERE Id IN: mapAccIdGrp.values()]);
        for(NSP_Account_Group__c accGrp: [Select Id, NSP_Account__c from NSP_Account_Group__c WHERE Id IN: mapAccIdGrp.keyset() AND NSP_Type__c !=: NSP_ServiceConstants.TYPECONTROLLEDGROUP]){
            if(mapAccIdGrp.containskey(accGrp.Id)){
                accGrp.NSP_Account__c = mapAccounts?.get(mapAccIdGrp?.get(accGrp.Id))?.Name;
                lstOfAccGrps.add(accGrp);
            }
        }
        //Update the oldRecords to unprimary which is associated to that group
        for(NSP_Account_Group_Member__c accGrpMem: [SELECT Id, NSP_Primary__c, NSP_Group__r.NSP_Type__c 
                                                    FROM NSP_Account_Group_Member__c 
                                                    WHERE NSP_Group__c IN: mapAccIdGrp.keyset() 
                                                    AND NSP_Member_Account__c 
                                                    NOT IN: mapAccIdGrp.values() 
                                                    AND NSP_Primary__c = true 
                                                    AND NSP_Group__r.NSP_Type__c !=: NSP_ServiceConstants.TYPECONTROLLEDGROUP]){
            accGrpMem.NSP_Primary__c = false;
            lstOfAccGrpsMembrs.add(accGrpMem);
        }
        
        if(!lstOfAccGrps.isEmpty()){
            Database.Update(lstOfAccGrps,false);
        }
        
        if(!lstOfAccGrpsMembrs.isEmpty()){
            Database.Update(lstOfAccGrpsMembrs,false);
        }
    }
    
    /**
    * List of AccountGroupMember -> Account and Group Relation Duplicate validations 
    * @param mapAccIdGrp of groupId and Account.  
    * @return void 
    */
    public void validateDuplicapteGroupMembers(List<NSP_Account_Group_Member__c> lstAccGrpMembers){
        try{ 
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
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_AccountGroupMemberTriggerHelper','validateDuplicapteGroupMembers',ex.getMessage());
        }
    }
    
    /**
    * AccountGroupMember -> validation for WXAccountGroup Members on delete
    * @param  List<NSP_Account_Group_Member__c> lstAccGrpMembers
    * @return void 
    */
    public void preventDeleteForWXAccountGroupMembers(List<NSP_Account_Group_Member__c> lstAccGrpMembers){
        User getUser  = [SELECT Id, Profile.Name From User WHERE Id =:userinfo.getUserId()];

        for (NSP_Account_Group_Member__c accGrpMember : lstAccGrpMembers) {
            if(isWxAccountGroupMember(accGrpMember) && getUser.Profile.Name != 'Integeration User'){
                accGrpMember.addError(label.NSP_AccountGroupErrorMessage);
            }
        }
    }
    
    /**
    * AccountGroupMember -> check is it valid AccountGroup Member to Delete 
    * @param  NSP_Account_Group_Member__c accGrpMember
    * @return Boolean 
    */
    private boolean isWxAccountGroupMember(NSP_Account_Group_Member__c accGrpMember){
        String profileName = [Select Id,Name from Profile WHERE Id=:userinfo.getProfileId()]?.Name;
        return accGrpMember.NSP_Type__c == NSP_ServiceConstants.ISOLVED && (profileName == NSP_ServiceConstants.PEOSERVICE 
                                                                            || profileName == NSP_ServiceConstants.CONTACTCENTER
                                                                            || profileName == NSP_ServiceConstants.BPSSERVICE
                                                                            || profileName == NSP_ServiceConstants.RT
                                                                            || profileName == NSP_ServiceConstants.PEO
                                                                            || profileName == NSP_ServiceConstants.BPS);
    }

    /* Description: This method is used to update Payroll Employee Of Account Group Member from Payroll Employee Of Account 
     * 
     * @param: Map <Id, Account> newMap, Map <Id, Account> oldMap
     * @return: void
     * Modification History:
     * -------------------------------------------------------------------------------------
     *  Date              | Description
     * -------------------------------------------------------------------------------------
     *  03/11/2022          created this new method added for STY-02846
     */

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
    
    /***********************************************************************
    * @MethodName : updatePrimaryForLastGroupMember
    * @Description: This method will update the last member 
    * 				of Account Group as Primary
    * @param      : List<NSP_Account_Group_Member__c> oldList, 
    * 				Map<Id, NSP_Account_Group_Member__c> oldMap
    * @Story      : STY-03316
    * @return     : void                          
    **************************************************************************/
    public static void updatePrimaryForLastGroupMember(List<NSP_Account_Group_Member__c> oldList, Map<Id, NSP_Account_Group_Member__c> oldMap){
        
        try{
            Map<String,String> mapAccIdGrp = new Map<String,String>();
            List<NSP_Account_Group__c> lstOfAccGrps = new List<NSP_Account_Group__c>();
            List<NSP_Account_Group__c> lstOfAccGrpsToUpdate = new List<NSP_Account_Group__c>();
            List<NSP_Account_Group_Member__c> lstOfAccGrpsMembrs = new List<NSP_Account_Group_Member__c>();
            List<NSP_Account_Group_Member__c> lstOfNonPrimaryAccGrpMembrs = new List<NSP_Account_Group_Member__c>();
            
            for(NSP_Account_Group_Member__c accGrpM: oldList){
                if(oldMap!=null && accGrpM.NSP_Primary__c == true){ 
                    mapAccIdGrp.put(accGrpM.NSP_Group__c, accGrpM.NSP_Member_Account__c);
                }
            }
            
            //Setting Account Group Name to update with Primary Account Group Member Name
            lstOfAccGrps = setAccountGroupName(mapAccIdGrp);

            //Update the Account Group Member record to primary which is associated to that group
            for(NSP_Account_Group_Member__c accGrpMem: [SELECT Id, NSP_Primary__c, NSP_Group__r.NSP_Account__c 
                                                        FROM NSP_Account_Group_Member__c 
                                                        WHERE NSP_Group__c IN: mapAccIdGrp.keyset() 
                                                        AND NSP_Primary__c = false 
                                                        AND NSP_Group__r.NSP_Type__c !=: NSP_ServiceConstants.TYPECONTROLLEDGROUP]){
                lstOfNonPrimaryAccGrpMembrs.add(accGrpMem);
                accGrpMem.NSP_Primary__c = true;
                lstOfAccGrpsMembrs.add(accGrpMem);
            }
            
            //Remove Account Name from Account Group Name if there is no Primary Group Member in Account Group
            if(!lstOfNonPrimaryAccGrpMembrs.isEmpty() || lstOfNonPrimaryAccGrpMembrs.isEmpty()){ 
                lstOfAccGrpsToUpdate = removeAccountNameFromGroupName(mapAccIdGrp.keyset());
            }
            
            //Update Account Group Name if there is not Primary Group Member in Account Group
            if(!lstOfAccGrpsToUpdate.isEmpty()){
                Database.SaveResult[] accGrpUpdateList = Database.update(lstOfAccGrpsToUpdate,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_AccountGroupMemberTriggerHelper', 'defaultPrimaryFirstAccountGroupMember:AccountGroupUpdate', accGrpUpdateList);
            }
            
            //Update Account Group Name with Primary Group Member Name in it if there is any Primary Group Member in Account Group
            if(!lstOfAccGrps.isEmpty()){
                Database.SaveResult[] accGrpUpdateList = Database.update(lstOfAccGrps,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_AccountGroupMemberTriggerHelper', 'defaultPrimaryFirstAccountGroupMember:AccountGroupUpdate', accGrpUpdateList);
            }
            //Update last Account Group Member to a Primary Group Member in the Account Group
            if(!lstOfAccGrpsMembrs.isEmpty() && lstOfAccGrpsMembrs.size() == 1){
                Database.SaveResult[] accGrpMemberUpdateList = Database.update(lstOfAccGrpsMembrs,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_AccountGroupMemberTriggerHelper', 'defaultPrimaryFirstAccountGroupMember:AccountGroupMemberUpdate', accGrpMemberUpdateList);
            }
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_AccountGroupMemberTriggerHelper', 'updatePrimaryForLastGroupMember', ex.getMessage());
        }
    }

    /***********************************************************************
    * @MethodName : removeAccountNameFromGroupName
    * @Description: This method will remove Account Name from Group Name 
    * @param      : Map<String,String> mapAccIdGrp
    * @Story      : STY-03316
    * @return     : void                          
    **************************************************************************/
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

    /***********************************************************************
    * @MethodName : setAccountGroupName
    * @Description: This method will set Account Group Name 
    * @param      : Map<String,String> mapAccIdGrp
    * @Story      : STY-03316
    * @return     : void                          
    **************************************************************************/
    public static List<NSP_Account_Group__c> setAccountGroupName(Map<String,String> mapAccIdGrp){
        List<NSP_Account_Group__c> lstOfAccGrps = new List<NSP_Account_Group__c>();

        List<String> accountFields = new List<String>{'Id','Name'};
        String query = new NSP_QueryBuilder('Account', accountFields)
                            .addFilter('Id', mapAccIdGrp.values(), NSP_QueryBuilder.Operator.INCLUDES).build();
        List<Account> accountList = (List<Account>)Database.query(query);
        Map<Id, Account> mapAccounts = new Map<Id, Account>(accountList);
        
        for(NSP_Account_Group__c accGrp: [Select Id, NSP_Account__c FROM NSP_Account_Group__c WHERE Id IN: mapAccIdGrp.keyset() AND NSP_Type__c !=: NSP_ServiceConstants.TYPECONTROLLEDGROUP]){
            if(mapAccIdGrp.containskey(accGrp.Id)){
                accGrp.NSP_Account__c = mapAccounts?.get(mapAccIdGrp?.get(accGrp.Id))?.Name;
                lstOfAccGrps.add(accGrp);
            }
        }
        return lstOfAccGrps;
    }

    /***********************************************************************
    * @MethodName : defaultPrimaryFirstAccountGroupMember
    * @Description: This method will update First Account Group Member as primary
    * @param      : List<NSP_Account_Group_Member__c> accGrpMemList
    * @Story      : STY-03316
    * @return     : void                          
    **************************************************************************/
    public static void defaultPrimaryFirstAccountGroupMember(List<NSP_Account_Group_Member__c> accGrpMemList){

        try{
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
            if(!lstOfAccGrps.isEmpty() && accGrpMemberListToUpdate.size() == 1){
                Database.SaveResult[] accGrpUpdateList = Database.update(lstOfAccGrps,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_AccountGroupMemberTriggerHelper', 'defaultPrimaryFirstAccountGroupMember:AccountGroupUpdate', accGrpUpdateList);
            }
            
             //Update first Account Group Member to a Primary Group Member in the Account Group
            if(!accGrpMemberListToUpdate.isEmpty() && accGrpMemberListToUpdate.size() == 1){
                Database.SaveResult[] accGrpMemberUpdateList = Database.update(accGrpMemberListToUpdate,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_AccountGroupMemberTriggerHelper', 'defaultPrimaryFirstAccountGroupMember:AccountGroupMemberUpdate', accGrpMemberUpdateList);
            }
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_AccountGroupMemberTriggerHelper', 'defaultPrimaryFirstAccountGroupMember', ex.getMessage());
        }
    }

    /***********************************************************************
    * @MethodName : preventAccountGroupsDeleting
    * @Description: This method will restrict account Groups that has only one group
    * @param      : List<NSP_Account_Group_Member__c> accGrpMemList
    * @Story      : STY-04122
    * @return     : void                          
    **************************************************************************/
    public static void preventAccountGroupsDeleting(List<NSP_Account_Group_Member__c> lstAccGrpMembers){
        List<String> lstGrpTypes = new List<String>{ NSP_ServiceConstants.ACCOUNT_HEALTH, NSP_ServiceConstants.RENEWAL_PROBABILITY, NSP_ServiceConstants.GROWTH_FORECAST };
        String userQuery = new NSP_QueryBuilder('User', new List<String>{'Id', 'NSP_Profile_Name__c'})
                                .addFilter('Id', userinfo.getUserId()).build();
        User usr  =  (User)Database.query(userQuery);

        for(NSP_Account_Group_Member__c accGroupMembr : lstAccGrpMembers){
            if(lstGrpTypes.contains(accGroupMembr.NSP_Type__c) && usr.NSP_Profile_Name__c != NSP_ServiceConstants.SYSTEM_ADMINISTRATOR && !accGroupMembr.NSP_ByPassValidation__c){
                accGroupMembr.addError(label.NSP_AccountCannotRemoveFromSelfGroup); 
            }
        }
    }
}