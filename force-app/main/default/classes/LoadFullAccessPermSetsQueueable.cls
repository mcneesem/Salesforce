public class LoadFullAccessPermSetsQueueable implements Queueable {

    private List<String> objectApiNames = new List<String>();
    private Map<id,Boolean> psMap = new Map<id,Boolean>();
    private Boolean oUpsertFlag;
    
    public LoadFullAccessPermSetsQueueable(List<String> objectApiNames, map<id,Boolean> psMap, Boolean oUpsertFlag) {
        this.objectApiNames = objectApiNames; 
        this.psMap = psMap;
        this.oUpsertFlag = oUpsertFlag; // upsert flag for Object Permissions
    }
    
    public void execute(QueueableContext context) {

        String currObjName = objectApiNames.remove(0); // remove top item from objectApiNames in each link in the chain

        // In first few passes, upsert object permissions for all the objects to resolve any dependencies;
		// once all upserts are successful, flag will be disabled
        if (oUpsertFlag) {
            List<String> objUpsertList = new List<String>();
            objUpsertList.add(currObjName);
            objUpsertList.addAll(objectApiNames);
            oUpsertFlag = loadObjectPermissions(psMap, objectApiNames, objUpsertList, oUpsertFlag);
		}
        
        loadFieldPermissions(psMap, currObjName); // upsert Field Permissions for first object in list

		// chain new job for next object
        if (objectApiNames.size() > 0) {
            Id jobID = System.enqueueJob(new LoadFullAccessPermSetsQueueable(objectApiNames, psMap, oUpsertFlag));
			System.debug( ' ~ nextJob=' + jobID );
            System.debug( ' ~ objects remaining=' + objectApiNames.size() );
        } else {
            System.debug( ' ~ This was the final job for LoadOBPermSetsQueueable' );
        }
    }

    // ************************ Object Permissions ************************
    public static Boolean loadObjectPermissions(Map<id,Boolean> psMap, List<String> objectApiNames, List<String> objUpsertList, Boolean oUpsertFlag) {
        List<ObjectPermissions> opList = new List<ObjectPermissions>();
        for(Id key : psMap.keySet()) { // loop through the perm sets
            // populate map of current object permissions records with each permission set Id as key
            map<string, ObjectPermissions> mCurrentObjectPerms = new Map<string, ObjectPermissions>();
            for (ObjectPermissions oPerm : [SELECT Id, SObjectType, ParentId
                    FROM ObjectPermissions WHERE ParentId = :key AND SObjectType IN :objUpsertList]) {
                mCurrentObjectPerms.put(oPerm.SObjectType, oPerm);
            }
            for (String objectApiName : objUpsertList) {
                ObjectPermissions op= new ObjectPermissions();
                if (mCurrentObjectPerms.size() > 0 && mCurrentObjectPerms.containsKey(objectApiName)) {
                    op.Id = mCurrentObjectPerms.get(objectApiName).Id;
                } else {
                    op.ParentId = key;// id of permission set
                    op.SobjectType = objectApiName;
                }
                op.PermissionsRead = true;
                op.PermissionsViewAllRecords = true;
                op.PermissionsCreate = psMap.get(key);
                op.PermissionsDelete = psMap.get(key);
                op.PermissionsEdit = psMap.get(key);
                op.PermissionsModifyAllRecords = psMap.get(key);
                opList.add(op);
            }
        }
        Database.UpsertResult[] oprList = Database.upsert(opList, false); // object perms results

        integer depCount = 0;
        Set<String> objBadList = new Set<String>();
        for (Database.UpsertResult opr : oprList) { // retrieve errors for failed record upserts
            if (!opr.isSuccess()) {
                for(Database.Error err : opr.getErrors()) {
                    System.debug(' ~ ObjectPermissions error occurred: ' + err.getStatusCode() + ': ' + err.getMessage());
                    if(err.getMessage().contains('depends on')){depCount++;}
                    if(err.getMessage().contains('SObject Type Name: bad value for restricted picklist field')){
                        objBadList.add(err.getMessage().remove('SObject Type Name: bad value for restricted picklist field: '));
                    }
                }
            }
        }
        if (oUpsertFlag) { // after first pass, remove bad names from object list
            System.debug( ' ~ original Object count=' + objUpsertList.size() );
            for(integer i= objectApiNames.size()-1; i>= 0 ; i--){ // remove bad object names from initial list
                if(!objBadList.isEmpty() && objBadList.contains(objectApiNames[i])){
                    objectApiNames.remove(i);
                }
            }
            System.debug( ' ~ Bad List count=' + objBadList.size() );
            System.debug( ' ~ updated Object count=' + (objectApiNames.size()+1) );
        }
        if (depCount > 0) {
            System.debug( ' ~ Object dependency errors=' + depCount );
        } else {
            oUpsertFlag = false; // if no dependency errors, stop the object permissions upsert iterations
        }
        return oUpsertFlag;
    }

    // ************************ Field Permissions ************************
    public static void loadFieldPermissions(Map<id,Boolean> psMap, String currObjName) {
        Set<String> skipFields = new Set<String>{'Id','IsDeleted','CreatedDate','LastModifiedDate','SystemModstamp','UserRecordAccessId',
            	'LastActivityDate','PhotoUrl','MasterRecordId','RecordTypeId','CreatedById','LastModifiedById','OwnerId','Name','CurrencyIsoCode',
           		'LastViewedDate','LastReferencedDate','RecordVisibilityId'};

        List<FieldDefinition> fieldDefList =  [SELECT EntityDefinition.QualifiedApiName, QualifiedApiName, IsCalculated
            FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = :currObjName AND IsNameField=false AND QualifiedApiName NOT IN :skipFields];

        List<FieldPermissions> fpList = new List<FieldPermissions>();
        for (Id key : psMap.keySet()) {
			// populate map of current field permissions records for current permission set with each field name as key
			map<string, FieldPermissions> mCurrentFieldPerms = new Map<string, FieldPermissions>();
			for (FieldPermissions fPerm : [SELECT Id, Field, SObjectType, ParentId
					FROM FieldPermissions WHERE ParentId = :key AND SObjectType = :currObjName]) {
				mCurrentFieldPerms.put(fPerm.Field, fPerm);
			}
			for (FieldDefinition field : fieldDefList) {
                FieldPermissions fp = new FieldPermissions();
				String fName = currObjName+'.'+field.QualifiedApiName;
                if (mCurrentFieldPerms.size() > 0 && mCurrentFieldPerms.containsKey(fName)) {
					fp.Id = mCurrentFieldPerms.get(fName).Id;
				} else {
					fp.ParentId = key; // id of permission set
					fp.SobjectType = currObjName;
					fp.Field = fName;
				}
                fp.PermissionsEdit = (field.IsCalculated) ? false : psMap.get(key);
                fp.PermissionsRead = true;
                fpList.add(fp);
            }
        }
        Database.upsert(fpList, false);
    }
}