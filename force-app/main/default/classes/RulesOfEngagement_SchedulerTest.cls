@isTest
private class RulesOfEngagement_SchedulerTest {

    //
    // DEPRECATED
    //

    @isTest
    private static void runRules() {

        User userDeployerManager = [
            SELECT Id, Name
            FROM User
            WHERE UserName LIKE 'deployment.manager@insperity.com%'
            LIMIT 1
        ];

        // Custom settings
        Rules_Of_Engagement__c roeSettings = new Rules_Of_Engagement__c();
        roeSettings.Available_User_Id__c = '0054x000008PgqNAAS';
        insert roeSettings;

        Test.startTest();

        System.runAs(userDeployerManager){

            // Run as Deployer Manager
            // Important: permisison set - > Set audit field on record creation

            List<SObject> contactList = new List<SObject>();
            List<AccountContactRelation> acrList = new List<AccountContactRelation>();

            Id userAvailable = Rules_Of_Engagement__c.getInstance(UserInfo.getUserId()).Available_User_Id__c;

            Account account = NSP_TestHelper.createAccount(true);

            Contact contact1 = new Contact();
            contact1.firstName = 'Is Primary and not COI';
            contact1.lastName = 'Test 1';
            contact1.email = 'Test1@test.com';
            contact1.AccountId = account.id;
            contactList.add(contact1);

            Contact contact2 = new Contact();
            contact2.firstName = 'Is Not Primary and COI';
            contact2.lastName = 'Test 1';
            contact2.email = 'Test1@test.com';
            contact2.AccountId = account.id;
            contactList.add(contact2);
            insert contactList;

            AccountContactRelation acr1  = [
                SELECT Id
                FROM AccountContactRelation
                WHERE AccountId =: account.Id AND contactId =: contact1.Id
            ];
            acr1.NSP_Is_Primary__c = true;
            acr1.IsActive = true;
            acr1.Roles = 'Agency';
            acrList.add(acr1);

            AccountContactRelation acr2  = [
                SELECT Id
                FROM AccountContactRelation
                WHERE AccountId =: account.Id AND contactId =: contact2.Id
            ];
            acr2.Roles = 'COI';
            acrList.add(acr2);
            update acrList;

            Opportunity opp = new Opportunity();
            opp.Name = 'Test Oppty';
            opp.AccountId = account.Id;
            opp.stagename = NSP_SalesConstants.DISCOVERY_STAGE;
            opp.CloseDate = date.today();
            opp.NSP_PrimaryProduct__c = 'WX';
            opp.NSP_Number_of_Employees__c = 100;
            opp.NSP_MidMarketNationalAccount__c = 'MidMarket';
            opp.type = 'New Product';
            opp.Discovery_Call_Completed_Date__c =  Date.newInstance(2023, 01, 09);
            insert opp;

            // Create a task in the past -> 200 days ago
            Task task = new Task();
            task.Subject = 'Test Task';
            task.Status = 'Completed';
            task.WhatId = opp.id;
            task.ActivityDate = Date.newInstance(2023, 01, 09);
            insert task;

            RulesOfEngagement_Scheduler.runRulesOfEngagement();
        }
        Test.stopTest();
    }

    @isTest
    private static void testRulesOfEngagement_Scheduler_schedule() {
        Test.startTest();
        String jobId = RulesOfEngagement_Scheduler.schedule();
        CronTrigger ct = [
            SELECT Id , CronExpression , TimesTriggered , NextFireTime
            FROM CronTrigger
            WHERE ( Id = :jobId )
        ];
        System.assertNotEquals( null , ct );
        System.assertEquals( 0 , ct.TimesTriggered );
        Test.stopTest();
   }

}
//