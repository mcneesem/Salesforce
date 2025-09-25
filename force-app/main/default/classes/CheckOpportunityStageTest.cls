@isTest
public class CheckOpportunityStageTest {

    @isTest
    static void testCheckOpportunityStagePositive() {
        Account acnt=NSP_TestHelper.createAccount(true);
        // Create a test opportunity

        Opportunity opp = NSP_TestHelper.createOpenOpportunity(acnt.Id,'New Product',false);
        opp.StageName = 'Prospecting';
        opp.NSP_Number_of_Employees__c = 12;
        opp.NSP_BidNumber__c = '123';
        opp.NSP_PrimaryProduct__c = 'WS';
        opp.NSP_Partner__c = acnt.Id;
        insert opp;

        // Create a CheckStageRequest input
        CheckOpportunityStage.CheckStageRequest request = new CheckOpportunityStage.CheckStageRequest();
        request.oppRecordId = opp.Id;
        request.stageName = 'Prospecting';
        // Prepare the input list
        List<CheckOpportunityStage.CheckStageRequest> requests = new List<CheckOpportunityStage.CheckStageRequest>();
        requests.add(request);
        // Call the method under test
        Test.startTest();
        List<CheckOpportunityStage.CheckStageResponse> responses = CheckOpportunityStage.checkOpportunityStage(requests);
        Test.stopTest();
        // Verify the response
        System.assertNotEquals( null , responses , 'Response should not be null' );
        System.assertEquals( 1 , responses.size() , 'There should be one response' );
        System.assertEquals( true , responses[0].checkStage , 'The stage check should return true' );
    }

    @isTest
    static void testCheckOpportunityStageNegative() {
        Account acnt=NSP_TestHelper.createAccount(true);
        // Create a test opportunity

        Opportunity opp = NSP_TestHelper.createOpenOpportunity(acnt.Id,'New Product',false);
        opp.StageName = 'Prospecting';
        opp.NSP_Number_of_Employees__c = 12;
        opp.NSP_BidNumber__c = '456';
        opp.NSP_PrimaryProduct__c = 'WS';
        opp.NSP_Partner__c = acnt.Id;
        insert opp;

        // Create a CheckStageRequest input
        CheckOpportunityStage.CheckStageRequest request = new CheckOpportunityStage.CheckStageRequest();
        request.oppRecordId = opp.Id;
        request.stageName = 'Closed Won';
        // Prepare the input list
        List<CheckOpportunityStage.CheckStageRequest> requests = new List<CheckOpportunityStage.CheckStageRequest>();
        requests.add(request);
        // Call the method under test
        Test.startTest();
        List<CheckOpportunityStage.CheckStageResponse> responses = CheckOpportunityStage.checkOpportunityStage(requests);
        Test.stopTest();
        // Verify the response
        System.assertNotEquals( null , responses , 'Response should not be null' );
        System.assertEquals( 1 , responses.size() , 'There should be one response' );
        System.assertEquals( false , responses[0].checkStage , 'The stage check should return false' );
    }
}