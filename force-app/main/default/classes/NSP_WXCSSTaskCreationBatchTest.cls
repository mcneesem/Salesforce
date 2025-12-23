@isTest
private class NSP_WXCSSTaskCreationBatchTest {

    @testSetup
    private static void setUpTestData() {
        List<Account> accList = new List<Account>();
        //create an account record
        Account acct = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acct.NSP_Engagement_Level__c = 'Level 3';
        acct.NSP_CSS_Renewal_Date__c = System.today().addDays(15);
        accList.add(acct);

        Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc.NSP_Engagement_Level__c = 'Level 1';
        acc.NSP_CSS_Renewal_Date__c = System.today().addDays(10);
        accList.add(acc);

        Database.insert(accList);

        //create an account team record
        NSP_Account_Team__c accTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        accTeam.NSP_Account__c = acct.Id;
        accTeam.NSP_Role__c = NSP_ServiceConstants.CUSTOMER_SPECIALIST;
        accTeam.NSP_User__c = UserInfo.getUserId();
        accTeam.NSP_Primary__c = true;
        Database.insert(accTeam);
    }

    @isTest
    private static void taskCreationTest() {
        List<String> accFields = new List<String>{'Id'};
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder('Account', accFields)
            .setSecurityEnforce(false)
            .addFilter('NSP_Engagement_Level__c', 'Level 3')
            .addLimit(1);
        String query = queryBuilder.build();
        Account acct = Database.query(query);

        test.startTest();
        NSP_WXCSSTaskCreationBatch batchSch = new NSP_WXCSSTaskCreationBatch();
        Database.executeBatch(batchSch, 200);
        test.stopTest();

        List<String> taskFields = new List<String>{'Id', 'WhatId'};
        NSP_QueryBuilder taskQueryBuilder = new NSP_QueryBuilder('Task', taskFields)
            .setSecurityEnforce(false)
            .addFilter('WhatId', acct.Id)
            .addLimit(1);
        String taskquery = taskQueryBuilder.build();
        List<Task> taskList = (List<Task>) Database.query(taskquery);
        System.assertEquals(1, taskList.size());
    }

    @isTest
    private static void negativeTaskCreationTest() {
        List<String> accFields = new List<String>{'Id'};
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder('Account', accFields)
            .setSecurityEnforce(false)
            .addFilter('NSP_Engagement_Level__c', 'Level 1')
            .addLimit(1);
        String query = queryBuilder.build();
        Account acct = Database.query(query);

        test.startTest();
        NSP_WXCSSTaskCreationBatch batchSch = new NSP_WXCSSTaskCreationBatch();
        Database.executeBatch(batchSch, 200);
        test.stopTest();

        List<String> taskFields = new List<String>{'Id', 'WhatId'};
        NSP_QueryBuilder taskQueryBuilder = new NSP_QueryBuilder('Task', taskFields)
            .setSecurityEnforce(false)
            .addFilter('WhatId', acct.Id)
            .addLimit(1);
        String taskquery = taskQueryBuilder.build();
        List<Task> taskList = (List<Task>) Database.query(taskquery);
        System.assertEquals(0, taskList.size());
    }

    @isTest
    private static void batchSchedulerTest() {
        Test.startTest();
        String jobId = NSP_WXCSSTaskCreationBatch.schedule();
        Test.stopTest();
        CronTrigger ct = [
            SELECT Id , CronExpression , TimesTriggered , NextFireTime
            FROM CronTrigger
            WHERE ( Id = :jobId )
        ];
        System.assertNotEquals( null , ct );
        System.assertEquals( 0 , ct.TimesTriggered );
    }

}
//