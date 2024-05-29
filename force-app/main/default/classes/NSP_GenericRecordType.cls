//
// Represents generic class to get record type info for any object
//
public with sharing class NSP_GenericRecordType {
    // test w/ NSP_AutomaticProjectBatchTest (100%)
    // test w/ NSP_AssetServiceTriggerHelperTest (100%)
    // test w/ NSP_OrderTriggerHelperTest (100%)
    // test w/ NSP_SingleRelatedListControllerTest (100%)
    // test w/ NSP_SubClientTriggerTest (100%)

    //
    // MethodName: getRecordTypeId
    // Description: This method returns record Type id based on object name and record type developer name
    // Params: String objectName, String developerName
    //
    public static Id getRecordTypeId( String objectName , String developerName ) {
        Id response = null;
        Map<String,Schema.RecordTypeInfo> infoMap = NSP_GenericRecordType.getRecordTypeMap( objectName );
        if ( String.isNotBlank( developerName )
            && ( infoMap != null )
            && infoMap.containsKey( developerName )
            )
        {
            Schema.RecordTypeInfo info = infoMap.get( developerName );
            if ( info != null ) {
                response = info.getRecordTypeId();
            }
        }
        return response;
    }

    //
    // It returns map of all record types of the given object.
    // Returned map will have record type developer name as key and record type info as value.
    // ~ NSP_AssetServiceTriggerHelper
    //
    public static Map<String,Schema.RecordTypeInfo> getRecordTypeMap( String objectName ) {
        Map<String,Schema.RecordTypeInfo> response = new Map<String,Schema.RecordTypeInfo>();
        if ( String.isNotBlank( objectName ) ) {
            if ( ( NSP_GenericRecordType.sObjectRecordTypeInfo != null )
                && NSP_GenericRecordType.sObjectRecordTypeInfo.containsKey( objectName )
                )
            {
                // used cached response to prevent System.LimitException: Apex CPU time limit exceeded
                response = NSP_GenericRecordType.sObjectRecordTypeInfo.get( objectName );
            } else {
                // calculate response once per Apex thread...
                if ( ( NSP_GenericRecordType.globalDescribe != null )
                    && NSP_GenericRecordType.globalDescribe.containsKey( objectName )
                    )
                {
                    SObjectType soType = NSP_GenericRecordType.globalDescribe.get( objectName );
                    if ( soType != null ) {
                        DescribeSObjectResult soDescribe = soType.getDescribe();
                        if ( soDescribe != null ) {
                            response = soDescribe.getRecordTypeInfosByDeveloperName();
                            // cache the response to prevent recalculation...
                            NSP_GenericRecordType.sObjectRecordTypeInfo.put( objectName , response );
                        }
                    }
                }
            }
        }
        return response;
    }

    //
    //
    //

    private static Map<String,Schema.SObjectType> globalDescribe {
        private get {
            if ( globalDescribe == null ) {
                globalDescribe = Schema.getGlobalDescribe();
            }
            return globalDescribe;
        }
        private set;
    }

    private static Map<String,Map<String,Schema.RecordTypeInfo>> sObjectRecordTypeInfo {
        private get {
            if ( sObjectRecordTypeInfo == null ) {
                sObjectRecordTypeInfo = new Map<String,Map<String,Schema.RecordTypeInfo>>();
            }
            return sObjectRecordTypeInfo;
        }
        private set;
    }

}
//