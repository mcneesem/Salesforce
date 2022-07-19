/**
* Represents the Account trigger helper which handles all the logic.
* -------------------------------------------------------------------------------------------------  
* Modification History
*	ManiTeja           March 28 2022        As part of DF-01476, removed setChannelPartnerAndLoyaltyAdvisor reference to populate Loyalty Advisor and CPM based on state.
***************************************************************************************************/
public class NSP_AccountTriggerHelper {
    
    private static final string NSP_AccountTriggerHelper = 'NSP_AccountTriggerHelper';
    private static final string PARTNER_RECORDTYPE = 'NSP_Partner_Client';
    private static final Id PARTNER_RECORDTYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PARTNER_RECORDTYPE).getRecordTypeId();
    private static final string DA_ROLE = 'District Administrator';
    /**
* Iterates throught the list of new Account and passes the required attributes to other methods.
* @param newList List of New Accounts.  
* @return void             
*                
*/
    public void beforeInsertDirector(List<Account> newList){
        try{
            List<Account> partnerAccountList = new List<Account>();
            Set<Id> userIdsSet = new Set<Id>();
             /* Added as part of DF-01906 */
             List<Account> bpaAccountList = new List<Account>();
             Set<string> salesOfficeSet = new Set<String>();
             User userDetails =[SELECT Id, Name, UserRole.Name, ToLabel(NSP_Sales_Office__c) FROM User where Id =: userinfo.getUserId() ];
             /* Added as part of DF-01906 */
            List<Account> acctListToStampDocusignTemplateId = new List<Account>();
            for(Account accountObj : newList) {
                
                // Added as part of DF-01906 to populate CPM and LA based on Sales office of loggedin BPA
                if(accountObj.RecordTypeId==PARTNER_RECORDTYPE_ID){
                    accountObj.NSP_Partner_Lifecycle__c = NSP_SalesConstants.EVALUATION;
                        }
                   if(accountObj.RecordTypeId==PARTNER_RECORDTYPE_ID 
                      && userDetails.UserRole.Name == NSP_SalesConstants.BPA_User && String.isNotBlank(userDetails.NSP_Sales_Office__c)){
                          // Added as part of DF-01154
                          bpaAccountList.add(accountObj);
                          salesOfficeSet.add(userDetails.NSP_Sales_Office__c);
                          
                      }
                   if(accountObj.RecordTypeId==PARTNER_RECORDTYPE_ID 
                      && userDetails.UserRole.Name == NSP_SalesConstants.BPC_USER){
                       accountObj.NSP_Channel_Program_Manager__c = system.label.NSP_CPM_USER;
                   }
                //create list to populate docusign template id for merge on demand templates
                if(!String.isBlank(accountObj.NSP_Template_Selection__c)){
                    acctListToStampDocusignTemplateId.add(accountObj);
                }

                updateAccountSegment(accountObj);
                // update ready to sync to true whenever opportunity is cloned 
                 // added as a part of DF-01145
                 if(accountObj.isClone()){
                    accountObj.NSP_Ready_for_Integration_Sync__c = true;
                } 
            }
            
            if(!bpaAccountList.isEmpty()){
                setChannelPartnerAndLoyaltyAdvisor(bpaAccountList, salesOfficeSet);
           }
            //call method to populate template id
            if(acctListToStampDocusignTemplateId.size() > 0){
                setDummyUsers(acctListToStampDocusignTemplateId);
            }
            
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);    
        }
        
    }
    
    
    /**
* Iterates throught the Account map and identifies the records that needs to worked based on various criterias.
* @param accountNewMap Map of New Account. 
* @param accountOldMap Map of Old Account. 
* @return void             
*                
*/
    public void beforeUpdateDirector(Map<Id, Account> accountNewMap,Map<Id, Account> accountOldMap){
        try{
            
            List<Account> accountList = new List<Account>();
            List<Account> accountownerChangedList = new List<Account>();
            List<Account> partnerAccountList = new List<Account>();
            Set<Id> userIdsSet = new Set<Id>();
            List<Account> acctListToStampDocusignTemplateId = new List<Account>();
            
            //Iterating over the new Account map
            for(Id accountId : accountNewMap.keySet()){
                Account newAccount =  accountNewMap.get(accountId);
                Account oldAccount =  accountOldMap.get(accountId);
                If(String.isNotBlank(accountNewMap.get(accountId).NSP_Account_Status__c)){
                    if(accountNewMap.get(accountId).NSP_Account_Status__c.equals(NSP_SalesConstants.ACTIVE) && 
                       (accountNewMap.get(accountId).NSP_Account_Status__c != accountOldMap.get(accountId).NSP_Account_Status__c)){
                           accountList.add(accountNewMap.get(accountId));
                       }
                }
                
                if(accountNewMap.get(accountId).Ownerid != accountOldMap.get(accountId).Ownerid){
                    accountownerChangedList.add(accountNewMap.get(accountId));
                }

                if(accountNewMap.get(accountId).NumberOfEmployees != accountOldMap.get(accountId).NumberOfEmployees){
                    updateAccountSegment(accountNewMap.get(accountId));
                }
                
                //create list to populate docusign template id for merge on demand templates
                    if(!String.isBlank(newAccount.NSP_Template_Selection__c) && 
                    newAccount.NSP_Template_Selection__c != oldAccount.NSP_Template_Selection__c){
                    acctListToStampDocusignTemplateId.add(newAccount);
                    
                }

                if((newAccount.NSP_Signed_MOD_Document__c
               		&& newAccount.NSP_Signed_MOD_Document__c != oldAccount.NSP_Signed_MOD_Document__c) 
                   	&& (newAccount.NSP_Partner_Lifecycle__c != NSP_SalesConstants.ACTIVE)){
                   		newAccount.NSP_Partner_Lifecycle__c = NSP_SalesConstants.ACTIVE;
                }
                
            }
            
            if(accountList.size() > 0){
                setAccountStage(accountList);
            }
            if(accountownerChangedList.size() > 0){
                setAccountStageWhenOwnerChanged(accountownerChangedList);
            }
            //call updateTriggerclass for metadata check ad update integration sync field on account
            Set<Id> accountIdSetToUpdateResyncFLag = new Set<Id>();
            NSP_SObjectUpdateTriggerHelper sObjectUpdateObj = new NSP_SObjectUpdateTriggerHelper();
            accountIdSetToUpdateResyncFLag.addAll(sObjectUpdateObj.fetchUpdFieldsLst(NSP_IntegrationConstants.SOBJECT_ACCOUNT, accountNewMap, accountOldMap));
            
            if(accountIdSetToUpdateResyncFLag.size() > 0){
                for(Id accountId : accountIdSetToUpdateResyncFLag){
                    accountNewMap.get(accountId).NSP_Ready_for_Integration_Sync__c = true;
                }
            }

            //call method to populate template id
            if(acctListToStampDocusignTemplateId.size() > 0){
                setDummyUsers(acctListToStampDocusignTemplateId);
            }

        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }  
    }
    
    
    /**
* Iterates throught the list of new Account and passes the required attributes to other methods.
* @param newList List of New Account.
* @param newMap List of New Account.
* @return void
*                
*/
    public void afterInsertDirector(List<Account> newList, Map<Id, Account> newMap) {
        try{
            List<Integration_Account_Event__e> accountEventList = New List<Integration_Account_Event__e>();
            List<Account> updateResyncFlagAccountList = new List<Account>();
            // Iterating Trigger.new to feed the Account Id to Event List
            for(Account accObj : newList) {
                if(accObj.NSP_Ready_for_Integration_Sync__c) {
                    accountEventList.add(New Integration_Account_Event__e(Id__c = accObj.Id));
                    updateResyncFlagAccountList.add(accObj);
                }
            }
            // Send the list to publish event bus
            if(accountEventList.size() > 0){
                Id profileId=userinfo.getProfileId();
				String profileName=[SELECT Id,Name from Profile WHERE Id=:profileId].Name;
                /* Adding OR Condition as part of DF-01043 so that publishEventBus method will not trigger for Integration user profile*/
                if(!profileName.containsIgnoreCase(System.label.NSP_Data_Migration_Profile_Name) || 
                   !profileName.containsIgnoreCase(System.label.NSP_Integration_User_Profile_Name)){
                	publishEventBus(accountEventList, updateResyncFlagAccountList);
                }
            }
            
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        } 
    }
    
    /**
* Iterates throught the list of new Account and passes the required attributes to other methods.
* @param newMap List of New Account.
* @param oldMap List of New Account.
* @return void
*                
*/
    
    /* Description: This method send data to publishevent when some particular account field is changed.
     * Modified this method to fire opportunity trigger when owner of account is changed which lead to change owner of opportunity.
     * Added as part of service request - 569324.
     * @param: newMap,oldMap
     * @return: void
     * Modification History:
     * -------------------------------------------------------------------------------------
     * author           | Date              | Description
     * -------------------------------------------------------------------------------------
     * Rahul Singh         	07/11/2022        Modified this method
     * 
     * 
    */
    public void afterUpdateDirector(Map<Id, Account> newMap, Map<Id, Account> oldMap) {
        List<Account> accountList = new List<Account>();	//list to store accounts to handle Tasks when Partner contract is generated
        try{
            Map<Id,DateTime> accountTeamMDeleteMap = new Map<Id,DateTime>();
            Map<Id,String> accountTeamMDelete = new Map<Id,String>();
			List<Integration_Account_Event__e> accountEvent = New List<Integration_Account_Event__e>();
            List<Account> updateAccountList = new List<Account>();
            
            for(Account accObj : newMap.values()){
                if(accObj.NSP_Ready_for_Integration_Sync__c) {
                    accountEvent.add(New Integration_Account_Event__e(Id__c = accObj.Id));
                    updateAccountList.add(accObj);
                }
                 if(accObj.NSP_Delete_Account_Teams__c != Null){
                    accountTeamMDeleteMap.put(accObj.Id,accObj.NSP_Delete_Account_Teams__c);
                    accountTeamMDelete.put(accObj.Id,accObj.NSP_Integrated_With__c);
                } 
                
                if(accObj.NSP_Partner_Lifecycle__c != oldMap.get(accObj.Id).NSP_Partner_Lifecycle__c 
                   && accObj.RecordTypeId==PARTNER_RECORDTYPE_ID && (accObj.NSP_Partner_Lifecycle__c == NSP_SalesConstants.ACTIVE 
                       || accObj.NSP_Partner_Lifecycle__c == NSP_SalesConstants.ONBOARDING)){
                    accountList.add(accObj);
                }
            }
            
            //for tracking history
            if(!test.isRunningTest()){
            NSP_SObjectHistoryTrackingHelper objectFieldHistoryHelper = new NSP_SObjectHistoryTrackingHelper((Map<Id, sObject>)newMap, (Map<Id, sObject>)oldMap);
            If( Limits.getQueueableJobs() != Limits.getLimitQueueableJobs()) {
                System.enqueueJob(objectFieldHistoryHelper);  
            }
        }
            // Send the list to publish event bus
            if(updateAccountList.size() > 0){
                /* Adding If Condition as part of DF-01043 so that publishEventBus method will not trigger for Integration user profile*/
                Id profileId = userinfo.getProfileId();
                String profileName = [SELECT Id,Name from Profile WHERE Id=:profileId].Name;
                if(String.isNotBlank(profileName) && !profileName.containsIgnoreCase(System.label.NSP_Integration_User_Profile_Name)){
                publishEventBus(accountEvent, updateAccountList);
                
                List<Opportunity> oppUpdated = [SELECT Id FROM Opportunity Where OwnerId =:newMap.values().OwnerId AND LastModifiedById=:newMap.values().LastModifiedById AND LastModifiedDate =:newMap.values().LastModifiedDate];
                List<Opportunity> listOppOwner = new List<Opportunity>();
               //update opportunity to fire opportunity trigger
                	if(oppUpdated.size() > 0){
			        	for(Opportunity oppObj :oppUpdated ){
                        oppObj.NSP_Ready_for_Integration_Sync__c = true; 
                        listOppOwner.add(oppObj);
                    	}
                    update listOppOwner;
                    }
                }
            }
            
            if(accountList.size() > 0) {
                handleTaskForPartnerContracts(accountList);
            }
            
            //call future method
            if(accountTeamMDeleteMap.size() > 0){
                deleteAccountTeam(accountTeamMDeleteMap, accountTeamMDelete);
            }
            
            //for tracking history
            //NSP_SObjectHistoryTrackingHelper objectFieldHistoryHelper = new NSP_SObjectHistoryTrackingHelper((Map<Id, sObject>)newMap, (Map<Id, sObject>)oldMap);
            //System.enqueueJob(objectFieldHistoryHelper);
                
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        } 
    }
    
    public void setAccountStage (List<Account> accountList){
        
        for(Account accountObj : accountList){ 
            List<String> profileList = Label.NSP_Sales_Profiles.split(',');
            if(profileList.contains(accountObj.NSP_Account_Owners_Profile__c)){
                if(String.isNotBlank(accountObj.NSP_Stage__c) && (accountObj.NSP_Stage__c.equalsIgnoreCase(NSP_SalesConstants.STR_NEW) ||
                                                                  accountObj.NSP_Stage__c.equalsIgnoreCase(NSP_SalesConstants.AVAILABLE))){
                    accountObj.NSP_Stage__c = NSP_SalesConstants.ASSIGNED;
                                                                  }
            }else{
                
                if(String.isNotBlank(accountObj.NSP_Stage__c) && (accountObj.NSP_Stage__c.equalsIgnoreCase(NSP_SalesConstants.STR_NEW))){
                    accountObj.NSP_Stage__c = NSP_SalesConstants.AVAILABLE;
                }
            } 
        }
    }
    
    public void setAccountStageWhenOwnerChanged (List<Account> accountList){
        
        for(Account accountObj : accountList){
            List<String> profileList = Label.NSP_Sales_Profiles.split(',');
            if(profileList.contains(accountObj.NSP_Account_Owners_Profile__c)){
                if(String.isNotBlank(accountObj.NSP_Stage__c) && accountObj.NSP_Stage__c.equals(NSP_SalesConstants.AVAILABLE)){
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
    public void publishEventBus(List<Integration_Account_Event__e> eventList, List<Account> objectList) {
        List<Account> updateResyncFlagAccountList = new List<Account>();
        
        if(!eventList.isEmpty()) {
            // Publishing records Event 
            List<Database.SaveResult> results = EventBus.publish(eventList);
            
            // Inspect publishing result for each event
            List<NSP_Error_Log__c> logList = new List<NSP_Error_Log__c>();
            for (Database.SaveResult sr : results) {
                NSP_Error_Log__c log = new NSP_Error_Log__c();
                log.NSP_Class__c = NSP_AccountTriggerHelper;
                log.NSP_Method__c = 'publishEventBus';                
                log.NSP_Description__c = String.valueOf(sr.getErrors()[0].getMessage()) + '  '+String.valueOf(sr.getErrors()[0].getStatusCode());
                log.NSP_Record_Id__c = sr.getId();
                logList.add(log);  
            }
            
            if(logList.size() > 0){
                insert logList;
            }
            
            for(Account  accObj : objectList) {
                Account tempAccObj = new Account();
                tempAccObj.Id = accObj.Id;
                tempAccObj.NSP_Ready_for_Integration_Sync__c = FALSE;
                updateResyncFlagAccountList.add(tempAccObj);
            }
            
            if(updateResyncFlagAccountList.size() > 0){
                update updateResyncFlagAccountList; 
            }
        }
    }
    
    /**
* Iterates throught the Account Id set and update successfully publish Account records.
* @param idSet Map of New Account. 
* @return void             
* 
*/
    Public void updatePublishAccount(set<Id> idSet) {
        
        List<Account> successAccountList = [SELECT Id, NSP_Ready_for_Integration_Sync__c from Account WHERE Id =: idSet];
        
        // Iterating Success set Id to
        for(Account accountObj : successAccountList){
            accountObj.NSP_Ready_for_Integration_Sync__c = FALSE;
        }
        
        // Account records update.
        Update successAccountList;
    }

        /*
     * Description: Method takes all Account records WHERE partner lifecycle is 
     * set to Onboarding or Active and creates a new task or marks existing task complete based on 
     * partner lifecycle value
     * @Param : List of New Accounts: accountsList
     * @return type: void 
*/
public static void handleTaskForPartnerContracts(List<Account> accountList){
    List<Task> tasksToUpsert = new List<Task>();
    Set<Id> accountIdsSet = new Set<Id>();
    for(Account accountRecord : accountList){
        if(accountRecord.NSP_Partner_Lifecycle__c.equals(NSP_SalesConstants.ONBOARDING)){
            /*Task taskRecord = NSP_UtilityClass.instantiateTaskRecord(NSP_SalesConstants.PARTNER_CONTRACT_GENERATED, accountRecord.Id, '',
                                                                    accountRecord.OwnerId,'',NSP_SalesConstants.OPEN,
                                                                     NSP_SalesConstants.PARTNER_AGREEMENT,null);*/
            Task taskRecord = new Task(
                Subject = NSP_SalesConstants.PARTNER_CONTRACT_GENERATED,
                WhatId = accountRecord.Id,
                OwnerId = accountRecord.OwnerId,
                NSP_Task_type__c = NSP_SalesConstants.CHANNELS,
                NSP_Task_Subtype__c = NSP_SalesConstants.PARTNER_AGREEMENT,
                Status = NSP_SalesConstants.OPEN
            );
            taskRecord.NSP_Task_type__c = NSP_SalesConstants.CHANNELS;
            tasksToUpsert.add(taskRecord);
        }else if(accountRecord.NSP_Partner_Lifecycle__c == NSP_SalesConstants.ACTIVE){
            accountIdsSet.add(accountRecord.Id);
        }
    }
    
    if(accountIdsSet.size()>0){
        List<Task> taskstoUpdate = [SELECT Id, Subject, Status, NSP_Task_type__c, NSP_Task_Subtype__c FROM Task WHERE WhatId IN :accountIdsSet
                                   AND NSP_Task_type__c = :NSP_SalesConstants.CHANNELS  AND NSP_Task_Subtype__c = :NSP_SalesConstants.PARTNER_AGREEMENT 
                                    AND Status != :NSP_SalesConstants.COMPLETED];
        for(Task taskRecord : taskstoUpdate){
            taskRecord.Status = NSP_SalesConstants.COMPLETED;
            tasksToUpsert.add(taskRecord);
        }
    }
    
    if(tasksToUpsert.size()>0){
        try{                
            upsert tasksToUpsert;
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }
}

  /*
     * Description: This method is used to populate CPM and LA on Account on insertion based on BPA sales office group
     * @Param : List of New Accounts: accountsList and salesOfficeSet
     * @return type: void 
     * Defect: DF-01906
*/
public static void setChannelPartnerAndLoyaltyAdvisor(List<Account> accList, Set<String> salesOfficeSet) {
    Map<String, string> grpIdGrpMemMap = new Map<String, string>();
    Map<String, string> grpNameCPMUserMap = new Map<String, string>();
    Map<String, string> grpNameLAUserMap = new Map<String, string>();
    try{
          User userDetails =[SELECT Id, Name, UserRole.Name, ToLabel(NSP_Sales_Office__c) FROM User where Id =: userinfo.getUserId() ];
        //mapping userId and group Name
        for(GroupMember gMem : [SELECT groupId, group.Name, UserOrGroupId FROM GroupMember WHERE group.Name IN: salesOfficeSet]){
            if(String.valueOf(gMem.UserOrGroupId).startsWith('005')){   
                grpIdGrpMemMap.put(gMem.UserOrGroupId, gMem.group.Name);     
            }
        }
        if(!grpIdGrpMemMap.isEmpty()){
            //mapping  group Name and userId
            for(User getUser : [SELECT Id, UserRoleId, userRole.Name FROM User 
                                WHERE (userRole.Name = 'Loyalty Advisor' OR userRole.Name = 'Channel Program Manager') AND Id IN: grpIdGrpMemMap.keySet()]){
                                    if(getUser.userRole.Name == 'Loyalty Advisor'){
                                        grpNameLAUserMap.put(grpIdGrpMemMap.get(getUser.Id), getUser.Id);        
                                    }else if(getUser.userRole.Name == 'Channel Program Manager'){
                                        grpNameCPMUserMap.put(grpIdGrpMemMap.get(getUser.Id), getUser.Id);
                                    }
                                } 
            for(Account ac : accList){
                if(!grpNameLAUserMap.isEmpty() && grpNameLAUserMap.containsKey(userDetails.NSP_Sales_Office__c)){
                    ac.NSP_Loyalty_Advisor__c = grpNameLAUserMap.get(userDetails.NSP_Sales_Office__c);      
                }
               if(!grpNameCPMUserMap.isEmpty() && grpNameCPMUserMap.containsKey(userDetails.NSP_Sales_Office__c)){
                    ac.NSP_Channel_Program_Manager__c = grpNameCPMUserMap.get(userDetails.NSP_Sales_Office__c);      
                }
            }         
        }
    }catch(Exception ex){
        NSP_ErrorLogHandler.logSaveException(NSP_AccountTriggerHelper,'setChannelPartnerAndLoyaltyAdvisor',ex.getMessage());
    }
} 

    /**
    * Based on the number of employees, Account segmentation field is populated.
    *param accountObject
    *returns void
    */
        public static void updateAccountSegment(Account accountObject){
    if(accountObject.NumberOfEmployees > Integer.valueOf(System.Label.NSP_MidMarket_Threshold)){
        accountObject.NSP_Account_Segment__c = System.Label.NSP_Account_Segment_MidMarket;
    } else if(accountObject.NumberOfEmployees > Integer.valueOf(System.Label.NSP_Emerging_Growth_Threshold_Employees) 
              && accountObject.NumberOfEmployees <= Integer.valueOf(System.Label.NSP_MidMarket_Threshold)){
                  accountObject.NSP_Account_Segment__c = System.Label.NSP_Account_Segment_Emerging_Growth;
              }else if(accountObject.NumberOfEmployees!=null){
                accountObject.NSP_Account_Segment__c = System.Label.NSP_Account_Segment_Core_Sales;
            }        
    
    }
    
    /**
    * Iterates throught the Account Id set and update successfully publish Account records.
    * @param idSet Map of New Account. 
    * @return void             
    * 
    */
    @future
    public static void deleteAccountTeam(Map<Id,DateTime> accountIdDeleteAccountTeamMap, Map<Id,String> accountTeamMDelete){
        try{
        List<NSP_Account_Team__c> accountTeamList = [SELECT Id, NSP_Account__c , NSP_Integrated_With__c from NSP_Account_Team__c
                                                     WHERE NSP_Account__c IN: accountIdDeleteAccountTeamMap.keySet() AND createdBy.profile.name = :System.label.NSP_Integration_Profile_Name
                                                    AND createddate < :accountIdDeleteAccountTeamMap.values()
                                                    AND NSP_Integrated_With__c != ''];
        List<NSP_Account_Team__c> accountDelTeamList = new List<NSP_Account_Team__c>();
        if(!accountTeamList.isEmpty()){
           for(NSP_Account_Team__c nspAccTeam : accountTeamList){
              if(nspAccTeam.NSP_Integrated_With__c == accountTeamMDelete.get(nspAccTeam.NSP_Account__c)){
                  NSP_Account_Team__c newAccTeam = new NSP_Account_Team__c();
                  newAccTeam.Id = nspAccTeam.Id;
                  accountDelTeamList.add(newAccTeam);
              }
           }      
        }
        if(!accountDelTeamList.isEmpty()){
           delete accountDelTeamList;
        }
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }

    
   /* Description: This method sets signer to dummy user
     * BPA to Account owner if role is BPA
     * @param: accountList
     * @return: void
     * Modification History:
     * -------------------------------------------------------------------------------------
     * author           | Date              | Description
     * -------------------------------------------------------------------------------------
     * Harsha Khiroya         	12/22/2021         	created this new method
     * 
     * 
    */
    public void setDummyUsers(List<Account> accountList){
        
        try{
            
            List<User> dummyUser = [SELECT Id FROM User WHERE Name =: NSP_SalesConstants.DUMMY_USER_SIGNER limit 1];
        
            for(Account accountObj : accountList){
            //if Opportunity owner is BPA
            //set BPA as owner or set as dummy user
            if(accountObj.NSP_BPA__c == null ){
                if(accountObj.Account_Owner_Role__c == NSP_SalesConstants.BPA_User){
                    accountObj.NSP_BPA__c = accountObj.OwnerId;
                }else{
                    accountObj.NSP_BPA__c = dummyUser[0].Id;
                }
            }
            if(accountObj.Channel_Manager__c == null){
                accountObj.Channel_Manager__c = dummyUser[0].Id;
            }
            if(accountObj.NSP_Channel_Partner_Manager__c == null){
                accountObj.NSP_Channel_Partner_Manager__c = dummyUser[0].Id;
            }
            if(accountObj.NSP_Channel_Program_Manager__c == null){
                accountObj.NSP_Channel_Program_Manager__c = dummyUser[0].Id;
            }
            
            
        }}catch(Exception ex){
            NSP_CustomException.LogException(ex);
            
        }
    }
}