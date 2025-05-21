//
// @description  :  class for set up manual sharing rules.
// @date 05/23/2022
// Added as part of STY-00721
// Name : NSP_ProjectRecordSharing
//
public class NSP_ProjectRecordSharing {
    // test w/ NSP_ProjectRecordSharingTest, NSP_ProjectTriggerHelperTest (82%)
    // test w/ NSP_ProjectRecordSharingTest (65%)
    // test w/ NSP_ProjectTriggerHelperTest (51%)

    //
    // MethodName: projectRecordSharing
    // Description : Method to share project records with community users
    // Params:       Map<Id, pse__Proj__c> mapOfProjects, Set<Id> accountIdSet
    //
    public static void projectRecordSharing ( Set<Id> accountIdSet , Map<Id,pse__Proj__c> mapOfProjects ) {
        List<pse__Proj__Share> newProjectShareList = new List<pse__Proj__Share>();
        Set<Id> contactIdSet = new Set<Id> ();
        Map<Id,Set<Id>> mapOfAccountContacts = new Map<Id,Set<Id>>();
        Map<Id,Id> mapOfUserContact = new Map<Id,Id>();
        try {
            if ( !accountIdSet.isEmpty() ) {
                //fetch all the acr associated to the project account
                List<AccountContactRelation> acrList = [
                    SELECT ContactId , AccountId
                    FROM AccountContactRelation
                    WHERE (
                        AccountId IN :accountIdSet
                        AND NSP_Community_Access__c INCLUDES ( :NSP_ServiceConstants.peoCommunityAccess )
                    )
                ];
                for(AccountContactRelation acr : acrList){
                    //get all contacts of acr where community access is peo projects
                    contactIdSet.add(acr.ContactId);
                    if(mapOfAccountContacts.get(acr.AccountId)==null){
                        mapOfAccountContacts.put(acr.AccountId,new Set<Id>());
                    }
                    mapOfAccountContacts.get(acr.AccountId).add(acr.ContactId);
                }
                if(!contactIdSet.isEmpty()){
                    //get all community users to whom project record need to be shared
                    List<User> userList =[SELECT Id,
                                          ContactId
                                          FROM User
                                          WHERE ContactId IN : contactIdSet
                                          AND Profile.Name =: NSP_ServiceConstants.CUSTOMER_COMMUNITY_PLUS AND isActive=TRUE];
                    for(User oUser : userList){
                        mapOfUserContact.put(oUser.ContactId,oUser.Id);
                    }
                    for(pse__Proj__c proj : mapOfProjects.Values()){
                        Set<Id> contactSet = mapOfAccountContacts.get(proj.pse__Account__c);
                        if(!contactSet.isEmpty()){
                            for(Id contactId : contactSet){
                                if(mapOfUserContact.get(contactId) != null){
                                    pse__Proj__Share projShare = createProjectSharing ( mapOfUserContact.get(contactId), proj.Id );
                                    newProjectShareList.add(projShare);
                                }
                            }
                        }
                    }
                }
            }
            // Inserting new  Project Shares Records
            if ( !newProjectShareList.isEmpty() ) {
                List<Database.SaveResult> results = Database.insert( newProjectShareList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ProjectRecordSharing.class.getName() ,
                    'projectRecordSharing:insert' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ProjectRecordSharing.handleException( e , 'projectRecordSharing' );
        }
    }

    //
    // MethodName: projectRecordSharing
    // Description : Method to remove project records with community users
    // Params:        Set<Id> accountIdSet
    //
    //
    public static void projectRemoveSharing( Set<Id> projectSharedIdSet ) {
        //Seacrhing for existing Project Share Records
        try {
            List<pse__Proj__Share> oldProjShareList = [
                SELECT Id , ParentId , UserorGroup.Profile.Name , UserorGroupId
                FROM pse__Proj__Share
                WHERE (
                    ParentId IN :projectSharedIdSet
                    AND Rowcause = :Schema.pse__Proj__Share.RowCause.InsperitySharing__c
                    AND UserorGroup.Profile.Name = :NSP_ServiceConstants.CUSTOMER_COMMUNITY_PLUS
                )
            ];
            // Deleting old  Project Shares Records
            if ( !oldProjShareList.isEmpty() ) {
                List<Database.DeleteResult> results = Database.delete( oldProjShareList , false );
                NSP_ProjectRecordSharing.handleResults( results , 'projectRemoveSharing:delete' );
            }
        } catch ( Exception e ) {
            NSP_ProjectRecordSharing.handleException( e , 'projectRemoveSharing' );
        }
    }

    //
    // MethodName: createProjectSharing
    // Description : Method to retrieve community users
    // Params:       String userorGroupId , String projectId
    //
    public static pse__Proj__Share createProjectSharing( String userorGroupId , String projectId ) {
        pse__Proj__Share projShare = new pse__Proj__Share();
        projShare.RowCause = Schema.pse__Proj__Share.RowCause.InsperitySharing__c;
        projShare.UserOrGroupId = userorGroupId;
        projShare.AccessLevel = NSP_ServiceConstants.READ_ACCESS;
        projShare.ParentId = projectId;
        return projShare;
    }

    //
    // MethodName: shareRelatedProjectTasks
    // Description : Method to share Project related task with community users
    // Params: Set<Id> projectIdSet
    //
    //
    @future
    public static void shareRelatedProjectTasks( Set<Id> projectIdSet ) {
        if ( !projectIdSet.isEmpty() ) {
            Map<Id,pse__Project_Task__c> projectTaskMap = new Map<Id,pse__Project_Task__c>(
                [
                    SELECT Id , pse__Project__c , pse__Project__r.pse__Account__c, NSP_Visible_to_Client__c
                    FROM pse__Project_Task__c
                    WHERE (
                        pse__Project__c IN :projectIdSet
                        AND pse__Project__r.pse__Account__c != null
                        AND NSP_Visible_to_Client__c = true
                    )
                ]
            );
            NSP_ProjectTaskSharing.projectTaskRecordSharing( projectTaskMap.keySet() , new Set<Id>() );
        }
    }

    //
    // MethodName: shareRelatedMilestones
    // Description : Method to share Project related milestones with community users
    // Params: Set<Id> projectIdSet
    //
    @future
    public static void shareRelatedMilestones( Set<Id> projectIdSet ) {
        if ( !projectIdSet.isEmpty() ) {
            Map<Id,pse__Milestone__c> milestoneMap = new map<Id,pse__Milestone__c>(
                [
                    SELECT Id , pse__Project__c , pse__Project__r.pse__Account__c, NSP_Visible_to_Client__c
                    FROM pse__Milestone__c
                    WHERE (
                        pse__Project__c IN :projectIdSet
                        AND pse__Project__r.pse__Account__c != null
                        AND NSP_Visible_to_Client__c = true
                    )
                ]
            );
            NSP_MilestoneTaskSharing.mileStoneRecordSharing( milestoneMap.keySet() , new Set<Id>() );
        }
    }

    //
    // MethodName: removeRelatedProjectSharing
    // Description : Method to remove the task and milestones sharing after
    // Params: Set<Id> projectIdSet
    //
    public static void removeRelatedProjectSharing( Set<Id> projectIdSet ) {
        List<pse__Milestone__Share> deleteMilestoneSharelist = new List<pse__Milestone__Share>();
        List<pse__Project_Task__share> deletePTaskSharelist = new List<pse__Project_Task__share>();
        Set<Id>pTaskIdSet = new Set<Id>();
        Set<Id>milestoneIdSet = new Set<Id>();
        if ( !projectIdSet.isEmpty() ) {
            for ( pse__Milestone__c mile : [
                        SELECT Id
                        FROM pse__Milestone__c
                        WHERE (
                            pse__Project__c IN :projectIdSet
                            AND pse__Project__r.pse__Account__c != null
                            AND NSP_Visible_to_Client__c = true
                        )
                    ]
                )
            {
                milestoneIdSet.add( mile.Id );
            }
            for ( pse__Project_Task__c pTask : [
                        SELECT Id
                        FROM pse__Project_Task__c
                        WHERE (
                            pse__Project__c IN :projectIdSet
                            AND pse__Project__r.pse__Account__c != null
                            AND NSP_Visible_to_Client__c = true
                        )
                    ]
                )
            {
                pTaskIdSet.add( pTask.Id );
            }
            deletePTaskSharelist = NSP_ProjectTaskSharing.getProjectTaskShareList(pTaskIdSet);
            deleteMilestoneSharelist = NSP_MilestoneTaskSharing.getMilestoneShareList(milestoneIdSet);
        }
        if ( !deletePTaskSharelist.isEmpty() ) {
            List<Database.DeleteResult> results = Database.delete( deletePTaskSharelist , false );
            NSP_ProjectRecordSharing.handleResults( results , 'removeRelatedProjectSharing:delete:pse__Project_Task__Share' );
        }
        if ( !deleteMilestoneSharelist.isEmpty() ) {
            List<Database.DeleteResult> results = Database.delete( deleteMilestoneSharelist , false );
            NSP_ProjectRecordSharing.handleResults( results , 'removeRelatedProjectSharing:delete:pse__Milestone__Share' );
        }
    }

    // for test code coverage only...
    public static void testHandleResults( List<Database.DeleteResult> results , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_ProjectRecordSharing.handleResults( results , methodName );
        }
    }

    private static void handleResults( List<Database.DeleteResult> results , String methodName ) {
        NSP_ErrorLogHandler.logResults(
            NSP_ProjectRecordSharing.class.getName() ,
            methodName ,
            results
        );
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_ProjectRecordSharing.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_ProjectRecordSharing.class.getName() ,
            methodName ,
            e
        );
    }

}
//