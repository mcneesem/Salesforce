public with sharing class NSP_SObjectHistoryTrackingHelper implements Queueable {
    // test w/ NSP_SObjectHistoryTrackingHelperTest, NSP_SingleRelatedListControllerTest (80%)
    // test w/ NSP_SObjectHistoryTrackingHelperTest (66%)
    // test w/ NSP_SingleRelatedListControllerTest (27%)

    // unified entry point...
    public static void enqueueJob( Map<Id,sObject> newRecords , Map<Id,sObject> oldRecords ) {
        String localSObjectName = null;
        if ( newRecords != null ) {
            Schema.SObjectType localSObjectType = newRecords.getSObjectType();
            if ( localSObjectType != null ) {
                localSObjectName = String.valueOf( localSObjectType );
            }
        }
        Boolean isAllowedSObjectName = False;
        if ( String.isNotBlank( localSObjectName )
            && ( NSP_SObjectHistoryTrackingHelper.allowedSObjectNames != null )
            && NSP_SObjectHistoryTrackingHelper.allowedSObjectNames.contains( localSObjectName )
           )
        {
            isAllowedSObjectName = True;
        }
        if ( isAllowedSObjectName
            && NSP_SObjectHistoryTrackingHelper.isEnabled
            && ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() )
            )
        {
            System.enqueueJob(
                new NSP_SObjectHistoryTrackingHelper(
                    newRecords ,
                    oldRecords
                )
            );
        }
    }

    //
    //
    //

    private static HistoryTrackingSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = HistoryTrackingSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( NSP_SObjectHistoryTrackingHelper.settings != null ) {
                    local = NSP_SObjectHistoryTrackingHelper.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    public static Boolean isEnabledStandard {
        public get {
            if ( isEnabledStandard == null ) {
                Boolean local = False;
                if ( NSP_SObjectHistoryTrackingHelper.settings != null ) {
                    local = NSP_SObjectHistoryTrackingHelper.settings.IsEnabledStandard__c;
                }
                isEnabledStandard = local;
            }
            return isEnabledStandard;
        }
        private set;
    }

    private static Set<String> allowedSObjectNames {
        private get {
            if ( allowedSObjectNames == null ) {
                Set<String> local = null;
                if ( ( NSP_SObjectHistoryTrackingHelper.settings != null )
                    && String.isNotBlank( NSP_SObjectHistoryTrackingHelper.settings.AllowedSObjectNames__c )
                    )
                {
                    List<String> allowedSObjectNamesList = NSP_SObjectHistoryTrackingHelper.settings.AllowedSObjectNames__c.split( ',' );
                    if ( ( allowedSObjectNamesList != null ) && !allowedSObjectNamesList.isEmpty() ) {
                        local = new Set<String>( allowedSObjectNamesList );
                    }
                }
                allowedSObjectNames = local;
            }
            return allowedSObjectNames;
        }
        private set;
    }

    //
    //
    //

    private Map<Id,sObject> newMapSObject;
    private Map<Id,sObject> oldMapSObject;
    private Map<Id,Decimal> recIdHistoryCountMap = new Map<Id,Decimal>();
    private List<NSP_SObject_Field_History__mdt> objFields = new List<NSP_SObject_Field_History__mdt>();

    private NSP_SObjectHistoryTrackingHelper( Map<Id,sObject> newMapSObject , Map<Id,sObject> oldMapSObject ) {
        this.newMapSObject = newMapSObject;
        this.oldMapSObject = oldMapSObject;
    }

    //
    // Here we insert the Customer Interaction big object records, or log an error if insertion fails.
    //
    public void execute( QueueableContext context ) {
        try {
            if ( ( this.newMapSObject != null )
                && ( this.newMapSObject InstanceOf Map<Id,Implementation_Profile__c> )
                && ( this.recIdHistoryCountMap != null )
                && this.recIdHistoryCountMap.isEmpty()
                )
            {
                this.getPreviousIPHistoryRecordCount();
            }
            if ( this.objFields != null ) {
                this.objFields.addAll( this.getMetaDataFields() );
                if ( !this.objFields.isEmpty() ) {
                    this.fieldHistoryLogData(
                        this.newMapSObject ,
                        this.oldMapSObject
                    );
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_SObjectHistoryTrackingHelper.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    private void fieldHistoryLogData( Map<Id,sObject> newMapSObject , Map<Id,sObject> oldMapSObject ) {
        // loop through new records, finding fields that changed...
        final List<sObject> trackList = new List<sObject>();
        if ( this.fieldMap != null ) {
            for ( Id sobjkey : newMapSObject.keySet() ) {
                sObject newRec = newMapSObject.get( sobjkey );
                sObject oldRec = oldMapSObject.get( newRec.Id );
                Integer count = 1;
                for ( NSP_SObject_Field_History__mdt ofh : objFields ) {
                    // used cached results of the described field map to reduce System.LimitException: Apex CPU time limit exceeded...
                    if ( this.fieldMap.containsKey( ofh.NSP_Field_API_Name__c.toLowerCase() )
                        && ( newRec != null )
                        && ( oldRec != null )
                        && ( newRec.get( ofh.NSP_Field_API_Name__c ) != oldRec.get( ofh.NSP_Field_API_Name__c ) )
                        )
                    {
                        if ( newRec instanceof Implementation_Profile__c ) {
                            trackList.add( newIPHistoryTrackingRec( newRec , ofh , count ) );
                            count++;
                        } else {
                            trackList.add( newHistoryTrackingRec( newRec , ofh ) );
                        }
                    }
                }
            }
        }
        try {
            if ( !trackList.isEmpty() && !Test.isRunningTest() ) {
                Database.insertImmediate( trackList );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_SObjectHistoryTrackingHelper.class.getName() ,
                'fieldHistoryLogData' ,
                e
            );
        }
    }

    //
    // MethodName: newHistoryTrackingRec
    // Description : prepare bigobject history record
    //
    private  NSP_SObjects_History_Tracking__b newHistoryTrackingRec(sObject newRec, NSP_SObject_Field_History__mdt ofh){
        final NSP_SObjects_History_Tracking__b oht = new NSP_SObjects_History_Tracking__b();
        sObject oldRec = oldMapSObject.get(newRec.Id);

        // set rest of fields
        oht.NSP_Field_Name__c = fieldMap.get(ofh.NSP_Field_API_Name__c).getDescribe().getLabel();
        oht.NSP_Sobject_Record_Id__c  = (String)newRec.get('Id');
        // set old and new values
        oht.NSP_Old_Value__c = String.valueOf(oldRec.get(ofh.NSP_Field_API_Name__c));
        oht.NSP_New_Value__c = String.valueOf(newRec.get(ofh.NSP_Field_API_Name__c));
        // for now - get the userid and modify date out of the new record
        oht.NSP_Modified_By__c = (Id) newRec.get('LastModifiedById');
        oht.NSP_Modified_Date__c = (Datetime) newRec.get('LastModifiedDate');
        //poulate Effective date if NSP_Client_Segment_type__c is changed on asset
        if ( oht.NSP_Field_Name__c == String.valueOf( 'Client Segment type' ) ) {
            oht.NSP_Effective_Date__c = (Datetime)newRec.get( 'NSP_Client_SegmentDate__c' );
        }
        return oht;
    }

    //
    // MethodName: newIPHistoryTrackingRec
    // Description : prepare bigobject IP history record
    //
    private  NSP_IP_History_Tracking__b newIPHistoryTrackingRec(sObject newRec, NSP_SObject_Field_History__mdt ofh, Integer count){
        final NSP_IP_History_Tracking__b oht = new NSP_IP_History_Tracking__b();
        sObject oldRec = oldMapSObject.get(newRec.Id);
        // set rest of fields
        oht.NSP_Field_Label__c = fieldMap.get(ofh.NSP_Field_API_Name__c).getDescribe().getLabel();
        oht.NSP_Field_Name__c = fieldMap.get(ofh.NSP_Field_API_Name__c).getDescribe().getName();
        oht.NSP_Sobject_Record_Id__c  = (String)newRec.get('Id');
        // set old and new values
        oht.NSP_Old_Value__c = String.valueOf(oldRec.get(ofh.NSP_Field_API_Name__c));
        oht.NSP_New_Value__c = String.valueOf(newRec.get(ofh.NSP_Field_API_Name__c));
        // for now - get the userid and modify date out of the new record
        oht.NSP_Modified_By__c = (Id) newRec.get('LastModifiedById');
        oht.NSP_Modified_Date__c = (Datetime) newRec.get('LastModifiedDate');
        //this is set for pagination
        if(recIdHistoryCountMap.containsKey((String)newRec.get('Id'))){
            oht.NSP_Index__c = recIdHistoryCountMap.get((String)newRec.get('Id'));
            recIdHistoryCountMap.put((String)newRec.get('Id'), recIdHistoryCountMap.get((String)newRec.get('Id')) + 1);
        } else {
            oht.NSP_Index__c = count;
        }
        return oht;
    }

    private Schema.SObjectType soType {
        private get {
            if ( ( soType == null ) && ( this.newMapSObject != null ) ) {
                soType = this.newMapSObject.getSObjectType();
            }
            return soType;
        }
        private set;
    }

    // cache the results of the describing the field map results to reduce System.LimitException: Apex CPU time limit exceeded...
    private Map<String,Schema.SObjectField> fieldMap {
        private get {
            if ( ( fieldMap == null ) && ( this.soType != null ) ) {
                fieldMap = this.soType.getDescribe().fields.getMap();
            }
            return fieldMap;
        }
        private set;
    }

    private String sObjectName {
        private get {
            if ( ( sObjectName == null ) && ( this.soType != null ) ) {
                sObjectName = String.valueOf( this.soType );
            }
            return sObjectName;
        }
        private set;
    }

    //
    // MethodName: getMetaDataFields
    // Description : get a list of the fields that need to be updated
    //
    private List<NSP_SObject_Field_History__mdt> getMetaDataFields() {
        return [
            SELECT NSP_Field_API_Name__c , NSP_Field_Label__c
            FROM NSP_SObject_Field_History__mdt
            WHERE NSP_SObject_Name__c = :this.sObjectName
        ];
    }

    //
    // MethodName: getPreviousIPHistoryRecordCount
    // Description : Get previous IP bigObject count
    //
    private void getPreviousIPHistoryRecordCount() {
        // 2024-12-30 ~ throws ~ System.BigObjectException: Internal Salesforce.com Query Error
        for(NSP_IP_History_Tracking__b obj: [SELECT NSP_Index__c, NSP_Sobject_Record_Id__c FROM NSP_IP_History_Tracking__b WHERE NSP_Sobject_Record_Id__c IN: newMapSObject.keySet() ]){
            if(!recIdHistoryCountMap.containsKey(obj.NSP_Sobject_Record_Id__c)){
                recIdHistoryCountMap.put(obj.NSP_Sobject_Record_Id__c, obj.NSP_Index__c >= 1 ? obj.NSP_Index__c + 1: 1 );
            }
        }
    }

    // mirgrated from NSP_HistoryTrackingVisibilityHandler
    public static List<SObject> getAccessibleFieldList( List<sObject> objRecords , Id recordId ) {
        List<sObject> accessibleFieldsData = new List<sObject>();
        for ( String fieldName : NSP_HistoryTrackingVisibilityHandler.getAccessibleFields( recordId ) ) {
            for ( sObject objRecord : objRecords ) {
                if ( ( objRecord.getSObjectType() == NSP_SObjects_History_Tracking__b.sObjectType )
                    && ( fieldName == ((NSP_SObjects_History_Tracking__b)objRecord).NSP_Field_Name__c )
                    )
                {
                    accessibleFieldsData.add( objRecord );
                }
            }
        }
        return accessibleFieldsData;
    }

    // mirgrated from NSP_HistoryTrackingVisibilityHandler
    public static List<String> getAccessibleFields( Id recordId ) {
        List<String> fieldsToShow = new List<String>();
        if ( ( recordId != null )
            && ( NSP_SObjectHistoryTrackingHelper.globalDescribe != null )
            )
        {
            SObjectType schemaType = NSP_SObjectHistoryTrackingHelper.globalDescribe.get( String.valueOf( recordId.getSObjectType() ) );
            if ( schemaType != null ) {
                Map<String,SObjectField> fieldMap = schemaType.getDescribe().fields.getMap();
                if ( ( fieldMap != null ) && !fieldMap.isEmpty() ) {
                    for ( String field : fieldMap.keySet() ) {
                        SObjectField sfield = fieldMap.get( field );
                        if ( sfield.getDescribe().isAccessible() ) {
                            fieldsToShow.add( sfield.getDescribe().getLabel() );
                        }
                    }
                }
            }
        }
        return fieldsToShow;
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