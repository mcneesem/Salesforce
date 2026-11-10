public with sharing class NSP_ProjectDeleteController {
    // test w/ NSP_ProjectDeleteControllerTest (89%)

    //
    // method to fetch Ids of child records for deletion
    // @param  projectId
    // @return void
    //
    @auraEnabled
    public static void deepDeleteRecords( Id projectId ) {
        try {
            //check if parent project exists then don't allow delete of the project
            List<pse__Proj__c> projectObjList = [
                SELECT Id , pse__Parent_Project__c
                FROM pse__Proj__c
                WHERE ( Id = :projectId )
            ];
            if ( projectObjList.isEmpty()
                || ( projectObjList[0].pse__Parent_Project__c != null )
                )
            {
                throw new AuraHandledException( 'Please remove the association in Parent Project field before deleting this project.' );
            }
            //store record ID to delete
            Set<Id> recordToFetch = New Set<Id>();
            recordToFetch.add( projectId );
            Set<Id> recordToDeleteSet = New Set<Id>();
            //get related project task records to delete
            Set<Id> projectTaskSet = NSP_ProjectDeleteController.getRelatedChildRecords(
                recordToFetch ,
                'pse__Project_Task__c' ,
                'pse__Project__c'
            );
            //get project task assignment records related project task to delete
            Set<Id> projectTaskAssignmentSet = NSP_ProjectDeleteController.getRelatedChildRecords(
                projectTaskSet ,
                'pse__Project_Task_Assignment__c' ,
                'pse__Project_Task__c'
            );
            //get task time records related project task assignment to delete
            recordToDeleteSet.addAll(
                NSP_ProjectDeleteController.getRelatedChildRecords(
                    projectTaskAssignmentSet ,
                    'pse__Task_Time__c' ,
                    'pse__Project_Task_Assignment__c'
                )
            );
            //get related assignment records to delete
            recordToDeleteSet.addAll(
                NSP_ProjectDeleteController.getRelatedChildRecords(
                    recordToFetch ,
                    'pse__Assignment__c' ,
                    'pse__Project__c'
                )
            );
            //get related Budget records to delete
            recordToDeleteSet.addAll(
                NSP_ProjectDeleteController.getRelatedChildRecords(
                    recordToFetch ,
                    'pse__Budget__c' ,
                    'pse__Project__c'
                )
            );
            //get related timecard records to delete
            recordToDeleteSet.addAll(
                NSP_ProjectDeleteController.getRelatedChildRecords(
                    recordToFetch ,
                    'pse__Timecard_Header__c' ,
                    'pse__Project__c'
                )
            );
            //get related milestone records to delete
            recordToDeleteSet.addAll(
                NSP_ProjectDeleteController.getRelatedChildRecords(
                    recordToFetch ,
                    'pse__Milestone__c' ,
                    'pse__Project__c'
                )
            );
            List<Id> recordToDeleteList = new List<Id>( recordToDeleteSet );
            recordToDeleteList.add( projectId );
            //Delete List of Ids
            Database.delete( recordToDeleteList , true );
        } catch ( Exception e ) {
            throw new AuraHandledException( e.getMessage() );
        }
    }

    //
    // Dynamic method to intake Paramter and fetch records accordingly
    // @param  projectId,objectName,relationField
    // @return Set of Id fetched
    //
    public static Set<Id> getRelatedChildRecords( Set<Id> projectId , String objectName , String relationField ) {
        Set<Id> childRecordIdSet = New Set<Id>();
        if ( objectName == 'pse__Assignment__c' ) {
            for ( pse__Assignment__c childRecordInstance : [
                        SELECT Id , pse__Schedule__c
                        FROM pse__Assignment__c
                        WHERE ( pse__Project__c IN :projectId )
                    ]
                )
            {
                if ( childRecordInstance.pse__Schedule__c != null ) {
                    childRecordIdSet.add( childRecordInstance.pse__Schedule__c );
                }
                childRecordIdSet.add( childRecordInstance.Id );
            }
        } else {
            List<sObject> childRecordList = Database.query(
                'SELECT Id'
                + ' FROM '+ String.escapeSingleQuotes( objectName )
                + ' WHERE ( '+ String.escapeSingleQuotes( relationField ) +' IN :projectId )'
            );
            if ( !childRecordList.isEmpty() ) {
                childRecordIdSet.addAll(
                    new Map<Id,sObject>( childRecordList ).keySet()
                );
            }
        }
        return childRecordIdSet;
    }

    //
    // to check if logged in user is system Administrator
    // @param  none
    // @return true if logged in user is System admin else false
    //
    @auraEnabled public static Boolean getIsUserSystemAdmin() {
        try {
            List<Profile> userProfiles = [
                SELECT Id , Name
                FROM Profile
                WHERE ( Id = :userinfo.getProfileId() )
                LIMIT 1
            ];
            Profile userProfile = null;
            if ( ! userProfiles.isEmpty() ) {
                userProfile = userProfiles[0];
            }
            String userProfileName = null;
            if ( userProfile != null ) {
                userProfileName = userProfile.Name;
            }
            Boolean isAllowedDelete = False;
            if ( String.isNotBlank( userProfileName ) && userProfileName.startsWith( 'System Admin' ) ) {
                isAllowedDelete = True;
            }
            return isAllowedDelete;
        } catch( Exception e ) {
            throw new AuraHandledException( e.getMessage() );
        }
    }

}
//
