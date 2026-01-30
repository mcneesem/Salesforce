/**
* @description  :  Helper class for Project Team Trigger.
* @date 07/21/2022
* Author : Nischay Jindal
* Name : NSP_ProjectTeamTriggerHelper
*/
public with sharing class NSP_ProjectTeamTriggerHelper {
    // test w/ NSP_ProjectTeamTriggerHelperTest (88%)

    /***********************************************************************************************
    * MethodName: restrictDuplicateProjectTeamRecords
    * Description : Restrict Duplicate record creation on Project Team
    * Params:       List<NSP_Project_Team__c> newProjectTeamList
    * ********************************************************************************************/
    public static void restrictDuplicateProjectTeamRecords(List<NSP_Project_Team__c> newProjectTeamList){
        Set<Id> projIdset = new Set<Id>();
        Map<String, Id> mapRoleProjectId = new Map<String, Id>();
        try{
            // Search for PEO Project record Id
            Id PEORecordTypeId  = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
            // creating a set of Project Id
            for(NSP_Project_Team__c projTeam: newProjectTeamList){
                projIdset.add(projTeam.NSP_Project__c);
            }
            // searching for ProjectTeams related to Project
            List<NSP_Project_Team__c> projTeamList =  [SELECT Id, NSP_Role__c, NSP_Project__c FROM NSP_Project_Team__c
                                                       WHERE NSP_Project__r.pse__Project_Type__c=:NSP_ServiceConstants.ImplementationProjectType AND (NSP_Project__r.TemplateName__c = :NSP_ServiceConstants.MM_PROJECT_TEMPLATE_KEY OR NSP_Project__r.TemplateName__c = :NSP_ServiceConstants.FSO_PROJECT_TEMPLATE_KEY)
                                                       AND NSP_Project__r.RecordTypeId=:PEORecordTypeId AND NSP_Project__c in :projIdset];

            // creating a map of Role and Project Id
            for(NSP_Project_Team__c prjTeam: projTeamList){
                mapRoleProjectId.put(prjTeam.NSP_Role__c, prjTeam.NSP_Project__c);
            }
            for(NSP_Project_Team__c projTeam: newProjectTeamList){
                // checking for existing project team record related to project with same role
                if(mapRoleProjectId.containsKey(projTeam.NSP_Role__c) && mapRoleProjectId.get(projTeam.NSP_Role__c)==projTeam.NSP_Project__c){
                    // throw error message
                    projTeam.addError(label.NSP_ProjectTeamTriggerValidationMsg);
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTeamTriggerHelper.class.getName() ,
                'restrictDuplicateProjectTeamRecords' ,
                e
            );
        }
    }

    /***********************************************************************************************
    * MethodName: updateImplementationProfileRoles
    * Description : This Method will update Imp Profile Roles from the Project
    * Params:       Map<Id, pse__Proj__c> newPrjMap,Map<Id, pse__Proj__c> oldPrjMap
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    public static void updateImplementationProfileRoles(Map <Id, NSP_Project_Team__c >newPrjTeamMap, Map <Id, NSP_Project_Team__c >oldPrjTeamMap ){
        Map<String,Map<String,String>> mapProjectIdMapRoleContactId = new  Map<String,Map<String,String>> ();
        List < Implementation_Profile__c >  updateImpProfileList = new List < Implementation_Profile__c > ();
        Map < Id, List < Implementation_Profile__c >> mapAccountIdListImpProfile = new Map < Id, List < Implementation_Profile__c >> ();
        try{
            // store PEO Project Record Id
            Id PEORecordTypeId  = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
            for(NSP_Project_Team__c prjTeam :newPrjTeamMap.values()){
                if(prjTeam.NSP_Assignee__c != oldPrjTeamMap.get(prjTeam.Id).NSP_Assignee__c && prjTeam.NSP_Role__c!=null){
                    // creating map of Project Id and Map of Role and Contact Id
                    if(!mapProjectIdMapRoleContactId.containsKey(prjTeam.NSP_Project__c)){
                        mapProjectIdMapRoleContactId.put(prjTeam.NSP_Project__c, new Map<String,String>());
                    }
                    mapProjectIdMapRoleContactId.get(prjTeam.NSP_Project__c).put(prjTeam.NSP_Role__c,prjTeam.NSP_Assignee__c);
                }
            }
            // searching for PEO Projects
            Map<Id, pse__Proj__c> implProjectMap = new Map<Id, pse__Proj__c>([Select Id ,pse__Project_Type__c ,TemplateName__c,RecordTypeId ,pse__Account__c From pse__Proj__c
                                                                              WHERE  pse__Project_Type__c=:NSP_ServiceConstants.ImplementationProjectType AND
                                                                              (TemplateName__c = :NSP_ServiceConstants.MM_PROJECT_TEMPLATE_KEY OR TemplateName__c = :NSP_ServiceConstants.FSO_PROJECT_TEMPLATE_KEY)
                                                                              AND RecordTypeId=:PEORecordTypeId AND Id IN :mapProjectIdMapRoleContactId.KeySet()]);

            // Searching for IMp Profile related to Primary Project Account
            List<Implementation_Profile__c> impProfileList = [
                SELECT
                Id ,
                Account__c ,
                NSP_Project__c ,
                NSP_Project_Manager__c ,
                NSP_Orientation_Rep__c ,
                NSP_OS_Coordinator__c ,
                NSP_OT_Coordinator__c ,
                NSP_OT_Planner__c ,
                NSP_Payroll_Specialist__c ,
                NSP_Transition_Specialist__c ,
                NSP_Sr_Benefit_Rep__c ,
                NSP_Payroll_Project_Manager__c ,
                NSP_Sr_HR_Specialist__c ,
                NSP_Account_Executive__c ,
                NSP_Orientation_Coordinator__c ,
                NSP_OT_Representative__c ,
                NSP_Onboarding_Specialist_Coordinator__c ,
                NSP_Orientation_Planner__c ,
                NSP_Sr_Onboarding_Benefit_Rep__c ,
                NSP_HR_Specialist__c ,
                NSP_HR_Quality_Support_Team_Member__c
                FROM Implementation_Profile__c
                WHERE (
                    ( NSP_Project__c IN :implProjectMap.keySet() )
                    AND ( Account__c != null )
                )
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            for(Implementation_Profile__c impPrf:impProfileList){
                // creating map of Imp Profile Account Id and IMP Profile
                if (!mapAccountIdListImpProfile.containsKey(impPrf.Account__c)) {
                    mapAccountIdListImpProfile.put(impPrf.Account__c, new List<Implementation_Profile__c> ());
                }
                mapAccountIdListImpProfile.get(impPrf.Account__c).add(impPrf);
            }
            for(pse__Proj__c project:implProjectMap.values()){
                // Updating roles on Imp Profile and creating list of Imp Profiles to be updated
                if(mapAccountIdListImpProfile.containsKey(project.pse__Account__c) && mapProjectIdMapRoleContactId.containsKey(project.Id)){
                    Id impProfileId =mapAccountIdListImpProfile.get(project.pse__Account__c)[0].Id;
                   Implementation_Profile__c impProfile = updateImpRoles(project,mapProjectIdMapRoleContactId,impProfileId);
                    updateImpProfileList.add(impProfile);
                }
            }
            // update Imp Profile
            if(!updateImpProfileList.isEmpty()){
                database.update(updateImpProfileList) ;
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTeamTriggerHelper.class.getName() ,
                'updateImplementationProfileRoles' ,
                e
            );
        }
    }

    /***********************************************************************************************
    * MethodName: updateImpRoles
    * Description : Private method to assign roles to Imp Profile
    * Params:       pse__Proj__c project, Map<String,Map<String,String>> mapProjectIdMapRoleContactId, Map < Id, List < Implementation_Profile__c >> mapAccountIdListImpProfile
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    private static   Implementation_Profile__c   updateImpRoles(pse__Proj__c project, Map<String,Map<String,String>> mapProjectIdMapRoleContactId, Id impProfileId){

        Implementation_Profile__c impProfile = new Implementation_Profile__c();
        // updating Project Manager on Imp Profile
        if(mapProjectIdMapRoleContactId.get(project.Id).containsKey(NSP_ServiceConstants.ProjectManager)){
             impProfile.Id= impProfileId;
            impProfile.NSP_Project_Manager__c = mapProjectIdMapRoleContactId.get(project.Id).get(NSP_ServiceConstants.ProjectManager);
        }
        // updating Orientation Rep on Imp Profile
        if(mapProjectIdMapRoleContactId.get(project.Id).containsKey(NSP_ServiceConstants.OrientationRep)){
            impProfile.Id= impProfileId;
            impProfile.NSP_Orientation_Rep__c = mapProjectIdMapRoleContactId.get(project.Id).get(NSP_ServiceConstants.OrientationRep);
        }
        // updating Orientation Rep on Imp Profile
        if(mapProjectIdMapRoleContactId.get(project.Id).containsKey(NSP_ServiceConstants.OrientationRep)){
            impProfile.Id= impProfileId;
            impProfile.NSP_OT_Representative__c = mapProjectIdMapRoleContactId.get(project.Id).get(NSP_ServiceConstants.OrientationRep);
        }
        // updating Os Coordinator on Imp Profile
        if(mapProjectIdMapRoleContactId.get(project.Id).containsKey(NSP_ServiceConstants.OSCoordinator)){
             impProfile.Id= impProfileId;
            impProfile.NSP_Onboarding_Specialist_Coordinator__c = mapProjectIdMapRoleContactId.get(project.Id).get(NSP_ServiceConstants.OSCoordinator);
        }
        // updating Ot Coordinator on Imp Profile
        if(mapProjectIdMapRoleContactId.get(project.Id).containsKey(NSP_ServiceConstants.OTCoordinator)){
            impProfile.Id= impProfileId;
            impProfile.NSP_Orientation_Coordinator__c = mapProjectIdMapRoleContactId.get(project.Id).get(NSP_ServiceConstants.OTCoordinator);
        }
        // updating OT Planner on Imp Profile
        if(mapProjectIdMapRoleContactId.get(project.Id).containsKey(NSP_ServiceConstants.OTPlanner)){
            impProfile.Id= impProfileId;
            impProfile.NSP_Orientation_Planner__c = mapProjectIdMapRoleContactId.get(project.Id).get(NSP_ServiceConstants.OTPlanner);
        }
        // updating Payroll Specialist on Imp Profile
        if(mapProjectIdMapRoleContactId.get(project.Id).containsKey(NSP_ServiceConstants.PayrollSpecialist)){
             impProfile.Id= impProfileId;
            impProfile.NSP_Payroll_Specialist__c = mapProjectIdMapRoleContactId.get(project.Id).get(NSP_ServiceConstants.PayrollSpecialist);
        }
        // updating Transition Specialist on Imp Profile
        if(mapProjectIdMapRoleContactId.get(project.Id).containsKey(NSP_ServiceConstants.TransitionSpecialist)){
             impProfile.Id= impProfileId;
            impProfile.NSP_Transition_Specialist__c = mapProjectIdMapRoleContactId.get(project.Id).get(NSP_ServiceConstants.TransitionSpecialist);
        }
        // updating Sr Benefit Rep on Imp Profile
        if(mapProjectIdMapRoleContactId.get(project.Id).containsKey(NSP_ServiceConstants.SrBenefitRep)){
            impProfile.Id= impProfileId;
            impProfile.NSP_Sr_Onboarding_Benefit_Rep__c = mapProjectIdMapRoleContactId.get(project.Id).get(NSP_ServiceConstants.SrBenefitRep);
        }
        // updating Payroll Project Manager on Imp Profile
        if(mapProjectIdMapRoleContactId.get(project.Id).containsKey(NSP_ServiceConstants.PayrollProjectManager)){
            impProfile.Id= impProfileId;
            impProfile.NSP_Payroll_Project_Manager__c = mapProjectIdMapRoleContactId.get(project.Id).get(NSP_ServiceConstants.PayrollProjectManager);
        }
        // updating Sr HR Specialist on Imp Profile
        if(mapProjectIdMapRoleContactId.get(project.Id).containsKey(NSP_ServiceConstants.SrHrSpecialist)){
             impProfile.Id= impProfileId;
            impProfile.NSP_HR_Specialist__c = mapProjectIdMapRoleContactId.get(project.Id).get(NSP_ServiceConstants.SrHrSpecialist);
        }
        // updating Account Executive on Imp Profile
        if(mapProjectIdMapRoleContactId.get(project.Id).containsKey(NSP_ServiceConstants.AccountExecutive)){
             impProfile.Id= impProfileId;
            impProfile.NSP_Account_Executive__c = mapProjectIdMapRoleContactId.get(project.Id).get(NSP_ServiceConstants.AccountExecutive);
        }
        // updating HR Quality Support Team Member on Imp Profile
        if ( mapProjectIdMapRoleContactId.get(project.Id).containsKey( 'HR Client Implementation Team Member' ) ) {
            impProfile.Id= impProfileId;
            impProfile.NSP_HR_Quality_Support_Team_Member__c = mapProjectIdMapRoleContactId.get(project.Id).get( 'HR Client Implementation Team Member' );
        }
        return impProfile;
    }

    /***********************************************************************************************
    * MethodName: updateProjectOwner
    * Description : This Method will update owner field on project when project manager role is assigned on project team object
    * Params:       Map <Id, NSP_Project_Team__c >newProjTeamMap, Map <Id, NSP_Project_Team__c >oldProjTeamMap
    * Author :      Bindushree R
    * ********************************************************************************************/

    public static void updateProjectOwner(Map <Id, NSP_Project_Team__c >newProjTeamMap, Map <Id, NSP_Project_Team__c >oldProjTeamMap){
        Map<Id,Id> mapOfProjectManager = new Map<Id,Id>();
        Id PEORecordTypeId  = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();

        try{
            for(NSP_Project_Team__c projTeam:newProjTeamMap.values()){
                //fetch project team assignee who has project manager role and put it in map of project, project manager
                if(projTeam.NSP_Assignee__c!=null && projTeam.NSP_Project__c!=null && projTeam.NSP_Role__c==NSP_ServiceConstants.ProjectManager){

                    if(oldProjTeamMap==null || projTeam.NSP_Assignee__c!= oldProjTeamMap.get(projTeam.id).NSP_Assignee__c
                      || projTeam.NSP_Role__c!= oldProjTeamMap.get(projTeam.id).NSP_Role__c){

                       mapOfProjectManager.put(projTeam.NSP_Project__c,projTeam.NSP_Assignee__c);
                    }
                }
            }
           //get map of all salesforce user for the project manager role contact
           Map<Id,Contact> mapofContacts= new Map<Id, Contact>([SELECT Id,pse__Salesforce_User__c from Contact WHERE Id in: mapOfProjectManager.values() AND pse__Salesforce_User__c!=null ]);


            //query for all the implementation project which present in the mapOfProjectManager
            List<pse__Proj__c> implProjectList = new List<pse__Proj__c>([Select Id ,pse__Project_Type__c ,TemplateName__c,RecordTypeId ,OwnerId
                                                                              From pse__Proj__c WHERE  pse__Project_Type__c=:NSP_ServiceConstants.ImplementationProjectType AND
                                                                              (TemplateName__c = :NSP_ServiceConstants.MM_PROJECT_TEMPLATE_KEY OR TemplateName__c = :NSP_ServiceConstants.FSO_PROJECT_TEMPLATE_KEY OR TemplateName__c = :NSP_ServiceConstants.HRSCALE_PROJECT_TEMPLATE_KEY)
                                                                              AND RecordTypeId=:PEORecordTypeId AND Id IN :mapOfProjectManager.keyset()]);

            List<pse__Proj__c> updateProjList = new List<pse__Proj__c>();

            for(pse__Proj__c proj:implProjectList ){
                Id projOwnerId=mapofContacts.get(mapOfProjectManager.get(proj.id)).pse__Salesforce_User__c;
                //Assign the project owner field to project manager of project team
                if(proj.OwnerId!=projOwnerId){

                   proj.OwnerId= projOwnerId;
                   updateProjList.add(proj);
                }
            }
            //update the project if list is not empty
            if(!updateProjList.isEmpty()){
                database.update(updateProjList, false);
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTeamTriggerHelper.class.getName() ,
                'updateProjectOwner' ,
                e
            );
        }
    }

    /***********************************************************************************************
    * MethodName: updatePayrollSpecialistonProject
    * Description : This Method will update owner field on project when project manager role is assigned on project team object
    * Params:       Map <Id, NSP_Project_Team__c >newProjTeamMap, Map <Id, NSP_Project_Team__c >oldProjTeamMap
    * Author :      Harsha Khiroya
    * ********************************************************************************************/

    public static void updatePayrollSpecialistonProject(Map <Id, NSP_Project_Team__c >newProjTeamMap, Map <Id, NSP_Project_Team__c >oldProjTeamMap){
        Map<Id,Id> mapOfPayrollSpecialist = new Map<Id,Id>();
        Id PEORecordTypeId  = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
        Set<Id> projectIdSet = new Set<Id>();
        try{

            for(NSP_Project_Team__c projTeam:newProjTeamMap.values()){

                //fetch project team assignee who has project manager role and put it in map of project, project manager
                if(projTeam.NSP_Assignee__c!=null && projTeam.NSP_Project__c!=null && projTeam.NSP_Role__c==NSP_ServiceConstants.PayrollSpecialist){

                    if(oldProjTeamMap==null || projTeam.NSP_Assignee__c!= oldProjTeamMap.get(projTeam.id).NSP_Assignee__c){

                       mapOfPayrollSpecialist.put(projTeam.NSP_Project__c,projTeam.NSP_Assignee__c);
                    }
                }

                if(String.isBlank(projTeam.NSP_Assignee__c) && projTeam.NSP_Role__c==NSP_ServiceConstants.PayrollSpecialist){
                    projectIdSet.add(projTeam.NSP_Project__c);

                }

            }
           //get map of all salesforce user for the project manager role contact
           Map<Id,Contact> mapofContacts= new Map<Id, Contact>([SELECT Id,Name, NSP_Work_email__c, NSP_Work_Phone__c, pse__Salesforce_User__c from Contact WHERE Id in: mapOfPayrollSpecialist.values() ]);


            //query for all the implementation project which present in the mapOfProjectManager
            List<pse__Proj__c> implProjectList = new List<pse__Proj__c>([Select Id ,pse__Project_Type__c ,TemplateName__c,RecordTypeId ,OwnerId,Project_Team_Payroll_Specialist__c
                                                                              From pse__Proj__c WHERE  pse__Project_Type__c=:NSP_ServiceConstants.ImplementationProjectType AND
                                                                              (TemplateName__c = :NSP_ServiceConstants.MM_PROJECT_TEMPLATE_KEY OR TemplateName__c = :NSP_ServiceConstants.FSO_PROJECT_TEMPLATE_KEY)
                                                                              AND RecordTypeId=:PEORecordTypeId AND Id IN :mapOfPayrollSpecialist.keyset()]);

             List<pse__Proj__c> projectList = new List<pse__Proj__c>([Select Id ,pse__Project_Type__c ,TemplateName__c,RecordTypeId ,OwnerId,Project_Team_Payroll_Specialist__c
                                                                              From pse__Proj__c WHERE Id IN :projectIdSet]);

            List<pse__Proj__c> updateProjList = new List<pse__Proj__c>();

            for(pse__Proj__c proj:implProjectList ){
                Id projTeamId=mapofContacts.get(mapOfPayrollSpecialist.get(proj.id)).Id;

                if(proj.Project_Team_Payroll_Specialist__c!=projTeamId){
                   proj.Project_Team_Payroll_Specialist__c= projTeamId;
                   updateProjList.add(proj);
                }
            }
            for(pse__Proj__c proj:projectList ){
                proj.Project_Team_Payroll_Specialist__c= null;
            }
            //update the project if list is not empty
            if(!updateProjList.isEmpty()){
                database.update(updateProjList, false);
            }
            if(!projectList.isEmpty()){
                database.update(projectList,false);
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTeamTriggerHelper.class.getName() ,
                'updatePayrollSpecialistonProject' ,
                e
            );
        }
    }

}
//