/* Name: NSP_SingleRelatedListController 
   Purpose: Controller class for NSP_SingleRelatedList
   Author: Hemali Patel
   Create Date: 2021-10-12
   Modify History:
   2021-10-12  Hemali Patel	Created
*/
public without sharing class NSP_SingleRelatedListController {
    public static final String FIELDS_PARAM = 'fields';
    public static final String NUMBER_OF_RECORDS_PARAM = 'numberOfRecords';
    public static final String RECORD_ID_PARAM = 'recordId';
    public static final String SOBJECT_API_NAME_PARAM = 'sobjectApiName';
    public static final String SOBJECT_LABEL_PARAM = 'sobjectLabel';
    public static final String SOBJECT_LABEL_PLURAL_PARAM = 'sobjectLabelPlural';
    public static final String PARENT_RELATIONSHIP_API_NAME_PARAM = 'parentRelationshipApiName';
    public static final String RELATED_FIELD_API_NAME_PARAM = 'relatedFieldApiName';
    public static final String SORTED_DIRECTION_PARAM = 'sortedDirection';
    public static final String SORTED_BY_PARAM = 'sortedBy';
    public static final String RECORDS_PARAM = 'records';
    public static final String ICON_NAME_PARAM = 'iconName';
    public static final String PAGE_NUMBER_PARAM = 'pageNumber';
    private static final String ErrorOccured = 'Error Occured ';
    /****************************************************************************************
     * Method Name : initData
     * Params: String jsonData
     * **************************************************************************************/    
    @AuraEnabled(cacheable=true)
    public static String initData(String jsonData){
        try{
            Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);  
            Map<String, Object> responseMap = new Map<String, Object>();
            responseMap.put(RECORDS_PARAM, getRecords(jsonData));
            
            String sobjectApiName = (String)requestMap.get(SOBJECT_API_NAME_PARAM);
            responseMap.put(ICON_NAME_PARAM, getIconName(sobjectApiName));
            String recordId = (String)requestMap.get(RECORD_ID_PARAM);
            String relatedFieldApiName = (String)requestMap.get(RELATED_FIELD_API_NAME_PARAM);
            responseMap.put(PARENT_RELATIONSHIP_API_NAME_PARAM, getParentRelationshipName(recordId, sobjectApiName, relatedFieldApiName));
            
            Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(sobjectApiName);
            Schema.DescribeSObjectResult sobjectDescribe = sobjectType.getDescribe();
            responseMap.put(SOBJECT_LABEL_PARAM, sobjectDescribe.getLabel());
            responseMap.put(SOBJECT_LABEL_PLURAL_PARAM, sobjectDescribe.getLabelPlural());
            return JSON.serialize(responseMap);
        }
        catch (Exception ex) {
			throw new AuraHandledException(ErrorOccured + ex.getMessage());
        }
    }

    /****************************************************************************************
     * Method Name : getRecords
     * Params: String jsonData
     * **************************************************************************************/  
	@AuraEnabled
    public static List<Sobject> getRecords(String jsonData){
		try{
            Map<String, Object> root = (Map<String, Object>)JSON.deserializeUntyped(jsonData);  
            String fields = (String)root.get(FIELDS_PARAM);
            Integer numberOfRecords = (Integer)root.get(NUMBER_OF_RECORDS_PARAM);
            Id recordId = (Id)root.get(RECORD_ID_PARAM);
            String relatedFieldApiName = (String)root.get(RELATED_FIELD_API_NAME_PARAM);
            String sobjectApiName = (String)root.get(SOBJECT_API_NAME_PARAM);        
            String orderBy = (String)root.get(SORTED_BY_PARAM) + ' ' + (String)root.get(SORTED_DIRECTION_PARAM);        
            Integer pageNumber = (Integer)root.get(PAGE_NUMBER_PARAM);
            String query = 'Select '+fields+' From '+sobjectApiName +' WHERE ' +relatedFieldApiName+ '= :recordId';
            if(recordId.getSobjectType() == Schema.Implementation_Profile__c.SObjectType && pageNumber != null){
                query += ' AND NSP_Index__c < :pageNumber';
            }
            query += ' Limit :numberOfRecords';
            List<SObject> queryReults = Database.query(String.escapeSingleQuotes(query));
            return recordId.getSobjectType() == Schema.Implementation_Profile__c.SObjectType ? queryReults : NSP_HistoryTrackingVisibilityHandler.getAccessibleFieldList(queryReults,(Id)recordId);
        } catch (Exception ex) {
			throw new AuraHandledException(ErrorOccured + ex.getMessage());
        }
	}

    /****************************************************************************************
     * Method Name : getParentRelationshipName
     * Params: Id recordId, String childSobjectApiName, String relatedFieldApiName
     * **************************************************************************************/   
    private static String getParentRelationshipName(Id recordId, String childSobjectApiName, String relatedFieldApiName){
        Schema.DescribeSObjectResult descrRes = recordId.getSObjectType().getDescribe();
        String name;
        for (Schema.ChildRelationship cr: descrRes.getChildRelationships()){ 
            if(cr.getChildSObject().getDescribe().getName() == childSobjectApiName
            && cr.getField().getDescribe().getName() == relatedFieldApiName){
          	 	name = cr.getRelationshipName();
                break;
            }
        }
        return name;
    }

    /****************************************************************************************
     * Method Name : deleteRecord
     * Params: Id recordId
     * **************************************************************************************/  

	@AuraEnabled
    public static Boolean deleteRecord(Id recordId){
        try{
            Sobject sobj = recordId.getSObjectType().newSObject(recordId);
            Database.DeleteResult result = Database.delete(sobj, true);
            return result.isSuccess();
        }catch (Exception ex) {
			throw new AuraHandledException(ErrorOccured + ex.getMessage());
        } 
	}       

     /****************************************************************************************
     * Method Name : getIconName
     * Params: String sobjectApiName
     * **************************************************************************************/ 
    
    @AuraEnabled
    public static String getIconName(String sobjectApiName){
    try{
        String iconName;
            List<Schema.DescribeTabSetResult> tabSetDesc = Schema.DescribeTabs();
            List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
            List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();
    
            for(Schema.DescribeTabSetResult tsr : tabSetDesc) { 
                tabDesc.addAll(tsr.getTabs()); 
            }
    
            for(Schema.DescribeTabResult tr : tabDesc) {
                if( sobjectApiName == tr.getSobjectName() ) {
                    if( tr.isCustom() ) {
                        iconDesc.addAll(tr.getIcons());
                    } else {
                        iconName = 'standard:' + sobjectApiName.toLowerCase();
                    }
                }
            }
            for (Schema.DescribeIconResult ir : iconDesc) {
                if (ir.getContentType() == 'image/svg+xml'){
                    iconName = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                    break;
                }
            }
            return iconName;
        }  
        catch (Exception ex) {
            throw new AuraHandledException(ErrorOccured + ex.getMessage());
        }
    }
    
    /****************************************************************************************
     * Method Name : getIPHistoryRecords
     * Params: String jsonData
     * return : List of IP history Records
     * **************************************************************************************/ 
    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> getIPHistoryRecords(String jsonData){
        try{
            List<NSP_IP_History_Tracking__b> records =  (List<NSP_IP_History_Tracking__b>) getRecords(jsonData);
            return getRelatedClients(records);
        } catch (Exception ex) {
            throw new AuraHandledException(ErrorOccured + ex.getMessage());
        }
    }

    /****************************************************************************************
     * Method Name : getImplementationPayPeriodHistory
     * Params: String recordId
     * Params: Integer pageNumber
     * **************************************************************************************/ 
    @AuraEnabled(cacheable = true)
    public static RecordsWrapper getImplementationPayPeriodHistory(String recordId, Integer pageNumber){
        try{
            Integer recordSize = 10;
            RecordsWrapper recordWrapper = new RecordsWrapper();
            String payPeriodquery = new NSP_QueryBuilder('Implementation_Pay_Period__c', new List<String>{'Id'})
                .addFilter('NSP_Implementation_Profile__c', new List<Id>{ String.escapeSingleQuotes(recordId) } , NSP_QueryBuilder.Operator.INCLUDES)
                .build();
            List<Id> payPeriodHistoryIds = new List<Id>();
            
            for(Implementation_Pay_Period__c ipPayPeriod : Database.Query(payPeriodquery)){
                payPeriodHistoryIds.add(ipPayPeriod.Id);
            }
            Integer offset = (pageNumber - 1) * recordSize;
            String payPeriodHistoryQuery = new NSP_QueryBuilder('Implementation_Pay_Period__History', new List<String>{'Id', 'ParentId', 'Parent.Name', 'Field', 'DataType', 'OldValue', 'NewValue', 'CreatedBy.Name' , 'CreatedDate'})
                .addFilter('ParentId', payPeriodHistoryIds, NSP_QueryBuilder.Operator.INCLUDES)
                .addLimit(recordSize)
                .setSecurityEnforce(false)
                .build()+' offset : offset';

            
            recordWrapper.lstRecords = Database.query(payPeriodHistoryQuery);
            recordWrapper.recordCount = Database.countQuery('SELECT count() FROM Implementation_Pay_Period__History WHERE ParentId IN: payPeriodHistoryIds');
            
            return recordWrapper;
        } catch (Exception ex) {
            throw new AuraHandledException(ErrorOccured + ex.getMessage());
        }
    }

    /****************************************************************************************
     * Method Name : process RelatedClients from Ids to Names
     * Params: List<NSP_IP_History_Tracking__b> records
     * Return History of Processed IP history Records
     * **************************************************************************************/ 
    public static List<Map<String,Object>> getRelatedClients(List<NSP_IP_History_Tracking__b> records){
        Set<String> recordIdReferences = new Set<String>{'NSP_Related_Clients__c'};
        Set<Id> lstRelatedClientIds = new Set<Id>();
        for(NSP_IP_History_Tracking__b historyTracking : (List<NSP_IP_History_Tracking__b>) records){
            if(recordIdReferences.contains(historyTracking.NSP_Field_Name__c)){
                List<Id> newIds = historyTracking?.NSP_New_Value__c?.split(', ');
                if(newIds != null){
                    lstRelatedClientIds.addAll(newIds);
                }
                List<Id> oldIds = historyTracking?.NSP_Old_Value__c?.split(', ');
                if(oldIds != null){
                    lstRelatedClientIds.addAll(oldIds);
                }
            }
        }
       
        return updateReferenceValues(lstRelatedClientIds, records, recordIdReferences);
    }

    /****************************************************************************************
     * Method Name : process RelatedClients from Ids to Names
     * Params: lstRelatedClientIds ids to be replaced
     * Params: records History records
     * Params: recordIdReferences Id references to replace
     * Return History of Processed IP history Records
     * **************************************************************************************/ 
    private static List<Map<String,Object>> updateReferenceValues(Set<Id> lstRelatedClientIds, List<NSP_IP_History_Tracking__b> records, Set<String> recordIdReferences){
        List<Map<String,Object>> lstRecords = new List<Map<String,Object>>();
        Map<Id,Account> accountMap = new Map<Id,Account>();
        if(!lstRelatedClientIds.isEmpty()){
            accountMap = new Map<Id,Account>([SELECT Id, Name from Account WHERE Id IN: lstRelatedClientIds ]);
        }

        for(NSP_IP_History_Tracking__b rec : records){
            String fieldApiName = String.valueOf(rec.get('NSP_Field_Name__c'));
            Map<String, Object> fieldValues = new Map<String, Object>();
            fieldValues.put('NSP_Field_Label__c', rec.get('NSP_Field_Label__c'));
            fieldValues.put('NSP_Field_Name__c', rec.get('NSP_Field_Name__c'));
            fieldValues.put('NSP_Modified_Date__c', rec.get('NSP_Modified_Date__c'));
            fieldValues.put('NSP_Old_Value__c', recordIdReferences.contains(fieldApiName) ? replaceIdWithName(accountMap, String.valueOf(rec.get('NSP_Old_Value__c'))) : rec.get('NSP_Old_Value__c'));
            fieldValues.put('NSP_New_Value__c',  recordIdReferences.contains(fieldApiName) ? replaceIdWithName(accountMap, String.valueOf(rec.get('NSP_New_Value__c'))) : rec.get('NSP_New_Value__c'));
            fieldValues.put('NSP_Modified_By__c', rec.get('NSP_Modified_By__c'));
            fieldValues.put('lastModifiedName', rec.NSP_Modified_By__r.Name);
            fieldValues.put('NSP_Index__c', rec.get('NSP_Index__c'));
            lstRecords.add(fieldValues);
        }
        return lstRecords;
    }

    /****************************************************************************************
     * Method Name : process RelatedClients from Ids to Names
     * Params: accountMap account with ids
     * Params: ids
     * Return Object return list of processed names
     * **************************************************************************************/ 
    private static Object replaceIdWithName(Map<Id,Account> accountMap, String ids){
        List<String> lstNames = new List<String>();
        List<String> lstIds = ids?.split(', ');
        if(lstIds != null){
            for(String recordId : lstIds ){
                lstNames.add(accountMap.get(recordId)?.Name);
            }
        }
        return (Object) String.join(lstNames, ', ');
    }
    

    public class RecordsWrapper{
        @AuraEnabled public List<Implementation_Pay_Period__History> lstRecords;
        @AuraEnabled public Integer recordCount;
    }
    
}