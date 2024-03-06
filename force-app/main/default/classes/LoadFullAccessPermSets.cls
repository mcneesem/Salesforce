public class LoadFullAccessPermSets {
    // test w/ LoadFullAccessPermSetsQueueableTest (96%)

    // ********************************************************************************************************
    //  Author:        Matthew McNeese
    //  MethodName:    runLoadFullAccessPermSets
    //  Description :  Method for loading two specified PermissionSets with Object and Field Permissions
    //                 for all (or optional list of) object API names. Method launches a Queueable
    //                 (LoadFullAccessPermSetsQueueable) chain with each queued job upserting ObjectPermissions
    //                 and FieldPermissions into each Perm Set for a single object from the list
    // 
    //  Params:        readPermSetId:      Id of perm set to be loaded with Read permissions
    //                 editPermSetId:      Id of perm set to be loaded with Edit permissions
    //                 objectApiNames:     optional List<String> of object API names; if null, method
    //                                     queries all object names from EntityDefinition
    //                 filterNamespaces:   optional List<String> of EntityDefinition.NamespacePrefix values
    //                                     to be filtered out of Permissions loading; if null, no objects
    //                                     are filtered out
    // ********************************************************************************************************

    public static void runLoadFullAccessPermSets(String readPermSetName, String editPermSetName, List<String> objectApiNames, List<String> filterNamespaces) {
        Map<String, Integer> depRetry = new Map<String, Integer>();
        Map<String, Id> mPermSets = new Map<String, Id>();
        for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN (:readPermSetName, :editPermSetName)]) {
            mPermSets.put(ps.Name, ps.Id);
        }

        if (objectApiNames == null) {
            objectApiNames = new List<String>();
        }
        if (filterNamespaces == null) {
            filterNamespaces = new List<String>();
        }

        if (!mPermSets.containsKey(readPermSetName)) {
            LoadFullAccessPermSetsQueueable.createErrorLog('LoadFullAccessPermSetsQueueable', 'runLoadFullAccessPermSets', null, 'PermissionSet not found: ' + readPermSetName);
        }
        if (!mPermSets.containsKey(editPermSetName)) {
            LoadFullAccessPermSetsQueueable.createErrorLog('LoadFullAccessPermSetsQueueable', 'runLoadFullAccessPermSets', null, 'PermissionSet not found: ' + editPermSetName);
        }

        if ( objectApiNames.isEmpty() ) {
            List<EntityDefinition> entities = [SELECT QualifiedApiName, InternalSharingModel, NamespacePrefix FROM EntityDefinition 
                WHERE KeyPrefix != null AND PublisherId != 'CDC' AND IsCustomSetting = false 
                ORDER BY InternalSharingModel];

            for ( EntityDefinition entity : entities ) {
                if( !entity.QualifiedApiName.endsWith('__mdt')
                    && !entity.QualifiedApiName.endsWith('Share')
                    && !entity.QualifiedApiName.endsWith('History')
                    && !entity.QualifiedApiName.endsWith('Feed')
                    && !entity.QualifiedApiName.endsWith('Trigger')
                    && !entity.QualifiedApiName.endsWith('View')
                    && !filterNamespaces.contains(entity.NamespacePrefix)
                    )
                {
                    objectApiNames.add(entity.QualifiedApiName);
                }
            }
        }

        if (!Test.isRunningTest()) {
            System.enqueueJob(new LoadFullAccessPermSetsQueueable(objectApiNames, mPermSets.get(readPermSetName), mPermSets.get(editPermSetName), depRetry));
        }
        LoadFullAccessPermSetsQueueable.createErrorLog('LoadFullAccessPermSetsQueueable', 'runLoadFullAccessPermSets', null, 'Launching LoadFullAccessPermSetsQueueable; objectCount=' + objectApiNames.size() );
    }
}