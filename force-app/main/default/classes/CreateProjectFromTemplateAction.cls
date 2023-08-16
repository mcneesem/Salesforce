/* Apex class is used to Create Project from Template Using Financial Force API through Flow
Date : 06/21/2023 */

public class CreateProjectFromTemplateAction {
    
    @InvocableMethod(label='Create Project from Template Service' 
                     description='Leverage Financial Force Service API to create a Project from a Project Template'
                     category ='Create Project')
    
    public static List<Response> createProjectFromTemplate( List<Request> requestList ) {
        // execute the FinancialForce Service API
        Id projectId = null;
        if( ( requestList != null ) && ( requestList.size() > 0 ) ) {
                projectId = createProjectFromAsset(requestList[0].oaccount,
                                                   requestList[0].oprojectTemplate,
                                                   requestList[0].ouser);
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

    
    /**
    * @description  : create a account project request and map name, ownerId of the project record and return the request
    * @param: account record, project template record, account team record
    * @return: projectId
   */
    public static Id createProjectFromAsset(Account oaccount, pse__proj__c oprojectTemplate, User ouser){
        
        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest projRequest = new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest(oaccount.Id, oprojectTemplate.Id , System.Today());
        //assigning the values
        projRequest.ProjectName = oprojectTemplate.Template_Name__c;
        projRequest.IsActive = true;
        projRequest.ProjectOwnerId = ouser.Id;
        
        //Make a fieldMapper for the recordtypeId field on Project.
        pse.SObjectCloneMapper.Field recordtypeMapper = new pse.SObjectCloneMapper.Field(Schema.pse__Proj__c.recordtypeId);
        Id PEOPROJECTTECORDTYPEID = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
        recordtypeMapper.DefaultValue = PEOPROJECTTECORDTYPEID;
        
        pse.SObjectCloneMapper.Field recordtypeMapper1 = new pse.SObjectCloneMapper.Field(Schema.pse__Proj__c.NSP_Exclusively_Assign_Owner__c);
        recordtypeMapper1.DefaultValue = TRUE;
            
        Set<pse.SObjectCloneMapper.Field> setOfFields = new Set<pse.SObjectCloneMapper.Field>{recordtypeMapper,recordtypeMapper1};

        //Make a mapper for the Project object
        pse.SObjectCloneMapper itemCloneMap = new pse.SObjectCloneMapper(pse__Proj__c.SObjectType, setOfFields);
            
        projRequest.Mappers = new List<pse.SObjectCloneMapper> { itemCloneMap };
        
        //Call the service and create project
        List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse =
        pse.CreateProjectFromTemplateService.createProjectsFromTemplates( 
        new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest>{projRequest});        
        return projResponse[0].NewProjectId;
    }
}