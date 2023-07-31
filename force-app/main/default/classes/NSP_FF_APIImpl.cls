/**
 * @description  :  class for calling FF API's.
 * @date 07/15/2022
 * Author : Nischay Jindal
 * Name : NSP_FF_APIImpl
 */
public class NSP_FF_APIImpl implements NSP_FF_APIs{
    /***********************************************************************************************
    * @MethodName: createProjectwithTemplate
    * @Description: This method will create Project record using template by 
    * 				utilizing FinancialForce API
    * @param : List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest> projects
    * @return: List<pse.CreateProjectFromTemplateService.CreateProjectResponse>                     
    *************************************************************************************************/
    public List<pse.CreateProjectFromTemplateService.CreateProjectResponse> createProjectwithTemplate(List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest> projects){
        return pse.CreateProjectFromTemplateService.createProjectsFromTemplates(projects);
    }
    
    /***********************************************************************************************
    * @MethodName: getProjectId
    * @Description: This method will return created project Id
    * @param : List<pse.CreateProjectFromTemplateService.CreateProjectResponse
    * @return: Id             
    *************************************************************************************************/
    public Id getProjectId(List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projects){
        return !projects.isEmpty() && projects[0].isSuccess() ? projects[0].NewProjectId : null;
    }
    
    /***********************************************************************************************
    * @MethodName: getProjectIdSet
    * @Description: This method will return created project Id set
    * @param : List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projects
    * @return: Set<Id>                  
    *************************************************************************************************/
    public Set<Id> getProjectIdSet(List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projects){
        Set<Id> projIds = new Set<Id>();
        for(pse.CreateProjectFromTemplateService.CreateProjectResponse projResponse : projects){
            if(projResponse.isSuccess()){
                projIds.add(projResponse.NewProjectId);
            }
        }
        return projIds;
    }
    
    /***********************************************************************************************
    * @MethodName: createProjectFromTemplate
    * @Description: This method will create Project record using template and Account request by
    * 				utilizing FinancialForce API
    * @param : List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest
    * @return: List<pse.CreateProjectFromTemplateService.CreateProjectResponse>                     
    *************************************************************************************************/
    public List<pse.CreateProjectFromTemplateService.CreateProjectResponse> createProjectFromTemplate(List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest> projects){
        return pse.CreateProjectFromTemplateService.createProjectsFromTemplates(projects);
    }
}