/**
 * @description  :  Mockclass for calling FF API's.
 * @date 07/15/2022
 * Author : Nischay Jindal & Nishkarsh
 * Name : Nsp_FFApiMock
 */
public class Nsp_FFApiMock implements NSP_FF_APIs {
    public static final Id PROJECT_ID = (Id) 'a2o3C000000ZMGNQA4';
    public Set<Id> projectIdSet;

    public Nsp_FFApiMock(){
        this.projectIdSet = new Set<Id>();
    }
    public Nsp_FFApiMock(Set<Id> projectIdSet){
        this.projectIdSet = projectIdSet;
    }
    public List<pse.CreateProjectFromTemplateService.CreateProjectResponse> createProjectwithTemplate(List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest> projects){
        return new List<pse.CreateProjectFromTemplateService.CreateProjectResponse>();
    }
    public Id getProjectId(List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projects){
        return PROJECT_ID;
    }
    public Set<Id> getProjectIdSet(List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projects){
        return projectIdSet;
    }
    public List<pse.CreateProjectFromTemplateService.CreateProjectResponse> createProjectFromTemplate(List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest> projects){
        return new List<pse.CreateProjectFromTemplateService.CreateProjectResponse>();
    }
}