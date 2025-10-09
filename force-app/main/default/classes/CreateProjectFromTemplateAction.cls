public with sharing class CreateProjectFromTemplateAction {
    // test w/ CreateProjectFromTemplateActionTest (83%)

    @InvocableMethod(
        label='Create Project from Template Service'
        description='Leverage Financial Force Service API to create a Project from a Project Template'
        category ='Create Project'
    )
    public static List<Response> createProjectFromTemplate( List<Request> requestList ) {
        // execute the FinancialForce Service API
        Id projectId = null;
        if( ( requestList != null ) && ( requestList.size() > 0 ) ) {
            projectId = CreateProjectFromTemplateAction.createProjectFromAsset(
                requestList[0].oaccount ,
                requestList[0].oprojectTemplate ,
                requestList[0].ouser
            );
        }
        // Build the invocable action response
        Response localResponse = null;
        if ( projectId != null ) {
            localResponse = new Response();
            localResponse.projectId = projectId;
        }
        List<Response> responseList = new List<Response>();
        if ( localResponse != null ) {
            responseList.add( localResponse );
        }
        return responseList;
    }

     public class Request {
        @InvocableVariable(label='Account' description='Account on which the Project is created' required=true)
        public Account oaccount;
        @InvocableVariable(label='Project Template' description='Template of the Project' required=true)
        public pse__proj__c oprojectTemplate;
        @InvocableVariable(label='User' description='User to set as Project Owner' required=true)
        public User ouser;
    }

    public class Response {
        @InvocableVariable(label='Project Id' description='Id of Project created from the requested Project Template' required=true)
        public Id projectId;
    }


    //
    // @description  : create a account project request and map name, ownerId of the project record and return the request
    // @param: account record, project template record, account team record
    // @return: projectId
    //
    public static Id createProjectFromAsset( Account oaccount , pse__proj__c oprojectTemplate , User ouser ) {
        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest projRequest = new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest(oaccount.Id, oprojectTemplate.Id , System.Today());
        //assigning the values
        projRequest.ProjectName = oprojectTemplate.Template_Name__c;
        projRequest.IsActive = true;
        projRequest.ProjectOwnerId = ouser.Id;
        //Make a fieldMapper for the recordtypeId field on Project.
        pse.SObjectCloneMapper.Field recordtypeMapper = new pse.SObjectCloneMapper.Field(Schema.pse__Proj__c.recordtypeId);
        recordtypeMapper.DefaultValue = NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , 'PEO_Project' );
        pse.SObjectCloneMapper.Field recordtypeMapper1 = new pse.SObjectCloneMapper.Field(Schema.pse__Proj__c.NSP_Exclusively_Assign_Owner__c);
        recordtypeMapper1.DefaultValue = TRUE;
        pse.SObjectCloneMapper.Field mapperFieldBillable = new pse.SObjectCloneMapper.Field( Schema.pse__Proj__c.pse__Is_Billable__c );
        mapperFieldBillable.DefaultValue = false;
        Set<pse.SObjectCloneMapper.Field> setOfFields = new Set<pse.SObjectCloneMapper.Field>{
            recordtypeMapper ,
            recordtypeMapper1 ,
            mapperFieldBillable ,
            NSP_CreateProjFromFlow.getDefaultRegionMapperField()
        };
        //Make a mapper for the Project object
        pse.SObjectCloneMapper itemCloneMap = new pse.SObjectCloneMapper(pse__Proj__c.SObjectType, setOfFields);
        projRequest.Mappers = new List<pse.SObjectCloneMapper> { itemCloneMap };
        //Call the service and create project
        List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse = pse.CreateProjectFromTemplateService.createProjectsFromTemplates(
            new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest>{ projRequest }
        );
        return CreateProjectFromTemplateAction.handleCreateProjectResponse(
            CreateProjectFromTemplateAction.class.getName() ,
            'createProjectFromAsset' ,
            projResponse
        );
    }

    //
    //
    //

    public static Set<Id> handleCreateProjectResponses( String className , String methodName , List<pse.CreateProjectFromTemplateService.CreateProjectResponse> responses ) {
        Set<Id> newProjectIds = new Set<Id>();
        if ( ( responses != null ) && !responses.isEmpty() ) {
            for ( pse.CreateProjectFromTemplateService.CreateProjectResponse response : responses ) {
                Id newProjectId = CreateProjectFromTemplateAction.handleCreateProjectResponse( className , methodName , response );
                if ( newProjectId != null ) {
                    newProjectIds.add( newProjectId );
                }
            }
        }
        return newProjectIds;
    }

    public static Id handleCreateProjectResponse( String className , String methodName , List<pse.CreateProjectFromTemplateService.CreateProjectResponse> responses ) {
        Id newProjectId = null;
        if ( ( responses != null ) && !responses.isEmpty() ) {
            newProjectId = CreateProjectFromTemplateAction.handleCreateProjectResponse( className , methodName , responses[0] );
        }
        return newProjectId;
    }

    private static Id handleCreateProjectResponse( String className , String methodName , pse.CreateProjectFromTemplateService.CreateProjectResponse response ) {
        Id newProjectId = null;
        if ( response != null ) {
            if ( response.isSuccess() ) {
                newProjectId = response.NewProjectId;
            } else {
                if ( ( response.Errors != null ) && !response.Errors.isEmpty() ) {
                    for ( pse.CreateProjectFromTemplateService.CreateProjectError error : response.Errors ) {
                        NSP_ErrorLogHandler.logInfo(
                            className ,
                            methodName ,
                            error.Message
                        );
                    }
                }
            }
        }
        return newProjectId;
    }

}
//