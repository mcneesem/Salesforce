public with sharing class SandboxDataExportController {
    // test w/ SandboxDataExportControllerTest (90%)

    private static final String CLASS_NAME = SandboxDataExportController.class.getName();
    private static final String QUOTE      = '"';
    private static final String DBL_QUOTE  = '""';
    private static final String COMMA      = ',';
    private static final String NEWLINE    = '\n';

    public class ExportDefinition implements Comparable {
        @AuraEnabled public String  label;
        @AuraEnabled public String  developerName;
        @AuraEnabled public String  fileName;
        @AuraEnabled public Integer sortOrder;

        public ExportDefinition(SandboxDataExportQuery__mdt rec) {
            label         = rec.Label;
            developerName = rec.DeveloperName;
            fileName      = rec.FileName__c;
            sortOrder     = (rec.SortOrder__c != null) ? rec.SortOrder__c.intValue() : 9999;
        }

        // Sorts ascending by sortOrder
        public Integer compareTo(Object compareTo) {
            ExportDefinition other = (ExportDefinition) compareTo;
            return sortOrder - other.sortOrder;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ExportDefinition> getExportDefinitions() {
        List<ExportDefinition> definitions = new List<ExportDefinition>();
        try {
            List<ExportDefinition> active = new List<ExportDefinition>();
            for (SandboxDataExportQuery__mdt rec : SandboxDataExportQuery__mdt.getAll().values()) {
                if (rec.IsActive__c) {
                    active.add(new ExportDefinition(rec));
                }
            }
            active.sort();
            definitions = active;
        } catch (Exception e) {
            NSP_ErrorLogHandler.logException(CLASS_NAME, 'getExportDefinitions', e);
            throw new AuraHandledException(
                'Unable to load export definitions. Please contact your administrator.'
            );
        }
        return definitions;
    }

    // Executes the SOQL query stored in the named SandboxDataExportQuery__mdt record
    // and returns the results as a CSV-formatted string ready for download.
    @AuraEnabled
    public static String executeExport(String developerName) {
        String csvResult = '';
        try {
            if (String.isBlank(developerName)) {
                throw new AuraHandledException('Export name is required.');
            }
            List<SandboxDataExportQuery__mdt> queryRecords = [
                SELECT SOQLQuery__c, FileName__c
                FROM SandboxDataExportQuery__mdt
                WHERE DeveloperName = :developerName
                AND IsActive__c = true
                LIMIT 1
            ];
            SandboxDataExportQuery__mdt queryRecord = queryRecords.isEmpty() ? null : queryRecords[0];
            if (queryRecord == null || String.isBlank(queryRecord.SOQLQuery__c)) {
                throw new AuraHandledException(
                    'Export definition not found or has no query configured: ' + developerName
                );
            }
            String soql = queryRecord.SOQLQuery__c.trim();
            List<SObject> records = Database.query(soql, AccessLevel.USER_MODE);
            csvResult = buildCsv(records, soql);
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            NSP_ErrorLogHandler.logException(CLASS_NAME, 'executeExport', e);
            throw new AuraHandledException(
                'Export failed for "' + developerName + '": ' + e.getMessage()
            );
        }
        return csvResult;
    }

    // ------------------------------------------------------------
    // Private helpers
    // ------------------------------------------------------------

    @TestVisible
    private static String buildCsv(List<SObject> records, String soql) {
        String csv = '';
        if (records != null && !records.isEmpty()) {
            List<String> columns = parseSelectColumns(soql);

            List<String> rows = new List<String>();
            List<String> header = new List<String>();
            for (String col : columns) {
                header.add(escapeCsvValue(col));
            }
            rows.add(String.join(header, COMMA));

            for (SObject record : records) {
                Map<String, Object> flatValues = flattenFieldValues(record.getPopulatedFieldsAsMap());
                List<String> cells = new List<String>();
                for (String col : columns) {
                    Object val = flatValues.get(col);
                    cells.add(escapeCsvValue(val == null ? '' : String.valueOf(val)));
                }
                rows.add(String.join(cells, COMMA));
            }
            csv = String.join(rows, NEWLINE);
        }
        return csv;
    }

    // Parses the SELECT clause to return columns in the order they appear in the query.
    @TestVisible
    private static List<String> parseSelectColumns(String soql) {
        String upper = soql.toUpperCase();
        Integer selectIdx = upper.indexOf('SELECT') + 6;
        Integer fromIdx   = upper.indexOf(' FROM ');
        String fieldsPart = soql.substring(selectIdx, fromIdx).trim();
        List<String> columns = new List<String>();
        for (String col : fieldsPart.split(',')) {
            columns.add(col.trim());
        }
        return columns;
    }

    // Returns a flat map of column name -> value, expanding SObject values into
    // dot-notation entries. Non-SObject fields are passed through unchanged.
    @TestVisible
    private static Map<String, Object> flattenFieldValues(Map<String, Object> fieldMap) {
        Map<String, Object> flat = new Map<String, Object>();
        for (String key : fieldMap.keySet()) {
            Object val = fieldMap.get(key);
            if (val instanceof SObject) {
                Map<String, Object> childFields = ((SObject) val).getPopulatedFieldsAsMap();
                for (String childKey : childFields.keySet()) {
                    flat.put(key + '.' + childKey, childFields.get(childKey));
                }
            } else {
                flat.put(key, val);
            }
        }
        return flat;
    }

    @TestVisible
    private static String escapeCsvValue(String value) {
        String safe = (value == null) ? '' : value;
        return QUOTE + safe.replace(QUOTE, DBL_QUOTE) + QUOTE;
    }
}
