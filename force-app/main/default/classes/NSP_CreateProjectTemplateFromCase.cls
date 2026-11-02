public with sharing class NSP_CreateProjectTemplateFromCase {
    // test w/ NSP_CreateProjectTemplateFromCaseTest (90%)

    @AuraEnabled
    public static String insertProject( String caseId ) {
        try {
            List<Case> records  = [
                SELECT NSP_Category__c
                FROM Case
                WHERE ( Id = :caseId )
            ];
            Case record = null;
            if ( !records.isEmpty() ) {
                record = records[0];
            }
            Id projectId = null;
            if ( record != null ) {
                projectId = NSP_CreateProjectUsingKey.createProject(
                    record.NSP_Category__c ,
                    System.today() ,
                    'Case'
                );
            }
            String response = System.Label.NSP_Template_Not_Found;
            if ( projectId != null ) {
                NSP_CreateProjectTemplateFromCase.linkProjectWithCase( projectId , record.Id );
                response = System.Label.NSP_Project_Created;
            }
            return response;
        } catch ( Exception e ) {
            return string.valueOf( e.getMessage() );
        }
    }

    @testVisible
    private static void linkProjectWithCase( Id projectId , String caseId ) {
        pse__Proj__c newProject = new pse__Proj__c();
        newProject.Id = projectId;
        newProject.Case__c = caseId;
        newProject.recordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , 'TES_BPS' );
        update newProject;
    }

}
//
