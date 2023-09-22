public class LoadFullAccessPermSets {
    // test w/ LoadFullAccessPermSetsQueueableTest (95%)

    // /*************************************************************************************************
	// * Author:        Matthew McNeese
    // * MethodName:    runLoadFullAccessPermSets 
	// * Description :  Method for loading two specified PermissionSets with Object and Field Permissions
    // *                for all (or optional list of) object API names. Method launches a Queueable
    // *                (LoadFullAccessPermSetsQueueable) chain which upserts the ObjectPermissions and
    // *                FieldPermissions into each Perm Set for a single object from the specified list.
    // *
	// * Params:        readPermSetId (Id of perm set to be loaded with Read permissions)
    // *                editPermSetId (Id of perm set to be loaded with Edit permissions)
    // *                objectApiNames (optional List<String> of object API names; if empty, method will 
    // *                                query all object names from EntityDefinition)
	// ***************************************************************************************************/

    public static void runLoadFullAccessPermSets(Id readPermSetId, Id editPermSetId, List<String> objectApiNames) {
        Map<String, Integer> depRetry = new Map<String, Integer>();

        if ([SELECT Id, Name FROM PermissionSet WHERE Id = :readPermSetId].isEmpty()) {
            LoadFullAccessPermSetsQueueable.createErrorLog('LoadFullAccessPermSetsQueueable', 'runLoadFullAccessPermSets', 'PermissionSet does not exist: ' + readPermSetId);
            readPermSetId = null;
        }

        if ([SELECT Id, Name FROM PermissionSet WHERE Id = :editPermSetId].isEmpty()) {
            LoadFullAccessPermSetsQueueable.createErrorLog('LoadFullAccessPermSetsQueueable', 'runLoadFullAccessPermSets', 'PermissionSet does not exist: ' + editPermSetId);
            editPermSetId = null;
        }
        
        if ( objectApiNames.isEmpty() ) {
            List<EntityDefinition> entities = [SELECT QualifiedApiName, InternalSharingModel FROM EntityDefinition 
                WHERE KeyPrefix != null AND PublisherId != 'CDC' AND IsCustomSetting = false AND IsRetrieveable = true 
                ORDER BY InternalSharingModel];

            for ( EntityDefinition entity : entities ) {
                if(!entity.QualifiedApiName.endsWith('__mdt')
                    && !entity.QualifiedApiName.endsWith('Share')
                    && !entity.QualifiedApiName.endsWith('History')
                    && !entity.QualifiedApiName.endsWith('Feed')
                    && !entity.QualifiedApiName.endsWith('Trigger')
                    && !entity.QualifiedApiName.endsWith('View'))
                        objectApiNames.add(entity.QualifiedApiName);
            }
        }

        if (!Test.isRunningTest()) {
            System.enqueueJob(new LoadFullAccessPermSetsQueueable(objectApiNames, readPermSetId, editPermSetId, depRetry));
            LoadFullAccessPermSetsQueueable.createErrorLog('LoadFullAccessPermSetsQueueable', 'runLoadFullAccessPermSets', 'Launching LoadFullAccessPermSetsQueueable; objectCount=' + objectApiNames.size() );
        }
    }
}