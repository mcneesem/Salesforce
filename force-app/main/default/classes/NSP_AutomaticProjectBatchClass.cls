//
// @description  : Batch Class to create project whenever a asset with account id is not present
// Automatically Creating a Service Plan Project for a new client based on STY-01029
// @date 05/12/2022
//
public class NSP_AutomaticProjectBatchClass implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<SObject> , Database.Stateful {
    // test w/ NSP_AutomaticProjectBatchTest (83%)

    @TestVisible
    private NSP_OpportunityTriggerServiceHelper opp = new NSP_OpportunityTriggerServiceHelper();

    //
    // argument-free constructor is required to be "runnable"
    //

    public NSP_AutomaticProjectBatchClass() {
    }

    //
    // ISelfSchedulable
    //

    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_AutomaticProjectScheduler ~ Create an Engagement Plan Project based on an asset\'s AIMS\'s status and AIMS\'s status date ~ Schedule to Run Everyday 11 pm' + suffix ,
            '0 0 23 * * ?' ,
            new NSP_AutomaticProjectBatchClass()
        );
    }

    //
    // Schedulable
    //

    public void execute( SchedulableContext ctx ) {
        this.call( 'run' , null );
    }

    //
    // Callable
    //

    public Object call( String action , Map<String,Object> args ) {
        Object response = null;
        if ( action == 'run' ) {
            response = this.run();
        }
        return response;
    }

    //
    // IJobRunnable
    //

    public Id run() {
        return Database.executeBatch( new NSP_AutomaticProjectBatchClass() , 1 );
    }

    //
    // Batchable
    //

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        Set<Id> assetAccIdSet = new Set<Id>();
        List<Id> accountIdList = new List<Id>();
        List<String> accountFields = new List<String>{ 'Id' , 'Name' };
        //Storing asset wo record type Id
        Id assertWORTId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'WO' );
        //getting all the accountId with wo recordtype, active status and status date is today
        assetAccIdSet = NSP_AutomaticProjectBatchClass.getAssetAccountIds( assertWORTId );
        //checking whether accountId are empty
        if ( !assetAccIdSet.isEmpty() ) {
            //removing all the accountId with existing project
            accountIdList = NSP_AutomaticProjectBatchClass.getFilteredAccountsFromProjects( assetAccIdSet );
        }
        String query = new NSP_QueryBuilder( 'Account' , accountFields )
            .addFilter( 'Id' , accountIdList , NSP_QueryBuilder.Operator.INCLUDES )
            .build();
        return Database.getQueryLocator( query );
    }

    public void execute( Database.BatchableContext bc , List<Account> listAccount ) {
        try {
            Map<Id,Asset> accountIdAssetMap = new Map<Id,Asset>();
            List<pse__Proj__c> projList = new List<pse__Proj__c>();
            //mapping all the accountId adn asset object
            for ( Asset oasset : [
                        SELECT
                            Id ,
                            Name ,
                            AccountId ,
                            RecordTypeId ,
                            NSP_Account_Status__c ,
                            NSP_Account_Status_Date__c ,
                            NSP_Client_Segment_type__c
                        FROM Asset
                        WHERE (
                            NSP_Client_Segment_type__c != NULL
                            AND AccountId IN :listAccount
                            AND Status IN ( 'Active' , 'Onboarding' )
                        )
                    ]
                )
            {
                accountIdAssetMap.put( oasset.AccountId , oasset );
            }
            //iterating over the accountList
            for ( Account oAccount : listAccount ) {
                if ( accountIdAssetMap.containsKey( oAccount.Id )
                    && ( accountIdAssetMap.get( oAccount.Id ) != null )
                    )
                {
                    Asset oasset = accountIdAssetMap.get( oAccount.Id );
                    //checking for the client type and getting respective template and account team
                    pse__Proj__c oproject = NSP_AutomaticProjectBatchClass.checkingClientType( oasset , oAccount , opp );
                    if ( oproject != null ) {
                        projList.add( oproject );
                    }
                }
            }
            //updating all the project
            if ( !projList.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( projList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AutomaticProjectBatchClass.class.getName() ,
                    'execute:update' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AutomaticProjectBatchClass.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    public void finish( Database.BatchableContext bc ) {
        // execute any post-processing operations
    }

    //
    // @description  : get all the asset account Ids with WO RecordType, active status and status date is today
    // @param: Id of Asset wo recordType
    // @return: set of accountIds
    //
    private static Set<Id> getAssetAccountIds( Id assertWORTId ) {
        Set<Id> assetAccIdSet = new Set<Id>();
        List<String> assetFields = new List<String>{ 'Id' , 'AccountId' };
        //getting all the assets from record with filter from queryBuilder Class
        String query = new NSP_QueryBuilder( 'Asset' , assetFields )
            .addFilter( 'RecordTypeId' , String.valueOf( assertWORTId ) )
            .addFilter( 'NSP_Account_Status__c' , 'Active' )
            .addFilter( 'NSP_Account_Status_Date__c' , ( System.today() + '' ).split( ' ' )[0] , NSP_QueryBuilder.Operator.EQUALS , false )
            .build();
        List<Asset> assetsList = (List<Asset>)Database.query( query );
        for ( Asset oAsset : assetsList ) {
             assetAccIdSet.add( oAsset.AccountId );
        }
        return assetAccIdSet;
    }

    //
    // @description  : filtering all the accountId which doesn't have project
    // @param: set of accountIds
    // @return: List of accountIds
    //
    private static List<Id> getFilteredAccountsFromProjects( Set<Id> assetAccIdSet ) {
        Set<Id> accountFilter = new Set<Id>();
        List<Id> finalAccountId = new List<Id>();
        //getting all the accountId with existing project
        for ( pse__Proj__c oproject : [
                    SELECT Id , pse__Account__c
                    FROM pse__Proj__c
                    WHERE (
                        pse__Account__c IN :assetAccIdSet
                        AND pse__Is_Active__c = true
                        AND pse__Is_Template__c != true
                        AND pse__Project_Status__c NOT IN (
                            'Complete' ,
                            'Cancelled' ,
                            'Close/Lost'
                        )
                        AND pse__Project_Type__c = 'Service Plan'
                    )
                ]
            )
        {
            accountFilter.add( oproject.pse__Account__c );
        }
        //remove all the accountId with the project
        assetAccIdSet.removeAll( accountFilter );
        finalAccountId.addAll( assetAccIdSet );
        return finalAccountId;
    }

    //
    // @description  : getting all the Engagement Plan project templates and storing in a map with template name and project
    // @param: NA
    // @return: map<TemplateName, ProjectTemplateRecord>
    //
    private static List<Template_Key_and_Id_Mapping__mdt> getProjectTemplates( String keyValue ) {
        //getting project template of Engagement Plan project
        List<String> templateFields = new List<String>{
            'Id',
            'Key__c',
            'Template_ID__c',
            'Template_Name__c'
        };
        String query = new NSP_QueryBuilder( 'Template_Key_and_Id_Mapping__mdt' , templateFields )
            .addFilter( 'Key__c' , String.escapeSingleQuotes( keyValue ) )
            .addFilter( 'NSP_From_Object__c' , String.escapeSingleQuotes( 'AssetOpportunity' ) )
            .setSecurityEnforce( false )
            .build();
        List<Template_Key_and_Id_Mapping__mdt> oTempKey = (List<Template_Key_and_Id_Mapping__mdt>)Database.query( query );
        return oTempKey;
    }

    //
    // @description  : checking for the client type on Asset and create a project
    // @param: asset record, account record, map<TemplateName, ProjectTemplateRecord>, peo recordType id
    // @return: project record
    //
    private static pse__Proj__c checkingClientType( Asset oasset , Account oaccount , NSP_OpportunityTriggerServiceHelper opp ) {
        pse__Proj__c oproject;
        if ( oasset.NSP_Client_Segment_type__c == NSP_ServiceConstants.BTAssetSegment ) {
            //getting BT Engagement plan project from the method
            List<Template_Key_and_Id_Mapping__mdt> templateKeyList = NSP_AutomaticProjectBatchClass.getProjectTemplates( NSP_ServiceConstants.PROJECT_TEMPLATE_NAME );
            oproject = createEngagementProject(
                oAccount ,
                templateKeyList ,
                NSP_ServiceConstants.BTAssetSegment ,
                opp
            );
        }else if( oasset.NSP_Client_Segment_type__c == NSP_ServiceConstants.CoreAssetSegment
            || oasset.NSP_Client_Segment_type__c == NSP_ServiceConstants.EG100AssetSegment
            || oasset.NSP_Client_Segment_type__c == NSP_ServiceConstants.EG50AssetSegment
            )
        {
            //getting core Engagement plan project from the method
            List<Template_Key_and_Id_Mapping__mdt> templateKeyList = NSP_AutomaticProjectBatchClass.getProjectTemplates( NSP_ServiceConstants.PROJECT_CORE_TEMPLATE );
            oproject = createEngagementProject(
                oAccount ,
                templateKeyList ,
                NSP_ServiceConstants.CoreAssetSegment ,
                opp
            );
        }else if ( oasset.NSP_Client_Segment_type__c == NSP_ServiceConstants.MMAssetSegment ) {
            //getting Middle Market Engagement plan project from the method
            List<Template_Key_and_Id_Mapping__mdt> templateKeyList = NSP_AutomaticProjectBatchClass.getProjectTemplates( NSP_ServiceConstants.PROJECT_MM_90_DAY_EP_TEMPLATE );
            oproject = createEngagementProject(
                oAccount ,
                templateKeyList ,
                NSP_ServiceConstants.MMAssetSegment ,
                opp
            );
        }else if ( oasset.NSP_Client_Segment_type__c == NSP_ServiceConstants.MMEAssetSegment ) {
            //getting Middle Market Engagement plan project from the method
            List<Template_Key_and_Id_Mapping__mdt> templateKeyList = NSP_AutomaticProjectBatchClass.getProjectTemplates( NSP_ServiceConstants.PROJECT_MM_ENTERPRISE_EP_TEMPLATE );
            oproject = createEngagementProject(
                oAccount ,
                templateKeyList ,
                NSP_ServiceConstants.MMAssetSegment ,
                opp
            );
        }
        return oproject;
    }

    //
    // @description  : getting all the accountTeam of the against account Id and the role
    // @param: account Id and asset client segment type
    // @return: account team record
    //
    private static Id getAccountTeam( Id accountId , String typeClient ) {
        //mapping of clientType and role
        Map<String,String> clientTypeAccTeamRole = new Map<String,String>{
            NSP_ServiceConstants.BTAssetSegment => NSP_ServiceConstants.BUS_TEAM_HRSP_CL ,
            NSP_ServiceConstants.CoreAssetSegment => NSP_ServiceConstants.CLIENT_LIAISION ,
            NSP_ServiceConstants.MMAssetSegment => NSP_ServiceConstants.MID_MARKET_ACC_EX
        };
        List<NSP_Account_Team__c> oAccteam;
        String accountTeamObjectName = 'NSP_Account_Team__c';
        List<String> accTeamFields = new List<String>{
            'Id' ,
            'NSP_User__c'
        };
        //getting the account team of against role and accountId
        if ( clientTypeAccTeamRole.containsKey( typeClient ) ) {
            String query= new NSP_QueryBuilder( accountTeamObjectName , accTeamFields )
                .addFilter( 'NSP_Account__c' , String.valueOf( accountId ) )
                .addFilter( 'NSP_Role__c' , String.valueOf( clientTypeAccTeamRole.get( typeClient ) ) )
                .addLimit( 1 )
                .build();
            oAccTeam = (List<NSP_Account_Team__c>)Database.query( query );
        }
        //if the account team doesn't have the particular role then get Manager, HR Service
        if ( oAccteam.isEmpty() ) {
            String query= new NSP_QueryBuilder( accountTeamObjectName , accTeamFields )
                .addFilter( 'NSP_Account__c' , String.valueOf( accountId ))
                .addFilter( 'NSP_Role__c' , String.escapeSingleQuotes( NSP_ServiceConstants.MANAGER_HRSERVICES ) )
                .addLimit( 1 )
                .build();
            oAccTeam = (List<NSP_Account_Team__c>)Database.query( query );
        }
        Id response = UserInfo.getUserId();
        if ( oAccteam != null && !oAccteam?.isEmpty() ) {
            response = oAccteam[0]?.NSP_User__c;
        }
        return response;
    }

    //
    // @description  :creating project for Engagement Plan Project Template
    // @param: account Id and asset client segment type
    // @return: project record
    //
    private static pse__Proj__c createEngagementProject(
        Account oaccount ,
        List<Template_Key_and_Id_Mapping__mdt> templateKeyList ,
        String clientType ,
        NSP_OpportunityTriggerServiceHelper opp
        )
    {
        //getting account team record of the particular role
        Id userId = NSP_AutomaticProjectBatchClass.getAccountTeam( oAccount.Id , clientType );
        //calling NSP_CreateProjectUsingKey to create the project and it returns project
        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest projectrequest = new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest(
            oaccount.Id ,
            templateKeyList[0].Template_ID__c ,
            System.today()
        );
        //copy recordTypeId
        pse.SObjectCloneMapper.Field mapperFieldRT = new pse.SObjectCloneMapper.Field( Schema.pse__Proj__c.RecordTypeId );
        pse.SObjectCloneMapper.Field mapperFieldStartDate = new pse.SObjectCloneMapper.Field( Schema.pse__Proj__c.pse__Start_Date__c );
        pse.SObjectCloneMapper.Field mapperFieldEndDate = new pse.SObjectCloneMapper.Field( Schema.pse__Proj__c.pse__End_Date__c );
        Set<pse.SObjectCloneMapper.Field> setMapperFields = new Set<pse.SObjectCloneMapper.Field>{
            mapperFieldRT ,
            mapperFieldStartDate ,
            mapperFieldEndDate
        };
        pse.SObjectCloneMapper mapp = new pse.SObjectCloneMapper( pse__Proj__c.SObjectType , setMapperFields );
        projectrequest.Mappers = new List<pse.SObjectCloneMapper>{ mapp };
        projectrequest.ProjectOwnerId = userId;
        projectrequest.IsActive = true;
        List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest> lProjRequests = new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest>();
        lProjRequests.add( projectrequest );
        //checking whether the account request is empty
        pse__Proj__c response = null;
        if ( lProjRequests != null ) {
            //create a project and deleting Budget
            Set<Id> newProjectId = opp.createProjectAndDeleteBudget( lProjRequests );
            if ( ( newProjectId != null ) && !newProjectId.isEmpty() ) {
                List<Id> newProjectIdList = new List<Id>();
                newProjectIdList.addAll( newProjectId );
                if ( !newProjectIdList.isEmpty() ) { // prevent System.ListException: List index out of bounds: 0
                    //querying related project created by the NSP_OpportunityTriggerServiceHelper method
                    List<String> projField = new List<String>{
                        'Id' , 'Name' , 'OwnerId' ,
                        'RecordTypeId' , 'Template_Name__c' ,
                        'pse__Is_Billable__c' , 'pse__Account__c' ,
                        'pse__End_Date__c' , 'pse__Start_Date__c'
                    };
                    String query = new NSP_QueryBuilder( 'pse__Proj__c' , projField )
                        .addFilter( 'pse__Is_Template__c' , false )
                        .addFilter( 'pse__Is_Active__c' , true )
                        .addFilter( 'pse__Account__c' , String.valueOf( oaccount.Id ) )
                        .addFilter( 'Id' , newProjectIdList[0] , NSP_QueryBuilder.Operator.INCLUDES )
                        .addFilter( 'OwnerId' , userId )
                        .build();
                    List<pse__Proj__c> records = (List<pse__Proj__c>)Database.query( query ); // throws System.QueryException: invalid ID field: null
                    response = NSP_AutomaticProjectBatchClass.populateFields( records );
                }
            }
        }
        return response;
    }

    // helper method to defeat sonar cognitive complexity...
    private static pse__Proj__c populateFields( List<pse__Proj__c> records ) {
        pse__Proj__c response = null;
        if ( ( records != null ) && !records.isEmpty() ) {
            response = records[0];
            if ( ( response.pse__Start_Date__c != null )
                && ( response.pse__End_Date__c != null )
                )
            {
                Integer numberDays = response.pse__Start_Date__c.daysBetween( response.pse__End_Date__c );
                response.pse__End_Date__c = System.today() + numberDays;
            } else {
                response.pse__End_Date__c = null;
            }
            response.pse__Start_Date__c = System.today();
            response.pse__Is_Billable__c = false;
        }
        return response;
    }

}
//
