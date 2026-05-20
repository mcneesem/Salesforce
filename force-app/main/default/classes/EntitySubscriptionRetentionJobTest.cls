@isTest
private class EntitySubscriptionRetentionJobTest {
    private static final String PRIMARY_CONTACT_FIRSTNAME = 'Curie';
    private static final String CONTACT_DEFAULT_TESTFACTORY = 'NSP_TestDataFactory.ContactDefaultsLight';

    @TestSetup
    static void setupData(){
        Account insAcc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        insAcc.Name = System.Label.NSP_Insperity_Account;
        insert insAcc;

        Contact insPriCon = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), CONTACT_DEFAULT_TESTFACTORY, false);
        insPriCon.AccountId = insAcc.Id;
        insPriCon.FirstName = 'INS ' + PRIMARY_CONTACT_FIRSTNAME;
        insert insPriCon;

        EntitySubscriptionRetentionJobSettings__c settings = EntitySubscriptionRetentionJobSettings__c.getOrgDefaults();
        settings.IsEnabled__c = true;
        settings.BatchSize__c = 200;
        settings.SoqlDaysLimitCases__c = 0;
        upsert settings;

        Case insCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        insCase.AccountId = insAcc.Id;
        insCase.ContactId = insPriCon.id;
        insCase.NSP_CorporateEmployeeEE__c = true;
        insCase.status = 'Closed';
        Insert insCase;

        EntitySubscription es = new  EntitySubscription();
        es.ParentId =  insCase.Id;
        es.subscriberId = UserInfo.getUserId();
        insert es;

    }

    @isTest
    static void myUnitTest() {


        EntitySubscriptionRetentionJob.schedule();
        EntitySubscriptionRetentionJob caseBatch = new EntitySubscriptionRetentionJob() ;
        caseBatch.run();
        caseBatch.call(null, null);
        Database.executeBatch(new EntitySubscriptionRetentionJob());
    }
}