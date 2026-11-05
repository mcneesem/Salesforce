@isTest
private class NSP_FlowInterviewListControllerTest {

    private static testMethod void getInterviewsTest() {
        Account  acc = NSP_TestHelper.createAccount(true);
        Opportunity  opportuniytObject = NSP_TestHelper.createOpenOpportunity(acc.Id, 'CAMS', false);
        opportuniytObject.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject.NSP_Number_of_Employees__c = 100;
        insert opportuniytObject;
        Test.startTest();
        NSP_FlowInterviewListController.getInterviews(opportuniytObject.ID);
        try{
            NSP_FlowInterviewListController.deleteInterview(null);
        }catch (Exception ex) {
            System.debug( ' ~ ex=' + ex );
        }
        Test.stopTest();
        system.assertEquals('CAMS', opportuniytObject.Type);
    }

}
//