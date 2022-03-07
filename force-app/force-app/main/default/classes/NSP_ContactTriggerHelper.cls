/* 
*    ClassName:NSP_ContactTriggerHelper
*    @description: Represents the Contact trigger helper which handles all the logic.
*    @date: 06/07/2021
*    @author: Tejas
*/

public class NSP_ContactTriggerHelper {
    
    
    /**
* Iterates throught the list of new Contact and passes the required attributes to other methods.
* @param newList List of New Contact.
* @param newMap List of New Contact.
* @return void
*                
*/
    
    public void beforeInsertDirector(List<Contact> newList) {
        
        for(Contact conObj : newList){
            if(conObj.NSP_Client_Reference__c){
                conObj.NSP_Client_Reference_Task_Date__c = system.today();
            }
            if(conObj.Phone != null){
                updatePhoneNumber(newList);
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
    
    public void afterInsertDirector(List<Contact> newList, Map<Id, Contact> newMap) {
        Set<Id> accountIdSet = new Set<Id>();
        List<Contact> clientRefernceContactList = new List<Contact>();
        for(Contact conObj : newList){
            if(conObj.NSP_Client_Reference__c){
                clientRefernceContactList.add(conObj);
            }
            if(conObj.NSP_IsPrimary__c){
                accountIdSet.add(conObj.AccountId);
            }
        }
        
        if(accountIdSet.size() > 0){
            List<Account> accountList = new List<Account>();
            for(ID accountId : accountIdSet){
                Account accountObj = new Account();
                accountObj.Id = accountId;
                accountObj.NSP_Ready_for_Integration_Sync__c = true;
                accountList.add(accountObj);
            }
            
            if(accountList.size() > 0){
                update accountList;
            }
        }
        
        if(clientRefernceContactList.size() > 0){
            createTaskforClientReference(clientRefernceContactList);
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
        
        for(Contact conObj : newMap.values()){
            if(conObj.NSP_Client_Reference__c != oldMap.get(conObj.Id).NSP_Client_Reference__c 
               && conObj.NSP_Client_Reference__c){
                   conObj.NSP_Client_Reference_Task_Date__c = system.today();
               }
               updatePhoneNum(newMap.Values(),oldMap);
        }
        
        //for integration
        Set<Id> accountIdSetToUpdateResyncFLag = new Set<Id>();
        NSP_SObjectUpdateTriggerHelper sObjectUpdateObj = new NSP_SObjectUpdateTriggerHelper();
        accountIdSetToUpdateResyncFLag = sObjectUpdateObj.fetchUpdFieldsLst(NSP_IntegrationConstants.SOBJECT_CONTACT, newMap, oldMap);
        
        if(accountIdSetToUpdateResyncFLag.size() > 0){
            List<Account> accountList = new List<Account>();
            for(Id accountId : accountIdSetToUpdateResyncFLag){
                Account accountObj = new Account();
                accountObj.Id = accountId;
                accountObj.NSP_Ready_for_Integration_Sync__c = true;
                accountList.add(accountObj);
            }
            if(accountList.size() > 0){
                update accountList; 
            }
            
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
* Iterates throught the list of new Contact and passes the required attributes to other methods.
* @param newList List of New Contact.
* @param newMap List of New Contact.
* @return void
*                
*/
    
    public void afterUpdateDirector(Map<Id, Contact> newMap,Map<Id, Contact> oldMap) {
        try{
            List<Contact> clientRefernceContactList = new List<Contact>();
            Map<Id,Contact> contactOldMap = new Map<Id,Contact>();
            Map<Id,Contact> contactNewMap = new Map<Id,Contact>();
            Set<Id> accountIdSet = new Set<Id>();
            
            for(Contact conObj : newMap.values()){
                if(conObj.NSP_Client_Reference__c != oldMap.get(conObj.Id).NSP_Client_Reference__c 
                   && conObj.NSP_Client_Reference__c){
                       clientRefernceContactList.add(conObj);
                   }
                
                if(conObj.NSP_IsPrimary__c){
                    accountIdSet.add(conObj.AccountId);
                    contactOldMap.put(conObj.Id,oldMap.get(conObj.Id));
                    contactNewMap.put(conObj.Id,newMap.get(conObj.Id));
                }
            }
            
            if(clientRefernceContactList.size() > 0){
                createTaskforClientReference(clientRefernceContactList);
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
        Pattern nonAlphanumeric = Pattern.compile('[^a-zA-Z0-9]');
        String initialNum = nonAlphanumeric.matcher(contact.Phone).replaceAll('').replace('ext','x');
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
            String initialNum = nonAlphanumeric.matcher(newContact.Phone).replaceAll('').replace('ext','x');
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
    if(trimString.contains('ext')) {
        parts = trimString.split('ext');
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
}