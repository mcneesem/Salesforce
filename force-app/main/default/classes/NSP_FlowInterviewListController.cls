// intentionally `without sharing` to preserve default sharing at api version 53...
public without sharing class NSP_FlowInterviewListController {
    // test w/ NSP_FlowInterviewListControllerTest (84%)

    @AuraEnabled
    public static List<FlowRecordRelation> getInterviews( String recordId ) {
        List<FlowRecordRelation> records = new List<FlowRecordRelation>();
        try {
            // Return paused flows where run as user was "paused" user and for the related record
            records = [
                SELECT
                    ParentId ,
                    Parent.InterviewLabel ,
                    Parent.PauseLabel ,
                    Parent.CurrentElement ,
                    Parent.CreatedDate ,
                    Parent.Owner.Name
                FROM FlowRecordRelation
                WHERE (
                    ( RelatedRecordId = :recordId )
                    AND ( CreatedById = :UserInfo.getUserId() )
                )
            ];
        } catch ( Exception e ) {
            throw new AuraHandledException( 'Error occured: ' + e.getMessage() );
        }
        return records;
    }

    @AuraEnabled
    public static FlowInterview deleteInterview( Id interviewId ) {
        FlowInterview interview = null;
        try {
            //allows users to remove thier own paused interviews
            List<FlowInterview> interviews = [
                SELECT Id
                FROM FlowInterview
                WHERE ( Id = :interviewId )
            ];
            if ( !interviews.isEmpty() ){
                interview = interviews[0];
                delete interview;
            }
        } catch ( Exception e ) {
            throw new AuraHandledException( 'Error occured: ' + e.getMessage() );
        }
        return interview;
    }

}
//
