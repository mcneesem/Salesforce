@isTest
private class TerminationEmailBatchTest {

    @testSetup
    private static void createTestData() {

        String title = 'LTR-Default_Termination_Attachment';

        // Create Termination form record
        NSP_Termination_Form__c form = new NSP_Termination_Form__c();
        form.NSP_Status__c = 'Term Team Approved';
        form.Name = 'Test Form';
        form.Termination_Email_Status__c = 'Ready to be sent';
        form.NSP_Revision__c = 'Yes';
        form.Client_Owner_Email__c = 'owner@example.com';
        form.NSP_Last_Date_Wages_Paid_Through__c = Date.newInstance(2025,12,31);
        form.RecordTypeId = Schema.getGlobalDescribe().get( 'NSP_Termination_Form__c' )
                                .getDescribe()
                                .getRecordTypeInfosByDeveloperName()
                                .get( 'NSP_Credit_Specialist_Form' )
                                .getRecordTypeId();
        insert form;

        // Utility: ensure Custom Setting instance for this running user
        TerminationEmailBatchSettings__c cs = new TerminationEmailBatchSettings__c(
            SetupOwnerId = UserInfo.getUserId(),
            BatchSize__c = 10,
            isEnabled__c = true,
            OrgWideEmailAddressId__c =  UserInfo.getUserId()
        );
        insert cs;
    }

    @isTest
    private static void terminate(){
        test.startTest();
        TerminationEmailBatch.schedule();
        test.stopTest();
    }

}
//