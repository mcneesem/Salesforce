public class LoadFullAccessPermSetsQueueable implements Queueable {
    // test w/ LoadFullAccessPermSetsQueueableTest (80%)

    // **************************************************************************************************
	//  Author:         Matthew McNeese
    //  MethodName:     LoadFullAccessPermSetsQueueable 
	//  Description :   Queueable method for loading two specified PermissionSets with Object and Field
    //                  Permissions for specified list of object API names. For each object name in the
    //                  specified list, method upserts ObjectPermissions and then FieldPermissions for
    //                  that object into each Perm Set and then strings a new Queueable job to do the same
    //                  for the next object name in the list. This Queueable chain can be aborted by
    //                  unchecking 'EnableLoadPermSetChain' field on 'QueueableSettings' Custom Setting.
    // ***************************************************************************************************

    private List<String> objectApiNames = new List<String>();
    private Id readPermSetId;
    private Id editPermSetId;
    Map<String, Integer> depRetry = new Map<String, Integer>();

    public LoadFullAccessPermSetsQueueable(List<String> objectApiNames, Id readPermSetId, Id editPermSetId, Map<String, Integer> depRetry) {
        this.objectApiNames = objectApiNames;
        this.readPermSetId = readPermSetId;
        this.editPermSetId = editPermSetId;
        this.depRetry = depRetry;
    }

    public void execute(QueueableContext context) {

        String currObjName = objectApiNames.remove(0); // remove top item from objectApiNames in each link in chain

        createErrorLog('LoadFullAccessPermSetsQueueable', 'execute', 'Loading ObjectPermissions for: ' + currObjName);
        if (!String.isBlank(readPermSetId)) loadObjectPermissions(readPermSetId, false, objectApiNames, currObjName, depRetry, true); // upsert read Object Permissions for all objects in list
        if (!String.isBlank(editPermSetId)) loadObjectPermissions(editPermSetId, true, objectApiNames, currObjName, depRetry, true); // upsert edit Object Permissions for all objects in list

        createErrorLog('LoadFullAccessPermSetsQueueable', 'execute', 'Loading FieldPermissions for: ' + currObjName);
        if (!String.isBlank(readPermSetId)) loadFieldPermissions(readPermSetId, false, currObjName); // upsert read Field Permissions for first object in list
        if (!String.isBlank(editPermSetId)) loadFieldPermissions(editPermSetId, true, currObjName); // upsert edit Field Permissions for first object in list

        if (!String.isBlank(readPermSetId) || !String.isBlank(editPermSetId)) {
            if (QueueableSettings__c.getOrgDefaults().EnableLoadPermSetChain__c) {
                if ( objectApiNames.size() > 0 ) { // chain new job for next object
                    System.enqueueJob(new LoadFullAccessPermSetsQueueable(objectApiNames, readPermSetId, editPermSetId, depRetry));
                    createErrorLog('LoadFullAccessPermSetsQueueable', 'execute', 'objectCount remaining=' + objectApiNames.size() );
                } else {
                    sendCompletionEmail();
                    createErrorLog('LoadFullAccessPermSetsQueueable', 'execute', 'This was the final job for LoadFullAccessPermSetsQueueable');
                }
            } else {
                createErrorLog('LoadFullAccessPermSetsQueueable', 'execute', 'QueueableSettings__c.EnableLoadPermSetChain__c is disabled');
            }
        }
    }

    // *************************************** Object Permissions ************************************************
    //  Description :   Upserts ObjectPermssions for specified object name into specified Perm Set recursivesly.
    //                  Method analyzes upsert results and (1) initiates a retry if ViewAll/ModifyAll object 
    //                  permission error is encountered, (2) moves object name to bottom of list if object
    //                  permission depency is encountered. Dependency retries are limited to five attempts.
    // ***********************************************************************************************************
    public static void loadObjectPermissions(Id permSetId, Boolean editFlag, List<String> objectApiNames, String currObjName, Map<String, Integer> depRetry, Boolean allPermFlag) {
        List<ObjectPermissions> opList = new List<ObjectPermissions>();
        Boolean retryFlag = false;

        // For current PermissionSet, populate map of current ObjectPermissions records using SObjectType as key
        Map<String, ObjectPermissions> mCurrentObjectPerms = new Map<String, ObjectPermissions>();
        for (ObjectPermissions oPerm : [SELECT Id, SObjectType, ParentId
                FROM ObjectPermissions WHERE ParentId = :permSetId AND SObjectType = :currObjName]) {
            mCurrentObjectPerms.put(oPerm.SObjectType, oPerm);
        }
        ObjectPermissions op= new ObjectPermissions();
        if (mCurrentObjectPerms.size() > 0 && mCurrentObjectPerms.containsKey(currObjName)) {
            op.Id = mCurrentObjectPerms.get(currObjName).Id;
        } else {
            op.ParentId = permSetId;
            op.SobjectType = currObjName;
        }
        op.PermissionsRead = true;
        op.PermissionsCreate = editFlag;
        op.PermissionsDelete = editFlag;
        op.PermissionsEdit = editFlag;
        if (allPermFlag) {
            op.PermissionsViewAllRecords = true;
            op.PermissionsModifyAllRecords = editFlag;
        }
        opList.add(op);

        Database.UpsertResult[] oprList = Database.upsert(opList, false);

        if (!oprList[0].isSuccess()) {
            for(Database.Error err : oprList[0].getErrors()) {
                if ( err.getMessage().contains('depends on')) {
                    depRetry.put(currObjName, depRetry.containsKey(currObjName) ? depRetry.get(currObjName)+1 : 1);
                    if (depRetry.get(currObjName) > 5) {
                        createErrorLog('LoadFullAccessPermSetsQueueable', 'loadObjectPermissions', 'exceeded retry limit for object: ' + currObjName);
                    } else if (!objectApiNames.contains(currObjName)) {
                        objectApiNames.add(currObjName);
                        createErrorLog('LoadFullAccessPermSetsQueueable', 'loadObjectPermissions', 'object dependency found for Object: ' + currObjName + '; moving to bottom of list');
                    }
                } else if ( err.getMessage().contains('The following permission isn\'t allowed: View All')) {
                    createErrorLog('LoadFullAccessPermSetsQueueable', 'loadObjectPermissions', 'View All error found for Object: ' + currObjName + '; disabling allPermFlag');
                    loadObjectPermissions(permSetId, editFlag, objectApiNames, currObjName, depRetry, false);
                } else if (!err.getMessage().contains('bad value for restricted picklist field')) {
                    createErrorLog('LoadFullAccessPermSetsQueueable', 'loadObjectPermissions', 'ObjectPermissions error occurred for Perm Set: ' + permSetId + ' : ' + err.getMessage());
                }
            }
        }
    }

    // ************************************ Field Permissions ************************************
    //  Description :   Upserts FieldPermssions for all fields of specified object name into
    //                  specified Perm Set.
    // *******************************************************************************************
    public static void loadFieldPermissions(Id permSetId, Boolean editFlag, String currObjName) {
        Set<String> skipFields = new Set<String>{'Id','IsDeleted','CreatedDate','LastModifiedDate','SystemModstamp','UserRecordAccessId',
            	'LastActivityDate','PhotoUrl','MasterRecordId','RecordTypeId','CreatedById','LastModifiedById','OwnerId','Name','CurrencyIsoCode',
           		'LastViewedDate','LastReferencedDate','RecordVisibilityId'};

        List<FieldDefinition> fieldDefList =  [SELECT EntityDefinition.QualifiedApiName, QualifiedApiName, IsCalculated
            FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = :currObjName AND IsNameField=false AND QualifiedApiName NOT IN :skipFields];

        List<FieldPermissions> fpList = new List<FieldPermissions>();

        // populate map of current field permissions records for current permission set with each field name as key
        Map<String, FieldPermissions> mCurrentFieldPerms = new Map<String, FieldPermissions>();
        for (FieldPermissions fPerm : [SELECT Id, Field, SObjectType, ParentId
                FROM FieldPermissions WHERE ParentId = :permSetId AND SObjectType = :currObjName]) {
            mCurrentFieldPerms.put(fPerm.Field, fPerm);
        }
        for (FieldDefinition field : fieldDefList) {
            FieldPermissions fp = new FieldPermissions();
            String fName = currObjName+'.'+field.QualifiedApiName;
            if (mCurrentFieldPerms.size() > 0 && mCurrentFieldPerms.containsKey(fName)) {
                fp.Id = mCurrentFieldPerms.get(fName).Id;
            } else {
                fp.ParentId = permSetId; // id of permission set
                fp.SobjectType = currObjName;
                fp.Field = fName;
            }
            fp.PermissionsEdit = (field.IsCalculated) ? false : editFlag;
            fp.PermissionsRead = true;
            fpList.add(fp);
        }

        Database.UpsertResult[] fprList = Database.upsert(fpList, false); // field perms results

        Integer errLogCount = 0; // reduce ErrorLog calls by just collecting an error count
        for (Database.UpsertResult fpr : fprList) { // retrieve errors for failed record upserts
            if (!fpr.isSuccess()) {
                for (Database.Error err : fpr.getErrors()) {
                    if (!err.getMessage().contains('bad value for restricted picklist field') && // ignore ineligible field names
                        !err.getMessage().contains('Read only field')) {
                        if (errLogCount++ < 1) createErrorLog('LoadFullAccessPermSetsQueueable', 'loadFieldPermissions', 'FieldPermissions error occurred for Object: ' + currObjName + ' on Perm Set: ' + permSetId + ' : ' + err.getMessage());
                    }
                }
            }
        }
        if (errLogCount > 0) createErrorLog('LoadFullAccessPermSetsQueueable', 'loadFieldPermissions', errLogCount + ' FieldPermissions errors occurred for Object: ' + currObjName + ' on Perm Set: ' + permSetId);
    }

    // ************************ Chain Completion Email ************************
    public static void sendCompletionEmail(){
        Messaging.SingleEmailMessage oEmail = new Messaging.SingleEmailMessage();
        oEmail.setSubject(OrgSettings__c.getOrgDefaults().SandboxName__c + ': LoadFullAccessPermSets job finished');
        oEmail.setTargetObjectId(UserInfo.getUserId());
        oEmail.setSaveAsActivity(false);
        oEmail.setPlainTextBody('Your LoadFullAccessPermSets job has finished for org: ' + OrgSettings__c.getOrgDefaults().SandboxName__c + '.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{oEmail});
    }

    // ************************ Write Error Log ************************
    @future
    public static void createErrorLog(String className, String methName, String descText){
        NSP_Error_Log__c log = new NSP_Error_Log__c();
        log.NSP_Class__c = className;
        log.NSP_Method__c = methName;
        log.NSP_Description__c = descText;
        Insert log;
    }
}