/*
    Apex class Name      :  NSP_sObjectOperationController
    Version              :  1.0
    Created Date         :  15 Jan, 2023
    Story                :  STY-03359
    Description          :  Generic class to handle search operations on sObjects.
    Created By           :  Nishkarsh Manav

*/
public with sharing class NSP_sObjectOperationController {
    private static final String DEFAULT_ICON = 'standard:account';

    /**
     * It provides search results on the basis of given search configuration.
     * @param - {String} - searchConfig
     * Possible parameters of search configuration object are
     * searchCategory - Field name that will be used in filtering records
     * searchTerm - Search Term (Contains operator will be used)
     * objectApiName - sObject name of the records
     * resultSize - count of records that should be returned
     * additionalInfoField - Additional field whose value needs to be displayed in lookup option
     * preSelectedRecs - Ids of the record which need to be excluded from search results
     * 
     */
    @AuraEnabled(cacheable=true)
    public static List<NSP_LookupOption> searchRecordsByFilters(String searchConfig){
        try {
            Map<String, Object> searchConfigMap = getSearchConfigMap(searchConfig);

            //String searchCategory = (String) searchConfigMap.get('searchCategory');
            String searchTerm = (String) searchConfigMap.get('searchTerm');
            String objectApiName = (String) searchConfigMap.get('objectApiName');
            Integer resultSize = (Integer) searchConfigMap.get('resultSize');
            String additionalInfoField = (String) searchConfigMap.get('additionalInfoField');
            List<String> preSelectedRecs = (List<String>) JSON.deserialize(searchConfigMap.get('preSelectedRecs').toString(), List<String>.class);
            List<String> fieldsToFetch = new List<String>{ 'Name' };
            List<String> additionalFields = String.isNotBlank(additionalInfoField) ? additionalInfoField.split(',') : new List<String>();

            if(!additionalFields.isEmpty()){
                fieldsToFetch.addAll(additionalFields);
            }

            NSP_sObjectSelector selector = new NSP_sObjectSelector(objectApiName, fieldsToFetch).addLimit(resultSize);
            List<SObject> filteredRecords = selector.selectByName(searchTerm, preSelectedRecs);

            return getLookupOptions(filteredRecords, 'Name', additionalFields);
        } catch (Exception excep) {
            throw NSP_Utilities.getAuraException(excep);
        }
    }

    /**
     * This method insert, update & delete the given records.
     * @param - recordsToUpsertMap - Map of object name (key) & records (value) that need to be inserted or updated
     * @param - recordsToDeleteMap - Map of object name (key) & records (value) that need to be deleted
     * 
     */
    @AuraEnabled
    public static void upsertAndDeleteRecords(Map<String, List<String>> recordsToUpsertMap, Map<String, List<String>> recordsToDeleteMap){
        try {
            if(!recordsToUpsertMap.isEmpty()){
                List<SObject> recordsToUpsert = getSobjectRecords(recordsToUpsertMap);

                if(!recordsToUpsert.isEmpty()){
                    upsert recordsToUpsert;
                }
            }

            if(!recordsToDeleteMap.isEmpty()){
                List<SObject> recordsToDelete = getSobjectRecords(recordsToDeleteMap);

                if(!recordsToDelete.isEmpty()){
                    delete recordsToDelete;
                }
            }
         } catch (Exception excep) {
             throw NSP_Utilities.getAuraException(excep);
        }
    }

    private static List<SObject> getSobjectRecords(Map<String, List<String>> recordsMap){
        List<SObject> recordsList = new List<SObject>();

        for (String objectApiName : recordsMap.keySet()) {
            recordsList.addAll(getSobjectRecords(recordsMap.get(objectApiName), objectApiName));
        }

        return recordsList;
    }

    private static List<SObject> getSobjectRecords(List<String> records, String sObjectName){
        List<SObject> sObjects = new List<SObject>();
        for(String rec : records){
            SObject sObj = (SObject) JSON.deserialize(rec, Type.forName(sObjectName));
            sObjects.add(sObj);
        }

        return sObjects;
    }

    private static Map<String, Object> getSearchConfigMap(String searchConfig){
        return (Map<String, Object>) JSON.deserializeUntyped(searchConfig);
    }

    // This method converts list of records into list of lookup options.
    private static List<NSP_LookupOption> getLookupOptions(List<SObject> filteredRecords, String primaryInfoField, List<String> additionalInfoFields){
        List<NSP_LookupOption> lookupOptions = new List<NSP_LookupOption>();
        String info = null;
        for (SObject rec : filteredRecords) {
            String optionLabel = String.valueOf(rec.get(primaryInfoField));
            if(!additionalInfoFields.isEmpty()){
                Map <String, String> additionalFieldValues = new Map <String, String>();
                for (String fieldName : additionalInfoFields) {
                    if(fieldName.contains('.')){
                        List<String> relationshipField = fieldName.split('[.]');
                        SObject objVal = rec.getSObject(relationshipField[0]);

                        additionalFieldValues.put(fieldName, String.valueOf(objVal.get(relationshipField[1])));
                    }else{
                        additionalFieldValues.put(fieldName, String.valueOf(rec.get(fieldName)));
                    }
                }
                info = JSON.serialize(additionalFieldValues);
            }

            lookupOptions.add(new NSP_LookupOption(optionLabel, rec.Id, info, DEFAULT_ICON, false));
        }

        return lookupOptions;
    }
}