public with sharing class NSP_IPSelector {
    private static final String ACCOUNT_ICON = 'standard:account';
    private static final String IP_OBJECT_API_NAME = 'Implementation_Profile__c';
    private static final String ID_FIELD = 'Id';
    private static final String META_INFO_SEPARATOR = ' - ';

    private static final List<String> DEFAULT_FIELD_LIST = new List<String>{ 'Id', 'Name', 'Account__r.Name', 'NSP_AIMS_ClientNo__c', 'RecordTypeId' };

    @AuraEnabled
    public static List<NSP_LookupOption> searchRecordsByFilters(String searchConfig){
        try {
            Map<String, Object> searchConfigMap = getSearchConfigMap(searchConfig);

            String searchCategory = (String) searchConfigMap.get('searchCategory');
            String searchTerm = (String) searchConfigMap.get('searchTerm');
            String recordTypeId = (String) searchConfigMap.get('recordTypeId');
            List<String> preSelectedRecs = (List<String>) JSON.deserialize(searchConfigMap.get('preSelectedRecs').toString(), List<String>.class);

            List<Implementation_Profile__c> ipList = getActiveFilteredRecords(searchCategory, searchTerm, preSelectedRecs);

            return getLookupOptions(ipList, recordTypeId);
        } catch (Exception excep) {
            throw NSP_Utilities.getAuraException(excep);
        }
    }

    public static Implementation_Profile__c getRecordById(String recId, List<String> fields){
        try {
            if(String.isBlank(recId)){
                return null;
            }

            List<String> fieldList = fields != null && !fields.isEmpty() ? fields : DEFAULT_FIELD_LIST;
            NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder(IP_OBJECT_API_NAME, fieldList);
            String query = queryBuilder.addFilter(ID_FIELD, recId).addLimit(1).build();
            List<Implementation_Profile__c> results = (List<Implementation_Profile__c>) Database.query(query);

            return results.isEmpty() ? null : results[0];
        } catch (Exception excep) {
            throw NSP_Utilities.getAuraException(excep);
        }
    }

    private static Map<String, Object> getSearchConfigMap(String searchConfig){
        return (Map<String, Object>) JSON.deserializeUntyped(searchConfig);
    }

    private static List<NSP_LookupOption> getLookupOptions(List<Implementation_Profile__c> ipList, String recordTypeId){
        List<NSP_LookupOption> lookupOptions = new List<NSP_LookupOption>();
        for (Implementation_Profile__c ip : ipList) {
            String info = ip.Account__r.Name;
            if(String.isNotBlank(ip.NSP_AIMS_ClientNo__c)){
                info += META_INFO_SEPARATOR + ip.NSP_AIMS_ClientNo__c;
            }

            Boolean isDisabled = ip.RecordTypeId != recordTypeId;
            lookupOptions.add(new NSP_LookupOption(ip.Name, ip.Id, info, ACCOUNT_ICON, isDisabled));
        }

        return lookupOptions;
    }

    private static List<Implementation_Profile__c> getActiveFilteredRecords(String fieldName, String fieldValue, List<String> preSelectedRecs){
        Integer resultSize = 10;
        String inactiveFieldName = 'NSP_Inactive__c';
        Boolean isInactiveFieldValue = false;

        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder(IP_OBJECT_API_NAME, DEFAULT_FIELD_LIST);
        queryBuilder.addContainsFilter(fieldName, fieldValue)
        .addFilter(inactiveFieldName, isInactiveFieldValue)
        .addLimit(resultSize).build();

        if(!preSelectedRecs.isEmpty()){
            queryBuilder.addFilter(ID_FIELD, preSelectedRecs, NSP_QueryBuilder.Operator.NOT_IN);
        }

        return (List<Implementation_Profile__c>) Database.query(queryBuilder.build());
    }
}