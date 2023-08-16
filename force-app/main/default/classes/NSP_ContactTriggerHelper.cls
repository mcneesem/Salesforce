/* 
*    ClassName:NSP_ContactTriggerHelper
*    @description: Represents the Contact trigger helper which handles all the logic.
*    @date: 06/07/2021
*    @author: Tejas
*/

public class NSP_ContactTriggerHelper {
    public static final String INSPERITYROLE = 'Insperity';
    public static final String CUSTOMERROLE = 'Customer';
    public static final String COMMUNITYLICENSE = 'Customer Community';
    public static final Id RESOURCE_REC_TYPE_ID = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.CONTACT_OBJECT, 'Resource');
    public static final Id NEW_CON_REC_TYPE_ID = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.CONTACT_OBJECT,'New_Contact_Record_Type');
    public static final List<String> INT_DM_PROFILES = new List<String>{NSP_ServiceConstants.INTEGRATION_USER, NSP_ServiceConstants.DATA_MIGRATION};
    public static final List<String> ALLOWED_PROFILES = new List<String>{'BPS Service','Contact Center','PEO Service','Retirement Services'};
    public static final String WORK_CALENDAR_US40 ='US 40';
        
    /**
* Iterates throught the list of new Contact and passes the required attributes to other methods.
* @param newList List of New Contact.
* @param newMap List of New Contact.
* @return void
*                
*/
    
    public void beforeInsertDirector(List<Contact> newList) {
        
        //STY-02849/DF-05013 - Default Resource Fields on manually created contacts - start
        List<Profile> loggedInUserProfileName = getLoggedInUserProfile();
        Id regionId, workCalenderId = null;
        if(loggedInUserProfileName.size() > 0 && ALLOWED_PROFILES.contains(loggedInUserProfileName[0].Name)) {
            regionId = getRegionId();
        	workCalenderId = getWorkCalendarId();
        }
        //STY-02849/DF-05013 - Default Resource Fields on manually created contacts - end
        
        for(Contact conObj : newList){
            if(conObj.NSP_Client_Reference__c){
                conObj.NSP_Client_Reference_Task_Date__c = system.today();
            }
            if(conObj.recordTypeId == NEW_CON_REC_TYPE_ID){
                conObj.recordTypeId = RESOURCE_REC_TYPE_ID; // Added as  part of STY-02840
            }
                conObj.NSP_isContactInsertion__c = true;
            
            //STY-02849/DF-05013 - Default Resource Fields on manually created contacts - start
            if(ALLOWED_PROFILES.contains(loggedInUserProfileName[0].Name)) {
                conObj.pse__Is_Resource_Active__c = true;
                conObj.pse__Is_Resource__c = true;
                conObj.pse__Region__c =  regionId;
                conObj.pse__Work_Calendar__c = workCalenderId;
            }
            //STY-02849/DF-05013 - Default Resource Fields on manually created contacts - end
        }
        //Format Phone number
        if(loggedInUserProfileName.size() > 0 && !INT_DM_PROFILES.contains(loggedInUserProfileName[0].Name)){
            updatePhoneNumber(newList);
        }
        try{
            //if(loggedInUserProfileName.size() > 0 && !INT_DM_PROFILES.contains(loggedInUserProfileName[0].Name)){
                Set<Id> sUserIds = new Set<Id>();
                List<Contact> lContacts = new List<Contact>();
                for(Contact conObj : newList ){
                  // UPDATE RESOURCE ROLE
                  if(conObj.pse__Salesforce_User__c != null){
                     sUserIds.add(conObj.pse__Salesforce_User__c);
                     lContacts.add(conObj);
                  }
                  // UPDATE SSN
                  if(conObj.NSP_SSN__c != null && conObj.NSP_SSN__c.length() > 4 ){
                     conObj.NSP_Last_4Digit_Of_SSN__c = conObj.NSP_SSN__c.right(4);
                  }
                }
               if(sUserIds.size() > 0){
                 updateContactRoles(sUserIds,lContacts);
               }
            //}     
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
       
    
        if(loggedInUserProfileName.size() > 0 && !INT_DM_PROFILES.contains(loggedInUserProfileName[0].Name)){
            setSalesOfficeDetails(newList,null);
        }
    }        
        
    /**
* Iterates throught the list of new Contact and passes the required attributes to other methods.
* @param newList List of New Contact.
* @param newMap List of New Contact.
* @return void
*                
*/

public void afterInsertDirector(List < Contact > newList, Map < Id, Contact > newMap) {
    Map<Id, Contact> ConIdcontactMap = new Map<Id,Contact>();
    List < Contact > clientRefernceContactList = new List < Contact > ();
    List<Profile> loggedInUserProfileName = getLoggedInUserProfile();
    if(loggedInUserProfileName.size() > 0 && !INT_DM_PROFILES.contains(loggedInUserProfileName[0].Name)){
        for (Contact conObj: newList) {
          if (conObj.NSP_Client_Reference__c) {
            clientRefernceContactList.add(conObj);
          }
          ConIdcontactMap.put(conObj.Id, conObj);
        
        }
       if(!ConIdcontactMap.isEmpty()){
               updateWorkPhoneEmailOnACR(ConIdcontactMap);
       } 
      if (clientRefernceContactList.size() > 0) {
        createTaskforClientReference(clientRefernceContactList);
      }
    }
}
    
    
    /**
* Iterates throught the list of new Contact and passes the required attributes to other methods.
* @param newList List of New Contact.
* @param newMap List of New Contact.
* @return void
*                
*/
    
    public void beforeUpdateDirector(Map<Id,Contact> newMap,Map<Id,Contact> oldMap) {
        List<Profile> loggedInUserProfileName = getLoggedInUserProfile();
        try{
        Set<Id> sUserIds = new Set<Id>();
        List<Contact> lContacts = new List<Contact>();
        //if(loggedInUserProfileName.size() > 0 && !INT_DM_PROFILES.contains(loggedInUserProfileName[0].Name)){
          for(Contact conObj : newMap.values()){
            if(conObj.NSP_Client_Reference__c != oldMap.get(conObj.Id).NSP_Client_Reference__c 
               && conObj.NSP_Client_Reference__c){
                   conObj.NSP_Client_Reference_Task_Date__c = system.today();
               }
            //UPDATE ROLE FILTER
            if(conObj.pse__Salesforce_User__c != null && conObj.pse__Salesforce_User__c != oldMap.get(conObj.Id).pse__Salesforce_User__c){
                sUserIds.add(conObj.pse__Salesforce_User__c);
                lContacts.add(conObj);
            }
             if(conObj.NSP_SSN__c != null && conObj.NSP_SSN__c.length() > 4 && oldMap.get(conObj.Id).NSP_SSN__c != conObj.NSP_SSN__c){
            conObj.NSP_Last_4Digit_Of_SSN__c = conObj.NSP_SSN__c.right(4);
            }
        }
         if(sUserIds.size() > 0){
            updateContactRoles(sUserIds,lContacts);
         }
        //}
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
        //Format Phone Number
            if(loggedInUserProfileName.size() > 0 && !INT_DM_PROFILES.contains(loggedInUserProfileName[0].Name)){
                updatePhoneNum(newMap.Values(),oldMap);
            }
        //for integration
        Set<Id> accountIdSetToUpdateResyncFLag = new Set<Id>();
        NSP_SObjectUpdateTriggerHelper sObjectUpdateObj = new NSP_SObjectUpdateTriggerHelper();
        accountIdSetToUpdateResyncFLag = sObjectUpdateObj.fetchUpdFieldsLst(NSP_IntegrationConstants.SOBJECT_CONTACT, newMap, oldMap);
        
        if(accountIdSetToUpdateResyncFLag.size() > 0 && loggedInUserProfileName.size() > 0 && !INT_DM_PROFILES.contains(loggedInUserProfileName[0].Name)){
            List<Account> accountList = new List<Account>();
            for(Id accountId : accountIdSetToUpdateResyncFLag){
                Account accountObj = new Account();
                accountObj.Id = accountId;
                accountObj.NSP_Ready_for_Integration_Sync__c = true;
                accountList.add(accountObj);
            }
            if(accountList.size() > 0){
                NSP_AccountTriggerHandler.TriggerDisabled = true; // added for 195356
                update accountList; 
            }
            
        }
        
        if(loggedInUserProfileName.size() > 0 && !INT_DM_PROFILES.contains(loggedInUserProfileName[0].Name)){
                setSalesOfficeDetails(newMap.values(),oldMap);
        }
    }
    
    /**
* Iterates throught the event list publish the records in event bus.
* @param eventList of New Contact.
* @param objectList of New Contact.
* @return void             
* 
*/
    
    public void publishEventBus(List<Integration_Account_Event__e> eventList, Set<Id> idSet) {
        
        List<Account> accountList = [SELECT Id, Name, NSP_Ready_for_Integration_Sync__c FROM Account WHERE Id =: idSet];
        if(!eventList.isEmpty()) {
            // Publishing records Event 
            EventBus.publish(eventList);
            for(Account account : accountList) {
                account.NSP_Ready_for_Integration_Sync__c = FALSE;
            }
        }
        // Account records update.
        Update accountList;
    }
    
    
    /**
* Iterates through the list of new Contact and passes the required attributes to other methods.
* @param newList List of New Contact.
* @param newMap List of New Contact.
* @return void
*                
*/
    
    public void afterUpdateDirector(Map<Id, Contact> newMap,Map<Id, Contact> oldMap) {
        List<Profile> loggedInUserProfileName = getLoggedInUserProfile();
        try{
            List<Contact> clientRefernceContactList = new List<Contact>();
            Map<Id, Contact> ConIdcontactMap = new Map<Id,Contact>();
            Contact oldContact;
            if(loggedInUserProfileName.size() > 0 && !INT_DM_PROFILES.contains(loggedInUserProfileName[0].Name)){
              for(Contact conObj : newMap.values()){
                oldContact = oldMap.get(conObj.Id);
                if(conObj.NSP_Client_Reference__c != oldMap.get(conObj.Id).NSP_Client_Reference__c 
                   && conObj.NSP_Client_Reference__c){
                       clientRefernceContactList.add(conObj);
                   }
                if((conObj.NSP_Work_Phone__c != null && oldContact.NSP_Work_Phone__c != conObj.NSP_Work_Phone__c) || 
                   (conObj.NSP_Work_email__c != null && oldContact.NSP_Work_email__c != conObj.NSP_Work_email__c) ||
                   oldContact.NSP_Employee_Status__c != conObj.NSP_Employee_Status__c ||
                   oldContact.NSP_Status_Date__c != conObj.NSP_Status_Date__c ||
                   oldContact.NSP_Job_Title__c != conObj.NSP_Job_Title__c){
                    ConIdcontactMap.put(conObj.Id, conObj);
                }
              }
            
              if(clientRefernceContactList.size() > 0){
                 createTaskforClientReference(clientRefernceContactList);
              }
            if(!ConIdcontactMap.isEmpty()){
                updateWorkPhoneEmailOnACR(ConIdcontactMap);
            }
            }
            //for tracking history
            NSP_SObjectHistoryTrackingHelper objectFieldHistoryHelper = new NSP_SObjectHistoryTrackingHelper((Map<Id, sObject>)newMap, (Map<Id, sObject>)oldMap);
            If( Limits.getQueueableJobs() != Limits.getLimitQueueableJobs()) {
                System.enqueueJob(objectFieldHistoryHelper);  
            }
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        } 
    }
    
    /**
* Iterates throught the list of new Contact and passes the required attributes to other methods.
* @param newList List of New Contact.
* @param newMap List of New Contact.
* @return void
*                
*/
    public void createTaskforClientReference(List<Contact> clientReferenceContactList){
        List<Task> taskList = new List<Task>();
        for(Contact conObj : clientReferenceContactList){
            Task taskObj = new Task();
            taskObj.Type = NSP_SalesConstants.CLIENT_REFERENCE_TASKTYPE;
            taskObj.Status = NSP_SalesConstants.COMPLETED;
            taskObj.whoId = conObj.Id;
            taskObj.Subject = System.Label.NSP_Client_Reference_Task_Subject;
            taskList.add(taskObj);
        }
        insert taskList;
    }
  /**
* Method Name : updatePhoneNumber 
* Description : Method to format Phone number on insert
* Author : Raksha       Date : 22/02/2022
* @param currentRecordsList List of New Contact.  
* @return void  
*/
public void updatePhoneNumber(List<Contact> currentRecordsList) {
    for(Contact contact : currentRecordsList){
        if(contact.Phone != null) {
        Pattern nonAlphanumeric = Pattern.compile('[^a-zA-Z0-9]');
        String initialNum = nonAlphanumeric.matcher(contact.Phone).replaceAll('').replace(NSP_ServiceConstants.EXT,'x');
        Pattern numFormat10Dig = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{4})');
        Pattern numFormat10Ext = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{4})(x\\d{3})?$');
        Pattern numFormat11Dig;
        Pattern numFormat11Ext;
        if(initialNum.startsWith('1')) {
            numFormat11Dig = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{5})');  
            numFormat11Ext = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{5})(x\\d{3})?$');
            if(numFormat11Dig.matcher(initialNum).matches() || numFormat11Ext.matcher(initialNum).matches()) {
                contact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(contact.Phone);
            }
        }
        if(numFormat10Dig.matcher(initialNum).matches() || numFormat10Ext.matcher(initialNum).matches()) {
            contact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(contact.Phone);
        }
        else {
            contact.NSP_Formatted_Phone_Num__c = contact.Phone;
        }
        } 
    }
}
/**
* Method Name : updatePhoneNum 
* Description : Method to format Phone number on update
* Author : Raksha       Date : 22/02/2022
* @param newContactList,contactOldMap.  
* @return void  
*/   
public void updatePhoneNum(List<Contact> newContactList,Map<Id,Contact> contactOldMap){
    for(Contact newContact : newContactList ) {
        Contact oldContact = contactOldMap != null ? contactOldMap.get(newContact.Id): null;
        if(newContact.Phone != oldContact.Phone && newContact.Phone != null){
            Pattern nonAlphanumeric = Pattern.compile('[^a-zA-Z0-9]');
            String initialNum = nonAlphanumeric.matcher(newContact.Phone).replaceAll('').replace(NSP_ServiceConstants.EXT,'x');
            Pattern numFormat10Dig = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{4})');
            Pattern numFormat10Ext = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{4})(x\\d{3})?$');
            Pattern numFormat11Dig;
            Pattern numFormat11Ext;
            if(initialNum.startsWith('1')) {
                numFormat11Dig = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{5})');  
                numFormat11Ext = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{5})(x\\d{3})?$');
                if(numFormat11Dig.matcher(initialNum).matches() || numFormat11Ext.matcher(initialNum).matches()) {
                    newContact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(newContact.Phone);
                }
                else if(numFormat10Dig.matcher(initialNum).matches() || numFormat10Ext.matcher(initialNum).matches()) {
                    newContact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(newContact.Phone);
                }
                else {
                    newContact.NSP_Formatted_Phone_Num__c = newContact.Phone;
                }
            }
            else if(numFormat10Dig.matcher(initialNum).matches() || numFormat10Ext.matcher(initialNum).matches()) {
                newContact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(newContact.Phone);
            }
            else {
                newContact.NSP_Formatted_Phone_Num__c = newContact.Phone;
            }
        }
        if(newContact.Phone == null){
            newContact.NSP_Formatted_Phone_Num__c = null;
        }
    }
}
/**
* Method Name : formatPhoneNumbers 
* Description : Method to format Phone number
* Author : Raksha       Date : 22/02/2022
* @param String input called from updatePhoneNum.  
* @return String  
*/   
public String formatPhoneNumbers(String input) {
    String requiredOutput;
    input = input.replaceAll('\\(', '').replaceAll('\\)', '');
    input = input.replaceAll('-', '');
    String trimString = input.deleteWhitespace();
    List<String> parts = new List<String>();
    if(trimString.contains(NSP_ServiceConstants.EXT)) {
        parts = trimString.split(NSP_ServiceConstants.EXT);
        requiredOutput = formatCommonPattern(parts.get(0).trim())+ ' x'+parts.get(1);
    } else  if(trimString.contains('x')) {
        parts = trimString.split('x');
        requiredOutput = formatCommonPattern(parts.get(0).trim())+ ' x'+parts.get(1);
    } else {
        requiredOutput = formatCommonPattern(trimString);
    }
    return requiredOutput;
}
/**
* Method Name : formatCommonPattern 
* Description : Method to construct common pattern and format Phone number
* Author : Raksha       Date : 22/02/2022
* @param String input called from formatPhoneNumbers.  
* @return String  
*/ 
public String formatCommonPattern(String input) {
    if(input.length() == 10){
        String number1 = input.replaceFirst('(\\d{3})(\\d{3})(\\d+)', '($1) $2-$3');
        return number1;
    }
    String substring = input.length() > 10 ? input.substring(input.length() - 10) : input;
    String codeNumber = substring.replaceFirst('(\\d{3})(\\d{3})(\\d+)', '+1 ($1) $2-$3');
    return codeNumber;
}   

/* Description: This method sets sales office details from user 
     * 
     * @param: contactList
     * @return: void
     * Modification History:
     * -------------------------------------------------------------------------------------
     *  Date              | Description
     * -------------------------------------------------------------------------------------
     *  08/05/2022          created this new method
     * 
     * 
    */
    
    public void setSalesOfficeDetails(List<Contact> newList,Map<Id, Contact> contactOldMap){
        set<Id> ownerIdSet = new set<Id>();
        for(Contact newContact: newList){
            Contact oldContact = contactOldMap != null ? contactOldMap.get(newContact.Id):null;
            if((Trigger.isInsert || newContact.OwnerId != oldContact.OwnerId) && newContact.OwnerId != null){
                ownerIdSet.add(newContact.OwnerId);
            }
            
        }
        
        if(ownerIdSet.Size() > 0){
            Map<Id,User> userIdMap = new Map<Id,User>([SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c from user WHERE Id In :ownerIdSet AND NSP_Sales_Office__c != null ]);
            for(Contact newContact: newList){
                Contact oldContact = contactOldMap != null ? contactOldMap.get(newContact.Id):null;
                if((Trigger.isInsert || newContact.OwnerId != oldContact.OwnerId) && newContact.OwnerId != null && userIdMap.containsKey(newContact.OwnerId)){
                    user eachUser = userIdMap.get(newContact.OwnerId);
                    newContact.NSP_Sales_Region__c = eachUser.NSP_SalesRegion__c;  // sales region
                    newContact.NSP_Sales_Division__c = eachUser.NSP_SalesDivision__c; // sales division
                    newContact.NSP_Sales_Office__c = eachUser.NSP_Sales_Office__c; // sales office
                }
            }
        }
    } 
    
    /* updateContactRoles function definition */
    public void updateContactRoles(Set<Id> sUserIds, List<Contact> lContacts){
        Map<Id,User> mUsers = new Map<Id,User>([SELECT Id,Profile.UserLicense.Name FROM User WHERE Id in : sUserIds]);
        for(Contact oContact : lContacts){
            if(mUsers.get(oContact.pse__Salesforce_User__c).Profile.UserLicense.Name == COMMUNITYLICENSE){
                oContact.pse__Resource_Role__c = CUSTOMERROLE;
            }
                else{
                oContact.pse__Resource_Role__c = INSPERITYROLE;
            }
        }
    }

    /**
* @MethodName: updateWorkPhoneEmailOnACR
* @Description: This method describes to update the ACR when ever Contact's Email and Work Phone.
* @param : Map<Id, Contact> conIdContactMap
* @createdDate : 12/13/2022
* @Story : STY-02840
* @return void                          
*/
    
    public void updateWorkPhoneEmailOnACR(Map<Id, Contact> conIdContactMap){
        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        List<Contact> conList = new List<Contact>();
        Set<Id> conIdSet = new Set<Id>();
        Contact cont;
        List<Profile> integrationUser = new NSP_sObjectSelector('Profile').setSecurityEnforce(false).selectByName(NSP_ServiceConstants.INTEGRATION_USER, null, true);
        try{
            for(AccountContactRelation acr : [SELECT Id, AccountId, 
                                              ContactId,
                                              Contact.NSP_isContactInsertion__c,
                                              NSP_Work_Email__c, 
                                              NSP_Work_Phone__c,
                                              IsDirect,
                                              createdById,
                                              CreatedBy.ProfileId
                                              FROM AccountContactRelation 
                                              WHERE ContactId IN: conIdContactMap.keySet() 
                                              AND isDirect = true
                                              AND CreatedBy.ProfileId !=: integrationUser[0].Id]){
                                                  conIdSet.add(acr.ContactId);
                                                  cont = conIdContactMap.get(acr.ContactId);
                                                  acr.NSP_Work_Email__c = cont.NSP_Work_email__c;
                                                  acr.NSP_Work_Phone__c = cont.NSP_Work_Phone__c;
                                                  acr.NSP_Employee_Status__c = cont.NSP_Employee_Status__c;
                                   				  acr.NSP_Status_Date__c = cont.NSP_Status_Date__c;
                                                  acr.NSP_Job_Title__c = cont.NSP_Job_Title__c;
                                                  acrList.add(acr);
                                              }
            for(Contact con : [SELECT Id, NSP_isContactInsertion__c FROM Contact WHERE Id IN: conIdSet]){
                con.NSP_isContactInsertion__c = false;
                conList.add(con);
            }
            if(!acrList.isEmpty()){
                update acrList ; // Don't chnage to Database.update
            }
            
            if(!conList.isEmpty()){
                update conList ; // Don't chnage to Database.update
            }
        }catch(exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_ContactTriggerHelper', 'updateWorkPhoneEmailOnACR', ex.getMessage());
        }
    }
    
    /**
	* Method Name : getLoggedInUserProfile 
	* Description : STY-02849/DF-05013 Method to get loggedin user profile
	* Date : 21/06/2023
	* @param   
	* @return List<Profile> 
	*/    
    public List<Profile> getLoggedInUserProfile() {
        List<String> profileFields = new List<String>{'Id','Name'};        
        String queryProfile = new NSP_QueryBuilder('Profile', profileFields)
                .addFilter('Id', UserInfo.getProfileId()).setSecurityEnforce(false).build();
        return Database.query(queryProfile);
    }
    
    /**
	* Method Name : getRegionId 
	* Description : STY-02849/DF-05013 Method to United State region id
	* Date : 21/06/2023
	* @param   
	* @return Id 
	*/
    public Id getRegionId() {
        List<String> regionFields = new List<String>{'Id','Name'};        
        String queryRegion = new NSP_QueryBuilder('pse__Region__c', regionFields)
                .addFilter('Name', NSP_ServiceConstants.UnitedStatesRegion).setSecurityEnforce(false).build();
        List<pse__Region__c> regionRecords = Database.query(queryRegion);
        if(regionRecords.size() > 0) {
            return regionRecords[0].id;
        }
        return null;
    }
    
    /**
	* Method Name : getWorkCalendarId 
	* Description : STY-02849/DF-05013 Method to work Calender US40 record id
	* Date : 21/06/2023
	* @param   
	* @return Id 
	*/
    public Id getWorkCalendarId() {
        List<String> wcFields = new List<String>{'Id','Name'};        
        String queryWC = new NSP_QueryBuilder('pse__Work_Calendar__c', wcFields)
                .addFilter('Name', WORK_CALENDAR_US40).setSecurityEnforce(false).build();
        List<pse__Work_Calendar__c> wcRecords = Database.query(queryWC);
        if(wcRecords.size() > 0) {
            return wcRecords[0].id;
        }
        return null;
    }
}