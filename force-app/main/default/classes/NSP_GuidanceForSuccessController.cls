// intentionally `without sharing` to ensure that aura/NSP_OpportunityGuidanceForSuccess has access to all NSP_Opportunity_Stage_Guidance_Path__mdt records.
public without sharing class  NSP_GuidanceForSuccessController {
    // test w/ NSP_GuidanceForSuccessControllerTest (86%)

    //
    // Description: This method queries the guidance for success from the custom metadata NSP_Opportunity_Stage_Guidance_Path__mdt
    // @param: stageName
    // @param: productId
    // @param: segmentId
    // @return: guidance message (String)
    //
    @AuraEnabled
    public static String getMessage( String stageName , String primaryProduct , String accountSegment ) {
        String segment = ( String.isNotBlank( accountSegment ) ? accountSegment : null );
        String message = '';
        try {
            if ( String.isNotBlank( stageName ) && String.isNotBlank( primaryProduct ) ) {
                // Get guidance text
                List<NSP_Opportunity_Stage_Guidance_Path__mdt> guidanceMessages = [
                    SELECT NSP_Message__c
                    FROM NSP_Opportunity_Stage_Guidance_Path__mdt
                    WHERE (
                        NSP_StageName__c = :stageName
                        AND NSP_PrimaryProduct__c = :primaryProduct
                        AND NSP_Account_Segment__c = :segment
                        AND NSP_Is_Active__c = true
                    )
                ];
                //  If not found then get default guidance text (non techology product)
                if ( guidanceMessages.isEmpty() ) {
                    guidanceMessages = [
                        SELECT NSP_Message__c
                        FROM NSP_Opportunity_Stage_Guidance_Path__mdt
                        WHERE (
                            NSP_StageName__c = :stageName
                            AND NSP_PrimaryProduct__c = 'Technology'
                            AND NSP_Is_Active__c = true
                        )
                    ];
                }
                if ( !guidanceMessages.isEmpty() ) {
                    message = guidanceMessages[0].NSP_Message__c;
                }
            }
        } catch ( Exception e ) {
            throw new AuraHandledException( 'Exceptions occured: ' + e.getMessage() );
        }
        return message;
    }

}
//