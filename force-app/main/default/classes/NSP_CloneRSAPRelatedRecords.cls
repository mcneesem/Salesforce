public without sharing class NSP_CloneRSAPRelatedRecords {
    // test w/ NSP_CloneRSAPRelatedRecordsTest (78%)

    @InvocableMethod(label='Clone Related RSAP Records' description='This method clones related RSAP records' category='NSP_Initiative__c')
    public static List<FlowOutputvalues> cloneRelatedRSAPRecords( List<FlowInputvalues> flowinput ) {
        FlowInputvalues input = flowinput[0];
        List<FlowOutputvalues> outputList = new List<FlowOutputvalues>();
        FlowOutputvalues output = new FlowOutputvalues();
        List<NSP_Engagement_Path__c> relatedEngagementRecords = [
            SELECT
                Id ,
                Action__c ,
                Name ,
                NSP_Actual_End_Date__c ,
                NSP_Initiative__c ,
                NSP_Service_Provider__c ,
                NSP_Start_Date__c ,
                NSP_Status__c ,
                NSP_Target_Date__c
            FROM NSP_Engagement_Path__c
            WHERE ( Relationship_Strategy_Action_Plan__c = :input.oldRSAPId )
        ];
        List<NSP_Initiative__c> relatedInitiativeRecords = [
            SELECT
                Id ,
                Initiative_Type__c ,
                Name ,
                NSP_Business_Drivers__c ,
                NSP_Relationship_Strategy_Action_Plan__c ,
                NSP_Status__c
            FROM NSP_Initiative__c
            WHERE ( NSP_Relationship_Strategy_Action_Plan__c = :input.oldRSAPId )
        ];
        FlowOutputvalues validateResponse = validateRSAPRelatedRecords(relatedInitiativeRecords, relatedEngagementRecords);
        if(validateResponse.isSuccess == TRUE) {
            FlowOutputvalues cloneResponse = cloneRecords(flowinput[0].oldRSAPId, flowinput[0].newRSAPName, relatedInitiativeRecords, relatedEngagementRecords);
            if(cloneResponse.isSuccess == TRUE) {
                output.isSuccess = TRUE;
                output.message = cloneResponse.message;
                output.clonedRecordId = cloneResponse.clonedRecordId;
            } else {
                // Error
                output.isSuccess = false;
                output.message = cloneResponse.message;
            }
        } else {
            // Error
            output.isSuccess = false;
            output.message = validateResponse.message;
        }
        //output.clonedRecordId = flowinput[0].oldRSAPId;
        outputList.add(output);
        return outputList;
    }

    private static FlowOutputvalues validateRSAPRelatedRecords( List<NSP_Initiative__c> relatedInitiativeRecords , List<NSP_Engagement_Path__c> relatedEngagementRecords ) {
        FlowOutputvalues output = new FlowOutputvalues();
        // If related Initiative records are empty then throw error condition
        if(relatedInitiativeRecords.isEmpty()) {
            output.isSuccess = FALSE;
            output.message = 'Related Initiative records not present to clone. Please check related records and try again!';
        } else {
            Map<Id, List<NSP_Engagement_Path__c>> initiativeRelatedEPMap = new Map<Id, List<NSP_Engagement_Path__c>>();
            Map<Id, NSP_Initiative__c> initiativeMap = new Map<Id, NSP_Initiative__c>();
            for(NSP_Initiative__c initiativeRec : relatedInitiativeRecords) {
                initiativeMap.put(initiativeRec.Id, initiativeRec);
                if(!initiativeRelatedEPMap.containsKey(initiativeRec.Id)) {
                    initiativeRelatedEPMap.put(initiativeRec.Id, new List<NSP_Engagement_Path__c>());
                }
                for(NSP_Engagement_Path__c engagementRec : relatedEngagementRecords) {
                    if(initiativeRec.Id == engagementRec.NSP_Initiative__c) {
                        initiativeRelatedEPMap.get(initiativeRec.Id).add(engagementRec);
                    }
                }
            }
            // Condition 1: (check1) When Engagement path is in progress or not started and Initiative is completed, then error should come and stop the cloning
            Boolean check1 = false;
            for(Id initiativeId : initiativeRelatedEPMap.keySet()) {
                NSP_Initiative__c initiativeRec = initiativeMap.get(initiativeId);
                if(initiativeRec.NSP_Status__c == 'Complete') {
                    for(NSP_Engagement_Path__c engagementRec : initiativeRelatedEPMap.get(initiativeId)) {
                        if(engagementRec.NSP_Status__c != 'Complete') {
                            check1 = true;
                        }
                    }
                }
            }
            if(check1 == true) {
                output.isSuccess = FALSE;
                output.message = 'There is an open Engagement Path associated with a closed Initiative. Correct the issue to clone.';
            } else {
                output.isSuccess = TRUE;
            }
        }
        return output;
    }

    private static FlowOutputvalues cloneRecords(
        String oldRSAPId ,
        String newRSAPName ,
        List<NSP_Initiative__c> relatedInitiativeRecords ,
        List<NSP_Engagement_Path__c> relatedEngagementRecords
        )
    {
        FlowOutputvalues output = new FlowOutputvalues();
        try {
            List<NSP_Relationship_Strategy_Action_Plan__c> rsapRec = [
                SELECT Id , Name , NSP_Account__c
                FROM NSP_Relationship_Strategy_Action_Plan__c
                WHERE ( Id = :oldRSAPId )
            ];
            if ( !rsapRec.isEmpty() ) {
                // Clone parent record i.e NSP_Relationship_Strategy_Action_Plan__c
                NSP_Relationship_Strategy_Action_Plan__c cloneRsapRec = new NSP_Relationship_Strategy_Action_Plan__c();
                cloneRsapRec.Name = newRSAPName;
                cloneRsapRec.NSP_Account__c = rsapRec[0].NSP_Account__c;
                insert cloneRsapRec;
                // Clone Inititative records
                Map<Id, Id> oldInitiativeIdWithnewInitiative = cloneInitiatives(relatedInitiativeRecords, cloneRsapRec.Id);
                cloneEngagementPaths(relatedEngagementRecords, cloneRsapRec.Id, oldInitiativeIdWithnewInitiative);
                output.isSuccess = TRUE;
                output.message = 'Records cloned successfully!';
                output.clonedRecordId = cloneRsapRec.Id;
            }
        } catch ( Exception e ) {
            output.isSuccess = FALSE;
            output.message = 'Exception while cloning - ' + e.getMessage();
        }
        return output;
    }

    private static Map<Id,Id> cloneInitiatives( List<NSP_Initiative__c> inputInitiatives , Id inputId ) {
        Map<Id,NSP_Initiative__c> initiativeRecords = new Map<Id,NSP_Initiative__c>();
        Map<Id,Id> oldInitiativeIdWithnewInitiative = new Map<Id,Id>();
        for ( NSP_Initiative__c initiative : inputInitiatives ) {
            if ( ( initiative.NSP_Status__c == 'Not Started' )
                || ( initiative.NSP_Status__c == 'In Progress' )
                )
            {
                NSP_Initiative__c clonedInitiative = initiative.clone();
                clonedInitiative.NSP_Relationship_Strategy_Action_Plan__c = inputId;
                initiativeRecords.put( initiative.Id , clonedInitiative );
            }
        }
        List<NSP_Initiative__c> response = new List<NSP_Initiative__c>(); // This response variable will store data of successfully inserted records
        if ( !initiativeRecords.values().isEmpty() ) {
            List<Database.SaveResult> results = Database.insert( initiativeRecords.values() , false );
            for ( Id oldId : initiativeRecords.keyset() ) {
                NSP_Initiative__c clonedInitiative = initiativeRecords.get( oldId );
                if ( clonedInitiative.Id != null ) {// This means Id is present then above database.insert has created record
                    oldInitiativeIdWithnewInitiative.put( oldId , clonedInitiative.Id );
                }
            }
            NSP_ErrorLogHandler.logResults(
                NSP_CloneRSAPRelatedRecords.class.getName() ,
                'cloneInitiatives' ,
                results
            );
        }
        return oldInitiativeIdWithnewInitiative;
    }

    private static void cloneEngagementPaths(
        List<NSP_Engagement_Path__c> lstEngagementPath ,
        Id inputId ,
        Map<Id,Id> oldInitiativeIdWithnewInitiative
        )
    {
        List<NSP_Engagement_Path__c> engagementRecords = new List<NSP_Engagement_Path__c>();
        for ( NSP_Engagement_Path__c engagementPath : lstEngagementPath ) {
            if ( ( oldInitiativeIdWithnewInitiative != null )
                && oldInitiativeIdWithnewInitiative.containsKey( engagementPath.NSP_Initiative__c )
                )
            {
                if ( ( engagementPath.NSP_Status__c == 'Not Started' )
                    || ( engagementPath.NSP_Status__c == 'In Progress' )
                    )
                {
                    NSP_Engagement_Path__c clonedEngagementPath = engagementPath.clone();
                    clonedEngagementPath.Relationship_Strategy_Action_Plan__c = inputId;
                    clonedEngagementPath.NSP_Initiative__c = oldInitiativeIdWithnewInitiative.get( engagementPath.NSP_Initiative__c );
                    engagementRecords.add( clonedEngagementPath );
                }
            }
        }
        if ( !engagementRecords.isEmpty() ) {
            List<Database.SaveResult> results = Database.insert( engagementRecords , false );
            NSP_ErrorLogHandler.logResults(
                NSP_CloneRSAPRelatedRecords.class.getName() ,
                'cloneEngagementPaths' ,
                results
            );
        }
    }

    public class FlowInputvalues{
        @InvocableVariable(label='Old RSAP Id' description='Store RSAP Record Id' required=true)
        public String oldRSAPId;
        @InvocableVariable(label='New RSAP Name' description='Store New RSAP Record Name' required=true)
        public String newRSAPName;
    }

    public class FlowOutputvalues{
        @InvocableVariable(label='Is Success' description='Is Success' required=true)
        public Boolean isSuccess;
        @InvocableVariable(label='Result Message' description='Result Message' required=true)
        public String message;
        @InvocableVariable(label='Cloned Record Id' description='Cloned Record Id')
        public String clonedRecordId;
    }

}
//