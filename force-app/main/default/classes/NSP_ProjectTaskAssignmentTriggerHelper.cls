public with sharing class NSP_ProjectTaskAssignmentTriggerHelper {
    // test w/ NSP_ProjectTaskAssignmentTriggerHelpTest (92%)

    public static Boolean runAssignmentMethod = false;

    public void beforeInsertTaskAssignmentFilters( List<pse__Project_Task_Assignment__c> lProjectTaskAssignments ) {
        Set<Id> sContactIds = new Set<Id>();
        List<pse__Project_Task_Assignment__c> lTaskAssignments = new List<pse__Project_Task_Assignment__c>();
        for ( pse__Project_Task_Assignment__c oProjectTaskAssignment : lProjectTaskAssignments ) {
            if ( oProjectTaskAssignment.pse__Resource__c != null ) {
                sContactIds.add( oProjectTaskAssignment.pse__Resource__c );
                lTaskAssignments.add( oProjectTaskAssignment );
            }
        }
    }

    public void beforeUpdateTaskAssignmentFilters(
        Map<Id,pse__Project_Task_Assignment__c> mNewProjectTaskAssignments ,
        Map<Id,pse__Project_Task_Assignment__c> mOldProjectTaskAssignments
        )
    {
        Set<Id> sContactsIds = new Set<Id>();
        Set<Id> setOfProjectTaskId1 = new Set<Id> ();
        List<pse__Project_Task_Assignment__c> lTaskAssignments = new List<pse__Project_Task_Assignment__c>();
        List<pse__Project_Task_Assignment__c> listOfPTA1 = new List<pse__Project_Task_Assignment__c>();
        for ( pse__Project_Task_Assignment__c oTaskAssignment : mNewProjectTaskAssignments.values() ) {
            if ( ( oTaskAssignment.pse__Resource__c != null )
                && ( oTaskAssignment.pse__Resource__c != mOldProjectTaskAssignments.get( oTaskAssignment.Id ).pse__Resource__c )
                )
            {
                sContactsIds.add( oTaskAssignment.pse__Resource__c );
                lTaskAssignments.add( oTaskAssignment );
            }
            if ( ( oTaskAssignment.pse__Resource__c != null )
                && ( oTaskAssignment.pse__Resource__c != mOldProjectTaskAssignments.get( oTaskAssignment.Id ).pse__Resource__c )
                && ( oTaskAssignment.pse__Project_Task__c != null )
                )
            {
                listOfPTA1.add( oTaskAssignment );
                setOfProjectTaskId1.add( oTaskAssignment.pse__Project_Task__c );
            }
        }
    }

    public static void updateResourceOnInsert( Set<Id> projectTaskId , Set<Id> PTAIdSet , Id userId ) {
        Id peoRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Project_Task__c' , 'PEO_Project_Task' );
        Id bpsRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Project_Task__c' , 'BPS_Project_Task' );
        try {
            NSP_ProjectTaskAssignmentTriggerHelper.createPTAResourceFromAccountTeam(
                projectTaskId ,
                peoRecordTypeId ,
                bpsRecordTypeId ,
                userId
            );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTaskAssignmentTriggerHelper.class.getName() ,
                'updateResourceOnInsert' ,
                e
            );
        }
    }

    private static void createPTAResourceFromAccountTeam( Set<Id> projectTaskIds , Id peoRecordTypeId , Id bpsRecordTypeId , Id currentUserId ) {
        Map<Id,pse__Project_Task__c> projTaskMap = new Map<Id,pse__Project_Task__c>();
        Map<Id,Set<Id>> mapAccIdSetPrjId = new Map<Id,Set<Id>>();
        Map<String,List<NSP_Account_Team__c>> mapAccIdAccTeamList = new Map<String,List<NSP_Account_Team__c>>();
        List<pse__Project_Task_Assignment__c> lstPtAToUpdate = new List<pse__Project_Task_Assignment__c>();
        Map<Id,pse__Project_Task_Assignment__c> mapPTA = new Map<Id,pse__Project_Task_Assignment__c> ();
        Set<Id> accTeamUserContactSet = new Set<Id>();
        Map<Id,Id> mapUserIdContactId = new Map<Id,Id>();
        Map<Id,Id> projectTaskWithCreatedOwner = new Map<Id,Id>();
        Map<Id,Id> projectTaskWithOwner = new Map<Id,Id>();
        for ( pse__Project_Task__c pTask : Database.query( NSP_ProjectTaskAssignmentTriggerHelper.getProjectTaskQuery( projectTaskIds , peoRecordTypeId , bpsRecordTypeId ) ) ) {
            // populating Project Task Map
            projTaskMap.put( pTask.Id , pTask );
            // creating map of AccountId and Set Project Id
            if ( !mapAccIdSetPrjId.containsKey( pTask.pse__Project__r.pse__Account__c ) ) {
                mapAccIdSetPrjId.put( pTask.pse__Project__r.pse__Account__c , new Set<Id>() );
            }
            mapAccIdSetPrjId.get( pTask.pse__Project__r.pse__Account__c ).add( pTask.pse__Project__c );
        }
        if ( !mapAccIdSetPrjId.isEmpty() ) {
            for ( NSP_Account_Team__c accTeam : Database.query( NSP_ProjectTaskAssignmentTriggerHelper.getAccountTeamQuery( mapAccIdSetPrjId.keySet() ) ) ) {
                if ( !mapAccIdAccTeamList.containsKey( accTeam.NSP_Account__c ) ) {
                    mapAccIdAccTeamList.put( accTeam.NSP_Account__c , new List<NSP_Account_Team__c>() );
                }
                mapAccIdAccTeamList.get( accTeam.NSP_Account__c ).add( accTeam );
                accTeamUserContactSet.add( accTeam.NSP_User__c );
            }
            for ( Contact cont : Database.query( NSP_ProjectTaskAssignmentTriggerHelper.getContactQuery( accTeamUserContactSet ) ) ) {
                mapUserIdContactId.put( cont.pse__Salesforce_User__c , cont.Id );
            }
        }
        for ( pse__Project_Task_Assignment__c projTaskAssign : Database.query( NSP_ProjectTaskAssignmentTriggerHelper.getProjectTaskAssignQuery( projectTaskIds , peoRecordTypeId , bpsRecordTypeId ) ) ) {
            //project task owner to updated to created user if their is no primary accteam or role
            projectTaskWithCreatedOwner.put( projTaskAssign.pse__Project_Task__c , currentUserId );
            if ( projTaskMap.containsKey( projTaskAssign.pse__Project_Task__c )
                && mapAccIdAccTeamList?.containsKey( projTaskMap.get( projTaskAssign.pse__Project_Task__c )?.pse__Project__r.pse__Account__c )
                )
            {
                Id accountId = projTaskMap?.get( projTaskAssign.pse__Project_Task__c )?.pse__Project__r?.pse__Account__c;
                for ( NSP_Account_Team__c accTeam : mapAccIdAccTeamList?.get( accountId ) ) {
                    //this holds primary account/ if no primary account the alphabet order
                    if ( ( accTeam.NSP_User__c != null )
                        && !projectTaskWithOwner.containsKey( projTaskAssign.pse__Project_Task__c )
                        && ( projTaskAssign.pse__Resource_Role__c == accTeam.NSP_Role__c )
                        )
                    {
                        projectTaskWithOwner.put( projTaskAssign.pse__Project_Task__c , accTeam.NSP_User__c );
                    }
                    if ( ( projTaskAssign.pse__Resource_Role__c == accTeam.NSP_Role__c )
                        && !mapPTA.containsKey( projTaskAssign.Id )
                        )
                    {
                        //assigning the resource that exists in the accountTeam user and matches with Contact salesforce User.
                        mapPTA.put( projTaskAssign.Id , projTaskAssign );
                        projTaskAssign.pse__Resource__c = mapUserIdContactId.get( accTeam.NSP_User__c );
                        lstPtAToUpdate.add( projTaskAssign );
                        // Break after first match to ensure only ONE team member per role per account
                        break;
                    }
                }
            }
        }
        if ( !lstPtAToUpdate.isEmpty() ) {
            List<Database.UpsertResult> results = Database.upsert( lstPtAToUpdate , false );
            NSP_ErrorLogHandler.logResults(
                NSP_ProjectTaskAssignmentTriggerHelper.class.getName() ,
                'createPTAResourceFromAccountTeam' ,
                results
            );
        }
        NSP_ProjectTaskAssignmentTriggerHelper.updateProjectTaskOwner(
            projectTaskIds ,
            projectTaskWithOwner ,
            projectTaskWithCreatedOwner
        );
    }

    @TestVisible
    private static void updateProjectTaskOwner(
        Set<Id> projectTaskIds ,
        Map<Id,Id> projectTaskWithOwner ,
        Map<Id,Id> projectTaskWithCreatedOwner
        )
    {
        List<pse__Project_Task__c> lstProjTaskToUpdate = new List<pse__Project_Task__c>();
        for ( Id projectTaskId : projectTaskIds ) {
            if ( projectTaskWithOwner.containsKey( projectTaskId ) ) {
                lstProjTaskToUpdate.add(
                    new pse__Project_Task__c(
                        Id=projectTaskId ,
                        OwnerId=projectTaskWithOwner.get( projectTaskId )
                    )
                );
            } else if ( projectTaskWithCreatedOwner.containsKey( projectTaskId ) ) {
                lstProjTaskToUpdate.add(
                    new pse__Project_Task__c(
                        Id=projectTaskId ,
                        OwnerId=projectTaskWithCreatedOwner.get( projectTaskId )
                    )
                );
            }
        }
        if ( !lstProjTaskToUpdate.isEmpty() ) {
            List<Database.UpsertResult> results = Database.upsert( lstProjTaskToUpdate , false );
            NSP_ErrorLogHandler.logResults(
                NSP_ProjectTaskAssignmentTriggerHelper.class.getName() ,
                'updateProjectTaskOwner' ,
                results
            );
        }
    }

    public static String getProjectTaskAssignQuery( Set<Id> projectTaskIds , Id peoRecordTypeId , Id bpsRecordTypeId ) {
        String projTaskAssignmtQuery = new NSP_QueryBuilder(
                'pse__Project_Task_Assignment__c' ,
                new List<String>{
                    'Id' ,
                    'Name' ,
                    'pse__Project_Task__r.pse__Project__r.pse__Account__c' ,
                    'pse__Resource_Role__c' ,
                    'pse__Resource__c' ,
                    'pse__Project_Task__c' ,
                    'NSP_Priority__c' ,
                    'pse__Project_Task__r.NSP_isClonedFromAutomation__c'
                }
            )
            .addFilter( 'pse__Project_Task__c' , new List<Id>( projectTaskIds ) , NSP_QueryBuilder.Operator.INCLUDES )
            .addFilter( 'pse__Project_Task__r.RecordTypeId' , new List<Id>{ peoRecordTypeId , bpsRecordTypeId } , NSP_QueryBuilder.Operator.INCLUDES )
            .addFilter( 'pse__Project_Task__r.pse__Project__r.NSP_Auto_Resource_Project__c', true , NSP_QueryBuilder.Operator.EQUALS , false )
            .addFilter( 'pse__Project_Task__r.Owner.Type' , 'User' , NSP_QueryBuilder.Operator.EQUALS )
            .addFilter( 'pse__Project_Task__r.NSP_isClonedFromAutomation__c' , false , NSP_QueryBuilder.Operator.EQUALS , false )
            .orderBy( 'NSP_Priority__c' , 'ASC' , true )
            .build()
            ;
        return projTaskAssignmtQuery;
    }

    private static String getAccountTeamQuery( Set<Id> accountIds ) {
        String accTeamQuery = new NSP_QueryBuilder(
                'NSP_Account_Team__c' ,
                new List<String>{
                    'NSP_Account__c' ,
                    'NSP_Role__c' ,
                    'NSP_User__c' ,
                    'NSP_Primary__c' ,
                    'NSP_First_Name__c'
                }
            )
            .addFilter( 'NSP_Role__c' , null , NSP_QueryBuilder.Operator.NOT_EQUALS , false )
            .addFilter( 'NSP_Account__c', new List<Id>( accountIds ) , NSP_QueryBuilder.Operator.INCLUDES )
            .setSecurityEnforce( false )
            .build()
            + ' ORDER BY NSP_Primary__c DESC , NSP_First_Name__c ASC'
            ;
        return accTeamQuery;
    }

    public static String getProjectTaskQuery( Set<Id> projectTaskIds , Id peoRecordTypeId , Id bpsRecordTypeId ) {
        String projTaskQuery = new NSP_QueryBuilder(
                'pse__Project_Task__c' ,
                new List<String>{
                    'Id' ,
                    'OwnerId' ,
                    'pse__Number_of_Assignments__c' ,
                    'pse__Project__c' ,
                    'pse__Project__r.pse__Account__c' ,
                    'NSP_isClonedFromAutomation__c'
                }
            )
            .addFilter( 'Id' , new List<Id>( projectTaskIds ) , NSP_QueryBuilder.Operator.INCLUDES )
            .addFilter( 'pse__Project__r.NSP_Auto_Resource_Project__c' , true , NSP_QueryBuilder.Operator.EQUALS , false )
            .addFilter( 'RecordTypeId' , new List<Id>{ peoRecordTypeId , bpsRecordTypeId } , NSP_QueryBuilder.Operator.INCLUDES )
            .addFilter( 'NSP_isClonedFromAutomation__c' , false , NSP_QueryBuilder.Operator.EQUALS , false )
            .build()
            ;
        return projTaskQuery;
    }

    private static String getContactQuery( Set<Id> userIds ) {
        String contactQuery = new NSP_QueryBuilder(
                'Contact' ,
                new List<String>{
                    'Id' ,
                    'pse__Salesforce_User__c'
                }
            )
            .addFilter( 'pse__Is_Resource_Active__c' , true )
            .addFilter( 'pse__Is_Resource__c' , true )
            .addFilter( 'pse__Salesforce_User__c' , null , NSP_QueryBuilder.Operator.NOT_EQUALS , false )
            .addFilter( 'pse__Salesforce_User__c' , new List<Id>( userIds ) , NSP_QueryBuilder.Operator.INCLUDES )
            .build()
            ;
        return contactQuery;
    }

    public void afterInsertTaskAssignmentFilters(
        List<pse__Project_Task_Assignment__c> lProjectTaskAssignments ,
        Map<Id,pse__Project_Task_Assignment__c> mProjectTaskAssignments
        )
    {
        Set<Id> sContactIds = new Set<Id>();
        Set<Id> setOfProjectTaskId = new Set<Id> ();
        Map<Id,Id> mAssignmentToContact = new Map<Id,Id>();
        Set<Id> projectTaskAssSet = new Set<Id>();
        List<pse__Project_Task_Assignment__c> listOfPTA = new List<pse__Project_Task_Assignment__c>();
        for ( pse__Project_Task_Assignment__c oProjectTaskAssignment : lProjectTaskAssignments ) {
            if ( ( oProjectTaskAssignment.pse__Resource__c != null )
                && ( oProjectTaskAssignment.NSP_Project_Record_Type__c != NSP_ServiceConstants.PROJECT_RET_RECORDTYPE )
                && ( oProjectTaskAssignment.NSP_Project_Record_Type__c != NSP_ServiceConstants.PROJECT_BPS_RECORDTYPE )
                )
            {
                sContactIds.add( oProjectTaskAssignment.pse__Resource__c );
                mAssignmentToContact.put( oProjectTaskAssignment.Id , oProjectTaskAssignment.pse__Resource__c );
            }
            if ( oProjectTaskAssignment.pse__Project_Task__c != null ) {
                setOfProjectTaskId.add( oProjectTaskAssignment.pse__Project_Task__c );
            }
            if ( oProjectTaskAssignment.pse__Project_Task__c != null && !runAssignmentMethod ) {
                setOfProjectTaskId.add( oProjectTaskAssignment.pse__Project_Task__c );
                listOfPTA.add( oProjectTaskAssignment );
                projectTaskAssSet.add( oProjectTaskAssignment.Id );
            }
        }
        if ( !projectTaskAssSet.isEmpty() ) {
            Map<String,Object> mapInputParams = new Map<String,Object>{
                'projectTaskId' => setOfProjectTaskId ,
                'PTAIdSet' => projectTaskAssSet
            };
            List<NSP_ProjectTaskQueueEvent__e> lstTaskQueueEvent = new List<NSP_ProjectTaskQueueEvent__e>();
            lstTaskQueueEvent.add(
                new NSP_ProjectTaskQueueEvent__e(
                    NSP_Input_Parameters__c=JSON.serialize( mapInputParams ) ,
                    NSP_MethodName__c='updateResourceOnInsert' ,
                    NSP_UserId__c=UserInfo.getUserId()
                )
            );
            List<Database.SaveResult> results = EventBus.publish( lstTaskQueueEvent );
            NSP_ErrorLogHandler.logResults(
                NSP_ProjectTaskAssignmentTriggerHelper.class.getName() ,
                'afterInsertTaskAssignmentFilters' ,
                results
            );
        }
    }

    public void afterUpdateTaskAssignmentfilters(
        Map<Id,pse__Project_Task_Assignment__c> mNewProjectTaskAssignments ,
        Map<Id,pse__Project_Task_Assignment__c> mOldProjectTaskAssignments
        )
    {
        Set<Id> sContactIds = new Set<Id>();
        Map<Id,Id> mAssignmentToContact = new Map<Id,Id>();
        for ( pse__Project_Task_Assignment__c oProjectTaskAssignment : mNewProjectTaskAssignments.values() ) {
            if ( ( oProjectTaskAssignment.NSP_Project_Record_Type__c != NSP_ServiceConstants.PROJECT_RET_RECORDTYPE )
                && ( oProjectTaskAssignment.NSP_Project_Record_Type__c != NSP_ServiceConstants.PROJECT_BPS_RECORDTYPE )
                && ( oProjectTaskAssignment.pse__Resource__c != null )
                && ( oProjectTaskAssignment.pse__Resource__c != mOldProjectTaskAssignments.get( oProjectTaskAssignment.Id ).pse__Resource__c )
                )
            {
                sContactIds.add( oProjectTaskAssignment.pse__Resource__c );
                mAssignmentToContact.put( oProjectTaskAssignment.Id , oProjectTaskAssignment.pse__Resource__c );
            }
        }
    }

}
//