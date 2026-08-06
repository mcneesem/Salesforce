// intentionally `without sharing` to prevent ~ DUPLICATES_DETECTED: You're creating a duplicate record.
public without sharing class FindDuplicatesAction {
    // test w/ FindDuplicatesActionTest (82%)

    @InvocableMethod(label='Find Duplicates' description='Find records that duplicate the given record.')
    public static List<FindDuplicatesResponse> invoke( List<FindDuplicatesRequest> requests ) {
        List<FindDuplicatesResponse> responses = new List<FindDuplicatesResponse>();
        if ( ( requests != null ) && !requests.isEmpty() ) {
            for ( FindDuplicatesRequest request : requests ) {
                responses.add(
                    FindDuplicatesAction.findDuplicates( request.record )
                );
            }
        }
        return responses;
    }

    private static FindDuplicatesResponse findDuplicates( sObject record ) {
        FindDuplicatesResponse response = new FindDuplicatesResponse();
        try {
            response.duplicateIds = FindDuplicatesAction.matchRecords( record );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                FindDuplicatesAction.class.getName() ,
                'findDuplicates' ,
                e
            );
        }
        return response;
    }

    private static List<Id> matchRecords( sObject record ) {
        List<sObject> records = new List<sObject>();
        if ( record != null ) {
            records = new List<sObject>{ record };
        }
        List<sObject> matches = new List<sObject>();
        for ( Datacloud.FindDuplicatesResult fdResult : Datacloud.FindDuplicates.findDuplicates( records ) ) {
            for ( Datacloud.DuplicateResult dResult : fdResult.getDuplicateResults() ) {
                for ( Datacloud.MatchResult mResult : dResult.getMatchResults() ) {
                    for ( Datacloud.MatchRecord mRecord : mResult.getMatchRecords() ) {
                        matches.add( mRecord.getRecord() );
                    }
                }
            }
        }
        Set<Id> matchIds = new Set<Id>();
        if ( !matches.isEmpty() ) {
            for ( sObject match : matches ) {
                matchIds.add( match.Id );
            }
        }
        return matchIds;
    }

    public class FindDuplicatesRequest {
        @InvocableVariable(label='Record' description='Record for duplicate checking' required=true)
        public sObject record;
    }

    public class FindDuplicatesResponse {
        @InvocableVariable(label='Duplicate Ids' description='List of duplicate records Ids' required=true)
        public List<Id> duplicateIds;
    }

}
//