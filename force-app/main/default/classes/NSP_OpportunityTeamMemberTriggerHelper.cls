public with sharing class NSP_OpportunityTeamMemberTriggerHelper {
    // test w/ NSP_OpportunityTeamMemberTriggerTest (90%)

    // Iterates through OpportunityTeamMember records and passes the required attributes to other methods.
    public void afterInsertDirector( List<OpportunityTeamMember> newList , Map<Id,OpportunityTeamMember> newMapDEPRECATED ) {
        try {
            Set<Id> oppIdSet = new Set<Id>();
            for ( OpportunityTeamMember oppTeamMemberObj : newList ) {
                if ( ( oppTeamMemberObj.TeamMemberRole == NSP_IntegrationConstants.BPAROLE )
                    || ( oppTeamMemberObj.TeamMemberRole == NSP_IntegrationConstants.BPCROLE )
                    )
                {
                    oppIdSet.add( oppTeamMemberObj.OpportunityId );
                }
            }
            if ( !oppIdSet.isEmpty() ) {
                List<Opportunity> oppList = new List<Opportunity>();
                for ( Id oppId : oppIdSet ) {
                    Opportunity oppObj = new Opportunity();
                    oppObj.Id = oppId;
                    oppObj.NSP_Ready_for_Integration_Sync__c = true;
                    oppList.add( oppObj );
                }
                if ( !oppList.isEmpty() ) {
                    update oppList;
                }
            }
            NSP_EnrollmentFeePaymentSharing.onOppTeamMemberInsert( newList );
        } catch ( Exception e ) {
            NSP_OpportunityTeamMemberTriggerHelper.handleException( e , 'afterInsertDirector' );
        }
    }

    // Iterates through OpportunityTeamMember records and passes the required attributes to other methods.
    public void afterUpdateDirector( Map<Id,OpportunityTeamMember> newMap , Map<Id,OpportunityTeamMember> oldMap ) {
        try {
            Map<Id,OpportunityTeamMember> newOpptyMap = new Map<Id,OpportunityTeamMember>();
            Map<Id,OpportunityTeamMember> oldOpptyMap = new Map<Id,OpportunityTeamMember>();
            for ( OpportunityTeamMember opptyTeamMemberObj : newMap.values() ) {
                if ( ( opptyTeamMemberObj.TeamMemberRole != oldMap.get( opptyTeamMemberObj.Id ).TeamMemberRole )
                    && (
                        ( opptyTeamMemberObj.TeamMemberRole == NSP_IntegrationConstants.BPAROLE )
                        || ( opptyTeamMemberObj.TeamMemberRole == NSP_IntegrationConstants.BPCROLE )
                        )
                    )
                {
                    newOpptyMap.put( opptyTeamMemberObj.Id , opptyTeamMemberObj );
                    oldOpptyMap.put( opptyTeamMemberObj.Id , oldMap.get( opptyTeamMemberObj.Id ) );
                }
            }
            Set<Id> opptyIdSetToUpdateResyncFlag = new Set<Id>();
            NSP_SObjectUpdateTriggerHelper sObjectUpdateObj = new NSP_SObjectUpdateTriggerHelper();
            opptyIdSetToUpdateResyncFlag.addAll(
                sObjectUpdateObj.fetchUpdFieldsLst(
                    NSP_IntegrationConstants.SOBJECT_OPPORTUNITYTEAMMEMBER ,
                    (Map<Id,sObject>)newOpptyMap ,
                    (Map<Id,sObject>)oldOpptyMap
                )
            );
            if ( !opptyIdSetToUpdateResyncFlag.isEmpty() ) {
                List<Opportunity> updateOppList = new List<Opportunity>();
                for ( Id opptyId : opptyIdSetToUpdateResyncFlag ) {
                    Opportunity oppObj = new Opportunity();
                    oppObj.Id = opptyId;
                    oppObj.NSP_Ready_for_Integration_Sync__c = true;
                    updateOppList.add( oppObj );
                }
                if ( !updateOppList.isEmpty() ) {
                    update updateOppList;
                }
            }
        } catch ( Exception e ) {
            NSP_OpportunityTeamMemberTriggerHelper.handleException( e , 'afterUpdateDirector' );
        }
    }

    // Iterates through OpportunityTeamMember records and passes the required attributes to other methods.
    public void afterDeleteDirector( List<OpportunityTeamMember> oldList , Map<Id,OpportunityTeamMember> oldMapDEPRECATED ) {
        try {
            NSP_EnrollmentFeePaymentSharing.onOppTeamMemberDelete( oldList );
        } catch ( Exception e ) {
            NSP_OpportunityTeamMemberTriggerHelper.handleException( e , 'afterDeleteDirector' );
        }
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_OpportunityTeamMemberTriggerHelper.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_OpportunityTeamMemberTriggerHelper.class.getName() ,
            methodName ,
            e
        );
    }

}
//