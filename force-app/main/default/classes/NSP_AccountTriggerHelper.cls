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
            Set<String> stateCodeSet = new Set<String>();
            List<Account> integrationAccountList = new List<Account>(); //Accounts created from External Site
            Set<String> docuSignTemplateName = new Set<String>();
            List<Account> acctListToStampDocusignTemplateId = new List<Account>();
            for(Account accountObj : newList) {
                //Partner Accounts created from Partner Form. As part of DF-01476, when Partner Account is created from Partner Form, Loyalty Advisor 
                // CPM will populate based on Zipcode
                if(accountObj.RecordTypeId==PARTNER_RECORDTYPE_ID 
                && String.isNotBlank(accountObj.BillingState)){
                    accountObj.NSP_Partner_Lifecycle__c = NSP_SalesConstants.EVALUATION; // Added as part of DF-01154
                    integrationAccountList.add(accountObj);
                    stateCodeSet.add(accountObj.BillingState);
                }
                
                //create list to populate docusign template id for merge on demand templates
                if(!String.isBlank(accountObj.NSP_Template_Selection__c)){
                    acctListToStampDocusignTemplateId.add(accountObj);
                    docuSignTemplateName.add(accountObj.NSP_Template_Selection__c);
                }

                updateAccountSegment(accountObj);
                // update ready to sync to true whenever opportunity is cloned 
                 // added as a part of DF-01145
                 if(accountObj.isClone()){
                    accountObj.NSP_Ready_for_Integration_Sync__c = true;
                } 
            }
            
            if(! integrationAccountList.isEmpty()){
                setCPMAndLAForIntegrationAccounts(integrationAccountList,stateCodeSet);
            }
            //call method to populate template id
            if(acctListToStampDocusignTemplateId.size() > 0){
                setDocuSignTemplateId(acctListToStampDocusignTemplateId,docuSignTemplateName);
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
            Set<String> stateCodeSet = new Set<String>();
            List<Account> integrationAccountList = new List<Account>(); //Accounts created from External Site
            Set<String> docuSignTemplateName = new Set<String>();
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
                                        
                    //Partner Accounts created from Partner Form. As part of DF-01476, when Partner Account is created from Partner Form, Loyalty Advisor 
                    // CPM will populate based on state
                    if(accountNewMap.get(accountId).RecordTypeId==PARTNER_RECORDTYPE_ID 
                       && String.isNotBlank(accountNewMap.get(accountId).BillingStateCode)
                       && accountNewMap.get(accountId).BillingStateCode != accountOldMap.get(accountId).BillingStateCode){
                           integrationAccountList.add(accountNewMap.get(accountId));
                           stateCodeSet.add(accountNewMap.get(accountId).BillingStateCode);
                       }
                }

                if(accountNewMap.get(accountId).NumberOfEmployees != accountOldMap.get(accountId).NumberOfEmployees){
                    updateAccountSegment(accountNewMap.get(accountId));
                }
                
                //create list to populate docusign template id for merge on demand templates
                    if(!String.isBlank(newAccount.NSP_Template_Selection__c) && 
                    newAccount.NSP_Template_Selection__c != oldAccount.NSP_Template_Selection__c){
                    acctListToStampDocusignTemplateId.add(newAccount);
                    docuSignTemplateName.add(newAccount.NSP_Template_Selection__c);
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
            if(! integrationAccountList.isEmpty()){
                setCPMAndLAForIntegrationAccounts(integrationAccountList,stateCodeSet);
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
                setDocuSignTemplateId(acctListToStampDocusignTemplateId,docuSignTemplateName);
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
            NSP_SObjectHistoryTrackingHelper objectFieldHistoryHelper = new NSP_SObjectHistoryTrackingHelper((Map<Id, sObject>)newMap, (Map<Id, sObject>)oldMap);
            If( Limits.getQueueableJobs() != Limits.getLimitQueueableJobs()) {
                System.enqueueJob(objectFieldHistoryHelper);  
            }

            // Send the list to publish event bus
            if(updateAccountList.size() > 0){
                /* Adding If Condition as part of DF-01043 so that publishEventBus method will not trigger for Integration user profile*/
                Id profileId = userinfo.getProfileId();
                String profileName = [SELECT Id,Name from Profile WHERE Id=:profileId].Name;
                if(String.isNotBlank(profileName) && !profileName.containsIgnoreCase(System.label.NSP_Integration_User_Profile_Name)){
                publishEventBus(accountEvent, updateAccountList);
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
     * Description: This method accepts all Partner Accounts owned by Integration Users(created from External Site)
     * and sets the Channel Program Manager(CPM) and Loyalty Advisor(LA) based on
     * Account's State. CPM and LA are fetched from State Assignment Object records
     * @Param : List of New Accounts: accountsList and stateCodeSet
     * @return type: void 
*/
    public static void setCPMAndLAForIntegrationAccounts(List<Account> accountsList, Set<String> stateCodeSet) {
        Map<String, NSP_State_Assignment__c> stateAssignmentsMap = new Map<String, NSP_State_Assignment__c>();
        
        
        List<NSP_State_Assignment__c> stateAssignments = [SELECT Id,Name, NSP_Channel_Program_Manager__c,NSP_State__c,NSP_Loyalty_Advisor__c,
                                                          NSP_Channel_Program_Manager__r.IsActive
                                                          FROM NSP_State_Assignment__c WHERE NSP_State__c IN :stateCodeSet];        
        
        for(NSP_State_Assignment__c stateAssignment : stateAssignments){
            stateAssignmentsMap.put(stateAssignment.NSP_State__c, stateAssignment);
        }
        
        for(Account accountRecord : accountsList){
            if(stateAssignmentsMap.containsKey(accountRecord.BillingState)){
                NSP_State_Assignment__c stateAssignment = stateAssignmentsMap.get(accountRecord.BillingState);
                accountRecord.NSP_Channel_Program_Manager__c = stateAssignment.NSP_Channel_Program_Manager__c;
                accountRecord.NSP_Loyalty_Advisor__c = stateAssignment.NSP_Loyalty_Advisor__c;
            }
        }
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

/* Description: This method sets NSP_Merge_On_Demand_DocuSign_Template_Id__c
     * 
     * @param: setAcctTemplateIdList
     * @param templateName
     * @return: void
     * Modification History:
     * -------------------------------------------------------------------------------------
     * author           | Date              | Description
     * -------------------------------------------------------------------------------------
     * harsha khiroya         	10/21/2021         	created this new method
     * 
     * 
    */
    public void setDocuSignTemplateId(List<Account> setAcctTemplateIdList,Set<String> templateName){
        //get custom metadata for docusign template mapping
        Map<String,NSP_DocuSign_Template_Mapping__mdt> templateNameIdMap = new Map<String,NSP_DocuSign_Template_Mapping__mdt>();
        List<NSP_DocuSign_Template_Mapping__mdt> docusignTemplateMappingList = [SELECT NSP_Template_Id__c,NSP_Template_Name__c
                                                                               From NSP_DocuSign_Template_Mapping__mdt WHERE NSP_Template_Name__c IN: templateName];
        
        for(NSP_DocuSign_Template_Mapping__mdt docuSignTemplateObj : docusignTemplateMappingList){
            templateNameIdMap.put(docuSignTemplateObj.NSP_Template_Name__c,docuSignTemplateObj);
        }
        
        for(Account AcctObj : setAcctTemplateIdList){
            if(templateNameIdMap.containsKey(AcctObj.NSP_Template_Selection__c)){
                AcctObj.NSP_Merge_On_Demand_DocuSign_Template_Id__c = templateNameIdMap.get(AcctObj.NSP_Template_Selection__c).NSP_Template_Id__c;
            }
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