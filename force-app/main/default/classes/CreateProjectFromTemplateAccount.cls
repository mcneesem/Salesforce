public with sharing class  CreateProjectFromTemplateAccount {

    // test w/ CreateProjectFromTemplateAccountTest (77%)
    @InvocableMethod(
        label='Create Project From Template Account'
        description='Leverage Financial Force Service API to create a Project from a Project Template'
        category='Create Project'
    )
    public static List<Response> createProject(List<Request> requestList) {
        List<Response> responseList = new List<Response>();

        if (requestList == null || requestList.isEmpty()) {
            return responseList;
        }

        // Collect all Account and Template IDs
        List<Id> accountIds = new List<Id>();
        List<Id> templateIds = new List<Id>();

        for (Request req : requestList) {
            if (req.oaccountId != null) accountIds.add(req.oaccountId);
            if (req.oprojectTemplateId != null) templateIds.add(req.oprojectTemplateId);
        }

        // Query all Accounts
        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id FROM Account WHERE Id IN :accountIds]
        );
		
		// Query all Templates
        Map<Id, pse__proj__c> templateMap = new Map<Id, pse__proj__c>(
            [SELECT Id, Template_Name__c,RecordTypeId FROM pse__proj__c WHERE pse__Is_Template__c = true AND Id IN :templateIds]
        );

        // Process each request
        for (Request req : requestList) {
            Response res = new Response();

            if (req.oaccountId == null || req.oprojectTemplateId == null) {
                res.isSuccess = false;
                res.errorMessages = new List<String>{'Missing required input fields: Account Id or Project Template Id'};
                responseList.add(res);
                continue;
            }

            Account acc = accountMap.get(req.oaccountId);
            pse__proj__c template = templateMap.get(req.oprojectTemplateId);

            if (acc == null || template == null) {
                res.isSuccess = false;
                res.errorMessages = new List<String>{'Account or Project Template not found for provided IDs'};
                responseList.add(res);
                continue;
            }

            try {
                Id projectId = createProjectFromTemplate(acc, template);
                if (projectId != null) {
                    res.projectId = projectId;
                    res.isSuccess = true;
                } else {
                    res.isSuccess = false;
                    res.errorMessages = new List<String>{'Project creation failed with no ID returned.'};
                }
            } catch (Exception e) {
                res.isSuccess = false;
                res.errorMessages = new List<String>{'Exception: ' + e.getMessage()};
            }

            responseList.add(res);
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

        @InvocableVariable(label='Error Messages' description='List of error messages if any occurred')
        public List<String> errorMessages;
    }

    public static Id createProjectFromTemplate(Account oaccount, pse__proj__c oprojectTemplate) {
        if (oaccount == null || oprojectTemplate == null) {
            return null;
        }

        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest projRequest =
            new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest(
                oaccount.Id, oprojectTemplate.Id, System.today()
            );

        projRequest.ProjectName = oprojectTemplate.Template_Name__c;
        projRequest.IsActive = true;
        
        // Field mappers
        pse.SObjectCloneMapper.Field recordtypeMapper = new pse.SObjectCloneMapper.Field(Schema.pse__Proj__c.recordtypeId);
        recordtypeMapper.DefaultValue = oprojectTemplate.recordtypeId;   

        Set<pse.SObjectCloneMapper.Field> setOfFields = new Set<pse.SObjectCloneMapper.Field>{
            recordtypeMapper,
            NSP_CreateProjFromFlow.getDefaultRegionMapperField()
        };

        pse.SObjectCloneMapper itemCloneMap = new pse.SObjectCloneMapper(pse__Proj__c.SObjectType, setOfFields);
        projRequest.Mappers = new List<pse.SObjectCloneMapper>{ itemCloneMap };

        List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse =
            pse.CreateProjectFromTemplateService.createProjectsFromTemplates(
                new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest>{ projRequest }
            );

        return handleCreateProjectResponse('CreateProjectFromTemplateAccount', 'createProjectFromTemplate', projResponse);
    }

    public static Id handleCreateProjectResponse(String className, String methodName, List<pse.CreateProjectFromTemplateService.CreateProjectResponse> responses) {
        if (responses == null || responses.isEmpty()) {
            return null;
        }

        pse.CreateProjectFromTemplateService.CreateProjectResponse response = responses[0];
        if (response.isSuccess()) {
            return response.NewProjectId;
        } else if (response.Errors != null && !response.Errors.isEmpty()) {
            for (pse.CreateProjectFromTemplateService.CreateProjectError error : response.Errors) {
                NSP_ErrorLogHandler.logInfo(className, methodName, error.Message);
            }
        }

        return null;
    }

}