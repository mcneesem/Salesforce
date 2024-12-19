// Apex class is used to Create Project from Template Using Financial Force API
// Date : 02/11/2021
public with sharing class NSP_CreateProjectUsingKey {
    // test w/ NSP_CreateProjectUsingKeyTest (100%)

    // This method will accept key and look for Template Id in Custom Metadata: Template_Key_and_Id_Mapping__mdt.
    // It will also delete Budgets, considered as part of STY-00954
    // Date: 02/11/2021
    public static Id createProject(String key, Date projectStartdate, String objApiName){
        List<Template_Key_and_Id_Mapping__mdt> keyWithTemplateId = [
            SELECT Key__c, Template_ID__c, Template_Name__c 
            FROM Template_Key_and_Id_Mapping__mdt
            WHERE Key__c = :key AND NSP_From_Object__c = :objApiName
        ];
        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest projRequest = new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest(
            keyWithTemplateId[0].Template_ID__c ,
            projectStartdate
        );
        //Set new project name to specified name
        projRequest.ProjectName = keyWithTemplateId[0].Template_Name__c;
        projRequest.Mappers = new List<pse.SObjectCloneMapper>{
            NSP_CreateProjFromFlow.getDefaultMappers()
        };
        //Call the service and create project
        List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse = pse.CreateProjectFromTemplateService.createProjectsFromTemplates(
            new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest>{ projRequest }
        );
        Id newProjectId = CreateProjectFromTemplateAction.handleCreateProjectResponse(
            NSP_CreateProjectUsingKey.class.getName() ,
            'createProject' ,
            projResponse
        );
        NSP_CreateProjectUsingKey.deleteProjectBudgets( new Set<Id>{ newProjectId } );
        return newProjectId;
    }

	//
    // @description  : create a project from template request
    // @param: Id templateProjectId, Date startDateForProject, String projectName
    // @return: FinacialForce API of creating a project from template request
    //
    public static pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest createProjectFromTemplate( Id templateProjectId , Date startDateForProject , String projectName ) {
        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest projRequest = new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest(
            templateProjectId ,
            startDateForProject
        );
        //assigning the values
        projRequest.ProjectName = projectName;
        projRequest.IsActive = true;
        projRequest.Mappers = new List<pse.SObjectCloneMapper>{
            NSP_CreateProjFromFlow.getDefaultMappers()
        };
        return projRequest;
    }

    //
    // @description  : create a project and delete budget
    // @param: Id templateProjectId, Date startDateForProject, String projectName
    // @return: FinacialForce API of creating a project from template request
    //
    public static Set<Id> createProjectAndDeleteBudget( List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest> projRequestList ) {
        //Call the service and create project
        List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse = pse.CreateProjectFromTemplateService.createProjectsFromTemplates(
            new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest>( projRequestList )
        );
        Set<Id> newProjectIds = CreateProjectFromTemplateAction.handleCreateProjectResponses(
            NSP_CreateProjectUsingKey.class.getName() ,
            'createProjectAndDeleteBudget' ,
            projResponse
        );
        NSP_CreateProjectUsingKey.deleteProjectBudgets( newProjectIds );
        return newProjectIds;
    }

    // deleting all budgets created for a set of projects...
    private static void deleteProjectBudgets( Set<Id> projectIds ) {
        if ( ( projectIds != null ) && !projectIds.isEmpty() ) {
            List<pse__Budget__c> budgetList = [
                SELECT Id
                FROM pse__Budget__c
                WHERE ( pse__Project__c IN : projectIds )
            ];
            delete budgetList;
        }
    }

}
//