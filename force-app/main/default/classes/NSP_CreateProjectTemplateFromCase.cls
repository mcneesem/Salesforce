/* Description : Class is used to create Project with Template
                based on Case Category value. This will be called
                from Case detail page button i.e. Project Setup.
    Date       : 05/10/2021 */
    
    public with sharing class NSP_CreateProjectTemplateFromCase {
        // Test w/ NSP_CreateProjectTemplateFromCaseTest (85%)

        /***********************************************************************************************
        * MethodName: insertProject
        * Params: String caseId
        * ********************************************************************************************/ 

        @AuraEnabled
        public static String insertProject(String caseId){
            try {
                Case getCase = null;
                Id projectId = null;
                List<Case> cases  = [SELECT NSP_Category__c FROM Case WHERE Id = : caseId];
                if (!cases.isEmpty()) {
                getCase = cases[0];
                projectId = NSP_CreateProjectUsingKey.createProject(getCase.NSP_Category__c, System.Today(), 'Case');
}
                if(projectId != null){
                    linkProjectWithCase(projectId, getCase.id);
                    return System.Label.NSP_Project_Created;
                } else{
                    return System.Label.NSP_Template_Not_Found;
                } 
            } catch (Exception exc) {
                return string.valueOf(exc.getMessage());
            } 
        }

        /***********************************************************************************************
        * MethodName: linkProjectWithCase
        * Params: Id projectId, String caseId
        * ********************************************************************************************/ 
    
        public static void linkProjectWithCase(Id projectId, String caseId){
            Id tesBpsRecordTypeId = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get('TES_BPS').getRecordTypeId();
    
            pse__Proj__c newProject = new pse__Proj__c();
            newProject.Id = projectId;
            newProject.Case__c = caseId;
            newProject.recordTypeId = tesBpsRecordTypeId;
            update newProject;
        }
    }