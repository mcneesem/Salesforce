/**
 * @AuraEnabled controller for the sandboxDataExportTool LWC.
 * Reads active SandboxDataExportQuery__mdt records and executes their stored SOQL
 * queries, returning each result set as a CSV string for client-side download.
 *
 * Security: with sharing + AccessLevel.USER_MODE on all dynamic queries.
 * CMT access uses built-in static methods (no SOQL on __mdt types).
 */
public with sharing class SandboxDataExportController {
    // test w/ SandboxDataExportControllerTest (TBD%)

    private static final String CLASS_NAME = SandboxDataExportController.class.getName();
    private static final String QUOTE      = '"';
    private static final String DBL_QUOTE  = '""';
    private static final String COMMA      = ',';
    private static final String NEWLINE    = '\n';

    // ------------------------------------------------------------
    // Inner DTO
    // ------------------------------------------------------------

    /**
     * Lightweight DTO sent to the LWC to populate the export table.
     * Implements Comparable so the list can be sorted by SortOrder__c.
     */
    public class ExportDefinition implements Comparable {
        /** Human-readable label from the CMT record. */
        @AuraEnabled public String  label;
        /** DeveloperName — used as the key when calling executeExport. */
        @AuraEnabled public String  developerName;
        /** Desired CSV filename without the .csv extension. */
        @AuraEnabled public String  fileName;
        /** Execution order; lower values run first. */
        @AuraEnabled public Integer sortOrder;

        /**
         * @param rec Active SandboxDataExportQuery__mdt record to wrap
         */
        public ExportDefinition(SandboxDataExportQuery__mdt rec) {
            label         = rec.Label;
            developerName = rec.DeveloperName;
            fileName      = rec.FileName__c;
            sortOrder     = (rec.SortOrder__c != null) ? rec.SortOrder__c.intValue() : 9999;
        }

        /**
         * Sorts ascending by sortOrder.
         * @param compareTo Object to compare against
         * @return Negative if this comes first, positive if other comes first
         */
        public Integer compareTo(Object compareTo) {
            ExportDefinition other = (ExportDefinition) compareTo;
            return sortOrder - other.sortOrder;
        }
    }

    // ------------------------------------------------------------
    // AuraEnabled methods
    // ------------------------------------------------------------

    /**
     * Returns all active SandboxDataExportQuery__mdt definitions sorted by SortOrder__c.
     * Called on LWC initialisation to populate the export table.
     *
     * @return Ordered list of ExportDefinition wrappers
     */
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

    /**
     * Executes the SOQL query stored in the named SandboxDataExportQuery__mdt record
     * and returns the results as a CSV-formatted string ready for download.
     *
     * @param developerName DeveloperName of the SandboxDataExportQuery__mdt record to run
     * @return CSV string with a header row followed by one data row per record
     */
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
            List<SObject> records = Database.query(
                queryRecord.SOQLQuery__c.trim(),
                AccessLevel.USER_MODE
            );
            csvResult = buildCsv(records);
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

    private static String buildCsv(List<SObject> records) {
        String csv = '';
        if (records != null && !records.isEmpty()) {
            List<String> fieldNames = new List<String>(
                records[0].getPopulatedFieldsAsMap().keySet()
            );
            fieldNames.sort();

            List<String> rows = new List<String>();
            List<String> header = new List<String>();
            for (String fieldName : fieldNames) {
                header.add(escapeCsvValue(fieldName));
            }
            rows.add(String.join(header, COMMA));

            for (SObject record : records) {
                Map<String, Object> fieldValues = record.getPopulatedFieldsAsMap();
                List<String> cells = new List<String>();
                for (String fieldName : fieldNames) {
                    Object val = fieldValues.get(fieldName);
                    cells.add(escapeCsvValue(val == null ? '' : String.valueOf(val)));
                }
                rows.add(String.join(cells, COMMA));
            }
            csv = String.join(rows, NEWLINE);
        }
        return csv;
    }

    private static String escapeCsvValue(String value) {
        String safe = (value == null) ? '' : value;
        return QUOTE + safe.replace(QUOTE, DBL_QUOTE) + QUOTE;
    }
}
