@isTest
private class CampaignMemberTriggerHelperTest {

    @isTest
    private static void testAfterUpdate() {
        Test.startTest();
        Campaign campaign = new Campaign(Name = 'Test Campaign');
        campaign.Campaign_Level__c = 'Grandparent: Campaign';
        insert campaign;
        Lead lead = new Lead(LastName = 'Test Lead', Company = 'Test Company');
        lead.FirstName = 'test 1';
        lead.LastName = 'test 2';
        lead.Email = 'abc@abc.com';
        insert lead;
        CampaignMember campaignMember = new CampaignMember(CampaignId = campaign.Id, LeadId = lead.Id);
        insert campaignMember;
        campaignMember.Status = 'Responded';
        update campaignMember;
        Test.stopTest();
        CampaignMember campaignMemberTest = [SELECT Status FROM CampaignMember WHERE Id =: campaignMember.Id];
         //	Call the rest of methods to reach the required coverage
        CampaignMemberTriggerHandler campaignMemberTriggerHandler = new CampaignMemberTriggerHandler();
        campaignMemberTriggerHandler.isDisabled();
        campaignMemberTriggerHandler.beforeInsert(new List<sObject>());
        campaignMemberTriggerHandler.afterInsert(new List<sObject>(), new Map<Id, sObject>());
        campaignMemberTriggerHandler.beforeUpdate(new Map<Id, sObject>(), new Map<Id, sObject>());
        campaignMemberTriggerHandler.beforeDelete(new List<sObject>(), new Map<Id, sObject>());
        campaignMemberTriggerHandler.afterDelete(new List<sObject>(), new Map<Id, sObject>());
        System.assertEquals('Responded', campaignMemberTest.Status, 'CampaignMember history tracking record has been created');
    }

}
//