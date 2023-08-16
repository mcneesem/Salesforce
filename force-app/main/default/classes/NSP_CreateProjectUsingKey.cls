/* Apex class is used to Create Project from Template Using Financial Force API
Date : 02/11/2021 */

public with sharing class NSP_CreateProjectUsingKey {

    /*This method will accept key and look for Template Id in Custom Metadata: Template_Key_and_Id_Mapping__mdt.
    * It will also delete Budgets, considered as part of STY-00954
    Date: 02/11/2021 */
    
    public static Id createProject(String Key, Date projectStartdate, String objApiName){
        List<Template_Key_and_Id_Mapping__mdt> keyWithTemplateId = [SELECT Key__c, Template_ID__c, Template_Name__c 
                                                                    FROM Template_Key_and_Id_Mapping__mdt
                                                                    WHERE Key__c = : key AND NSP_From_Object__c =: objApiName];

        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest projRequest =
        new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest(keyWithTemplateId[0].Template_ID__c, projectStartdate);
        //Set new project name to specified name
        projRequest.ProjectName = keyWithTemplateId[0].Template_Name__c;

        //Call the service and create project
        List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse =
        pse.CreateProjectFromTemplateService.createProjectsFromTemplates( 
        new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest>{projRequest});

        if(projResponse[0].NewProjectId != null){
            List<pse__Budget__c> budget = [SELECT id FROM pse__Budget__c WHERE pse__Project__c = :  projResponse[0].NewProjectId];
            if(!budget.isEmpty()){
            delete budget;
        }
        }

        return projResponse[0].NewProjectId;
    }
    

	/**
    * @description  : create a project from template request
    * @param: Id templateProjectId, Date startDateForProject, String projectName
    * @return: FinacialForce API of creating a project from template request
   */
    public static pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest createProjectFromTemplate(Id templateProjectId, Date startDateForProject, String projectName){
        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest projRequest =
                        new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest(templateProjectId, startDateForProject);
        //assigning the values
        projRequest.ProjectName = projectName;
		projRequest.IsActive = true;
        return projRequest;
    }
    
    /**
    * @description  : create a project and delete budget
    * @param: Id templateProjectId, Date startDateForProject, String projectName
    * @return: FinacialForce API of creating a project from template request
   */
    public static Set<Id> createProjectAndDeleteBudget(List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest> projRequestList){
        Set<Id> newProjectId = new Set<Id> ();
        
        //Call the service and create project
        List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse =
            pse.CreateProjectFromTemplateService.createProjectsFromTemplates(
                new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest>(projRequestList));
        
        for(pse.CreateProjectFromTemplateService.CreateProjectResponse response : projResponse){
            if( response.isSuccess() ){
                newProjectId.add(response.NewProjectId);
            }
        }
        
        // Deleting all Budgets Created with Projects
        if(!newProjectId.isEmpty()){
            List<pse__Budget__c> budgetList = [SELECT Id FROM pse__Budget__c WHERE pse__Project__c IN : newProjectId];
            DELETE budgetList;
        }
        
        return newProjectId;
    }
}