@isTest
public class LoadFullAccessPermSetsQueueableTest {
	@testSetup 
    static void testData() {
		List<PermissionSet> psList = new List<PermissionSet>();
		PermissionSet ps1 = new PermissionSet(Label='FA Test Read Permisson Set',Name='FA_Test_Read_Permisson_Set');
		PermissionSet ps2 = new PermissionSet(Label='FA Test Edit Permisson Set',Name='FA_Test_Edit_Permisson_Set');
        psList.add(ps1);
        psList.add(ps2);
		insert psList;
	}

	@isTest
	static void testLoadFullAccessPermSets1() {
		Test.startTest();
        List<String> objectApiNames = new List<String>();
		LoadFullAccessPermSets.runLoadFullAccessPermSets('FA_Test_Read_Permisson_Set', 'FA_Test_Edit_Permisson_Set', objectApiNames);
		LoadFullAccessPermSetsQueueable.sendCompletionEmail();
        Test.stopTest();
	}

	@isTest
	static void testLoadFullAccessPermSets2() {
		Test.startTest();
        List<String> objectApiNames = new List<String>{'Account', 'EntityDefinition'};
		LoadFullAccessPermSets.runLoadFullAccessPermSets(null, null, objectApiNames);
		LoadFullAccessPermSets.runLoadFullAccessPermSets('FA_Test_Read_Permisson_Set', 'FA_Test_Edit_Permisson_Set', objectApiNames);
		Test.stopTest();
	}

	@isTest
	static void testLoadFullAccessPermSetsQueueable() {
		Id readPermSetId = [SELECT Id FROM PermissionSet WHERE Name = 'FA_Test_Read_Permisson_Set' LIMIT 1].Id;
		Id editPermSetId = [SELECT Id FROM PermissionSet WHERE Name = 'FA_Test_Edit_Permisson_Set' LIMIT 1].Id;
		Map<id,Boolean> psMap = new map<id,Boolean>{ readPermSetId => false, editPermSetId => true };
		Map<String, Integer> depRetry = new Map<String, Integer>();

        List<EntityDefinition> entities = [SELECT QualifiedApiName FROM EntityDefinition 
			WHERE QualifiedApiName IN ('Account','EntityDefinition','Idea')]; // one success case, one bad case, one ViewAll case

		List<String> objectApiNames = new List<String>();
		for ( EntityDefinition entity : entities )  {
			objectApiNames.add( entity.QualifiedApiName );
		}

        Test.startTest();
        System.enqueueJob(new LoadFullAccessPermSetsQueueable(objectApiNames, readPermSetId, editPermSetId, depRetry));
        System.enqueueJob(new LoadFullAccessPermSetsQueueable(objectApiNames, readPermSetId, editPermSetId, depRetry));
        Test.stopTest();

		List<ObjectPermissions> op = [SELECT Id, ParentId FROM ObjectPermissions WHERE ParentId IN :psMap.keySet() ];
        System.assertNotEquals(null, op);

        List<FieldPermissions> fp = [SELECT Id, ParentId FROM FieldPermissions WHERE ParentId IN :psMap.keySet() ];
        System.assertNotEquals(null, fp);
    }
}