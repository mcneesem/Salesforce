public with sharing class BoxCreateFolderForRecordIdFromTemplate {
    // test w/ BoxWrapperTest (100%)

    @InvocableMethod(label='Box Create Folder For Record Id From Template' description='Creates a Box folder for a specified Record Id from a template folder.')
    public static List<box.CreateFolderForRecordIdFromTemplate_v2.Response> createFolderForRecordIdFromTemplate(List<box.CreateFolderForRecordIdFromTemplate_v2.Request> requests) {
        List<box.CreateFolderForRecordIdFromTemplate_v2.Response> responses = null;
        try {
            responses = box.CreateFolderForRecordIdFromTemplate_v2.tkCreateFolderForRecordIdFromTemplate( requests );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                BoxCreateCollaborationOnRecord.class.getName() ,
                'createFolderForRecordIdFromTemplate' ,
                e
            );
        }
        return responses;
    }

}
//