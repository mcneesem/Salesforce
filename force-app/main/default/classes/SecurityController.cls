public with sharing class SecurityController {
    // test w/ SecurityControllerTest (97%)
    private static final String CLASS_NAME = ' ~ SecurityController';

    //
    // dynamic soql support
    //

    // generate a basic SELECT query containing all accessible fields for a given sObject
    // ~ a field is accessible if User has a minimum of Read Permission...
    // ~ results are cached and only derived once per request/execution...
    public static String getAccessibleSelectQuery( SObjectType soType ) {
        String accessibleSoqlQuery = null;
        if ( ( soType != null )
            && ( SecurityController.sObjectAccessibleSoqlQueries != null )
           )
        {
            if ( SecurityController.sObjectAccessibleSoqlQueries.containsKey( soType ) ) {
                // pull from previous calculation...
                accessibleSoqlQuery = SecurityController.sObjectAccessibleSoqlQueries.get( soType );
            } else {
                // build and store in static property cache...
                String accessibleSoqlFields = SecurityController.getAccessibleSoqlFields( soType );
                if ( String.isNotBlank( accessibleSoqlFields ) ) {
                    accessibleSoqlQuery = 'SELECT ' + accessibleSoqlFields;
                    accessibleSoqlQuery += ' FROM ' + soType.getDescribe().getName();
                    SecurityController.sObjectAccessibleSoqlQueries.put( soType , accessibleSoqlQuery );
                }
            }
        }
        return accessibleSoqlQuery;
    }

    // cache of previously computed accessibleSoqlFields for each sObjectType...
    // ~ SObjectType --> 'SELECT * FROM sObject'
    private static Map<SObjectType,String> sObjectAccessibleSoqlQueries {
        get {
            if ( sObjectAccessibleSoqlQueries == null ) {
                sObjectAccessibleSoqlQueries = new Map<SObjectType,String>();
            }
            return sObjectAccessibleSoqlQueries;
        }
        private set;
    }

    // generate a comma-separated String of accessible Field API Names for a given sObject
    // ~ a field is accessible if User has a minimum of Read Permission...
    // ~ results are cached and only derived once per request/execution...
    private static String getAccessibleSoqlFields( SObjectType soType ) {
        String accessibleSoqlFields = null;
        if ( ( soType != null )
            && ( SecurityController.sObjectAccessibleSoqlFields != null )
           )
        {
            if ( SecurityController.sObjectAccessibleSoqlFields.containsKey( soType ) ) {
                // pull from previous calculation...
                accessibleSoqlFields = SecurityController.sObjectAccessibleSoqlFields.get( soType );
            } else {
                // build and store in static property cache...
                accessibleSoqlFields = '';
                List<String> accessibleSObjectFieldNames = SecurityController.getAccessibleFieldNames( soType );
                if ( ( accessibleSObjectFieldNames != null )
                    && ( accessibleSObjectFieldNames.size() > 0 )
                   )
                {
                    accessibleSoqlFields = String.join( accessibleSObjectFieldNames , ' , ' );
                }
                SecurityController.sObjectAccessibleSoqlFields.put( soType , accessibleSoqlFields );
            }
        }
        return accessibleSoqlFields;
    }

    // cache of previously computed accessibleSoqlFields for each sObjectType...
    // ~ SObjectType --> comma separated String of Field API Names
    private static Map<SObjectType,String> sObjectAccessibleSoqlFields {
        get {
            if ( sObjectAccessibleSoqlFields == null ) {
                sObjectAccessibleSoqlFields = new Map<SObjectType,String>();
            }
            return sObjectAccessibleSoqlFields;
        }
        private set;
    }

    // generate a List of accessible Field API Names for a given sObject
    // ~ a field is accessible if User has a minimum of Read Permission...
    // ~ results are cached and only derived once per request/execution...
    public static List<String> getAccessibleFieldNames( Schema.SObjectType soType ) {
        List<String> accessibleFieldNames = null;
        if ( ( soType != null )
            && ( SecurityController.sObjectAccessibleFieldNames != null )
           )
        {
            if ( SecurityController.sObjectAccessibleFieldNames.containsKey( soType ) ) {
                // pull from previous calculation...
                accessibleFieldNames = SecurityController.sObjectAccessibleFieldNames.get( soType );
            } else {
                // build and store in static property cache...
                accessibleFieldNames = new List<String>();
                Map<String,Schema.SObjectField> accessibleFieldMap = SecurityController.getAccessibleFieldMap( soType );
                if ( accessibleFieldMap != null ) {
                    for ( String fieldtoken : accessibleFieldMap.keySet() ) {
                        // the 'fieldtoken' is always a lowercase version of the Field API Name...
                        accessibleFieldNames.add( accessibleFieldMap.get( fieldtoken ).getDescribe().getName() );
                    }
                }
                SecurityController.sObjectAccessibleFieldNames.put( soType , accessibleFieldNames );
            }
        }
        return accessibleFieldNames;
    }

    // cache of previously computed accessibleFieldNames for each sObjectType...
    // ~ SObjectType --> List<SObjectField.Name>
    private static Map<Schema.SObjectType,List<String>> sObjectAccessibleFieldNames { 
        get {
            if ( sObjectAccessibleFieldNames == null ) {
                sObjectAccessibleFieldNames = new Map<Schema.SObjectType,List<String>>();
            }
            return sObjectAccessibleFieldNames;
        }
        private set;
    }

    // generate a Map of accessible fields for a given sObject
    // ~ key is a lowercase 'fieldtoken'...
    // ~ a field is accessible if User has a minimum of Read Permission...
    // ~ results are cached and only derived once per request/execution...
    public static Map<String,Schema.SObjectField> getAccessibleFieldMap( Schema.SObjectType soType ) {
        Map<String,Schema.SObjectField> accessibleFieldMap = null;
        if ( ( soType != null )
            && ( SecurityController.sObjectAccessibleFieldMap != null )
           )
        {
            if ( SecurityController.sObjectAccessibleFieldMap.containsKey( soType ) ) {
                // pull from previous calculation...
                accessibleFieldMap = SecurityController.sObjectAccessibleFieldMap.get( soType );
            } else {
                // build and store in static property cache...
                accessibleFieldMap = new Map<String,Schema.SObjectField>();
                Map<String,Schema.SObjectField> fieldMap = soType.getDescribe().fields.getMap();
                for ( String fieldtoken : fieldMap.keySet() ) {
                    // the 'fieldtoken' is always a lowercase version of the Field API Name...
                    Schema.DescribeFieldResult fieldDescribe = fieldMap.get( fieldtoken ).getDescribe();
                    if ( fieldDescribe.isAccessible() ) {
                        // User.UserPreferences*** fields can throw "System.QueryException: Insufficient permissions: secure query included inaccessible field" while using 'WITH SECURITY_ENFORCED'...
                        if ( ( soType != User.getSObjectType() ) || !fieldtoken.startsWith( 'userpreferences' ) ) {
                            accessibleFieldMap.put( fieldtoken , fieldMap.get( fieldtoken ) );
                        }
                    }
                }
                SecurityController.sObjectAccessibleFieldMap.put( soType , accessibleFieldMap );
            }
        }
        return accessibleFieldMap;
    }

    // cache of previously computed accessibleFieldMaps for each sObjectType...
    // ~ SObjectType --> fieldtoken --> SObjectField
    private static Map<Schema.SObjectType,Map<String,Schema.SObjectField>> sObjectAccessibleFieldMap {
        private get {
            if ( sObjectAccessibleFieldMap == null ) {
                sObjectAccessibleFieldMap = new Map<Schema.SObjectType,Map<String,Schema.SObjectField>>();
            }
            return sObjectAccessibleFieldMap;
        }
        private set;
    }

}
//