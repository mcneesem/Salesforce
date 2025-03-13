public with sharing class NSP_ClientGoalTriggerHelper {
    // test w/ NSP_ClientGoalTriggerHelper_Test (90%)

    //
    // Iterates throught the list of new leads and passes the required attributes to other methods.
    // @param newList List of New Client Goal.
    // @return void
    //
    public void afterInsertDirector( List<NSP_ClientGoal__c> newList ) {
        try {
            Set<Id> setOfAccountId = new Set<Id>();
            Map<Id,Id> projectMap = new Map<Id,Id>();
            Map<Id,NSP_ClientGoal__c> goalMap = new Map<Id,NSP_ClientGoal__c>();
            for ( NSP_ClientGoal__c clientGoal : newList ) {
               if ( clientGoal.NSP_Account__c != null ) {
                   setOfAccountId.add( clientGoal.NSP_Account__c );
                   goalMap.put( clientGoal.NSP_Account__c , clientGoal );
               }
            }
            projectMap = getProjectDetails( setOfAccountId );
            if ( ( projectMap != null ) && !projectMap.isEmpty() ) {
                copyClientGoalFromAccountOnProjectGoalOnProject( goalMap , projectMap );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ClientGoalTriggerHelper.class.getName() ,
                'afterUpdateDirector' ,
                e
            );
        }
    }

    //
    // Iterates throught the Map of new NSP_ClientGoal__c and passes the required attributes to other methods.
    // @param Map<Id, NSP_ClientGoal__c> newMap,Map<Id, NSP_ClientGoal__c> oldMap
    // @return void
    //
    public void afterUpdateDirector( Map<Id,NSP_ClientGoal__c> newMap , Map<Id,NSP_ClientGoal__c> oldMap ) {
        try {
            List<NSP_ProjectGoal__c> projectGoalList = new List<NSP_ProjectGoal__c>();
            List<String> clientGoalName = new List<String>();
            for ( NSP_ClientGoal__c clientGoal : newMap.Values() ) {
                if ( clientGoal.name != null ) {
                    clientGoalName.add( clientGoal.name );
                }
            }
            projectGoalList = [
                SELECT
                    Id ,
                    Client_Goals_Name__c ,
                    NSP_GoalType__c ,
                    NSP_PG_Date__c ,
                    NSP_PG_Goal_Target_Date__c ,
                    NSP_PG_Status__c ,
                    NSP_PG_Contact__c ,
                    NSP_PG_Asset__c ,
                    NSP_Details__c ,
                    NSP_Project__c ,
                    NSP_Project__r.pse__Project_Status__c
                FROM NSP_ProjectGoal__c 
                WHERE (
                    ( Client_Goals_Name__c != null )
                    AND ( NSP_Project__r.pse__Project_Status__c NOT IN ( 'Complete' , 'Cancelled' ) )
                    AND ( Client_Goals_Name__c IN :clientGoalName )
                )
            ];
            updateClientGoalToProjectGoal( projectGoalList , newMap );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ClientGoalTriggerHelper.class.getName() ,
                'afterUpdateDirector' ,
                e
            );
        }
    }

    //
    // MethodName: getProjectDetails
    // params : Set<Id> accountIds
    //
    private static Map<Id,Id> getProjectDetails( Set<Id> accountIds ) {
        Map<Id,Id> projectMap = new Map<Id,Id>();
        Id peoProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , 'PEO_Project' );
        Id billableSerRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , 'PEO_Project_Billable' );
        List<pse__Proj__c> pseProjects = [
            SELECT Id , pse__Account__c , pse__Project_Status__c
            FROM pse__Proj__c
            WHERE (
                ( pse__Account__c IN :accountIds )
                AND ( pse__Project_Status__c NOT IN ( 'Complete' , 'Cancelled' ) )
                AND (
                    ( RecordTypeId = :peoProjectRecordTypeId )
                    OR ( RecordTypeId = :billableSerRecordTypeId )
                )
            )
        ];
        if ( !pseProjects.isEmpty() ) {
            for ( pse__Proj__c proj : pseProjects ) {
                projectMap.put( proj.Id , proj.pse__Account__c );
            }
            return projectMap;
        }
        return new Map<Id,Id>();
    }

    // Description : This will copy all the client goals associated with account to Project goals associated with Project
    // Date : 11/05/2022
    private void copyClientGoalFromAccountOnProjectGoalOnProject( Map<Id,NSP_ClientGoal__c> goalMap , Map<Id,Id> projectMap ) {
        List<NSP_ProjectGoal__c> listOfProjectGoals = new List<NSP_ProjectGoal__c>();
        for ( Id projectId : projectMap.keySet() ) {
            NSP_ClientGoal__c goal = goalMap.get( projectMap.get( projectId ) );
            NSP_ProjectGoal__c createProjectGoal = new NSP_ProjectGoal__c();
            createProjectGoal.NSP_GoalType__c = goal.NSP_Goal_Type__c;
            createProjectGoal.NSP_Project__c  = projectId;
            createProjectGoal.NSP_PG_Date__c = goal.NSP_Date__c;
            createProjectGoal.NSP_PG_Goal_Target_Date__c = goal.NSP_Goal_Date__c;
            createProjectGoal.NSP_PG_Status__c = goal.NSP_Status__c;
            createProjectGoal.NSP_PG_Contact__c = goal.NSP_Contact__c;
            createProjectGoal.NSP_PG_Asset__c = goal.Asset__c;
            createProjectGoal.Client_Goals_Name__c = goal.Name;
            createProjectGoal.NSP_Details__c = SchemaController.safeText(
                goal.NSP_Goal_Details__c ,
                sObjectType.NSP_ProjectGoal__c.Fields.NSP_Details__c
            );
            listOfProjectGoals.add( createProjectGoal );
        }
        if ( !listOfProjectGoals.isEmpty() ) {
            List<Database.SaveResult> results = Database.insert( listOfProjectGoals , false );
            NSP_ErrorLogHandler.logResults(
                NSP_ClientGoalTriggerHelper.class.getName() ,
                'copyClientGoalFromAccountOnProjectGoalOnProject' ,
                results
            );
        }
    }

    //
    // Method Name : updateClientGoalToProjectGoal
    // Description : This will copy updates from Client gaol on Account to Project Goal on Project
    // @param List<NSP_ProjectGoal__c> projectGoalList, Map<Id, NSP_ClientGoal__c> newMap
    // @return void
    //
    private void updateClientGoalToProjectGoal( List<NSP_ProjectGoal__c> projectGoalList , Map<Id,NSP_ClientGoal__c> newMap ) {
        List<NSP_ProjectGoal__c> updatedProjectGoalList = new List<NSP_ProjectGoal__c>();
        for ( NSP_ProjectGoal__c projectGoal : projectGoalList ) {
            String pClientGoalName = projectGoal.Client_Goals_Name__c;
            for ( NSP_ClientGoal__c clientGoal : newMap.values() ) {
                String clientGName = clientGoal.Name;
                if ( pClientGoalName == clientGName ) {
                    projectGoal.NSP_GoalType__c = clientGoal.NSP_Goal_Type__c;
                    projectGoal.NSP_PG_Date__c = clientGoal.NSP_Date__c;
                    projectGoal.NSP_PG_Goal_Target_Date__c = clientGoal.NSP_Goal_Date__c;
                    projectGoal.NSP_PG_Status__c = clientGoal.NSP_Status__c;
                    projectGoal.NSP_PG_Contact__c = clientGoal.NSP_Contact__c;
                    projectGoal.NSP_PG_Asset__c = clientGoal.Asset__c;
                    projectGoal.NSP_Details__c = SchemaController.safeText(
                        clientGoal.NSP_Goal_Details__c ,
                        sObjectType.NSP_ProjectGoal__c.Fields.NSP_Details__c
                    );
                    updatedProjectGoalList.add( projectGoal );
                }
            }
        }
        if ( !updatedProjectGoalList.isEmpty() ) {
            List<Database.SaveResult> results = Database.update( updatedProjectGoalList , false );
            NSP_ErrorLogHandler.logResults(
                NSP_ClientGoalTriggerHelper.class.getName() ,
                'updateClientGoalToProjectGoal' ,
                results
            );
        }
    }

    public static Map<Id,NSP_Relationship_Strategy_Action_Plan__c> getRSAPDetails( Set<Id> accountIds ) {
        Map<Id,NSP_Relationship_Strategy_Action_Plan__c> rsapMap = new Map<Id,NSP_Relationship_Strategy_Action_Plan__c>();
        if ( ( accountIds != null ) && !accountIds.isEmpty() ) {
            List<NSP_Relationship_Strategy_Action_Plan__c> rsapRecords = [
                SELECT Id , NSP_Account__c , NSP_Status__c
                FROM NSP_Relationship_Strategy_Action_Plan__c
                WHERE (
                    ( NSP_Account__c IN :accountIds )
                    AND ( NSP_Status__c NOT IN ( 'Completed' , 'Cancelled' ) )
                )
            ];
            if ( !rsapRecords.isEmpty() ) {
                for ( NSP_Relationship_Strategy_Action_Plan__c rsap : rsapRecords ) {
                    rsapMap.put( rsap.NSP_Account__c , rsap );
                }
            }
        }
        return rsapMap;
    }

}
//