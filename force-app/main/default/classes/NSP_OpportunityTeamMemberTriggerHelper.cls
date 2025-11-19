public with sharing class NSP_OpportunityTeamMemberTriggerHelper {
    // test w/ NSP_OpportunityTeamMemberTriggerTest (85%)

    // Iterates through OpportunityTeamMember records and passes the required attributes to other methods.
    public void afterInsertDirector( List<OpportunityTeamMember> newList , Map<Id,OpportunityTeamMember> newMapDEPRECATED ) {
        try {
            Set<Id> opportunityIds = new Set<Id>();
            for ( OpportunityTeamMember oppTeamMemberObj : newList ) {
                if ( ( oppTeamMemberObj.TeamMemberRole == NSP_IntegrationConstants.BPAROLE )
                    || ( oppTeamMemberObj.TeamMemberRole == NSP_IntegrationConstants.BPCROLE )
                    )
                {
                    opportunityIds.add( oppTeamMemberObj.OpportunityId );
                }
            }
            IntegrationSyncController.setReadyForIntegrationSync(
                opportunityIds ,
                OpportunityTeamMember.getSObjectType()
            );
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
            IntegrationSyncController.setReadyForIntegrationSync(
                opptyIdSetToUpdateResyncFlag ,
                OpportunityTeamMember.getSObjectType()
            );
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