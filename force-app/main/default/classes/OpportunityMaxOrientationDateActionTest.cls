@isTest
private class OpportunityMaxOrientationDateActionTest {

    @isTest
    static void maxOrientationDateTest() {

        Date today = Date.today();

        Account acct = new Account();
        acct.name = 'Test';
        insert acct;

        Opportunity opp = new Opportunity();
        opp.AccountId = acct.Id;
        opp.Name = 'Test Opportunity';
        opp.StageName = 'Prospecting';
        opp.CloseDate = today;
        insert opp;

        OpportunityMaxOrientationDateAction.FlowInput input = new OpportunityMaxOrientationDateAction.FlowInput();
        input.opportunitytId = opp.Id;
        input.maxOrientationDate = today;
        List<OpportunityMaxOrientationDateAction.FlowInput> inputs = new List<OpportunityMaxOrientationDateAction.FlowInput>();
        inputs.add(input);
        OpportunityMaxOrientationDateAction.invoke(inputs);

        List<Opportunity> records = [SELECT Max_Orientation_Date__c, Name FROM Opportunity WHERE Id = :opp.Id];

        System.assertEquals(records.isEmpty(), false );
        System.assertEquals(today, records[0].Max_Orientation_Date__c);
    }
}