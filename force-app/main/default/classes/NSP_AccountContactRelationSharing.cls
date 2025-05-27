public class NSP_AccountContactRelationSharing {
    // test w/ NSP_AccountContactRelationSharingTest, NSP_AccountContactRelationHelperTest (79%)
    // test w/ NSP_AccountContactRelationSharingTest (55%)
    // test w/ NSP_AccountContactRelationHelperTest (57%)

    //
    // MethodName: projectRecordSharing
    // Description : Method for sharing records With Community Users
    // Params:       Set<Id> newAccountIdSet
    //
    public static void projectRecordSharing( Set<Id> newAccountIdSet ) {
        try {
            //fetch all the related projects for acr contact for sharing the project records
            Map<Id,pse__Proj__c> mapOfNewProjects = new Map<Id, pse__Proj__c>(
                [
                    SELECT Id , pse__Account__c , NSP_Visible_to_Client__c
                    FROM pse__Proj__c
                    WHERE (
                        pse__Account__c IN :newAccountIdSet
                        AND NSP_Visible_to_Client__c = true
                    )
                ]
            );
            if ( !mapOfNewProjects.isEmpty() ) {
                NSP_ProjectRecordSharing.projectRecordSharing( newAccountIdSet , mapOfNewProjects );
            }
        } catch ( Exception e ) {
            NSP_AccountContactRelationSharing.handleException( e , 'projectRecordSharing' );
        }

    }

    //
    // MethodName: projectRemoveSharing
    // Description : Method for removing sharing access  With Community Users
    // Params:       Set<Id> oldAccountIdSet
    //
    public static void projectRemoveSharing( Set<Id> oldAccountIdSet ) {
        try{
            //fetch all the related projects where project sharing needs to delete when acr is updated
            Map<Id, pse__Proj__c> mapOfOldProjects = new Map<Id, pse__Proj__c>(
                [
                    SELECT Id , pse__Account__c
                    FROM pse__Proj__c
                    WHERE (
                        pse__Account__c IN :oldAccountIdSet
                        AND NSP_Visible_to_Client__c = true
                    )
                ]
            );
            if ( !mapOfOldProjects.isEmpty() ) {
                    NSP_ProjectRecordSharing.projectRemoveSharing( mapOfOldProjects.keySet() );
            }
        } catch ( Exception e ) {
            NSP_AccountContactRelationSharing.handleException( e , 'projectRemoveSharing' );
        }

    }

    //
    // MethodName: projectTaskRecordSharing
    // Description : Method for sharing project task records With Community Users
    // Params:       Set<Id> newAccountIdSet,Set<Id> oldAccountIdSet
    //
    public static void projectTaskRecordSharing( Set<Id> newAccountIdSet , Set<Id> oldAccountIdSet ) {
        try {
            //fetch all the related projects for acr contact for sharing the project records
            if ( ( newAccountIdSet != null ) && !newAccountIdSet.isEmpty() ) {
                Map<Id, pse__Project_Task__c> mapOfNewProjectTasks = new Map<Id,pse__Project_Task__c>(
                    [
                        SELECT Id , pse__Project__c  , pse__Project__r.pse__Account__c , NSP_Visible_to_Client__c
                        FROM pse__Project_Task__c
                        WHERE (
                            pse__Project__r.pse__Account__c IN :newAccountIdSet
                            AND NSP_Visible_to_Client__c = true
                        )
                    ]
                );
                if ( !mapOfNewProjectTasks.isEmpty() ) {
                    NSP_ProjectTaskSharing.projectTaskRecordSharing( mapOfNewProjectTasks.keyset() , null );
                }
            }
            if ( ( oldAccountIdSet != null ) && !oldAccountIdSet.isEmpty() ) {
                Map<Id, pse__Project_Task__c> mapOfOldProjectTasks = new Map<Id,pse__Project_Task__c>(
                    [
                        SELECT Id , pse__Project__c , pse__Project__r.pse__Account__c , NSP_Visible_to_Client__c
                        FROM pse__Project_Task__c
                        WHERE (
                            pse__Project__r.pse__Account__c IN :oldAccountIdSet
                            AND NSP_Visible_to_Client__c != true
                        )
                    ]
                );
                if ( !mapOfOldProjectTasks.isEmpty() ) {
                        NSP_ProjectTaskSharing.projectTaskRecordSharing( null , mapOfOldProjectTasks.keyset() );
                }
            }
        } catch ( Exception e ) {
            NSP_AccountContactRelationSharing.handleException( e , 'projectTaskRecordSharing' );
        }

    }

    //
    // MethodName: milestoneRecordSharing
    // Description : Method for sharing milestone records With Community Users
    // Params:       Set<Id> newAccountIdSet,Set<Id> oldAccountIdSet
    //
    public static void milestoneRecordSharing( Set<Id> newAccountIdSet , Set<Id> oldAccountIdSet ) {
        try {
            //fetch all the related projects for acr contact for sharing the project records
            if ( ( newAccountIdSet != null ) && !newAccountIdSet.isEmpty() ) {
                Map<Id, pse__Milestone__c> mapOfNewMilestones = new Map<Id,pse__Milestone__c>(
                    [
                        SELECT Id , pse__Project__c , pse__Project__r.pse__Account__c , NSP_Visible_to_Client__c
                        FROM pse__Milestone__c
                        WHERE (
                            pse__Project__r.pse__Account__c IN :newAccountIdSet
                            AND NSP_Visible_to_Client__c = true
                        )
                    ]
                );
                if ( !mapOfNewMilestones.isEmpty() ) {
                        NSP_MilestoneTaskSharing.mileStoneRecordSharing( mapOfNewMilestones.keyset() , null );
                }
            }
            if ( ( oldAccountIdSet != null ) && !oldAccountIdSet.isEmpty() ) {
                Map<Id,pse__Milestone__c> mapOfOldMilestones = new Map<Id,pse__Milestone__c>(
                    [
                        SELECT Id , pse__Project__c , pse__Project__r.pse__Account__c , NSP_Visible_to_Client__c
                        FROM pse__Milestone__c
                        WHERE (
                            pse__Project__r.pse__Account__c IN :oldAccountIdSet
                            AND NSP_Visible_to_Client__c != true
                        )
                    ]
                );
                if ( !mapOfOldMilestones.isEmpty() ) {
                    NSP_MilestoneTaskSharing.mileStoneRecordSharing( null , mapOfOldMilestones.keyset() );
                }
            }
        } catch ( Exception e ) {
            NSP_AccountContactRelationSharing.handleException( e , 'milestoneRecordSharing' );
        }
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_AccountContactRelationSharing.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_AccountContactRelationSharing.class.getName() ,
            methodName ,
            e
        );
    }

}
//