// intentionally `without sharing` to prevent ~ INSUFFICIENT_ACCESS_OR_READONLY, insufficient access rights on object id
public without sharing class LeadLastActivityDateHelper {
    // test w/ LeadLastActivityDateHelperTest, NSP_TaskTriggerHelperTest, NSP_EventTriggerHelperTest (86%)
    // test w/ LeadLastActivityDateHelperTest (86%)
    // test w/ NSP_TaskTriggerHelperTest (86%)
    // test w/ NSP_EventTriggerHelperTest (86%)

    public static void updateLeadLastActivityDate( Set<Id> whoIds ) {
        try {
            Set<String> statusValues = new Set<String>{ 'Nurturing', 'Unqualified'};
            List<Lead> relatedLeads = null;
            if ( ( whoIds != null ) && !whoIds.isEmpty() ) {
                relatedLeads = [
                    SELECT Id , DNB_Connect_DUNS_Number__c , LastActivityDate
                    FROM Lead
                    WHERE (
                        ( Id IN : whoIds )
                        AND ( DNB_Connect_DUNS_Number__c != null )
                        AND ( LastActivityDate != null )
                        AND (
                            (NSP_Reason__c != null)
                            OR
                            ( Status NOT IN :statusValues )
                        )
                    )
                ];
            }
            Map<String,Date> lastActivityDateMap = new Map<String,Date>();
            if ( ( relatedLeads != null ) && !relatedLeads.isEmpty() ) {
                for ( Lead relatedLead : relatedLeads ) {
                    lastActivityDateMap.put(
                        relatedLead.DNB_Connect_DUNS_Number__c ,
                        relatedLead.LastActivityDate
                    );
                }
            }
            LeadLastActivityDateHelper.updateLeadLastActivityDate( lastActivityDateMap );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_EventTriggerHelper.class.getName() ,
                'updateLeadLastActivityDate' ,
                e
            );
        }
    }

    private static void updateLeadLastActivityDate( Map<String,Date> lastActivityDateMap ) {
        List<Lead> leadsWithDuns = null;
        if ( ( lastActivityDateMap != null ) && !lastActivityDateMap.isEmpty() ) {
            leadsWithDuns = [
                SELECT Id , DNB_Connect_DUNS_Number__c , LastActivityDate , NSP_Last_Activity__c
                FROM Lead
                WHERE ( DNB_Connect_DUNS_Number__c IN :lastActivityDateMap.keySet() )
                ORDER BY LastActivityDate DESC NULLS LAST
            ];
        }
        List<Lead> leadsToUpdate = new List<Lead> ();
        if ( ( leadsWithDuns != null ) && !leadsWithDuns.isEmpty() ) {
            Date leadLastActivityDate = leadsWithDuns[0].LastActivityDate;
            if ( leadLastActivityDate != null ) {
                for ( Lead leadWithDuns : leadsWithDuns ) {
                    if ( leadWithDuns.NSP_Last_Activity__c != leadLastActivityDate ) {
                        leadWithDuns.NSP_Last_Activity__c = leadLastActivityDate;
                        leadsToUpdate.add( leadWithDuns );
                    }
                }
            }
        }
        if ( !leadsToUpdate.isEmpty() ) {
            // `with sharing` throws ~ INSUFFICIENT_ACCESS_OR_READONLY, insufficient access rights on object id
            List<Database.SaveResult> results = Database.update( leadsToUpdate , false );
            NSP_ErrorLogHandler.logResults(
                LeadLastActivityDateHelper.class.getName() ,
                'updateLeadLastActivityDate:update' ,
                results
            );
        }
    }

}
//
