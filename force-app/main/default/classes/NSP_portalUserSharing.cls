public class NSP_portalUserSharing implements Queueable {
    // test w/ NSP_portalUserSharingTest (100%)

    private Map<Id,Id> mapContactIdUserId;

    public static void enqueueJob( Map<Id,Id> mapContactIdUserId ) {
        if ( ( mapContactIdUserId != null )
            && !mapContactIdUserId.isEmpty()
            && ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() )
            )
        {
            System.enqueueJob(
                new NSP_portalUserSharing(
                    mapContactIdUserId
                )
            );
        }
    }

    private NSP_portalUserSharing( Map<Id,Id> mapContactIdUserId ) {
        this.mapContactIdUserId = mapContactIdUserId;
    }

    public void execute( QueueableContext context ) { // DEPRECATED
        Map<Id,Set<Id>> mapAccountIdSetContactId = new Map<Id,Set<Id>>();
        List<pse__Proj__Share> projectShareList = new List<pse__Proj__Share>();
        List<pse__Project_Task__Share> projectTaskShareList = new List<pse__Project_Task__Share>();
        List<pse__Milestone__Share> projectMilestoneShareList = new List<pse__Milestone__Share>();
        for ( AccountContactRelation acr : [
                    SELECT
                        Id ,
                        AccountId ,
                        ContactId,NSP_Community_Access__c
                    FROM AccountContactRelation
                    WHERE (
                        ( ContactId IN :mapContactIdUserId.keySet() )
                        AND ( NSP_Community_Access__c INCLUDES ( 'PEO Projects' ) )
                    )
                ]
            )
        {
            if ( !mapAccountIdSetContactId.containsKey( acr.accountId ) ) {
                mapAccountIdSetContactId.put( acr.accountId , new Set<Id>() );
            }
            mapAccountIdSetContactId.get( acr.accountId ).add( acr.ContactId );
        }
        projectShareList = NSP_portalUserSharing.generateProjectShareList(
            mapContactIdUserId ,
            mapAccountIdSetContactId
        );
        if ( !projectShareList.isEmpty() ) {
            // inserting List of Project Shares
            insert projectShareList;
            // fething list of Milestone Shares
            projectMilestoneShareList = NSP_portalUserSharing.generateMilestoneShareList(
                mapContactIdUserId ,
                mapAccountIdSetContactId
            );
            if ( !projectMilestoneShareList.isEmpty() ) {
                // inserting list of Milsetone Shares
                insert projectMilestoneShareList;
            }
            // fething list of Project Task Shares
            projectTaskShareList = NSP_portalUserSharing.generateProjectTaskShareList(
                mapContactIdUserId ,
                mapAccountIdSetContactId
            );
            if ( !projectTaskShareList.isEmpty() ) {
                // inserting list of Project Task Shares
                insert projectTaskShareList;
            }
        }
    }

    private static List<pse__Proj__Share> generateProjectShareList(
        Map<Id,Id> mapContactIdUserId ,
        Map<Id,Set<Id>> mapAccountIdSetContactId
        )
    {
        List<pse__Proj__Share> projectShareList = new List<pse__Proj__Share>();
        for ( pse__Proj__c project : [
                    SELECT
                        Id ,
                        pse__Account__c ,
                        NSP_Visible_to_Client__c
                    FROM pse__Proj__c
                    WHERE (
                        ( pse__Account__c IN :mapAccountIdSetContactId.keySet() )
                        AND ( NSP_Visible_to_Client__c = true )
                    )
                ]
            )
        {
            if ( mapAccountIdSetContactId.containsKey( project.pse__Account__c )
                && !mapAccountIdSetContactId.get( project.pse__Account__c ).isEmpty()
                )
            {
                for ( Id contactId : mapAccountIdSetContactId.get( project.pse__Account__c ) ) {
                    if ( mapContactIdUserId.containsKey( contactId ) ) {
                        pse__Proj__Share prShare = NSP_portalUserSharing.createProjectShare(
                            project.Id ,
                            mapContactIdUserId.get( contactId )
                        );
                        projectShareList.add( prShare );
                    }
                }
            }
        }
        return projectShareList;
    }

    private static pse__Proj__Share createProjectShare( Id projectId , Id userId ) {
        pse__Proj__Share prjShare = new pse__Proj__Share();
        prjShare.RowCause = Schema.pse__Proj__Share.RowCause.InsperitySharing__c;
        prjShare.UserOrGroupId = userId;
        prjShare.AccessLevel = NSP_ServiceConstants.readAccess;
        prjShare.ParentId = projectId;
        return prjShare;
    }

    private static  List<pse__Project_Task__Share >  generateProjectTaskShareList(
        Map<Id,Id> mapContactIdUserId ,
        Map<Id,Set<Id>> mapAccountIdSetContactId
        )
    {
        List<pse__Project_Task__Share> projectTaskShareList = new List<pse__Project_Task__Share>();
        for ( pse__Project_Task__c projectTask : [
                    SELECT
                        Id ,
                        pse__Project__c ,
                        pse__Project__r.pse__Account__c ,
                        NSP_Visible_to_Client__c
                    FROM pse__Project_Task__c
                    WHERE (
                        ( pse__Project__r.pse__Account__c IN :mapAccountIdSetContactId.keySet() )
                        AND ( NSP_Visible_to_Client__c = true )
                        AND ( pse__Project__c != null )
                    )
                ]
            )
        {

            if ( mapAccountIdSetContactId.containsKey( projectTask.pse__Project__r.pse__Account__c )
                && !mapAccountIdSetContactId.get( projectTask.pse__Project__r.pse__Account__c ).isEmpty()
                )
            {
                for ( Id contactId : mapAccountIdSetContactId.get( projectTask.pse__Project__r.pse__Account__c)){
                    if ( mapContactIdUserId.containsKey( contactId ) ) {
                        pse__Project_Task__Share prShare = NSP_portalUserSharing.createProjectTaskShare(
                            projectTask.Id ,
                            mapContactIdUserId.get( contactId )
                        );
                        projectTaskShareList.add( prShare );
                    }
                }

            }
        }
        return projectTaskShareList;
    }

    private static pse__Project_Task__Share createProjectTaskShare( Id projectTaskId , Id userId ) {
        pse__Project_Task__Share prjTskShare = new pse__Project_Task__Share();
        prjTskShare.RowCause = Schema.pse__Project_Task__Share.RowCause.InsperitySharing__c;
        prjTskShare.UserOrGroupId = userId;
        prjTskShare.AccessLevel = NSP_ServiceConstants.readAccess;
        prjTskShare.ParentId = projectTaskId;
        return prjTskShare;
    }

    private static List<pse__Milestone__Share> generateMilestoneShareList(
        Map<Id,Id> mapContactIdUserId ,
        Map<Id,Set<Id>> mapAccountIdSetContactId
        )
    {
        List<pse__Milestone__Share> projectMilestoneShareList = new List<pse__Milestone__Share>();
        for ( pse__Milestone__c milestone : [
                    SELECT
                        Id ,
                        pse__Project__c ,
                        pse__Project__r.pse__Account__c ,
                        NSP_Visible_to_Client__c
                    FROM pse__Milestone__c
                    WHERE (
                        ( pse__Project__r.pse__Account__c IN :mapAccountIdSetContactId.keySet() )
                        AND ( NSP_Visible_to_Client__c = true )
                        AND ( pse__Project__c != null )
                    )
                ]
            )
        {
            if ( mapAccountIdSetContactId.containsKey( milestone.pse__Project__r.pse__Account__c )
                && !mapAccountIdSetContactId.get( milestone.pse__Project__r.pse__Account__c ).isEmpty()
                )
            {
                for ( Id contactId : mapAccountIdSetContactId.get( milestone.pse__Project__r.pse__Account__c ) ) {
                    if ( mapContactIdUserId.containsKey( contactId ) ) {
                        pse__Milestone__Share mlShare = NSP_portalUserSharing.createMilestoneShare(
                            milestone.Id ,
                            mapContactIdUserId.get( contactId )
                        );
                        projectMilestoneShareList.add( mlShare );
                    }
                }
            }
        }
        return projectMilestoneShareList;
    }

    private static pse__Milestone__Share createMilestoneShare( Id milestone , Id userId ) {
        pse__Milestone__Share mileShare = new pse__Milestone__Share();
        mileShare.RowCause = Schema.pse__Milestone__Share.RowCause.InsperitySharing__c;
        mileShare.UserOrGroupId = userId;
        mileShare.AccessLevel = NSP_ServiceConstants.readAccess;
        mileShare.ParentId = milestone;
        return mileShare;
    }

}
//