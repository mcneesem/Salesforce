public class NSP_ProjectTasksTriggerHelper {
    // test w/ NSP_ProjectTasksTriggerHelperTest, NSP_Implprofile_ServiceHelperUpdate_Test (80%)
    // test w/ NSP_ProjectTasksTriggerHelperTest (79%)
    // test w/ NSP_Implprofile_ServiceHelperUpdate_Test (34%)

    private static final String HUNDRED_PERCENT =  '100%';
    private static final String COBRA_MM ='NSP_COBRA';
    private static final String COBRA_GUIDELINES_MM = 'NSP_COBRAGuidelines';
    private static final String COBRA_TEAM_MM = 'NSP_COBRATeam';
    private static final String COBRA_PACKETS_MM = 'NSP_COBRAPackets';
    private static final Id wOAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'WO' );
    private static final Id peoProjectTaskRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Project_Task__c' , 'PEO_Project_Task' );
    private static final String BACKOUT = 'Backout';
    private static final String TERMINATED = 'Terminated';
    private static final String RETURNED = 'Returned';
    private static final String INACTIVE = 'Inactive';
    private static final String SUBMIT_TERMINATION_CHECKLIST = 'Submit Termination Checklist';
    private static final String LEVIESTASK = 'Employee Levies Provided';
    private static final String LINE_BREAK = '<br/><br/>';
    private static final String HSA_OPTUM_NO_MM='NSP_HSA_No_Optum';
    private static final String HSA_OPTUM_MM='HSA_Optum';

    //
    // Iterates throught the list of new pse__Project_Task__c and passes the required attributes to other methods.
    // @param projectTaskNewMap Map of New project.
    // @param projecttaskOldMap Map of Old project.
    // @return void
    //
    public void updateProjectTaskFields( List<pse__Project_Task__c> projectTaskList ) {
        Map<Id,List<pse__Project_Task__c>> projectTaskMap = new Map<Id,List<pse__Project_Task__c>>();
        Map<Id,pse__Proj__c> parentProjectMap  = new Map<Id,pse__Proj__c>();
        Map<Id,Id> mapOfparentTaskIdAndMilestoneId = new Map<Id,Id>();
        Set<Id> setOfParentProjectTask = new Set<Id>();
        List<String> projectForCancallation = new List<String>();
        if ( ( NSP_ProjectTasksTriggerHelper.settings != null )
            && String.isNotBlank( NSP_ProjectTasksTriggerHelper.settings.CancellationProjects1__c )
            )
        {
            projectForCancallation = NSP_ProjectTasksTriggerHelper.settings.CancellationProjects1__c.split( ',' );
            if ( String.isNotBlank( NSP_ProjectTasksTriggerHelper.settings.CancellationProjects2__c ) ) {
                projectForCancallation.addAll( NSP_ProjectTasksTriggerHelper.settings.CancellationProjects2__c.split( ',' ) );
            }
        }
        for(pse__Project_Task__c projectTask : projectTaskList){
            if(projectTask.pse__Parent_Task__c != null){
                setOfParentProjectTask.add(projectTask.pse__Parent_Task__c);
            }

            // STY-03891
            if(projectTask.NSP_Create_Work_Order__c == true && String.isNotBlank(projectTask.NSP_Dispatch_Region__c)){
                projectTask.pse__Status__c = 'Unscheduled';
            }


            if(projectTask.pse__Project__c != null){
                if(!projectTaskMap.containsKey(projectTask.pse__Project__c)){
                    projectTaskMap.put(projectTask.pse__Project__c, new List<pse__Project_Task__c>());
                }
                projectTaskMap.get(projectTask.pse__Project__c).add(projectTask);
            }

            // UPDATE Started and Completed Details
            if(projectTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED){
                projectTask.pse__Actual_End_Date_Time__c = Datetime.now();
                projectTask.pse__Completed__c = true;
            }else{
                projectTask.pse__Completed__c = false;
            }
            if(String.isBlank(projectTask.pse__Status__c) || projectTask.pse__Status__c == NSP_ServiceConstants.PROJECT_TASK_CANCELLED || projectTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSNOTSTARTED ){
                projectTask.pse__Started__c = false;
            }else{
                projectTask.pse__Actual_Start_Date_Time__c = Datetime.now();
                projectTask.pse__Started__c = true;
            }
            if ( ( projectTask.RecordTypeId == NSP_ProjectTasksTriggerHelper.peoProjectTaskRecordTypeId )
                && ( projectForCancallation != null )
                && !projectForCancallation.isEmpty()
                && String.isNotBlank( projectTask.Name )
                && ( projectForCancallation.contains( projectTask.Name ) )
                && CustomPermissionController.checkUserPermission( 'Finance_Service_User' , UserInfo.getUserId() )
               )
            {
                projectTask.pse__Status__c = 'Canceled';
            }
        }
        if(!setOfParentProjectTask.isEmpty()){
            for(pse__Project_Task__c parentTask : [SELECT pse__Milestone__c FROM pse__Project_Task__c WHERE ID IN : setOfParentProjectTask]){
                mapOfparentTaskIdAndMilestoneId.put(parentTask.id, parentTask.pse__Milestone__c);
            }

            for(pse__Project_Task__c pTask : projectTaskList){
                if(pTask.pse__Parent_Task__c != null){
                    pTask.pse__Milestone__c = mapOfparentTaskIdAndMilestoneId.get(pTask.pse__Parent_Task__c);
                }
            }
        }

        if(projectTaskMap.size() > 0){
            parentProjectMap  = new  Map<Id, pse__Proj__c>( [Select Id, pse__Is_Template__c
                                                                FROM pse__Proj__c
                                                                WHERE pse__Is_Template__c = True AND
                                                                ID In: projectTaskMap.keySet()]);
        }

        if(!parentProjectMap.isEmpty()){
            for(pse__Proj__c eachProj : parentProjectMap.values() ){
                if( projectTaskMap.get(eachProj.Id) != null){
                    for(pse__Project_Task__c projectTask : projectTaskMap.get(eachProj.Id)){
                            projectTask.NSP_Template_Generated__c = True;
                    }
                }
            }
        }
    }

    /**
    * Description: Filter record for other functions
    * @return void
    */
    public void afterInsertFilter(List<pse__Project_Task__c> listProjectTasks, Map<Id, pse__Project_Task__c> mapProjectTasks){
        List<pse__Project_Task__c> cobraProjectTaskList = new List<pse__Project_Task__c>();
        NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(COBRA_MM);
        List<ID> accountIdList = new List<ID>();
        List<string> peoTerminationTaskList = System.Label.PEO_Termination_Tasks.split(';');
        List<pse__Project_Task__c> garnishments = new List<pse__Project_Task__c>();
        List<pse__Project_Task__c> levies = new List<pse__Project_Task__c>();
        String TERMINATIONANALYSIS = null;
        if ( peoTerminationTaskList != null
            && !peoTerminationTaskList.isEmpty()
            && ( peoTerminationTaskList.size() >= 2 )
            )
        {
            TERMINATIONANALYSIS = peoTerminationTaskList[1];
        }
        if(listProjectTasks != null){
            for(pse__Project_Task__c pTask : listProjectTasks){
                //Checking for COBRA Parent Task
                if(pTask.Name==pta.NSP_Task_Name__c){
                    cobraProjectTaskList.add(pTask);
                }
                if(pTask.Name == NSP_ServiceConstants.GARNISHMENT){
                    garnishments.add(pTask);
                }
                if(pTask.Name == LEVIESTASK){
                    levies.add(pTask);
                }
                //Create HSA Optum Bank Project Tasks
                createHSASubtask(pTask);
                //Checking for Project Task Account
                if ( pTask.NSP_Account_Id__c != null
                    && pTask.Name == TERMINATIONANALYSIS
                    )
                {
                    accountIdList.add(pTask.NSP_Account_Id__c);
                }
            }
        }
        if(cobraProjectTaskList.size() > 0){
            createCobraSubTasks(cobraProjectTaskList);
        }
        if (accountIdList.size() > 0){
            updateDocusignAsset(accountIdList);
        }
        if (garnishments.size() > 0){
            createSubtask(garnishments, NSP_ServiceConstants.GARNISHMENT);
        }
        if (levies.size() > 0){
            createSubtask(levies, LEVIESTASK);
        }
    }

    private void createHSASubtask( pse__Project_Task__c pTask ) {
        List<pse__Project_Task__c> hsaOptumMM = new List<pse__Project_Task__c>();
        List<pse__Project_Task__c> hsaOptumNoMM = new List<pse__Project_Task__c>();
        String hsaOptum = NSP_MMImplProfile_ServHelpUpdate.hsaOptumChildren();
        if( pTask != null && String.isNotBlank(hsaOptum) ) {
            if(pTask.Name == NSP_ServiceConstants.HSA && hsaOptum == HSA_OPTUM_MM){
                hsaOptumMM.add(pTask);
            }
            if(pTask.Name == NSP_ServiceConstants.HSA && hsaOptum == HSA_OPTUM_NO_MM){
                hsaOptumNoMM.add(pTask);
            }
            if( hsaOptumMM != null && !hsaOptumMM.isEmpty() ){
                createProjectTaskForHSAChildren(hsaOptumMM, HSA_OPTUM_MM);
            }
            if(hsaOptumNoMM != null && !hsaOptumNoMM.isEmpty()){
                createProjectTaskForHSAChildren(hsaOptumNoMM, HSA_OPTUM_NO_MM);
            }
        }
    }

    //
    // MethodName:  createSubtask
    // Description : Create sub tasks for garnishments and levies
    // Params: List<pse__Project_Task__c> projectTasks, String taskType
    //
    private void createSubtask( List<pse__Project_Task__c> records , String taskType ) {
        try {
            List<pse__Project_Task__c> newProjectTasks = new List<pse__Project_Task__c>();
            Map<Id,pse__Project_Task__c> ipToParentTaskMap = new Map<Id,pse__Project_Task__c>();
            Map<Id,Map<String, String>> taskEmployeedata = new Map<Id,Map<String, String>>();
            Map<String,String> documentMap = new Map<String,String>();
            Map<Id,pse__Project_Task__c> idProjecttask = new Map<Id,pse__Project_Task__c>();
            Map<Id,Implementation_Profile__c> implMap = new Map<Id,Implementation_Profile__c>();
            for ( pse__Project_Task__c record : records ) {
                if ( record.Implementation_Profile__c != null ) {
                    ipToParentTaskMap.put( record.Implementation_Profile__c , record );
                }
                if ( record.Id != null ) {
                    idProjecttask.put( record.Id , record );
                }
            }
            if ( !ipToParentTaskMap.isEmpty() ) {
                List<Implementation_Profile__c> employeeDataList = [
                    SELECT
                        Id ,
                        Account__r.Name ,
                        NSP_Project_Manager__r.pse__Salesforce_User__c ,
                        Account__r.Id ,
                        NSP_Documents_garnishments__c ,
                        Document_Levies__c
                    FROM Implementation_Profile__c
                    WHERE ( Id IN :ipToParentTaskMap.keyset() )
                ];
                if ( !employeeDataList.isEmpty() ) {
                    for ( Implementation_Profile__c impl : employeeDataList ) {
                        if ( impl != null ) {
                            implMap.put( impl.id , impl );
                            List<String> documentList = new List<String>();
                            if ( ( taskType == NSP_ServiceConstants.GARNISHMENT )
                                && String.isNotBlank( impl.NSP_Documents_garnishments__c )
                                )
                            {
                                documentList = impl.NSP_Documents_garnishments__c.split( ',' );
                            } else if ( ( taskType == NSP_ProjectTasksTriggerHelper.LEVIESTASK )
                                && String.isNotBlank( impl.Document_Levies__c )
                                )
                            {
                                documentList = impl.Document_Levies__c.split( ',' );
                            }
                            if(!documentList.isEmpty()){
                                for (String documents : documentList) {
                                    if(String.isNotBlank(documents)){
                                        List<String> documentSplit = documents.split('~');
                                        if (documentSplit.size() == 2) {
                                            String documentKey = documentSplit[0].trim();
                                            String documentValue = documentSplit[1].trim();
                                            documentMap.put(documentKey, documentValue);
                                        }
                                    }
                                }
                            }

                            if ( ipToParentTaskMap.containsKey(impl.id)
                                && ipToParentTaskMap.get(impl.id) != null
                                && ipToParentTaskMap.get(impl.id).id != null
                                )
                            {
                                Id parentId = ipToParentTaskMap.get(impl.id).id;
                                if (taskEmployeedata.containsKey(parentId)) {
                                    Map<String, String> existingMap = taskEmployeedata.get(parentId);
                                    existingMap.putAll(documentMap);
                                } else {
                                    taskEmployeedata.put(parentId, documentMap);
                                }
                            }
                        }
                    }
                }
            }

            if(taskEmployeedata.keyset().size() > 0){
                for(ID projTask : taskEmployeedata.keyset()){
                    for(String employee : taskEmployeedata.get(projTask).keyset()){
                        if(String.isNotBlank(employee)
                            && taskEmployeedata.containsKey(projTask)
                            && taskEmployeedata.get(projTask).containsKey(employee)
                            && taskEmployeedata.get(projTask).get(employee) == NSP_ServiceConstants.NOTCOLLECTED
                            )
                        {
                            if(idProjecttask.containsKey(projTask)){
                                pse__Project_Task__c parentTask = idProjecttask.get(projTask);
                                if ( parentTask != null
                                    && parentTask.Implementation_Profile__c != null
                                    && implMap.containsKey(parentTask.Implementation_Profile__c)
                                    )
                                {
                                    pse__Project_Task__c eachProjecttask = new pse__Project_Task__c();
                                    Implementation_Profile__c eachImplProfile = implMap.get(parentTask.Implementation_Profile__c);
                                    if(eachImplProfile != null){
                                        if ( eachImplProfile.NSP_Project_Manager__c != null
                                            && eachImplProfile.NSP_Project_Manager__r.pse__Salesforce_User__c != null
                                            )
                                        {
                                            eachProjecttask.OwnerId = eachImplProfile.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                        }
                                        if(eachImplProfile.Account__c != null && eachImplProfile.Account__r.Name != null){
                                            eachProjecttask.NSP_Implementation_Profile_Account__c = eachImplProfile.Account__r.Name;
                                        }
                                        if(eachImplProfile.Account__c != null){
                                            eachProjecttask.NSP_Implementation_Account_Id__c = eachImplProfile.Account__c;
                                        }
                                    }
                                    eachProjecttask.NSP_Category__c = parentTask.NSP_Category__c;
                                    eachProjecttask.NSP_Sub_Category__c = parentTask.NSP_Sub_Category__c;
                                    eachProjecttask.pse__Start_Date_Time__c = parentTask.pse__Start_Date_Time__c;
                                    eachProjecttask.pse__End_Date_Time__c = parentTask.pse__End_Date_Time__c;
                                    eachProjecttask.Name = employee + (taskType == NSP_ServiceConstants.GARNISHMENT ? NSP_ServiceConstants.GARNISHDOC : NSP_ServiceConstants.LEVYDOC);
                                    eachProjecttask.pse__Parent_Task__c = parentTask.Id;
                                    eachProjecttask.pse__Hierarchy_Depth__c = 1;
                                    eachProjecttask.pse__Milestone__c = parentTask.pse__Milestone__c;
                                    eachProjecttask.pse__Order__c =parentTask.pse__Order__c;
                                    eachProjecttask.Task_Order__c =parentTask.Task_Order__c;
                                    newProjectTasks.add(eachProjecttask);
                                }
                            }
                        }
                    }
                }
            }
            if (newProjectTasks.size() > 0){
                insert newProjectTasks;
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTasksTriggerHelper.class.getName() ,
                'createsubtask' ,
                e
            );
        }
    }

    /**
    * @MethodName: updateDocusignAsset
    * @Description: Populate related Active asset for docusign use
    * @param :List<Id> accountList
    * @return void
    */
    public static void updateDocusignAsset(List<ID> accountList) {
        List<String> excludeStatusValues = new List<String>();
        List<String> excluderecordTypeWithStatusValues = new List<String>();
        List<String> excluderecordTypeValues = new List<String>();
        AssetTriggerSettings__c settings = AssetTriggerSettings__c.getInstance( UserInfo.getUserId() );
        if ( settings != null ) {
            if ( String.isNotBlank( settings.Exclude_Status__c ) ) {
                excludeStatusValues = settings.Exclude_Status__c.split( '\\R' );
            }
            if ( String.isNotBlank( settings.Exclude_Record_Types_WRT_Status__c ) ) {
                excluderecordTypeWithStatusValues = settings.Exclude_Record_Types_WRT_Status__c.split( '\\R' );
            }
            if ( String.isNotBlank( settings.Exclude_Record_Types__c ) ) {
                excluderecordTypeValues = settings.Exclude_Record_Types__c.split( '\\R' );
            }
        }
        try {
            List<Asset> assetList = [
                SELECT Id , RecordTypeId , RecordType.Name , AccountId , Status
                FROM Asset
                WHERE (
                    ( AccountId IN :accountList )
                    AND (
                        NOT (
                            (
                                ( RecordType.Name = :excluderecordTypeWithStatusValues )
                                AND ( Status = :excludeStatusValues )
                            )
                            OR ( RecordType.Name = :excluderecordTypeValues )
                        )
                    )
                )
            ];
            Map<Id,Set<String>> accountToAssetRecordtypeMap = new Map<Id,Set<String>>();
            Map<Id,RecordTypeInfo> recTypeMap = Asset.sObjectType.getDescribe().getRecordTypeInfosById();
            for (Asset eachAsset : assetList) {
                if (eachAsset.AccountId != null) {
                    if (!accountToAssetRecordtypeMap.containsKey(eachAsset.AccountId)) {
                        accountToAssetRecordtypeMap.put(eachAsset.AccountId, new Set<String>());
                    }
                    String recordTypeName;
                    if (recTypeMap.containsKey(eachAsset.RecordTypeId)) {
                        recordTypeName = recTypeMap.get(eachAsset.RecordTypeId).getName();
                    }
                    // Adding recordtypes from all related assets
                    accountToAssetRecordtypeMap.get(eachAsset.AccountId).addAll(recordTypeName.split(','));
                }
            }
            List<Account> acctList = new List<Account>();
            List<String> activeAssetList = new List<String>();
            for (Account eachAccount : [SELECT Id, Docusign_Assets__c FROM Account WHERE ID IN :accountList]) {
                //Clearing old value for Docusign_Assets__c
                eachAccount.Docusign_Assets__c = Null;
                if (accountToAssetRecordtypeMap.containsKey(eachAccount.Id)) {
                    //Adding value into Set for deduplication
                    Set<String> existingassetsrecordtype = accountToAssetRecordtypeMap.get(eachAccount.Id);
                    //Adding value from set to List
                    activeAssetList.addAll(existingassetsrecordtype);
                    //Updating the Docusign_Assets__c
                    if (activeAssetList.size() > 0){
                        eachAccount.Docusign_Assets__c = String.join(activeAssetList, ', ');
                    }
                }
                acctList.add(eachAccount);
            }
            if (acctList.size() > 0){
                update acctList;
            }
        } catch ( exception e ) {
            NSP_ProjectTasksTriggerHelper.handleException(
                e ,
                'updateDocusignAsset'
            );
        }
    }

    /***********************************************************************************************
    * MethodName:  createCobraSubTasks
    * Description : Create sub tasks for cobra
    * Params: List<pse__Project_Task__c> cobraProjectTaskList
    * ********************************************************************************************/
    public void createCobraSubTasks(List<pse__Project_Task__c> cobraProjectTaskList){
        NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(COBRA_MM);
        NSP_ProjectTask_Automation__mdt pta1 =  NSP_ProjectTask_Automation__mdt.getInstance(COBRA_GUIDELINES_MM);
        NSP_ProjectTask_Automation__mdt pta2 =  NSP_ProjectTask_Automation__mdt.getInstance(COBRA_TEAM_MM);
        NSP_ProjectTask_Automation__mdt pta3 =  NSP_ProjectTask_Automation__mdt.getInstance(COBRA_PACKETS_MM);
        List<pse__Project_Task__c> cobraChildProjectTaskList = new List<pse__Project_Task__c>();
        try{
        for(pse__Project_Task__c pt: cobraProjectTaskList){
            if(pt.Name==pta.NSP_Task_Name__c){
                pse__Project_Task__c eachProjecttask = createProjectTaskfromParent(pt);
                eachProjecttask.NSP_Sub_Category__c=pta1.NSP_Sub_Category__c;
                eachProjecttask.Name=pta1.NSP_Task_Name__c;
                eachProjecttask.pse__Hierarchy_Depth__c =1;
                eachProjecttask.pse__Order__c=1;
                eachProjecttask.Task_Order__c=90;
                if(String.isNotBlank(System.label.COBRA_Guidelines)){
                    eachProjecttask.pse__Long_Description__c = System.label.COBRA_Guidelines;
                }
                //
                cobraChildProjectTaskList.add(eachProjecttask);
                pse__Project_Task__c eachProjecttask1 = createProjectTaskfromParent(pt);
                eachProjecttask1.NSP_Sub_Category__c=pta2.NSP_Sub_Category__c;
                eachProjecttask1.Name=pta2.NSP_Task_Name__c;
                eachProjecttask1.pse__Hierarchy_Depth__c =2;
                eachProjecttask1.pse__Order__c=2;
                eachProjecttask1.Task_Order__c=91;
                if(String.isNotBlank(System.label.COBRA_Team)){
                    eachProjecttask1.pse__Long_Description__c = System.label.COBRA_Team;
                }
                cobraChildProjectTaskList.add(eachProjecttask1);
                //
                pse__Project_Task__c eachProjecttask2 = createProjectTaskfromParent(pt);
                eachProjecttask2.NSP_Sub_Category__c=pta3.NSP_Sub_Category__c;
                eachProjecttask2.Name=pta3.NSP_Task_Name__c;
                eachProjecttask2.pse__Hierarchy_Depth__c =3;
                eachProjecttask2.pse__Order__c=3;
                eachProjecttask2.Task_Order__c=92;
                if(String.isNotBlank(System.label.COBRA_Packet)){
                    eachProjecttask2.pse__Long_Description__c = System.label.COBRA_Packet;
                }
                cobraChildProjectTaskList.add(eachProjecttask2);
            }
        }
            if ( !cobraChildProjectTaskList.isEmpty() ) {
                List<Database.SaveResult> insertChildResults = Database.insert( cobraChildProjectTaskList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ProjectTasksTriggerHelper.class.getName() ,
                    'createCobraSubTasks' ,
                    insertChildResults
                );
            }
        } catch ( Exception e ) {
            NSP_ProjectTasksTriggerHelper.handleException(
                e ,
                'createCobraSubTasks'
            );
        }
    }

    public void createProjectTaskForHSAChildren( List<pse__Project_Task__c> projectTaskList , String automation ) {
        Id ipId = null;
        Integer hierarchyDepth = null;
        String longDescription = null;
        NSP_ProjectTask_Automation__mdt pta = null;
        if ( String.isNotBlank( automation ) ) {
            pta =  NSP_ProjectTask_Automation__mdt.getInstance( automation );
            if ( automation == HSA_OPTUM_MM ) {
                hierarchyDepth = 1;
                longDescription = System.label.HSA_With_Optum_Bank;
            }
            if ( automation == HSA_OPTUM_NO_MM ) {
                hierarchyDepth = 2;
                longDescription = System.label.HSA_With_No_Optum_Bank;
            }
        }
        List<pse__Project_Task__c> hsaProjectTaskList = new List<pse__Project_Task__c>();
        try {
            for ( pse__Project_Task__c pt : projectTaskList ) {
                if ( pt.Name==NSP_ServiceConstants.HSA && ( pta != null ) ) {
                    pse__Project_Task__c eachProjecttask = createProjectTaskfromParent( pt );
                    ipId = pt.Implementation_Profile__c;
                    eachProjecttask.NSP_Sub_Category__c = pta.NSP_Sub_Category__c;
                    eachProjecttask.Name = pta.NSP_Task_Name__c;
                    eachProjecttask.pse__Hierarchy_Depth__c = hierarchyDepth;
                    eachProjecttask.pse__Order__c= pta.Order__c;
                    eachProjecttask.Task_Order__c= pta.Task_Order__c;
                    eachProjecttask.NSP_Visible_to_Client__c = pta.Visible_to_Client__c;
                    eachProjecttask.pse__Long_Description__c = longDescription;
                    hsaProjectTaskList.add( eachProjecttask );
                }
                if ( ( hsaProjectTaskList != null ) && !hsaProjectTaskList.isEmpty() ) {
                    List<Database.SaveResult> insertChildResults = Database.insert( hsaProjectTaskList , false );
                    NSP_ErrorLogHandler.logResults(
                        NSP_ProjectTasksTriggerHelper.class.getName() ,
                        'createProjectTaskForHSAChildren' ,
                        insertChildResults
                    );
                }
            }
            //Insert Implementation Automation Record
            insertHsaIpAutomations( ipId , automation );
        } catch ( Exception e ) {
            NSP_ProjectTasksTriggerHelper.handleException(
                e ,
                'createProjectTaskForHSAChildren'
            );
        }
    }

    private void insertHsaIpAutomations( Id ipId , String automation ) {
        List<NSP_Implementation_Profile_Automation__c> ipAutomationList = new List<NSP_Implementation_Profile_Automation__c>();
        List<Implementation_Profile__c> ipRec = new List<Implementation_Profile__c>();
        Implementation_Profile__c implementationProfile = null;
        NSP_Implementation_Automations__mdt ipa = null;
        if ( automation != null ) {
            ipa = NSP_Implementation_Automations__mdt.getInstance( automation );
        }
        if ( ( ipId != null ) && ( ipa != null ) ) {
            ipRec = [
                SELECT Id , RecordTypeId
                FROM Implementation_Profile__c
                WHERE ( Id = :ipId )
                LIMIT 1
            ];
            if ( ipRec != null ) {
                implementationProfile = ipRec[0];
            }
            //Creating Implementation Profile record
            NSP_Implementation_Profile_Automation__c ipAutomation = NSP_MMImplProfile_ServHelpUpdate.createIPAutomation(
                implementationProfile,ipa.NSP_Automation_Name__c ,
                ipa.NSP_Method_Name__c ,
                ipa.NSP_Section__c
            );
            ipAutomationList.add( ipAutomation );
            if ( ( ipAutomationList != null ) && !ipAutomationList.isEmpty() ) {
                List<Database.SaveResult> ipAutomationResults = Database.insert( ipAutomationList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ProjectTasksTriggerHelper.class.getName() ,
                    'insertHsaIpAutomations' ,
                    ipAutomationResults
                );
            }
        }
    }

    private pse__Project_Task__c createProjectTaskfromParent( pse__Project_Task__c parentProjectTask ) {
        pse__Project_Task__c eachProjectTask = new pse__Project_Task__c();
        eachProjectTask.RecordTypeId = NSP_ProjectTasksTriggerHelper.peoProjectTaskRecordTypeId;
        eachProjectTask.NSP_Category__c= parentProjectTask.NSP_Category__c;
        eachProjectTask.NSP_Visible_to_Client__c = TRUE;
        eachProjectTask.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_NOT_STARTED;
        eachProjectTask.pse__Start_Date_Time__c = System.now();
        eachProjectTask.pse__WBS_Element_Number__c = parentProjectTask.pse__WBS_Element_Number__c;
        eachProjecttask.pse__Project__c = parentProjectTask.pse__Project__c;
        eachProjecttask.pse__End_Date_Time__c = parentProjectTask.pse__End_Date_Time__c;
        eachProjectTask.NSP_Implementation_Profile_Account__c = parentProjectTask.NSP_Implementation_Profile_Account__c;
        eachProjectTask.NSP_Implementation_Account_Id__c = parentProjectTask.NSP_Implementation_Account_Id__c;
        eachProjectTask.OwnerId = parentProjectTask.OwnerId;
        eachProjectTask.pse__Parent_Task__c = parentProjectTask.Id;
        eachProjectTask.pse__Milestone__c = parentProjectTask.pse__Milestone__c;
        return eachProjectTask;
    }

    /**
    * Update Project Task Completed and Started checkbox based on its Status.
    * @param lProjectTasks Map of New project Tasks.
    * @param mOldProjecTasks Map of Old project Tasks.
    * @return void
    *
    */
    public void updateStartedorCompleted(List<pse__Project_Task__c> lProjectTasks,Map<Id, pse__Project_Task__c> mOldProjecTasks){
        Map<Id,pse__Project_Task__c> mCompletedTasks = new Map<Id,pse__Project_Task__c>();
        for(pse__Project_Task__c oProjectTask: lProjectTasks){
            String oldStatus = mOldProjecTasks.get(oProjectTask.Id).pse__Status__c;
            oProjectTask.pse__Actual_End_Date_Time__c = oldStatus != oProjectTask.pse__Status__c && oldStatus == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED ? null : oProjectTask.pse__Actual_End_Date_Time__c;
            if(oProjectTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED && oProjectTask.pse__Status__c != oldStatus){
                oProjectTask.pse__Actual_End_Date_Time__c = Datetime.now();
                oProjectTask.pse__Completed__c = true;
                mCompletedTasks.put(oProjectTask.Id,oProjectTask);
            }else if(oProjectTask.pse__Status__c != NSP_ServiceConstants.PROJECTSTATUSCOMPLETED){
                oProjectTask.pse__Completed__c = false;
            }
            if(String.isBlank(oProjectTask.pse__Status__c) || oProjectTask.pse__Status__c == NSP_ServiceConstants.PROJECT_TASK_CANCELLED || oProjectTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSNOTSTARTED ){
                oProjectTask.pse__Started__c = false;
            }else if( oProjectTask.pse__Status__c != oldStatus && ( String.isBlank(oldStatus) || oldStatus == NSP_ServiceConstants.PROJECT_TASK_CANCELLED || oldStatus == NSP_ServiceConstants.PROJECTSTATUSNOTSTARTED )){
                oProjectTask.pse__Actual_Start_Date_Time__c = Datetime.now();
                oProjectTask.pse__Started__c = true;
            }
        }

        if(mCompletedTasks.keySet().size() > 0){
            checkRelatedTerminationsFormStatus(mCompletedTasks);
        }
    }

    /**
    * Check if all Related Terminations forms are Approved , otherwise throw Error
    * @param lProjectTasks List of New project Task.
    * @return void
    */
    public void checkRelatedTerminationsFormStatus(Map<Id,pse__Project_Task__c> mCompletedTasks){
        List<String> lTerminationFormStatus = new List<String>{NSP_ServiceConstants.PR_SUPERVISOR_APPROVED, NSP_ServiceConstants.TERM_SUPERVISOR_APPROVED};

        List<NSP_Termination_Form__c> lTerminationForms = new List<NSP_Termination_Form__c>([SELECT Id,NSP_Project_Task__c FROM NSP_Termination_Form__c WHERE NSP_Project_Task__c in: mCompletedTasks.keySet() AND NSP_Status__c NOT IN:lTerminationFormStatus]);
        Set<Id> sTasksWithIncompleteForms = new Set<Id>();
        for(NSP_Termination_Form__c oTerminationForm :lTerminationForms){
            sTasksWithIncompleteForms.add(oTerminationForm.NSP_Project_Task__c);
        }

        for(pse__Project_Task__c oProjectTask : mCompletedTasks.values()){
            if(sTasksWithIncompleteForms.contains(oProjectTask.Id)){
                oProjectTask.addError(System.Label.NSP_Project_Task_Completion_Error);
            }
        }
    }
    public void showErrorIfPercentageCompleteChangeToNot100(List<pse__Project_Task__c> lProjectTasks, map<Id, pse__Project_Task__c> oldMap){

        for(pse__Project_Task__c oProjecTask : lProjectTasks){
            if(oProjecTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED
                && oProjecTask.NSP_Percentage_Complete__c != HUNDRED_PERCENT
                && oldMap.get(oProjecTask.id).NSP_Percentage_Complete__c == HUNDRED_PERCENT){
                        oProjecTask.addError(System.Label.ShowErrorMessageWhenStausCompleteButPercentageNot100);
            }

            if(oProjecTask.NSP_Percentage_Complete__c == HUNDRED_PERCENT
            && oProjecTask.NSP_Percentage_Complete__c != oldMap.get(oProjecTask.id).NSP_Percentage_Complete__c
            && oProjecTask.pse__Status__c != NSP_ServiceConstants.PROJECTSTATUSCOMPLETED){
                oProjecTask.addError(System.Label.ShowErrorMessageWhenPercentage100ButStatusNotComplete);
            }

            /* commented as a part of <DF-02510>
            if(oProjecTask.NSP_Percentage_Complete__c == '0%'
                && oldMap.get(oProjecTask.id).NSP_Percentage_Complete__c != '0%'){
                    oProjecTask.addError(System.Label.ShowErrorMessageWhenPercentageMoveBackToZero);
            } */
                // Added Or condition as part of DF-2180
            if(oProjecTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED ||
            oProjecTask.pse__Status__c == NSP_ServiceConstants.PROJECT_TASK_CANCELLED){
                oProjecTask.NSP_Percentage_Complete__c = HUNDRED_PERCENT;
            }
        }
    }

    public void sendEmailToAccountTeamMembersIfTaskIsLetterReceived( List<pse__Project_Task__c> lProjectTasks , Map<Id,pse__Project_Task__c> oldMap ) {
        List<String> listOfToAddresses = new List<String>();
        Map<Id,Id> mapOfProjectTaskAndProject = new Map<Id,Id>();
        Map<Id,Id> mapOfProjectAndAccount = new Map<Id,Id>();
        List<Id> listOfAccountId = new List<Id>();
        Map<Id,Asset> woActiveList = new Map<Id,Asset>();
        Map<Id,List<String>> mapOfAccountAndListOfAccountTeamMemberEmailAddress = new Map<Id,List<String>>();
        Map<Id,pse__Project_Task__c> projectTaskLetterMap = new Map<Id,pse__Project_Task__c>();
        Map<Id,List<NSP_Account_Team__c>> mapOfAccountPayrollMem = new Map<Id,List<NSP_Account_Team__c>>();
        List<String> peoTerminationTeamRoles = System.Label.PEO_Termination_Team_Roles.split(';');
        List<String> peoTerminationTaskList = System.Label.PEO_Termination_Tasks.split(';');
        String writtenTermination = null;
        Map<Id,List<NSP_Account_Team__c>>mapOfAccountAndListOfAccountTeamMember = new Map<Id,List<NSP_Account_Team__c>>();

        try{
            if ( peoTerminationTaskList != null
                && !peoTerminationTaskList.isEmpty()
                )
            {
                writtenTermination = peoTerminationTaskList[0];
            }
            if (lProjectTasks != null) {
                for (pse__Project_Task__c projectTask : lProjectTasks) {
                    if ( projectTask != null
                        && projectTask.pse__Status__c == 'Complete'
                        && oldMap != null
                        && oldMap.containsKey(projectTask.Id)
                        && projectTask.pse__Status__c != oldMap.get(projectTask.Id).pse__Status__c
                        && ( projectTask.Name == writtenTermination )
                        )
                    {
                        if ( !mapOfProjectTaskAndProject.containsKey( projectTask.Id ) ) {
                            mapOfProjectTaskAndProject.put(
                                projectTask.Id ,
                                projectTask.pse__Project__c
                            );
                        }
                        if ( projectTask.NSP_AccountId__c != null ) {
                            listOfAccountId.add( projectTask.NSP_AccountId__c );
                        }
                    }
                }
            }
            if ( !mapOfProjectTaskAndProject.isEmpty() ) {
                for ( pse__Project_Task__c projectTask : [
                            SELECT
                                Id ,
                                pse__Project__c ,
                                Name ,
                                pse__Project__r.pse__Account__r.Name ,
                                pse__Project__r.pse__Account__r.NSP_AIMS_Client__c ,
                                NSP_AccountId__c ,
                                OwnerId
                            FROM pse__Project_Task__c
                            WHERE ( Id IN :mapOfProjectTaskAndProject.keySet() )
                        ]
                    )
                {
                    if (projectTask != null) {
                        if (!mapOfProjectAndAccount.containsKey(projectTask.Id)) {
                            mapOfProjectAndAccount.put(projectTask.Id, projectTask.NSP_AccountId__c);
                        }
                        if (!projectTaskLetterMap.containsKey(projectTask.Id)) {
                            projectTaskLetterMap.put(projectTask.Id, projectTask);
                        }
                    }
                }
            }
            if (!listOfAccountId.isEmpty()) {
                for (Asset eachAsset : [
                            SELECT Id , AccountId , NSP_Reason_for_Term__c , NSP_Anticipated_Date_Of_Termination__c
                            FROM Asset
                            WHERE (
                                RecordTypeId = :NSP_ProjectTasksTriggerHelper.wOAssetRecordTypeId
                                AND Status = 'Active'
                                AND AccountId IN :listOfAccountId
                            )
                        ]
                    )
                {
                    if (eachAsset != null && eachAsset.AccountId != null) {
                        woActiveList.put(eachAsset.AccountId, eachAsset);
                    }
                }
            }
            if (!mapOfProjectAndAccount.values().isEmpty()) {
                for (NSP_Account_Team__c accTeamMember : [
                            SELECT
                                Id ,
                                NSP_Role__c ,
                                NSP_Account__c ,
                                NSP_Email__c ,
                                NSP_First_Name__c ,
                                NSP_Last_Name__c ,
                                NSP_Work_Phone__c ,
                                NSP_User__c
                            FROM NSP_Account_Team__c
                            WHERE (
                                ( NSP_Account__c IN :mapOfProjectAndAccount.values() )
                                AND ( NSP_Role__c IN :peoTerminationTeamRoles )
                                AND ( NSP_User__c != null )
                            )
                            ORDER BY NSP_Role__c DESC
                        ]
                    )
                {
                    if ( ( accTeamMember != null )
                        && ( accTeamMember.NSP_Account__c != null )
                        && ( mapOfProjectAndAccount.values().contains( accTeamMember.NSP_Account__c ) )
                        )
                    {
                        if ( accTeamMember.NSP_Role__c == 'Payroll Specialist' ) {
                            if ( !mapOfAccountPayrollMem.containsKey( accTeamMember.NSP_Account__c ) ) {
                                mapOfAccountPayrollMem.put(
                                    accTeamMember.NSP_Account__c ,
                                    new List<NSP_Account_Team__c>()
                                );
                            }
                            mapOfAccountPayrollMem.get( accTeamMember.NSP_Account__c ).add( accTeamMember );
                        }
                        if ( !mapOfAccountAndListOfAccountTeamMemberEmailAddress.containsKey( accTeamMember.NSP_Account__c ) ) {
                            mapOfAccountAndListOfAccountTeamMemberEmailAddress.put(
                                accTeamMember.NSP_Account__c ,
                                new List<String>()
                            );
                        }
                        mapOfAccountAndListOfAccountTeamMemberEmailAddress.get( accTeamMember.NSP_Account__c ).add( accTeamMember.NSP_Email__c );
                        if ( !mapOfAccountAndListOfAccountTeamMember.containsKey( accTeamMember.NSP_Account__c ) ) {
                            mapOfAccountAndListOfAccountTeamMember.put(
                                accTeamMember.NSP_Account__c ,
                                new List<NSP_Account_Team__c>()
                            );
                        }
                        mapOfAccountAndListOfAccountTeamMember.get( accTeamMember.NSP_Account__c ).add( accTeamMember );
                    }
                }
            }
            if ( !projectTaskLetterMap.isEmpty() ) {
                for (pse__Project_Task__c pTask : lProjectTasks) {
                    if ( ( pTask != null )
                        && projectTaskLetterMap.containsKey( pTask.Id )
                        && woActiveList.containsKey( pTask.NSP_AccountId__c )
                        && ( pTask.Name == writtenTermination )
                        && mapOfAccountAndListOfAccountTeamMember.containsKey( pTask.NSP_AccountId__c )
                        )
                    {
                        if ( !mapOfAccountAndListOfAccountTeamMemberEmailAddress.isEmpty() ) {
                            listOfToAddresses.addAll(
                                mapOfAccountAndListOfAccountTeamMemberEmailAddress.get(
                                    mapOfProjectAndAccount.get( pTask.Id )
                                )
                            );
                        }
                        listOfToAddresses.add( System.Label.NSP_Termination_Team );
                        this.letterReceivedEmail(
                            pTask ,
                            projectTaskLetterMap.get( pTask.Id ).pse__Project__r.pse__Account__r ,
                            listOfToAddresses ,
                            woActiveList.get( pTask.NSP_AccountId__c ) ,
                            mapOfAccountAndListOfAccountTeamMember.get( pTask.NSP_AccountId__c )
                        );
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTasksTriggerHelper.class.getName() ,
                'sendEmailToAccountTeamMembersIfTaskIsLetterReceived' ,
                e
            );
        }
    }

    //Letter Received email.
    private void letterReceivedEmail(
        pse__Project_Task__c pTask ,
        Account pTaskAccount ,
        List<String> listOfToAddresses ,
        Asset pTaskAsset ,
        List<NSP_Account_Team__c> accountTeamList
        )
    {
        try {
            String dtStr;
            if ( pTaskAsset.NSP_Anticipated_Date_Of_Termination__c != null ) {
                dtStr = pTaskAsset.NSP_Anticipated_Date_Of_Termination__c.format();
            }
            String accName = pTaskAccount.Name + '(' + pTaskAccount.NSP_AIMS_Client__c + ')';
            String customUrl = URL.getOrgDomainURL().toExternalForm() + '/' + pTaskAccount.Id;
            String projectTaskUrl = URL.getOrgDomainURL().toExternalForm() + '/' + pTask.Id;
            String subjectString = 'Termination letter received for ' + pTaskAccount.Name + '(' + pTaskAccount.NSP_AIMS_Client__c + ')';
            String mailBody = 'Hello Team,'+ NSP_ProjectTasksTriggerHelper.LINE_BREAK;
            mailBody += NSP_ProjectTasksTriggerHelper.buildAnchorElement( customUrl , accName );
            mailBody += ' submitted written notification of their intent to terminate their contract with Insperity.';
            mailBody += ' Below are the details of the termination:' + NSP_ProjectTasksTriggerHelper.LINE_BREAK;
            mailBody += 'Intended effective termination date: ' + dtStr + '<br/>';
            mailBody += 'Termination reason: ' + pTaskAsset.NSP_Reason_for_Term__c + '<br/>';
            mailBody += 'Project Task: '
                + NSP_ProjectTasksTriggerHelper.buildAnchorElement( projectTaskUrl , pTask.Name )
                + NSP_ProjectTasksTriggerHelper.LINE_BREAK;
            if(!accountTeamList.isEmpty()) {
                for(NSP_Account_Team__c accTeam : accountTeamList){
                    if ( ( accTeam.NSP_Role__c == 'Payroll Specialist' )
                        || ( accTeam.NSP_Role__c == 'Payroll Supervisor' )
                        || ( accTeam.NSP_Role__c == 'Client Liaison' )
                        || ( accTeam.NSP_Role__c == 'Manager, HR Services' )
                        || ( accTeam.NSP_Role__c == 'Business Performance Advisor' )
                        || ( accTeam.NSP_Role__c == 'Bus. Team-HRSp/CL' )
                        || ( accTeam.NSP_Role__c == 'MidMarket Account Exec' )
                        || ( accTeam.NSP_Role__c == '401k Plan Consultant' )
                        || ( accTeam.NSP_Role__c == 'Renewal Coordinator' )
                        )
                    {
                        mailBody += accTeam.NSP_Role__c
                            + ': ' +accTeam.NSP_First_Name__c
                            + ' ' + accTeam.NSP_Last_Name__c
                            + '<br/>';
                    }
                }
            }
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(listOfToAddresses);
            email.setSubject(subjectString);
            email.setHtmlBody(mailBody);
            email.setSaveAsActivity(false);
            email.setTargetObjectId(userinfo.getUserId());
            if ( !Test.isRunningTest() ) {
                NSP_ProjectTasksTriggerHelper.sendSingleEmailMessage( email );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTasksTriggerHelper.class.getName() ,
                'letterReceivedEmail' ,
                e
            );
        }
    }

    private static String buildAnchorElement( String link , String label ) {
        return '<a href="' + link + '">' + label + '</a>';
    }

    // Description : This method throws an error if Dependent Task is started without completing Preceding Task
    // Date : 12/10/2021
    public void showErrorIfPreceedingTaskNotCompleted( List<pse__Project_Task__c> lProjectTasks, Map<Id,pse__Project_Task__c> oldMap ) {
        set<ID> setOfDependentTask                      = new set<ID>();
        set<ID> setOfPrecedingTask                      = new set<ID>();
        map<Id, Id> mapOfDependentTaskAndPrecedingtask  = new map<Id, Id>();

        for(pse__Project_Task__c projectTask : lProjectTasks){
            if(projectTask.pse__Started__c
                && projectTask.pse__Started__c != oldMap.get(projectTask.id).pse__Started__c){
                setOfDependentTask.add(projectTask.id);
            }
        }

        if(!setOfDependentTask.isEmpty()){
            for(pse__Project_Task_Dependency__c projectDependency : [SELECT pse__Dependent_Task__c, pse__Preceding_Task__c, pse__Type__c
                                                                    FROM pse__Project_Task_Dependency__c
                                                                    WHERE pse__Dependent_Task__c IN : setOfDependentTask
                                                                    and pse__Type__c = :NSP_ServiceConstants.FINISH_To_START]){
                if(projectDependency.pse__Preceding_Task__c != null){
                    setOfPrecedingTask.add(projectDependency.pse__Preceding_Task__c);

                    if(!mapOfDependentTaskAndPrecedingtask.containsKey(projectDependency.pse__Dependent_Task__c)){
                        mapOfDependentTaskAndPrecedingtask.put(projectDependency.pse__Dependent_Task__c, projectDependency.pse__Preceding_Task__c);
                    }
                }
            }
        }

        Map<Id,Boolean> isMapOfPrecedingTaskAndCompleted = this.buildMapOfPrecedingTaskAndCompleted( setOfPrecedingTask );
        if ( !isMapOfPrecedingTaskAndCompleted.isEmpty() ) {
            for ( pse__Project_Task__c projectTaskError : lProjectTasks ) {
                // when the current task has started...
                if ( projectTaskError.pse__Started__c ) {
                    // find the preceeding task...
                    Id precedingTaskId = null;
                    if ( ( projectTaskError.Id != null )
                        && mapOfDependentTaskAndPrecedingtask.containsKey( projectTaskError.Id )
                       )
                    {
                        precedingTaskId = mapOfDependentTaskAndPrecedingtask.get( projectTaskError.Id );
                    }
                    // check if the preceeding task is incomplete...
                    if ( ( precedingTaskId != null )
                        && isMapOfPrecedingTaskAndCompleted.containsKey( precedingTaskId )
                        && !isMapOfPrecedingTaskAndCompleted.get( precedingTaskId )
                       )
                    {
                        // show an error when the preceeding task is incomplete...
                        // ~ Error: You cannot start Dependent task without completing Preceding task
                        projectTaskError.addError( System.Label.NSP_ProjectTask_Validation );
                    }
                }
            }
        }
    }

    private Map<Id,Boolean> buildMapOfPrecedingTaskAndCompleted( Set<Id> setOfPrecedingTask ) {
        Map<Id,Boolean> response = new Map<Id,Boolean>();
        if ( ( setOfPrecedingTask != null ) && !setOfPrecedingTask.isEmpty() ) {
            for ( pse__Project_Task__c record : [
                        SELECT Is_Completed__c
                        FROM pse__Project_Task__c
                        WHERE Id IN :setOfPrecedingTask
                    ]
                )
            {
                if ( !response.containsKey( record.Id ) ) {
                    response.put( record.Id , record.Is_Completed__c );
                }
            }
        }
        return response;
    }

    /**
    * Iterates throught the list of new pse__Project_Task__c and passes the required attributes to other methods.
    * @param projectTaskNewMap Map of New project.
    * @param projecttaskOldMap Map of Old project.
    * @return void
    *
    */
    @future
    public static void onChangeOfProjectTemplate(Set<Id> projectTaskList){
        Set<Id> projectsIdSet = new Set<Id>();
        Map<Id, pse__Proj__c> parentProjectMap = new Map<Id, pse__Proj__c>();
        Map<Id, pse__Project_Task__c> projectTaskMap = new Map<Id, pse__Project_Task__c>();
        List<pse__Project_Task_Assignment__c> projectTaskAssignmentList = new List<pse__Project_Task_Assignment__c>();
        try{
            Contact resourceContact = [Select Id, pse__Salesforce_User__c From Contact WHERE pse__Salesforce_User__c =: UserInfo.getUserId()];
            if(resourceContact != null){
                for(pse__Project_Task__c projectTask : [SELECT pse__Project__c, NSP_Template_Generated__c
                                                        FROM pse__Project_Task__c
                                                        WHERE ID IN : projectTaskList]){
                    if(projectTask.pse__Project__c != null && !projectTask.NSP_Template_Generated__c){
                        projectsIdSet.add(projectTask.pse__Project__c);
                        projectTaskMap.put(projectTask.Id, projectTask);
                    }
                }
            }
            if(projectsIdSet.size() > 0){
                parentProjectMap = new Map<Id, pse__Proj__c>([Select Id, pse__Is_Template__c
                                                    From pse__Proj__c
                                                    WHERE pse__Is_Template__c = False
                                                    AND ID In: projectsIdSet]);

            }
            if(!parentProjectMap.isEmpty()){
                for(pse__Project_Task__c projectTask : projectTaskMap.values()){
                    if(parentProjectMap.get(projectTask.pse__Project__c) != null){
                        pse__Project_Task_Assignment__c projectTaskAssignment = new pse__Project_Task_Assignment__c();
                        projectTaskAssignment.pse__Resource__c = resourceContact.Id;
                        projectTaskAssignment.NSP_Priority__c = 1;
                        projectTaskAssignment.pse__Project_Task__c = projectTask.Id;
                        projectTaskAssignmentList.add(projectTaskAssignment);
                    }
                }
            }
            if(projectTaskAssignmentList.size() > 0){
                insert projectTaskAssignmentList;
            }
        }catch(exception ex){

        }
    }
    /**
    * This method update Template Used field on Project from Template Name field on Project task
    * @param projectTaskList List of New project.
    * @return void
    *
    */
    public void updateTemplateUsedFieldOnProject(List<pse__Project_Task__c> projectTaskList){
        Set<Id> setOfProjectId = new Set<Id>();
        Map<Id, Set<String>> mapOfProjectIdAndSetOfTemplateNameOnProjectTask = new Map<Id, Set<String>>();
        List<pse__Proj__c> listOfProject = new List<pse__Proj__c>();
        String templateUsed = '';

        for(pse__Project_Task__c projectTask : projectTaskList){
            if(projectTask.pse__Project__c != null && String.isBlank(projectTask.NSP_Implementation_Account_Id__c)){
                setOfProjectId.add(projectTask.pse__Project__c);
                if(mapOfProjectIdAndSetOfTemplateNameOnProjectTask.containsKey(projectTask.pse__Project__c)){
                    mapOfProjectIdAndSetOfTemplateNameOnProjectTask.get(projectTask.pse__Project__c);
                } else if(!mapOfProjectIdAndSetOfTemplateNameOnProjectTask.containsKey(projectTask.pse__Project__c)
                    && projectTask.Template_Name__c != null){
                                mapOfProjectIdAndSetOfTemplateNameOnProjectTask.put(projectTask.pse__Project__c, new Set<String> {projectTask.Template_Name__c});
                    }
                            }
        }

        for(pse__Proj__c project : [SELECT Templates_Used__c FROM pse__Proj__c WHERE ID IN : setOfProjectId and pse__Is_Template__c = false]){
            if(!mapOfProjectIdAndSetOfTemplateNameOnProjectTask.isEmpty()){
                if(project.Templates_Used__c != null){
                    templateUsed = project.Templates_Used__c + mapOfProjectIdAndSetOfTemplateNameOnProjectTask.get(project.id) + ',';
                } else {
                    templateUsed = mapOfProjectIdAndSetOfTemplateNameOnProjectTask.get(project.id) + ',';
                }
                if(templateUsed.contains('{') || templateUsed.contains('}')){
                    String tempRemovedSingleBrances = templateUsed.remove('{');
                    String tempRemovedSecondBraces  = tempRemovedSingleBrances.remove('}');
                    project.Templates_Used__c = tempRemovedSecondBraces.length()>255? tempRemovedSecondBraces.substring(0, 255):tempRemovedSecondBraces;
                }

                listOfProject.add(project);
            }
        }

        if(!listOfProject.isEmpty()){
            Database.update(listOfProject);
        }

    }

    //
    // INSERT: This method update Milestone Complete field on related Milestone and Project Complete field on related Project
    // @param projectTaskList List of New project.
    // @return void
    // STY-00717
    //
    public void updateMilestoneAndProjectPercentCompleteOnInsert( List<pse__Project_Task__c> projectTaskList ) {
        Set<Id> setOfMilestoneId = new Set<Id>();
        Set<Id> setOfProjectId = new Set<Id>();
        for ( pse__Project_Task__c pTask : projectTaskList ) {
            if ( pTask.pse__Milestone__c != null ) {
                setOfMilestoneId.add( pTask.pse__Milestone__c );
            }
            if ( pTask.pse__Project__c != null ) {
                setOfProjectId.add( pTask.pse__Project__c );
            }
        }
        if ( !setOfMilestoneId.isEmpty() ) {
            NSP_ProjectTasksTriggerHelper.updateMilestonePercentComplete( setOfMilestoneId );
        }
        //updating values in Project Percent Complete Field
        if ( !setOfProjectId.isEmpty()
            && !System.isQueueable()
            && !System.isFuture()
            && !System.isBatch()
            )
        {
            NSP_ProjectTasksTriggerHelper.updateProjectPercentageComplete( setOfProjectId );
        }
    }

    //
    // UPDATE: This method update Milestone Complete field and Project Complete on related Milestone and Project respectively after deletion of Project task
    // @param projectTaskList List of old project.
    // @Defect : DF-02180
    // STORY : STY-00717
    // @return void
    //
    public void afterDeleteProjectTask( List<pse__Project_Task__c> projectTaskList ) {
        Set<Id> setOfMilestoneId = new Set<Id>();
        Set<Id> projectIdSet = new Set<Id>();
        for ( pse__Project_Task__c pTask : projectTaskList ) {
            if ( pTask.pse__Milestone__c != null ) {
                setOfMilestoneId.add( pTask.pse__Milestone__c );
            }
            if ( pTask.pse__Project__c != null ) {
                projectIdSet.add( pTask.pse__Project__c );
            }
        }
        if ( !setOfMilestoneId.isEmpty() ) {
            NSP_ProjectTasksTriggerHelper.updateMilestonePercentComplete( setOfMilestoneId );
        }
        if ( !projectIdSet.isEmpty()
            && !System.isQueueable()
            && !System.isFuture()
            && !System.isBatch()
            )
        {
            NSP_ProjectTasksTriggerHelper.updateProjectPercentageComplete( projectIdSet );
        }
    }

    //
    // UPDATE: This method update Milestone Complete field and Project Complete field on related Milestone and Project respectively.
    // @param projectTaskList List of New project.
    // @param oldMap Map of Project
    // @return void
    // STY-00717
    //
    public void updateMilestoneAndProjectPercentCompleteOnUpdate( List<pse__Project_Task__c> projectTaskList , Map<Id,pse__Project_Task__c> oldMap ) {
        Set<Id> setOfMilestoneId = new Set<Id>();
        Set<Id> setOFProjectId = new Set<Id>();
        for ( pse__Project_Task__c pTask : projectTaskList ) {
            if ( pTask.NSP_PercentageCompleteFormula__c != null
                && !String.isBlank( pTask.pse__Status__c )
                && pTask.NSP_PercentageCompleteFormula__c != oldMap.get( pTask.Id ).NSP_PercentageCompleteFormula__c
                || ( pTask.pse__Status__c != oldMap.get( pTask.id ).pse__Status__c )
                )
            {
                if ( String.isNotBlank( pTask.pse__Milestone__c ) ) {
                    setOfMilestoneId.add( pTask.pse__Milestone__c );
                }
                if ( String.isNotBlank( pTask.pse__Project__c ) ) {
                    setOFProjectId.add( pTask.pse__Project__c );
                }
            }
        }
        if ( !setOfMilestoneId.isEmpty() ) {
            NSP_ProjectTasksTriggerHelper.updateMilestonePercentComplete( setOfMilestoneId );
        }
        if ( !setOfProjectId.isEmpty()
            && !System.isQueueable()
            && !System.isFuture()
            && !System.isBatch()
            )
        {
            NSP_ProjectTasksTriggerHelper.updateProjectPercentageComplete( setOfProjectId );
        }
    }

    private static void updateMilestonePercentComplete( Set<Id> milestoneIds ) {
        try {
            AggregateResult[] groupedResults = [
                SELECT
                    SUM(NSP_PercentageCompleteFormula__c) ,
                    COUNT(Id) ,
                    pse__Milestone__c
                FROM pse__Project_Task__c
                WHERE (
                    ( pse__Milestone__c IN :milestoneIds )
                    AND (
                        ( pse__Status__c != :NSP_ServiceConstants.PROJECT_TASK_CANCELLED )
                        OR ( pse__Status__c != :NSP_ServiceConstants.PROJECTSTATUSCOMPLETED )
                    )
                    AND ( pse__Synchronize_Milestone_And_Task__c = false )
                )
                GROUP BY pse__Milestone__c
            ];
            List<pse__Milestone__c> records = new List<pse__Milestone__c>();
            for ( AggregateResult ar : groupedResults ) {
                if ( ar.get( 'pse__Milestone__c' ) != null ) {
                    Id milestoneId = (Id)ar.get( 'pse__Milestone__c' );
                    Decimal count = (Decimal)ar.get( 'expr0' );
                    Decimal countOfRecords = (Decimal)ar.get( 'expr1' );
                    pse__Milestone__c record = new pse__Milestone__c(
                        Id=milestoneId
                    );
                    record.NSP_Milestone_Complete__c = ( count / countOfRecords );
                    records.add( record );
                }
            }
            if ( !records.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( records , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ProjectTasksTriggerHelper.class.getName() ,
                    'updateMilestonePercentComplete:update' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTasksTriggerHelper.class.getName() ,
                'updateMilestonePercentComplete' ,
                e
            );
        }
    }

    //
    // UPDATE: This method update Project Complete field on related Project
    // @return void
    // STY-00717
    //
    private static void updateProjectPercentageComplete( Set<Id> projectIds ) {
        if ( NSP_ProjectTasksTriggerHelper.isEnabledQueueablePercentage
            && ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() )
            )
        {
            ProjectPercentageCompleteQueueable.enqueueJob( projectIds );
        } else if ( NSP_ProjectTasksTriggerHelper.isEnabledFuturePercentage
            && ( Limits.getFutureCalls() < Limits.getLimitFutureCalls() )
            )
        {
            NSP_ProjectTasksTriggerHelper.updateProjectPercentageCompleteFuture( projectIds );
        }
    }

    // DEPRECATED ~ see ProjectPercentageCompleteQueueable
    @future
    private static void updateProjectPercentageCompleteFuture( Set<Id> projectIds ) {
        try {
            AggregateResult[] groupedResults = [
                SELECT
                    SUM(NSP_PercentageCompleteFormula__c) ,
                    COUNT(Id) ,
                    pse__Project__c
                FROM pse__Project_Task__c
                WHERE (
                    ( pse__Project__c IN :projectIds )
                    AND (
                        ( pse__Status__c != :NSP_ServiceConstants.PROJECT_TASK_CANCELLED )
                        OR ( pse__Status__c != :NSP_ServiceConstants.PROJECTSTATUSCOMPLETED )
                    )
                )
                GROUP BY pse__Project__c
            ];
            List<pse__Proj__c> records = new List<pse__Proj__c>();
            for ( AggregateResult ar : groupedResults ) {
                if ( ar.get( 'pse__Project__c' ) != null ) {
                    Id projectId = (Id)ar.get( 'pse__Project__c' );
                    Decimal count = (Decimal)ar.get( 'expr0' );
                    Decimal countOfRecords = (Decimal)ar.get( 'expr1' );
                    pse__Proj__c record = new pse__Proj__c(
                        Id=projectId
                    );
                    record.NSP_Project_Complete__c = ( count / countOfRecords );
                    records.add( record );
                }
            }
            if ( !records.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( records , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ProjectTasksTriggerHelper.class.getName() ,
                    'updateProjectPercentageCompleteFuture:update' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ProjectTasksTriggerHelper.handleException(
                e ,
                'updateProjectPercentageCompleteFuture'
            );
        }
    }

    // This method update NSP_NumberOfCompletedProjectTask__c field on related Milestone when project gets Cancelled/complete with total number of Complete + cancelled projects
    public void calculateNumberOfCompletedAndCancelledProjectTask( List<pse__Project_Task__c> projectTaskList , Map<Id, pse__Project_Task__c> oldMap ) {
        Set<Id> setOfMilestoneId = new Set<Id> ();
        List<pse__Milestone__c> listOfMilestone = new List<pse__Milestone__c>();
        try {
            for ( pse__Project_Task__c projectTask : projectTaskList ) {
                if ( ( projectTask.pse__Milestone__c != null )
                    && ( projectTask.RecordTypeId == NSP_ProjectTasksTriggerHelper.peoProjectTaskRecordTypeId )
                    && ( ( projectTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED )
                        || ( projectTask.pse__Status__c == NSP_ServiceConstants.PROJECT_TASK_CANCELLED )
                        )
                    )
                {
                    setOfMilestoneId.add( projectTask.pse__Milestone__c );
                }
            }
            if(!setOfMilestoneId.isEmpty()){
            AggregateResult[] groupedResults = [SELECT Count(id),pse__Milestone__c
                                                FROM pse__Project_Task__c
                                                WHERE pse__Milestone__c IN :setOfMilestoneId AND
                                                (pse__Status__c =: NSP_ServiceConstants.PROJECTSTATUSCOMPLETED OR pse__Status__c =: NSP_ServiceConstants.PROJECT_TASK_CANCELLED) AND
                                                pse__Synchronize_Milestone_And_Task__c = false
                                                GROUP BY pse__Milestone__c ];

            for(AggregateResult ar:groupedResults) {
                Id pMilestone = (ID)ar.get('pse__Milestone__c');
                if(pMilestone!=null){

                    Decimal countOfrecords = (Decimal)ar.get('expr0');
                    pse__Milestone__c milestone = new pse__Milestone__c(Id = pMilestone);
                    milestone.NSP_NumberOfCompletedProjectTask__c= countOfrecords;

                    listOfMilestone.add(milestone);
                }
            }
            }

            if(!listOfMilestone.isEmpty()){
                Database.update(listOfMilestone);
            }
        } catch( Exception e ) {
            NSP_ProjectTasksTriggerHelper.handleException(
                e ,
                'calculateNumberOfCompletedAndCancelledProjectTask'
            );
        }
    }

    /**
    * Update Depenedent Task Resources about Precending Task Completion if Responsible Party is Different
    * @param mNewProjectTasks Map of New project.
    * @param mOldProjectTasks Map of Old project.
    * @return void
    */
    public void afterUpdateTaskfilters(Map<Id, pse__Project_Task__c> mNewProjectTasks,Map<Id, pse__Project_Task__c> oldMapProjecttasks){
        Set<Id> sProjectTasksIds = new Set<Id>();
        Map<Id,Id> mapofProjecttasks = new Map<Id,Id>();
        Set<Id> projectTaskIdSet = new Set<Id>();
        Map<Id,Id> mapofFundingProjecttasks = new Map<Id,Id>();
        Set<Id> fundingprojectTaskIdSet = new Set<Id>();
        Map<Id,Id> mapofFormProjecttasks = new Map<Id,Id>();
        Set<Id> projectFsoIdset = new Set<Id>();
        Map<Id, Id> accountIdFsoProjectTaskMap = new Map<Id, Id>();
        Set<Id> projectTaskCobraIdSet = new  Set<Id>();
        Set<Id> projectTaskidsChangedOwner = new  Set<Id>();
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        Map<Id, Id> mapOfProjectTaskOwner = new Map<Id,Id>();
        Map<Id, Id> mapofClientProjectTask = new Map<Id, Id>();
        List<Id> accountIdList = new List<Id>();
        List<string> peoTerminationTaskList = System.Label.PEO_Termination_Tasks.split(';');
        String TERMINATIONANALYSIS = null;
        Map<Id,Id> mapOfProjectTaskAndProject = new Map<Id,Id>();
        List<Id> listOfAccountId = new List<Id>();
        if ( peoTerminationTaskList != null
            && !peoTerminationTaskList.isEmpty()
            && ( peoTerminationTaskList.size() >= 2 )
            )
        {
            TERMINATIONANALYSIS = peoTerminationTaskList[1];
        }
        if ( mNewProjectTasks != null
            && !mNewProjectTasks.values().isEmpty()
            )
        {
            for ( pse__Project_Task__c oProjectTask : mNewProjectTasks.values() ) {
                if ( oProjectTask.Name == TERMINATIONANALYSIS
                    && oProjectTask.NSP_Account_Id__c != NULL
                    && oldMapProjecttasks != null
                    && oldMapProjecttasks.containsKey(oProjectTask.Id)
                    && oldMapProjecttasks.get(oProjectTask.Id).NSP_Account_Id__c != oProjectTask.NSP_Account_Id__c
                    )
                {
                    accountIdList.add(oProjectTask.NSP_Account_Id__c);
                }
                // FILTER COMPLETED PROJECTS
                if ( oProjectTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED
                    && oldMapProjecttasks.get(oProjectTask.Id).pse__Status__c != NSP_ServiceConstants.PROJECTSTATUSCOMPLETED
                    && oProjectTask.Name != NSP_ProjectTasksTriggerHelper.SUBMIT_TERMINATION_CHECKLIST
                    )
                {
                    sProjectTasksIds.add(oProjectTask.Id);
                }
                if ( ( oldMapProjecttasks.get( oProjectTask.Id ).pse__Status__c != NSP_ServiceConstants.TASKCOMPLETE )
                    && ( oProjectTask.pse__Status__c == NSP_ServiceConstants.TASKCOMPLETE )
                    && ( oProjectTask.pse__Project__c != null )
                    )
                {
                    //check if FEIN project task is completed
                    if(oProjectTask.Name==NSP_ServiceConstants.FEIN  ){
                        mapofProjecttasks.put(oProjectTask.pse__Project__c,oProjectTask.Id);
                        projectTaskIdSet.add(oProjectTask.Id);
                    }
                    //check if FUNDING DOCUMENTS project task is completed
                    if(oProjectTask.Name==NSP_ServiceConstants.FUNDINGDOCUMENTS ){
                        mapofFundingProjecttasks.put(oProjectTask.pse__Project__c,oProjectTask.Id);
                        fundingprojectTaskIdSet.add(oProjectTask.Id);
                    }
                    //check if FORM COLLECTED project task is completed
                    if(oProjectTask.Name==NSP_ServiceConstants.FORMCOLLECTED){
                        mapofFormProjecttasks.put(oProjectTask.pse__Project__c,oProjectTask.Id);
                    }
                    //Check if subtask first payroll approved task is completed
                    if ( oProjectTask.pse__Parent_Task__c!=null
                        && oProjectTask.Name==NSP_ServiceConstants.PAYROLLAPPROVED
                        )
                    {
                        projectFsoIdset.add(oProjectTask.pse__Project__c);
                        accountIdFsoProjectTaskMap.put(oProjectTask.NSP_AccountId__c, oProjectTask.Id);
                    }
                    //Check if cobra  task is completed
                    if ( oProjectTask.Name.startsWith(NSP_ServiceConstants.COBRA_FORM_YES)
                        || oProjectTask.Name.startsWith(NSP_ServiceConstants.COBRA_FORM_NO)
                        )
                    {
                        projectTaskCobraIdSet.add(oProjectTask.Id);
                        projectTaskList.add(oProjectTask);
                    }
                    //Check if client transition is completed
                    if(oProjectTask.Name==NSP_ServiceConstants.CLIENTTRANSITION){
                        mapOfProjectTaskOwner.put(oProjectTask.pse__Project__c, oProjectTask.OwnerId);
                        mapofClientProjectTask.put(oProjectTask.pse__Project__c,oProjectTask.id);
                    }
                    discoveryProject(oProjectTask);
                }

                if ( oldMapProjecttasks.get(oProjectTask.Id).pse__Status__c != oProjectTask.pse__Status__c
                    && oProjectTask.pse__Status__c == NSP_ServiceConstants.TASKCOMPLETE
                    )
                {
                }
                if ( oldMapProjecttasks.get(oProjectTask.Id).OwnerId != oProjectTask.OwnerId
                    && oProjectTask.OwnerId.getsobjecttype() == User.sobjecttype
                    )
                {
                    projectTaskidsChangedOwner.add(oProjectTask.Id);
                }
                //Check projectTaskName and Status
                if ( oProjectTask != null
                    && oProjectTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED
                    && oldMapProjecttasks != null
                    && oldMapProjecttasks.containsKey(oProjectTask.Id)
                    && oProjectTask.pse__Status__c != oldMapProjecttasks.get(oProjectTask.Id).pse__Status__c
                   )
                {
                    if ( oProjectTask.Name == NSP_ProjectTasksTriggerHelper.SUBMIT_TERMINATION_CHECKLIST ) {
                        if ( !mapOfProjectTaskAndProject.containsKey(oProjectTask.Id) ) {
                            mapOfProjectTaskAndProject.put(
                                oProjectTask.Id ,
                                oProjectTask.pse__Project__c
                            );
                        }
                        if ( oProjectTask.NSP_AccountId__c != null ) {
                            listOfAccountId.add(oProjectTask.NSP_AccountId__c);
                        }
                    }
                }
            }
        }
        if ( !mapOfProjectTaskAndProject.isEmpty() && !listOfAccountId.isEmpty() ) {
            onSubmitTaskCompletion( mapOfProjectTaskAndProject , listOfAccountId );
        }
        if ( !projectTaskidsChangedOwner.isEmpty() && !System.isFuture() && !System.isBatch() ) {
            Map<String,Object> mapInputParams = new Map<String,Object>{
                'projectTaskidsChangedOwner' => projectTaskidsChangedOwner
            };
            List<NSP_ProjectTaskQueueEvent__e> lstTaskQueueEvent = new List<NSP_ProjectTaskQueueEvent__e>();
            lstTaskQueueEvent.add(
                new NSP_ProjectTaskQueueEvent__e(
                    NSP_Input_Parameters__c=JSON.serialize( mapInputParams ) ,
                    NSP_MethodName__c='createPTAIfOwnerIsChanged' ,
                    NSP_UserId__c=UserInfo.getUserId()
                )
            );
            List<Database.SaveResult> saveResults = EventBus.publish( lstTaskQueueEvent );
            NSP_ErrorLogHandler.logResults(
                NSP_ProjectTasksTriggerHelper.class.getName() ,
                'afterUpdateTaskfilters:publish' ,
                saveResults
            );
        }
        if ( !sProjectTasksIds.isEmpty()
            && NotificationDeliverabilityController.IsEnabledOutbound
            )
        {
            NSP_ProjectTasksTriggerHelper.sendNotificationToDependentResource( sProjectTasksIds );
            NSP_ProjectTasksTriggerHelper.sendBellNotificationToDependentResource( sProjectTasksIds );
        }
        if ( !sProjectTasksIds.isEmpty() ) {
            NSP_ProjectTasksTriggerHelper.sendEmailToProjectResource( sProjectTasksIds ); // STY-02213
        }
        if ( !projectTaskIdSet.isEmpty() ) {
            NSP_ProjectTaskTriggerEmailNotification.emailNotifyforFEIN(
                projectTaskIdSet ,
                mapofProjecttasks
            );
        }
        if ( NSP_ProjectTasksTriggerHelper.isUpdateDocusignAsset
            && !accountIdList.isEmpty()
            )
        {
            NSP_ProjectTasksTriggerHelper.updateDocusignAsset( accountIdList );
        }
        if ( !fundingprojectTaskIdSet.isEmpty() ) {
            NSP_ProjectTaskTriggerEmailNotification.emailNotifyforFundingDocuments(
                fundingprojectTaskIdSet ,
                mapofFundingProjecttasks
            );
        }
        if ( !mapofFormProjecttasks.isEmpty() ) {
            NSP_ProjectTasksTriggerHelper.ipYesFormCollected( mapofFormProjecttasks );
        }
        if ( !projectFsoIdset.isEmpty() ) {
            NSP_ProjectTaskTriggerEmailNotification.emailNotifyforFirstPayrollFSO(
                projectFsoIdset ,
                accountIdFsoProjectTaskMap
            );
        }
        if ( !projectFsoIdset.isEmpty()
            && NSP_Trigger_Switch__c.getInstance( UserInfo.getUserId() ).NSP_FP_MM_EmailNotification__c
            )
        {
            NSP_ProjectTaskTriggerEmailNotification.emailNotifyforFirstPayrollMM(
                projectFsoIdset ,
                accountIdFsoProjectTaskMap
            );
        }
        if ( !projectTaskCobraIdSet.isEmpty() ) {
            NSP_ProjectTaskTriggerEmailNotification.emailNotifyforCobraFollowUp(
                projectTaskCobraIdSet ,
                projectTaskList
            );
        }
        if ( !mapofClientProjectTask.isEmpty() ) {
            NSP_ProjectTaskTriggerEmailNotification.emailNotifyClientTransition(
                mapofClientProjectTask ,
                mapOfProjectTaskOwner
            );
        }
    }

    //Email On Site Discovery
    private void discoveryProject( pse__Project_Task__c oProjectTask ) {
        Map<Id,Id> mapofDiscoveryProjectTask = new Map<Id,Id>();
        Map<Id,Id> mapOfDiscoveryProjectTaskOwner = new Map<Id,Id>();
        if ( ( oProjectTask != null )
            && ( oProjectTask.Name == NSP_ServiceConstants.ONSITEDISCOVERY )
            )
        {
            mapOfDiscoveryProjectTaskOwner.put( oProjectTask.pse__Project__c , oProjectTask.OwnerId );
            mapofDiscoveryProjectTask.put( oProjectTask.pse__Project__c , oProjectTask.id );
        }
        if ( !mapofDiscoveryProjectTask.isEmpty() ) {
            NSP_ProjectTaskTriggerEmailNotification.emailNotifyOnsiteDiscovery(
                mapofDiscoveryProjectTask ,
                mapOfDiscoveryProjectTaskOwner
            );
        }
    }

    public static void ipYesFormCollected(Map<Id, Id> mapOfProjectTasks) {
        List<Implementation_Profile__c> updateIpList = new List<Implementation_Profile__c>();
        Id ipMMRecordTypeId = NSP_GenericRecordType.getRecordTypeId(
            'Implementation_Profile__c' ,
            NSP_ServiceConstants.MMProfile
        );
        try {
            if ( mapOfProjectTasks != null
                && !mapOfProjectTasks.isEmpty()
                && ipMMRecordTypeId != null
                )
            {
                // Update IP field form discussed to yes when the form discussed project task is complete
                for ( Implementation_Profile__c ip : [
                            SELECT Id , Has_form_8973_been_discussed__c , NSP_Project__c
                            FROM Implementation_Profile__c
                            WHERE (
                                NSP_Project__c IN :mapOfProjectTasks.keySet()
                                AND RecordTypeId = :ipMMRecordTypeId
                                AND Has_form_8973_been_discussed__c != :NSP_ServiceConstants.YES
                            )
                        ]
                    )
                {
                    ip.Has_form_8973_been_discussed__c = NSP_ServiceConstants.YES;
                    updateIpList.add(ip);
                }
                if ( !updateIpList.isEmpty() ) {
                    // Perform the update and log results
                    Database.SaveResult[] results = Database.update( updateIpList , false );
                    NSP_ErrorLogHandler.logResults(
                        NSP_ProjectTasksTriggerHelper.class.getName() ,
                        'ipYesFormCollected:update' ,
                        results
                    );
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTasksTriggerHelper.class.getName(),
                'ipYesFormCollected',
                e
            );
        }
    }

    private void onSubmitTaskCompletion( Map<Id,Id> mapOfProjectTaskAndProject , List<Id> listOfAccountId ) {
        Id TAAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.TIME_ATTENDANCE_ASSET);
        Id PMAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.PERFORMANCE_MANAGEMENT_ASSET);
        Id OPAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset','Organizational_Planning');
        Id XMLAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.XML_ASSET);
        Id IntegraAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.INTEGRA_ASSET);
        try {
            Map<Id,NSP_Termination_Form__c> projectTaskTermFormMap = new Map<Id,NSP_Termination_Form__c>();
            Map<Id,Id> projectMap = new Map<Id,Id>();
            Map<Id,pse__Project_Task__c> projectTaskMap = new Map<Id,pse__Project_Task__c>();
            if (!mapOfProjectTaskAndProject.isEmpty()) {
                for ( NSP_Termination_Form__c termForm : [
                            SELECT
                                Id ,
                                NSP_Project_Task__c ,
                                NSP_Last_Date_Wages_Paid_Through__c ,
                                NSP_Term_Reason__c ,
                                NSP_SubTerm_reason__c,
                                Previous_Term_Date__c ,
                                NSP_Revision__c ,
                                CreatedDate
                            FROM NSP_Termination_Form__c
                            WHERE ( NSP_Project_Task__c IN :mapOfProjectTaskAndProject.keySet() )
                            ORDER BY CreatedDate DESC
                        ]
                    )
                {
                    if ( String.isNotBlank( termForm.NSP_Project_Task__c )
                        && !projectTaskTermFormMap.containsKey( termForm.NSP_Project_Task__c )
                        )
                    {
                        projectTaskTermFormMap.put( termForm.NSP_Project_Task__c , termForm );
                    }
                }
                for ( pse__Project_Task__c projectTask : [
                            SELECT
                                Id , Name , pse__Project__r.pse__Account__r.Name ,
                                pse__Project__r.pse__Account__r.NSP_AIMS_Client__c , NSP_AccountId__c
                            FROM pse__Project_Task__c
                            WHERE ( Id IN :mapOfProjectTaskAndProject.keySet() )
                        ]
                    )
                {
                    if (projectTask != null) {
                        if (!projectTaskMap.containsKey(projectTask.Id)) {
                            projectTaskMap.put(projectTask.Id, projectTask);
                        }
                        if (!projectMap.containsKey(projectTask.Id)) {
                            projectMap.put(projectTask.Id, projectTask.pse__Project__c);
                        }
                    }
                }
            }
            Map<Id,List<Asset>> activeAssetList = new Map<Id,List<Asset>>();
            if ( !listOfAccountId.isEmpty() ) {
                for ( Asset eachAsset : [
                            SELECT Id , AccountId, Name
                            FROM Asset
                            WHERE (
                                (
                                    RecordTypeId = :TAAssetRecordTypeId
                                    OR RecordTypeId = :PMAssetRecordTypeId
                                    OR RecordTypeId = :OPAssetRecordTypeId
                                    OR RecordTypeId = :XMLAssetRecordTypeId
                                    OR RecordTypeId = :IntegraAssetRecordTypeId
                                )
                                AND NSP_Account_Status__c != :NSP_ServiceConstants.TERMINATED
                                AND AccountId IN :listOfAccountId
                            )
                        ]
                    )
                {
                    if ( !activeAssetList.containsKey( eachAsset.AccountId ) ) {
                        activeAssetList.put(
                            eachAsset.AccountId ,
                            new List<Asset>()
                        );
                    }
                    activeAssetList.get( eachAsset.AccountId ).add( eachAsset );
                }
            }
            List<pse__Project_Task__c> optionalProjectTask = new List<pse__Project_Task__c>();
            if ( !projectTaskMap.isEmpty() && !projectMap.values().isEmpty() ) {
                List<pse__Project_Task__c> optionalTasks = [
                    SELECT Id,pse__Project__c
                    FROM pse__Project_Task__c
                    WHERE (
                        pse__Project__c IN :projectMap.values()
                        AND Name = 'Optional: Initiate BPS Termination'
                    )
                ];
                Map<Id,pse__Project_Task__c> optionalTaskMap = new Map<Id,pse__Project_Task__c>();
                for ( pse__Project_Task__c optionalTask : optionalTasks ) {
                    optionalTaskMap.put( optionalTask.pse__Project__c , optionalTask );
                }
                List<String> emailTermination_Task_Completion = new List<String>();
                if ( String.isNotBlank( System.Label.Termination_Task_Completion ) ) {
                    emailTermination_Task_Completion = System.Label.Termination_Task_Completion.split(',');
                }
                List<String> listOfToAddresses = new List<String>();
                listOfToAddresses.addAll( emailTermination_Task_Completion );
                for (pse__Project_Task__c pTask : projectTaskMap.Values()) {
                    if ( pTask != null
                        && pTask.NSP_AccountId__c != null
                        && activeAssetList.containsKey(pTask.NSP_AccountId__c)
                        && pTask.Name == NSP_ProjectTasksTriggerHelper.SUBMIT_TERMINATION_CHECKLIST
                        && pTask.pse__Project__c != null
                       )
                    {
                        pse__Project_Task__c optionalTask = optionalTaskMap.get(pTask.pse__Project__c);
                        assetListEmail(
                            projectTaskMap.get(pTask.Id).pse__Project__r.pse__Account__r.Name,
                            projectTaskMap.get(pTask.Id).pse__Project__r.pse__Account__c,
                            projectTaskMap.get(pTask.Id).pse__Project__r.pse__Account__r.NSP_AIMS_Client__c,
                            listOfToAddresses,
                            activeAssetList.get(pTask.NSP_AccountId__c),
                            projectTaskTermFormMap.get(pTask.Id)
                        );
                        if (optionalTask != null) {
                            optionalTask.pse__Status__c = NSP_ServiceConstants.PROJECTSTATUSCOMPLETED;
                            optionalProjectTask.add(optionalTask);
                        }
                    } else if ( pTask != null
                        && pTask.NSP_AccountId__c != null
                        && !activeAssetList.containsKey(pTask.NSP_AccountId__c)
                        && pTask.Name == NSP_ProjectTasksTriggerHelper.SUBMIT_TERMINATION_CHECKLIST
                        && pTask.pse__Project__c != null
                        )
                    {
                        pse__Project_Task__c optionalTask = optionalTaskMap.get(pTask.pse__Project__c);
                        if (optionalTask != null) {
                            optionalTask.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_CANCELLED;
                            optionalTask.pse__Long_Description__c = 'No active BPS Assets';
                            optionalProjectTask.add(optionalTask);
                        }
                    }
                }
            }
            if ( !optionalProjectTask.isEmpty() ) {
                update optionalProjectTask;
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTasksTriggerHelper.class.getName() ,
                'onSubmitTaskCompletion' ,
                e
            );
        }
    }

    //Letter Received email.
    private void assetListEmail(
        String accountName ,
        Id accountId ,
        String accountAIMS ,
        List<String> listOfToAddresses ,
        List<Asset> assetList ,
        NSP_Termination_Form__c termForm
        )
    {
        String subjectString = null;
        String mailBody = null;
        String accName = accountName+' | '+accountAIMS;
        String customUrl = URL.getOrgDomainURL().toExternalForm()+ '/'+accountId;
        String prefix = 'WO Client ';
        if ( ( termForm != null ) && ( termForm.NSP_Revision__c == 'Yes' ) ) {
            prefix = 'REVISION WO Client ';
        }
        subjectString = prefix + accName + ' has been approved for termination';
        mailBody = prefix + NSP_ProjectTasksTriggerHelper.buildAnchorElement( customUrl , accName );
        mailBody = NSP_ProjectTasksTriggerHelper.addTermDetails ( mailBody , termForm , assetList );
        NSP_ProjectTasksTriggerHelper.sendEmail( listOfToAddresses , subjectString , mailBody , null );
    }

    private static String addTermDetails( String mailBody , NSP_Termination_Form__c termForm , List<Asset> assetList ) {
        String termFormDetails = '';
        if ( String.isBlank( mailBody ) ) {
            mailBody = '';
        }
        if ( termForm != null ) {
            if ( termForm.NSP_Last_Date_Wages_Paid_Through__c != null ) {
                termFormDetails = ' on ' + termForm.NSP_Last_Date_Wages_Paid_Through__c.format();
            }
            mailBody += ' has been approved for termination' + termFormDetails + '.' + '<br>';
            if ( ( termForm.NSP_Revision__c == 'Yes' ) && ( termForm.Previous_Term_Date__c != null ) ) {
                mailBody += 'Previous Term Date: '+ termForm.Previous_Term_Date__c.format() + '<br>';
            }
            if ( String.isNotBlank( termForm.NSP_Term_Reason__c ) ) {
                mailBody += 'Term Reason: ' + termForm.NSP_Term_Reason__c + '<br>';
            }
            if ( String.isNotBlank( termForm.NSP_SubTerm_reason__c ) ) {
                mailBody += 'Sub Term Reason: '
                    + termForm.NSP_SubTerm_reason__c
                    + NSP_ProjectTasksTriggerHelper.LINE_BREAK;
            }
        }
        mailBody += 'Please review the following Assets to determine next steps for termination.' + '<br>';
        if ( ( assetList != null ) && !assetList.isEmpty() ) {
            for ( Asset asset : assetList ) {
                String assetUrl = URL.getOrgDomainURL().toExternalForm()+ '/'+asset.Id;
                mailBody += NSP_ProjectTasksTriggerHelper.buildAnchorElement( assetUrl , asset.Name ) + '<br/>';
            }
        }
        return mailBody;
    }

    public static void sendEmail( List<String> listOfToAddresses , String subject , String body , String recordId ) {
        try {
            Map<String,Object> inputs = new Map<String,Object>();
            if ( ( listOfToAddresses != null ) && !listOfToAddresses.isEmpty() ) {
                inputs.put( 'toEmailAddresses' , listOfToAddresses );
                inputs.put( 'emailSubject' , subject );
                inputs.put( 'emailBody' , body );
                inputs.put( 'recordId' , recordId );
                inputs.put( 'logEmail' , true );
                Flow.Interview.Send_Email sendEmailFlow = new Flow.Interview.Send_Email( inputs );
                sendEmailFlow.start();
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTasksTriggerHelper.class.getName() ,
                'sendEmail' ,
                e
            );
        }
    }

    // Method to Send Bell Notifications when a Client, Payroll Termination Form is Approved
    @future
    private static void sendBellNotificationToDependentResource( Set<Id> sProjectTasksIds ) {
        Id clientRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'NSP_Termination_Form__c' , 'NSP_Client_Reinstatement' );
        Id payrollRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'NSP_Termination_Form__c' , 'NSP_Payroll_Specialist_Form' );
        String mPrecedingTaskId;
        Set<String> mDependentTaskOwnerIds = new Set<String>();

        List<pse__Project_Task_Dependency__c> mDependentTasksOwner = new List<pse__Project_Task_Dependency__c>(
            [
                SELECT
                    Id ,
                    pse__Preceding_Task__c ,
                    pse__Dependent_Task__r.OwnerId
                FROM pse__Project_Task_Dependency__c
                WHERE ( pse__Preceding_Task__c IN :sProjectTasksIds )
            ]
        );
        List<NSP_Termination_Form__c> termFormList = new List<NSP_Termination_Form__c>(
            [
                SELECT
                    Id ,
                    NSP_Project_Task__c ,
                    OwnerId
                FROM NSP_Termination_Form__c
                WHERE (
                    ( NSP_Project_Task__c IN :sProjectTasksIds )
                    AND ( NSP_Project_Task__r.RecordTypeId = :NSP_ProjectTasksTriggerHelper.peoProjectTaskRecordTypeId )
                    AND (
                        ( RecordTypeId = :clientRecordTypeId )
                        OR ( RecordTypeId = :payrollRecordTypeId )
                    )
                )
            ]
        );

        if ( !mDependentTasksOwner.isEmpty() ) {
            mPrecedingTaskId = mDependentTasksOwner.get(0).pse__Preceding_Task__c;
        } else {
            return;
        }

        Set<Id> termFormRecordList = NSP_ProjectTasksTriggerHelper.collectProjectTaskIds( termFormList );

        for ( pse__Project_Task_Dependency__c mOwnerDependentTask : mDependentTasksOwner ) {
            if ( mOwnerDependentTask.pse__Dependent_Task__r.OwnerId != null
                && termFormRecordList.contains( mOwnerDependentTask.pse__Preceding_Task__c )
                )
            {
                mDependentTaskOwnerIds.add( mOwnerDependentTask.pse__Dependent_Task__r.OwnerId );
            }
        }

        if ( mDependentTaskOwnerIds.isEmpty() ) {
            return;
        } else {
            List<CustomNotificationType> bellNotificationTypes = [
                SELECT Id , DeveloperName
                FROM CustomNotificationType
                WHERE ( DeveloperName = 'NSP_Bell_Notification_Termination_Form' )
                LIMIT 1
            ];
            if ( !bellNotificationTypes.isEmpty() ) {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setNotificationTypeId( bellNotificationTypes[0].Id );
                notification.setTitle( 'Termination Form approval Completed' );
                notification.setBody( 'You have task(s) to complete' );
                notification.setTargetId( mPrecedingTaskId );
                notification.send( mDependentTaskOwnerIds );
            }
        }
    }

    // reduce sonar cognitive complexity...
    private static Set<Id> collectProjectTaskIds( List<NSP_Termination_Form__c> records ) {
        Set<Id> projectTaskIds = new Set<Id>();
        if ( ( records != null ) && !records.isEmpty() ) {
            for ( NSP_Termination_Form__c record : records ) {
                if ( record.OwnerId != null ) {
                    projectTaskIds.add( record.NSP_Project_Task__c );
                }
            }
        }
        return projectTaskIds;
    }

    // Update Depenedent Task Resources about Precending Task Completion if Responsible Party is Different
    @future
    public static void sendNotificationToDependentResource( Set<Id> sProjectTasksIds ) {
        Id bpsProjectTaskRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Project_Task__c' , 'BPS_Project_Task' );
        Set<Id> sDependentTasksIds = new Set<Id>();
        List<pse__Project_Task_Dependency__c> lDependentTasks = new List<pse__Project_Task_Dependency__c>([SELECT Id,pse__Preceding_Task__c,pse__Preceding_Task__r.RecordTypeId,pse__Preceding_Task__r.Responsible_Party__c,pse__Dependent_Task__c,pse__Dependent_Task__r.RecordTypeId,pse__Dependent_Task__r.Responsible_Party__c FROM pse__Project_Task_Dependency__c WHERE pse__Preceding_Task__c in: sProjectTasksIds]);
        if(lDependentTasks.size() == 0){
            return;
        }
        for(pse__Project_Task_Dependency__c oDependentTask : lDependentTasks){
            if ( oDependentTask.pse__Dependent_Task__r.RecordTypeId == bpsProjectTaskRecordTypeId ) {
                if(String.isBlank(oDependentTask.pse__Dependent_Task__r.Responsible_Party__c) || oDependentTask.pse__Dependent_Task__r.Responsible_Party__c != oDependentTask.pse__Preceding_Task__r.Responsible_Party__c){
                    sDependentTasksIds.add(oDependentTask.pse__Dependent_Task__c);
                }
            } else if ( oDependentTask.pse__Dependent_Task__r.RecordTypeId == NSP_ProjectTasksTriggerHelper.peoProjectTaskRecordTypeId ) {
                // NO RESPONSIBLE PARTY CONDITION FOR PEO TASK
                sDependentTasksIds.add(oDependentTask.pse__Dependent_Task__c);
            }
        }
        if(sDependentTasksIds.size() == 0){
            return;
        }
        List<pse__Project_Task_Assignment__c> lTaskAssignments = new List<pse__Project_Task_Assignment__c>([SELECT Id,pse__Project_Task__c,pse__Project_Task__r.RecordTypeId,pse__Resource__c,pse__Resource__r.pse__Salesforce_User__c FROM pse__Project_Task_Assignment__c WHERE pse__Project_Task__c in :sDependentTasksIds]);
        Map<Id,Id> mBPSProjectTaskToResourceId = new Map<Id,Id>();
        Map<Id,Id> mPEOProjectTaskToResourceId = new Map<Id,Id>();
        for(pse__Project_Task_Assignment__c oProjectTaskAssignment : lTaskAssignments){
            if(oProjectTaskAssignment.pse__Resource__c != null && oProjectTaskAssignment.pse__Resource__r.pse__Salesforce_User__c != null){
                if ( oProjectTaskAssignment.pse__Project_Task__r.RecordTypeId == bpsProjectTaskRecordTypeId ) {
                    mBPSProjectTaskToResourceId.put(oProjectTaskAssignment.pse__Project_Task__c , oProjectTaskAssignment.pse__Resource__r.pse__Salesforce_User__c);
                } else if ( oProjectTaskAssignment.pse__Project_Task__r.RecordTypeId == NSP_ProjectTasksTriggerHelper.peoProjectTaskRecordTypeId ) {
                    mPEOProjectTaskToResourceId.put(oProjectTaskAssignment.pse__Project_Task__c , oProjectTaskAssignment.pse__Resource__r.pse__Salesforce_User__c);
                }
            }
        }
        if(mBPSProjectTaskToResourceId.keySet().size() > 0){
            NSP_EmailService.sendEmail(mBPSProjectTaskToResourceId, NSP_ServiceConstants.BPS_DEPENDENTTASKNOTIFICATIONTEMPLATE);
        }
        if(mPEOProjectTaskToResourceId.keySet().size() > 0){
            NSP_EmailService.sendEmail(mPEOProjectTaskToResourceId, NSP_ServiceConstants.PEO_DEPENDENTTASKNOTIFICATIONTEMPLATE);
        }
    }

    /**
    * Update Start Date and End date on Project Task using Offset date and # number of days offset.
    * USE THIS METHOD IF YOU ADD MORE VALUES TO OFFSET DATE.
    * @param projectTaskList List of project.
    * @return void
    */

    public void setStartDateAndEndDateOnProjectTask(List<pse__Project_Task__c> projectTaskList){
        Set<Id> setOfProjectId                         = new Set<Id>();
        Map<Id,pse__Proj__c> projectMap                = new Map<Id,pse__Proj__c> ();

        Id projectRecordType = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c',NSP_ServiceConstants.PEOProject);
        try{
            //iterate over project task to store project id
            for(pse__Project_Task__c projectTask : projectTaskList){
            if(projectTask.pse__Project__c != null && projectTask.NSP_Template_Generated__c){
                    setOfProjectId.add(projectTask.pse__Project__c);
            }else{
                projectTask.pse__Start_Date_Time__c = projectTask.pse__Start_Date_Time__c != null ? DateTime.newInstance(projectTask.pse__Start_Date_Time__c.date(), Time.newInstance(12, 0, 0, 0))
                    : projectTask.pse__Start_Date_Time__c;
                projectTask.pse__End_Date_Time__c = projectTask.pse__End_Date_Time__c != null ? DateTime.newInstance(projectTask.pse__End_Date_Time__c.date(), Time.newInstance(12, 0, 0, 0))
                    : projectTask.pse__End_Date_Time__c;
                }
            }


            //update start & end time of project task of rec type PEO & not of type implementation and template MM or FSO
            if(!setOfProjectId.isEmpty()){
                    for(pse__Project_Task__c projectTasks : projectTaskList){
                        if(projectTasks.NSP_Offset_Date__c == null){
                            projectTasks.pse__Start_Date_Time__c = projectTasks.pse__Start_Date_Time__c != null ? DateTime.newInstance(projectTasks.pse__Start_Date_Time__c.date(), Time.newInstance(12, 0, 0, 0))
                                : projectTasks.pse__Start_Date_Time__c;
                            projectTasks.pse__End_Date_Time__c = projectTasks.pse__End_Date_Time__c != null ? DateTime.newInstance(projectTasks.pse__End_Date_Time__c.date(), Time.newInstance(12, 0, 0, 0))
                                : projectTasks.pse__End_Date_Time__c;
                        }
                    }
            }
        } catch ( Exception e ) {
            NSP_ProjectTasksTriggerHelper.handleException(
                e ,
                'setStartDateAndEndDateOnProjectTask'
            );
        }
    }

    /**calling platform event trigger from after insert to call the setStartDateAndEndDateOnProjectTaskQTP method**/
    public void platformEventToSetStartDateAndTimePT(Map<Id, pse__Project_Task__c> newMap){
        Map<String, Object> mapInputParams = new Map<String, Object>{
            'projectTaskIdsOffsetDate' => (Set<Id>) newMap.keySet()
        };
        List<NSP_ProjectTaskQueueEvent__e> lstTaskQueueEvent = new List<NSP_ProjectTaskQueueEvent__e>();
        lstTaskQueueEvent.add(new NSP_ProjectTaskQueueEvent__e(NSP_Input_Parameters__c = JSON.serialize(mapInputParams), NSP_MethodName__c = 'setStartDateAndEndDateOnProjectTaskQTP', NSP_UserId__c = UserInfo.getUserId()));
        List<Database.SaveResult> saveResults = EventBus.publish(lstTaskQueueEvent);
    }

    /**
    * @description : Update Start Date and End date on Project Task using Offset date and # number of days offset.
    * USE THIS METHOD IF YOU ADD MORE VALUES TO OFFSET DATE.
    * Start and End date fields ON PROJECT TASKS are updated by manage package and its overwritting the value.
    To overcome this issue the method is called in AFTER INSERT transcation.
    * @param projectTaskSet Id of project.
    * @return void
    */

    public static void setStartDateAndEndDateOnProjectTaskQTP(Set<Id> projectTaskSet){
        Set<Id> setOfProjectId                         = new Set<Id>();
        Map<Id, Date> mapOfProjectIdAndAccountRenewal  = new Map<Id, Date>();

        try{
            //iterate over project task to store project id
            List<String> projTaskFields = new List<String>{'Id','Name','NSP_Template_Generated__c','pse__Project__c','pse__Start_Date_Time__c',
                'pse__End_Date_Time__c', 'RecordTypeId', 'NSP_of_Days_Offset__c', 'NSP_Offset_Date__c'};
            String query = new NSP_QueryBuilder(NSP_ServiceConstants.PROJECT_TASK_SOBJECT_TYPE, projTaskFields)
                    .addFilter('Id', new List<Id>(projectTaskSet), NSP_QueryBuilder.Operator.INCLUDES)
                    .build();

            List<pse__Project_Task__c> projectTaskList = (List<pse__Project_Task__c>)Database.query(query);
            for(pse__Project_Task__c projectTask : projectTaskList){
                if(projectTask.pse__Project__c != null && projectTask.NSP_Template_Generated__c){
                    setOfProjectId.add(projectTask.pse__Project__c);
                }
            }

            if(!setOfProjectId.isEmpty()){
                for(pse__Proj__c project : [SELECT  Id, TemplateName__c,pse__Project_Type__c, RecordTypeId, pse__Account__r.NSP_AIMS_Renewal_Date__c, pse__Start_Date__c, pse__End_Date__c
                                            FROM pse__Proj__c
                                            WHERE ID IN : setOfProjectId and pse__Is_Template__c = false]){
                                                if(!mapOfProjectIdAndAccountRenewal.containsKey(project.id)){
                                                    mapOfProjectIdAndAccountRenewal.put(project.id,project.pse__Account__r.NSP_AIMS_Renewal_Date__c);
                                                }
                                            }
            }
            //update start & end time of project task of rec type PEO & not of type implementation and template MM or FSO
            if(!mapOfProjectIdAndAccountRenewal.isEmpty()){

                if(!setOfProjectId.isEmpty()){
                    Integer daysBetweenStartAndEndDate;
                    for(pse__Project_Task__c projectTasks : projectTaskList){
                        if ( ( projectTasks.RecordTypeId == NSP_ProjectTasksTriggerHelper.peoProjectTaskRecordTypeId )
                            && ( projectTasks.pse__Start_Date_Time__c != null )
                            && ( projectTasks.pse__End_Date_Time__c != null )
                            )
                        {
                            daysBetweenStartAndEndDate = Date.valueOf(projectTasks.pse__Start_Date_Time__c).daysBetween(Date.valueOf(projectTasks.pse__End_Date_Time__c));
                        }

                        if(projectTasks.NSP_Offset_Date__c != null && projectTasks.NSP_Offset_Date__c == NSP_ServiceConstants.ASSET_OFFSET_DATE){
                            Integer offsetDays = (projectTasks.NSP_of_Days_Offset__c != null) ? Integer.valueOf(projectTasks.NSP_of_Days_Offset__c) : 0;
                            if(mapOfProjectIdAndAccountRenewal.get(projectTasks.pse__Project__c) != null){
                                Date newdate = mapOfProjectIdAndAccountRenewal.get(projectTasks.pse__Project__c).addDays(offsetDays);
                                projectTasks.pse__Start_Date_Time__c = DateTime.newInstance(newdate, Time.newInstance(12, 0, 0, 0));
                                if(daysBetweenStartAndEndDate != null){
                                    projectTasks.pse__End_Date_Time__c = DateTime.newInstance(newdate.addDays(daysBetweenStartAndEndDate+2), Time.newInstance(12, 0, 0, 0)) ;
                                }
                            }
                        }
                    }
                }
                if(!projectTaskList.isEmpty()){
                    Database.Update(projectTaskList, false);
                }
            }
        } catch ( Exception e ) {
            NSP_ProjectTasksTriggerHelper.handleException(
                e ,
                'setStartDateAndEndDateOnProjectTaskQTP'
            );
        }
    }

    /**
    * This will update Parent Project Status to Cancelled if Reinstatement Requested Task is marked as Complete
    * @param projectTaskList List of project Task.
    * @param oldMap Map of Project Id and Project
    * @return void
    */

    public void cancelParentProjectIfProjectTaskIsCompletedonReinstatementRequestedTask(List<pse__Project_Task__c> projectTaskList, Map<Id, pse__Project_Task__c> oldMap){
        Set<Id> setOfProjectId                 = new Set<Id> ();
        Set<Id> setOfParentProject             = new Set<Id> ();
        List<pse__Proj__c> listOfParentProject = new List<pse__Proj__c> ();

        for(pse__Project_Task__c pTask : projectTaskList){
            if(pTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED &&
            pTask.pse__Status__c != oldMap.get(pTask.id).pse__Status__c &&
            pTask.Name == NSP_ServiceConstants.REINSTATEMENT_REQUESTED_TASK){
                setOfProjectId.add(pTask.pse__Project__c);
            }
        }

        if(!setOfProjectId.isEmpty()){
            for(pse__Proj__c project : [SELECT pse__Parent_Project__c FROM pse__Proj__c WHERE ID IN : setOfProjectId]){
                if(project.pse__Parent_Project__c != null){
                    setOfParentProject.add(project.pse__Parent_Project__c);
                }
            }

            for(pse__Proj__c parentProj : [SELECT pse__Project_Status__c, NSP_Cancelled_Reason__c FROM pse__Proj__c WHERE ID IN : setOfParentProject]){
                parentProj.pse__Project_Status__c = NSP_ServiceConstants.PROJECTSTATUSCANCELLED;
                parentProj.NSP_Cancelled_Reason__c = NSP_ServiceConstants.CANCELLED_REASON;
                listOfParentProject.add(parentProj);
            }

            if(!listOfParentProject.isEmpty()){
                Database.update(listOfParentProject, false);
            }
        }
    }


    /**
    * Update Template Name field on Project Task and Templates Used field on Project
    * @param projectTaskList List of project.
    * @return void
    */

    public void updateTemplateNameOnProjectTaskAndTemplatesUsedOnProject(List<pse__Project_Task__c> projectTaskList){
        Set<Id> setOfProjectId = new Set<Id>();
        Map<Id, pse__Proj__c> mapOfProjectTaskIdAndProject = new Map<Id, pse__Proj__c>();

        for(pse__Project_Task__c projectTask : projectTaskList){
            if(projectTask.pse__Project__c != null){
                setOfProjectId.add(projectTask.pse__Project__c);
            }
        }

        for(pse__Proj__c project : [SELECT TemplateName__c, pse__Is_Template__c FROM pse__Proj__c WHERE ID IN : setOfProjectId]){
            if(!mapOfProjectTaskIdAndProject.containsKey(project.id)){
                mapOfProjectTaskIdAndProject.put(project.id, project);
            }
        }

        for(pse__Project_Task__c projectTask : projectTaskList){
            if(projectTask.pse__Project__c != null &&
                mapOfProjectTaskIdAndProject.get(projectTask.pse__Project__c).pse__Is_Template__c){
            projectTask.Template_Name__c = mapOfProjectTaskIdAndProject.get(projectTask.pse__Project__c).TemplateName__c;
            }
        }
    }

    /***********************************************************************************************
    * MethodName: assignQueueTasks
    * Description : This Method will update Queue as the Owner of MM and FSO projects
    * Params:      List<pse__Project_Task__c> projectTaskList
    * Author :Nischay
    * ********************************************************************************************/
    public static void assignQueueTasks(List<pse__Project_Task__c> projectTaskList){
        try{
            Set<Id>projectIdSet = new set<Id>();
            // storing PEO Project recordtype
            Id peoProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , 'PEO_Project' );
            Set<String> MMCoreQueueSet = new  Set<String>{NSP_ServiceConstants.IPIC, NSP_ServiceConstants.HWProducts};
            // searching for Queue's
            List<Group> MMCoreQueues= [Select Id ,Name,DeveloperNAME from Group WHERE Type=:NSP_ServiceConstants.GroupType AND DeveloperNAME IN:MMCoreQueueSet];
            Id IPICQueueId;
            Id HWQueueId;
            for(Group mmcoreQueue:MMCoreQueues){
                if(mmcoreQueue.DeveloperName==NSP_ServiceConstants.IPIC){
                    IPICQueueId=mmcoreQueue.Id;
                }else if(mmcoreQueue.DeveloperName==NSP_ServiceConstants.HWProducts){
                    HWQueueId=mmcoreQueue.Id;
                }
            }
            // store Project Task project Id in set
            for(pse__Project_Task__c prjTask:projectTaskList){
                projectIdSet.add(prjTask.pse__Project__c);
            }
            // Searching for MM and FSO Projects
            Map<Id,pse__Proj__c> projectMap= new Map<Id,pse__Proj__c>([Select Id,OwnerId, TemplateName__c, pse__End_Date__c from pse__Proj__c WHERE Id IN:projectIdSet
                                                                        AND pse__Project_Type__c=:NSP_ServiceConstants.ImplementationProjectType AND
                                                                        (TemplateName__c = :label.Middle_Market_Implementation_Project OR TemplateName__c=  :label.FSOImplementationProject) AND recordTypeId=:peoProjectRecordTypeId   ]);
            // Assign Queue as the Owner of  Project tasks
            for(pse__Project_Task__c prjTask:projectTaskList){
                if(projectMap.containsKey(prjTask.pse__Project__c) && !MMCoreQueues.isEmpty()){
                    if( prjTask.Name==NSP_ServiceConstants.PayCodeClientTask
                        || prjTask.Name==NSP_ServiceConstants.ClientPackingTask || prjTask.Name==NSP_ServiceConstants.EnrollmentTask){
                            prjTask.OwnerId=IPICQueueId;
                        } else if(prjTask.Name==NSP_ServiceConstants.CONFIGURATION){
                        prjTask.OwnerId=projectMap.get(prjTask.pse__Project__c).OwnerId;


                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ProjectTasksTriggerHelper.handleException(
                e ,
                'assignQueueTasks'
            );
        }
    }

    /***********************************************************************************************
    * MethodName: updateEmailsTransitionToService
    * Description : Update ListToemails from Account Teams members emails
    * Story : STY-00711
    * Params: List<pse__Project_Task__c> newList
    * Params: Map<Id,pse__Project_Task__c> oldProjectTaskMap
    * ********************************************************************************************/
    public static void updateEmailsTransitionToService(List<pse__Project_Task__c> newList , Map<Id,pse__Project_Task__c> oldProjectTaskMap){
        try{
            set<Id> setAccountIds = new set<Id>();
            List<NSP_Account_Team__c> lstAccTeams = new List<NSP_Account_Team__c>();
            Map<String,set<String>> mapAccTeamEmails = new Map<String,set<String>>();
            Map<String,NSP_Account_Team__c> mapAccTeamCLHR = new Map<String,NSP_Account_Team__c>();
            for(pse__Project_Task__c project : newList){
                if((oldProjectTaskMap == null && project.NSP_AccountId__c!=null) ||  (oldProjectTaskMap != null && project.NSP_AccountId__c !=null && oldProjectTaskMap.get(project.id).NSP_AccountId__c!=project.NSP_AccountId__c )){
                    setAccountIds.add(project.NSP_AccountId__c);
                }
            }
            if(!setAccountIds.isEmpty()){
                lstAccTeams =  getAccountTeamRecords(setAccountIds);
                mapAccTeamEmails = getCCAccountTeams(lstAccTeams);
                mapAccTeamCLHR = getAccountTeams(lstAccTeams);
            }
            for(pse__Project_Task__c proj : newList){
                if(mapAccTeamEmails.containsKey(proj.NSP_AccountId__c) && mapAccTeamEmails.get(proj.NSP_AccountId__c)!=null){
                    List<String> ccEmails = new List<String>();
                    ccEmails.addAll(mapAccTeamEmails.get(proj.NSP_AccountId__c));
                    proj.NSP_CC_Emails__c = String.join(ccEmails, ',');
                }
                if(mapAccTeamCLHR.containsKey(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)){
                    proj.NSP_Client_Liaison_Name__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_First_Name__c +' '+mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_Last_Name__c;
                    proj.NSP_Client_Liaison_Email__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_Email__c;
                    proj.NSP_HR_Specialist_Name__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_First_Name__c +' '+mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_Last_Name__c;
                    proj.NSP_HR_Specialist_Email__c =  mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_Email__c;
                }else if(mapAccTeamCLHR.containsKey(NSP_ServiceConstants.CLIENT_LIAISION) || mapAccTeamCLHR.containsKey(NSP_ServiceConstants.HRSpecialist)){
                    proj.NSP_Client_Liaison_Name__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.CLIENT_LIAISION)?.NSP_First_Name__c +' '+mapAccTeamCLHR?.get(NSP_ServiceConstants.CLIENT_LIAISION)?.NSP_Last_Name__c;
                    proj.NSP_Client_Liaison_Email__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.CLIENT_LIAISION)?.NSP_Email__c;
                    proj.NSP_HR_Specialist_Name__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.HRSpecialist)?.NSP_First_Name__c +' '+mapAccTeamCLHR?.get(NSP_ServiceConstants.HRSpecialist)?.NSP_Last_Name__c;
                    proj.NSP_HR_Specialist_Email__c =  mapAccTeamCLHR?.get(NSP_ServiceConstants.HRSpecialist)?.NSP_Email__c;
                }
            }
        } catch ( Exception e ) {
            NSP_ProjectTasksTriggerHelper.handleException(
                e ,
                'updateEmailsTransitionToService'
            );
        }
    }

    private static Map<String,set<String>> getCCAccountTeams(List<NSP_Account_Team__c> accTeamRecords){
        Map<String,set<String>> mapAccTeamEmails = new Map<String,set<String>>();
        for(NSP_Account_Team__c accTeam: accTeamRecords){
            if(mapAccTeamEmails.containsKey(accTeam.NSP_Account__c)){
                mapAccTeamEmails.get(accTeam.NSP_Account__c).add(accTeam.NSP_Email__c);
            }else{
                mapAccTeamEmails.put(accTeam.NSP_Account__c,new set<String>{accTeam.NSP_Email__c});
            }
        }
        return mapAccTeamEmails;
    }

    private static Map<String,NSP_Account_Team__c> getAccountTeams(List<NSP_Account_Team__c> accTeamRecords){
        Map<String,NSP_Account_Team__c> mapAccTeamCLHR = new Map<String,NSP_Account_Team__c>();
        for(NSP_Account_Team__c accTeam: accTeamRecords){
            if(accTeam.NSP_Role__c == NSP_ServiceConstants.BUS_TEAM_HRSP_CL){
                mapAccTeamCLHR.put(NSP_ServiceConstants.BUS_TEAM_HRSP_CL, accTeam);
            }
            if(accTeam.NSP_Role__c == NSP_ServiceConstants.CLIENT_LIAISION){
                mapAccTeamCLHR.put(NSP_ServiceConstants.CLIENT_LIAISION, accTeam);
            }
            if(accTeam.NSP_Role__c == NSP_ServiceConstants.HRSpecialist){
                mapAccTeamCLHR.put(NSP_ServiceConstants.HRSpecialist, accTeam);
            }
        }
        return mapAccTeamCLHR;
    }

    private static List<NSP_Account_Team__c> getAccountTeamRecords(Set<Id> setAccountIds){
        List<String> lstAccTeamRoles = new List<String>{NSP_ServiceConstants.MANAGER_HRSERVICES,NSP_ServiceConstants.PAYROLL_SUPERVISOR,
            NSP_ServiceConstants.CLIENT_LIAISION,NSP_ServiceConstants.HRSpecialist,NSP_ServiceConstants.PayrollSpecialist,
            NSP_ServiceConstants.PERFOMANCE_SPECIALIST,NSP_ServiceConstants.SAFETY_CONSULTANT,NSP_ServiceConstants.BUS_TEAM_HRSP_CL,
            NSP_ServiceConstants.MID_MARKET_ACC_EX,NSP_ServiceConstants.NATIONAL_ACC_EX};
                return [SELECT Id,NSP_Email__c,NSP_Account__c,NSP_First_Name__c,NSP_Last_Name__c,NSP_Role__c FROM NSP_Account_Team__c
                        WHERE NSP_Account__c IN:setAccountIds AND NSP_Role__c IN:lstAccTeamRoles];
    }

    public static void checkStatusComplete( Map<Id,pse__Project_Task__c> newMap , Map<Id,pse__Project_Task__c> oldMap ) {
        try {
            if ( ( newMap != null ) && ( oldMap != null ) ) {
                for ( pse__Project_Task__c projTask : newMap.values() ) {
                    // update the flag when first time the NSP_Is_Status_Completed__c is set to Complete
                    if ( ( projTask.pse__Status__c != null )
                        && oldMap.containsKey( projTask.Id )
                        && ( oldMap.get( projTask.Id ).pse__Status__c != NSP_ServiceConstants.PROJECTSTATUSCOMPLETED )
                        && ( projTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED )
                        && !oldMap.get( projTask.Id ).NSP_Is_Status_Completed__c
                        )
                    {
                        projTask.NSP_Is_Status_Completed__c = true;
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ProjectTasksTriggerHelper.handleException(
                e ,
                'beforeUpdate'
            );
        }
    }

    //
    // MethodName: sendEmailToProjectResource
    // Description : Method to send an email to proj resource when higher peer order proj task is completed.
    // Params: List<pse__Project_Task__c> newProjectTaskList, Map<Id, pse__Project_Task__c> projectTaskOldMap
    // Story : STY-02213
    //
    public static void sendEmailToProjectResource( Set<Id> projectTaskIdSet ) {
        if ( ( projectTaskIdSet != null )
            && !projectTaskIdSet.isEmpty()
            && EmailDeliverabilityController.IsEnabledOutbound
            )
        {
            if ( NSP_ProjectTasksTriggerHelper.isEnabledFutureNotifications
                && ( Limits.getFutureCalls() < Limits.getLimitFutureCalls() )
                )
            {
                NSP_ProjectTasksTriggerHelper.sendEmailToProjectResourceFuture( projectTaskIdSet );
            } else {
                NSP_ProjectTasksTriggerHelper.sendEmailToProjectResourceStatic( projectTaskIdSet );
            }
        }
    }

    @future
    private static void sendEmailToProjectResourceFuture( Set<Id> projectTaskIdSet ) {
        NSP_ProjectTasksTriggerHelper.sendEmailToProjectResourceStatic( projectTaskIdSet );
    }

    private static void sendEmailToProjectResourceStatic( Set<Id> projectTaskIdSet ) {
        //A list to store all RET Templates
        List<String> retTemplateNames = System.Label.NSP_RET_Project_Templates.split(',');
        //Map of project and current project task
        Map<Id, pse__Project_Task__c> mapOfProjAndProjTask = new Map<Id, pse__Project_Task__c>();
        //Map of Project and the resource email address
        Map<Id, Map<String, String>> mapOfProjAndResourceEmail = new Map<Id, Map<String, String>>();

        try{
            for(pse__Project_Task__c projTask: [SELECT Id, Name, pse__Order__c, Task_Order__c, pse__Status__c, pse__Project__r.TemplateName__c, Responsible_Party__c
                                                FROM pse__Project_Task__c WHERE Id IN: projectTaskIdSet AND pse__Project__r.TemplateName__c IN :retTemplateNames]){

                                                                mapOfProjAndProjTask.put(projTask.pse__Project__c, projTask);

            }

            List<String> projTaskFields = new List<String>{'Id', 'Name', 'pse__Project__c', 'pse__Order__c','Task_Order__c', 'Responsible_Party__c'};

                //Get a list of all the project task associated with the parent project
            String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                                .addFilter('pse__Project__c',  new List<Id>(mapOfProjAndProjTask.keySet()), NSP_QueryBuilder.Operator.INCLUDES).build();
            List<pse__Project_Task__c> listOfAllPrjTaskForAProject = (List<pse__Project_Task__c>) Database.query(query);

            for(pse__Resource_Request__c resourceRequest: [SELECT Id, pse__Resource_Role__c, pse__Staffer_Resource__r.pse__Salesforce_User__r.Email, pse__Project__c
                                                            FROM pse__Resource_Request__c
                                                            WHERE pse__Project__c IN: mapOfProjAndProjTask.keySet()]){
                                                                if(!mapOfProjAndResourceEmail.containsKey(resourceRequest.pse__Project__c)){
                                                                    mapOfProjAndResourceEmail.put(resourceRequest.pse__Project__c, new Map<String,String>());
                                                                }
                                                                mapOfProjAndResourceEmail.get(resourceRequest.pse__Project__c).put(resourceRequest.pse__Resource_Role__c, resourceRequest.pse__Staffer_Resource__r.pse__Salesforce_User__r.Email);
                                                            }

            //If the next in line projTask Responsibe party is diff send an email to the proj resource who's resource role matches with the next in line projTask's Responsibe party
            if(!listOfAllPrjTaskForAProject.isEmpty() && !mapOfProjAndResourceEmail.isEmpty()){
                for(pse__Project_Task__c projTask : listOfAllPrjTaskForAProject){
                    if(projTask.pse__Order__c == mapOfProjAndProjTask.get(projTask.pse__Project__c).pse__Order__c+1 &&
                        projTask.Task_Order__c == mapOfProjAndProjTask.get(projTask.pse__Project__c).Task_Order__c+1 &&
                        projTask.Responsible_Party__c != mapOfProjAndProjTask.get(projTask.pse__Project__c).Responsible_Party__c &&
                        mapOfProjAndResourceEmail.containsKey(projTask.pse__Project__c) &&
                        mapOfProjAndResourceEmail.get(projTask.pse__Project__c).containsKey(projTask.Responsible_Party__c)){
                            sendEmailNotificationToResource(mapOfProjAndProjTask.get(projTask.pse__Project__c).Name, mapOfProjAndResourceEmail.get(projTask.pse__Project__c).get(projTask.Responsible_Party__c), projTask.Id);
                        }
                }
            }
        } catch ( Exception e ) {
            NSP_ProjectTasksTriggerHelper.handleException(
                e ,
                'sendEmailToProjectResource'
            );
        }
    }

    /***********************************************************************************************
    * MethodName: sendEmailNotificationToResource
    * Description : Helper method for sendEmailToProjectResource
    * Params: String nextInLineProjTask, String completedProjTask, String sendToUserAddress, Id projTaskId
    * Story : STY-02213
    * ********************************************************************************************/

    private static void sendEmailNotificationToResource(String completedProjTask, String sendToUserAddress, Id projTaskId){
        //list to store to email address
        List<String> toEmailAddress = new List<String>();
        toEmailAddress.add(sendToUserAddress);
        List<String> emailTempFields = new List<String>{'ID'};
        //Get email template
        EmailTemplate emailTemplate = NSP_sObjectSelector.selectByDeveloperName(emailTempFields, 'NSP_Send_email_to_resource');
        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(emailTemplate.Id, NULL, projTaskId);
        email.setTemplateId(emailTemplate.Id);
        email.setToAddresses(toEmailAddress);
        //replace '$resource$' in the email template body with the completed project task name
        String emailBody = email.getHtmlBody().replace('$resource$', completedProjTask);
        email.setHtmlBody(emailBody);
        email.setSaveAsActivity(false);
        NSP_ProjectTasksTriggerHelper.sendSingleEmailMessage( email );
    }

    private static void sendSingleEmailMessage( Messaging.SingleEmailMessage message ) {
        if ( message != null ) {
            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
            messages.add( message );
            NSP_ProjectTasksTriggerHelper.sendSingleEmailMessages( messages );
        }
    }

    private static void sendSingleEmailMessages( List<Messaging.SingleEmailMessage> messages ) {
        if ( EmailDeliverabilityController.IsEnabledOutbound
            && ( messages != null )
            && !messages.isEmpty()
            )
        {
            try {
                Messaging.sendEmail( messages );
            } catch ( Exception e ) {
                NSP_ProjectTasksTriggerHelper.handleException(
                    e ,
                    'sendSingleEmailMessages'
                );
            }
        }
    }

    private static void handleException( Exception e , String methodName ) {
        if ( e != null ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTasksTriggerHelper.class.getName() ,
                methodName ,
                e
            );
        }
    }

    /***********************************************************************************************
    * MethodName: beforeUpdateDirector
    * Description : before update director mehtod
    * Params: List<pse__Project_Task__c> newProjectTasks
    * Params:  Map<Id, pse__Project_Task__c> oldProjectTaskMap
    * ********************************************************************************************/
    public void beforeUpdateDirector(List<pse__Project_Task__c> newProjectTasks, Map<Id, pse__Project_Task__c> oldProjectTaskMap){
        // Get filtered data on the basis of different conditions
        Map<String, Object> filteredData = getBeforeUpdateFilteredData(newProjectTasks, oldProjectTaskMap);

        // Perform before update operations if required data is present
        doBeforeUpdateActions(filteredData);
    }

    /***********************************************************************************************
    * MethodName: getBeforeUpdateFilteredData
    * Description : filter before update Records
    * Params: List<pse__Project_Task__c> newProjectTasks
    * Params:  Map<Id, pse__Project_Task__c> oldProjectTaskMap
    * ********************************************************************************************/
    private Map<String, Object> getBeforeUpdateFilteredData(List<pse__Project_Task__c> newProjectTasks, Map<Id, pse__Project_Task__c> oldProjectTaskMap){
        Map<String, Object> dataMap = new Map<String, Object>();
        try{
            List<pse__Project_Task__c> scheduledProjectTasks = new List<pse__Project_Task__c>();
            Set<Id> scheduledProjectTaskOwnerIds = new Set<Id>();
            Set<Id> projectTaskId = new Set<Id>();

            for (pse__Project_Task__c projectTask : newProjectTasks) {
                pse__Project_Task__c priorProjectTask = oldProjectTaskMap.get(projectTask.Id);
                //STY-03891
                // When Status field on project task is changed to "Scheduled"
                if(isStatusChangedToScheduled(projectTask, priorProjectTask)){
                    scheduledProjectTasks.add(projectTask);
                    scheduledProjectTaskOwnerIds.add(projectTask.OwnerId);
                    projectTaskId.add(projectTask.Id);
                }
                //STY-03891
                // When Create Work Order is checked and Dispatch Region populated
                if( projectTask.NSP_Create_Work_Order__c != priorProjectTask.NSP_Create_Work_Order__c && String.isNotBlank(projectTask.NSP_Dispatch_Region__c)){
                    projectTask.pse__Status__c = 'Unscheduled';
                }



                // added as part of story STY-04172
                if ( ( projectTask.NSP_Create_Work_Order__c != null )
                    && String.isNotBlank( projectTask.NSP_Dispatch_Region__c )
                    && ( projectTask.pse__Start_Date_Time__c != null )
                    )
                {
                    if ( ( projectTask.pse__End_Date_Time__c == null )
                        || ( projectTask.pse__Start_Date_Time__c == projectTask.pse__End_Date_Time__c )
                        )
                    {
                        projectTask.pse__End_Date_Time__c = projectTask.pse__Start_Date_Time__c.addHours( 1 );
                    }
                }
            }
            // Populate all the filtered data in the map
            dataMap.put( 'scheduledProjectTasks' , scheduledProjectTasks );
            dataMap.put( 'scheduledProjectTaskOwnerIds' , scheduledProjectTaskOwnerIds );
            dataMap.put( 'projectTaskIds' , projectTaskId );
        } catch ( Exception e ) {
            NSP_ProjectTasksTriggerHelper.handleException(
                e ,
                'getBeforeUpdateFilteredData'
            );
        }
        return dataMap;
    }

        /***********************************************************************************************
    * MethodName: doBeforeUpdateActions
    * Description : before Update Actions
    * Params: Map<String, Object> filteredDataMap
    * ********************************************************************************************/
    private void doBeforeUpdateActions(Map<String, Object> filteredDataMap){
        List<pse__Project_Task__c> scheduledProjectTasks = (List<pse__Project_Task__c>) filteredDataMap.get('scheduledProjectTasks');
        Set<Id> scheduledProjectTaskOwnerIds = (Set<Id>) filteredDataMap.get('scheduledProjectTaskOwnerIds');
        Set<Id> projectTaskId = (Set<Id>) filteredDataMap.get('projectTaskIds');

        // STY-03891
        // Check filtered list & call respective method if there is any record available
        if(projectTaskId != null && !scheduledProjectTasks.isEmpty()){
            assignResourceToServiceAppointment(scheduledProjectTasks, scheduledProjectTaskOwnerIds , projectTaskId);
        }

    }

        /***********************************************************************************************
    * MethodName: assignResourceToServiceAppointment
    * Description : assuign Resource to SA before Scheduling
    * Params: List<pse__Project_Task__c> projectTasks
    * Params: Set<Id> ownerIds
    * Params: Set<Id> projectTaskId
    * STY-03891
    * ********************************************************************************************/
    private void assignResourceToServiceAppointment(List<pse__Project_Task__c> projectTasks, Set<Id> ownerIds, Set<Id> projectTaskId ){
        Map<Id,Id> mapUserIdsToServiceResource = new Map<Id,Id>();
        Map<Id,WorkOrder> mapPtIDToWo = new Map<Id,WorkOrder>();
        Map<Id,pse__Project_Task__c> mapWoIdToPt = new Map<Id,pse__Project_Task__c>();
        List<WorkOrder> woListToUpdate = new List<WorkOrder>();

        for(ServiceResource serviceResource : [SELECT Id, RelatedRecordId FROM ServiceResource WHERE RelatedRecordId IN :ownerIds]){
            mapUserIdsToServiceResource.put( serviceResource.RelatedRecordId , serviceResource.Id );
        }

        for( WorkOrder eachWo : [SELECT Id,Status,NSP_Project_Task__c,OwnerId,StartDate FROM WorkOrder WHERE NSP_Project_Task__c IN: projectTaskId]){
            mapPtIDToWo.put( eachWo.NSP_Project_Task__c , eachWo);
        }

        for (pse__Project_Task__c projectTask : projectTasks) {

            //check if Owner is not valid Service Resource
            if( mapUserIdsToServiceResource.get(projectTask.OwnerId) == null ){
                projectTask.pse__Status__c.addError(System.Label.NSP_Owner_Not_Valid_Resource);
            }
            //Check if related WO is not there
            else if( mapPtIDToWo.get( projectTask.ID ) == null ){
                projectTask.pse__Status__c.addError(System.Label.NSP_ProjectTask_Unschedule_Validation);
            }
            //check if Start and end date is not populated
            else if( projectTask.pse__Start_Date_Time__c == null || projectTask.pse__End_Date_Time__c == null ){
                projectTask.pse__Status__c.addError(System.Label.NSP_PorjectTask_Date_Validation);
            }
            //add Wo to list to update
            else{
                woListToUpdate.add( mapPtIDToWo.get(projectTask.Id ));
                mapWoIdToPt.put( mapPtIDToWo.get(projectTask.Id ).Id , projectTask );
            }
        }
        //check if woListToUpdate is not empty
        if ( !woListToUpdate.isEmpty()
            && !System.isQueueable()
            && !System.isFuture()
            )
        {
            NSP_ProjectTasksTriggerHelper.scheduleWorkOrderAndSA(
                woListToUpdate ,
                mapWoIdToPt ,
                mapUserIdsToServiceResource
            );
        }
    }

    //
    // MethodName: scheduleWorkOrderAndSA
    // Description : Schedule WO and SA when Project task status is changed to Scheduled
    // Params: List<WorkOrder> woListToUpdate
    // Params: Map<Id,pse__Project_Task__c> mapWoIdToPt
    // Params: Map<Id,Id> mapUserIdsToServiceResource
    // STY-03891
    //
    private static void scheduleWorkOrderAndSA(
        List<WorkOrder> woListToUpdate ,
        Map<Id,pse__Project_Task__c> mapWoIdToPt ,
        Map<Id,Id> mapUserIdsToServiceResource
        )
    {
        List<ServiceAppointment> saListToUpdate = new List<ServiceAppointment>();
        List<AssignedResource> assgnResToCreate = new List<AssignedResource>();
        List<sObject> recordsToUpdate = new List<sObject>();
        //update WorkOrder Status and Sync other fields
        for ( WorkOrder eachWo : woListToUpdate ) {
            eachWo.StartDate = mapWoIdToPt.get( eachWo.Id ).pse__Start_Date_Time__c;
            eachWo.EndDate = mapWoIdToPt.get( eachWo.Id ).pse__End_Date_Time__c;
            eachWo.Status = 'Scheduled';
        }
        //update Service Appointment and sync other fields
        for ( ServiceAppointment eachSa : [
                    SELECT
                        Id ,
                        Status ,
                        SchedStartTime ,
                        SchedEndTime ,
                        OwnerId ,
                        ParentRecordId
                    FROM ServiceAppointment
                    WHERE ( ParentRecordId IN :mapWoIdToPt.keySet() )
                ]
            )
        {
            eachSa.SchedStartTime = mapWoIdToPt.get( eachSa.ParentRecordId ).pse__Start_Date_Time__c;
            eachSa.SchedEndTime = mapWoIdToPt.get( eachSa.ParentRecordId ).pse__End_Date_Time__c;
            eachSa.Status = 'Scheduled';
            saListToUpdate.add( eachSa );
            //Create new Assigned Resource Rec
            AssignedResource newAssgnRes = new AssignedResource();
            newAssgnRes.ServiceResourceId = mapUserIdsToServiceResource.get( mapWoIdToPt.get( eachSa.ParentRecordId ).OwnerId );
            newAssgnRes.ServiceAppointmentId = eachSa.Id;
            assgnResToCreate.add( newAssgnRes );
        }
        //update WO And SA
        recordsToUpdate.addAll( woListToUpdate );
        recordsToUpdate.addAll( saListToUpdate );
        List<Database.SaveResult> results1 = Database.update( recordsToUpdate , false );
        NSP_ErrorLogHandler.logResults(
            NSP_ProjectTasksTriggerHelper.class.getName() ,
            'scheduleWorkOrderAndSA:update' ,
            results1
        );
        //insert Assigned Resource
        List<Database.SaveResult> results3 = Database.insert( assgnResToCreate , false );
        NSP_ErrorLogHandler.logResults(
            NSP_ProjectTasksTriggerHelper.class.getName() ,
            'scheduleWorkOrderAndSA:insert' ,
            results3
        );
    }

    /***********************************************************************************************
    * MethodName: isStatusChangedToScheduled
    * Description : check if status changed to schedule
    * Params: pse__Project_Task__c projectTask
    * Params: pse__Project_Task__c priorProjectTask
    * ********************************************************************************************/
    private static Boolean isStatusChangedToScheduled(pse__Project_Task__c projectTask, pse__Project_Task__c priorProjectTask){
        return isValueChanged(projectTask, priorProjectTask, 'pse__Status__c') && projectTask.pse__Status__c == 'Scheduled' && (projectTask.NSP_Create_Work_Order__c && projectTask.NSP_Dispatch_Region__c != null);
    }
    /***********************************************************************************************
    * MethodName: isStatusChangedToScheduled
    * Description : check if status changed to schedule
    * Params: SObject newObj
    * Params: SObject oldObj
    * Params: String fieldName
    * ********************************************************************************************/
    private static Boolean isValueChanged(SObject newObj, SObject oldObj, String fieldName){
        return newObj != null && oldObj != null && String.isNotBlank(fieldName) ? newObj.get(fieldName) != oldObj.get(fieldName) : false;
    }

    //
    // MethodName: createPTAIfOwnerIsChanged
    // Description : if Project task owner is updated Check for PTA and Insert new PTA if doesnt exist
    // Params: projectTaskIds projectTask recordIds if Owner is Updated
    //
    public static void createPTAIfOwnerIsChanged( Set<Id> projectTaskIds ) {
        Id peoRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT_TASK_SOBJECT_TYPE,NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE);
        Id bpsRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT_TASK_SOBJECT_TYPE,NSP_ServiceConstants.PROJECT_TASK_BPS_RECORDTYPE);
        Map<Id,Id> projTaskIdWithOwnerIds = new Map<Id,Id>();
        Map<Id,Decimal> projTaskIdWithPTACount = new Map<Id,Decimal>();
        Map<Id,Id> userIdWithcontId = new Map<Id,Id>();
        Map<Id,List<Id>> projTaskWithResourceLst = new Map<Id,List<Id>>();
        List<pse__Project_Task_Assignment__c> newPTAList = new List<pse__Project_Task_Assignment__c> () ;
        try {
            if ( NSP_ProjectTasksTriggerHelper.isEnabledCreatePtaIfOwnerChanged ) {
                String projTaskQuery = new NSP_QueryBuilder('pse__Project_Task__c', new List<String>{'Id', 'OwnerId', 'pse__Number_of_Assignments__c','pse__Summary__c'})
                    .addFilter('Id', new List<Id>(projectTaskIds) , NSP_QueryBuilder.Operator.INCLUDES)
                    .addFilter('pse__Project__r.NSP_Auto_Resource_Project__c', true , NSP_QueryBuilder.Operator.EQUALS, false)
                    .addFilter('RecordTypeId', new List<Id>{ peoRecordTypeId, bpsRecordTypeId } , NSP_QueryBuilder.Operator.INCLUDES)
                    .addFilter('pse__Project__r.pse__Summary__c', false , NSP_QueryBuilder.Operator.EQUALS, false) // throws...  System.QueryException: No such column 'pse__Summary__c' on entity 'pse__Proj__c'.
                    .build();
                for(pse__Project_Task__c projTask : Database.query(projTaskQuery)) {
                    projTaskIdWithOwnerIds.put(projTask.Id, projTask.OwnerId);
                    projTaskIdWithPTACount.put(projTask.Id, projTask.pse__Number_of_Assignments__c);
                }
                if(!projTaskIdWithOwnerIds.isEmpty()) {
                    String contactQuery = new NSP_QueryBuilder('Contact', new List<String>{'Id', 'Name', 'pse__Salesforce_User__c'})
                        .addFilter('pse__Salesforce_User__c', projTaskIdWithOwnerIds.values() , NSP_QueryBuilder.Operator.INCLUDES)
                        .build();
                    for(Contact cont: Database.query(contactQuery)) {
                        userIdWithcontId.put(cont.pse__Salesforce_User__c, cont.Id);
                    }
                }
                String projTaskAssignmtQuery = NSP_ProjectTaskAssignmentTriggerHelper.getProjectTaskAssignQuery(projectTaskIds, peoRecordTypeId, bpsRecordTypeId);
                for(pse__Project_Task_Assignment__c projTaskAssign: Database.query(projTaskAssignmtQuery)) {
                    if(!projTaskWithResourceLst.containsKey(projTaskAssign.pse__Project_Task__c)) {
                        projTaskWithResourceLst.put(projTaskAssign.pse__Project_Task__c, new List<Id>{ projTaskAssign.pse__Resource__c });
                    }
                    projTaskWithResourceLst.get(projTaskAssign.pse__Project_Task__c).add(projTaskAssign.pse__Resource__c);
                }
                if(!projTaskWithResourceLst.isEmpty()) {
                    for(Id projTaskId : projTaskWithResourceLst.keySet()) {
                        Id contResourceId = userIdWithcontId?.get(projTaskIdWithOwnerIds?.get(projTaskId));
                        List<Id> lstResouceListOfProjTask = projTaskWithResourceLst?.get(projTaskId);
                        if(String.isNotBlank(contResourceId) && !lstResouceListOfProjTask.contains(contResourceId)){
                            newPTAList.add(new pse__Project_Task_Assignment__c(pse__Resource__c = contResourceId,pse__Project_Task__c = projTaskId));
                        }
                    }
                } else {
                    for(Id projId : projTaskIdWithPTACount.keySet()) {
                        Id contResourceId = userIdWithcontId?.get(projTaskIdWithOwnerIds?.get(projId));
                        if(projTaskIdWithPTACount.get(projId) == 0) {
                            newPTAList.add(new pse__Project_Task_Assignment__c(pse__Resource__c = contResourceId, pse__Project_Task__c = projId));
                        }
                    }
                }
                if ( !newPTAList.isEmpty() ) {
                    NSP_ProjectTaskAssignmentTriggerHelper.runAssignmentMethod = true;
                    Database.UpsertResult[] upsertResults = Database.upsert( newPTAList , false );
                    NSP_ErrorLogHandler.logResults(
                        NSP_ProjectTasksTriggerHelper.class.getName() ,
                        'createPTAIfOwnerIsChanged' ,
                        upsertResults
                    );
                }
            }
        } catch ( Exception e ) {
            NSP_ProjectTasksTriggerHelper.handleException(
                e ,
                'createPTAIfOwnerIsChanged'
            );
        }
    }

    /***********************************************************************************************
    * MethodName: handleBeforeDeleteOfProjTemp
    * Description : Helper method to check before deleting a project Task
    * Params:       List<pse__Project_Task__c> projTasks
    * Created as part of STY-04554
    * ********************************************************************************************/
    public void handleBeforeDeleteOfProjTemp(List<pse__Project_Task__c> projTasks) {

        try{
            List<String> userList = new List<String>{'Id','Name','NSP_Service_Stakeholder__c'};
            Map<Id, Boolean> projIdTempValMap = new Map<Id, Boolean>();
            String query = new NSP_QueryBuilder('User', userList)
                .addFilter('Id', UserInfo.getUserId())
                .addLimit(1)
                .setSecurityEnforce(false)
                .build();
            User userDetails = Database.query(query);

            if(!userDetails.Name.contains('Deployment') && !userDetails.NSP_Service_Stakeholder__c){
                for (pse__Project_Task__c task : [Select Id, pse__Project__c,pse__Project__r.pse__Is_Template__c
                                                    FROM pse__Project_Task__c
                                                    WHERE Id IN: projTasks]) {
                    if (task.pse__Project__r.pse__Is_Template__c ) {
                        projIdTempValMap.put(task.Id, task.pse__Project__r.pse__Is_Template__c);
                    }
                }
                for (pse__Project_Task__c task : projTasks) {
                    if (projIdTempValMap.containsKey(task.Id)) {
                        //After the custom label gets deployed please change the below line to
                        //task.addError(System.Label.NSP_ProjTemplateDeleteError);
                        task.addError('You do not have permission to delete project templates');
                    }
                }
            }
        } catch( Exception e ) {
            NSP_ProjectTasksTriggerHelper.handleException(
                e ,
                'handleBeforeDeleteOfProjTemp'
            );
        }
    }

    //
    // Custom Settings
    //

    private static ProjectTaskTriggerSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = ProjectTaskTriggerSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabledCreatePtaIfOwnerChanged {
        private get {
            if ( isEnabledCreatePtaIfOwnerChanged == null ) {
                Boolean local = False;
                if ( settings != null ) {
                    local = settings.IsEnabledCreatePtaIfOwnerChanged__c;
                }
                isEnabledCreatePtaIfOwnerChanged = local;
            }
            return isEnabledCreatePtaIfOwnerChanged;
        }
        private set;
    }

    private static Boolean isEnabledFutureNotifications {
        private get {
            if ( isEnabledFutureNotifications == null ) {
                Boolean local = False;
                if ( settings != null ) {
                    local = settings.IsEnabledFutureNotifications__c;
                }
                isEnabledFutureNotifications = local;
            }
            return isEnabledFutureNotifications;
        }
        private set;
    }

    private static Boolean isEnabledFuturePercentage {
        private get {
            if ( isEnabledFuturePercentage == null ) {
                Boolean local = False;
                if ( settings != null ) {
                    local = settings.IsEnabledFuturePercentage__c;
                }
                isEnabledFuturePercentage = local;
            }
            return isEnabledFuturePercentage;
        }
        private set;
    }

    private static Boolean isEnabledQueueablePercentage {
        private get {
            if ( isEnabledQueueablePercentage == null ) {
                Boolean local = False;
                if ( settings != null ) {
                    local = settings.IsEnabledQueueablePercentage__c;
                }
                isEnabledQueueablePercentage = local;
            }
            return isEnabledQueueablePercentage;
        }
        private set;
    }

    private static Boolean isUpdateDocusignAsset {
        private get {
            if ( isUpdateDocusignAsset == null ) {
                Boolean local = False;
                if ( settings != null ) {
                    local = settings.IsUpdateDocusignAsset__c;
                }
                isUpdateDocusignAsset = local;
            }
            return isUpdateDocusignAsset;
        }
        private set;
    }

}
//