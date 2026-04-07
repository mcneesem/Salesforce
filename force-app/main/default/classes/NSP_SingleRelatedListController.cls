public without sharing class NSP_SingleRelatedListController {
    // test w/ NSP_SingleRelatedListControllerTest (83%)

    private static final String FIELDS_PARAM = 'fields';
    private static final String NUMBER_OF_RECORDS_PARAM = 'numberOfRecords';
    private static final String RECORD_ID_PARAM = 'recordId';
    private static final String SOBJECT_API_NAME_PARAM = 'sobjectApiName';
    private static final String SOBJECT_LABEL_PARAM = 'sobjectLabel';
    private static final String SOBJECT_LABEL_PLURAL_PARAM = 'sobjectLabelPlural';
    private static final String PARENT_RELATIONSHIP_API_NAME_PARAM = 'parentRelationshipApiName';
    private static final String RELATED_FIELD_API_NAME_PARAM = 'relatedFieldApiName';
    private static final String SORTED_DIRECTION_PARAM = 'sortedDirection';
    private static final String SORTED_BY_PARAM = 'sortedBy';
    private static final String RECORDS_PARAM = 'records';
    private static final String ICON_NAME_PARAM = 'iconName';
    private static final String PAGE_NUMBER_PARAM = 'pageNumber';
    private static final String ErrorOccured = 'Error Occured ';

    //
    //
    //

    // extract recordId from LWC/Aura generated JSON payload...
    // ~ backwards compatibility with LWC:nsp_historyTracking and Aura:NSP_SingleRelatedList
    private static Id parseRecordId( String jsonData ) {
        Id recordId = null;
        if ( String.isNotBlank( jsonData ) ) {
            Map<String,Object> root = (Map<String,Object>)JSON.deserializeUntyped( jsonData );
            if ( root != null ) {
                recordId = (Id)root.get( 'recordId' );
            }
        }
        return recordId;
    }

    // extract numberOfRecords from LWC/Aura generated JSON payload...
    // ~ backwards compatibility with LWC:nsp_historyTracking and Aura:NSP_SingleRelatedList
    private static Integer parseLimit( String jsonData ) {
        Integer soqlLimit = 10;
        if ( String.isNotBlank( jsonData ) ) {
            Map<String,Object> root = (Map<String,Object>)JSON.deserializeUntyped( jsonData );
            if ( root != null ) {
                soqlLimit = (Integer)root.get( 'numberOfRecords' );
            }
        }
        // must be non-null...
        if ( soqlLimit == null ) {
            soqlLimit = 10;
        }
        return soqlLimit;
    }

    // extract pageNumber from LWC/Aura generated JSON payload...
    // ~ backwards compatibility with LWC:nsp_historyTracking and Aura:NSP_SingleRelatedList
    private static Integer parseOffset( String jsonData ) {
        Integer soqlOffset = 0;
        if ( String.isNotBlank( jsonData ) ) {
            Map<String,Object> root = (Map<String,Object>)JSON.deserializeUntyped( jsonData );
            if ( root != null ) {
                soqlOffset = (Integer)root.get( 'pageNumber' );
            }
        }
        // must be non-null...
        if ( soqlOffset == null ) {
            soqlOffset = 0;
        }
        return soqlOffset;
    }

    // DEPRECATED
    // ~ previously used by Aura:NSP_SingleRelatedList
    @AuraEnabled(cacheable=true)
    public static String initData( String jsonData ) {
        try{
            Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);
            Map<String, Object> responseMap = new Map<String, Object>();
            String sobjectApiName = (String)requestMap.get(SOBJECT_API_NAME_PARAM);
            responseMap.put(ICON_NAME_PARAM, getIconName(sobjectApiName));
            String recordId = NSP_SingleRelatedListController.parseRecordId( jsonData );
            NSP_SingleRelatedListController.parseLimit( jsonData );
            NSP_SingleRelatedListController.parseOffset( jsonData );
            String relatedFieldApiName = (String)requestMap.get(RELATED_FIELD_API_NAME_PARAM);
            responseMap.put(PARENT_RELATIONSHIP_API_NAME_PARAM, getParentRelationshipName(recordId, sobjectApiName, relatedFieldApiName));
            Schema.SObjectType sobjectType = NSP_SingleRelatedListController.globalDescribe.get( sobjectApiName );
            Schema.DescribeSObjectResult sobjectDescribe = sobjectType.getDescribe();
            responseMap.put(SOBJECT_LABEL_PARAM, sobjectDescribe.getLabel());
            responseMap.put(SOBJECT_LABEL_PLURAL_PARAM, sobjectDescribe.getLabelPlural());
            return JSON.serialize(responseMap);
        } catch (Exception ex) {
            throw new AuraHandledException(ErrorOccured + ex.getMessage());
        }
    }

    // query all standard history for a given Implementation_Profile__c record...
    private static List<Implementation_Profile__History> selectImplementationProfileHistory( Id recordId ) {
        List<Implementation_Profile__History> response = new List<Implementation_Profile__History>();
        if ( recordId != null ) {
            response = [
                SELECT
                    Id ,
                    ParentId ,
                    Field ,
                    DataType ,
                    OldValue ,
                    NewValue ,
                    CreatedById ,
                    CreatedBy.Name ,
                    CreatedDate
                FROM Implementation_Profile__History
                WHERE ( ParentId = :recordId )
                ORDER BY CreatedDate DESC
            ];
        }
        return response;
    }

    public static List<sObject> testGetRecords( String jsonData ) {
        List<sObject> response = null;
        if ( Test.isRunningTest() ) {
            response = NSP_SingleRelatedListController.getRecords( jsonData );
        }
        return response;
    }

    private static List<sObject> getRecords( String jsonData ) {
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

    private static String getParentRelationshipName( Id recordId , String childSobjectApiName , String relatedFieldApiName ) {
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

    public static Boolean deleteRecord( Id recordId ) {
        try{
            Sobject sobj = recordId.getSObjectType().newSObject(recordId);
            Database.DeleteResult result = Database.delete(sobj, true);
            return result.isSuccess();
        }catch (Exception ex) {
            throw new AuraHandledException(ErrorOccured + ex.getMessage());
        }
    }

    private static String getIconName( String sobjectApiName ) {
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

    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> getIPHistoryRecords( String jsonData ) {
        List<Map<String,Object>> response = null;
        try {
            if ( NSP_SObjectHistoryTrackingHelper.isEnabledStandard ) {
                // replace NSP_IP_History_Tracking__b usage with Implementation_Profile__History...
                Id recordId = NSP_SingleRelatedListController.parseRecordId( jsonData );
                Integer soqlLimit = NSP_SingleRelatedListController.parseLimit( jsonData );
                Integer soqlOffset = NSP_SingleRelatedListController.parseOffset( jsonData );
                List<Implementation_Profile__History> stories = NSP_SingleRelatedListController.selectImplementationProfileHistory( recordId );
                response = NSP_SingleRelatedListController.tranformHistory(
                    stories ,
                    soqlLimit ,
                    soqlOffset
                );
            } else {
                List<NSP_IP_History_Tracking__b> records = (List<NSP_IP_History_Tracking__b>)NSP_SingleRelatedListController.getRecords( jsonData );
                response = NSP_SingleRelatedListController.getRelatedClientsInternal( records );
            }
        } catch ( Exception e ) {
            throw new AuraHandledException( ErrorOccured + e.getMessage() );
        }
        return response;
    }

    // transform Implementation_Profile__History records into the javascipt object structure expected by the existing LWC/Aura components...
    // ~ backwards compatibility with LWC:nsp_historyTracking and Aura:NSP_SingleRelatedList
    private static List<Map<String,Object>> tranformHistory(
        List<Implementation_Profile__History> records ,
        Integer soqlLimit ,
        Integer soqlOffset
        )
    {
        List<Map<String,Object>> response = new List<Map<String,Object>>();
        if ( ( records != null ) && !records.isEmpty() ) {
            Integer count = 0;
            Integer index = records.size();
            for ( Implementation_Profile__History record : records ) {
                if ( ( count < soqlLimit )
                    && ( ( soqlOffset <= 0 ) || ( index < soqlOffset ) )
                    )
                {
                    Map<String,Object> row = new Map<String,Object>();
                    row.put( 'NSP_Field_Label__c' , NSP_SingleRelatedListController.getFieldLabel( record.Field ) );
                    row.put( 'NSP_Field_Name__c' , record.Field );
                    row.put( 'NSP_Modified_Date__c' , record.CreatedDate );
                    row.put( 'NSP_Old_Value__c' , record.OldValue );
                    row.put( 'NSP_New_Value__c' ,  record.NewValue );
                    row.put( 'NSP_Modified_By__c' , record.CreatedById );
                    row.put( 'lastModifiedName' , record.CreatedBy.Name );
                    row.put( 'NSP_Index__c' , index );
                    response.add( row );
                    count++;
                }
                index--;
            }
        }
        return response;
    }

    @AuraEnabled(cacheable=true)
    public static RecordsWrapper getImplementationPayPeriodHistory( String recordId , Integer pageNumber ) {
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

    // NSP_ImplementationProfileControllerTest
    // NSP_SingleRelatedListControllerTest
    public static List<Map<String,Object>> getRelatedClients( List<NSP_IP_History_Tracking__b> records ) {
        List<Map<String,Object>> lstRecords = new List<Map<String,Object>>();
        if ( Test.isRunningTest() ) {
            lstRecords = NSP_SingleRelatedListController.getRelatedClientsInternal( records );
        }
        return lstRecords;
    }

    private static List<Map<String,Object>> getRelatedClientsInternal( List<NSP_IP_History_Tracking__b> records ) {
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
        return NSP_SingleRelatedListController.updateReferenceValues(
            lstRelatedClientIds ,
            records ,
            recordIdReferences
        );
    }

    private static List<Map<String,Object>> updateReferenceValues( Set<Id> lstRelatedClientIds , List<NSP_IP_History_Tracking__b> records , Set<String> recordIdReferences ) {
        List<Map<String,Object>> lstRecords = new List<Map<String,Object>>();
        Map<Id,Account> accountMap = new Map<Id,Account>();
        if(!lstRelatedClientIds.isEmpty()){
            accountMap = new Map<Id,Account>([SELECT Id, Name from Account WHERE Id IN: lstRelatedClientIds ]);
        }

        for(NSP_IP_History_Tracking__b rec : records){
            String fieldApiName = String.valueOf(rec.get('NSP_Field_Name__c'));
            Map<String, Object> fieldValues = new Map<String, Object>();
            fieldValues.put('NSP_Field_Label__c', NSP_SingleRelatedListController.getFieldLabel( (String)rec.get('NSP_Field_Name__c') ) );
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

    private static Object replaceIdWithName( Map<Id,Account> accountMap , String ids ) {
        List<String> lstNames = new List<String>();
        List<String> lstIds = ids?.split(', ');
        if(lstIds != null){
            for(String recordId : lstIds ){
                lstNames.add(accountMap.get(recordId)?.Name);
            }
        }
        return (Object) String.join(lstNames, ', ');
    }

    public class RecordsWrapper {
        @AuraEnabled
        public List<Implementation_Pay_Period__History> lstRecords;
        @AuraEnabled
        public Integer recordCount;
    }

    //
    // schema helper methods...
    //

    public static String testGetFieldLabel( String fieldApiName ) {
        String fieldLabel = fieldApiName;
        if ( Test.isRunningTest() ) {
            fieldLabel = NSP_SingleRelatedListController.getFieldLabel( fieldApiName );
        }
        return fieldLabel;
    }

    private static String getFieldLabel( String fieldApiName ) {
        String fieldLabel = fieldApiName;
        if ( String.isNotBlank( fieldApiName ) ) {
            // populate the describe map...
            if ( !NSP_SingleRelatedListController.describeFieldResultMap.containsKey( fieldApiName ) ) {
                SObjectField soField = null;
                if ( NSP_SingleRelatedListController.fieldMap.containsKey( fieldApiName ) ) {
                    soField = NSP_SingleRelatedListController.fieldMap.get( fieldApiName );
                }
                if ( soField != null ) {
                    Schema.DescribeFieldResult fieldResult = soField.getDescribe();
                    if ( fieldResult != null ) {
                        NSP_SingleRelatedListController.describeFieldResultMap.put(
                            fieldApiName ,
                            fieldResult
                        );
                    }
                }
            }
            // use describe map to access cached label...
            if ( NSP_SingleRelatedListController.describeFieldResultMap.containsKey( fieldApiName ) ) {
                Schema.DescribeFieldResult describedField = NSP_SingleRelatedListController.describeFieldResultMap.get( fieldApiName );
                if ( describedField != null ) {
                    fieldLabel = describedField.getLabel();
                }
            }
        }
        return fieldLabel;
    }

    // cached map from field api name to described field results...
    private static Map<String,Schema.DescribeFieldResult> describeFieldResultMap {
        private get {
            if ( describeFieldResultMap == null ) {
                describeFieldResultMap = new Map<String,Schema.DescribeFieldResult>();
            }
            return describeFieldResultMap;
        }
        private set;
    }

    // cached map of all fields on the Implementation_Profile__c sobject...
    private static Map<String,SObjectField> fieldMap {
        private get {
            if ( fieldMap == null ) {
                fieldMap = Schema.Implementation_Profile__c.SObjectType.getDescribe().fields.getMap();
            }
            return fieldMap;
        }
        private set;
    }

    // cached global schema description...
    private static Map<String,Schema.SObjectType> globalDescribe {
        private get {
            if ( globalDescribe == null ) {
                globalDescribe = Schema.getGlobalDescribe();
            }
            return globalDescribe;
        }
        private set;
    }

}
//