public with sharing class CreateProjectFromTemplateAccount {
    // test w/ CreateProjectFromTemplateAccountTest (77%)


    @InvocableMethod(
        label='Create Project From Template And Account'
        description='Leverage Financial Force Service API to create a Project from a Project Template'
        category='Create Project'
    )
    public static List<Response> createProject( List<Request> requestList ) {
        List<Response> responseList = new List<Response>();
        if ( ( requestList != null ) && !requestList.isEmpty() ) {
            // Collect all Account and Template IDs
            List<Id> accountIds = new List<Id>();
            List<Id> templateIds = new List<Id>();
            for ( Request req : requestList ) {
                if ( req.oaccountId != null ) {
                    accountIds.add( req.oaccountId );
                }
                if ( req.oprojectTemplateId != null ) {
                    templateIds.add( req.oprojectTemplateId );
                }
            }
            // Query all Accounts
            Map<Id,Account> accountMap = new Map<Id,Account>(
                [
                    SELECT Id
                    FROM Account
                    WHERE ( Id IN :accountIds )
                ]
            );
            // Query all Templates
            Map<Id,pse__Proj__c> templateMap = new Map<Id,pse__Proj__c>(
                [
                    SELECT Id , Template_Name__c,Start_Date_Offset__c, RecordTypeId
                    FROM pse__Proj__c
                    WHERE (
                        ( pse__Is_Template__c = true )
                        AND ( Id IN :templateIds )
                    )
                ]
            );
            // Process each request
            for ( Request req : requestList ) {
                responseList.add(
                    CreateProjectFromTemplateAccount.processProjectRequest(
                        req ,
                        accountMap ,
                        templateMap
                    )
                );
            }
        }
        return responseList;
    }

    public class Request {
        @InvocableVariable(label='Account Id' description='Id of the Account on which the Project is created' required=true)
        public Id oaccountId;
        @InvocableVariable(label='Project Template Id' description='Id of the Project Template' required=true)
        public Id oprojectTemplateId;
    }

    public class Response {
        @InvocableVariable(label='Project Id' description='Id of Project created from the requested Project Template')
        public Id projectId;
        @InvocableVariable(label='Success' description='Indicates if the project was created successfully')
        public Boolean isSuccess;
        @InvocableVariable(label='Error Message' description='Error message if any occurred')
        public String errorMessage;
    }

    private static Response processProjectRequest( Request req , Map<Id,Account> accountMap , Map<Id,pse__Proj__c> templateMap ) {
        Response res = new Response();
        // Validate input parameters
        if ( ( req == null )
            || ( req.oaccountId == null )
            || ( req.oprojectTemplateId == null )
            )
        {
            res.isSuccess = false;
            res.errorMessage = 'Missing required inputs: Account Id or Project Template Id.';
        } else {
            // Validate records exist
            Account acc = accountMap.get( req.oaccountId );
            pse__proj__c template = templateMap.get( req.oprojectTemplateId );
            if ( ( acc == null ) || ( template == null ) ) {
                res.isSuccess = false;
                res.errorMessage = 'Account or Project Template not found for the provided inputs.';
            } else {
                // Create project
                try {
                    Id projectId = CreateProjectFromTemplateAccount.createProjectFromTemplate( acc , template );
                    if ( projectId != null ) {
                        res.projectId = projectId;
                        res.isSuccess = true;
                    } else {
                        res.isSuccess = false;
                        res.errorMessage = 'Project creation failed with no ID returned.';
                    }
                } catch ( Exception e ) {
                    res.isSuccess = false;
                    res.errorMessage = 'Exception: ' + e.getMessage();
                }
            }
        }
        return res;
    }

    private static Id createProjectFromTemplate( Account oaccount , pse__proj__c oprojectTemplate ) {
        Id resultId = null;
        if ( ( oaccount != null ) && ( oprojectTemplate != null ) ) {
             Date prjStartDate  = System.today();
            if ( ( oprojectTemplate != null ) && ( oprojectTemplate.Start_Date_Offset__c != null ) && ( oprojectTemplate.Start_Date_Offset__c > 0 )){
                 prjStartDate = prjStartDate.addDays( Integer.valueOf( oprojectTemplate.Start_Date_Offset__c ) );
            }
            pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest projRequest = new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest(
                oaccount.Id ,
                oprojectTemplate.Id ,
                prjStartDate
            );
            projRequest.ProjectName = oprojectTemplate.Template_Name__c;
            projRequest.IsActive = true;
            // Field mappers
            pse.SObjectCloneMapper.Field recordtypeMapper = new pse.SObjectCloneMapper.Field( Schema.pse__Proj__c.RecordTypeId );
            recordtypeMapper.DefaultValue = oprojectTemplate.RecordTypeId;
            Set<pse.SObjectCloneMapper.Field> setOfFields = new Set<pse.SObjectCloneMapper.Field>{
                recordtypeMapper ,
                NSP_CreateProjFromFlow.getDefaultRegionMapperField()
            };
            pse.SObjectCloneMapper itemCloneMap = new pse.SObjectCloneMapper(
                pse__Proj__c.SObjectType ,
                setOfFields
            );
            projRequest.Mappers = new List<pse.SObjectCloneMapper>{ itemCloneMap };
            List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse = pse.CreateProjectFromTemplateService.createProjectsFromTemplates(
                new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest>{ projRequest }
            );
            resultId = CreateProjectFromTemplateAction.handleCreateProjectResponse(
                CreateProjectFromTemplateAccount.class.getName() ,
                'createProjectFromTemplate' ,
                projResponse
            );
        }
        return resultId;
    }

}
//