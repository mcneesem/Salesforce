/**************************************************************************************************   
Class Name :  NSP_FF_APIImpl_Test
Version              :  1.0                                                                          
Created Date         :   January 24, 2023                                                              
Function             :  This class is used as test class for NSP_FF_APIImpl
Test class           :  NSP_FF_APIImpl_Test
Story                :                                                                             
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* -------------------------------------------------------------------------------------------------  

*	          January 24, 2023          First Iteration
***************************************************************************************************/
@isTest
private class NSP_FF_APIImpl_Test {
    static NSP_FF_APIs implInstance = new NSP_FF_APIImpl();
    /**
    *  @Method Cover : NSP_FF_APIImpl.createProjectwithTemplate();           
    */
    @isTest
    static void createProjectwithTemplateTest(){
        List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest> project = new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest>();
        List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projectList = implInstance.createProjectwithTemplate(project);
        System.assert(projectList != null);
    }
    /**
    *  @Method Cover : NSP_FF_APIImpl.getProjectId();           
    */
    @isTest
    static void getProjectIdTest(){ 
        List<pse.CreateProjectFromTemplateService.CreateProjectResponse> project = new List<pse.CreateProjectFromTemplateService.CreateProjectResponse>();
        Id projectId = implInstance.getProjectId(project);
        System.assert(projectId == null);
    }
    /**
    *  @Method Cover : NSP_FF_APIImpl.getProjectIdSet();           
    */
    @isTest
    static void getProjectIdSetTest(){ 
        List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse =
            pse.CreateProjectFromTemplateService.createProjectsFromTemplates(new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest>{null, null, null});
        Set<Id> projectId = implInstance.getProjectIdSet(projResponse);
        System.assert(projectId != null);
    }
    /**
    *  @Method Cover : NSP_FF_APIImpl.createProjectFromTemplate();           
    */
    @isTest
    static void createProjectFromTemplateTest(){ 
        List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest> project = new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest>();
        List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projectList = implInstance.createProjectFromTemplate(project);
        System.assert(projectList != null);
    }
}