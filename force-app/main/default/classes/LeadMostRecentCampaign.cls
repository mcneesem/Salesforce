public with sharing class LeadMostRecentCampaign {
    // test w/ LeadMostRecentCampaignTest (84%)

    @InvocableMethod(label='Lead Most Recent Campaign' description='Updates the Most Recent Campaign field on a given Lead.')
    public static void updateMostRecentCampaign(List<Request> requests) {
        try {
            Map<Id,String> campaignMap = new Map<Id,String>();
            if ( ( requests != null ) && !requests.isEmpty() ) {
                for ( Request req : requests ) {
                    campaignMap.put( req.leadId , req.campaignName );
                }
            }
            List<Lead> records = null;
            if ( !campaignMap.isEmpty() ) {
                records = [
                    SELECT Id , Most_Recent_Campaign__c
                    FROM Lead
                    WHERE ( Id IN :campaignMap.keySet() )
                ];
            }
            List<Lead> modifiedRecords = LeadMostRecentCampaign.buildModifiedRecords(
                records ,
                campaignMap
            );
            if ( ( modifiedRecords != null ) && !modifiedRecords.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( modifiedRecords , false );
                NSP_ErrorLogHandler.logResults(
                    LeadMostRecentCampaign.class.getName() ,
                    'updateMostRecentCampaign:update' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                LeadMostRecentCampaign.class.getName() ,
                'updateMostRecentCampaign' ,
                e
            );
        }
    }

    private static List<Lead> buildModifiedRecords( List<Lead> records , Map<Id,String> campaignMap ) {
        List<Lead> modifiedRecords = new List<Lead>();
        if ( ( campaignMap != null )
            && ( records != null )
            && !records.isEmpty()
            )
        {
            for ( Lead record : records ) {
                String campaignName = null;
                if ( campaignMap.containsKey( record.Id ) ) {
                    campaignName = campaignMap.get( record.Id );
                }
                if ( record.Most_Recent_Campaign__c != campaignName ) {
                    modifiedRecords.add(
                        new Lead(
                            Id=record.Id ,
                            Most_Recent_Campaign__c=campaignName
                        )
                    );
                }
            }
        }
        return modifiedRecords;
    }

    public class Request {
        @InvocableVariable(label='Lead Id' description='Id of the Lead to modify' required=true)
        public Id leadId;
        @InvocableVariable(label='Most Recent Campaign Name' description='Name of the Most Recent Campaign')
        public String campaignName;
    }

}
//