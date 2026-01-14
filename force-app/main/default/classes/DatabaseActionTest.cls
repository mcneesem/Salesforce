@isTest
private class DatabaseActionTest {

    @isTest
    private static void testInsertAction() {
        DatabaseAction.Request req = new DatabaseAction.Request();
        req.flowApiName = 'XXX_TEST_FLOW_XXX';
        req.operation = 'INSERT';
        List<CampaignMemberStatus> records = new List<CampaignMemberStatus>();
        records.add(
            new CampaignMemberStatus(
            )
        );
        req.records = records;

        Test.startTest();
        DatabaseAction.performDmlOperation( new List<DatabaseAction.Request>{ req } );
        Test.stopTest();
    }

    @isTest
    private static void testUpdateAction() {
        DatabaseAction.Request req = new DatabaseAction.Request();
        req.flowApiName = 'XXX_TEST_FLOW_XXX';
        req.operation = 'UPDATE';
        List<CampaignMemberStatus> records = new List<CampaignMemberStatus>();
        records.add(
            new CampaignMemberStatus(
            )
        );
        req.records = records;

        Test.startTest();
        DatabaseAction.performDmlOperation( new List<DatabaseAction.Request>{ req } );
        Test.stopTest();
    }

    @isTest
    private static void testDeleteAction() {
        DatabaseAction.Request req = new DatabaseAction.Request();
        req.flowApiName = 'XXX_TEST_FLOW_XXX';
        req.operation = 'DELETE';
        List<CampaignMemberStatus> records = new List<CampaignMemberStatus>();
        records.add(
            new CampaignMemberStatus(
            )
        );
        req.records = records;

        Test.startTest();
        DatabaseAction.performDmlOperation( new List<DatabaseAction.Request>{ req } );
        Test.stopTest();
    }

}
//