public with sharing class Nps_CloneServicePlanProjectController {
    // test w/ Nps_CloneServicePlanProjectCtrTest (78%)

    private static final List<String> PROJECT_TASK_FIELDS = new List<String>{
        'Id' , 'pse__Project__c' , 'Name' , 'OwnerId' , 'pse__Status__c' ,
        'pse__Start_Date_Time__c' , 'pse__End_Date_Time__c' ,
        'NSP_Percentage_Complete__c' , 'NSP_isClonedFromAutomation__c' ,
        'NSP_Category__c' , 'NSP_Sub_Category__c' , 'NSP_Detail__c' ,
        'pse__Parent_Task__c' , 'pse__Parent_Task__r.Name'
    };

    @AuraEnabled
    public static List<pse__Project_Task__c> retrieveProjectTask( String recordId){
        try{
            return [
                SELECT Id, pse__Project__c,Name,pse__Start_Date_Time__c,pse__End_Date_Time__c, pse__Parent_Task__c, pse__Parent_Task__r.Name,pse__Status__c
                FROM pse__Project_Task__c WHERE pse__Status__c !=: NSP_ServiceConstants.PROJECT_TASK_CANCELLED AND pse__Status__c !=: NSP_ServiceConstants.PROJECTSTATUSCOMPLETED
                AND RecordType.DeveloperName = 'PEO_Project_Task' AND pse__Synchronize_Milestone_And_Task__c = false AND pse__Project__c = :recordId LIMIT 1000
            ];
        }catch(Exception Ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static List<String> saveProjectTask(String taskDataString){
        try{
            List<pse__Project_Task__c> taskList = (List<pse__Project_Task__c>)System.JSON.deserializeStrict(taskDataString, List<pse__Project_Task__c>.Class);
            Database.SaveResult[] result = Database.insert(taskList,false);
            List<String> saveResult = new List<String>();
            //iterating over the new String list
            for (Database.SaveResult sr : result) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        saveResult.add( 'error : '+err.getMessage());
                    }
                }else{
                    saveResult.add('success : '+sr.getId());
                }
            }
            return saveResult;
        }catch(Exception Ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //Retrieving project Milestone
    @AuraEnabled
    public static List<pse__Milestone__c> retrieveProjectMilestone( String recordId){
        try{
            return [
                SELECT Id,Name,pse__Status__c,pse__Project__c,pse__Target_Date__c,pse__Milestone_Amount__c,pse__Total_Number_of_Tasks__c
                FROM pse__Milestone__c WHERE pse__Status__c != : NSP_ServiceConstants.PROJECTSTATUSCANCELLED   AND pse__Project__c = :recordId
                LIMIT 1000
            ];
        }catch(Exception Ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //Saving Project Milestone
    @AuraEnabled
    public static List<String> saveProjectMilestone(String milestoneDataString){
        try{
            List<pse__Milestone__c> milestoneList = (List<pse__Milestone__c>)System.JSON.deserializeStrict(milestoneDataString, List<pse__Milestone__c>.Class);
            Database.SaveResult[] result = Database.insert(milestoneList,false);
            List<String> saveResult = new List<String>();
            //iterating over the new string list
            for (Database.SaveResult sr : result) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        saveResult.add( 'error : '+err.getMessage());
                    }
                }else{
                    saveResult.add('success : '+sr.getId());
                }
            }
            return saveResult;
        }catch(Exception Ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //Retrieving Record Types
    @AuraEnabled
    public static List<RecordType> retrieveRecordTypes(List<String> sobjectList ){
        try{
            return [SELECT Id, Name,DeveloperName,SobjectType FROM RecordType WHERE SobjectType IN : sobjectList] ;
        }catch(Exception Ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //
    // This method is used to get all the records related to a project
    // which are required to check before marking a project as complete.
    //
    @AuraEnabled
    public static Map<String, String> getProjectRelatedRecordsData(String projectId, String accountId){
        try {
            Map<String, String> relatedRecordsData = new Map<String, String>();
            Asset woAsset = getWoAssetByAccountId(accountId);
            // Add Segment Type
            String woAssetSegment = woAsset == null ? null : woAsset.NSP_Client_Segment_type__c;
            relatedRecordsData.put('segmentType', woAssetSegment);
            // Add Open Tasks count
            String openProjectTasksCount = String.valueOf(getOpenProjectTasksByProjectId(projectId).size());
            relatedRecordsData.put('openProjectTasksCount', openProjectTasksCount);
            // Add Project Accounts
            String projectAccounts = JSON.serialize(getProjectAccountOptions(projectId));
            relatedRecordsData.put('projectAccounts', projectAccounts);
            return relatedRecordsData;
        } catch (Exception excep) {
            throw NSP_Utilities.getAuraException(excep);
        }
    }

    //
    // Get all the Service Plan project template filtered by Segment Type.
    // This method returns a list of LookupOption objects that can be used with
    // radio button group, combobox group as well as multi-select lookup.
    //
    @AuraEnabled
    public static List<NSP_LookupOption> getProjectTemplatesBySegmentType(String segmentType){
        try {
            List<String> projectFields = new List<String>{ 'Name' };
            NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder('pse__Proj__c', projectFields)
                .addFilter('pse__Project_Type__c', 'Service Plan')
                .addFilter('pse__Is_Template__c', true);
            return getProjectTemplateOptions((List<pse__Proj__c>) Database.query(queryBuilder.build()));
        } catch (Exception excep) {
            throw NSP_Utilities.getAuraException(excep);
        }
    }

    //
    // This method is used to create/update/delete all the related records of project.
    // It returns a list of errors which we get during Database operations.
    //
    @AuraEnabled
    public static List<String> createProjectRelatedRecords( String config ) {
        try {
            Map<String,String> paramsMap = (Map<String,String>)JSON.deserialize(
                config ,
                Map<String,String>.class
            );
            // Extract all the required data from the parameter map
            String projId = paramsMap.get('projectId');
            String oldProjectId = paramsMap.get('oldProjectId');
            List<String> prevProjectTaskIds = getListValueByName('prevProjectTaskIds', paramsMap);
            List<String> projAccountIds = getListValueByName('projectAccountIds', paramsMap);
            // Populate list of project tasks that needs to be created
            addPreviousProjectTasks(prevProjectTaskIds, projId,oldProjectId);
            // Prepare a list of project account records that needs to be created
            List<Project_Account__c> projAccounts = getProjectAccounts(projAccountIds, projId);
            // Prepare a consolidated list of items which needs to be inserted
            List<SObject> itemsToInsert = new List<SObject>();
            List<SObject> itemsToUpdate = new List<SObject>();
            itemsToInsert.addAll(projAccounts);
            // Perform all the DML operations
            return performDbOperations(itemsToInsert, itemsToUpdate , new List<SObject>());
        } catch (Exception excep) {
            throw NSP_Utilities.getAuraException(excep);
        }
    }

    // This method creates a project from template and populates the incoming field values on the newly created project
    @AuraEnabled
    public static Id createProjectFromTemplate(Id templateId, String fields){
        NSP_FF_APIs implInstance = new NSP_FF_APIImpl();
        if(Test.isRunningTest()){
            implInstance = new Nsp_FFApiMock();
        }
        pse__Proj__c projField = (pse__Proj__c) JSON.deserialize(fields, pse__Proj__c.class);
        //creating a project request
        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest projectrequest = generateProjectCreationRequest(templateId, projField);
        List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse = implInstance.createProjectFromTemplate(new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest>{projectrequest});
        return implInstance.getProjectId(projResponse);
    }

    // Helper method for createProjectFromTemplate method that sets the fields on the newly created project
    private static pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest generateProjectCreationRequest( Id templateId , pse__Proj__c projField ) {
        //creating a project request
        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest projectrequest;
        projectrequest = new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest(
            projField.pse__Account__c ,
            templateId ,
            projField.pse__Start_Date__c
        );
        //Setting the fields on project
        projectrequest.ProjectName = projField.Name;
        projectrequest.ProjectOwnerId = Userinfo.getUserId();
        projectrequest.IsActive = projField.pse__Is_Active__c;
        pse.SObjectCloneMapper.Field mapperFieldRT = new pse.SObjectCloneMapper.Field( Schema.pse__Proj__c.RecordTypeId );
        pse.SObjectCloneMapper.Field mapperFieldEndDate = new pse.SObjectCloneMapper.Field( Schema.pse__Proj__c.pse__End_Date__c );
        mapperFieldEndDate.DefaultValue = projField.pse__End_Date__c;
        pse.SObjectCloneMapper.Field mapperFieldStatus = new pse.SObjectCloneMapper.Field( Schema.pse__Proj__c.pse__Project_Status__c );
        mapperFieldStatus.DefaultValue = projField.pse__Project_Status__c;
        pse.SObjectCloneMapper.Field mapperFieldBillable = new pse.SObjectCloneMapper.Field( Schema.pse__Proj__c.pse__Is_Billable__c );
        mapperFieldBillable.DefaultValue = false;
        Set<pse.SObjectCloneMapper.Field> setMapperFields = new Set<pse.SObjectCloneMapper.Field>{
            mapperFieldEndDate ,
            mapperFieldStatus ,
            mapperFieldRT ,
            mapperFieldBillable ,
            NSP_CreateProjFromFlow.getDefaultRegionMapperField()
        };
        pse.SObjectCloneMapper mapp = new pse.SObjectCloneMapper( pse__Proj__c.SObjectType , setMapperFields );
        projectrequest.Mappers = new List<pse.SObjectCloneMapper>{ mapp };
        return projectrequest;
    }

    //
    // This is a generic method to perform CUD DML operations.
    // NOTE : If you need to use this method at any other place in project
    // then make it public method & move it to `NSP_utilities` class.
    //
    private static List<String> performDbOperations(List<SObject> itemsToInsert, List<SObject> itemsToUpdate, List<SObject> itemsToDelete){
        List<String> errorList = new List<String>();
        if(!itemsToInsert.isEmpty()){
            errorList.addAll(NSP_Utilities.getDbErrorRecords(Database.insert(itemsToInsert, false)));
        }
        if(!itemsToUpdate.isEmpty()){
            errorList.addAll(NSP_Utilities.getDbErrorRecords(Database.update(itemsToUpdate, false)));
        }
        if(!itemsToDelete.isEmpty()){
            errorList.addAll(NSP_Utilities.getDbErrorRecords(Database.delete(itemsToDelete, false)));
        }
        return errorList;
    }

    //
    // This method converts a string parameter value to list of string.
    // It fetch value from parameter map on the basis of given param name
    // & then it converts that value to the list of string.
    //
    private static List<String> getListValueByName(String paramName, Map<String, String> paramsMap){
        return (List<String>) JSON.deserialize(paramsMap.get(paramName), List<String>.class);
    }

    private static List<SObject> updateStatusInProjectTasks(List<String> recordsIds){
        List<SObject> sObjects = new List<SObject>();
        for (String recordId : recordsIds) {
            pse__Project_Task__c projTask = new pse__Project_Task__c();
            projTask.Id = recordId;
            projTask.pse__Status__c = 'Closed - Moved';
            sObjects.add(projTask);
        }
        return sObjects;
    }

    private static List<pse__Project_Task__c> cancelUnslectedTaskStatus(List<pse__Project_Task__c> projectTaskRecs){
        List<pse__Project_Task__c> projTaskList = new List<pse__Project_Task__c>();
        for (pse__Project_Task__c projTask : projectTaskRecs) {
            projTask.pse__Status__c = 'Canceled';
            projTaskList.add(projTask);
        }
        return projTaskList;
    }

    //
    // This method retrieves project tasks by task ids and add it to the given project task list.
    //
    @future
    public static void addPreviousProjectTasks( List<String> prevProjectTaskIds , Id projId , Id oldProjectId ) {
        try {
            List<pse__Project_Task__c> prevProjTasks = (List<pse__Project_Task__c>) new NSP_sObjectSelector('pse__Project_Task__c', PROJECT_TASK_FIELDS)
                .selectById(prevProjectTaskIds);
            List<String> newProjectTaskIds = new List<String>();
            List<pse__Project_Task__c> parentProjectTasks = new List<pse__Project_Task__c>();
            List<pse__Project_Task__c> childProjectTasks = new List<pse__Project_Task__c>();
            Map<String,String> parentTaskNameIds = new Map<String,String>();
            for(pse__Project_Task__c task : prevProjTasks){
                pse__Project_Task__c newTask = task.clone(false, true, false, false);
                newTask.NSP_isClonedFromAutomation__c = true;
                newTask.pse__Project__c = projId;
                if(newTask.pse__Parent_Task__c != null){
                    childProjectTasks.add(newTask);
                }else{
                    parentProjectTasks.add(newTask);
                }
            }
            if ( !parentProjectTasks.isEmpty() ) {
                List<Database.SaveResult> results = Database.insert( parentProjectTasks , false );
                NSP_ErrorLogHandler.logResults(
                    Nps_CloneServicePlanProjectController.class.getName() ,
                    'addPreviousProjectTasks:parent' ,
                    results
                );
            }
            for(pse__Project_Task__c newTask:[SELECT Id,Name FROM pse__Project_Task__c WHERE pse__Project__c=:projId AND NSP_isClonedFromAutomation__c = true]){
                parentTaskNameIds.put(newTask.Name,newTask.Id);
            }
            //get parent task id and update child task
            for(pse__Project_Task__c childTask: childProjectTasks){
                childTask.pse__Parent_Task__c = parentTaskNameIds.get(childTask.pse__Parent_Task__r.Name);
            }
            if ( !childProjectTasks.isEmpty() ) {
                List<Database.SaveResult> results = Database.insert( childProjectTasks , false );
                NSP_ErrorLogHandler.logResults(
                    Nps_CloneServicePlanProjectController.class.getName() ,
                    'addPreviousProjectTasks:child' ,
                    results
                );
            }
            for ( pse__Project_Task__c newTask : [
                        SELECT Id , Name
                        FROM pse__Project_Task__c
                        WHERE (
                            ( pse__Project__c = :projId )
                            AND ( NSP_isClonedFromAutomation__c = true )
                        )
                    ]
                )
            {
                newProjectTaskIds.add(newTask.Id);
            }
            insertProjTaskRelatedRecords(
                prevProjectTaskIds ,
                newProjectTaskIds ,
                projId
            );
            List<pse__Project_Task__c> projTaskToCancel = getUnselectedProjectTasksByProjectId(
                oldProjectId ,
                prevProjectTaskIds
            );
            // Prepare a consolidated list of items which needs to be updated
            List<SObject> itemsToUpdate = new List<SObject>();
            itemsToUpdate.addAll( updateStatusInProjectTasks( prevProjectTaskIds ) );
            itemsToUpdate.addAll( cancelUnslectedTaskStatus( projTaskToCancel ) );
            // Perform all the DML operations
            performDbOperations(
                new List<SObject>() ,
                itemsToUpdate ,
                new List<SObject>()
            );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                Nps_CloneServicePlanProjectController.class.getName() ,
                'addPreviousProjectTasks' ,
                e
            );
        }
    }

    // This method creates a list of project accounts by populating project id and account id in it.
    private static List<Project_Account__c> getProjectAccounts(List<String> accountIds, String projId) {
        List<Project_Account__c> projAccounts = new List<Project_Account__c>();
        for (String accId : accountIds) {
            projAccounts.add(new Project_Account__c(Account__c = accId, Project__c = projId));
        }
        return projAccounts;
    }

    //
    // This method inserts the related records of Project Task to be cloned.
    //
    public static void insertProjTaskRelatedRecords( List<String> prevProjTaskIds , List<Id> newProjTaskIds , Id projId ) {
        List<pse__Project_Task__c> prevProjTasks = (List<pse__Project_Task__c>) new NSP_sObjectSelector('pse__Project_Task__c', PROJECT_TASK_FIELDS)
            .selectById(prevProjTaskIds);
        List<pse__Project_Task__c> newProjTasks = (List<pse__Project_Task__c>) new NSP_sObjectSelector('pse__Project_Task__c', PROJECT_TASK_FIELDS)
            .selectById(newProjTaskIds);
        Map<String, Id> newMapOfPTNameAndId = new Map<String, Id>();
        Map<Id, String> oldMapOfPTIdAndName = new Map<Id, String>();
        List<sObject> relatedRecords = new List<sObject>();
        for(pse__Project_Task__c oldPT: prevProjTasks){
            oldMapOfPTIdAndName.put(oldPT.Id, uniqueIdentifierForPTA(oldPT));
        }
        for(pse__Project_Task__c projTask: newProjTasks){
            newMapOfPTNameAndId.put(uniqueIdentifierForPTA(projTask), projTask.Id);
        }
        //clone the project task assignments and attach them to the newly cloned project task
        for(pse__Project_Task_Assignment__c projTaskAssignment: [SELECT Id, NSP_Is_Account_Team__c, AccountID__c, pse__Allocation_Hours__c, pse__Allocation_Percentage__c, pse__Assignment__c, NSP_Client_Number__c,
                                                                NSP_Customer__c, pse__End_Date__c, psa_report__Estimated_Hours__c, psa_report__Estimated_Hours_per_PTA__c, pse__External_Resource__c,
                                                                pse__Hours__c, psaws__Is_Resource_Current_User__c, NSP_Job_Title__c, NSP_Parent_Role__c, NSP_Priority__c,
                                                                NSP_Project__c, pse__Project__c, NSP_Project_Coordinator__c, pse__Project_ID__c, NSP_Project_Name__c, NSP_Project_Number__c,
                                                                NSP_Project_Record_Type__c, NSP_Project_Start_Date__c, NSP_Project_Task_Assignment_External_ID__c, pse__Project_Task_End_Date__c,
                                                                pse__Project_Task_Start_Date__c, psaws__Status__c, pse__Resource_Request__c, pse__Resource_Role__c,
                                                                Resource_Type__c, pse__Schedule_Type__c, pse__Start_Date__c, pse__Project_Task__c, pse__Project_Task__r.Name, pse__Project_Task__r.pse__Status__c, pse__Resource__c,
                                                                pse__Project_Task__r.pse__Start_Date_Time__c, pse__Project_Task__r.pse__End_Date_Time__c, pse__Project_Task__r.NSP_Percentage_Complete__c,
                                                                pse__Resource__r.Name, pse__Project_Task__r.pse__Parent_Task__r.Name
                                                                FROM pse__Project_Task_Assignment__c
                                                                WHERE pse__Project_Task__c =: prevProjTaskIds]){
            pse__Project_Task_Assignment__c newProjTaskAssignemt = projTaskAssignment.clone(false, true, false, false);
            String identifier = uniqueIdentifierForPTA(projTaskAssignment.pse__Project_Task__r);
            newProjTaskAssignemt.pse__Project_Task__c = newMapOfPTNameAndId.get(identifier);
            relatedRecords.add(newProjTaskAssignemt);
        }
        //clone the notes and attach them to the newly cloned project task
        for(NSP_Note__c note: [
                    SELECT
                        Id , NSP_NetSuite_External_ID__c , NSP_OneVoice_External_ID__c ,
                        NSP_Project_Task__c , NSP_Project_Task__r.Name , NSP_Project_Task__r.pse__Status__c ,
                        NSP_Project_Task__r.pse__Start_Date_Time__c , NSP_Project_Task__r.pse__End_Date_Time__c ,
                        NSP_Project_Task__r.NSP_Percentage_Complete__c , NSP_Project_Task__r.pse__Parent_Task__r.Name
                    FROM NSP_Note__c
                    WHERE NSP_Project_Task__c =: prevProjTaskIds
                ]
            )
        {
            NSP_Note__c newNote = note.clone(false, true, false, false);
            String identifier = uniqueIdentifierForPTA(note.NSP_Project_Task__r);
            newNote.NSP_Project_Task__c = newMapOfPTNameAndId.get(identifier);
            relatedRecords.add(newNote);
        }
        //clone the files and attach them to the newly cloned project task
        if(!oldMapOfPTIdAndName.isEmpty()){
            for(ContentDocumentLink doc: [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink
                                        WHERE LinkedEntityId =: oldMapOfPTIdAndName.keySet() AND LinkedEntity.Type ='pse__Project_Task__c']){
                ContentDocumentLink newDoc = doc.clone(false, true, false, false);
                String oldId = oldMapOfPTIdAndName.get(doc.LinkedEntityId);
                newDoc.LinkedEntityId = newMapOfPTNameAndId.get(oldId);
                relatedRecords.add(newDoc);
            }
            if(!relatedRecords.isEmpty()){
                Database.insert(relatedRecords);
            }
        }
    }

    private static String uniqueIdentifierForPTA(pse__Project_Task__c projTask){
        return projTask.Name + '`' + projTask.pse__Parent_Task__r.Name;
    }

    // This method return a list of Project Account options in map format.
    private static List<Map<String, String>> getProjectAccountOptions(String projectId) {
        List<Map<String, String>> projectAccounts = new List<Map<String, String>>();
        for (Project_Account__c projAccount : [SELECT Id, Account__c, Account__r.Name FROM Project_Account__c WHERE Project__c = :projectId LIMIT 1000]) {
            projectAccounts.add(new Map<String, String>{
                'Id' => projAccount.Id,
                'Account__c' => projAccount.Account__c,
                'Account__r.Name' => projAccount.Account__r.Name
            });
        }
        return projectAccounts;
    }

    // This method returns a list of Project template lookup options.
    private static List<NSP_LookupOption> getProjectTemplateOptions(List<pse__Proj__c> projectTemplates){
        List<NSP_LookupOption> options = new List<NSP_LookupOption>();
        for (pse__Proj__c projectTemplate : projectTemplates) {
            options.add(new NSP_LookupOption(projectTemplate.Name, projectTemplate.Id, null, null, null));
        }
        return options;
    }

    // This method returns a WO Asset linked with the given Account.
    private static Asset getWoAssetByAccountId(String accountId){
        List<String> assetFields = new List<String>{ 'NSP_Client_Segment_type__c' };
        String woAssetQuery = new NSP_QueryBuilder('Asset', assetFields)
            .addFilter('RecordType.Name', 'WO')
            .addFilter('AccountId', accountId).build();
        List<Asset> woAssets = Database.query(woAssetQuery);
        return woAssets.isEmpty() ? null : woAssets[0];
    }

    // This method returns a list of in-progress project tasks of the given project.
    private static List<pse__Project_Task__c> getOpenProjectTasksByProjectId(String projectId){
        List<String> projectTaskFields = new List<String>{ 'pse__Status__c' };
        String projectTaskQuery = new NSP_QueryBuilder('pse__Project_Task__c', projectTaskFields)
            .addFilter('pse__Status__c', 'In Progress')
            .addFilter('pse__Project__c', projectId).build();
        return Database.query(projectTaskQuery);
    }

    // This method returns a list of in-progress & Unselected project tasks of the given project.
    private static List<pse__Project_Task__c> getUnselectedProjectTasksByProjectId(String projectId, List<String> selectedProjectId){
        List<String> projectTaskFields = new List<String>{ 'Id','pse__Status__c' };
        List<String> projTasksNotToBeCancelled = new List<String>{'Complete', 'Canceled'};
        String projectTaskQuery = new NSP_QueryBuilder('pse__Project_Task__c', projectTaskFields)
            .addFilter('pse__Project__c', projectId)
            .addFilter('pse__Status__c', projTasksNotToBeCancelled, NSP_QueryBuilder.Operator.NOT_IN)
            .addFilter('Id', selectedProjectId,NSP_QueryBuilder.Operator.NOT_IN).build();
        return Database.query(projectTaskQuery);
    }

}
//
