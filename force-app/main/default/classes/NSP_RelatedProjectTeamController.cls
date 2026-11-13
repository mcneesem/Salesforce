// intentionally `without sharing` to preserve default sharing at api version 55...
public without sharing class NSP_RelatedProjectTeamController {
    // test w/ NSP_RelatedProjectTeamController_Test (100%)

    public static String recId;

    public static void setrecId ( String recordId ) {
        recId = recordId;
    }

    public static String getrecId() {
        return recId;
    }

    public static NSP_Project_Team__c projectTeam {
        public get {
            if ( recId != null ) {
                List<NSP_Project_Team__c> projectTeams = [
                    SELECT
                        Id ,
                        NSP_Role__c ,
                        NSP_Assignee__c ,
                        NSP_Assignee__r.Name ,
                        NSP_Assignee__r.NSP_Job_Title__c ,
                        NSP_Assignee__r.NSP_Work_email__c
                    FROM NSP_Project_Team__c
                    WHERE (
                        ( NSP_Project__c = :recId )
                        AND ( NSP_Role__c = 'Project Manager' )
                        AND ( NSP_Assignee__c != null )
                    )
                    LIMIT 1
                ];
                if ( !projectTeams.isEmpty() ) {
                    projectTeam = projectTeams[0];
                }
            }
            return projectTeam;
        }
        public set;
    }

}
//
