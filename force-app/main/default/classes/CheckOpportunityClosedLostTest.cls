@isTest
private class CheckOpportunityClosedLostTest {

    @isTest
    private static void testCheckOpportunityClosedLost() {
        Account acnt=NSP_TestHelper.createAccount(true);
        // Create a test opportunity
        Opportunity opp = NSP_TestHelper.createOpenOpportunity(acnt.Id,'New Product',false);
        opp.StageName = 'Prospecting';
        opp.NSP_Number_of_Employees__c=12;
        opp.NSP_BidNumber__c='123';
        opp.NSP_PrimaryProduct__c = 'WS';
        opp.NSP_Partner__c=acnt.Id;
        insert opp;

        // Create a CheckStageRequest input
        CheckOpportunityClosedLost.CheckStageRequest request = new CheckOpportunityClosedLost.CheckStageRequest();
        request.oppRecordId = opp.Id;

        // Prepare the input list
        List<CheckOpportunityClosedLost.CheckStageRequest> requests = new List<CheckOpportunityClosedLost.CheckStageRequest>();
        requests.add(request);

        // Call the method under test
        Test.startTest();
        OpportunityStageSettings__c setting = new OpportunityStageSettings__c();
        setting.Is_Enabled_WO_WS_Stage_Entry__c = true;
        insert setting;
        List<CheckOpportunityClosedLost.CheckStageResponse> responses = CheckOpportunityClosedLost.checkOpportunityClosedLost(requests);
        Test.stopTest();

        // Verify the response
        System.assertNotEquals(null, responses, 'Response should not be null');
        System.assertEquals(1, responses.size(), 'There should be one response');
        System.assertEquals(true, responses[0].checkStage, 'The stage check should return true');
    }

}
//