/* Name: NSP_FlowInterviewListController
Purpose: Supports NSP_FlowInterviewList component for retrieving paused flow interviews, by user, to be resumed
Author: Ryan Del Mauro
Create Date: 2021-12-06
Modify History:
2021-12-06   Ryan Del Mauro	Created
*/
public class NSP_FlowInterviewListController {
    // test w/ NSP_FlowInterviewListControllerTest (84%)
    @AuraEnabled
    public static List<FlowRecordRelation> getInterviews(String recordId) {
        List<FlowRecordRelation> FlowRecordRelationList = new List<FlowRecordRelation>();
        //get run as user
        Id userId = UserInfo.getUserId();
        try{
            // Return paused flows where run as user was "paused" user and for the related record
            FlowRecordRelationList =  [ SELECT
                                       ParentId, Parent.InterviewLabel, Parent.PauseLabel,
                                       Parent.CurrentElement, Parent.CreatedDate, Parent.Owner.Name
                                       FROM FlowRecordRelation
                                       WHERE RelatedRecordId = :recordId
                                       AND CreatedById =: userId ];
        }catch (Exception ex) {throw new AuraHandledException(System.label.NSP_Error_Message + ''+ex.getMessage());}
        return FlowRecordRelationList;

    }

    @AuraEnabled
    public static FlowInterview deleteInterview(Id interviewId) {
        try{
            //allows users to remove thier own paused interviews
            List<FlowInterview> interviews = [SELECT Id FROM FlowInterview WHERE Id = :interviewId];
            FlowInterview interview = null;
            if(!interviews.isEmpty()){
                interview = interviews[0];
            }
            delete interview;
            return interview;
        }catch (Exception ex) {
            throw new AuraHandledException(System.label.NSP_Error_Message + ''+ex.getMessage());
        }
    }
}