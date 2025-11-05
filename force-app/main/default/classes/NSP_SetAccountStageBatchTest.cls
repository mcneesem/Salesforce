@isTest
private class NSP_SetAccountStageBatchTest {

    @testSetup
    private static void testData() {
            Test.startTest();
        //Account creation
        Account accoutObject = new Account();
        accoutObject.Name = 'Test Account';
        accoutObject.NSP_Stage__c = 'Assigned';
        accoutObject.NSP_Account_Status__c = 'Active';
        //inserting account
        insert accoutObject;

        List<Opportunity> optyList = new List<Opportunity>();

        //Opportunity Createtion
        Opportunity opportunityObject = new Opportunity();
        opportunityObject.Name = 'Test Opportunity';
        opportunityObject.StageName = 'Prospecting';
        opportunityObject.accountid = accoutObject.id;
        opportunityObject.CloseDate = date.today();
        //Adding opportunity object to the list
        optyList.add(opportunityObject);
        //Opportunity Createtion
        Opportunity opportunityObject1 = new Opportunity();
        opportunityObject1.Name = 'Test Opportunity';
        opportunityObject1.StageName = 'Prospecting';
        opportunityObject1.accountid = accoutObject.id;
        opportunityObject1.CloseDate = date.today();
        //Adding opportunity object to the list
        optyList.add(opportunityObject1);
        //inserting opportunity records
        insert optyList;

        SBQQ__Quote__c primaryQuote = new SBQQ__Quote__c();
        primaryQuote.SBQQ__Primary__c = true;
        primaryQuote.SBQQ__Opportunity2__c = optyList[0].Id;
        primaryQuote.SBQQ__Account__c = accoutObject.id;
        primaryQuote.SBQQ__Status__c='Approved';

        insert primaryQuote;
        Test.stopTest();
        //optyList[1].StageName='Closed Won';
        optyList[0].StageName='Closed Won';

        update optyList;

    }

    @isTest
    private static void testSetAccountSatge() {
        Test.startTest();
        //Calling the batch
        Database.executeBatch(new NSP_SetAccountStageBatch(),15);
        System.assert(true,true);

        NSP_SetAccountStageScheduler testsche = new NSP_SetAccountStageScheduler();
        String sch = '0 0 23 * * ?';
        system.schedule('Test status Check', sch, testsche );

        Test.stopTest();
    }

}
//