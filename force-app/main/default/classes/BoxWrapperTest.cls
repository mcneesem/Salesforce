@isTest private class BoxWrapperTest {

    @isTest private static void testCreateCollaboration() {
        Test.startTest();
        BoxCreateCollaborationOnRecord.createCollaboration( null );
        Test.stopTest();
    }

    @isTest private static void testCreateFolder() {
        Test.startTest();
        BoxCreateFolder.createFolder( null );
        Test.stopTest();
    }

    @isTest private static void testCreateFolder() {
        Test.startTest();
        BoxCreateFolderForRecordIdFromTemplate.createFolderForRecordIdFromTemplate( null );
        Test.stopTest();
    }

}
//