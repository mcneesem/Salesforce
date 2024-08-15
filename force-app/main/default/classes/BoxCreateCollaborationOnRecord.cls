public with sharing class BoxCreateCollaborationOnRecord {
    // test w/ BoxWrapperTest (100%)

    @InvocableMethod(label='Box Create Collaboration On Record' description='Creates a Box collaboration for a specified Salesforce Record Id, Box User Id, and Collaboration Type.')
    public static List<box.CreateCollaborationOnRecord_v2.Response> createCollaboration( List<box.CreateCollaborationOnRecord_v2.Request> requests ) {
        List<box.CreateCollaborationOnRecord_v2.Response> responses = null;
        try {
            responses = box.CreateCollaborationOnRecord_v2.tkCreateCollaborationOnRecord( requests );
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