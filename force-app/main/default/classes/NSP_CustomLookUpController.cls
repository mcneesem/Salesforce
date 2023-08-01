/**************************************************************************************************   
Version              :  1.0                                                                          
Created Date         :  November 14, 2022                                                             
Function             :  Represents the NSP_CustomLookUpController which handles all the logic that is related to Multiple Contacts on Case.
Test class           :  NSP_CustomLookUpControllerTest
Story                :  STY-02660                                                                      
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* -------------------------------------------------------------------------------------------------  
***************************************************************************************************/
public with sharing class NSP_CustomLookUpController {
    private static Set<Id> accIdSet;
    private static Set<Id> conIdSet; // DF-02822
    private static List<String> serviceProfile;
    private static Set<Id> quedIdSet;
    private static List<String> ID_NAME_FIELDS = new List<String>{'Id','Name'};
    private static List<String> ID_ACCOUNTID_FIELDS = new List<String>{'Id','AccountId'};

    /**
    * @MethodName: fetchLookupData
    * @Description: This method describes to fetch the data when it is placed on Flow and Case Form based on Search and Parent Account or Contact Id.
    * @param : string searchKey , string sObjectApiName, String accId, String parentId
    * @createdDate : 11/14/2022
    * @Story : STY-02660
    * @return void                          
    */
            @AuraEnabled(cacheable=true)
            public static list<sObject> fetchLookupData(string searchKey , string sObjectApiName, String accId, String parentId) {    
                List < sObject > returnList = new List < sObject > ();
                string sQuery;
                string sWildCardText = String.isNotBlank(searchKey) ? '%' + String.escapeSingleQuotes(searchKey) + '%' : '%' + searchKey + '%';
                String parentAccountId = parentId != NSP_ServiceConstants.EMPTY_STRING ? parentId : accId; 
                try{
                sQuery =  sObjectApiName == NSP_ServiceConstants.ACCOUNT_OBJECT ?
                    queryForAccountLookup(parentId, sObjectApiName, sWildCardText)
                    : sObjectApiName == NSP_ServiceConstants.CONTACT_OBJECT ? 
                        queryForContactLookup(parentId, sObjectApiName, sWildCardText, accId, parentAccountId)
                        : sObjectApiName == NSP_ServiceConstants.ASSET_SOBJECT_TYPE ?
                            frameFetchLookUpDataQuery(searchKey, sObjectApiName, parentAccountId)
                                : sObjectApiName == NSP_ServiceConstants.PSE_MILESTONE ?
                                    frameFetchLookUpDataQuery(searchKey, sObjectApiName, parentAccountId)
                                         : queryForUserOrGroupLookup(sObjectApiName, sWildCardText);
                
                if(String.isNotBlank(sQuery)){
                    for (sObject obj: database.query(sQuery)) {
                        returnList.add(obj);
                    }
                }
                return returnList;
                }catch (Exception ex) {
            throw NSP_Utilities.getAuraException(ex);
        }
            }
    
    /**
    * @MethodName: queryForAccountLookup
    * @Description: This method describes to fetch the Records of Account.
    * @param : string parentId , string sObjectApiName, String sWildCardText
    * @createdDate : 11/24/2022
    * @Story : STY-02660
    * @return void                          
    */
    private static string queryForAccountLookup(string parentId, String sObjectApiName, String sWildCardText) {
        string accQuery = '';
        accIdSet = new Set<Id>();
        if(String.isNotBlank(parentId) && parentId.substring(0, 3) == '003'){
            for(AccountContactRelation acr : [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE ContactId =: parentId]){
                accIdSet.add(acr.AccountId); 
            }
            accQuery = 'Select Id,Name From ' + sObjectApiName + ' Where Name Like : sWildCardText AND ID IN: accIdSet order by createdDate DESC LIMIT 1000';
        }else{
            accQuery = frameFetchLookUpDataQuery(sWildCardText, sObjectApiName, NSP_ServiceConstants.EMPTY_STRING);
        }
        return accQuery;
    }
    
    /**
    * @MethodName: queryForContactLookup
    * @Description: This method describes to fetch the Records of Contact.
    * @param : string parentId , string sObjectApiName, String sWildCardText,  String accId, String parentAccountId
    * @createdDate : 11/24/2022
    * @Story : STY-02660
    * @return void                          
    */
    private static string queryForContactLookup(string parentId, String sObjectApiName, String sWildCardText, String accId, String parentAccountId) {
        string conQuery = '';
        conIdSet = new Set<Id>();
        if (String.isNotBlank(accId) || String.isNotBlank(parentId)){
            for(AccountContactRelation acr : [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE AccountId =: parentAccountId]){
                conIdSet.add(acr.ContactId); 
            }
            conQuery = 'Select Id,Name From ' + sObjectApiName + ' Where Name Like : sWildCardText AND ID IN: conIdSet order by createdDate DESC LIMIT 1000';
        }else{
            conQuery = frameFetchLookUpDataQuery(sWildCardText, sObjectApiName, NSP_ServiceConstants.EMPTY_STRING);
        }
        return conQuery;
    }
    
    /**
    * @MethodName: queryForUserOrGroupLookup
    * @Description: This method describes to fetch the Records of User or Group.
    * @param : string sObjectApiName, String sWildCardText
    * @createdDate : 11/24/2022
    * @Story : STY-02660
    * @return void                          
    */
    private static string queryForUserOrGroupLookup(String sObjectApiName, String sWildCardText) {
        string userOrGrpQuery = '';
        if(sObjectApiName == NSP_ServiceConstants.USER_OBJECT){
            serviceProfile = system.label.NSP_Service_Profiles.split(',');
            serviceProfile.add(NSP_ServiceConstants.SYSTEM_ADMINISTRATOR);
            userOrGrpQuery = 'Select Id,Name From ' + sObjectApiName + ' Where Name Like : sWildCardText AND Profile.Name IN: serviceProfile  AND IsActive = true order by createdDate DESC LIMIT 1000';
        }else if(sObjectApiName == NSP_ServiceConstants.TYPE_GROUP){
             quedIdSet = new Set<Id>();
            for(QueueSobject qObj : [ SELECT QueueId, Queue.Name FROM QueueSobject WHERE SobjectType = 'Case']){
                quedIdSet.add(qObj.QueueId);
            }
            userOrGrpQuery = 'Select Id,Name From ' + sObjectApiName + ' Where Name Like : sWildCardText AND Type = \'Queue\' AND Id IN: quedIdSet order by createdDate DESC LIMIT 1000';
        }
        return userOrGrpQuery;
    }    
    /**
    * @MethodName: fetchDefaultRecord
    * @Description: This method describes to fetch the default Record of Contact Or Account.
    * @param : string searchKey , string sObjectApiName, String parentId
    * @createdDate : 11/14/2022
    * @Story : STY-02660
    * @return void                          
    */
    @AuraEnabled
    public static sObject fetchDefaultRecord(string recordId, String sObjectApiName, String parentId) {
        String getParentId = recordId != null ? recordId : parentId;
        string sQuery;
        try{
        sQuery = sObjectApiName == NSP_ServiceConstants.ACCOUNT_OBJECT ? queryForDefaultAccount(parentId, sObjectApiName, getParentId) : 
        (sObjectApiName ==  NSP_ServiceConstants.ASSET_SOBJECT_TYPE && parentId != null) ? queryForDefaultAccount(parentId, sObjectApiName, getParentId) :
        frameDefaultQuery(sObjectApiName, getParentId, ID_NAME_FIELDS);
        if(String.isNotBlank(sQuery)){
            for (sObject obj: database.query(sQuery)) {
                return obj;
            }
        }
        return null;
        }catch(Exception Ex){
                throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /**
    * @MethodName: queryForAccount
    * @Description: This method describes to fetch the query of default record related to Account.
    * @param : string searchKey , string sObjectApiName, String parentId
    * @createdDate : 11/14/2022
    * @Story : STY-02660
    * @return void                          
    */
    private static string queryForDefaultAccount(string parentId, String sObjectApiName, String getParentId) {
        string accQuery = '';
        if(String.isNotBlank(parentId)){ 
            String getAccountId = parentId.substring(0, 3) == '003' ?  fetchDefaultAccountForContact(NSP_ServiceConstants.CONTACT_OBJECT, parentId) :
            parentId.substring(0, 3) == '02i' ? fetchDefaultAccountForAsset(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, parentId) : '';
            accQuery = (String.isBlank(getAccountId) && sObjectApiName == NSP_ServiceConstants.ACCOUNT_OBJECT) ? 
                			frameDefaultQuery(sObjectApiName, parentId, ID_NAME_FIELDS) : 
            				frameDefaultQuery(sObjectApiName, getaccountId, ID_NAME_FIELDS);                   
        }else{
            accQuery = frameDefaultQuery(sObjectApiName, getParentId, ID_NAME_FIELDS);  
        }
        return accQuery;
    }
    
    /**
    * @MethodName: fetchDefaultAccountForContact
    * @Description: This method describes to fetch the query of Account related to Contact.
    * @param : string childRecordId
    * @createdDate : 3/4/2023
    * @Story : DF-02535
    * @return void                          
    */
    private static string fetchDefaultAccountForContact(String sObjectApiName, String childRecordId){
        string accountId = '';
        string accQuery = frameDefaultQuery('Contact', childRecordId, ID_ACCOUNTID_FIELDS);
        if(String.isNotBlank(accQuery)){
            List<sObject> queryContact = database.query(accQuery);
            List<Contact> conList = (List<contact>) queryContact;
            return conList[0].AccountId;
        }
        return accountId;
        
    }
    
    /**
    * @MethodName: fetchDefaultAccountForAsset
    * @Description: This method describes to fetch the query of Account related to Asset.
    * @param : string childRecordId
    * @createdDate : 3/4/2023
    * @Story : DF-02535
    * @return void                          
    */
    private static string fetchDefaultAccountForAsset(String sObjectApiName, String childRecordId){
        string accountId = '';
        string accQuery = frameDefaultQuery('Asset', childRecordId, ID_ACCOUNTID_FIELDS);
        if(String.isNotBlank(accQuery)){
            List<sObject> queryContact = database.query(accQuery);
            List<Asset> assetList = (List<Asset>) queryContact;
            return assetList[0].AccountId;
        }
        return accountId;
        
    }
    
    /**
    * @MethodName: frameDefaultQuery
    * @Description: This method is used to frame the default query based on the object and parentId
    * @param : string searchKey , string sObjectApiName, String idToSearch
    * @createdDate : 11/14/2022
    * @Story : STY-02660
    * @return void                          
    */
    private static string frameDefaultQuery(string sObjectApiName, String idToSearch, List<String> FIELDS){
        Integer recordSize = 1;
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder(sObjectApiName, FIELDS); 
        queryBuilder.addFilter('Id', idToSearch , NSP_QueryBuilder.Operator.EQUALS); 
        queryBuilder.addLimit(recordSize);
        String query = queryBuilder.build(); 
        return query;
    }
    
    /**
    * @MethodName: frameFetchLookUpDataQuery
    * @Description: This method is used to frame the query based on the object and parentId
    * @param : string searchKey , string sObjectApiName, String parentId, Set<id> setOfIds
    * @createdDate : 11/14/2022
    * @Story : STY-02660
    * @return void                          
    */
    private static string frameFetchLookUpDataQuery(String searchKey, string sObjectApiName, String parentId ){
        List<String> FIELDS = new List<String>{'Id','Name'};
            Integer recordSize = 1000;
            NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder(sObjectApiName, FIELDS);
        queryBuilder.addContainsFilter('Name', searchKey);
        if((sObjectApiName ==  NSP_ServiceConstants.CONTACT_OBJECT || sObjectApiName ==  NSP_ServiceConstants.ASSET_SOBJECT_TYPE)
           && String.isNotBlank(parentId)){
               queryBuilder.addFilter('AccountId', parentId);
           }else if(sObjectApiName ==  NSP_ServiceConstants.PSE_MILESTONE ){
            queryBuilder.addFilter('pse__Project__c', parentId);
           }
        queryBuilder.orderBy('createdDate', 'DESC', false);
        queryBuilder.addLimit(recordSize);
        String query = queryBuilder.build();
        return query;
    }
    
}