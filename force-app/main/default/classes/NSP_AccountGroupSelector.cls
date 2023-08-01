/**
 * @description       : Filter Account Groups when Creating a new Account Group Member
 * @author            : Anil
 * @group             : 
 * @last modified on  : 02-09-2023
 * @last modified by  : Anil
**/
public with sharing class NSP_AccountGroupSelector {

    /**
    * @description - Returns list of account group members on the basis of the given search configuration.
    * @author Anil | 02-09-2023
    * @param searchConfig
    * @return List<NSP_Account_Group_Member__c>
    **/
    @AuraEnabled(cacheable=true)
    public static List<NSP_Account_Group_Member__c> searchRecordsByFilters(String searchConfig){
        try {
            Map<String, Object> searchConfigMap = getSearchConfigMap(searchConfig);

            String groupType = (String) searchConfigMap.get('groupType');
            String account = (String) searchConfigMap.get('account');
            String aimsClient = (String) searchConfigMap.get('aimsClient');

            return getFilteredRecords(groupType, account, aimsClient);
        } catch (Exception excep) {
            throw NSP_Utilities.getAuraException(excep);
        }
    }

    /**
    * @description 
    * @author Anil | 02-09-2023 
    * @param searchConfig 
    * @return Map<String, Object> 
    **/
    private static Map<String, Object> getSearchConfigMap(String searchConfig){
        return (Map<String, Object>) JSON.deserializeUntyped(searchConfig);
    }

    /**
    * @description 
    * @author Anil | 02-09-2023 
    * @param groupType 
    * @param account 
    * @param aimsClient 
    * @return List<NSP_Account_Group_Member__c> 
    **/
    private static List<NSP_Account_Group_Member__c> getFilteredRecords(String groupType, String account, String aimsClient){
        Integer resultSize = 10;
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder('NSP_Account_Group_Member__c', new List<String>{'Id', 'Name', 'NSP_Group__c', 'NSP_Group__r.Name', 'NSP_Group__r.NSP_Type__c', 'NSP_Member_Account__c', 'NSP_Member_Account__r.Name', 'NSP_AIMS_Client_ID__c' });
        queryBuilder.addContainsFilter('NSP_Group__r.NSP_Type__c', groupType);
        if(account != null){
            queryBuilder.addContainsFilter('NSP_Member_Account__r.Name', account);
        }
        if(aimsClient != null){
            queryBuilder.addContainsFilter('NSP_AIMS_Client_ID__c', aimsClient);
        }
        queryBuilder.addLimit(resultSize);
        return (List<NSP_Account_Group_Member__c>) Database.query(queryBuilder.build());
    }
}