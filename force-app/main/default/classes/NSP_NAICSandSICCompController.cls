 /**
Apex Class Name      :  NSP_NAICSandSICCompController for NSP_NAICSandSICComp
Version              :  1.0                                                                          
Created Date         :  12/24/2021   
Function             :  This class is used as a controller for SIC/NAICS screen to display current field values 
and to update the field values with new values selected from the screen
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Tejas                 12/24/2021            First Iteration
*/
 
public without sharing class NSP_NAICSandSICCompController {
    
    Public Static Final String NAME='Name';
    Public Static Final String NAICS='Naics';
    Public Static Final String NAICSDESC='NaicsDesc';
    Public Static Final String SIC='Sic';
    Public Static Final String SICDESC='SicDesc';
    Public Static Final String ERROR='Error';
    Public Static Final String SUCCESS='Success';
    Public Static Final String ERROCCURED=' Error occured: ';
/**
 * Represents the getAccountRecord to get Account record based on record id
 * Created by : Tejas
 * Date : 24/12/2021
 */
@AuraEnabled(cacheable=true)
public static Account getAccountRecord(string accountId){
    Account accountRecord = new Account();
    try {
        String acntId = String.escapeSingleQuotes(accountId);
        accountRecord = [SELECT Id, Name, NSP_NAICS__c, NSP_NaicsDesc__c, Sic, SicDesc FROM Account WHERE Id =:acntId];
    } catch (Exception ex) {
        throw new AuraHandledException(ERROCCURED +ex.getMessage());
    }

    return accountRecord;
}

/**
 * Represents the NAICS on Account record based on record id
 * Created by : Tejas
 * Date : 24/12/2021
 */
@AuraEnabled
public static Account updateAccount(Account accountRecord){
    try {
        update accountRecord;
    } catch (Exception ex) {
        throw new AuraHandledException(ex.getMessage());
    }

    return accountRecord;
}

/**
 * Description: this method takes in the recordId as a parameter
 * and identifies to which object this record belongs to 
 * and queries for the set of fields for that record and returns it 
 * to the lwc component
 * 
 * Params: @recordId
 * return: sObject record
 */
@AuraEnabled(cacheable=true)
public static ResponseWrapper getRecordDetails(Id recordId){
    String sObjectName = recordId.getSObjectType().getDescribe().getName();
    String query = getQuery(sObjectName, recordId);
    
    
    ResponseWrapper responseWrapper = new ResponseWrapper();
    Map<String, String> fieldValueMap = new Map<String, String>();
    sObject sObjectRecord;
    try {
        sObjectRecord = Database.query(query);
        responseWrapper.status = SUCCESS;
        fieldValueMap.put('Id', sObjectRecord.Id);       
        if(sObjectName == 'Account'){
            Account acc = (Account) sObjectRecord;
            fieldValueMap.put(NAME, acc.Name);
            fieldValueMap.put(NAICS, acc.NSP_NAICS__c);
            fieldValueMap.put(NAICSDESC, acc.NSP_NaicsDesc__c);
            fieldValueMap.put(SIC, acc.Sic);
            fieldValueMap.put(SICDESC, acc.SicDesc);
        }else{
            Lead lead = (Lead) sObjectRecord;
            fieldValueMap.put(NAME, lead.Name);
            fieldValueMap.put(NAICS, lead.NSP_NAICS__c);
            fieldValueMap.put(NAICSDESC, lead.NSP_NaicsDesc__c);
            fieldValueMap.put(SIC, lead.NSP_SIC__c);
            fieldValueMap.put(SICDESC, lead.NSP_SicDesc__c);
        }
        responseWrapper.sObjectName = sObjectName;
        responseWrapper.recordMap = fieldValueMap;

    } catch (Exception ex) {
        responseWrapper.status = ERROR;
        throw new AuraHandledException(System.label.NSP_Error_Message+ex.getMessage());
    }

    return responseWrapper;
}

/**
 * This method takes in the sObject name as a parameter
 * and constructs the query and returns it
 * Params: string: sObjectName
 * return: string: SOQL string
 * 
 */
public static string getQuery(string sObjectName, Id recordId){
    String querySelect = 'SELECT Id, Name, ';
    String queryFrom;
    String queryWhere = ' WHERE Id = \''+recordId+'\' ';
    String finalQuery;

    if(sObjectName=='Account'){
        querySelect += ' NSP_NAICS__c, NSP_NaicsDesc__c, Sic, SicDesc ';            
    }else if(sObjectName == 'Lead'){
        querySelect += ' NSP_NAICS__c, NSP_NaicsDesc__c, NSP_SIC__c, NSP_SicDesc__c ';
    }

    queryFrom = ' FROM '+sObjectName+' ';

    finalQuery = querySelect+queryFrom+queryWhere;

    return finalQuery;
}

 @AuraEnabled
 public static sObject saveRecord(Map<String, String> recordMap, string objectApiName){
    sObject sObjectRecord;
    if(objectApiName=='Account'){
        Account acc = new Account(Id=recordMap.get('Id'));            
        acc.Sic = recordMap.get(SIC);
        acc.SicDesc = recordMap.get(SICDESC);
        acc.NSP_NAICS__c = recordMap.get(NAICS);
        acc.NSP_NaicsDesc__c = recordMap.get(NAICSDESC);

        sObjectRecord = acc;
    }else if(objectApiName=='Lead'){
        Lead lead = new Lead(Id=recordMap.get('Id'));
        lead.NSP_Sic__c = recordMap.get(SIC);
        lead.NSP_SicDesc__c = recordMap.get(SICDESC);
        lead.NSP_NAICS__c = recordMap.get(NAICS);
        lead.NSP_NaicsDesc__c = recordMap.get(NAICSDESC);

        sObjectRecord = lead;
    }
     try {
         update sObjectRecord;
     } catch (Exception ex) {
         throw new AuraHandledException(ex.getMessage());
     }

     return sObjectRecord;
 }

 /*
  * This wrapper class used to maintain a map of field names vs field values
  * which will be used in the lwc component
  * and status if the operation is successfull or error
*/
 public class ResponseWrapper{
    @AuraEnabled
    public String sObjectName;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public Map<String, String> recordMap;   //this map contains SIC/NAICS field details     

 }
}