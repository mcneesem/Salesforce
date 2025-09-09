@isTest
public class CheckOpportunityStageTest {
    @isTest
    static void testCheckOpportunityStage() {
        // Create a test opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpportunity;

        // Create a CheckStageRequest input
        CheckOpportunityStage.CheckStageRequest request = new CheckOpportunityStage.CheckStageRequest();
        request.oppRecord = testOpportunity;
        request.stageName = 'Closed Won';

        // Prepare the input list
        List<CheckOpportunityStage.CheckStageRequest> requests = new List<CheckOpportunityStage.CheckStageRequest>();
        requests.add(request);

        // Call the method under test
        Test.startTest();
        List<CheckOpportunityStage.CheckStageResponse> responses = CheckOpportunityStage.checkOpportunityStage(requests);
        Test.stopTest();

        // Verify the response
        System.assertNotEquals(null, responses, 'Response should not be null');
        System.assertEquals(1, responses.size(), 'There should be one response');
        System.assertEquals(true, responses[0].checkStage, 'The stage check should return true');
    }
}