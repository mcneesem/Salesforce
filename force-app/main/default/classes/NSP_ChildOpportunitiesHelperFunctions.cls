// This class should remain as "without sharing" as all its SOQL methods
// are called from updating a parent Opportunity by a User who may not have
// record visibility to the desired child Opportunities.
public without sharing class NSP_ChildOpportunitiesHelperFunctions {
    // test w/ NSP_OpportunityTriggerHelperTest (91%)

    public NSP_ChildOpportunitiesHelperFunctions() { }

    //
    // Updates the child opportunity with retirement service as product to close lost.
    // @param opportunityList lsit of New Opportunity.
    // @return void
    //
    public void updatesOnChildOpportunity( List<String> opportunityList ) {
        Id lockedOpportunityRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Opportunity' , 'Opportunity_Locked' );
        List<Opportunity> opportunityToUpdateList = new List<Opportunity>();
        // Querying the child oppotunities that is not closed lost and is not parent
        for ( Opportunity opportunityObject : [
                    SELECT
                        Id ,
                        StageName ,
                        NSP_PrimaryProduct__c ,
                        NSP_Parent_Opportunity__r.NSP_PrimaryProduct__c ,
                        NSP_Parent_Opportunity__r.NSP_Lost_Reason__c
                    FROM Opportunity
                    WHERE (
                        NSP_Parent_Opportunity__c IN :opportunityList
                        AND StageName != :NSP_SalesConstants.CLOSED_LOST
                        AND StageName != :NSP_SalesConstants.CLOSED_WON
                    )
                ]
            )
        {
            // Querying the child oppotunities that has product type as Retirement Services
            if ( opportunityObject.NSP_PrimaryProduct__c == NSP_SalesConstants.RETIREMENT_SERVICE ) {
                // Update the stage to closed lost on child optys
                opportunityObject.stagename = NSP_SalesConstants.CLOSED_LOST;
                // Entering the lost reason as well
                opportunityObject.Closed_Lost_Group__c = 'Retirement';
                opportunityObject.NSP_Lost_Reason__c = 'BPA lost prospect';
                opportunityObject.NSP_Is_Parent_Opportunity_Closed_Lost__c = TRUE;
                // ADO-340819
                // Update close date and lock record
                opportunityObject.CloseDate = Date.today();
                opportunityObject.RecordTypeId = lockedOpportunityRecordTypeId;
                opportunityToUpdateList.add( opportunityObject );
            }
            // 569718-Querying the child oppotunities that has product type as Non- Retirement Services
            if ( opportunityObject.NSP_PrimaryProduct__c != null
                && opportunityObject.NSP_PrimaryProduct__c != NSP_SalesConstants.RETIREMENT_SERVICE
                )
            {
                opportunityObject.NSP_Is_Parent_Opportunity_Closed_Lost__c = TRUE;
                opportunityToUpdateList.add( opportunityObject );
            }
        }
        // updating the child opportunity records
        if ( !opportunityToUpdateList.isEmpty() ) {
            try {
                List<Database.SaveResult> results = Database.update( opportunityToUpdateList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ChildOpportunitiesHelperFunctions.class.getName() ,
                    'updatesOnChildOpportunity' ,
                    results
                );
            } catch ( Exception e ) {
                NSP_ChildOpportunitiesHelperFunctions.handleException( e , 'updatesOnChildOpportunity' );
            }
        }
    }

    //
    // Updates when primary product is changed on parent opportunity from WO to WX or vice versa
    // @param opportunityList lsit of New Opportunity.
    // @return void
    //

    public void updateChildOpportunityOnProductChange( List<String> opportunityList ) {
        List<Opportunity> opportunityToUpdateList = new List<Opportunity>();
        //Querying the child oppotunities that has product type as Retirement Services
        //and is not closed lost and is not parent
        for ( Opportunity opportunityObject : [
                    SELECT Id , StageName
                    FROM Opportunity
                    WHERE (
                        NSP_Parent_Opportunity__c IN :opportunityList
                        AND NSP_PrimaryProduct__c = :NSP_SalesConstants.RETIREMENT_SERVICE
                        AND StageName != :NSP_SalesConstants.CLOSED_LOST
                    )
                ]
            )
        {
            //Update the stage to closed lost on child optys
            opportunityObject.NSP_Parent_Primary_Product_Changed__c = true;
            opportunityToUpdateList.add( opportunityObject );
        }
        // updating the child opportunity records
        if ( !opportunityToUpdateList.isEmpty() ) {
            try {
                List<Database.SaveResult> results = Database.update( opportunityToUpdateList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ChildOpportunitiesHelperFunctions.class.getName() ,
                    'updateChildOpportunityOnProductChange' ,
                    results
                );
            } catch ( Exception e ) {
                NSP_ChildOpportunitiesHelperFunctions.handleException( e , 'updateChildOpportunityOnProductChange' );
            }
        }
    }

    //
    // Description: Iterates through all new child Opportunties(Opportunity where NSP_Parent_Opportunity__c is populated)
    // and copies Client for Life value from parent opportunity to child opportunity
    // @return: void
    // Modification History:
    // -------------------------------------------------------------------------------------
    // author           | Date              | Description
    // -------------------------------------------------------------------------------------
    // Tejas          10-19-2021          created this new method
    //
    public static void defaultFieldsOnChildOpportunity( List<Opportunity> newChildOpportunityList , Set<Id> parentOpportunityIdsSet ) {
        Map<Id,Opportunity> parentOpportunityMap = new Map<Id,Opportunity>(
            [
                SELECT Id , NSP_PrimaryProduct__c , NSP_Client_For_Life__c
                FROM Opportunity
                WHERE Id IN :parentOpportunityIdsSet
            ]
        );
        for ( Opportunity opportunityObject : newChildOpportunityList ) {
            opportunityObject.NSP_Client_For_Life__c = parentOpportunityMap.get( opportunityObject.NSP_Parent_Opportunity__c ).NSP_Client_For_Life__c;
        }
    }

    //
    // 569718-Updates the NSP_Is_Parent_Opportunity_Closed_Won__c on open child opportunity to true.
    // @param opportunityList list of New Opportunity.
    // @return void
    //
    public void updatesOnOpenChildOpportunity( List<String> opportunityList ) {
        List<Opportunity> opportunityToUpdateList = new List<Opportunity>();
        for ( Opportunity opportunityObject : [
                    SELECT Id , StageName , NSP_PrimaryProduct__c , NSP_Parent_Opportunity__r.NSP_PrimaryProduct__c
                    FROM Opportunity
                    WHERE (
                        NSP_Parent_Opportunity__c IN :opportunityList
                        AND StageName != :NSP_SalesConstants.CLOSED_LOST
                        AND StageName !=: NSP_SalesConstants.CLOSED_WON
                    )
                ]
            )
        {
            opportunityObject.NSP_Is_Parent_Opportunity_Closed_Won__c = true;
            opportunityToUpdateList.add( opportunityObject );
        }
        // updating the child opportunity records
        if ( !opportunityToUpdateList.isEmpty() ) {
            try {
                List<Database.SaveResult> results = Database.update( opportunityToUpdateList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ChildOpportunitiesHelperFunctions.class.getName() ,
                    'updatesOnOpenChildOpportunity' ,
                    results
                );
            } catch ( Exception e ) {
                NSP_ChildOpportunitiesHelperFunctions.handleException( e , 'updatesOnOpenChildOpportunity' );
            }
        }
    }

    //
    // 569718-Updates the NSP_Is_Parent_Opportunity_Closed_Won__c on open child opportunity to true.
    // @param opportunityList list of New Opportunity.
    // @return void
    //
    public static void updateChildOpportunityOnReopen( List<String> opportunityList ) {
        List<Opportunity> opportunityToUpdateList = new List<Opportunity>();
        for ( Opportunity opportunityObject : [
                    SELECT
                        Id ,
                        StageName ,
                        NSP_Is_Parent_Opportunity_Closed_Lost__c ,
                        NSP_Is_Parent_Opportunity_Closed_Won__c
                    FROM Opportunity
                    WHERE (
                        NSP_Parent_Opportunity__c IN :opportunityList
                        AND ( NSP_Is_Parent_Opportunity_Closed_Lost__c = true
                            OR NSP_Is_Parent_Opportunity_Closed_Won__c = true )
                    )
                ]
            )
        {
            opportunityObject.NSP_Is_Parent_Opportunity_Closed_Lost__c = false;
            opportunityObject.NSP_Is_Parent_Opportunity_Closed_Won__c = false;
            opportunityToUpdateList.add( opportunityObject );
        }
        // updating the child opportunity records
        if ( !opportunityToUpdateList.isEmpty() ) {
            try {
                List<Database.SaveResult> results = Database.update( opportunityToUpdateList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ChildOpportunitiesHelperFunctions.class.getName() ,
                    'updateChildOpportunityOnReopen:update' ,
                    results
                );
            } catch ( Exception e ) {
                NSP_ChildOpportunitiesHelperFunctions.handleException( e , 'updateChildOpportunityOnReopen' );
            }
        }
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_ChildOpportunitiesHelperFunctions.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_ChildOpportunitiesHelperFunctions.class.getName() ,
            methodName ,
            e
        );
    }

}
//