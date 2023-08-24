@isTest
public class LoadFullAccessPermSetsQueueableTest {
	@testSetup 
    static void testData() {	
		PermissionSet ps = new PermissionSet(Label='FA Test Permisson Set',Name='FA_Test_Permisson_Set');
		insert ps;
	}

	@isTest
	static void testLoadFullAccessPermSets() {
		Test.startTest();
        LoadFullAccessPermSets.runLoadFullAccessPermSets();
        Test.stopTest();
	}

	@isTest
	static void testLoadFullAccessPermSetsQueueable() {
		map<id,Boolean> psMap = new map<id,Boolean>{ [SELECT Id FROM PermissionSet WHERE Name = 'FA_Test_Permisson_Set' LIMIT 1].Id => false };

        List<EntityDefinition> entities = [SELECT QualifiedApiName, IsCustomSetting, PublisherId
			FROM EntityDefinition WHERE QualifiedApiName = 'Account'];

		List<String> objectApiNames = new List<String>();
		for ( EntityDefinition entity : entities )  {
			objectApiNames.add( entity.QualifiedApiName );
		}

        Test.startTest();        
        System.enqueueJob(new LoadFullAccessPermSetsQueueable(objectApiNames, psMap, 0));
        Test.stopTest();
		
		List<ObjectPermissions> op = [SELECT Id, ParentId FROM ObjectPermissions WHERE ParentId IN :psMap.keySet() ];
        System.assertNotEquals(null, op);
		
        List<FieldPermissions> fp = [SELECT Id, ParentId FROM FieldPermissions WHERE ParentId IN :psMap.keySet() ];
        System.assertNotEquals(null, fp);
    }
}