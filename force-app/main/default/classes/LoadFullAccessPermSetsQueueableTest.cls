@isTest
private class LoadFullAccessPermSetsQueueableTest {

    @testSetup
    private static void testData() {
        List<PermissionSet> psList = new List<PermissionSet>();
        PermissionSet ps1 = new PermissionSet(Label='FA Test Read Permission Set',Name='FA_Test_Read_Permission_Set');
        PermissionSet ps2 = new PermissionSet(Label='FA Test Edit Permission Set',Name='FA_Test_Edit_Permission_Set');
        psList.add(ps1);
        psList.add(ps2);
        insert psList;
    }

    @isTest
    private static void testLoadFullAccessPermSets1() {
        Test.startTest();
        LoadFullAccessPermSets.runLoadFullAccessPermSets('FA_Test_Read_Permission_Set', 'FA_Test_Edit_Permission_Set', null, null);
        LoadFullAccessPermSetsQueueable.sendCompletionEmail();
        Test.stopTest();
    }

    @isTest
    private static void testLoadFullAccessPermSets2() {
        Test.startTest();
        OrgSettings__c setting = new OrgSettings__c();
        setting.ExternalIdObjects1__c = 'blng__GLRule__c,blng__GLAccount__c';
        setting.IsSandbox__c = false;
        setting.IsEnabled_loadRecTypeVisibility__c = true;
        insert setting;
        List<String> objectApiNames = new List<String>{'Account', 'EntityDefinition','blng__GLRule__c','blng__GLAccount__c'};
        LoadFullAccessPermSets.runLoadFullAccessPermSets(null, null, objectApiNames, null);
        LoadFullAccessPermSets.runLoadFullAccessPermSets('FA_Test_Read_Permission_Set', 'FA_Test_Edit_Permission_Set', objectApiNames, null);
        Test.stopTest();
    }

    @isTest
    private static void testLoadFullAccessPermSetsQueueable() {
        Id readPermSetId = [SELECT Id FROM PermissionSet WHERE Name = 'FA_Test_Read_Permission_Set' LIMIT 1].Id;
        Id editPermSetId = [SELECT Id FROM PermissionSet WHERE Name = 'FA_Test_Edit_Permission_Set' LIMIT 1].Id;
        Map<id,Boolean> psMap = new map<id,Boolean>{ readPermSetId => false, editPermSetId => true };
        Map<String, Integer> depRetry = new Map<String, Integer>();

        List<EntityDefinition> entities = [SELECT QualifiedApiName FROM EntityDefinition 
            WHERE QualifiedApiName IN ('Account','EntityDefinition','Idea')]; // one success case, one bad case, one ViewAll case

        List<String> objectApiNames = new List<String>();
        for ( EntityDefinition entity : entities )  {
            objectApiNames.add( entity.QualifiedApiName );
        }

        Test.startTest();
        System.enqueueJob(new LoadFullAccessPermSetsQueueable(objectApiNames, readPermSetId, editPermSetId, depRetry, null, null));
        System.enqueueJob(new LoadFullAccessPermSetsQueueable(objectApiNames, readPermSetId, editPermSetId, depRetry, null, null));
        Test.stopTest();

        List<ObjectPermissions> op = [SELECT Id, ParentId FROM ObjectPermissions WHERE ParentId IN :psMap.keySet() ];
        System.assertNotEquals(null, op);

        List<FieldPermissions> fp = [SELECT Id, ParentId FROM FieldPermissions WHERE ParentId IN :psMap.keySet() ];
        System.assertNotEquals(null, fp);
    }

    @isTest
    private static void testLoadFullAccessPermSetsQueueableLogging() {
        Test.startTest();
        LoadFullAccessPermSetsQueueable.createErrorLogFuture( null , null , null );
        Test.stopTest();
    }

    @isTest
    private static void testloadExternalIds() {
        Test.startTest();
        LoadFullAccessPermSetsQueueable.loadExternalIds( 'blng__GLAccount__c' );
        Test.stopTest();
    }

}
//