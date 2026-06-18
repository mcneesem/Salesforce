/**
 * @AuraEnabled controller for the nsp_dataExportTool LWC.
 * Reads active DataExportQuery__mdt records and executes their stored SOQL
 * queries, returning each result set as a CSV string for client-side download.
 *
 * Security: with sharing + AccessLevel.USER_MODE on all dynamic queries.
 * CMT access uses built-in static methods (no SOQL on __mdt types).
 */
public with sharing class DataExportController {
    // test w/ DataExportControllerTest (TBD%)

    private static final String CLASS_NAME = DataExportController.class.getName();
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
         * @param rec Active DataExportQuery__mdt record to wrap
         */
        public ExportDefinition(DataExportQuery__mdt rec) {
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
     * Returns all active DataExportQuery__mdt definitions sorted by SortOrder__c.
     * Called on LWC initialisation to populate the export table.
     *
     * @return Ordered list of ExportDefinition wrappers
     * @example
     * List<DataExportController.ExportDefinition> defs =
     *     DataExportController.getExportDefinitions();
     */
    @AuraEnabled(cacheable=true)
    public static List<ExportDefinition> getExportDefinitions() {
        List<ExportDefinition> definitions = new List<ExportDefinition>();
        try {
            List<ExportDefinition> active = new List<ExportDefinition>();
            for (DataExportQuery__mdt rec : DataExportQuery__mdt.getAll().values()) {
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
     * Executes the SOQL query stored in the named DataExportQuery__mdt record
     * and returns the results as a CSV-formatted string ready for download.
     *
     * @param developerName DeveloperName of the DataExportQuery__mdt record to run
     * @return CSV string with a header row followed by one data row per record
     * @example
     * String csv = DataExportController.executeExport('Account_Master');
     */
    @AuraEnabled
    public static String executeExport(String developerName) {
        String csvResult = '';
        try {
            if (String.isBlank(developerName)) {
                throw new AuraHandledException('Export name is required.');
            }
            DataExportQuery__mdt queryRecord = DataExportQuery__mdt.getInstance(developerName);
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
                'Export failed for "' + developerName + '". Please contact your administrator.'
            );
        }
        return csvResult;
    }

    // ------------------------------------------------------------
    // Private helpers
    // ------------------------------------------------------------

    /**
     * Converts a list of SObject records into a CSV string.
     * The first row is a header derived from the populated field map keys.
     * Values containing commas, double-quotes, or newlines are enclosed in
     * double quotes; embedded double-quotes are escaped by doubling them.
     *
     * @param records Query results to serialise
     * @return CSV-formatted string, or empty string when records is empty
     */
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

    /**
     * Wraps a string value in double quotes and escapes any embedded double
     * quotes by doubling them (RFC 4180).
     *
     * @param value Raw cell value; null is treated as empty string
     * @return Value enclosed in double quotes with internal quotes escaped
     */
    private static String escapeCsvValue(String value) {
        String safe = (value == null) ? '' : value;
        return QUOTE + safe.replace(QUOTE, DBL_QUOTE) + QUOTE;
    }
}