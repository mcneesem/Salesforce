public with sharing class BoxCreateFolder {
    // test w/ BoxWrapperTest (100%)

    @InvocableMethod(label='Box Create Folder' description='Creates a new Box folder in the specified parent folder.')
    public static List<box.CreateFolder_v2.Response> createFolder(List<box.CreateFolder_v2.Request> requests) {
        List<box.CreateFolder_v2.Response> responses = null;
        try {
            responses = box.CreateFolder_v2.tkCreateFolder( requests );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                BoxCreateCollaborationOnRecord.class.getName() ,
                'createFolder' ,
                e
            );
        }
        return responses;
    }

}
//