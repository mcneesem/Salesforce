public with sharing class NSP_portalUserUpdate implements Queueable {
    // test w/ NSP_AccountContactServiceHelperTest (83%)

    private Set<Id> userIdSet = new Set<Id>();
    private Boolean activeStatus = false;
    private Set<Id> permIdSet = new Set<Id>();
    private Set<Id> removePermUserIdSet = new Set<Id>();
    private Set<Id> permissionIdSet = new Set<Id>();

    public static void enqueueJob(
        Set<Id> userIdSet ,
        Boolean activeStatus ,
        Set<Id> permIdSet ,
        Set<Id> removePermUserIdSet ,
        Set<Id> permissionIdSet
        )
    {
        if ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) {
            System.enqueueJob(
                new NSP_portalUserUpdate(
                    userIdSet ,
                    activeStatus ,
                    permIdSet ,
                    removePermUserIdSet ,
                    permissionIdSet
                )
            );
        }
    }

    private NSP_portalUserUpdate(
        Set<Id> userIdSet ,
        Boolean activeStatus ,
        Set<Id> permIdSet ,
        Set<Id> removePermUserIdSet ,
        Set<Id> permissionIdSet
        )
    {
        this.userIdSet = userIdSet;
        this.activeStatus = activeStatus;
        this.permIdSet = permIdSet;
        this.removePermUserIdSet = removePermUserIdSet;
        this.permissionIdSet = permissionIdSet;
    }

    public void execute( QueueableContext context ) {
        try {
            NSP_portalUserUpdate.portalUsersActiveStatus(
                userIdSet ,
                activeStatus ,
                permIdSet ,
                removePermUserIdSet ,
                permissionIdSet
            );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_portalUserUpdate.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    // change the Active status of the user based on the account group relationship
    private static void portalUsersActiveStatus(
        Set<Id> userIdSet ,
        Boolean activeStatus ,
        Set<Id> permIdSet ,
        Set<Id> removePermUserIdSet ,
        Set<Id> permissionIdSet
        )
    {
        List<User> updatedUserList = new List<User>();
        for ( User usr : [
                    SELECT Id , IsActive
                    FROM User
                    WHERE ( Id IN :userIdSet )
                ]
            )
        {
            usr.isActive = activeStatus;
            updatedUserList.add( usr );
        }
        if ( !updatedUserList.isEmpty() ) {
            Database.update( updatedUserList , false );
            if ( !removePermUserIdSet.isEmpty() ) {
                NSP_AccountContactServiceHelper.removeUserPermissions(
                    removePermUserIdSet ,
                    permissionIdSet
                );
            }
        }
        if ( activeStatus ) {
            NSP_AccountContactServiceHelper.createUserPerm(
                userIdSet ,
                permIdSet
            );
        }
    }

}
//