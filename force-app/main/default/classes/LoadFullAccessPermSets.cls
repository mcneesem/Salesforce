public class LoadFullAccessPermSets {
    // test w/ LoadFullAccessPermSetsQueueableTest (89%)

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
        List<String> extIdObjList = new List<String>();
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
            LoadFullAccessPermSetsQueueable.createErrorLog( 'runLoadFullAccessPermSets' , null , 'PermissionSet not found: ' + readPermSetName );
        }
        if (!mPermSets.containsKey(editPermSetName)) {
            LoadFullAccessPermSetsQueueable.createErrorLog( 'runLoadFullAccessPermSets' , null , 'PermissionSet not found: ' + editPermSetName );
        }

        if ( objectApiNames.isEmpty() ) {
            List<EntityDefinition> entities = [SELECT QualifiedApiName, InternalSharingModel, NamespacePrefix FROM EntityDefinition
                WHERE KeyPrefix != null AND PublisherId != 'CDC' AND IsCustomSetting = false
                ORDER BY InternalSharingModel];

            objectApiNames = getobjectApiNames(entities , filterNamespaces);
        }

        OrgSettings__c orgSettings = OrgSettings__c.getOrgDefaults();
        Set<String> orgSettingsFields = Schema.SObjectType.OrgSettings__c.fields.getMap().keySet();
        for ( String orgSettingsField : orgSettingsFields ){
            if( !orgSettings.IsSandbox__c && orgSettingsField.contains('externalidobjects') ){
                String fieldValue = (String) orgSettings.get(orgSettingsField);
                if( fieldValue != null ){
                    extIdObjList.addAll(fieldValue.split(','));
                }
            }
        }

        loadRecTypeVisibility(mPermSets.get(editPermSetName));
        if (!Test.isRunningTest()) {
            System.enqueueJob(new LoadFullAccessPermSetsQueueable( objectApiNames , mPermSets.get(readPermSetName) , mPermSets.get(editPermSetName) , depRetry , filterNamespaces , extIdObjList ) );
        }
        LoadFullAccessPermSetsQueueable.createErrorLog( 'runLoadFullAccessPermSets' , null , 'Loading RecTypeVisibilities' );
        LoadFullAccessPermSetsQueueable.createErrorLog( 'runLoadFullAccessPermSets' , null , 'Launching LoadFullAccessPermSetsQueueable; objectCount=' + objectApiNames.size() );
    }

    // ************************************ Record Type Visibility ************************************
    //  Description :   Upserts PermissionSetRecordTypeVisibility for all Record Types of specified
    //                  object name into specified Perm Set.
    // ************************************************************************************************
    @future(callout=true)
    public static void loadRecTypeVisibility(Id permSetId) {
        if ( OrgSettings__c.getOrgDefaults().IsEnabled_loadRecTypeVisibility__c
            && !String.isBlank( permSetId )
            )
        {
            List<RecordType> recTypeList =  [SELECT DeveloperName, SobjectType, NamespacePrefix FROM RecordType WHERE IsActive = true];
            MetadataService.MetadataPort service = NSP_PrepSandbox.createService();

            String[] permissionSetNames = new String[] {[SELECT Name FROM PermissionSet WHERE Id = :permSetId LIMIT 1].Name};
            MetadataService.PermissionSet permSet = new MetadataService.PermissionSet();
            if (!Test.isRunningTest()) {
                permSet = (MetadataService.PermissionSet) service.readMetadata('PermissionSet', permissionSetNames).getRecords()[0];
            }

            for (RecordType recType : recTypeList) {
                MetadataService.PermissionSetRecordTypeVisibility recTypeVis = new MetadataService.PermissionSetRecordTypeVisibility();
                String prefix = (recType.NamespacePrefix == null) ? '' : recType.NamespacePrefix + '__';
                recTypeVis.recordType = recType.SobjectType + '.' + prefix + recType.DeveloperName;
                recTypeVis.visible = true;

                if (permSet.recordTypeVisibilities != null) {
                    permSet.recordTypeVisibilities.add(recTypeVis);
                } else {
                    permSet.recordTypeVisibilities = new MetadataService.PermissionSetRecordTypeVisibility[] { recTypeVis };
                }
            }

            updatePermSet( permSet , service );
        }
    }

    private static void updatePermSet( MetadataService.PermissionSet permSet , MetadataService.MetadataPort service ) {
        if ( ( permSet != null ) && !Test.isRunningTest() ) {
            List<MetadataService.SaveResult> results = service.updateMetadata( new MetadataService.Metadata[] { permSet } );
            if ( !results[0].success ) {
                LoadFullAccessPermSetsQueueable.createErrorLog( 'loadRecTypeVisibility' , null , 'RecTypeVisibility errors: ' + results[0].errors[0].message );
            }
        }
    }

    private static List<String> getobjectApiNames(List<EntityDefinition> entities , List<String> filterNamespaces){
        List<String> objectApiNames = new List<String>();
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
        return objectApiNames;
    }
}