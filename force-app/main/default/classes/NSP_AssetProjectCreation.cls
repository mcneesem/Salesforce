public class NSP_AssetProjectCreation implements Queueable {
    // test w/ NSP_AssetServiceTriggerHelperTest (82%)
    // test w/ NSP_AssetTriggerHelperTest (35%)
    // test w/ NSP_UserTriggerHelper_Test (35%)

    private Set<Id> accountIdSet = new Set<Id>();
    private Set<Id> fsoAssetSet = new Set<Id>();
    private Set<Id> mmAssetSet = new Set<Id>();
    private Set<Id> woAssetIdSet = new Set<Id>();

    public NSP_AssetProjectCreation( Set<Id> woAssetIdSet , Set<Id> accountIdSet , Set<Id> fsoAssetSet , Set<Id> mmAssetSet ) {
        this.woAssetIdSet = woAssetIdSet;
        this.accountIdSet = accountIdSet;
        this.fsoAssetSet =  fsoAssetSet;
        this.mmAssetSet = mmAssetSet;
    }

    public void execute( QueueableContext qc ) {
        try {
            this.createImplementationProject(
                woAssetIdSet ,
                accountIdSet ,
                fsoAssetSet ,
                mmAssetSet
            );
        } catch ( Exception e ) {
            NSP_AssetProjectCreation.handleException( e , 'execute' );
        }
    }

    private List<pse__Proj__c> selectProjects( Set<Id> accountIdSet ) {
        List<pse__Proj__c> projectList = new List<pse__Proj__c>();
        if ( ( accountIdSet != null ) && !accountIdSet.isEmpty() ) {
            projectList = [
                SELECT Id , pse__Account__c
                FROM pse__Proj__c
                WHERE (
                    ( pse__Account__c IN :accountIdSet )
                    AND ( RecordTypeId = :NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , 'PEO_Project' ) )
                    AND ( pse__Project_Type__c = 'Implementation' )
                    AND (
                        ( TemplateName__c = :System.label.FSOImplementationProject )
                        OR ( TemplateName__c = :System.label.Middle_Market_Implementation_Project )
                    )
                )
            ];
        }
        return projectList;
    }

    //
    // MethodName: createImplementationProject
    // Description :  This method will create the implementation Project for MM , BT Core ,EG asset
    // Params:   Set<Id>woAssetIdSet,Set<Id>accountIdSet,Set<Id> fsoAssetSet,Set<Id> mmAssetSet
    //
    private void createImplementationProject( Set<Id> woAssetIdSet , Set<Id> accountIdSet , Set<Id> fsoAssetSet , Set<Id> mmAssetSet ) {
        try {
            List<pse__Proj__c> projectList = this.selectProjects( accountIdSet );
            // getting template from metadata
            Map<String,Template_Key_and_Id_Mapping__mdt> templateMap = new Map<String,Template_Key_and_Id_Mapping__mdt>();
            List<String> projectKeys = System.label.NSP_ProjectKeySet.split( ',' );
            Set<String> templateKeySet = new Set<String>();
            templateKeySet.addAll( projectKeys );
            List<Template_Key_and_Id_Mapping__mdt> templateList = [
                SELECT Key__c , Template_ID__c , Template_Name__c
                FROM Template_Key_and_Id_Mapping__mdt
                WHERE (
                    ( Key__c IN :templateKeySet )
                    AND ( NSP_From_Object__c = 'AssetOpportunity' )
                )
            ];
            for ( Template_Key_and_Id_Mapping__mdt template : templateList ) {
                templateMap.put( template.Key__c , template );
            }
            // checking if the asset has the active project
            List<pse__Proj__c> updatedProjectList = new List<pse__Proj__c>();
            List<Project_Asset__c> projectAssetMapping = new List<Project_Asset__c>();
            Id projectRecordType = NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , 'PEO_Project' );
            for ( Asset asset : [
                        SELECT
                            Id ,
                            RecordTypeId ,
                            NSP_Client_Segment_type__c ,
                            AccountId ,
                            Opportunity__c
                        FROM Asset
                        WHERE ( Id IN :woAssetIdSet )
                    ]
                )
            {
                if ( projectList.isEmpty() ) {
                    String templateType;
                    Id projectId;
                    Template_Key_and_Id_Mapping__mdt projectTemplateType = new Template_Key_and_Id_Mapping__mdt();
                    // checking for MM Assets
                    if ( mmAssetSet.contains( asset.Id ) ) {
                        projectTemplateType = templateMap.get( NSP_ServiceConstants.MM_PROJECT_TEMPLATE_KEY );
                        templateType = System.label.Middle_Market_Implementation_Project;
                        projectId = createProjectWithTemplateFromAsset( projectTemplateType , asset.Id );
                    } else if ( fsoAssetSet.Contains( asset.Id ) ) {
                        // checking for EG, BT, Core Assets
                        projectTemplateType = templateMap.get( NSP_ServiceConstants.FSO_PROJECT_TEMPLATE_KEY );
                        templateType = System.label.FSOImplementationProject;
                        projectId = createProjectWithTemplateFromAsset( projectTemplateType , asset.Id );
                    }
                    if ( projectId != null ) {
                        // Update Mid Market & FSO Project Data
                        updatedProjectList.add(
                            createProjectObject(
                                projectId ,
                                projectRecordType ,
                                asset.AccountId ,
                                templateType ,
                                asset.opportunity__c
                            )
                        );
                        //Update the project with its related entity.
                        projectAssetMapping.add( linkProjectWithAsset( projectId , asset.Id ) );
                    }
                }
            }
            if ( !updatedProjectList.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( updatedProjectList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AssetProjectCreation.class.getName() ,
                    'createImplementationProject:update' ,
                    results
                );
            }
            this.createImplementationProjectHelper( updatedProjectList );
            if ( !projectAssetMapping.isEmpty() ) {
                List<Database.UpsertResult> upsertResults = Database.upsert( projectAssetMapping , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AssetProjectCreation.class.getName() ,
                    'createImplementationProject:upsert' ,
                    upsertResults
                );
            }
        } catch ( Exception e ) {
            NSP_AssetProjectCreation.handleException( e , 'createImplementationProject' );
        }
    }

    private void createImplementationProjectHelper( List<pse__Proj__c> updatedProjectList ) {
        if ( ( updatedProjectList != null ) && !updatedProjectList.isEmpty() ) {
            Set<Id> projectIds = new Set<Id>();
            Set<Id> accIdSet = new Set<Id>();
            for ( pse__Proj__c prj : updatedProjectList ) {
                projectIds.add( prj.Id );
                if ( String.isNotBlank( prj.pse__Account__c ) ) {
                    accIdSet.add( prj.pse__Account__c );
                }
            }
            List<pse__Proj__c> impProjectList = new List<pse__Proj__c>();
            for ( pse__Proj__c impProj : [
                        SELECT
                            Id ,
                            pse__Project_Type__c ,
                            pse__Account__c ,
                            pse__Is_Template__c ,
                            RecordTypeId ,
                            TemplateName__c
                        FROM pse__Proj__c
                        WHERE ( Id IN :projectIds )
                    ]
                )
            {
                impProjectList.add( impProj );
            }
            NSP_ProjectTriggerHelper.createImplementationProfile( impProjectList , accIdSet );
            NSP_ProjectTriggerHelper.createProjectTeamRoles( impProjectList );
            NSP_AssetProjectCreation.setStartDateAndEndDateOnFSOImplProjectTask( projectIds );
        }
    }

    private Id createProjectWithTemplateFromAsset( Template_Key_and_Id_Mapping__mdt oTempKey , Id assetId ) {
        Id projectId = new NSP_AssetServiceTriggerHelper().createProjectWithTemplateFromAsset( oTempKey , assetId );
        return projectId;
    }

    // Method to link the entity to the project
    private static Project_Asset__c linkProjectWithAsset( Id projectId , Id assetId ) {
        Project_Asset__c newProject = new Project_Asset__c();
        newProject.Project__c = projectId;
        newProject.Asset__c = assetId;
        return newProject;
    }

    private static pse__Proj__c createProjectObject( Id projId , Id recordTypeId , Id accountId , String assetTemplateType , Id opportunityId ) {
        pse__Proj__c project = new pse__Proj__c();
        project.Id = projId;
        project.pse__Project_Status__c = NSP_ServiceConstants.ProjectStatus;
        project.pse__Account__c = accountId;
        project.RecordTypeId = recordTypeId;
        project.pse__Is_Billable__c = false;
        project.NSP_Asset_Implementation_Project__c= True;
        project.pse__Opportunity__c = opportunityId;
        if ( assetTemplateType == System.label.Middle_Market_Implementation_Project ) {
            project.pse__End_Date__c = System.Today().addDays( 180 );
        } else if ( assetTemplateType == System.label.FSOImplementationProject ) {
            project.pse__End_Date__c = System.Today().addDays( 90 );
        }
        return project;
    }

    //
    // Update Start Date and End date on Project Task when WO Asset are created
    // @param setOfProject List of project.
    // @return void
    //
    private static void setStartDateAndEndDateOnFSOImplProjectTask( Set<Id> setOfProject ) {
        Set<Id> setOfProjectId = new Set<Id>();
        Id projectRecordType = NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , 'PEO_Project' );
        Map<Id,pse__Proj__c> projectMap = new Map<Id,pse__Proj__c>();
        List<pse__Project_Task__c> projectTaskList = [
            SELECT Id , Name , pse__Project__c
            FROM pse__Project_Task__c
            WHERE ( pse__Project__c IN :setOfProject )
        ];
        for ( pse__Project_Task__c projectTask : projectTaskList ) {
            if ( projectTask.pse__Project__c != null && projectTask.NSP_Template_Generated__c ) {
                setOfProjectId.add( projectTask.pse__Project__c );
            }
        }
        if ( !setOfProjectId.isEmpty() ){
            for(pse__Proj__c project : [
                        SELECT
                            Id ,
                            TemplateName__c ,
                            pse__Project_Type__c ,
                            RecordTypeId ,
                            pse__Account__r.NSP_AIMS_Renewal_Date__c ,
                            pse__Start_Date__c ,
                            pse__End_Date__c
                        FROM pse__Proj__c
                        WHERE (
                            ( Id IN :setOfProjectId )
                            AND ( pse__Is_Template__c = false )
                        )
                    ]
                )
            {
                //check if project of type implementation and MM or FSO template
                if ( !projectMap.containsKey( project.Id )
                    && project.RecordTypeId == projectRecordType
                    && project.pse__Project_Type__c == NSP_ServiceConstants.ImplementationProjectType
                    && ( project.TemplateName__c == System.label.Middle_Market_Implementation_Project
                        || project.TemplateName__c == System.label.FSOImplementationProject
                        )
                    )
                {
                    projectMap.put( project.Id , project );
                }
            }
        }
        NSP_AssetProjectCreation.setStartDateEndDate( projectTaskList , projectMap );
    }

    // update start & end time of project task of type implementation and template MM or FSO
    @testVisible
    private static void setStartDateEndDate( List<pse__Project_Task__c> projectTaskList , Map<Id,pse__Proj__c> projectMap ) {
        if ( ( projectTaskList != null )
            && !projectTaskList.isEmpty()
            && ( projectMap != null )
            && !projectMap.isEmpty()
            )
        {
            for ( pse__Project_Task__c prTask : projectTaskList ) {
                // updating Project Start and End Date on Project Taks
                if ( ( prTask.pse__Project__c != null )
                    && projectMap.containsKey( prTask.pse__Project__c )
                    )
                {
                    prTask.pse__Start_Date_Time__c = DateTime.newInstance(
                        System.now().date() ,
                        Time.newInstance( 12 , 0 , 0 , 0 )
                    );
                    if ( projectMap.get( prTask.pse__Project__c ) != null ) {
                        prTask.pse__End_Date_Time__c = DateTime.newInstance(
                            projectMap.get( prTask.pse__Project__c ).pse__End_Date__c ,
                            Time.newInstance( 12 , 0 , 0 , 0 )
                        );
                    }
                }
            }
        }
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_AssetProjectCreation.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_AssetProjectCreation.class.getName() ,
            methodName ,
            e
        );
    }

}
//