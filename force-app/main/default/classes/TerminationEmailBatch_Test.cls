@isTest
private class TerminationEmailBatch_Test {

    @TestSetup
    private static void createTestData() {

        String title = 'LTR-Default_Termination_Attachment';

        // Utility: ensure Custom Setting instance for this running user
        TerminationEmailBatchSettings__c cs = new TerminationEmailBatchSettings__c(
            SetupOwnerId = UserInfo.getUserId(),
            BatchSize__c = 10,
            isEnabled__c = true,
            orgWideEmailAddress__c = 'test@gmail.com',
            DefaultAttachmentName__c = title
        );
        insert cs;

        // Create Termination form record
        NSP_Termination_Form__c form = new NSP_Termination_Form__c();
        form.NSP_Status__c = 'Term Team Approved';
        form.Name = 'Test Form';
        form.Termination_Email_Status__c = 'Ready to be sent';
        form.NSP_Revision__c = 'Yes';
        form.Client_Owner_Email__c = 'owner@example.com';
        form.RecordTypeId = Schema.getGlobalDescribe().get( 'NSP_Termination_Form__c' )
                                .getDescribe()
                                .getRecordTypeInfosByDeveloperName()
                                .get( 'NSP_Client_Reinstatement' )
                                .getRecordTypeId();
        insert form;

        // Attach an optional doc to one of the records
        ContentVersion cv = new ContentVersion(
            Title = title,
            PathOnClient = title + '.pdf',
            VersionData = Blob.valueOf('PDF bytes')
        );
        insert cv;

        ContentVersion latest = [
            SELECT Id, 
                ContentDocumentId,
                Title
            FROM ContentVersion
            WHERE Id =: cv.Id
        ];

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = form.Id,
            ContentDocumentId = latest.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
      
    }

    @isTest private static void terminate(){
        test.startTest();
        TerminationEmailBatch.schedule();
        test.stopTest();
    }

}