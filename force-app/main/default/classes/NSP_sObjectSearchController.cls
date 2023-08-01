/*
    Apex class Name      :  NSP_sObjectSearchController
    Version              :  1.0
    Created Date         :  15 Jan, 2023
    Story                :  STY-03359
    Description          :  Generic class to handle search operations on sObjects.
    Created By           :  Nishkarsh Manav
*/
public with sharing class NSP_sObjectSearchController {
    private static final String DEFAULT_ICON = 'standard:account';

    @AuraEnabled
    public static List<NSP_LookupOption> searchRecordsByFilters(String searchConfig){
        try {
            Map<String, Object> searchConfigMap = getSearchConfigMap(searchConfig);
            // initializing details
            String searchTerm = (String) searchConfigMap.get('searchTerm');
            String objectApiName = (String) searchConfigMap.get('objectApiName');
            Integer resultSize = (Integer) searchConfigMap.get('resultSize');
            List<String> preSelectedRecs = (List<String>) JSON.deserialize(searchConfigMap.get('preSelectedRecs').toString(), List<String>.class);

            NSP_sObjectSelector selector = new NSP_sObjectSelector(objectApiName).addLimit(resultSize);
            List<SObject> filteredRecords = selector.selectByName(searchTerm, preSelectedRecs);

            return getLookupOptions(filteredRecords);
        } catch (Exception ex) {
            throw NSP_Utilities.getAuraException(ex);
        }
    }

    private static Map<String, Object> getSearchConfigMap(String searchConfig){
        return (Map<String, Object>) JSON.deserializeUntyped(searchConfig);
    }

    private static List<NSP_LookupOption> getLookupOptions(List<SObject> filteredRecords){
        //call to constructor to get lookup options
        List<NSP_LookupOption> lookupOptions = new List<NSP_LookupOption>();
        for (SObject rec : filteredRecords) {
            lookupOptions.add(new NSP_LookupOption(String.valueOf(rec.get('Name')), rec.Id, null, DEFAULT_ICON, false));
        }

        return lookupOptions;
    }
}