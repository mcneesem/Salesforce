// **
// ** Filters a list of SObject records to only those the running user can edit.
// **
public with sharing class ObjectAccessFilter {
    // test w/ ObjectAccessFilterTest (100%)

    private static final Integer USER_RECORD_ACCESS_BATCH_SIZE = 200;
    private static final Integer DEFAULT_MAX_RECORDS = 2000;

    @InvocableMethod(label='Filter Editable Records' description='Filter out records running User is not allowed to update')
    public static List<FilterResult> filterEditableRecords( List<FilterInput> inputs ) {
        List<FilterResult> results = new List<FilterResult>();
        if ( inputs != null && !inputs.isEmpty() ) {
            for ( FilterInput input : inputs ) {
                FilterResult result = new FilterResult();
                Integer maxRecords = ( input.maxRecords != null && input.maxRecords > 0 )
                    ? input.maxRecords
                    : DEFAULT_MAX_RECORDS;
                List<SObject> truncatedRecords = ObjectAccessFilter.truncateList( input.records, maxRecords );
                result.editableRecords = ObjectAccessFilter.getEditableFromList( truncatedRecords );
                result.isTruncated = ( input.records != null && input.records.size() > maxRecords );
                results.add( result );
            }
        }
        return results;
    }

    public class FilterInput {
        @InvocableVariable(label='Records' description='List of SObject records to filter' required=true)
        public List<SObject> records;
        @InvocableVariable(label='Max Records' description='Maximum records to process (default 2000)')
        public Integer maxRecords;
    }

    public class FilterResult {
        @InvocableVariable(label='Editable Records' description='Records the running user can edit')
        public List<SObject> editableRecords;
        @InvocableVariable(label='Is Truncated' description='True if input exceeded max and was truncated')
        public Boolean isTruncated;
    }

    private static List<SObject> truncateList( List<SObject> records, Integer maxSize ) {
        List<SObject> result = new List<SObject>();
        if ( records != null && maxSize != null ) {
            Integer limit_size = Math.min( records.size(), maxSize );
            for ( Integer i = 0; i < limit_size; i++ ) {
                result.add( records[i] );
            }
        }
        return result;
    }

    private static List<SObject> getEditableFromList( List<SObject> candidates ) {
        List<SObject> editableRecords = new List<SObject>();
        if ( candidates != null && !candidates.isEmpty() ) {
            Set<Id> editableIds = ObjectAccessFilter.getEditableRecordIds( candidates );
            for ( SObject candidate : candidates ) {
                if ( editableIds != null && editableIds.contains( candidate.Id ) ) {
                    editableRecords.add( candidate );
                }
            }
        }
        return editableRecords;
    }

    private static Set<Id> getEditableRecordIds( List<SObject> candidates ) {
        Set<Id> editableIds = new Set<Id>();
        if ( candidates == null || candidates.isEmpty() ) {
            return editableIds;
        }
        List<Id> candidateIds = new List<Id>( new Map<Id, SObject>( candidates ).keySet() );
        List<List<Id>> batches = ObjectAccessFilter.batchIds( candidateIds, USER_RECORD_ACCESS_BATCH_SIZE );
        if ( batches != null ) {
            for ( List<Id> batch : batches ) {
                for ( UserRecordAccess access : [ // NOSONAR - UserRecordAccess has a 200-record platform limit per query
                    SELECT RecordId
                    FROM UserRecordAccess
                    WHERE UserId = :UserInfo.getUserId()
                    AND RecordId IN :batch
                    AND HasEditAccess = true
                    WITH SYSTEM_MODE
                ] ) {
                    editableIds.add( access.RecordId );
                }
            }
        }
        return editableIds;
    }

    private static List<List<Id>> batchIds( List<Id> ids, Integer batchSize ) {
        List<List<Id>> batches = new List<List<Id>>();
        if ( ids != null && batchSize != null && batchSize > 0 ) {
            Integer totalSize = ids.size();
            for ( Integer i = 0; i < totalSize; i += batchSize ) {
                Integer endIndex = Math.min( i + batchSize, totalSize );
                List<Id> batch = new List<Id>();
                for ( Integer j = i; j < endIndex; j++ ) {
                    batch.add( ids[j] );
                }
                batches.add( batch );
            }
        }
        return batches;
    }

}