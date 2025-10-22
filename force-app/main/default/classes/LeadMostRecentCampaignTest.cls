@isTest
private class LeadMostRecentCampaignTest {

    @isTest
    private static void testCreateCollaboration() {
        Lead sharedLead = new Lead(
            FirstName='TestFirstName' ,
            LastName='TestLastName' ,
            Email='test@test.com' ,
            Company='TestCompany'
        );
        insert sharedLead;

        LeadMostRecentCampaign.Request req = new LeadMostRecentCampaign.Request();
        req.leadId = sharedLead.Id;
        req.campaignName = 'TestCampaignName';
        
        Test.startTest();
        LeadMostRecentCampaign.updateMostRecentCampaign( new List<LeadMostRecentCampaign.Request>{ req } );
        Test.stopTest();
    }

}
//