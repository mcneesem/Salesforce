public with sharing class GroupMembershipController {
    // test w/ GroupMembershipControllerTest (97%)
    private static final String CLASS_NAME = ' ~ GroupMembershipController';
    private static final String MANAGE_QUEUE_MEMBERSHIP = 'Manage_Queue_Membership';

    //
    //
    //

    public static Boolean saveGroupMemberships( GroupMembershipEvent__e event ) {
        String METHOD_NAME = 'saveGroupMemberships';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ event=' + event );
        System.debug(
            DEBUG_PREFIX
            + ' ~ UserInfo.getName=' + UserInfo.getName()
            + ' ~ UserInfo.getUserId=' + UserInfo.getUserId()
            + ' ~ UserInfo.getUserType=' + UserInfo.getUserType()
            + ' ~ UserInfo.getUserName=' + UserInfo.getUserName()
        );
        // only handle events in the context of the "Automated Process" User...
        // ~ only handle event created by a User with the "Manage Queue Membership" Custom Permission...
        Boolean eventPublished = False;
        if ( ( UserInfo.getUserType() == 'AutomatedProcess' )
            && String.isNotBlank( UserInfo.getUserName() )
            && ( UserInfo.getUserName().startsWith( 'autoproc@00d' ) )
            && ( event != null )
            && ( event.CreatedById != null )
            && CustomPermissionController.checkUserPermission( GroupMembershipController.MANAGE_QUEUE_MEMBERSHIP , event.CreatedById )
           )
        {
            // extract/validate the userId from the event...
            if ( ( event.UserId__c != null )
                && ( event.UserId__c InstanceOf Id )
                && ( Id.valueOf( event.UserId__c ).getSObjectType() == User.SObjectType )
               )
            {
                GroupMembershipController.recordId = event.UserId__c;
            }
            System.debug( DEBUG_PREFIX + ' ~ GroupMembershipController.raw=' + GroupMembershipController.raw );
            // only proceed when a User exists with the given Id...
            if ( GroupMembershipController.raw != null ) {
                // split the comma-separated GroupIdsLong__c value into a List of Strings...
                List<String> splitGroupIds = new List<String>();
                if ( String.isNotBlank( event.GroupIdsLong__c ) ) {
                    splitGroupIds = event.GroupIdsLong__c.split( ',' );
                }
                // execute DML insert/delete operations...
                Boolean modifiedRecords = GroupMembershipController.saveGroupMembershipsInternal(
                    event.CreatedById ,
                    splitGroupIds
                );
                if ( True || modifiedRecords ) {
                    // publish a new "save complete" GroupMembershipProcessedEvent__e...
                    // ~ UserId__c are monitored by c-queue-membership to refresh the component...
                    // ~ always publish to always refresh the front end component...
                    GroupMembershipProcessedEvent__e platformEvent = new GroupMembershipProcessedEvent__e();
                    platformEvent.UserId__c = GroupMembershipController.raw.Id;
                    List<GroupMembershipProcessedEvent__e> platformEvents = new List<GroupMembershipProcessedEvent__e>();
                    platformEvents.add( platformEvent );
                    List<Database.SaveResult> publishResults = EventBus.publish( platformEvents );
                    for ( Database.SaveResult publishResult : publishResults ) {
                        if ( publishResult.isSuccess() ) {
                            eventPublished = True;
                        }
                    }
                }
            }
        }
        System.debug( DEBUG_PREFIX + ' ~ eventPublished=' + eventPublished );
        return eventPublished;
    }

    //
    //
    //

    private static Boolean saveGroupMembershipsInternal( Id createdById , List<String> groupIds ) {
        String METHOD_NAME = 'saveGroupMembershipsInternal';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ groupIds=' + groupIds );
        //
        // build audit log of group membership changes...
        String newLine = '\n';
        String logBody = '';
        logBody += ' ~ START ~ now=' + System.now() + newLine;
        logBody += ' ~ ' + newLine;
        User requester = GroupMembershipController.getUserRecord( createdById );
        if ( requester != null ) {
            logBody += ' ~ REQUESTER ~ ' + GroupMembershipController.userToString( requester ) + newLine;
        }
        if ( ( groupIds != null ) && ( groupIds.size() > 0 ) ) {
            logBody += ' ~ REQUESTED ~ GroupIds=' + String.join( groupIds , ',' ) + newLine;
        }
        logBody += ' ~ ' + newLine;
        if ( GroupMembershipController.raw != null ) {
            logBody += ' ~ MEMBER ~ ' + GroupMembershipController.userToString( GroupMembershipController.raw ) + newLine;
        }
        //
        // build map of current queue memberships...
        // ~ map from Group.Id -> GroupMember
        Map<Id,GroupMember> currentQueueMembershipsMap = new Map<Id,GroupMember>(); // Group.Id -> GroupMember
        List<GroupMember> currentQueueMemberships = GroupMembershipController.queueMemberships;
        if ( ( currentQueueMemberships != null ) && ( currentQueueMemberships.size() > 0 ) ) {
            for ( GroupMember currentQueueMembership : currentQueueMemberships ) {
                currentQueueMembershipsMap.put( currentQueueMembership.GroupId , currentQueueMembership );
                logBody += ' ~ CURRENT ~ ' + GroupMembershipController.groupToString( currentQueueMembership.Group ) + newLine;
            }
        }
        logBody += ' ~ ' + newLine;
        //
        // determine which queue memberships to insert/keep...
        Map<Id,GroupMember> keepQueueMembershipsMap = new Map<Id,GroupMember>(); // Group.Id -> GroupMember
        List<GroupMember> queueMembershipInserts = new List<GroupMember>();
        if ( ( groupIds != null ) && ( groupIds.size() > 0 ) ) {
            Map<Id,Group> groupMap = GroupMembershipController.getGroupMap( groupIds );
            for ( String groupId : groupIds ) {
                if ( ( groupId InstanceOf Id )
                    && ( Id.valueOf( groupId ).getSObjectType() == Group.getSObjectType() )
                   )
                {
                    if ( currentQueueMembershipsMap != null ) {
                        if ( currentQueueMembershipsMap.containsKey( groupId ) ) {
                            GroupMember queueMembership = currentQueueMembershipsMap.get( groupId );
                            keepQueueMembershipsMap.put( groupId , queueMembership );
                            System.debug( DEBUG_PREFIX + ' ~ KEEP ~ queueMembership=' + queueMembership );
                        } else {
                            GroupMember queueMembership = new GroupMember(
                                UserOrGroupId=GroupMembershipController.raw.Id ,
                                GroupId=groupId
                            );
                            queueMembershipInserts.add( queueMembership );
                            // logging...
                            System.debug( DEBUG_PREFIX + ' ~ ADD ~ queueMembership=' + queueMembership );
                            String logMessage = 'Group:{Id=' + groupId + '}';
                            if ( ( groupMap != null ) && groupMap.containsKey( groupId ) ) {
                                logMessage = GroupMembershipController.groupToString( groupMap.get( groupId ) );
                            }
                            logBody += ' ~ ADD ~ ' + logMessage + newLine;
                        }
                    }
                }
            }
        }
        //
        // determine which queue memberships to remove...
        List<GroupMember> queueMembershipRemovals = new List<GroupMember>();
        if ( ( currentQueueMemberships != null ) && ( currentQueueMemberships.size() > 0 ) ) {
            for ( GroupMember queueMembership : currentQueueMemberships ) {
                if ( ! keepQueueMembershipsMap.containsKey( queueMembership.GroupId ) ) {
                    queueMembershipRemovals.add( queueMembership );
                    System.debug( DEBUG_PREFIX + ' ~ REMOVE ~ queueMembership=' + queueMembership );
                    logBody += ' ~ REMOVE ~ ' + GroupMembershipController.groupToString( queueMembership.Group ) + newLine;
                }
            }
        }
        logBody += ' ~ ' + newLine;
        //
        // wrap the full save plus logging in a single transaction...
        Boolean modifiedRecords = False;
        SavePoint sp = Database.setSavepoint();
        try {
            // deferred insert DML...
            logBody += ' ~ INSERT ~ queueMembershipInserts=' + queueMembershipInserts + newLine;
            System.debug( DEBUG_PREFIX + ' ~ queueMembershipInserts=' + queueMembershipInserts );
            if ( ( queueMembershipInserts != null ) && ( queueMembershipInserts.size() > 0 ) ) {
                System.debug( DEBUG_PREFIX + ' ~ queueMembershipInserts.size=' + queueMembershipInserts.size() );
                insert queueMembershipInserts;
                modifiedRecords = True;
            }
            // deferred delete DML...
            logBody += ' ~ DELETE ~ queueMembershipRemovals=' + queueMembershipRemovals + newLine;
            System.debug( DEBUG_PREFIX + ' ~ queueMembershipRemovals=' + queueMembershipRemovals );
            if ( ( queueMembershipRemovals != null ) && ( queueMembershipRemovals.size() > 0 ) ) {
                System.debug( DEBUG_PREFIX + ' ~ queueMembershipRemovals.size=' + queueMembershipRemovals.size() );
                delete queueMembershipRemovals;
                modifiedRecords = True;
            }
            // logging...
            logBody += ' ~ RESPONSE ~ modifiedRecords=' + modifiedRecords + newLine;
            logBody += ' ~ ' + newLine;
            logBody += ' ~ END ~ now=' + System.now() + newLine;
            GroupMembershipController.saveLog( logBody );
        } catch ( Exception e ) {
            System.debug( DEBUG_PREFIX + ' ~ CATCH ~ e=' + e );
            Database.rollback( sp );
            //if ( Test.isRunningTest() ) {
            //    throw e;
            //}
        }
        System.debug( DEBUG_PREFIX + ' ~ modifiedRecords=' + modifiedRecords );
        return modifiedRecords;
    }

    @future private static void saveLog( String logBody ) {
        if ( String.isNotBlank( logBody ) ) {
            GroupMembershipLog__c log = new GroupMembershipLog__c(
                Body__c=logBody
            );
            insert log;
        }
    }

    private static String groupToString( Group record ) {
        String response = '';
        if ( record != null ) {
            response = 'Group:{'
                + 'Id=' + record.Id + ', '
                + 'Name=' + record.Name + ', '
                + 'DeveloperName=' + record.DeveloperName
                + '}';
        }
        return response;
    }

    private static String userToString( User record ) {
        String response = '';
        if ( record != null ) {
            response = 'User:{'
                + 'Id=' + record.Id + ', '
                + 'Name=' + record.Name + ', '
                + 'Username=' + record.Username
                + '}';
        }
        return response;
    }

    //
    //
    //

    private static String recordId {
        private get {
            return recordId;
        }
        private set {
            recordId = value;
        }
    }

    private static User raw {
        private get {
            if ( raw == null ) {
                raw = GroupMembershipController.getUserRecord( GroupMembershipController.recordId );
            }
            return raw;
        }
        private set;
    }

    private static User getUserRecord( String userId ) {
        User userRecord = null;
        if ( String.isNotBlank( userId )
            && ( userId InstanceOf Id )
            && ( Id.valueOf( userId ).getSObjectType() == User.getSObjectType() )
           )
        {
            List<User>  userRecords = [
                SELECT
                Id ,
                Name ,
                Username ,
                CreatedDate
                FROM User
                WHERE ( Id = :userId )
            ];
            if((userRecords != null) && (userRecords.size()>0)){
                userRecord = userRecords[0];
            }
        }
        return userRecord;
    }

    //
    //
    //

    private static List<GroupMember> queueMemberships {
        private get {
            if ( queueMemberships == null ) {
                queueMemberships = GroupMembershipController.selectGroupMemberships( 'Queue' );
            }
            return queueMemberships;
        }
        private set;
    }

    private static List<GroupMember> selectGroupMemberships( String groupType ) {
        List<GroupMember> groupMembers = new List<GroupMember>();
        if ( ( GroupMembershipController.raw != null )
            && ( GroupMembershipController.raw.Id != null )
            && String.isNotBlank( groupType )
           )
        {
            groupMembers = [
                SELECT
                    Id , 
                    GroupId ,
                    Group.Id ,
                    Group.Name ,
                    Group.DeveloperName ,
                    SystemModstamp
                FROM GroupMember
                WHERE (
                    ( UserOrGroupId = :GroupMembershipController.raw.Id )
                    AND ( Group.Type = :groupType )
                )
                ORDER BY Group.Name ASC 
            ];
            //AND ( Group.QueueRoutingConfigId != null ) // Omni-Channel Enabled Queues
        }
        return groupMembers;
    }

    //
    //
    //

    private static Map<Id,Group> getGroupMap( List<String> groupIds ) {
        Map<Id,Group> groupMap = new Map<Id,Group>();
        if ( ( groupIds != null ) && ( groupIds.size() > 0 ) ) {
            List<Group> groupRecords = [
                SELECT
                Id ,
                Name ,
                DeveloperName
                FROM Group
                WHERE ( Id IN :groupIds )
            ];
            if ( ( groupRecords != null ) && ( groupRecords.size() > 0 ) ) {
                groupMap = new Map<Id,Group>( groupRecords );
            }
        }
        return groupMap;
    }

    //
    //
    //

}
//