public class LoadFullAccessPermSetsQueueable implements Queueable {
    // test w/ LoadFullAccessPermSetsQueueableTest (93%)

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

        // in first few jobs, upsert object permissions for entire objects list to resolve any dependencies;
		// once all obj perm upserts are successful, flag will be disabled
        if (oUpsertFlag) {
            oUpsertFlag = loadObjectPermissions(psMap, objectApiNames, currObjName, oUpsertFlag);
		}
        
        loadFieldPermissions(psMap, currObjName); // upsert Field Permissions for first object in list

		// chain new job for next object
        if (objectApiNames.size() > 0) {
            Id jobID = System.enqueueJob(new LoadFullAccessPermSetsQueueable(objectApiNames, psMap, oUpsertFlag));
            System.debug( ' ~ objects remaining=' + objectApiNames.size() );
			System.debug( ' ~ nextJob=' + jobID );
        } else {
            System.debug( ' ~ This was the final job for LoadOBPermSetsQueueable' );
            sendCompletionEmail();
        }
    }

    // ************************ Object Permissions ************************
    public static Boolean loadObjectPermissions(Map<id,Boolean> psMap, List<String> objectApiNames, String currObjName, Boolean oUpsertFlag) {
        List<ObjectPermissions> opList = new List<ObjectPermissions>();
        List<String> objUpsertList = new List<String>{currObjName};
            objUpsertList.addAll(objectApiNames);

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
        if (!objBadList.isEmpty()) { // after first pass, remove bad names from object list
            for(integer i= objectApiNames.size()-1; i>= 0 ; i--){ // remove bad object names from initial list
                if(objBadList.contains(objectApiNames[i])){
                    objectApiNames.remove(i);
                }
            }
            System.debug( ' ~ bad Object name count=' + objBadList.size() );
        }
        if (depCount > 0) {
            System.debug( ' ~ dependent Object count=' + depCount );
        } else {
            System.debug( ' ~  Object Permissions upserts complete' );
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

    // ************************ Chain Completion Email ************************
    public void sendCompletionEmail(){
        Messaging.SingleEmailMessage oEmail = new Messaging.SingleEmailMessage();
        oEmail.setSubject(OrgSettings__c.getOrgDefaults().SandboxName__c + ': LoadFullAccessPermSets job finished');
        oEmail.setTargetObjectId(UserInfo.getUserId());
        oEmail.setSaveAsActivity(false);
        oEmail.setPlainTextBody('Your LoadFullAccessPermSets job has finished for org: ' + OrgSettings__c.getOrgDefaults().SandboxName__c + '.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{oEmail});
    }
}