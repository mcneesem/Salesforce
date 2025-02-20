public with sharing class BoxCreateCollaborationOnRecord {
    // test w/ BoxWrapperTest (100%)

    @InvocableMethod(label='Box Create Collaboration On Record' description='Creates a Box collaboration for a specified Salesforce Record Id, Box User Id, and Collaboration Type.')
    public static List<box.CreateCollaborationOnRecord_v2.Response> createCollaboration( List<box.CreateCollaborationOnRecord_v2.Request> requests ) {
        List<box.CreateCollaborationOnRecord_v2.Response> responses = null;
        try {
            // prevent ~ box.Toolkit.BoxApiException: Requested Salesforce user has not set up their connection to Box
            // ~ ignore actions invoked by the 'Automated Process' User...
            if ( UserInfo.getCurrentUvid() != '0054x000002pCZ9AAM' ) {
                responses = box.CreateCollaborationOnRecord_v2.tkCreateCollaborationOnRecord( requests );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                BoxCreateCollaborationOnRecord.class.getName() ,
                'createCollaboration' ,
                e
            );
        }
        return responses;
    }
}
//