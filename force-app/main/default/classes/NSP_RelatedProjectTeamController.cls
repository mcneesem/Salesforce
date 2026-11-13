/**
* Author : Nischay Jindal
* Date : 20/June/2023
*Represents the NSP_RelatedProjectTeamController  for related  ProjectTeam Members in email Templates.
*/
public class NSP_RelatedProjectTeamController {
    // test w/ NSP_RelatedProjectTeamController_Test (100%)
    public static String recId;
      
       //set recordId
       public static void setrecId (String recordId) {
           recId = recordId;
       }
       //get recordId
       public static String getrecId() {
           return recId;
       } 
   
       public static NSP_Project_Team__c projectTeam {
           get{
               if ( recId != null ){
                   projectTeam = null;
                   List<NSP_Project_Team__c> projectTeams = [SELECT Id,NSP_Role__c,NSP_Assignee__c, NSP_Assignee__r.Name,NSP_Assignee__r.NSP_Job_Title__c,
                                  NSP_Assignee__r.NSP_Work_email__c FROM NSP_Project_Team__c WHERE NSP_Project__c =:recId  AND 
                                  NSP_Role__c =: NSP_ServiceConstants.ProjectManager  AND NSP_Assignee__c!=null LIMIT 1];
                    if (!projectTeams.isEmpty()) {
                        projectTeam = projectTeams[0];
                    }
                   }
               return projectTeam;
           }
           set;
       }
   
        
   }