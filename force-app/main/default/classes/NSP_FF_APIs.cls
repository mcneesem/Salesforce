/**
 * @description  :  Interface  for calling FF API's.
 * @date 07/15/2022
 * Author : Nischay Jindal & Nishkarsh
 * Name : Nsp_FFApiMock
 */
public interface NSP_FF_APIs {
	List<pse.CreateProjectFromTemplateService.CreateProjectResponse> createProjectwithTemplate(List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest> projects);
    Id getProjectId(List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projects);
    Set<Id> getProjectIdSet(List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projects);
    List<pse.CreateProjectFromTemplateService.CreateProjectResponse> createProjectFromTemplate(List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest> projects);
   
}