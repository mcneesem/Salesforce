public with sharing class NSP_ProjectTriggerHelper {
    // test w/ NSP_ProjectTriggerHelperTest, NSP_AssetServiceTriggerHelperTest (82%)
    // test w/ NSP_ProjectTriggerHelperTest (81%)
    // test w/ NSP_AssetServiceTriggerHelperTest (29%)

    public static Set<Id> dupPreventionSet = new Set<Id>();
    public final String PROJECTTASKSTATUSCOMPLETE = 'Complete';
    public final String PROJECTTASKSTATUSCANCELLED = 'Canceled';
    public final String PROJECTSERVICEPLAN3 = 'Service_Plan_Level_3';
    public final String PROJECTSERVICEPLAN4 = 'Service_Plan_Level_4';
    public static final Id PEOPROJECTTECORDTYPEID = NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , 'PEO_Project' );
    public static final Id TESBPSPROJECTTECORDTYPEID = NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , 'TES_BPS' );
    public static final List<String> PROJECTTASKNAMES = label.NSP_Project_Task_Names.split(',');
    public static final String NEWPROJECTNAME = 'Post Implementation Payroll Follow Up';
    public static final String NEWPROJECTTYPE = 'Implementation';
    private static final String LAYOUTBOB_PEO_GENERIC = 'PEO Generic';
    public static final Id WORECORDTYPEID = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'WO' );
    public static final Id PEOBILLRECTYPEID = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT, NSP_ServiceConstants.PEO_BILL_RECORDTYPE);
    public static final Id casePEORecordTypeId = NSP_GenericRecordType.getRecordTypeId('Case', NSP_ServiceConstants.PEO);
    private static final Id itaCqaRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Case', NSP_ServiceConstants.NSP_ITA_CQA);
    private static final Id peoProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT, NSP_ServiceConstants.PROJECT_PEO_RECORDTYPE);
    private static final Id bpsProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT, NSP_ServiceConstants.PROJECT_BPS_RECORDTYPE);
    private static final String SERVICEPLANPROJECTTYPE = 'Service Plan';

    public NSP_FF_APIs implInstance = new NSP_FF_APIImpl();

    public NSP_ProjectTriggerHelper() {
        if ( Test.isRunningTest() ) {
            this.implInstance = new Nsp_FFApiMock();
        }
    }

    public void beforeInsertDirector( List<pse__Proj__c> newProjectsList ) {
        Set<Id> accIdSet = new Set<Id>();
        Map<Id, Account> projAccIdNameMap;
        //getting PEO Billable Project Record Id
        Id billableSerRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT, NSP_ServiceConstants.PEO_BILL_RECORDTYPE);
        List<pse__Proj__c> projectsList = new List<pse__Proj__c>();//<STY-04002>
        List<ID> projAccountIDs = new List<ID>(); //<STY-04002>
        List<pse__Proj__c> projectNameList = new List<pse__Proj__c>();
        List<pse__Proj__c> servicePlanProjectsList = new List<pse__Proj__c>();
        Set<Id> servicePlanAccountIDs = new Set<Id>();

        for(pse__Proj__c project : newProjectsList){
            if(String.isNotBlank(project.pse__Account__c)){
                accIdSet.add(project.pse__Account__c);
            }
            //update start date as today
            project = setProjectStartAndEndDates(
                project ,
                PEOPROJECTTECORDTYPEID ,
                NSP_ServiceConstants.WO_WX_TEMPLATE ,
                System.today().addDays(30)
            );
            project = setProjectStartAndEndDates(
                project ,
                TESBPSPROJECTTECORDTYPEID ,
                NSP_ServiceConstants.ITA_IMPLEMENTATION ,
                System.today().addmonths(12)
            );

              //<STY-04002> if loop to check if RT is PEO Project Billable
            if(!project.pse__Is_Template__c && project.recordTypeID == billableSerRecordTypeId){
                if(project.pse__Account__c!= null){
                    projAccountIDs.add(project.pse__Account__c);
                }
                projectsList.add(project);
            }

            // Added this condition as part of STY-02092
            if(project.Name != NEWPROJECTNAME){
                projectNameList.add(project);
            }

             //Added this condition as part of STY-04589 to populate owner based on account segment type
            if(project.pse__Project_Type__c == NSP_ServiceConstants.PROJECT_TYPE_SERVICE && project.pse__Is_Template__c == False && project.pse__Account__c!= null){
                servicePlanAccountIDs.add(project.pse__Account__c);
                servicePlanProjectsList.add(project);
            }
        }

        projAccIdNameMap = getProjectRelatedAccounts(accIdSet);

        // ADO - 329309
        setProjectSegmentOnBeforeSave(newProjectsList, projAccIdNameMap);

        //Update ProjectName
        //update Asset Type --DF_04021
        this.updateAssetTypeProject( newProjectsList );

        // Added this condition as part of STY-02092
        if(!projectNameList.isEmpty()){
            updateProjectNameonBeforeInsert(projectNameList, projAccIdNameMap);
        }

        //Update Project owner for PEO billable - <STY-04002>
        if(!projectsList.isEmpty()){
          updateProjOwnerForPEOBillable(projectsList,projAccountIDs);
        }

        //Update Project owner for Service Plan project type
        if(!servicePlanProjectsList.isEmpty()){
            updateProjOwnerForServicePlanProjectType(servicePlanProjectsList, servicePlanAccountIDs);
        }
    }

    private static pse__Proj__c setProjectStartAndEndDates( pse__Proj__c project , Id recordTypeId , String templateName , Date endDate ) {
        if ( ( project != null )
            && ( project.recordTypeId == recordTypeId )
            && ( project.TemplateName__c == templateName )
            )
        {
            project.pse__Start_Date__c = System.today();
            project.pse__End_Date__c = endDate;
        }
        return project;
    }

    public void beforeUpdateDirector( Map<Id,pse__Proj__c> newProjectsMap , Map<Id,pse__Proj__c> mOldProjects ) {
        Set<Id> sProjectIds = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> updateProjectIdNameSet = new Set<Id>();
        Set<Id> newsProjectIds = new Set<Id>();
        Set<Id> accIdSet = new Set<Id>();
        List<Asset> assetList;
        List<pse__Proj__c> newProjectsList = new List<pse__Proj__c>();
        Map<Id,Account> projAccIdNameMap;
        Id servicePlan3RecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , 'Service_Plan_Level_3' );
        Id servicePlan4RecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , 'Service_Plan_Level_4' );
        Id peoProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , 'PEO_Project' );
        Id woAssetRecordtypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'WO' );
        Set<Id> mRecordTypeIds = new Set<Id>();
        List<String> projectTypeCompletionValues = label.NSP_Project_Type_Completion_Values.Split(','); // Added as part of DF-03778
        if(servicePlan3RecordTypeId != null){
            mRecordTypeIds.add(servicePlan3RecordTypeId);
        }
        if(servicePlan4RecordTypeId != null){
            mRecordTypeIds.add(servicePlan4RecordTypeId);
        }
        for(pse__Proj__c oProject: newProjectsMap.values()){
            //handleProjectCompletion - Modified If condition as part of DF-03778
            if( !mRecordTypeIds.contains(oProject.recordTypeId) && oProject.pse__Project_Status__c == PROJECTTASKSTATUSCOMPLETE &&
              mOldProjects.get(oProject.Id).pse__Project_Status__c != PROJECTTASKSTATUSCOMPLETE &&
               oProject.recordTypeId == peoProjectRecordTypeId && oProject.pse__Project_Type__c == SERVICEPLANPROJECTTYPE){
                sProjectIds.add(oProject.Id);
                accountIdSet.add(oProject.pse__Account__c);
              }
            //checking for other project record types and excluding Implementation
            if(!mRecordTypeIds.contains(oProject.recordTypeId) && oProject.pse__Project_Status__c == PROJECTTASKSTATUSCOMPLETE &&
              mOldProjects.get(oProject.Id).pse__Project_Status__c != PROJECTTASKSTATUSCOMPLETE &&
               (oProject.recordTypeId != peoProjectRecordTypeId ||
                (oProject.recordTypeId == peoProjectRecordTypeId && !projectTypeCompletionValues.contains(oProject.pse__Project_Type__c)))){
                   newsProjectIds.add(oProject.Id);
               }
            if(oProject.Name != mOldProjects.get(oProject.id).Name && oProject.pse__Is_Template__c){
                oProject.TemplateName__c = oProject.Name;
            }
            // checking for MM and FSO Projects
            if ( !oProject.pse__Is_Template__c
                && ( oProject.TemplateName__c != null )
                && ( ( oProject.TemplateName__c == NSP_ServiceConstants.MM_PROJECT_TEMPLATE_KEY )
                    || ( oProject.TemplateName__c == NSP_ServiceConstants.FSO_PROJECT_TEMPLATE_KEY )
                    )
                && ( oProject.pse__Project_Manager__c != null )
                )
            {
                // creating a Set of Project Manager(Contact) Id
                contactIdSet.add( oProject.pse__Project_Manager__c );
            }
            //updateProjectName
            //added as a part of STY-03216
            if ( ( oProject.pse__Account__c != null )
                && ( oProject.recordTypeId == peoProjectRecordTypeId )
                && ( oProject.pse__Project_Type__c == NSP_ServiceConstants.ImplementationProjectType )
                && !oProject.pse__Is_Template__c
                && ( ( oProject.TemplateName__c == NSP_ServiceConstants.MM_PROJECT_TEMPLATE_KEY )
                    || ( oProject.TemplateName__c == NSP_ServiceConstants.FSO_PROJECT_TEMPLATE_KEY )
                    )
                )
            {
                updateProjectIdNameSet.add( oProject.Id );
            }
            // checkBankAuditTask
            if ( ( oProject.TES_HCM_Implementation_Support_Tasks__c != null )
                && ( mOldProjects.get( oProject.Id ).TES_HCM_Implementation_Support_Tasks__c != NSP_ServiceConstants.TES_HCM_BANK_AUDIT )
                && ( oProject.TES_HCM_Implementation_Support_Tasks__c == NSP_ServiceConstants.TES_HCM_BANK_AUDIT )
                && !mOldProjects.get( oProject.Id ).NSP_Is_Bank_Audit_Task__c
                )
            {
                oProject.NSP_Is_Bank_Audit_Task__c = true;
            }
            if ( String.isNotBlank( oProject.pse__Account__c )
                && ( oProject.pse__Account__c != mOldProjects.get( oProject.Id ).pse__Account__c )
                )
            {
                oProject.Name = '';
                newProjectsList.add( oProject );
                accIdSet.add( oproject.pse__Account__c );
            }
        }
        if ( !accountIdSet.isEmpty() ) {
            List<String> assetFields = new List<String>{
                'Id' ,
                'NSP_Client_Segment_type__c'
            };
            String queryAsset = new NSP_QueryBuilder( 'Asset' , assetFields )
                .addFilter(
                    'AccountId' ,
                    new List<Id>( accountIdSet ) ,
                    NSP_QueryBuilder.Operator.INCLUDES
                )
                .addFilter( 'RecordTypeId' , woAssetRecordtypeId )
                .addFilter( 'NSP_Client_Segment_type__c' , 'Business Team' )
                .addFilter( 'NSP_Account_Status__c' , 'Active' )
                .build();
            assetList = (List<Asset>)Database.query( queryAsset );
        }
        projAccIdNameMap = getProjectRelatedAccounts(accIdSet);

        // ADO - 329309
        setProjectSegmentOnBeforeSave(newProjectsMap.values(), projAccIdNameMap);

        if(!sProjectIds.isEmpty() && !assetList.isEmpty()){
            handleProjectCompletion(newProjectsMap,mOldProjects,sProjectIds);
        }
        if(!newsProjectIds.isEmpty()){
            handleProjectCompletion(newProjectsMap,mOldProjects,newsProjectIds);
        }
        // added as a part of STY-02129
        if(!contactIdSet.isEmpty()){
            updateProjectOwner(newProjectsMap,contactIdSet);
        }
        //added as a part of STY-03216
        if(!updateProjectIdNameSet.isEmpty()){
            updateProjectName(newProjectsMap,mOldProjects,updateProjectIdNameSet, peoProjectRecordTypeId);
        }

        if(!newProjectsList.isEmpty() && projAccIdNameMap != null){
            updateProjectNameonBeforeInsert(newProjectsList, projAccIdNameMap);
        }
    }

    //== Return Account Based on project records
    private static Map<Id,Account> getProjectRelatedAccounts( Set<Id> accIdSet ) {
        Map<Id,Account> accountMap = new Map<Id,Account>();
        if( !accIdSet?.isEmpty() ) {
            accountMap = new Map<Id,Account>([
                SELECT Id , Name , NSP_Account_Segment__c , NSP_Service_Segment__c
                FROM Account
                WHERE ( Id IN :accIdSet )
            ]);
        }
        return accountMap;
    }

    //== Method to set the project client segment on before save // ADO - 329309
    private static void setProjectSegmentOnBeforeSave( List<pse__Proj__c> projectsList , Map<Id,Account> projAccIdNameMap ) {
        Set<String> projectStatusSet = new Set<String>{
            'Complete' ,
            'Cancelled'
        };
        if ( !projAccIdNameMap?.isEmpty() && !projectsList?.isEmpty() ) {
            for ( pse__Proj__c project : projectsList ) {
                if ( projAccIdNameMap.containsKey( project.pse__Account__c )
                    && !projectStatusSet.contains( project.pse__Project_Status__c )
                    )
                {
                    project.Client_Segment__c = NSP_ProjectTriggerHelper.getSegmentValue(
                        projAccIdNameMap.get( project.pse__Account__c ) ,
                        project.Client_Segment__c
                    );
                }
            }
        }
    }

    private static String getSegmentValue( Account record , String defaultValue ) {
        String returnValue = defaultValue;
        if ( record != null ) {
            if ( String.isNotBlank( record.NSP_Service_Segment__c ) ) {
                returnValue = record.NSP_Service_Segment__c;
            } else if ( String.isNotBlank( record.NSP_Account_Segment__c ) ) {
                returnValue = record.NSP_Account_Segment__c;
                String accountSegment = 'Enterprise';
                if ( accountSegment.equalsIgnoreCase( record.NSP_Account_Segment__c ) ) {
                    returnValue = 'Middle Market Enterprise';
                }
            }
        }
        return returnValue;
    }

    //
    // Iterates throught the list of new leads and passes the required attributes to other methods.
    // @param projectNewList List of New project.
    // @param projectOldMap Map of Old project.
    // @return void
    //
    public void afterInsertMethod( List<pse__Proj__c> projectNewList , Map<Id,pse__Proj__c> projectOldMap ) {
        Map<Id,pse__Proj__c> projectNewMap = new Map<Id,pse__Proj__c>();
        for ( pse__Proj__c proj : projectNewList ) {
            projectNewMap.put( proj.Id , proj );
        }
        this.onChangeOfProjectImplementorCoordinator( projectNewMap , projectOldMap );
    }

    //
    // Iterates throught the list of new leads and passes the required attributes to other methods.
    // @param projectNewMap Map of New project.
    // @param projectOldMap Map of Old project.
    // @return void
    //
    public void afterUpdateDirector( Map<Id, pse__Proj__c> projectNewMap , Map<Id, pse__Proj__c> projectOldMap ) {
        Set<Id> cancelledProjectIdSet = new Set<Id>();
        Set<Id> setOfProjectId = new Set<Id>();
        Set<Id> completedPrjctIdSet = new Set<Id>();
        Set<Id> hcmAfterUpdatePrjctIdSet = new Set<Id>();
        Set<Id> updateAssetProductSegmentPrjIdSet = new Set<Id>();
            //Added as part of STY-00721
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id,pse__Proj__c > mapOfProjects = new Map<Id,pse__Proj__c>();//projectidprojectmap
        Map<String,String > projectAssetRecordTypeMap = new Map<String,String>();
        Set<Id> projectSharedIdSet = new Set<Id>();
        Set<Id> setofProjAccId = new Set<Id>();
        Id bpsProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT, 'TES_BPS');
        projectAssetRecordTypeMap.put(NSP_ServiceConstants.HCM_PROJECT_NAME,NSP_ServiceConstants.WX_WA);
        projectAssetRecordTypeMap.put(NSP_ServiceConstants.ITA_IMPLEMENTATION,NSP_ServiceConstants.ASSET_TT_RECORDTYPE);
        projectAssetRecordTypeMap.put(NSP_ServiceConstants.RSTalentConnectIMP,NSP_ServiceConstants.APPLICANT_TRACKING_RECORD_TYPE);
        projectAssetRecordTypeMap.put(NSP_ServiceConstants.OPRTImpl,NSP_ServiceConstants.ASSET_OP_RECORDTYPE);
        projectAssetRecordTypeMap.put(NSP_ServiceConstants.PERFORMSMART_IMPLEMENTATION ,NSP_ServiceConstants.PERFORMANCE_ASSET);
        projectAssetRecordTypeMap.put(NSP_ServiceConstants.INTEGRA_IMPLEMENTATION ,NSP_ServiceConstants.INTEGRA_ASSET);

        List<String> templatesUsedToUpdatePeerReview = new List<string>{NSP_ServiceConstants.ITA_IMPLEMENTATION, NSP_ServiceConstants.ITA_OTHER};
        Set<Id> sentToReviewPrjctIdSet = new Set<Id>();
        //Added as a part of STY-02064
        Set<Id> activeAssetProjectId = new Set<Id>();
        Set<String> projectTemplateNames = new Set<String>();
        Set<Id> backoutAssetProjectId = new Set<Id>();
        Map<String,String> mapofRecordTypevsTemplate = new Map<String,String>();
        // Iterate through the Asset Template Mapping to get the Record Type Name Map of Asset
        for(NSP_Asset_Template_Mapping__mdt metadataObj : [SELECT NSP_Service_Asset_Record_Type__c,NSP_Project_Template__c FROM NSP_Asset_Template_Mapping__mdt WHERE NSP_Project_Template__c != NULL]){
            mapofRecordTypevsTemplate.put(metadataObj.NSP_Service_Asset_Record_Type__c,metadataObj.NSP_Project_Template__c);
        }
        //Iterating over the project new map
        for(Id projectId : projectNewMap.keySet()){
            if(projectNewMap.get(projectId).pse__Account__c != projectOldMap.get(projectId).pse__Account__c){
                setofProjAccId.add(projectId);
            }
            // if the parent opty is closed lost then adding it to the list
            if(!String.isBlank(projectNewMap.get(projectId).pse__Project_Status__c)
                && projectNewMap.get(projectId).pse__Project_Status__c.equals('Cancelled')
                && projectOldMap.get(projectId).pse__Project_Status__c != projectNewMap.get(projectId).pse__Project_Status__c){
                    cancelledProjectIdSet.add(projectId);
                }
            this.onChangeOfProjectImplementorCoordinator( projectNewMap , projectOldMap );
            if(projectNewMap.get(projectId).pse__Is_Template__c && projectNewMap.get(projectId).TemplateName__c != projectOldMap.get(projectId).TemplateName__c){
                setOfProjectId.add(projectId);
            }


                if(projectOldMap.get(projectId).pse__Project_Status__c != projectNewMap.get(projectId).pse__Project_Status__c &&
                    projectNewMap.get(projectId).pse__Project_Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED ){
                        completedPrjctIdSet.add(projectId);
                    }
            if(projectNewMap.get(projectId).TES_HCM_Implementation_Support_Tasks__c == NSP_ServiceConstants.TES_HCM_BANK_AUDIT &&
                projectNewMap.get(projectId).RecordTypeId == bpsProjectRecordTypeId &&
                projectNewMap.get(projectId).TemplateName__c == NSP_ServiceConstants.HCM_PROJECT_NAME &&
                projectNewMap.get(projectId).NSP_Is_Bank_Audit_Task__c && !projectOldMap.get(projectId).NSP_Is_Bank_Audit_Task__c){
                    hcmAfterUpdatePrjctIdSet.add(projectId);
                }
                //Added as part of STY-00721
            //fetch all the project account where visible to client is marked true
            if(projectNewMap.get(projectId).NSP_Visible_to_Client__c && !projectOldMap.get(projectId).NSP_Visible_to_Client__c
            && String.isNotBlank(projectNewMap.get(projectId).pse__Account__c)){
                        accountIdSet.add(projectNewMap.get(projectId).pse__Account__c);
                        mapOfProjects.put(projectId, projectNewMap.get(projectId));
                }
            //Store old project records where visible to client is unchecked from checked
            if(!projectNewMap.get(projectId).NSP_Visible_to_Client__c && projectOldMap.get(projectId).NSP_Visible_to_Client__c
            && String.isNotBlank(projectNewMap.get(projectId).pse__Account__c)){
                        projectSharedIdSet.add(projectId);
            }
                // STY-01785
            if(projectNewMap.get(projectId).recordTypeId == bpsProjectRecordTypeId
                && templatesUsedToUpdatePeerReview.contains(projectNewMap.get(projectId).TemplateName__c)
                && projectNewMap.get(projectId).Peer_Review__c != projectOldMap.get(projectId).Peer_Review__c
                && projectNewMap.get(projectId).Peer_Review__c == NSP_ServiceConstants.PEER_REVIEW_SENT_TO_REVIEW){
                    sentToReviewPrjctIdSet.add(projectId);
            }
            // added as a part of STY-03551
            if(projectNewMap.get(projectId).NSP_Client_Size__c != projectOldMap.get(projectId).NSP_Client_Size__c  && projectAssetRecordTypeMap.containsKey(projectNewMap.get(projectId).TemplateName__c)){
                updateAssetProductSegmentPrjIdSet.add(projectId);
            }
            //Added as a part of STY-02064
            if(mapofRecordTypevsTemplate.values()?.contains(projectNewMap.get(projectId).TemplateName__c)){
                projectTemplateNames.add(projectNewMap.get(projectId).TemplateName__c);
            }
            if(mapofRecordTypevsTemplate.values()?.contains(projectNewMap.get(projectId).TemplateName__c) && (projectNewMap.get(projectId).Invoice_Ready__c && projectNewMap.get(projectId).Go_Live_Date__c != null) && (projectNewMap.get(projectId).Invoice_Ready__c != projectOldMap.get(projectId).Invoice_Ready__c || projectNewMap.get(projectId).Go_Live_Date__c != projectOldMap.get(projectId).Go_Live_Date__c)){
                activeAssetProjectId.add(projectId);
            }
            if(mapofRecordTypevsTemplate.values()?.contains(projectNewMap.get(projectId).TemplateName__c) && projectNewMap.get(projectId).pse__Project_Status__c ==  NSP_ServiceConstants.PROJECTSTATUSCLOSED && projectNewMap.get(projectId).pse__Project_Status__c != projectOldMap.get(projectId).pse__Project_Status__c){
                backoutAssetProjectId.add(projectId);
            }

        }
        if ( !cancelledProjectIdSet.isEmpty() ) {
            this.closeChildrecords( cancelledProjectIdSet );
            onCancelUpdateImplProfile( cancelledProjectIdSet ); //STY-03334
        }
        if(!setOfProjectId.isEmpty()){
            updateTemplateNameOnProjectTask(setOfProjectId, projectNewMap);
        }

        if(!completedPrjctIdSet.isEmpty()){
            cloneTheOpenProjectTasks(completedPrjctIdSet);
        }

        if(!hcmAfterUpdatePrjctIdSet.isEmpty()){
            afterUpdateHCMField(hcmAfterUpdatePrjctIdSet);
        }
        //Added as part of STY-00721
        if(!accountIdSet.isEmpty() && mapOfProjects.size()>0){
             NSP_ProjectRecordSharing.projectRecordSharing(accountIdSet, mapOfProjects);
        }

        if(!projectSharedIdSet.isEmpty()){
            NSP_ProjectRecordSharing.projectRemoveSharing(projectSharedIdSet);
            NSP_ProjectRecordSharing.removeRelatedProjectSharing(projectSharedIdSet);
        }

        if(!sentToReviewPrjctIdSet.isEmpty()){
            createItaCqaCaseAndSendEmail(sentToReviewPrjctIdSet); // STY-01785
        }
        if(!updateAssetProductSegmentPrjIdSet.isEmpty()){
            updateAssetProductSegment(updateAssetProductSegmentPrjIdSet,projectAssetRecordTypeMap);
        }
        if(!backoutAssetProjectId.isEmpty() || !activeAssetProjectId.isEmpty() ) {
            relatedAssetUpdate(activeAssetProjectId,backoutAssetProjectId,projectTemplateNames,mapofRecordTypevsTemplate);
        }
        if(!setofProjAccId.isEmpty()){
            relatedProjectTaskUpdate(setofProjAccId,projectNewMap,projectOldMap);
        }
        // Share task and Milestone after project sharing
        // added as a part of STY-04601
        if(!accountIdSet.isEmpty() && mapOfProjects.size()>0  && !System.isFuture() && !System.isBatch() ){
             NSP_ProjectRecordSharing.shareRelatedProjectTasks(mapOfProjects.keySet());
             NSP_ProjectRecordSharing.shareRelatedMilestones(mapOfProjects.keySet());
        }
    }

    /***********************************************************************************************
    * MethodName: updateProjectNameonBeforeInsert
    * Description : Method to Update Project Name
    * Params:       List<pse__Proj__c> newProjectsList, Map<Id, Account> projAccIdNameMap
    *
    * ********************************************************************************************/
    public void updateProjectNameonBeforeInsert(List<pse__Proj__c> newProjectsList, Map<Id, Account> projAccIdNameMap){
        List<String> templateNameList = new List<String>{
            NSP_ServiceConstants.PROJECT_TEMPLATE_NAME ,
            NSP_ServiceConstants.PROJECT_CORE_TEMPLATE ,
            NSP_ServiceConstants.PROJECT_MM_FOUNDATIONAL_TEMPLATE
        };
        Id bpsProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId(
            NSP_ServiceConstants.PROJECT ,
            NSP_ServiceConstants.PROJECT_BPS_RECORDTYPE
        );
        String payrollUser = UserInfo.getUserId();
        if ( ( projAccIdNameMap != null ) && !projAccIdNameMap.isEmpty() ) {
            List<NSP_Account_Team__c> teamList = [
                SELECT NSP_Role__c , NSP_User__c , NSP_Primary__c , NSP_Last_Name__c
                FROM NSP_Account_Team__c
                WHERE (
                    NSP_Account__c IN :projAccIdNameMap.keySet()
                    AND NSP_User__c != null
                    AND (
                        NSP_Role__c = :NSP_ServiceConstants.PAYROLL_SPECIALIST
                        OR NSP_Role__c = :NSP_ServiceConstants.PAYROLL_SUPERVISOR
                    )
                )
                ORDER BY NSP_Role__c ASC , NSP_Primary__c DESC , NSP_Last_Name__c ASC
                LIMIT 1
            ];
            if ( !teamList.isEmpty() ) {
                payrollUser = teamList[0].NSP_User__c;
            }
        }
        for ( pse__Proj__c project : newProjectsList ) {
            if ( !project.pse__Is_Template__c
                && ( project.RecordTypeId != PEOBILLRECTYPEID )
                && ( project.pse__Project_Type__c != NSP_ServiceConstants.PROJECT_TYPE_SERVICE )
                && ( project.OwnerId == null || !String.valueOf(project.OwnerId).startsWith('00G') && project.NSP_Exclusively_Assign_Owner__c != true)
                )
            {
                project.OwnerId = UserInfo.getUserId();
            }
            if ( payrollUser != null
                && !project.pse__Is_Template__c
                && project.TemplateName__c == 'PEO Termination'
                && project.NSP_Exclusively_Assign_Owner__c != true
                )
            {
                project.OwnerId = payrollUser;
            }
            if ( project.pse__Is_Template__c ) {
                project.TemplateName__c = project.name;
            } else if ( !project.pse__Is_Template__c
                && ( ( project.RecordTypeId == bpsProjectRecordTypeId )
                    || ( String.isNotBlank( project.TemplateName__c )
                        && project.TemplateName__c.startsWith( 'RET' )
                        )
                    )
                )
            {
                project.Name = String.isNotBlank(project.pse__Account__c) ?
                    projAccIdNameMap.get(project.pse__Account__c).Name + ': ' + project.TemplateName__c :
                    project.TemplateName__c
                    ;
            } else if ( !project.pse__Is_Template__c
                && project.pse__Start_Date__c == System.today()
                && project.pse__Is_Active__c == true
                && templateNameList.contains(project.TemplateName__c)
                )
            {
                project.Name = String.isNotBlank(project.pse__Account__c) ?
                    projectNameAsPerNamingConvention(project.TemplateName__c,project.pse__Start_Date__c, projAccIdNameMap.get(project.pse__Account__c).Name) :
                    projectNameAsPerNamingConvention(project.TemplateName__c,project.pse__Start_Date__c, NSP_ServiceConstants.EMPTY_STRING)
                    ;
            } else if ( !project.pse__Is_Template__c
                && ( project.RecordTypeId == peoProjectRecordTypeId || project.RecordTypeId == PEOBILLRECTYPEID )
                && project.pse__Start_Date__c != null
                )
            {
                project.Name = String.isNotBlank(project.pse__Account__c) ?
                    projectNameAsPerNamingConvention(project.TemplateName__c,project.pse__Start_Date__c, projAccIdNameMap.get(project.pse__Account__c).Name) :
                    projectNameAsPerNamingConvention(project.TemplateName__c,project.pse__Start_Date__c, NSP_ServiceConstants.EMPTY_STRING)
                    ;
            }
            project.Name = NSP_ProjectTriggerHelper.safeProjectName( project.Name );
        }
    }

    private static String safeProjectName( String value ) {
        String response = value;
        if ( String.isNotBlank( response ) && ( response.length() > 73 ) ) {
            response = response.substring( 0 , 73 );
        }
        return response;
    }

    //
    // MethodName: getProjectAssetFromTemp
    // Description : Method to get projecttemplate Asset Type
    // Params: String Template Name
    //
    private String getProjectAssetFromTemp( String templateName ) {
        List<pse__Proj__c> projectTemplate = null;
        if ( String.isNotBlank( templateName ) ) {
            projectTemplate = [
                SELECT Id , NSP_Asset_Type__c
                FROM pse__Proj__c
                WHERE (
                    ( TemplateName__c = :templateName )
                    AND ( pse__Is_Template__c = true )
                    AND ( pse__Is_Active__c = true )
                )
                LIMIT 1
            ];
        }
        String response = null;
        if ( ( projectTemplate != null ) && !projectTemplate.isEmpty() ) {
            response = projectTemplate[0].NSP_Asset_Type__c;
        }
        return response;
    }

    //
    // MethodName: updateAssetTypeProject
    // Description : update project Asset Type name with project template Asset Type
    // Params: List<pse__Proj__c> newProjectsList
    //
    private void updateAssetTypeProject( List<pse__Proj__c> newProjectsList ) {
        if ( ( newProjectsList != null ) && !newProjectsList.isEmpty() ) {
            for ( pse__Proj__c project : newProjectsList ) {
                project.NSP_Asset_Type__c = this.getProjectAssetFromTemp( project.TemplateName__c );
            }
        }
    }

    //
    // call the method to Update the child records with closed status.
    // @param projectId set of New project.
    // @return void
    //
    private void closeChildrecords( Set<Id> projectIdSet ) {
        if ( !projectIdSet.isEmpty() ) {
            this.updateChildStatus(
                projectIdSet ,
                'pse__Assignment__c' ,
                NSP_ServiceConstants.PSE_PROJECT ,
                NSP_ServiceConstants.CLOSED_STATUS
            );
            this.updateChildStatus(
                projectIdSet ,
                'pse__Milestone__c' ,
                NSP_ServiceConstants.PSE_PROJECT ,
                NSP_ServiceConstants.CANCELLED_STATUS
            );
            this.updateChildStatus(
                projectIdSet ,
                'pse__Project_Task__c' ,
                NSP_ServiceConstants.PSE_PROJECT ,
                NSP_ServiceConstants.PROJECT_TASK_CANCELLED
            );
        }
    }

    //
    // method to Updates the child records with closed status.
    // @param projectId set of New project, Object name, relationField, updatedStatusValue
    // @return void
    //
    private void updateChildStatus(
        Set<Id> projectIdSet ,
        String objectName ,
        String relationField ,
        String updatedStatusValue
        )
    {
        List<sObject> childRecordList = Database.query(
            'SELECT Id , pse__Status__c'
            + ' FROM ' + String.escapeSingleQuotes( objectName )
            + ' WHERE ('
            + '    ( ' + String.escapeSingleQuotes( relationField ) + ' IN :projectIdSet )'
            + '    AND ('
            + '         ( pse__Status__c != ' + '\'' + NSP_ServiceConstants.COMPLETE_STATUS + '\' )'
            + '         AND ( pse__Status__c != ' + '\'' + NSP_ServiceConstants.SCHEDULED_STATUS + '\' )'
            + '     )'
            + ' )'
        );
        if ( ( childRecordList != null ) && !childRecordList.isEmpty() ) {
            for ( sObject childRecordObj : childRecordList ) {
                childRecordObj.put( 'pse__Status__c' , updatedStatusValue );
            }
            List<Database.SaveResult> results = Database.update( childRecordList , false );
            NSP_ErrorLogHandler.logResults(
                NSP_ProjectTriggerHelper.class.getName() ,
                'updateChildStatus' ,
                results
            );
        }
    }

    //
    // Method to assign assignments to project and its related project task and milestone on change of Project co-ordinator and Implementor.
    // @param projectNewMap Map of New project.
    // @param projectOldMap Map of Old project.
    // @return void
    //
    private void onChangeOfProjectImplementorCoordinator( Map<Id,pse__Proj__c> projectNewMap , Map<Id,pse__Proj__c> projectOldMap ) {
        Map<Id, Id> userWithContactMap = new Map<Id, Id>();
        Map<Id, pse__Proj__c> changedProjectMap = new Map<Id, pse__Proj__c>();
        Set<Id> projectUsersSet = new Set<Id>();
        //Iterating over the project new map
        for(pse__Proj__c project : projectNewMap.values()){
            // if the parent opty is closed lost then adding it to the list
            if(!String.isBlank(projectNewMap.get(project.Id).Project_Implementer__c)
                && projectNewMap.get(project.Id).Project_Implementer__c !=
                projectOldMap.get(project.Id).Project_Implementer__c){
                    changedProjectMap.put(project.Id, project);
                    projectUsersSet.add(project.Project_Implementer__c);
            }
            if(!String.isBlank(projectNewMap.get(project.Id).Project_Coordinator__c)
                && projectNewMap.get(project.Id).Project_Coordinator__c !=
                projectOldMap.get(project.Id).Project_Coordinator__c){
                    changedProjectMap.put(project.Id, project);
                    projectUsersSet.add(project.Project_Coordinator__c);
            }
        }
        if(!projectUsersSet.isEmpty()){
            for(Contact userVal : [SELECT Id, pse__Salesforce_User__c
                                    FROM Contact
                                    WHERE pse__Salesforce_User__c IN: projectUsersSet]){
                userWithContactMap.put(userVal.pse__Salesforce_User__c, userVal.Id);
            }
        }
        //List is empty or not
        if ( !changedProjectMap.isEmpty() && !userWithContactMap.isEmpty() ) {
            this.linkProjectImplementerToChildrecords(
                changedProjectMap ,
                userWithContactMap ,
                projectNewMap
            );
        }
    }

    //
    // call the method to Update the child records to link project Implementer.
    // @param Map<Id, pse__Proj__c> changedProjectMap, Map<Id, Id> userWithContactMap, Map<Id, pse__Proj__c> projectNewMap
    // @return void
    //
    private void linkProjectImplementerToChildrecords(
        Map<Id,pse__Proj__c> changedProjectMap ,
        Map<Id,Id> userWithContactMap ,
        Map<Id,pse__Proj__c> projectNewMap
        )
    {
        if ( ( changedProjectMap != null ) && !changedProjectMap.isEmpty() ) {
            this.createSchedule(
                changedProjectMap ,
                userWithContactMap ,
                projectNewMap
            );
        }
    }

    //
    // method to create schedule for the assignments.
    // @param Map<Id, pse__Proj__c> changedProjectMap, Map<Id, Id> userWithContactMap, Map<Id, pse__Proj__c> projectNewMap
    // @return void
    //
    private void createSchedule(
        Map<Id,pse__Proj__c> changedProjectMap ,
        Map<Id,Id> userWithContactMap ,
        Map<Id,pse__Proj__c> projectNewMap
        )
    {
        try {
            Map<Id,pse__Schedule__c> projectWithScheduleMap = new Map<Id,pse__Schedule__c>();
            if ( ( projectNewMap != null ) && !projectNewMap.isEmpty() ) {
                for ( pse__Proj__c project : projectNewMap.values() ) {
                    if ( ( project.Id != null )
                        && ( project.pse__Start_Date__c != null )
                        && ( project.pse__End_Date__c != null )
                        )
                    {
                        pse__Schedule__c sch = new pse__Schedule__c();
                        sch.pse__Start_Date__c = project.pse__Start_Date__c;
                        sch.pse__End_Date__c = project.pse__End_Date__c;
                        projectWithScheduleMap.put( project.Id , sch );
                    }
                }
                if ( !projectWithScheduleMap.isEmpty() ) {
                    insert projectWithScheduleMap.values();
                }
            }
            this.createAssignments(
                changedProjectMap ,
                userWithContactMap ,
                projectWithScheduleMap
            );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTriggerHelper.class.getName() ,
                'createSchedule' ,
                e
            );
        }
    }

    //
    // method to create assignments for project coordinator and implementor.
    // @param Map<Id, pse__Proj__c> changedProjectMap, Map<Id, Id> userWithContactMap, Map<Id, pse__Schedule__c> projectWithScheduleMap
    // @return void
    //
    private void createAssignments(
        Map<Id,pse__Proj__c> changedProjectMap ,
        Map<Id,Id> userWithContactMap ,
        Map<Id,pse__Schedule__c> projectWithScheduleMap
        )
    {
        try {
            Set<Id> resourceContactIds = new Set<Id>();
            if(!userWithContactMap?.isEmpty()) {
                resourceContactIds.addAll(userWithContactMap.values());
            }
            Set<Id> staffingPermittedResourceIds = NSP_ProjectTriggerHelper.getStaffingPermittedResourceIds( resourceContactIds );
            List<pse__Assignment__c> relatedAssignmentList = new List<pse__Assignment__c>();
            for ( Id projectId : changedProjectMap.keyset() ) {
                pse__Proj__c project = changedProjectMap.get( projectId );
                Id projectCoordinator = userWithContactMap.get( project.Project_Coordinator__c );
                Id projectImplementor = userWithContactMap.get( project.Project_Implementer__c );
                Id resourceId = null;
                if ( projectCoordinator != projectImplementor ) {
                    if ( projectImplementor != null ) {
                        resourceId = projectImplementor;
                    }
                    if ( projectCoordinator != null ) {
                        resourceId = projectCoordinator;
                    }
                } else if ( projectCoordinator == projectImplementor ) {
                    resourceId = projectImplementor;
                }
                pse__Schedule__c schedule = projectWithScheduleMap.get( projectId );
                if ( schedule != null && resourceId != null && staffingPermittedResourceIds?.contains( resourceId ) ) {
                    relatedAssignmentList.add(
                        this.buildLinkedAssignment(
                            projectId ,
                            resourceId ,
                            schedule.Id
                        )
                    );
                }
            }
            // Adding Test.isRunningTest to bypass in test class as we need staffing permission for the assignment's resource and the assignment's
            if ( !relatedAssignmentList.isEmpty() && !Test.isRunningTest() ) {
                // throws DmlException ~ FIELD_CUSTOM_VALIDATION_EXCEPTION, You are not allowed to create the assignment *** You must be granted the Staffing permission for the assignment's resource and the assignment's project.
                List<Database.SaveResult> results = Database.insert( relatedAssignmentList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ProjectTriggerHelper.class.getName() ,
                    'createAssignments:insert' ,
                    results
                );
            }
            this.linkAssignmentToProjectTask(
                'pse__Project_Task__c' ,
                'pse__Project__c' ,
                relatedAssignmentList ,
                changedProjectMap
            );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTriggerHelper.class.getName() ,
                'createAssignments' ,
                e
            );
        }
    }



    // Returns the subset of resourceContactIds that have an active Staffing permission control.
    // @param resourceContactIds Set of Contact Ids to check against pse__Permission_Control__c
    // @return Set<Id> of Contact Ids where pse__Staffing__c is true
    private static Set<Id> getStaffingPermittedResourceIds( Set<Id> resourceContactIds ) {
        Set<Id> result = new Set<Id>();
        if(!resourceContactIds?.isEmpty()) {
            for ( pse__Permission_Control__c pc : [
                SELECT pse__Resource__c
                FROM pse__Permission_Control__c
                WHERE pse__Resource__c IN :resourceContactIds
                  AND pse__Staffing__c = true
            ] ) {
                result.add( pc.pse__Resource__c );
            }
        }
        return result;
    }

    private pse__Assignment__c buildLinkedAssignment( Id projectId , Id resourceId , Id scheduleId ) {
        pse__Assignment__c relatedAssignment = new pse__Assignment__c();
        relatedAssignment.pse__Project__c = projectId;
        relatedAssignment.pse__Bill_Rate__c = 0.00;
        relatedAssignment.pse__Resource__c = resourceId;
        relatedAssignment.pse__Schedule__c = scheduleId;
        return relatedAssignment;
    }

    //
    // method to link project task with new assignemnts.
    // @param String objectName, String relationField, List<pse__Assignment__c> relatedAssignmentList, Map<Id, pse__Proj__c> changedProjectMap
    // @return void
    //
    private void linkAssignmentToProjectTask(
        String objectName ,
        String relationField ,
        List<pse__Assignment__c> relatedAssignmentList ,
        Map<Id,pse__Proj__c> changedProjectMap
        )
    {
        try {
            Set<Id> projectKeys = changedProjectMap.keyset();
            Map<Id,pse__Assignment__c> resourceWithAssignment = new Map<Id,pse__Assignment__c>();
            List<sObject> childRecordList = Database.query(
                'SELECT Id, pse__Project__c'
                +' FROM '+ String.escapeSingleQuotes(objectName)
                +' WHERE '+ String.escapeSingleQuotes(relationField) +' IN: projectKeys'
                +' AND pse__Project__r.RecordTypeId !='+ '\''+bpsProjectRecordTypeId+'\''
            );
            List<pse__Project_Task_Assignment__c> ptaList = new List<pse__Project_Task_Assignment__c>();
            for(pse__Assignment__c assignment : relatedAssignmentList){
                resourceWithAssignment.put(assignment.pse__Resource__c, assignment);
            }
            if(!childRecordList.isEmpty()){
                for(sObject childRecordObj : childRecordList){
                    if(objectName == 'pse__Project_Task__c'){
                        for(pse__Assignment__c assignment : resourceWithAssignment.values()){
                            pse__Project_Task_Assignment__c pta = new pse__Project_Task_Assignment__c();
                            pta.pse__Project_Task__c = childRecordObj.Id;
                            pta.pse__Assignment__c = assignment.Id;
                            pta.pse__Resource__c = assignment.pse__Resource__c;
                            pta.pse__Resource_Role__c = 'Executive';
                            ptaList.add(pta);
                        }
                    }
                }
            }
            insert ptaList;
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTriggerHelper.class.getName() ,
                'linkAssignmentToProjectTask' ,
                e
            );
        }
    }

    public void afterInsertDirector( List<pse__Proj__c> newProjectList , Map<Id,pse__Proj__c> oldMap ) {
        Map<Id,Id> mapOfAccountIdAndProjectId = new Map<Id,Id>();
        Map<Id,pse__Proj__c> mapOfProjectIdAndProject = new Map<Id,pse__Proj__c>();
        Set<Id> setOfAccountId = new Set<Id> ();
        Set<Id> setOfProjectId = new Set<Id> ();
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> mmProjectIds = new Set<Id>();
        Set<Id> fsoProjectIds = new Set<Id>();
        Set<Id> itaProjectIds = new Set<Id>();
        Set<Id> hrScaleProjectIds = new Set<Id>();
        Set<Id> shareProjAccIdSet = new Set<Id>();
        Map<Id,pse__Proj__c > mapOfProjectToShare = new Map<Id,pse__Proj__c>();
        List<pse__Proj__c> ipProjectList = new List<pse__Proj__c>();
        Set<Id> wxProjectIdSet = new Set<Id>();
        Map<Id, Id> projectAccountMap = new Map<Id, Id>();
        Id bpsProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT, 'TES_BPS');
        List<String> templatesUsedToUpdatePeerReview = new List<string>{NSP_ServiceConstants.ITA_IMPLEMENTATION, NSP_ServiceConstants.ITA_OTHER};
        Set<Id> sentToReviewPrjctIdSet = new Set<Id>();
        for(pse__Proj__c project : newProjectList){
            if(project.pse__Account__c != null && (project.RecordTypeId == peoProjectRecordTypeId ||project.RecordTypeId == PEOBILLRECTYPEID)){
                setOfAccountId.add( project.pse__Account__c );
                if(!mapOfAccountIdAndProjectId.containsKey(project.pse__Account__c)){
                    mapOfAccountIdAndProjectId.put(project.pse__Account__c,project.id);
                }
            }

            if(project.pse__Is_Template__c){
                setOfProjectId.add(project.id);
                if(!mapOfProjectIdAndProject.containsKey(project.id)){
                    mapOfProjectIdAndProject.put(project.id, project);
                }
            }

            if(project.pse__Account__c!=null){
                accountIdSet.add(project.pse__Account__c);
            }
            if ( ( project.pse__Project_Type__c == NSP_ServiceConstants.ImplementationProjectType )
                && !project.pse__Is_Template__c
                && project.RecordTypeId == NSP_ProjectTriggerHelper.peoProjectRecordTypeId
                && ( ( project.TemplateName__c == NSP_ServiceConstants.MM_PROJECT_TEMPLATE_KEY )
                    || ( project.TemplateName__c == NSP_ServiceConstants.FSO_PROJECT_TEMPLATE_KEY )
                    || ( project.TemplateName__c == NSP_ServiceConstants.HRSCALE_PROJECT_TEMPLATE_KEY )
                    )
                )
            {
                if ( project.TemplateName__c == NSP_ServiceConstants.MM_PROJECT_TEMPLATE_KEY ) {
                    ipProjectList.add( project );
                    mmProjectIds.add( project.Id );
                } else if ( project.TemplateName__c == NSP_ServiceConstants.FSO_PROJECT_TEMPLATE_KEY ) {
                    ipProjectList.add( project );
                    fsoProjectIds.add( project.Id );
                } else if ( project.TemplateName__c == NSP_ServiceConstants.HRSCALE_PROJECT_TEMPLATE_KEY ) {
                    hrScaleProjectIds.add( project.Id );
                }
            } else if ( ( project.pse__Project_Type__c == 'New' )
                && project.RecordTypeId == NSP_ProjectTriggerHelper.bpsProjectRecordTypeId
                && ( project.TemplateName__c == NSP_ServiceConstants.ITA_Prj_Temp )
                )
            {
                itaProjectIds.add( project.Id );
            }

            //STY-02159
            if(!dupPreventionSet.contains(project.Id) && !project.pse__Is_Template__c && project.TemplateName__c == 'iSolved Benefits'){
                dupPreventionSet.add(project.Id);
                wxProjectIdSet.add(project.Id);
            }
            //STY-03820, store the project id and associated account ids in map for the ITA implementation project templates
            if(project.TemplateName__c == NSP_ServiceConstants.ITA_IMPLEMENTATION && project.pse__Account__c != NULL){
                projectAccountMap.put(project.Id, project.pse__Account__c);
            }
            //STY-04100 - To share project records in community
            if(oldMap.get(project.Id).NSP_Visible_to_Client__c == true
               && String.isNotBlank(oldMap.get(project.Id).pse__Account__c)
               && oldMap.get(project.Id).pse__Is_Template__c == false){
                   shareProjAccIdSet.add(oldMap.get(project.Id).pse__Account__c);
                   mapOfProjectToShare.put(project.Id, oldMap.get(project.Id));
            }

                 // STY-01785
            if(project.recordTypeId == bpsProjectRecordTypeId
                && templatesUsedToUpdatePeerReview.contains(project.TemplateName__c)
                && project.Peer_Review__c == NSP_ServiceConstants.PEER_REVIEW_SENT_TO_REVIEW){
                    sentToReviewPrjctIdSet.add(project.Id);
            }
        }

        if(!setOfAccountId.isEmpty()){
            copyClientGoalFromAccountOnProjectGoalOnProject( setOfAccountId, mapOfAccountIdAndProjectId );
        }

        if(!setOfProjectId.isEmpty()){
            updateTemplateNameOnProjectTask(setOfProjectId, mapOfProjectIdAndProject);
        }

        if(!ipProjectList.isEmpty()){
            createImplementationProfile(ipProjectList, accountIdSet);
        }

        if(!wxProjectIdSet.isEmpty()){
            createWXProject(wxProjectIdSet);
        }
        //added as part of story STY-03820
        if(projectAccountMap.size()>0){
            createPEOCase(projectAccountMap);
        }
        if ( !mmProjectIds.isEmpty()
            || !fsoProjectIds.isEmpty()
            || !hrScaleProjectIds.isEmpty()
            || !itaProjectIds.isEmpty()
            )
        {
            NSP_ProjectTriggerHelper.createProjectTeamRoles(
                mmProjectIds ,
                fsoProjectIds ,
                hrScaleProjectIds ,
                itaProjectIds
            );
        }
        //STY-04100 - To share project records in community
        if(!shareProjAccIdSet.isEmpty() && mapOfProjectToShare != null){
            NSP_ProjectRecordSharing.projectRecordSharing(shareProjAccIdSet, mapOfProjectToShare);
        }

        if(!sentToReviewPrjctIdSet.isEmpty()){
            createItaCqaCaseAndSendEmail(sentToReviewPrjctIdSet); // STY-01785
        }
    }

    /* Description : This will copy all the client goals associated with
                    account to Project goals associated with Project
        * Date        : 30/09/2021 */

    public void copyClientGoalFromAccountOnProjectGoalOnProject(set<ID> accountId, map<Id, Id> mapOfAccountIdAndProjectId){
        list<NSP_ProjectGoal__c> listOfProjectGoals = new list<NSP_ProjectGoal__c>();

        for(NSP_ClientGoal__c clientGoals : [SELECT NSP_Account__c, NSP_Goal_Type__c, NSP_Goal_Details__c, NSP_Date__c, NSP_Goal_Date__c, NSP_Status__c, NSP_Contact__c, Asset__c, Name
                                                FROM NSP_ClientGoal__c
                                                WHERE NSP_Account__c IN :accountId and NSP_Status__c = 'Active']){
            NSP_ProjectGoal__c createProjectGoal = new NSP_ProjectGoal__c();
            createProjectGoal.NSP_GoalType__c = clientGoals.NSP_Goal_Type__c;
            createProjectGoal.NSP_Project__c  = mapOfAccountIdAndProjectId.get(clientGoals.NSP_Account__c);
            createProjectGoal.NSP_PG_Date__c = clientGoals.NSP_Date__c;
            createProjectGoal.NSP_PG_Goal_Target_Date__c = clientGoals.NSP_Goal_Date__c;
            createProjectGoal.NSP_PG_Status__c = clientGoals.NSP_Status__c;
            createProjectGoal.NSP_PG_Contact__c = clientGoals.NSP_Contact__c;
            createProjectGoal.NSP_PG_Asset__c = clientGoals.Asset__c;
            createProjectGoal.Client_Goals_Name__c = clientGoals.Name;
            if(clientGoals.NSP_Goal_Details__c!=null && clientGoals.NSP_Goal_Details__c.length()>255){
                createProjectGoal.NSP_Details__c = clientGoals.NSP_Goal_Details__c.subString(0,255);
            } else{
                createProjectGoal.NSP_Details__c = clientGoals.NSP_Goal_Details__c;
            }

            listOfProjectGoals.add(createProjectGoal);
        }

        if(!listOfProjectGoals.isEmpty()){
            Database.insert(listOfProjectGoals);
        }
    }

    /* Description : This will update Template Name field on Project Task
                    with related Template Name if Template EQUALS TRUE
        * Date        : 02/11/2021 */

    public void updateTemplateNameOnProjectTask(set<ID> projectId, Map<Id, pse__Proj__c> mapOfProjectIdProject){
        List<pse__Project_Task__c> listOfProjectTask = new List<pse__Project_Task__c>();

        for(pse__Project_Task__c projectTask : [SELECT Template_Name__c, pse__Project__c
                                                FROM pse__Project_Task__c
                                                WHERE pse__Project__c IN : projectId]){
            projectTask.Template_Name__c = mapOfProjectIdProject.get(projectTask.pse__Project__c).TemplateName__c;
            listOfProjectTask.add(projectTask);
        }

        if(!listOfProjectTask.isEmpty()){
            Database.update(listOfProjectTask);
        }
    }

    /**
    * Iterates throught the list of new pse__Proj__c and passes the required attributes to other methods.
    * @param mNewProjects Map of New projects
    * @param mOldProjects Map of Old projects
    * @return void
    *
    */
    public void handleProjectCompletion(Map<Id,pse__Proj__c> mNewProjects,Map<Id,pse__Proj__c> mOldProjects, Set<Id> sProjectIds){
        if(sProjectIds.size() > 0){
            List<pse__Project_Task__c> lProjectTasks = new List<pse__Project_Task__c>([SELECT Id, pse__Project__c, pse__Status__c FROM pse__Project_Task__c WHERE pse__Project__c in: sProjectIds AND ( pse__Status__c !=: PROJECTTASKSTATUSCOMPLETE AND pse__Status__c !=: PROJECTTASKSTATUSCANCELLED)
                                                                                        AND Name NOT IN: PROJECTTASKNAMES]);
            for(pse__Project_Task__c oProjectTask  : lProjectTasks){
                mNewProjects.get(oProjectTask.pse__Project__c).addError(System.Label.NSP_ProjectTask_Completion_Error);
            }
            List<pse__Milestone__c> lMileStones = new List<pse__Milestone__c>([SELECT Id, pse__Project__c,   (SELECT Id, Name FROM pse__Project_Tasks__r WHERE Name IN: PROJECTTASKNAMES),pse__Status__c FROM pse__Milestone__c WHERE pse__Project__c in: sProjectIds
                                                                                AND ( pse__Status__c !=: PROJECTTASKSTATUSCOMPLETE AND pse__Status__c != 'Cancelled')]);
            for(pse__Milestone__c oMileStone  : lMileStones){
                if(oMileStone.pse__Project_Tasks__r.isEmpty()){
                    mNewProjects.get(oMileStone.pse__Project__c).addError(System.Label.NSP_ProjectTask_Completion_Error);
                }
            }
        }
    }

    // create Implementation Profile when a Project is Created
    public static void createImplementationProfile( List< pse__Proj__c> projectList , Set<Id> accountIdSet ) {
        Id recordTypeFSOImpProfileID = NSP_GenericRecordType.getRecordTypeId( 'Implementation_Profile__c' , 'FSO' );
        Id recordTypeMMImpProfileID = NSP_GenericRecordType.getRecordTypeId( 'Implementation_Profile__c' , 'Middle_Market' );
        Id assetWoRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'WO' );
        Map<Id,Id> mapAccountIdAssetId = new Map<Id,Id>();
        List<Implementation_Profile__c> implementationProfiles = new List<Implementation_Profile__c>();
        try {
            for ( Asset asset : [
                        SELECT Id , AccountId
                        FROM Asset
                        WHERE (
                            ( AccountId IN :accountIdSet )
                            AND ( RecordTypeId = :assetWoRecordTypeId )
                        )
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ]
                )
            {
                mapAccountIdAssetId.put( asset.AccountId , asset.Id );
            }
            // creating Implementation Profile Record for MM & FSO Projects
            for ( pse__Proj__c project : projectList ) {
                Implementation_Profile__c imProfile = new Implementation_Profile__c();
                imProfile.NSP_Project__c = project.Id;
                imProfile.recordTypeId = ( ( project.TemplateName__c == NSP_ServiceConstants.MM_PROJECT_TEMPLATE_KEY ) ? recordTypeMMImpProfileID : recordTypeFSOImpProfileID );
                if ( project.pse__Account__c != null ) {
                    imProfile.Account__c = project.pse__Account__c;
                }
                // Mapping Account Asset Id on Imp Profile
                if ( project.pse__Account__c != null && mapAccountIdAssetId.containsKey( project.pse__Account__c ) ) {
                    imProfile.NSP_Asset__c = mapAccountIdAssetId.get( project.pse__Account__c );
                }
                imProfile = NSP_ImplementationHelper.prepopulateIPData( imProfile.Account__c , imProfile );
                implementationProfiles.add( imProfile );
            }
            // Inserting Implementation Profile Records
            if ( !implementationProfiles.isEmpty() ) {
                Database.insert( implementationProfiles );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTriggerHelper.class.getName() ,
                'createImplementationProfile' ,
                e
            );
        }
    }

    /***********************************************************************************************
    * MethodName: updateProjectOwner
    * Description : This Method will update Project Manager as the Owner of the Project for Automated Projects
    * Params:       Map<Id, pse__Proj__c> newProjectMap
    * ********************************************************************************************/
    public void updateProjectOwner(Map<Id, pse__Proj__c> newProjectMap, Set<Id> contactIdSet){
        try{
            // Creating Map of Contact and SF User
            Map<Id,Contact> projectManagerMap =  new Map<Id,Contact>([Select Id , pse__Salesforce_User__c FROM Contact WHERE Id IN:contactIdSet  AND pse__Salesforce_User__c != null]);
            // updating Project Manager as the Owner of the Project
            for(pse__Proj__c project:newProjectMap.values()){
                // Assigning Project Manager as the Owner of the Project
                if(projectManagerMap.containsKey(project.pse__Project_Manager__c)){
                    project.OwnerId=projectManagerMap.get(project.pse__Project_Manager__c).pse__Salesforce_User__c;
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTriggerHelper.class.getName() ,
                'updateProjectOwner' ,
                e
            );
        }
    }

    // create Project Team records for MM and FSO projects
    private static void createProjectTeamRoles(
        Set<Id> mapMMProjectListMMRoles ,
        Set<Id> mapFSOProjectListFSORoles ,
        Set<Id> mapHRScaleProjectListHRScaleRoles ,
        Set<Id> mapITAProjectListITARoles
        )
    {
        List<NSP_Project_Team__c> projectTeamList = new List<NSP_Project_Team__c>();
        try {
            Set<String> fsoProjectTeamRolesList = new Set<String>{
                NSP_ServiceConstants.ProjectManager ,
                NSP_ServiceConstants.OrientationRep ,
                NSP_ServiceConstants.OSCoordinator ,
                NSP_ServiceConstants.OTCoordinator ,
                NSP_ServiceConstants.OTPlanner ,
                NSP_ServiceConstants.PayrollSpecialist ,
                'HR Client Implementation Team Member'
            };
            Set<String> mmProjectTeamRolesList = new Set<String>{
                NSP_ServiceConstants.ProjectManager ,
                NSP_ServiceConstants.TransitionSpecialist ,
                NSP_ServiceConstants.SrBenefitRep ,
                NSP_ServiceConstants.PayrollProjectManager ,
                NSP_ServiceConstants.PayrollSpecialist ,
                NSP_ServiceConstants.SrHrSpecialist ,
                NSP_ServiceConstants.AccountExecutive ,
                'HR Client Implementation Team Member'
            };
            Set<String> hrScaleProjectTeamRolesList = new Set<String>{
                NSP_ServiceConstants.ProjectManager ,
                NSP_ServiceConstants.HCMAnalyst ,
                NSP_ServiceConstants.FCPayroll ,
                NSP_ServiceConstants.TimeAnalyst ,
                NSP_ServiceConstants.SrBenefitRep ,
                NSP_ServiceConstants.HCMPayrollAnalyst ,
                NSP_ServiceConstants.FCTalent ,
                NSP_ServiceConstants.CompAnalyst
            };
            Set<String> itaProjectTeamRolesList = new Set<String>{
                NSP_ServiceConstants.IntakeSpecialist ,
                NSP_ServiceConstants.SoftwareAnalyst
            };
            Id mmProjectTeamRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'NSP_Project_Team__c' , 'NSP_Middle_Market_Project_Team' );
            Id fsoProjectTeamRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'NSP_Project_Team__c' , 'NSP_FSO_Project_Team' );
            // creating a list of MM Project Team records
            if ( mapMMProjectListMMROles!= null && !mapMMProjectListMMROles.isEmpty() ) {
                for( Id projectId : mapMMProjectListMMROles ) {
                    for ( String mmPrjRole : mmProjectTeamRolesList ) {
                        NSP_Project_Team__c mmPrjTeam = new NSP_Project_Team__c();
                        mmPrjTeam.RecordTypeId = mmProjectTeamRecordTypeId;
                        mmPrjTeam.NSP_Project__c = projectId;
                        mmPrjTeam.NSP_Role__c = mmPrjRole;
                        projectTeamList.add( mmPrjTeam );
                    }
                }
            }
            // creating a list of FSO Project Team records
            if ( mapFSOProjectListFSOROles!=null && !mapFSOProjectListFSOROles.isEmpty() ) {
                for ( Id projectId : mapFSOProjectListFSOROles ) {
                    for ( String fsoPrjRole : fsoProjectTeamRolesList ) {
                        NSP_Project_Team__c fsoPrjTeam = new NSP_Project_Team__c();
                        fsoPrjTeam.RecordTypeId = fsoProjectTeamRecordTypeId;
                        fsoPrjTeam.NSP_Project__c = projectId;
                        fsoPrjTeam.NSP_Role__c = fsoPrjRole;
                        projectTeamList.add( fsoPrjTeam );
                    }
                }
            }

            // creating a list of HRScale Project Team records
            if ( ( mapHRScaleProjectListHRScaleRoles != null ) && !mapHRScaleProjectListHRScaleRoles.isEmpty() ) {
                for ( Id projectId : mapHRScaleProjectListHRScaleRoles ) {
                    for ( String hrScalePrjRole : hrScaleProjectTeamRolesList ) {
                        NSP_Project_Team__c hrScalePrjTeam = new NSP_Project_Team__c();
                        hrScalePrjTeam.RecordTypeId = fsoProjectTeamRecordTypeId;
                        hrScalePrjTeam.NSP_Project__c = projectId;
                        hrScalePrjTeam.NSP_Role__c = hrScalePrjRole;
                        projectTeamList.add( hrScalePrjTeam );
                    }
                }
            }
            // creating a list of ITA Project Team records
            if ( ( mapITAProjectListITARoles != null ) && !mapITAProjectListITARoles.isEmpty() ) {
                for ( Id projectId : mapITAProjectListITARoles ) {
                    for ( String itaPrjRole : itaProjectTeamRolesList ) {
                        NSP_Project_Team__c itaPrjTeam = new NSP_Project_Team__c();
                        itaPrjTeam.RecordTypeId = fsoProjectTeamRecordTypeId;
                        itaPrjTeam.NSP_Project__c = projectId;
                        itaPrjTeam.NSP_Role__c = itaPrjRole;
                        projectTeamList.add( itaPrjTeam );
                    }
                }
            }
            // Inserting a list of  Project Team records
            if ( !projectTeamList.isEmpty() ) {
                insert projectTeamList;
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTriggerHelper.class.getName() ,
                'createProjectTeamRoles' ,
                e
            );
        }
    }

    public static void createProjectTeamRoles( List< pse__Proj__c> projectList ) {
        Set<Id> mmProjectIds = new Set<Id>();
        Set<Id> fsoProjectIds = new Set<Id>();
        Set<Id> hrScaleProjectIds = new Set<Id>();
        for ( pse__Proj__c project : projectList ) {
            // checking for MM and FSO Projects
            if ( ( project.pse__Project_Type__c == NSP_ServiceConstants.ImplementationProjectType )
                && !project.pse__Is_Template__c
                && ( project.recordTypeId == peoProjectRecordTypeId )
                && ( ( project.TemplateName__c == NSP_ServiceConstants.MM_PROJECT_TEMPLATE_KEY )
                    || ( project.TemplateName__c == NSP_ServiceConstants.FSO_PROJECT_TEMPLATE_KEY )
                    || ( project.TemplateName__c == NSP_ServiceConstants.HRSCALE_PROJECT_TEMPLATE_KEY )
                    )
                )
            {
                // creating maps from Project Id to List of Project Team Roles...
                if ( project.TemplateName__c == NSP_ServiceConstants.MM_PROJECT_TEMPLATE_KEY ) {
                    mmProjectIds.add( project.Id );
                } else if ( project.TemplateName__c == NSP_ServiceConstants.FSO_PROJECT_TEMPLATE_KEY ) {
                    fsoProjectIds.add( project.Id );
                } else if ( project.TemplateName__c == NSP_ServiceConstants.HRSCALE_PROJECT_TEMPLATE_KEY ) {
                    hrScaleProjectIds.add( project.Id );
                }
            }
        }
        if ( !mmProjectIds.isEmpty()
            || !fsoProjectIds.isEmpty()
            || !hrScaleProjectIds.isEmpty()
            )
        {
            NSP_ProjectTriggerHelper.createProjectTeamRoles(
                mmProjectIds ,
                fsoProjectIds ,
                hrScaleProjectIds ,
                null
            );
        }
    }

    // update the project name for FSO and MM Projects
    public void updateProjectName(
        Map<Id,pse__Proj__c> newProjectMap ,
        Map<Id,pse__Proj__c> oldProjectMap ,
        Set <Id> projectSetId ,
        Id peoProjectRecordTypeId
        )
    {
        try {
            Map<Id,pse__Proj__c> projectAccountMap= new Map<Id,pse__Proj__c>(
                [
                    SELECT Id , pse__Account__c , pse__Account__r.Name
                    FROM pse__Proj__c
                    WHERE ( Id IN :projectSetId )
                ]
            );
            for ( pse__Proj__c project : newProjectMap.values() ) {
                if ( ( project.pse__Account__c != null )
                    && projectAccountMap.containsKey( project.Id )
                    && ( projectAccountMap.get( project.Id ) != null )
                    && ( project.pse__Account__c == projectAccountMap.get( project.Id ).pse__Account__c )
                    && ( projectAccountMap.get( project.Id ).pse__Account__r != null )
                    && !project.Name.contains( projectAccountMap.get( project.Id ).pse__Account__r.Name )
                    && ( project.pse__Project_Type__c == NSP_ServiceConstants.ImplementationProjectType )
                    && !project.pse__Is_Template__c
                    && ( project.recordTypeId == NSP_ProjectTriggerHelper.peoProjectRecordTypeId )
                    && projectAccountMap.containsKey( project.pse__Account__c )
                    && ( projectAccountMap.get( project.pse__Account__c ) != null )
                    && ( ( project.TemplateName__c == NSP_ServiceConstants.MM_PROJECT_TEMPLATE_KEY )
                        || ( project.TemplateName__c == NSP_ServiceConstants.FSO_PROJECT_TEMPLATE_KEY )
                        )
                    )
                {
                    project.Name = projectNameAsPerNamingConvention(
                        project.TemplateName__c ,
                        project.pse__Start_Date__c ,
                        projectAccountMap.get( project.pse__Account__c ).Name
                    );
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTriggerHelper.class.getName() ,
                'updateProjectName' ,
                e
            );
        }
    }

    // check whether the project is completed or not
    public void cloneTheOpenProjectTasks( Set<Id> prjctIdSet ) {
        try {
            Set<Id> completedPrjctList = new Set<Id>();
            if ( !prjctIdSet.isEmpty() ) {
                for ( pse__Project_Task__c prjTask : [
                            SELECT
                                Id ,
                                Name ,
                                NSP_Account__c ,
                                pse__Project__c ,
                                pse__Project__r.pse__Project_Status__c ,
                                pse__Project__r.pse__Project_Type__c,pse__Project__r.TemplateName__c,
                                pse__Project__r.recordTypeId,pse__Project__r.pse__Account__c ,
                                pse__Project__r.OwnerId ,
                                pse__Project__r.pse__Parent_Project__c ,
                                pse__Status__c
                            FROM pse__Project_Task__c
                            WHERE (
                                ( pse__Project__c IN :prjctIdSet )
                                AND ( pse__Project__r.pse__Project_Type__c = :NEWPROJECTTYPE )
                                AND ( pse__Project__r.TemplateName__c = :NSP_ServiceConstants.FSO_PROJECT_TEMPLATE_KEY )
                                AND ( pse__Project__r.recordTypeId = :PEOPROJECTTECORDTYPEID )
                                AND ( Name IN :PROJECTTASKNAMES )
                                AND ( pse__Status__c != :PROJECTTASKSTATUSCOMPLETE )
                                AND ( pse__Status__c != :PROJECTTASKSTATUSCANCELLED )
                            )
                        ]
                    )
                {
                    completedPrjctList.add( prjTask.pse__Project__c );
                }
            }
            if ( !completedPrjctList.isEmpty() && !System.isFuture() && !System.isBatch() ) {
                NSP_ProjectTriggerHelper.createProjectAndProjectTasks( completedPrjctList );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTriggerHelper.class.getName() ,
                'cloneTheOpenProjectTasks' ,
                e
            );
        }
    }

    /***********************************************************************************************
    * MethodName: createProjectAndProjectTasks
    * Description : This Method will Clone the existing project, if it is Status is completed and Create a new project with Open project Tasks
    * Story : STY-02092
    * Params: Set< Id > completedPrjctList
    * ********************************************************************************************/
    @future
    public static void createProjectAndProjectTasks(Set< Id > completedPrjctList){
        Map<String, String> mapOfOldIdNewId = new Map<String, String>();
        Map<Id, date> prjctAssetDateMap = new Map<Id, date>();
        Map<Id, Id> prjctPayRollSpecialistMap = new Map<Id, Id>();
        pse__Proj__c clonedPrjct;
        pse__Project_Task__c clonedPrjctTask;
        List<pse__Proj__c> clonedPrjctList = new List<pse__Proj__c>();
        List<pse__Project_Task__c> pPrctTasksToUpdate = new List<pse__Project_Task__c>();
        List<pse__Project_Task__c> clonedPrjctTaskList = new List<pse__Project_Task__c>();
        set<id> prjActId = new Set<Id>();

        try{
            for(NSP_Project_Team__c prjteam : [SELECT Id, NSP_Assignee__c,
                                                NSP_Assignee__r.pse__Salesforce_User__c,
                                                NSP_Project__c,
                                                NSP_Role__c FROM NSP_Project_Team__c
                                                WHERE NSP_Project__c IN: completedPrjctList
                                                AND NSP_Role__c =: NSP_ServiceConstants.PAYROLL_SPECIALIST]){
                                                    prjctPayRollSpecialistMap.put(prjteam.NSP_Project__c, prjteam.NSP_Assignee__r.pse__Salesforce_User__c);
                                                }
            for ( pse__Proj__c prjc : [
                        SELECT
                            Id ,
                            pse__Account__c ,
                            OwnerId ,
                            TemplateName__c ,
                            pse__Parent_Project__c
                        FROM pse__Proj__c
                        WHERE ( Id IN :completedPrjctList )
                    ]
                )
            {
                Id payrollSpecialistId = prjctPayRollSpecialistMap.get( prjc.Id );
                clonedPrjct = new pse__Proj__c();
                clonedPrjct.Name = NEWPROJECTNAME;
                clonedPrjct.OwnerId = ( ( payrollSpecialistId != null ) ? payrollSpecialistId : prjc.OwnerId );
                clonedPrjct.pse__Start_Date__c = System.today();
                clonedPrjct.pse__End_Date__c = System.today().addDays( 60 );
                clonedPrjct.pse__Project_Type__c = NSP_ProjectTriggerHelper.NEWPROJECTTYPE;
                clonedPrjct.Layout_BOB__c = NSP_ProjectTriggerHelper.LAYOUTBOB_PEO_GENERIC;
                clonedPrjct.pse__Project_Status__c = NSP_ServiceConstants.STATUS_ACTIVE;
                clonedPrjct.pse__Is_Active__c = true;
                clonedPrjct.NSP_Exclusively_Assign_Owner__c = true; // Added as part of DF-02179
                clonedPrjct.pse__Account__c = prjc.pse__Account__c;
                clonedPrjct.recordTypeId = NSP_ProjectTriggerHelper.PEOPROJECTTECORDTYPEID;
                clonedPrjct.pse__Parent_Project__c = prjc.Id;
                clonedPrjctList.add( clonedPrjct );
                prjActId.add( prjc.pse__Account__c );
            }
            if(!clonedPrjctList.isEmpty()){
                Database.insert(clonedPrjctList);
                for(pse__Proj__c clPrj : [SELECT Id, pse__Parent_Project__c FROM pse__Proj__c WHERE ID IN: clonedPrjctList]){
                    mapOfOldIdNewId.put(clPrj.pse__Parent_Project__c, clPrj.Id);
                }
                for(Asset ast : [SELECT Id, AccountId,NSP_AIMS_First_Pay_Date__c FROM Asset WHERE AccountId IN: prjActId AND recordTypeId =: WORECORDTYPEID AND NSP_AIMS_First_Pay_Date__c >= TODAY]){
                    prjctAssetDateMap.put(ast.AccountId, ast.NSP_AIMS_First_Pay_Date__c);
                }
                if(!mapOfOldIdNewId.isEmpty()){
                        Map<String, Schema.SObjectField> fieldMap = pse__Project_Task__c.sObjectType.getDescribe().fields.getMap();
                    Set<String> setFieldNames = fieldMap.keySet();
                    list<String> lstFieldNames = new List<String>(setFieldNames);
                    list<string> keyList = new List<string>();
                    keyList.addAll(mapOfOldIdNewId.keySet());
                    String queryString = 'SELECT ' + String.join(lstFieldNames, ',') + ' ,pse__Project__r.pse__Account__c' +' FROM pse__Project_Task__c WHERE pse__Project__c IN :keyList' ;
                    queryString += ' AND NAME IN :PROJECTTASKNAMES';
                    queryString += ' AND pse__Status__c != \'Complete\' AND pse__Status__c != \'Canceled\'' ;
                    List<pse__Project_Task__c> prjtaskList =  Database.query(queryString);
                    for(pse__Project_Task__c prjctTask : prjtaskList ){
                        clonedPrjctTask = prjctTask.clone();
                        clonedPrjctTask.pse__Project__c = mapOfOldIdNewId.get(prjctTask.pse__Project__c);
                        clonedPrjctTask.pse__Task_Key_Chain__c = '';
                        clonedPrjctTask.pse__Task_Key__c = '';
                        clonedPrjctTask.pse__Milestone__c = null;
                        clonedPrjctTask.ownerId = prjctTask.OwnerId;
                        clonedPrjctTask.pse__End_Date_Time__c = prjctAssetDateMap.get(prjctTask.pse__Project__r.pse__Account__c) != null ? prjctAssetDateMap.get(prjctTask.pse__Project__r.pse__Account__c).addDays(60) : prjctTask.pse__End_Date_Time__c.addDays(60);
                        clonedPrjctTaskList.add(clonedPrjctTask);
                        prjctTask.pse__Status__c = 'Closed - Moved';
                        pPrctTasksToUpdate.add(prjctTask);
                    }
                }


                if(!clonedPrjctTaskList.isEmpty()){
                    NSP_ProjectTasksTriggerServiceHelper.runOwnerAssignmentLogic = false;
                    Database.insert(clonedPrjctTaskList);
                }
                if(!pPrctTasksToUpdate.isEmpty()){
                    Database.update(pPrctTasksToUpdate, false);
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTriggerHelper.class.getName() ,
                'createProjectAndProjectTasks' ,
                e
            );
        }
    }

    /**
    * Iterates throught the list of new Projects and passes the required attributes to other methods.
    * @param projectNewMap Map of New project.
    * @param projectOldMap Map of Old project.
    * @return void
    *
    */
    public void onCancelUpdateImplProfile(Set<Id> cancelledProjectIdsSet){
        List<Implementation_Profile__c> impProfilesToUpdate = new List<Implementation_Profile__c>();
        try{
            //Cancelled ProjectIds
            if(!cancelledProjectIdsSet.isEmpty()){
                for(Implementation_Profile__c impProfile : [SELECT Id, NSP_Inactive__c FROM Implementation_Profile__c WHERE NSP_Project__c IN: cancelledProjectIdsSet AND NSP_Inactive__c = false WITH SECURITY_ENFORCED FOR UPDATE]){
                    impProfile.NSP_Inactive__c = true;
                    impProfilesToUpdate.add(impProfile);
                }
            }
            //update Ips
            if(!impProfilesToUpdate.isEmpty() && Schema.sObjectType.Implementation_Profile__c.isUpdateable()){
                Database.update(impProfilesToUpdate,false);
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTriggerHelper.class.getName() ,
                'onCancelUpdateImplProfile' ,
                e
            );
        }
    }

    //
    // MethodName: updateAssetProductSegment
    // Description : This Method updates the product segment on Asset
    // Params: List< pse__Proj__c> projectList ,  Map<Id,pse__Proj__c> oldProjectMap
    // Author : Nischay Jindal
    //
    public static void updateAssetProductSegment( Set<Id> projectIdSet , Map<String,String> projectAssetRecordTypeMap ) {
        try {
            if( ( projectIdSet != null ) && !projectIdSet.isEmpty() ) {
                Map<Id,Asset> updateAssetMap = new Map<Id,Asset>();
                for ( Project_Asset__c prjAst : [
                            SELECT
                                Id ,
                                Asset__c ,
                                Asset__r.RecordType.DeveloperName ,
                                Asset__r.NSP_Product_Segment__c ,
                                Project__c ,
                                Project__r.TemplateName__c ,
                                Project__r.NSP_Client_Size__c
                            FROM Project_Asset__c
                            WHERE (
                                ( Project__c IN :projectIdSet )
                                AND (
                                    ( Asset__r.Status = :NSP_ServiceConstants.ASSET_ONBOARDING_STATUS )
                                    OR ( Asset__r.Status = :NSP_ServiceConstants.ASSET_ACTIVE_STATUS )
                                )
                            )
                        ]
                    )
                {
                    if ( NSP_ProjectTriggerHelper.isValidProjectAsset( prjAst , projectAssetRecordTypeMap )
                        && !updateAssetMap.containsKey( prjAst.Asset__c )
                        )
                    {
                        // prevent ~ ListException: Duplicate id in list...
                        updateAssetMap.put(
                            prjAst.Asset__c ,
                            new Asset(
                                Id=prjAst.Asset__c ,
                                NSP_Product_Segment__c=prjAst.Project__r.NSP_Client_Size__c
                            )
                        );
                    }
                }
                if ( !updateAssetMap.isEmpty() ) {
                    // throws ~ System.DmlException: FIELD_CUSTOM_VALIDATION_EXCEPTION, You don't have the permission to edit this field: [NSP_Product_Segment__c]
                    List<Database.SaveResult> results = Database.update( updateAssetMap.values() , false );
                    NSP_ErrorLogHandler.logResults(
                        NSP_ProjectTriggerHelper.class.getName() ,
                        'updateAssetProductSegment:update' ,
                        results
                    );
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTriggerHelper.class.getName() ,
                'updateAssetProductSegment' ,
                e
            );
        }
    }

    /***********************************************************************************************
    * MethodName:   isValidProjectAsset
    * Description : This Method updates check the valid asset Status
    * Params:       Project_Asset__c prjAst , Map<String,String>projectAssetRecordTypeMap
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    private static Boolean isValidProjectAsset(Project_Asset__c prjAst , Map<String,String>projectAssetRecordTypeMap){
        Boolean isValidProject;
        if(projectAssetRecordTypeMap.containsKey(prjAst.Project__r.TemplateName__c)){
            if(  projectAssetRecordTypeMap.get(prjAst.Project__r.TemplateName__c) == NSP_ServiceConstants.WX_WA ||
                    projectAssetRecordTypeMap.get(prjAst.Project__r.TemplateName__c) == NSP_ServiceConstants.ASSET_TT_RECORDTYPE ||
                    projectAssetRecordTypeMap.get(prjAst.Project__r.TemplateName__c) == NSP_ServiceConstants.APPLICANT_TRACKING_RECORD_TYPE||
                    projectAssetRecordTypeMap.get(prjAst.Project__r.TemplateName__c) == NSP_ServiceConstants.ASSET_OP_RECORDTYPE||
                    projectAssetRecordTypeMap.get(prjAst.Project__r.TemplateName__c) == NSP_ServiceConstants.PERFORMANCE_ASSET ||
                    projectAssetRecordTypeMap.get(prjAst.Project__r.TemplateName__c) == NSP_ServiceConstants.INTEGRA_ASSET ||
                    projectAssetRecordTypeMap.get(prjAst.Project__r.TemplateName__c) == NSP_ServiceConstants.XML_ASSET){
            }
            isValidProject = true;
        }
        return isValidProject;
    }

    /** Added as a part of STY-3842
     * Iterates throught the list of Project and Update Project Task Account.
         *Method Name:relatedProjectTaskUpdate
        * @param projectNewMap List of new Projects.
        * @param projectOldMap map of Old Projects
        * @return void
    **/
    public static void relatedProjectTaskUpdate(Set<Id> setofProjAccId,Map<Id, pse__Proj__c> projectNewMap,Map<Id, pse__Proj__c> projectOldMap ){

        List<pse__Project_Task__c> listOfProjectTask = new List<pse__Project_Task__c>();
        for(pse__Project_Task__c ptObj : [SELECT id,NSP_Account_Id__c,pse__Project__c from pse__Project_Task__c WHERE pse__Project__c IN: setofProjAccId]){
            if(ptObj.NSP_Account_Id__c == projectOldMap.get(ptObj.pse__Project__c).pse__Account__c){
                ptObj.NSP_Account_Id__c = projectNewMap.get(ptObj.pse__Project__c).pse__Account__c;
                listOfProjectTask.add(ptObj);
            }
        }
        if ( !listOfProjectTask.isEmpty() ) {
            Database.SaveResult[] results = Database.update( listOfProjectTask , false );
            NSP_ErrorLogHandler.logResults(
                NSP_ProjectTriggerHelper.class.getName() ,
                'relatedProjectTaskUpdate' ,
                results
            );
        }
    }

    /** Added as a part of STY-02064
     * Iterates throught the list of Project and Update Asset based on Project Asset and Order of Project.
         *Method Name:relatedAssetUpdate
        * @param newProjects List of new Projects.
        * @param oldProjects map of Old Projects
        * @return void
    **/
    public static void relatedAssetUpdate( Set<Id> activeAssetProjectId,Set<Id> backoutAssetProjectId,Set<String> projectTemplateNames,Map<String,String> mapofRecordTypevsTemplate  ){

        Map<Id,Asset> mapofAsset = new Map<Id,Asset>();

        try{
            // Iterate through the Orders based on the project and remove the Project Id based on the Order
            if(!backoutAssetProjectId.isEmpty() || !activeAssetProjectId.isEmpty() ) {
                for(Order orderObj : [SELECT id,NSP_Project__c,Status
                                    FROM Order
                                    WHERE NSP_Project__c IN: backoutAssetProjectId OR NSP_Project__c IN: activeAssetProjectId]){
                    if(activeAssetProjectId.contains(orderObj.NSP_Project__c)){
                        activeAssetProjectId.remove(orderObj.NSP_Project__c);
                    }
                    if(backoutAssetProjectId.contains(orderObj.NSP_Project__c) && orderObj.Status != 'Activated'){
                        backoutAssetProjectId.remove(orderObj.NSP_Project__c);
                    }
                }

            // Get the Asset record based on Project Asset and assign the Status based on the requirements
                for(Project_Asset__c projObj : [SELECT id, Asset__c, Asset__r.Status, Project__c,Asset__r.RecordType.DeveloperName
                                                FROM Project_Asset__c WHERE
                                                (Project__c IN:activeAssetProjectId OR Project__c IN:backoutAssetProjectId)]){
                                                    if(mapofRecordTypevsTemplate.containsKey(projObj.Asset__r.RecordType.DeveloperName)){
                                                        if(projObj.Asset__r.Status ==  NSP_ServiceConstants.ASSET_ONBOARDING_STATUS && activeAssetProjectId.contains(projObj.Project__c)){
                                                            Asset obj = new Asset();
                                                            obj.id = projObj.Asset__c;
                                                            obj.Status = NSP_ServiceConstants.ASSET_ACTIVE_STATUS;
                                                            mapofAsset.put(obj.id,obj);
                                                        }else if(backoutAssetProjectId.contains(projObj.Project__c)){
                                                            Asset obj = new Asset();
                                                            obj.id = projObj.Asset__c;
                                                            obj.Status = NSP_ServiceConstants.ASSETBLACKOUT;
                                                            mapofAsset.put(obj.id,obj);
                                                        }
                                                    }
                                                }
            }
            // Update the Asset Record
            if ( !mapofAsset.isEmpty() ) {
                Database.SaveResult[] results = Database.update( mapofAsset.values() , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ProjectTriggerHelper.class.getName() ,
                    'relatedAssetUpdate' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTriggerHelper.class.getName() ,
                'relatedAssetUpdate' ,
                e
            );
        }
    }

    /***********************************************************************************************
    * MethodName  : afterUpdateHCMField
    * Description : This Method creates a case and sends an email when the TES_HCM_Implementation_Support_Tasks__c
    * field is updated to 'Bank Audit Task' for the first time
    * * Params:     : Set<Id> prjctIdSet
    * Story : STY-02183
    * ********************************************************************************************/

    public void afterUpdateHCMField(Set<Id> prjctIdSet){
        String queueType = 'Queue';
        List<Case> caseList = new List<Case>();
        List<String> sendToList = new List<String>{System.Label.NSP_iSolved_HCM_Case_Completion_Email};
        List<String> emailTempFields = new List<String>{
                    'ID',
                    'BrandTemplateId',
                    'Subject',
                    'HTMLValue',
                    'Body',
                    'DeveloperName'
        };
        List<String> fields = new List<String>{'Id'};
        try{
            EmailTemplate emailTemplate = NSP_sObjectSelector.selectByDeveloperName(emailTempFields, 'NSP_iSolved_HCM_Audit_Case_Created');
        List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
            Id wXIMPLCaseRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Case', 'NSP_WX_IMPL');
            Group wXIMPLSupportQueue = NSP_sObjectSelector.selectGroupByTypeAndApiName(queueType, NSP_ServiceConstants.WX_IMPL_SUPPORT, fields);



            //Create a case when TES_HCM_Implementation_Support_Tasks__c is updated to 'Bank Audit Task' for the first time
            for(pse__Proj__c projRec: [SELECT Id, Name FROM pse__Proj__c WHERE Id IN: prjctIdSet]){
                    Case newCase = new Case();
                    newCase.RecordTypeId = WXIMPLCaseRecordTypeId;
                    newCase.Subject = NSP_ServiceConstants.BANK_AUDIT_CASE_SUBJECT + projRec.Name;
                    newCase.OwnerId = WXIMPLSupportQueue.Id;
                    newCase.Status = NSP_ServiceConstants.OPEN;
                    newCase.NSP_Case_Sub_Status__c = NSP_ServiceConstants.CASE_SUB_STATUS_NOT_STARTED;
                    newCase.NSP_Opened_Date__c = System.today();
                    newCase.Priority = NSP_ServiceConstants.MEDIUM;
                    newCase.NSP_Category__c = NSP_ServiceConstants.CASE_WX_WA;
                    newCase.NSP_SubCategory__c = NSP_ServiceConstants.CASE_SUB_CATEGORY_PROJECTS;
                    newCase.NSP_Detail__c = NSP_ServiceConstants.CASE_DETAIL_BANK_AUDIT;
                    newCase.NSP_Data_Template__c = NSP_ServiceConstants.BANK_AUDIT_CASE_CREATION_SUBJECT;
                    newCase.NSP_Assigned_Queue__c = NSP_ServiceConstants.CASE_ASIGNED_QUEUE_WX_IMPL_SUPPORT;
                    newCase.Project__c = projRec.Id;
                    caseList.add(newCase);
            }
            if(!caseList.isEmpty()){
                Database.insert(caseList, false);
            }
            //After creating a case fire an email to 'TESImplementationSupport@insperity.com'
            for(Case caseRec: caseList){
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email= Messaging.renderStoredEmailTemplate(emailTemplate.Id, null , caseRec.Id);
                email.setTemplateId(emailTemplate.Id);
                email.setToAddresses(sendToList);
                email.setWhatId(caseRec.Id);
                email.setSaveAsActivity(false);
                email.setOrgWideEmailAddressId(Label.NSP_OrgWideEmail_Insperity);
                lstEmailMessages.add(email);
            }
            if ( !lstEmailMessages.isEmpty()
                && EmailDeliverabilityController.isEnabledOutbound
                )
            {
                Messaging.sendEmail( lstEmailMessages );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTriggerHelper.class.getName() ,
                'afterUpdateHCMField' ,
                e
            );
        }
    }

    /***********************************************************************************************
    * MethodName:   createWXProject
    * Description :
    * Params:       List<pse__Proj__c>projectList
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    public static void createWXProject(Set<Id> projectIdSet ){
        Set<Id> wxProjectIdSet = new Set<Id>();
        List<String> toAddress = new List<String>{label.NSP_WXCarrierEmail};
        Map<Id,pse__Proj__c> wxProjectMap = new Map<Id,pse__Proj__c> ();
        List<pse__Proj__c> wxPrjList = new  List<pse__Proj__c>();

        if(!projectIdSet.isEmpty()){
            for(pse__Proj__c wxPrj :[Select Id  ,TemplateName__c , pse__Parent_Project__c FROM pse__Proj__c WHERE TemplateName__c =: NSP_ServiceConstants.WxCarrierConnectionProject AND pse__Parent_Project__c IN:projectIdSet AND pse__Is_Template__c = false  ]){
                wxProjectMap.put(wxPrj.pse__Parent_Project__c ,wxPrj);
            }

            List<String> emailFields = new List<String>{'Id','Name', 'DeveloperName', 'HtmlValue', 'Subject', 'Body'};

            EmailTemplate emailTemp = NSP_sObjectSelector.selectByDeveloperName(emailFields, NSP_ServiceConstants.wxEmailTemplate);

            Template_Key_and_Id_Mapping__mdt keyWithTemplateId = [SELECT Key__c, Template_ID__c, Template_Name__c
                                                                FROM Template_Key_and_Id_Mapping__mdt
                                                                WHERE Key__c =:NSP_ServiceConstants.WxCarrierConnectionProject];

            for(pse__Proj__c prj :[Select Id ,pse__Account__c,pse__Account__r.Name,TemplateName__c FROM pse__Proj__c WHERE Id IN:projectIdSet]){
            if(!wxProjectMap.containsKey(prj.Id)){
                String wxProjectId = createProjectwithTemplate(keyWithTemplateId,System.Today());
                wxProjectIdSet.add(wxProjectId);
                pse__Proj__c wxProject = new pse__Proj__c();
                wxProject.Id = wxProjectId;
                wxProject.TemplateName__c = NSP_ServiceConstants.WxCarrierConnectionProject;
                wxProject.pse__Parent_Project__c = prj.Id;
                if(prj.pse__Account__c!=null){
                    wxProject.name = prj.pse__Account__r.Name + ': ' + NSP_ServiceConstants.WxCarrierConnectionProject;
                    wxProject.pse__Account__c = prj.pse__Account__c;
                } else {
                    wxProject.name = NSP_ServiceConstants.WxCarrierConnectionProject;
                }
                wxProject.Name = NSP_ProjectTriggerHelper.safeProjectName( wxProject.Name );
                wxPrjList.add( wxProject );
            }
        }
            if ( !wxPrjList.isEmpty() ) {
                List<Database.UpsertResult> results = Database.upsert( wxPrjList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ProjectTriggerHelper.class.getName() ,
                    'createWXProject:upsertResults' ,
                    results
                );
                for ( Database.upsertResult result : results ) {
                    if ( result.isSuccess() ) {
                        sendMail(
                            emailTemp.Subject ,
                            emailTemp.HtmlValue ,
                            toAddress ,
                            null ,
                            result.getId() ,
                            emailTemp.Id
                        );
                    }
                }
            }
            if ( !wxProjectIdSet.isEmpty() ) {
                List<pse__Budget__c> budget = [
                    SELECT Id
                    FROM pse__Budget__c
                    WHERE ( pse__Project__c IN :wxProjectIdSet )
                ];
                Database.DeleteResult[] results = Database.delete( budget , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ProjectTriggerHelper.class.getName() ,
                    'createWXProject:deleteResults' ,
                    results
                );
            }
        }
    }

    /***********************************************************************************************
    * MethodName: createProjectwithTemplate
    * Description : Helper method to create Project From Template
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    public static Id createProjectwithTemplate(Template_Key_and_Id_Mapping__mdt keyWithTemplateId, Date projectStartdate){
        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest projRequest =
        new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest(keyWithTemplateId.Template_ID__c, projectStartdate);
        //Set new project name to specified name
        projRequest.ProjectName = keyWithTemplateId.Template_Name__c;
        projRequest.Mappers = new List<pse.SObjectCloneMapper>{
            NSP_CreateProjFromFlow.getDefaultMappers()
        };
        //Call the service and create project
        List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse = pse.CreateProjectFromTemplateService.createProjectsFromTemplates(
            new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest>{ projRequest }
        );
        return CreateProjectFromTemplateAction.handleCreateProjectResponse(
            NSP_ProjectTriggerHelper.class.getName() ,
            'createProjectwithTemplate' ,
            projResponse
        );
    }

    /**
    * @description  : create a account project request and map name, ownerId of the project record and return the request
    * @param: account record, project template record, account team record
    * @return: finacial API of creating a project from template and account request
    */

    public static pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest createProjectFromAsset(Account oaccount, pse__proj__c oprojectTemplate, NSP_Account_Team__c oaccountTeam){
        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest projRequest = new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest(oaccount.Id, oprojectTemplate.Id , System.Today());
        //assigning the values
        projRequest.ProjectName = oprojectTemplate.Template_Name__c;
        projRequest.Mappers = new List<pse.SObjectCloneMapper>{
            NSP_CreateProjFromFlow.getDefaultMappers()
        };
        projRequest.IsActive = true;
        projRequest.ProjectOwnerId = oaccountTeam.NSP_User__c;
        return projRequest;
    }

    /***********************************************************************************************
    * MethodName: sendMail
    * Description : Helper method for email body
    * Params:       String subjectString, String mailBody, list<String> listOfTOAddresses, String fromAddress, Id targetId, Id templateId
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    private static void sendMail(String subjectString, String mailBody, list<String> listOfTOAddresses, String fromAddress, Id targetId, Id templateId){
        //set template structure for the email template
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        if(listOfTOAddresses!=null && listOfTOAddresses.size()>0){
            email.setToAddresses(listOfTOAddresses);
        }
        if(targetId!=null && !String.isBlank(targetId)){
            email.setWhatId(targetId);
        }
        if(templateId!=null && !String.isBlank(templateId)){
            email.setTemplateId(templateId);
        }
        email.setTargetObjectId(UserInfo.getUserId());
        email.setTreatTargetObjectAsRecipient(false);
        try {
            if ( EmailDeliverabilityController.isEnabledOutbound ) {
                Messaging.sendEmail( new Messaging.SingleEmailMessage[]{ email } );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTriggerHelper.class.getName() ,
                'sendMail' ,
                e
            );
        }
    }

    // method to return project name as per naming convention
    private String projectNameAsPerNamingConvention( String projectName , Date startDate , String accountName ) {
        String prjName = '';
        if ( String.isNotBlank( projectName ) ) {
            if ( projectName == NSP_ServiceConstants.MM_PROJECT_TEMPLATE_KEY ) {
                prjName = projectName;
            } else if ( startDate != null ) {
                prjName = projectName + ' - ' + startDate.month() + '.' + startDate.day() + '.' + startDate.year();
            }
        }
        if ( String.isNotBlank( prjName ) && String.isNotBlank( accountName ) ) {
            prjName = prjName + ' - '+ accountName;
        }
        return prjName;
    }

    /***********************************************************************************************
    * MethodName: createPEOCase
    * Description : Helper method to create peo case for ITA implementation project
    * Params:       MAP<ID, ID> Project Id, Account Id
    * Created Date :      01/05/2023 created as part of story STY-03820
    * ********************************************************************************************/
    public void createPEOCase(Map<Id, Id> projectAccountMap){
        try{
            if(!projectAccountMap.values().isEmpty()){
                Date last90thDay = Date.today()-90;
                Map<Id, Asset> accountAssetIdMap = new Map<Id, Asset>();
                //fetch the account ids if the account has active wo asset and its first pay date is atleast less than 90 days
                for(Asset woAsset: [SELECT Id,AccountId FROM Asset
                                    WHERE RecordTypeId=:WORECORDTYPEID
                                    AND NSP_Account_Status__c=: NSP_ServiceConstants.AIMS_STATUS
                                    AND NSP_AIMS_First_Pay_Date__c <=  :last90thDay
                                    AND AccountId in :projectAccountMap.values()]){
                                        accountAssetIdMap.put(woAsset.AccountId , woAsset);


                }
                if(accountAssetIdMap.size()>0){
                    List<String> fields = new List<String>{'Id', 'Type','DeveloperName'};
                    //if active asset exist for account fetch group id for HR Shared group services
                    Id hrSharedQueueId = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.GroupType, NSP_ServiceConstants.HR_SHARED_QUEUE, fields).Id;
                    List<Case> peoCaseList = new List<Case>();

                    for(Id projectId :projectAccountMap.keyset() ){
                        //create peo case for each project id
                        if(accountAssetIdMap.keyset().contains(projectAccountMap.get(projectId))){
                            Asset woAsset =accountAssetIdMap.get(projectAccountMap.get(projectId));
                            Case peoCase   = createCase();
                            peoCase.OwnerId = hrSharedQueueId;
                            peoCase.AssetId = woAsset.Id;
                            if(woAsset.AccountId!=null){
                                peoCase.AccountId =woAsset.AccountId;
                            }
                            peoCaseList.add(peoCase);

                        }
                    }
                    if ( !peoCaseList.isEmpty() ) {
                        List<Database.SaveResult> results = Database.insert( peoCaseList , false );
                        NSP_ErrorLogHandler.logResults(
                            NSP_ProjectTriggerHelper.class.getName() ,
                            'createPEOCase' ,
                            results
                        );
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTriggerHelper.class.getName() ,
                'createPEOCase' ,
                e
            );
        }
    }

    /***********************************************************************************************
    * MethodName: createCase
    * Description : return  case fields values
    * Params:
    * Created Date :      01/05/2023 created as part of story STY-03820
    * ********************************************************************************************/

    private static Case createCase(){
        Case peoCase   = new Case();
                        peoCase.Origin = NSP_ServiceConstants.CANCELLED_REASON;
                        peoCase.NSP_Opened_Date__c = SYSTEM.TODAY();
                        peoCase.Priority  = NSP_ServiceConstants.MEDIUM;
                        peoCase.Status = NSP_ServiceConstants.OPEN;
                        peoCase.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
                        peoCase.Subject = NSP_ServiceConstants.PEO_CASE_SUBJECT;
                        peoCase.NSP_Category__c = NSP_ServiceConstants.INFRASTRUCTURE;
                        peoCase.NSP_SubCategory__c = NSP_ServiceConstants.PTO;
                        peoCase.RecordTypeId = casePEORecordTypeId;

        return peoCase;

    }

/**********************************************************************************************
/* MethodName: createItaCqaCaseAndSendEmail
/* Description : This method describes about the creation of ITQ CQA case, if the peer review status is changed to "Sent to Review"
/* Params:       Set<Id> sentToReviewPrjctIdSet
/* Story:        STY-01785
/* ********************************************************************************************/
    @future
    private static void createItaCqaCaseAndSendEmail(Set<Id> sentToReviewPrjctIdSet){

        Map<Id, Id> prjctIdCaseIdMap = new Map<Id,Id>();
        List<case> itaCqaCaseList = new List<case>();
        Case itaCqaCase;
        List<Messaging.SingleEmailMessage> emailMessageList = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<String> toAddressList = new List<String>();

        for(Case cse : [SELECT Id, recordTypeId, Project__c, ParentId FROM Case WHERE Project__c IN: sentToReviewPrjctIdSet AND recordTypeId =: itaCqaRecordTypeId
                                AND ParentId = null]){
                                    prjctIdCaseIdMap.put(cse.Project__c, cse.Id); // Framing map of Project and ITA CQA Case
        }

        for(pse__Proj__c prj : [SELECT Id FROM pse__Proj__c WHERE Id IN: sentToReviewPrjctIdSet]){
            // checking if the project is containg ITA CQA case or not
                if(prjctIdCaseIdMap.isEmpty() || prjctIdCaseIdMap.get(prj.Id) == null){
                    itaCqaCase = createItaCqaCase(prj.Id);
                    itaCqaCaseList.add(itaCqaCase);
                }
        }

        if(!itaCqaCaseList.isEmpty()){
            List<Database.SaveResult> results = Database.insert(itaCqaCaseList,false);
            NSP_ErrorLogHandler.logResults(
                NSP_ProjectTriggerHelper.class.getName() ,
                'createItaCqaCaseAndSendEmail' ,
                results
            );

            // get Org Wide address
            List<String> orgWideFields = new List<String>{'Id','Address','DisplayName'};
            String query = new NSP_QueryBuilder('OrgWideEmailAddress', orgWideFields)
                .addFilter('DisplayName', System.label.NSP_no_reply).addLimit(1).setSecurityEnforce(false).build();
            OrgWideEmailAddress orgWidAddress = Database.query(query);

            //get Email Template
            List<String> emailTempFields = new List<String>{'ID'};
            EmailTemplate emailTemplate = NSP_sObjectSelector.selectByDeveloperName(emailTempFields, 'NSP_ITA_CQA_Case_Creation_Template');
            toAddressList.add(System.Label.NSP_ITA_CQA_Team_Shared_box);

            if(emailTemplate != null && !toAddressList.isEmpty() && !itaCqaCaseList.isEmpty()){
                for(Case cse: [SELECT Id FROM Case WHERE Id IN: itaCqaCaseList]){
                    email= Messaging.renderStoredEmailTemplate(emailTemplate.Id, null , cse.Id);
                    email.setTreatTargetObjectAsRecipient(false);
                    email.setTargetObjectId(userInfo.getUserId());
                    email.setTemplateId(emailTemplate.Id);
                    email.setToAddresses(toAddressList);
                    email.setWhatId(cse.Id);
                    email.setSaveAsActivity(false);
                    email.setOrgWideEmailAddressId(orgWidAddress.Id);
                    emailMessageList.add(email);
                }
            }

            if ( !emailMessageList.isEmpty()
                && EmailDeliverabilityController.isEnabledOutbound
                )
            {
                NSP_GenericEmailUtility.sendSingleEmailMessages( emailMessageList , false );
            }
        }
    }

    /**********************************************************************************************
    * MethodName: createItaCqaCase
    * Description : This method describes about the creation of ITA CQA case record Instance
    * Params:       Id prjId
    * Story:        STY-01785
    * ********************************************************************************************/
    private static case createItaCqaCase (Id prjId){

     List<String> fields = new List<String>{'Id'};
     Group itaCqaQueue = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.GroupType, NSP_ServiceConstants.NSP_ITA_CQA, fields);

     Case itaCqaCase = new Case();
     itaCqaCase.Subject = NSP_ServiceConstants.MASTER_CQA_TASK;
     itaCqaCase.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
     itaCqaCase.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
     itaCqaCase.OwnerId = itaCqaQueue.Id;
     itaCqaCase.Priority = NSP_ServiceConstants.MEDIUM;
     itaCqaCase.recordTypeId = itaCqaRecordTypeId;
     itaCqaCase.NSP_CQA_Issue_Type__c = NSP_ServiceConstants.MASTER_CQA_TASK;
     itaCqaCase.NSP_Category__c = NSP_ServiceConstants.CATEGORY_TIME_ATTENDANCE;
     itaCqaCase.NSP_SubCategory__c = NSP_ServiceConstants.SUB_CATEGORY_ITA_CQA;
     itaCqaCase.Project__c = prjId;

     return itaCqaCase;
    }

   /**********************************************************************************************
    * MethodName: updateProjOwnerForPEOBillable
    * Description : This method to update owner field on project for PEO billable RT
    * Params:       List<pse__Proj__c> projectList,List<ID> projAccountIDs
    * Story:        STY-04002
    * ********************************************************************************************/

     private static void updateProjOwnerForPEOBillable (List<pse__Proj__c> projectList,List<ID> projAccountIDs){
         Map<ID,ID> acctTeamPrjOwnerMap = new Map<ID,ID>();
        // get Account team record related to project's account, with Role as MHRS , get the user linked to the record
         if(!projAccountIDs.isEmpty()){
             for(NSP_Account_Team__c acctTeam: [Select ID, NSP_Role__c, NSP_User__c,NSP_Account__c FROM NSP_Account_Team__c WHERE NSP_Account__c IN : projAccountIDs AND NSP_Role__c = : NSP_ServiceConstants.MANAGER_HRSERVICES ]){
                 if(acctTeam.NSP_User__c != null){
                     acctTeamPrjOwnerMap.put(acctTeam.NSP_Account__c, acctTeam.NSP_User__c) ;
                 }
             }
         }
          // loop through the project and assign project's owner field as per the condition
         for(pse__Proj__c  proj:projectList){
              // check for project owner field
             if(proj.NSP_ProjectOwner__c != null) {
                 proj.OwnerId =  proj.NSP_ProjectOwner__c ;
             }
             // else check for user field from account team
             else if(!acctTeamPrjOwnerMap.isEmpty() && acctTeamPrjOwnerMap.containsKey(proj.pse__Account__c)){
                 proj.OwnerId = acctTeamPrjOwnerMap.get(proj.pse__Account__c);
             }
         }
     }

    //
    // MethodName: handleBeforeDeleteOfProjTemp
    // Description : Helper method to check before deleting a project
    // Params: List<pse__Proj__c> projects
    // Created as part of STY-04554
    //
    public void handleBeforeDeleteOfProjTemp( List<pse__Proj__c> projects ) {
        String errorMessage = 'You do not have permission to delete project templates';
        try {
            List<String> userList = new List<String>{ 'Id' , 'Name' , 'NSP_Service_Stakeholder__c' };
            String query = new NSP_QueryBuilder( 'User' , userList )
                .addFilter( 'Id' , UserInfo.getUserId() )
                .addLimit( 1 )
                .setSecurityEnforce( false )
                .build();
            User userDetails = Database.query( query );
            for ( pse__Proj__c project : projects ) {
                if ( project.pse__Is_Template__c
                    && !userDetails.Name.contains( 'Deployment' )
                    && !userDetails.NSP_Service_Stakeholder__c
                    )
                {
                    //After the custom label gets deployed please change the below line to
                    //project.addError(System.Label.NSP_ProjTemplateDeleteError);
                    project.addError( errorMessage );
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTriggerHelper.class.getName() ,
                'handleBeforeDeleteOfProjTemp' ,
                e
            );
        }
    }

     /***********************************************************************************************
    * MethodName  : updateProjOwnerForServicePlanProjectType
    * Description : Helper method to assign owner for Service Plan Project based on Account Segments.
    * Params      : List<pse__Proj__c> servicePlanProjectsList,Set<ID> servicePlanAccountIDs
    * Created as part of STY-04589
    * ********************************************************************************************/
    private static void updateProjOwnerForServicePlanProjectType( List<pse__Proj__c> servicePlanProjectsList , Set<Id> servicePlanAccountIDs ) {
        //Creating a map for Account Team Role and Account Segment from NSP_Segment_Role_Mapping__mdt
        List<String> segmentRoleMappingFields = new List<String>{ 'NSP_Segment_Type__c' , 'NSP_Account_Team_Role__c' };
        String querySegmentRoleMetaData = new NSP_QueryBuilder( 'NSP_Segment_Role_Mapping__mdt' , segmentRoleMappingFields )
            .setSecurityEnforce( False )
            .build();
        Map<String,String> acccountTeamRoleSegmentTypeMap = new Map<String,String>();
        for(NSP_Segment_Role_Mapping__mdt segmentRoleRecords : Database.query(querySegmentRoleMetaData)){
            acccountTeamRoleSegmentTypeMap.put(segmentRoleRecords.NSP_Segment_Type__c,segmentRoleRecords.NSP_Account_Team_Role__c);
        }

        List<String> accounTeamFields = new List<String>{'Id', 'NSP_Role__c', 'NSP_User__c', 'NSP_Primary__c', 'NSP_Account__c', 'NSP_Account__r.NSP_Service_Segment__c'};
        String queryAccTeam = new NSP_QueryBuilder('NSP_Account_Team__c', accounTeamFields)
            .addFilter('NSP_Account__c', new List<Id>(servicePlanAccountIDs), NSP_QueryBuilder.Operator.INCLUDES)
            .addFilter('NSP_Role__c', new List<String>(acccountTeamRoleSegmentTypeMap.values()), NSP_QueryBuilder.Operator.INCLUDES)
            .orderBy('NSP_Primary__c', 'asc', true).build();

        //Creating map with Account and Account Team Role User.
        Map<Id, Id> accountWithTeamMemberId = new Map<Id,Id>();
        for(NSP_Account_Team__c acctTeam: Database.query(queryAccTeam)){
            if(acccountTeamRoleSegmentTypeMap.keySet().contains(acctTeam.NSP_Account__r.NSP_Service_Segment__c) &&
               acccountTeamRoleSegmentTypeMap.get(acctTeam.NSP_Account__r.NSP_Service_Segment__c) == acctTeam.NSP_Role__c &&
               acctTeam.NSP_User__c != null){
                   accountWithTeamMemberId.put(acctTeam.NSP_Account__c, acctTeam.NSP_User__c);
               }
        }

        //Assigning project owner based on account segment
        for(pse__Proj__c project: servicePlanProjectsList){
            if(accountWithTeamMemberId.keySet().contains(project.pse__Account__c) && !accountWithTeamMemberId.isEmpty()){
                project.OwnerId = accountWithTeamMemberId.get(project.pse__Account__c);
            }else{
                project.OwnerId = UserInfo.getUserId();
            }
        }
    }

}
