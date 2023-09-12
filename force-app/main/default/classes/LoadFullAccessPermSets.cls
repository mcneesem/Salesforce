public class LoadFullAccessPermSets {
    // test w/ LoadFullAccessPermSetsQueueableTest (96%)
    
    public static void runLoadFullAccessPermSets(){ // no arg runs all objects
        runLoadFullAccessPermSets(null);
    }
        
    public static void runLoadFullAccessPermSets(string argObjApiNames){ // can pass in comma-delimited list of obj api names
        List<PermissionSet> psList = new List<PermissionSet>(); 
        PermissionSet ps1 = new PermissionSet(Label='All objects - All fields - Read access', Name='All_objects_All_fields_Read_access');
        PermissionSet ps2 = new PermissionSet(Label='All objects - All fields - Edit access', Name='All_objects_All_fields_Edit_access');
        psList.add(ps1);
        psList.add(ps2);
        
        Database.upsert(psList, false);
        
        map<id,Boolean> psMap = new map<id,Boolean>{
            [SELECT Id FROM PermissionSet WHERE Name = 'All_objects_All_fields_Read_access' LIMIT 1].Id => false,
            [SELECT Id FROM PermissionSet WHERE Name = 'All_objects_All_fields_Edit_access' LIMIT 1].Id => true };
        
        List<String> objectApiNames = new List<String>();
        if (!String.isBlank(argObjApiNames)) {
            objectApiNames = argObjApiNames.split(',');
        } else {
            List<EntityDefinition> entities = [SELECT QualifiedApiName, InternalSharingModel FROM EntityDefinition 
                WHERE KeyPrefix != null AND PublisherId != 'CDC' AND IsCustomSetting = false AND IsRetrieveable = true 
                ORDER BY InternalSharingModel];
            
                for ( EntityDefinition entity : entities )  {
                if(!entity.QualifiedApiName.endsWith('__mdt')
                    && !entity.QualifiedApiName.endsWith('Share')
                    && !entity.QualifiedApiName.endsWith('History')
                    && !entity.QualifiedApiName.endsWith('Feed')
                    && !entity.QualifiedApiName.endsWith('Status')
                    && !entity.QualifiedApiName.endsWith('Trigger')
                    && !entity.QualifiedApiName.endsWith('View'))
                        objectApiNames.add(entity.QualifiedApiName);
            }
        }

        if (!Test.isRunningTest()) {
            System.debug( ' ~ Launch LoadFullAccessPermSetsQueueable chain - objectCount=' + objectApiNames.size() );
            Id jobID = System.enqueueJob(new LoadFullAccessPermSetsQueueable(objectApiNames, psMap, true, true));
            System.debug( ' ~ firstJob=' + jobID );
        }
    }
}