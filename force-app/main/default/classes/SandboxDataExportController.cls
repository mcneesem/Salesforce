public with sharing class SandboxDataExportController {
    // test w/ SandboxDataExportControllerTest (84%)

    public class ExportDefinition {
        @AuraEnabled public String label;
        @AuraEnabled public String developerName;
        @AuraEnabled public String fileName;

        public ExportDefinition(SandboxDataExportQuery__mdt rec) {
            label = rec.Label;
            developerName = rec.DeveloperName;
            fileName = rec.SObjectApiName__c;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ExportDefinition> getExportDefinitions() {
        List<ExportDefinition> definitions = new List<ExportDefinition>();
        try {
            for ( SandboxDataExportQuery__mdt rec : SandboxDataExportQuery__mdt.getAll().values() ) {
                if ( rec.IsActive__c ) {
                    definitions.add( new ExportDefinition( rec ) );
                }
            }
        } catch ( Exception e ) {
            throw new AuraHandledException(
                'Unable to load export definitions. Please contact your administrator.'
            );
        }
        return definitions;
    }

    // Builds a SOQL query from the named SandboxDataExportQuery__mdt record using
    // NSP_QueryBuilder and returns the results as a CSV-formatted string ready for download.
    @AuraEnabled
    public static String executeExport( String developerName ) {
        String csvResult = '';
        try {
            SandboxDataExportQuery__mdt queryRecord = SandboxDataExportController.getValidatedQueryRecord(
                developerName
            );
            List<String> fields = SandboxDataExportController.resolveExportFields( queryRecord );
            String soql = SandboxDataExportController.buildExportQuery( queryRecord , fields );
            List<SObject> records = Database.query( soql );
            csvResult = SandboxDataExportController.buildCsv( records , fields );
        } catch ( AuraHandledException ahe ) {
            throw ahe;
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                SandboxDataExportController.class.getName() ,
                'executeExport' ,
                e
            );
            throw new AuraHandledException(
                'Export failed for "' + developerName + '": ' + e.getMessage()
            );
        }
        return csvResult;
    }

    // ------------------------------------------------------------
    // Private helpers
    // ------------------------------------------------------------

    // Loads the active export definition and validates it is usable; throws AuraHandledException otherwise.
    private static SandboxDataExportQuery__mdt getValidatedQueryRecord( String developerName ) {
        if ( String.isBlank( developerName ) ) {
            throw new AuraHandledException( 'Export name is required.' );
        }
        List<SandboxDataExportQuery__mdt> queryRecords = [
            SELECT
                FieldApiNames__c ,
                SObjectApiName__c ,
                OrderBy__c
            FROM SandboxDataExportQuery__mdt
            WHERE (
                ( DeveloperName = :developerName )
                AND ( IsActive__c = true )
            )
            LIMIT 1
        ];
        if ( queryRecords.isEmpty() ) {
            throw new AuraHandledException( 'Export definition not found: ' + developerName );
        }
        SandboxDataExportQuery__mdt queryRecord = queryRecords[0];
        if ( String.isBlank( queryRecord.SObjectApiName__c ) ) {
            throw new AuraHandledException(
                'Export definition missing SObject configuration: ' + developerName
            );
        }
        return queryRecord;
    }

    // Returns configured fields first, followed by all remaining accessible fields, de-duplicated case-insensitively.
    private static List<String> resolveExportFields( SandboxDataExportQuery__mdt queryRecord ) {
        List<String> fields = new List<String>();
        Set<String> addedFieldKeys = new Set<String>();
        List<String> candidates = new List<String>();
        if ( String.isNotBlank( queryRecord.FieldApiNames__c ) ) {
            for ( String listedField : queryRecord.FieldApiNames__c.split( ',' ) ) {
                candidates.add( listedField.trim() );
            }
        }
        candidates.addAll( SandboxDataExportController.getAllAccessibleFields( queryRecord.SObjectApiName__c ) );
        for ( String candidate : candidates ) {
            if ( String.isNotBlank( candidate ) && addedFieldKeys.add( candidate.toLowerCase() ) ) {
                fields.add( candidate );
            }
        }
        if ( fields.isEmpty() ) {
            throw new AuraHandledException(
                'No accessible fields found for object: ' + queryRecord.SObjectApiName__c
            );
        }
        return fields;
    }

    private static String buildExportQuery( SandboxDataExportQuery__mdt queryRecord , List<String> fields ) {
        NSP_QueryBuilder builder = new NSP_QueryBuilder( queryRecord.SObjectApiName__c , fields );
        builder.setSecurityEnforce( false );
        if ( String.isNotBlank( queryRecord.OrderBy__c ) ) {
            builder.orderBy(
                queryRecord.OrderBy__c ,
                'ASC' ,
                false
            );
        }
        builder.addFilter(
            'NSP_External_Id__c' ,
            (Object)null ,
            NSP_QueryBuilder.Operator.NOT_EQUALS
        );
        return builder.build();
    }

    // @description Returns the API names of all FLS-accessible fields on the given sObject.
    // @param sObjectApiName API name of the target SObject.
    // @return Accessible field API names; empty list if the object is unknown or has no readable fields.
    @TestVisible
    private static List<String> getAllAccessibleFields( String sObjectApiName ) {
        List<String> fields = new List<String>();
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get( sObjectApiName );
        if ( sObjectType != null ) {
            Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
            for ( String fieldName : fieldMap.keySet() ) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get( fieldName ).getDescribe();
                Schema.DisplayType fieldType = fieldDescribe.getType();
                if ( fieldDescribe.isAccessible()
                    && fieldType != Schema.DisplayType.ADDRESS
                    && fieldType != Schema.DisplayType.LOCATION )
                {
                    fields.add( fieldName );
                }
            }
        }
        return fields;
    }

    @TestVisible
    private static String buildCsv( List<SObject> records , List<String> columns ) {
        String csv = '';
        if ( ( records != null )
            && !records.isEmpty()
            && ( columns != null )
            && !columns.isEmpty()
            )
        {
            List<String> rows = new List<String>();
            List<String> header = new List<String>();
            for ( String col : columns ) {
                header.add( SandboxDataExportController.escapeCsvValue( col ) );
            }
            rows.add( String.join( header , ',' ) );
            for ( SObject record : records ) {
                Map<String,Object> flatValues = SandboxDataExportController.flattenFieldValues(
                    record.getPopulatedFieldsAsMap()
                );
                List<String> cells = new List<String>();
                for ( String col : columns ) {
                    Object val = flatValues.get( col );
                    cells.add(
                        SandboxDataExportController.escapeCsvValue(
                            ( val == null ) ? '' : String.valueOf( val )
                        )
                    );
                }
                rows.add( String.join( cells , ',' ) );
            }
            csv = String.join( rows , '\n' );
        }
        return csv;
    }

    // Returns a flat map of column name -> value, expanding SObject values into
    // dot-notation entries. Non-SObject fields are passed through unchanged.
    @TestVisible
    private static Map<String, Object> flattenFieldValues( Map<String,Object> fieldMap ) {
        Map<String,Object> flat = new Map<String,Object>();
        if ( ( fieldMap != null ) && !fieldMap.isEmpty() ) {
            for ( String key : fieldMap.keySet() ) {
                Object val = fieldMap.get( key );
                if ( ( val != null ) && ( val instanceof SObject ) ) {
                    Map<String,Object> childFields = ( (SObject)val ).getPopulatedFieldsAsMap();
                    for ( String childKey : childFields.keySet() ) {
                        flat.put( key + '.' + childKey, childFields.get( childKey ) );
                    }
                } else {
                    flat.put( key , val );
                }
            }
        }
        return flat;
    }

    @TestVisible
    private static String escapeCsvValue( String value ) {
        String safe = ( ( value == null ) ? '' : value );
        return '"' + safe.replace( '"' , '""' ) + '"';
    }

}
//