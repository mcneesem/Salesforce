/**
* @description  :  Helper class for Implementation Profile  Trigger.
* @date 07/25/2022
* Author : Nischay Jindal
* Name : NSP_ImplementaionProfileTriggerHelper
*/
public class NSP_ImplementaionProfileTriggerHelper {

    /***********************************************************************************************
    * MethodName: updateProjectTeamRoles
    * Description : This Method will update Project Team Roles from the Imp Profile   
    * Params:       Map <Id, Implementation_Profile__c >newImpPrfMap, Map <Id, Implementation_Profile__c >oldImpPrfMap
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    public static void updateProjectTeamRoles(Map <Id, Implementation_Profile__c >newImpPrfMap, Map <Id, Implementation_Profile__c >oldImpPrfMap){
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id,Map<String,String>> mapProjectIdMapRoleContactId = new Map<Id,Map<String,String>>();
        List<NSP_Project_Team__c> updateProjectTeamList = new List<NSP_Project_Team__c>();
        try{
            Id pEORecordTypeId  = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
            for(Implementation_Profile__c imPfl: newImpPrfMap.values()){
                if(imPfl.NSP_Project__c!=null  && imPfl.Account__c!=null){
                    // checking for roles update on Imp Profile
                    if (impProfileRoleChange(imPfl,oldImpPrfMap)){
                        //add account Ids
                        accountIdSet.add(imPfl.Account__c);  
                    } 
                }
            }
            
            Map<Id, pse__Proj__c> implProjectMap = new Map<Id, pse__Proj__c>([Select Id ,pse__Project_Type__c ,TemplateName__c,RecordTypeId ,pse__Account__c
                                                                            From pse__Proj__c WHERE  pse__Project_Type__c=:NSP_ServiceConstants.ImplementationProjectType AND 
                                                                            (TemplateName__c = :label.Middle_Market_Implementation_Project OR TemplateName__c = :label.FSOImplementationProject) 
                                                                            AND RecordTypeId=: pEORecordTypeId AND pse__Account__c IN :accountIdSet]);
            
            List<NSP_Project_Team__c> projectTeamList = [SELECT Id,NSP_Role__c, NSP_Project__c, NSP_Assignee__c, RecordTypeId FROM NSP_Project_Team__c 
                                                        WHERE NSP_Project__c IN: implProjectMap.keySet()  ];
            for(Implementation_Profile__c imPfl: newImpPrfMap.values()){
                if(implProjectMap.containsKey(imPfl.NSP_Project__c)){
                    // creating map of Project and roles if Role change detected on Imp Profile
                    if (impProfileRoleChange(imPfl,oldImpPrfMap)){
                        // creating map of Project Id and Map of Imp roles and Role Contact 
                        mapProjectIdMapRoleContactId = getProjectRoleMap(imPfl,oldImpPrfMap);
                    } 
                }
            }
            for(NSP_Project_Team__c prjTeam :projectTeamList ){
                if(mapProjectIdMapRoleContactId.containsKey(prjTeam.NSP_Project__c) && mapProjectIdMapRoleContactId.get(prjTeam.NSP_Project__c)!=null ){
                    if(mapProjectIdMapRoleContactId.get(prjTeam.NSP_Project__c).containsKey(prjTeam.NSP_Role__c) ){
                        NSP_Project_Team__c projectTeam = new NSP_Project_Team__c();
                        projectTeam.Id = prjTeam.Id;
                        projectTeam.NSP_Assignee__c = mapProjectIdMapRoleContactId.get(prjTeam.NSP_Project__c).get(prjTeam.NSP_Role__c);
                        updateProjectTeamList.add(projectTeam);
                    }   
                }
            }
            if(!updateProjectTeamList.isEmpty()){
                //update project team 
                update updateProjectTeamList;
            }
        } catch (Exception ex) {
            //exception 
            NSP_ErrorLogHandler.logSaveException('NSP_ProjectTriggerHelper', 'createProjectTeamRoles', ex.getMessage());
        } 
        
    }
    /***********************************************************************************************
    * MethodName: impProfileRoleChange
    * Description : This Method will detect the role change on Imp Profile 
    * Params:       Implementation_Profile__c imPfl, Map <Id, Implementation_Profile__c >oldImpPrfMap
    * Author :      Nischay Jindal
    * Return : Boolean value
    * ********************************************************************************************/
    
    private static Boolean impProfileRoleChange(Implementation_Profile__c imPfl, Map <Id, Implementation_Profile__c >oldImpPrfMap){
        //initial value is false
        Boolean isRoleUpdate = false;
        if (imPfl.NSP_Project_Manager__c!=oldImpPrfMap.get(imPfl.Id).NSP_Project_Manager__c|| imPfl.NSP_OT_Representative__c!=oldImpPrfMap.get(imPfl.Id).NSP_OT_Representative__c ||
            imPfl.NSP_Orientation_Rep__c!=oldImpPrfMap.get(imPfl.Id).NSP_Orientation_Rep__c||
            imPfl.NSP_Onboarding_Specialist_Coordinator__c!=oldImpPrfMap.get(imPfl.Id).NSP_Onboarding_Specialist_Coordinator__c||
            imPfl.NSP_Orientation_Coordinator__c!=oldImpPrfMap.get(imPfl.Id).NSP_Orientation_Coordinator__c|| imPfl.NSP_Sr_Onboarding_Benefit_Rep__c!=oldImpPrfMap.get(imPfl.Id).NSP_Sr_Onboarding_Benefit_Rep__c||
            imPfl.NSP_Orientation_Planner__c!=oldImpPrfMap.get(imPfl.Id).NSP_Orientation_Planner__c||imPfl.NSP_Payroll_Specialist__c!=oldImpPrfMap.get(imPfl.Id).NSP_Payroll_Specialist__c||
            imPfl.NSP_Transition_Specialist__c!=oldImpPrfMap.get(imPfl.Id).NSP_Transition_Specialist__c||imPfl.NSP_Sr_Benefit_Rep__c!=oldImpPrfMap.get(imPfl.Id).NSP_Sr_Benefit_Rep__c||
            imPfl.NSP_Payroll_Project_Manager__c!=oldImpPrfMap.get(imPfl.Id).NSP_Payroll_Project_Manager__c||imPfl.NSP_HR_Specialist__c!=oldImpPrfMap.get(imPfl.Id).NSP_HR_Specialist__c||
            imPfl.NSP_Account_Executive__c!=oldImpPrfMap.get(imPfl.Id).NSP_Account_Executive__c){
                isRoleUpdate= true;
            }
        //return a boolean value
        return isRoleUpdate;
    } 
    /***********************************************************************************************
    * MethodName: getProjectRoleMap
    * Description : This Method will create map of Project Id along with Role and Conatct Id 
    * Params:       Implementation_Profile__c imPfl, Map <Id, Implementation_Profile__c >oldImpPrfMap
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    private static  Map<Id,Map<String,String>> getProjectRoleMap(Implementation_Profile__c imPfl, Map <Id, Implementation_Profile__c >oldImpPrfMap){
        Map<Id,Map<String,String>> mapProjectIdMapRoleContactId = new Map<Id,Map<String,String>>();
        if(!mapProjectIdMapRoleContactId.containskey(imPfl.NSP_Project__c)){
            mapProjectIdMapRoleContactId.put(imPfl.NSP_Project__c,new Map<String,String>()); 
        } 
        if(imPfl.NSP_Project_Manager__c!=oldImpPrfMap.get(imPfl.Id).NSP_Project_Manager__c){
            mapProjectIdMapRoleContactId.get(imPfl.NSP_Project__c).put(NSP_ServiceConstants.ProjectManager,imPfl.NSP_Project_Manager__c);
        }
        if(imPfl.NSP_OT_Representative__c!=oldImpPrfMap.get(imPfl.Id).NSP_OT_Representative__c){
            mapProjectIdMapRoleContactId.get(imPfl.NSP_Project__c).put(NSP_ServiceConstants.OrientationRep,imPfl.NSP_OT_Representative__c);
        }
        if(imPfl.NSP_Onboarding_Specialist_Coordinator__c!=oldImpPrfMap.get(imPfl.Id).NSP_Onboarding_Specialist_Coordinator__c){
            mapProjectIdMapRoleContactId.get(imPfl.NSP_Project__c).put(NSP_ServiceConstants.OSCoordinator,imPfl.NSP_Onboarding_Specialist_Coordinator__c);
        }
        if(imPfl.NSP_Orientation_Coordinator__c!=oldImpPrfMap.get(imPfl.Id).NSP_Orientation_Coordinator__c){
            mapProjectIdMapRoleContactId.get(imPfl.NSP_Project__c).put(NSP_ServiceConstants.OTCoordinator,imPfl.NSP_Orientation_Coordinator__c);
        }
        if(imPfl.NSP_Orientation_Planner__c!=oldImpPrfMap.get(imPfl.Id).NSP_Orientation_Planner__c){
            mapProjectIdMapRoleContactId.get(imPfl.NSP_Project__c).put(NSP_ServiceConstants.OTPlanner,imPfl.NSP_Orientation_Planner__c);
        }
        if(imPfl.NSP_Payroll_Specialist__c!=oldImpPrfMap.get(imPfl.Id).NSP_Payroll_Specialist__c){
            mapProjectIdMapRoleContactId.get(imPfl.NSP_Project__c).put(NSP_ServiceConstants.PayrollSpecialist,imPfl.NSP_Payroll_Specialist__c);
        }
        if(imPfl.NSP_Transition_Specialist__c!=oldImpPrfMap.get(imPfl.Id).NSP_Transition_Specialist__c){
            mapProjectIdMapRoleContactId.get(imPfl.NSP_Project__c).put(NSP_ServiceConstants.TransitionSpecialist,imPfl.NSP_Transition_Specialist__c);
        }
        if(imPfl.NSP_Sr_Onboarding_Benefit_Rep__c!=oldImpPrfMap.get(imPfl.Id).NSP_Sr_Onboarding_Benefit_Rep__c){
            mapProjectIdMapRoleContactId.get(imPfl.NSP_Project__c).put(NSP_ServiceConstants.SrBenefitRep,imPfl.NSP_Sr_Onboarding_Benefit_Rep__c);
        }
        if( imPfl.NSP_Payroll_Project_Manager__c!=oldImpPrfMap.get(imPfl.Id).NSP_Payroll_Project_Manager__c){
            mapProjectIdMapRoleContactId.get(imPfl.NSP_Project__c).put(NSP_ServiceConstants.PayrollProjectManager,imPfl.NSP_Payroll_Project_Manager__c);
        }
        if(imPfl.NSP_HR_Specialist__c!=oldImpPrfMap.get(imPfl.Id).NSP_HR_Specialist__c){
            mapProjectIdMapRoleContactId.get(imPfl.NSP_Project__c).put(NSP_ServiceConstants.SrHrSpecialist,imPfl.NSP_HR_Specialist__c);
        }
        if(imPfl.NSP_Account_Executive__c!=oldImpPrfMap.get(imPfl.Id).NSP_Account_Executive__c){
            mapProjectIdMapRoleContactId.get(imPfl.NSP_Project__c).put(NSP_ServiceConstants.AccountExecutive,imPfl.NSP_Account_Executive__c);
        }
        //return map of project and contact role Id
        return mapProjectIdMapRoleContactId;
    }  
}