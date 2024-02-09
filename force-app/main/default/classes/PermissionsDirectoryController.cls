public with sharing class PermissionsDirectoryController {
    // test w/ PermissionsDirectoryControllerTest (98%)
    private static final String CLASS_NAME = ' ~ PermissionsDirectoryController';
    private static String VIEW_PERMISSIONS_DIRECTORY = 'View_Permissions_Directory';

    private static Boolean hasPermissionView {
        private get {
            if ( hasPermissionView == null ) {
                hasPermissionView = CustomPermissionController.checkUserPermission(
                    PermissionsDirectoryController.VIEW_PERMISSIONS_DIRECTORY ,
                    UserInfo.getUserId()
                );
            }
            return hasPermissionView;
        }
        private set;
    }

    @AuraEnabled(cacheable=True)
    public static Boolean isAccessible() {
        String METHOD_NAME = 'isAccessible';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ hasPermissionView=' + PermissionsDirectoryController.hasPermissionView );
        return PermissionsDirectoryController.hasPermissionView;
    }

    @AuraEnabled(cacheable=True)
    public static List<AuraPermission> getPermissions( String recordId , String permissionType ) {
        String METHOD_NAME = 'getPermissions';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ recordId=' + recordId );
        System.debug( DEBUG_PREFIX + ' ~ permissionType=' + permissionType );
        System.debug( DEBUG_PREFIX + ' ~ hasPermissionView=' + PermissionsDirectoryController.hasPermissionView );
        //
        PermissionsDirectoryController.recordId = recordId;
        List<AuraPermission> response = new List<AuraPermission>();
        if ( PermissionsDirectoryController.hasPermissionView ) {
            if ( permissionType == 'UserPermissions' ) {
                if ( PermissionsDirectoryController.userPermissionsMap != null ) {
                    response = PermissionsDirectoryController.userPermissionsMap.values();
                    response.sort();
                }
            } else if ( permissionType == 'ObjectPermissions' ) {
                if ( PermissionsDirectoryController.objectPermissionsMap != null ) {
                    response = PermissionsDirectoryController.objectPermissionsMap.values();
                    response.sort();
                }
            } else if ( permissionType == 'CustomPermissions' ) {
                if ( PermissionsDirectoryController.customPermissionsMap != null ) {
                    response = PermissionsDirectoryController.customPermissionsMap.values();
                    response.sort();
                }
            }
        }
        //
        System.debug( DEBUG_PREFIX + ' ~ response=' + response );
        return response;
    }

    public class AuraPermission implements Comparable {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String allows { get; set; }
        @AuraEnabled public List<ComparableAllow> allowsRollup { get; set; }
        @AuraEnabled public Set<PermissionSet> sources { get; set; }
        //
        // 0 if this instance and other are equal
        // > 0 if this instance is greater than other
        // < 0 if this instance is less than other
        public Integer compareTo( Object other ) {
            Integer result = 0;
            if ( label == ((AuraPermission)other).label ) {
                result = 0;
            }
            if ( label > ((AuraPermission)other).label ) {
                result = 1;
            }
            if ( label < ((AuraPermission)other).label ) {
                result = -1;
            }
            return result;
        }
    }

    public static Map<String,Integer> allowsValueMap {
        public get {
            if ( allowsValueMap == null ) {
                Map<String,Integer> newMap = new Map<String,Integer>();
                newMap.put( 'Read' , 0 );
                newMap.put( 'Create' , 1 );
                newMap.put( 'Edit' , 2 );
                newMap.put( 'Delete' , 3 );
                newMap.put( 'View All' , 4 );
                newMap.put( 'Modify All' , 5 );
                allowsValueMap = newMap;
            }
            return allowsValueMap;
        }
        private set;
    }

    public class ComparableAllow implements Comparable {
        @AuraEnabled public String label { get; set; }
        //
        // used by List.contains()...
        // List.contains() uses the equals() method of the items in the list to test whether or not it has found the item it is looking for. 
        public Boolean equals( Object other ) {
            Integer labelValue = PermissionsDirectoryController.allowsValueMap.get( label );
            Integer otherLabelValue = PermissionsDirectoryController.allowsValueMap.get( ((ComparableAllow)other).label );
            return ( labelValue == otherLabelValue );
        }
        //
        // 0 if this instance and other are equal
        // > 0 if this instance is greater than other
        // < 0 if this instance is less than other
        public Integer compareTo( Object other ) {
            Integer labelValue = PermissionsDirectoryController.allowsValueMap.get( label );
            Integer otherLabelValue = PermissionsDirectoryController.allowsValueMap.get( ((ComparableAllow)other).label );
            Integer result = 0;
            if ( labelValue == otherLabelValue ) {
                result = 0;
            }
            if ( labelValue > otherLabelValue ) {
                result = 1;
            }
            if ( labelValue < otherLabelValue ) {
                result = -1;
            }
            return result;
        }
    }

    //
    //
    //

    private static String recordId {
        private get {
            return recordId;
        }
        private set {
            recordId = value;
        }
    }

    //
    //
    //

    private static List<PermissionSetAssignment> userPermissionSetAssignments {
        private get {
            if ( userPermissionSetAssignments == null ) {
                if ( PermissionsDirectoryController.recordId != null ) {
                    userPermissionSetAssignments = [
                        SELECT
                            Id ,
                            PermissionSetId ,
                            PermissionSet.Name ,
                            PermissionSet.Label ,
                            PermissionSet.IsOwnedByProfile ,
                            PermissionSet.ProfileId ,
                            PermissionSet.Profile.Name ,
                            PermissionSetGroupId ,
                            PermissionSet.PermissionsCustomizeApplication ,
                            PermissionSet.PermissionsManageUsers ,
                            PermissionSet.PermissionsEditPublicFilters ,
                            SystemModstamp
                        FROM PermissionSetAssignment
                        WHERE (
                            ( AssigneeId = :PermissionsDirectoryController.recordId )
                        )
                    ];
                }
            }
            return userPermissionSetAssignments;
        }
        private set;
    }

    // Set includes the PermissionSet.Id of the User's Profile...
    private static Set<Id> userPermissionSetIds {
        private get {
            if ( userPermissionSetIds == null ) {
                if ( PermissionsDirectoryController.userPermissionSetAssignments != null ) {
                    Set<Id> newSet = new Set<Id>();
                    for ( PermissionSetAssignment userPermissionSetAssignment : PermissionsDirectoryController.userPermissionSetAssignments ) {
                        newSet.add( userPermissionSetAssignment.PermissionSetId );
                    }
                    userPermissionSetIds = newSet;
                }
            }
            return userPermissionSetIds;
        }
        private set;
    }

    private static List<PermissionSet> userPermissionSets {
        private get {
            if ( userPermissionSets == null ) {
                if ( PermissionsDirectoryController.userPermissionSetIds != null ) {
                    String soqlQuery = SecurityController.getAccessibleSelectQuery( PermissionSet.getSObjectType() );
                    // protect from ExternalObjectException in Apex Test executions during Change Set Validation...
                    if ( Test.isRunningTest() ) {
                        soqlQuery = 'SELECT Id , ProfileId , PermissionsCustomizeApplication FROM PermissionSet';
                    }
                    if ( String.isNotBlank( soqlQuery ) && soqlQuery.contains( 'ProfileId' ) ) {
                        // Profile.Name is needed for the Lightning Component UX...
                        // ~ when ProfileId is accessible, then prepend query with Profile.Name...
                        soqlQuery = soqlQuery.replace( 'SELECT ' , 'SELECT Profile.Name , ' );
                    }
                    soqlQuery += ' WHERE ( Id IN :userPermissionSetIds )';
                    userPermissionSets = Database.query( soqlQuery );
                }
            }
            return userPermissionSets;
        }
        private set;
    }

    private static Map<Id,PermissionSet> userPermissionSetsMap {
        private get {
            if ( userPermissionSetsMap == null ) {
                if ( PermissionsDirectoryController.userPermissionSets != null ) {
                    userPermissionSetsMap = new Map<Id,PermissionSet>( PermissionsDirectoryController.userPermissionSets );
                }
            }
            return userPermissionSetsMap;
        }
        private set;
    }

    private static Set<String> ignoredPermissionSetFields {
        private get {
            if ( ignoredPermissionSetFields == null ) {
                Set<String> newSet = new Set<String>();
                newSet.add( 'Id' );
                newSet.add( 'Name' );
                newSet.add( 'Label' );
                newSet.add( 'LicenseId' );
                newSet.add( 'ProfileId' );
                newSet.add( 'IsOwnedByProfile' );
                newSet.add( 'IsCustom' );
                newSet.add( 'Description' );
                newSet.add( 'CreatedDate' );
                newSet.add( 'CreatedById' );
                newSet.add( 'LastModifiedDate' );
                newSet.add( 'LastModifiedById' );
                newSet.add( 'SystemModstamp' );
                newSet.add( 'NamespacePrefix' );
                newSet.add( 'HasActivationRequired' );
                newSet.add( 'PermissionSetGroupId' );
                newSet.add( 'Type' );
                ignoredPermissionSetFields = newSet;
            }
            return ignoredPermissionSetFields;
        }
        private set;
    }

    private static List<String> accessiblePermissionSetFieldNames {
        private get {
            if ( accessiblePermissionSetFieldNames == null ) {
                accessiblePermissionSetFieldNames = SecurityController.getAccessibleFieldNames( PermissionSet.getSObjectType() );
            }
            return accessiblePermissionSetFieldNames;
        }
        private set;
    }

    //
    // Objects
    // ~ accessor for Map from Object API Name to Object Label...
    //

    private static String getSObjectLabel( String sObjectName ) {
        String sObjectLabel = null;
        if ( String.isNotBlank( sObjectName ) ) {
            if ( ( PermissionsDirectoryController.sObjectLabelMap != null )
                && PermissionsDirectoryController.sObjectLabelMap.containsKey( sObjectName )
               )
            {
                sObjectLabel = PermissionsDirectoryController.sObjectLabelMap.get( sObjectName );
            } else if ( PermissionsDirectoryController.globalDescribe != null ) {
                SObjectType soType = PermissionsDirectoryController.globalDescribe.get( sObjectName );
                if ( soType != null ) {
                    sObjectLabel = soType.getDescribe().getLabel();
                    if ( String.isNotBlank( sObjectLabel )
                        && ( PermissionsDirectoryController.sObjectLabelMap != null )
                       )
                    {
                        PermissionsDirectoryController.sObjectLabelMap.put( sObjectName , sObjectLabel );
                    }
                }
            }
        }
        return sObjectLabel;
    }

    private static Map<String,String> sObjectLabelMap {
        private get {
            if ( sObjectLabelMap == null ) {
                sObjectLabelMap = new Map<String,String>();
            }
            return sObjectLabelMap;
        }
        private set;
    }

    //
    // PermissionSet Fields
    // ~ accessor for Map from Field API Name to Field Label...
    //

    private static String getPermissionFieldLabel( String permissionFieldName ) {
        String permissionFieldLabel = null;
        if ( String.isNotBlank( permissionFieldName )
            && ( PermissionsDirectoryController.permissionSetFieldsMap != null )
            && PermissionsDirectoryController.permissionSetFieldsMap.containsKey( permissionFieldName )
           )
        {
            Schema.SObjectField field = PermissionsDirectoryController.permissionSetFieldsMap.get( permissionFieldName );
            if ( field != null ) {
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                if ( fieldDescribe != null ) {
                    String fieldLabel = fieldDescribe.getLabel();
                    if ( String.isNotBlank( fieldLabel) ) {
                        permissionFieldLabel = fieldLabel;
                    }
                }
            }
        }
        // fallback to API Name when Label is missing...
        if ( String.isBlank( permissionFieldLabel ) ) {
            permissionFieldLabel = permissionFieldName;
        }
        return permissionFieldLabel;
    }

    // replace this fields.getMap() with SecurityController solution...
    private static Map<String,Schema.SObjectField> permissionSetFieldsMap {
        private get {
            if ( ( permissionSetFieldsMap == null )
                && ( PermissionsDirectoryController.globalDescribe != null )
               )
            {
                permissionSetFieldsMap = PermissionsDirectoryController.globalDescribe.get( 'PermissionSet' ).getDescribe().fields.getMap();
            }
            return permissionSetFieldsMap;
        }
        private set;
    }

    private static Map<String,Schema.SObjectType> globalDescribe {
        private get {
            if ( globalDescribe == null ) {
                globalDescribe = Schema.getGlobalDescribe();
            }
            return globalDescribe;
        }
        private set;
    }

    //
    // Permission Set Permissions
    //

    // Map from Permission.Label to AuraPermission
    private static Map<String,AuraPermission> userPermissionsMap {
        private get {
            if ( userPermissionsMap == null ) {
                if ( ( PermissionsDirectoryController.userPermissionSets != null )
                    && ( PermissionsDirectoryController.accessiblePermissionSetFieldNames != null )
                    && ( PermissionsDirectoryController.ignoredPermissionSetFields != null )
                   )
                {
                    Map<String,AuraPermission> newMap = new Map<String,AuraPermission>();
                    for ( PermissionSet source : PermissionsDirectoryController.userPermissionSets ) {
                        Map<String,Object> populatedPermissionSetFields = source.getPopulatedFieldsAsMap();
                        for ( String permissionSetFieldName : PermissionsDirectoryController.accessiblePermissionSetFieldNames ) {
                            // ignore system level fields from the PermissionSet Object...
                            // ~ i.e. Id, Name, LicenseId, CreatedById, etc...
                            // ~ only fields with a name beginning with "Permissions" are relavant...
                            if ( ! PermissionsDirectoryController.ignoredPermissionSetFields.contains( permissionSetFieldName )
                                && ( populatedPermissionSetFields != null )
                                && populatedPermissionSetFields.containsKey( permissionSetFieldName )
                               )
                            {
                                Object fieldValue = source.get( permissionSetFieldName );
                                if ( ( fieldValue InstanceOf Boolean ) ) {
                                    Boolean fieldValueBoolean = (Boolean)fieldValue;
                                    if ( fieldValueBoolean == True ) {
                                        //
                                        // ...found a <userPermission> that has been granted to the current User...
                                        //
                                        // construct a permission wrapper object that can be easily digested by javascript...
                                        if ( ! newMap.containsKey( permissionSetFieldName ) ) {
                                            newMap.put( permissionSetFieldName , new AuraPermission() );
                                        }
                                        AuraPermission wrapper = newMap.get( permissionSetFieldName );
                                        wrapper.name = permissionSetFieldName;
                                        // Label falls back to API Name when blank/missing...
                                        wrapper.label = PermissionsDirectoryController.getPermissionFieldLabel( permissionSetFieldName );
                                        // store the source PermissionSet record into the wrapper...
                                        if ( wrapper.sources == null ) {
                                            wrapper.sources = new Set<PermissionSet>();
                                        }
                                        wrapper.sources.add( source );
                                        // store permission wrapper object in response object...
                                        newMap.put( permissionSetFieldName , wrapper );
                                    }
                                }
                            }
                        }
                    }
                    userPermissionsMap = newMap;
                }
            }
            return userPermissionsMap;
        }
        private set;
    }

    //
    // Object Permissions
    //

    //
    // SELECT Id , ParentId , Parent.Name , Parent.Label , Parent.ProfileId , Parent.Profile.Name , Parent.PermissionSetGroupId , SObjectType , PermissionsCreate , PermissionsRead , PermissionsEdit , PermissionsDelete , PermissionsViewAllRecords , PermissionsModifyAllRecords , CreatedDate
    // FROM ObjectPermissions
    // WHERE ( ParentId IN :userPermissionSetIds )
    // ORDER BY CreatedDate DESC
    //
    private static List<ObjectPermissions> userObjectPermissions {
        private get {
            if ( userObjectPermissions == null ) {
                if ( PermissionsDirectoryController.userPermissionSetIds != null ) {
                    String soqlQuery = SecurityController.getAccessibleSelectQuery( ObjectPermissions.getSObjectType() );
                    soqlQuery = soqlQuery.replace( 'SELECT ' , 'SELECT Parent.Name , Parent.Label , Parent.ProfileId , Parent.Profile.Name , Parent.PermissionSetGroupId , ' );
                    soqlQuery += ' WHERE ( ParentId IN :userPermissionSetIds )';
                    userObjectPermissions = Database.query( soqlQuery );
                }
            }
            return userObjectPermissions;
        }
        private set;
    }

    // Map from sObject.Label to AuraPermission
    private static Map<String,AuraPermission> objectPermissionsMap {
        private get {
            if ( objectPermissionsMap == null ) {
                Map<String,AuraPermission> newMap = new Map<String,AuraPermission>();
                for ( ObjectPermissions userObjectPermission : PermissionsDirectoryController.userObjectPermissions ) {
                    //
                    // ...found an <objectPermission> that has been granted to the current User...
                    //
                    // construct a permission wrapper object that can be easily digested by javascript...
                    String accessibleSObjectName = userObjectPermission.SObjectType;
                    if ( ! newMap.containsKey( accessibleSObjectName ) ) {
                        newMap.put( accessibleSObjectName , new AuraPermission() );
                    }
                    AuraPermission wrapper = newMap.get( accessibleSObjectName );
                    wrapper.name = accessibleSObjectName;
                    // Label falls back to API Name when blank/missing...
                    String sObjectLabel = PermissionsDirectoryController.getSObjectLabel( accessibleSObjectName );
                    if ( String.isBlank( sObjectLabel ) ) {
                        sObjectLabel = accessibleSObjectName;
                    }
                    wrapper.label = sObjectLabel;

                    //
                    //
                    //

                    // rollup the Permissions*** fields of the allowed ObjectPermissions to the wrapper AuraPermission...
                    // ~ convert the 6 possible Boolean fields into a single String description...
                    // ~ i.e. "Read, Create, Edit, Delete, View All, Modify All"
                    List<ComparableAllow> allowsRollup = wrapper.allowsRollup;
                    if ( allowsRollup == null ) {
                        allowsRollup = new List<ComparableAllow>();
                    }
                    if ( userObjectPermission.PermissionsRead ) {
                        ComparableAllow comparableAllow = new ComparableAllow();
                        comparableAllow.label = 'Read';
                        if ( ! allowsRollup.contains( comparableAllow ) ) {
                            allowsRollup.add( comparableAllow );
                        }
                    }
                    if ( userObjectPermission.PermissionsCreate ) {
                        ComparableAllow comparableAllow = new ComparableAllow();
                        comparableAllow.label = 'Create';
                        if ( ! allowsRollup.contains( comparableAllow ) ) {
                            allowsRollup.add( comparableAllow );
                        }
                    }
                    if ( userObjectPermission.PermissionsEdit ) {
                        ComparableAllow comparableAllow = new ComparableAllow();
                        comparableAllow.label = 'Edit';
                        if ( ! allowsRollup.contains( comparableAllow ) ) {
                            allowsRollup.add( comparableAllow );
                        }
                    }
                    if ( userObjectPermission.PermissionsDelete ) {
                        ComparableAllow comparableAllow = new ComparableAllow();
                        comparableAllow.label = 'Delete';
                        if ( ! allowsRollup.contains( comparableAllow ) ) {
                            allowsRollup.add( comparableAllow );
                        }
                    }
                    if ( userObjectPermission.PermissionsViewAllRecords ) {
                        ComparableAllow comparableAllow = new ComparableAllow();
                        comparableAllow.label = 'View All';
                        if ( ! allowsRollup.contains( comparableAllow ) ) {
                            allowsRollup.add( comparableAllow );
                        }
                    }
                    if ( userObjectPermission.PermissionsModifyAllRecords ) {
                        ComparableAllow comparableAllow = new ComparableAllow();
                        comparableAllow.label = 'Modify All';
                        if ( ! allowsRollup.contains( comparableAllow ) ) {
                            allowsRollup.add( comparableAllow );
                        }
                    }
                    // sort and implode the rollup of allowed permission labels...
                    allowsRollup.sort();
                    String allows = '';
                    for ( ComparableAllow allow : allowsRollup ) {
                        allows += allow.label + ', ';
                    }
                    wrapper.allowsRollup = allowsRollup;
                    wrapper.allows = allows.trim().removeEnd( ',' );

                    //
                    //
                    //

                    // identify the source PermissionSet record...
                    if ( ( userObjectPermission.ParentId != null )
                        && ( PermissionsDirectoryController.userPermissionSetsMap != null )
                        && PermissionsDirectoryController.userPermissionSetsMap.containsKey( userObjectPermission.ParentId )
                        )
                    {
                        // store the source PermissionSet record into the wrapper...
                        PermissionSet source = PermissionsDirectoryController.userPermissionSetsMap.get( userObjectPermission.ParentId );
                        if ( source != null ) {
                            if ( wrapper.sources == null ) {
                                wrapper.sources = new Set<PermissionSet>();
                            }
                            wrapper.sources.add( source );
                        }
                    }
                    // store permission wrapper object in response object...
                    newMap.put( accessibleSObjectName , wrapper );
                }
                objectPermissionsMap = newMap;
            }
            return objectPermissionsMap;
        }
        private set;
    }

    //
    // Custom Permissions
    //

    //
    // SELECT Id , ParentId , SetupEntityId , SetupEntityType
    // FROM SetupEntityAccess
    // WHERE ( SetupEntityType = 'CustomPermission' ) AND ( ParentId IN :userPermissionSetIds )
    // ORDER BY Parent.Name ASC
    // 
    private static List<SetupEntityAccess> userSetupEntityAccesses {
        private get {
            if ( userSetupEntityAccesses == null ) {
                if ( PermissionsDirectoryController.userPermissionSetIds != null ) {
                    String soqlQuery = SecurityController.getAccessibleSelectQuery( SetupEntityAccess.getSObjectType() );
                    soqlQuery = soqlQuery.replace( 'SELECT ' , 'SELECT Parent.Name , Parent.Label , Parent.ProfileId , Parent.Profile.Name , Parent.PermissionSetGroupId , ' );
                    soqlQuery += ' WHERE ( ( SetupEntityType = \'CustomPermission\' ) AND ( ParentId IN :userPermissionSetIds ) )';
                    userSetupEntityAccesses = Database.query( soqlQuery );
                }
            }
            return userSetupEntityAccesses;
        }
        private set;
    }

    private static Set<Id> userCustomPermissionIds {
        private get {
            if ( userCustomPermissionIds == null ) {
                if ( PermissionsDirectoryController.userSetupEntityAccesses != null ) {
                    Set<Id> newSet = new Set<Id>();
                    for ( SetupEntityAccess userSetupEntityAccess : PermissionsDirectoryController.userSetupEntityAccesses ) {
                        if ( userSetupEntityAccess.SetupEntityType == 'CustomPermission' ) {
                            newSet.add( userSetupEntityAccess.SetupEntityId );
                        }
                    }
                    userCustomPermissionIds = newSet;
                }
            }
            return userCustomPermissionIds;
        }
        private set;
    }

    private static List<CustomPermission> userCustomPermissions {
        private get {
            if ( userCustomPermissions == null ) {
                if ( PermissionsDirectoryController.userPermissionSetIds != null ) {
                    String soqlQuery = SecurityController.getAccessibleSelectQuery( CustomPermission.getSObjectType() );
                    soqlQuery += ' WHERE ( Id IN :userCustomPermissionIds )';
                    userCustomPermissions = Database.query( soqlQuery );
                }
            }
            return userCustomPermissions;
        }
        private set;
    }

    private static Map<Id,CustomPermission> userCustomPermissionsMap {
        private get {
            if ( userCustomPermissionsMap == null ) {
                if ( PermissionsDirectoryController.userCustomPermissions != null ) {
                    userCustomPermissionsMap = new Map<Id,CustomPermission>( PermissionsDirectoryController.userCustomPermissions );
                }
            }
            return userCustomPermissionsMap;
        }
        private set;
    }

    // Map from CustomPermission.DeveloperName to AuraPermission
    private static Map<String,AuraPermission> customPermissionsMap {
        private get {
            if ( customPermissionsMap == null ) {
                if ( PermissionsDirectoryController.userCustomPermissionsMap != null ) {
                    Map<String,AuraPermission> newMap = new Map<String,AuraPermission>();
                    for ( SetupEntityAccess userSetupEntityAccess : PermissionsDirectoryController.userSetupEntityAccesses ) {
                        if ( PermissionsDirectoryController.userCustomPermissionsMap.containsKey( userSetupEntityAccess.SetupEntityId ) ) {
                            CustomPermission userCustomPermission = PermissionsDirectoryController.userCustomPermissionsMap.get( userSetupEntityAccess.SetupEntityId );
                            if ( userCustomPermission != null ) {
                                //
                                // ...found a <customPermission> that has been granted to the current User...
                                //
                                // construct a permission wrapper object that can be easily digested by javascript...
                                String customPermissionName = userCustomPermission.DeveloperName;
                                if ( ! newMap.containsKey( customPermissionName ) ) {
                                    newMap.put( customPermissionName , new AuraPermission() );
                                }
                                AuraPermission wrapper = newMap.get( customPermissionName );
                                wrapper.name = customPermissionName;
                                wrapper.label = userCustomPermission.MasterLabel;
                                // identify the source PermissionSet record...
                                if ( ( userSetupEntityAccess.ParentId != null )
                                    && ( PermissionsDirectoryController.userPermissionSetsMap != null )
                                    && PermissionsDirectoryController.userPermissionSetsMap.containsKey( userSetupEntityAccess.ParentId )
                                    )
                                {
                                    PermissionSet source = PermissionsDirectoryController.userPermissionSetsMap.get( userSetupEntityAccess.ParentId );
                                    // store the source PermissionSet record into the wrapper...
                                    if ( source != null ) {
                                        if ( wrapper.sources == null ) {
                                            wrapper.sources = new Set<PermissionSet>();
                                        }
                                        wrapper.sources.add( source );
                                    }
                                }
                                // store permission wrapper object in response object...
                                newMap.put( customPermissionName , wrapper );
                            }
                        }
                    }
                    customPermissionsMap = newMap;
                }
            }
            return customPermissionsMap;
        }
        private set;
    }

    //
    //
    //

}
//