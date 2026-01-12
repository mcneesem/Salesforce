public with sharing class NSP_ValidateOpportunityStage {
    // test w/ NSP_ValidateOpportunityStageTest (84%)

    // ***************************************************************************************************************************
    //  ClassName:      NSP_ValidateOpportunityStage
    //  Description :   Class for validating Opportunity Stage changes based on various User criteria and sales process
    //                  criteria. Sales process criteria are stored in Opportunity_Stage_Validation__mdt custom metadata records.
    //                  The class provides methods to validate whether an Opportunity can move to a specific stage based on the
    //                  criteria defined in the metadata matching the Opportunity's Primary_Product__c and Stage fields. The
    //                  condition defined in each matching metadata record must be met or the Stage change will be prevented
    //                  and the corresponding error message in the metadata will be displayed to the user. Some metadata
    //                  records are grouped together. Grouped criteria are evaluated as follows:
    //                      1. When all records in a group are for same Object name (e.g., Event), at least one related record
    //                         (of specified Object) matching all the criteria in the group must be found or validation fails.
    //                      2. If group contains a Does Not Exist condition, validation fails if any related record matching
    //                         all the other group criteria is found. If the metadata records in the group are for Opportunity
    //                         object, validation fails if the Opportunity being validated matches all the other criteria
    //                         in the group.
    //                      3. When one or more records in a group is marked as a Group Condition, then the validation defined by
    //                         the entire group is only applicable when each Group Condition evaluates to true. If all Group
    //                         Conditions are not met, then the Opportunity or related object criteria in the group are not
    //                         required and the validation passes.
    // ***************************************************************************************************************************

    public static Set<String> validHRProducts = new Set<String>{NSP_SalesConstants.WO, NSP_SalesConstants.WS, NSP_SalesConstants.HRScale};
    private static Set<String> validHR360Products = new Set<String>{NSP_SalesConstants.WO, NSP_SalesConstants.WS, NSP_SalesConstants.HRScale};
    private static Boolean checkOnly = false;
    public static List<String> analysisStageCriteraTypes = System.Label.NSP_AnalysisStageCriteria.split(',');
    public static List<String> proposeStageCriteraTypes = System.Label.NSP_ProposeStageCriteria.split(',');
    public static List<String> exitCriteriaProductException = System.Label.NSP_ExitCriteriaProductException.split(',');
    public static List<String> ownerBasedCriteriaProducts = System.Label.NSP_OwnerBasedCriteriaProducts.split(',');
    public static List<String> nonOwnerBasedCriteriaProducts = System.Label.NSP_NonOwnerBasedCriteriaProducts.split(',');
    public static List<String> closeLostRoleinOpportunityTeam = System.Label.Close_Lost_Role_in_Opportunity_Team.split(',');
    private static List<Opportunity_Stage_Validation__mdt> optyStageVals = Opportunity_Stage_Validation__mdt.getAll().values();
    private static final String AGGREGATES = 'Aggregates';
    private static final String DEFAULT_PRODUCT = 'Default';
    private static final String ONLY_IF = 'Only If';
    private static final String OPPORTUNITY_OBJ = 'Opportunity';
    public static final String FAILED = 'Failed Stage Validation';
    private static final Integer ERROR_DOES_NOT_EXIST = 99; // unified error code value...

    //
    //
    //

    public static void validateOpportunityStage( Opportunity record , Boolean checkOnlyLocal ) {
        NSP_ValidateOpportunityStage.validateOpportunityStage( new List<Opportunity>{ record } , checkOnlyLocal );
    }

    public static void validateOpportunityStage( List<Opportunity> newList ) {
        NSP_ValidateOpportunityStage.validateOpportunityStage( newList , false );
    }

    public static void validateOpportunityStage( List<Opportunity> newList , Boolean checkOnlyLocal ) {
        NSP_ValidateOpportunityStage.checkOnly = checkOnlyLocal;
        List<Id> oppIdList = new List<Id>();
        List<Id> oppOwnerIdList = new List<Id>();
        oppOwnerIdList.add( UserInfo.getUserId() );
        for ( Opportunity opp : newList ) {
            oppIdList.add( opp.Id );
            oppOwnerIdList.add( opp.OwnerId );
        }
        Map<Id,User> opportunityOwnerRoleMap = getUserRole( oppOwnerIdList );

        try {
            Map<Id,Opportunity> oppRelatedObjectMap = new Map<Id,Opportunity>(
                [
                    SELECT
                        Id ,
                        AccountId ,
                        (
                            SELECT Id , Status , NSP_Task_Type__c , Subject
                            FROM Tasks
                            WHERE ( NSP_Task_Type__c != null )
                        ) ,
                        (
                            SELECT Id , NSP_Event_Subtype__c , NSP_Method__c , NSP_Status__c
                            FROM Events
                            WHERE (
                                ( NSP_Event_Subtype__c != null )
                                AND ( NSP_Status__c != :NSP_SalesConstants.Cancelled )
                            )
                        ) ,
                        (
                            SELECT Id
                            FROM OpportunityContactRoles
                        ) ,
                        (
                            SELECT Id , NSP_Percent_Split__c , NSP_Number_of_Employees__c
                            FROM Employee_Splits__r
                        ) ,
                        (
                            SELECT Id , Status__c , Checklist_Type__c
                            FROM Checklists__r
                        )
                    FROM Opportunity
                    WHERE ( Id IN :oppIdList )
                ]
            );
            Map<Id, SBQQ__Quote__c> oppQuoteMap = new Map<Id,SBQQ__Quote__c>(
                [
                    SELECT
                        Id ,
                        SBQQ__Status__c ,
                        NSP_Opportunity_Primary_Product__c ,
                        NSP_Client_For_Life__c
                    FROM SBQQ__Quote__c
                    WHERE (
                        ( SBQQ__Opportunity2__c IN :oppIdList )
                        AND ( SBQQ__Primary__c = true )
                    )
                ]
            );
            for ( Opportunity opp : newList ) {
                if ( String.isBlank( opp.StageName )
                    || ( NSP_ValidateOpportunityStage.hasAllowClosedLostPermission
                        && opp.StageName.equals( NSP_SalesConstants.CLOSED_LOST )
                        )
                    )
                {
                    continue;
                }

                Opportunity oppFromMap = oppRelatedObjectMap.get( opp.Id );

                Map<String,List<SObject>> valObjectMap = new Map<String,List<SObject>>();
                valObjectMap.put('Opportunity' , new List<SObject>{ opp });
                valObjectMap.put('Event' , oppFromMap?.Events);
                valObjectMap.put('Task' , oppFromMap?.Tasks);
                valObjectMap.put('OpportunityContactRole' , oppFromMap?.OpportunityContactRoles);
                valObjectMap.put('NSP_Employee_Split__c' , oppFromMap?.Employee_Splits__r);
                valObjectMap.put('NSP_Checklist__c' , oppFromMap?.Checklists__r);
                valObjectMap.put('SBQQ__Quote__c' , new List<SBQQ__Quote__c>{ oppQuoteMap.get(opp.SBQQ__PrimaryQuote__c) });
                ValObjectAggregates valObjectAgs = new ValObjectAggregates(oppFromMap?.Employee_Splits__r);

                List<Opportunity_Stage_Validation__mdt> currentOptyStageVals = NSP_ValidateOpportunityStage.getCurrentOptyStageVals( opp );
                List<Opportunity_Stage_Validation__mdt> singleOptyStageVals = NSP_ValidateOpportunityStage.getSingleStageVals( currentOptyStageVals );
                Map<String,List<Opportunity_Stage_Validation__mdt>> groupedStageValMap = NSP_ValidateOpportunityStage.getGroupedStageValMap( currentOptyStageVals );

                NSP_ValidateOpportunityStage.evaluateSingleCriteria( opp , valObjectMap , valObjectAgs , singleOptyStageVals );
                NSP_ValidateOpportunityStage.evaluateGroupedCriteria( opp , valObjectMap , valObjectAgs , groupedStageValMap );
                //Proposal
                if ( opp.StageName.equals( NSP_SalesConstants.PROPOSAL_STAGE ) ) {
                    evaluateQuoteCriteria( opp , oppQuoteMap );
                }
                //Closed Won
                if ( opp.StageName.equals( NSP_SalesConstants.CLOSED_WON ) ) {
                    //first check if primary quote is created and approved on primary products it is applicable on then check user based criteria
                    NSP_ValidateOpportunityStage.evaluateQuoteCriteria( opp , oppQuoteMap );
                    NSP_ValidateOpportunityStage.evaluateClosedWonStageCriteria( opp );
                }
                //Closed Lost
                if( opp.StageName.equals( NSP_SalesConstants.CLOSED_LOST ) ) {
                    NSP_ValidateOpportunityStage.evaluateClosedLostStageCriteria( opp , opportunityOwnerRoleMap );
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ValidateOpportunityStage.class.getName() ,
                'validateOpportunityStageNew' ,
                e
            );
        }
    }

    public class ValObjectAggregates {
        public Decimal EmpSplit_TotalNumEEs { get; set; }
        public Decimal EmpSplit_TotalPercentSplit { get; set; }

        public ValObjectAggregates( List<NSP_Employee_Split__c> empSplits ) {
            this.EmpSplit_TotalNumEEs = this.calculateEmployeeCount( empSplits );
            this.EmpSplit_TotalPercentSplit = this.calculatePercentSplit( empSplits );
        }

        public Decimal get( String key ) {
            Decimal retVal = 0;
            if ( key == 'EmpSplit_TotalNumEEs' ) {
                retVal = this.EmpSplit_TotalNumEEs;
            } else if ( key == 'EmpSplit_TotalPercentSplit') {
                retVal = this.EmpSplit_TotalPercentSplit;
            }
            return retVal;
        }

        private Decimal calculatePercentSplit( List<NSP_Employee_Split__c> empSplits ) {
            Decimal totalPercentSplit = 0;
            if ( ( empSplits != null ) && !empSplits.isEmpty() ) {
                for ( NSP_Employee_Split__c empSplit : empSplits ) {
                    totalPercentSplit += ( ( empSplit.NSP_Percent_Split__c != null ) ? empSplit.NSP_Percent_Split__c : 0 );
                }
            }
            return totalPercentSplit;
        }

        private Decimal calculateEmployeeCount( List<NSP_Employee_Split__c> empSplits ) {
            Decimal totalEmployees = 0;
            if ( ( empSplits != null ) && !empSplits.isEmpty() ) {
                for ( NSP_Employee_Split__c empSplit : empSplits ) {
                    totalEmployees += ( ( empSplit.NSP_Number_of_Employees__c != null ) ? empSplit.NSP_Number_of_Employees__c : 0 );
                }
            }
            return totalEmployees;
        }
    }

    private static void evaluateSingleCriteria(
        Opportunity opp ,
        Map<String,List<SObject>> valObjectMap ,
        ValObjectAggregates valObjectAgs ,
        List<Opportunity_Stage_Validation__mdt> singleOptyStageVals
        )
    {
        if ( singleOptyStageVals != null ) {
            for ( Opportunity_Stage_Validation__mdt val : singleOptyStageVals ) {
                Integer passCheckCount = 0;
                if ( String.isNotBlank( val.Object__c )
                    && ( val.Object__c.indexOf( AGGREGATES ) > -1 )
                    )
                {
                    passCheckCount = NSP_ValidateOpportunityStage.evaluateAggregateVal( opp , passCheckCount , valObjectAgs , val );
                } else {
                    passCheckCount = NSP_ValidateOpportunityStage.evaluateSingleVal( passCheckCount , valObjectMap , val );
                }
                NSP_ValidateOpportunityStage.addValError(
                    opp ,
                    passCheckCount ,
                    val.Error_Message__c
                );
            }
        }
    }

    private static Integer evaluateAggregateVal(
        Opportunity opp ,
        Integer passCheckCount ,
        ValObjectAggregates valObjectAgs ,
        Opportunity_Stage_Validation__mdt val
        )
    {
        if ( val != null ) {
            String valValue = val.Value__c;
            if ( String.isNotBlank( valValue ) && ( valValue.indexOf( 'Field Value: ' ) > -1 ) ) {
                Object fieldValue = opp.get( valValue.substringAfter( 'Field Value: ' ) );
                if ( fieldValue != null ) {
                    valValue = fieldValue.toString();
                }
            }
            if ( ( valObjectAgs != null )
                && NSP_ValidateOpportunityStage.checkCondition( valObjectAgs.get(val.Field__c) , valValue , val.Operation__c )
                )
            {
                passCheckCount++;
            }
        }
        return passCheckCount;
    }

    private static Integer evaluateSingleVal(
        Integer passCheckCount ,
        Map<String,List<SObject>> valObjectMap ,
        Opportunity_Stage_Validation__mdt val
        )
    {
        if ( ( val != null )
            && ( valObjectMap != null )
            && ( valObjectMap.get(val.Object__c) != null )
            )
        {
            for ( SObject valObject : valObjectMap.get(val.Object__c) ) {
                if ( NSP_ValidateOpportunityStage.checkCondition( valObject.get(val.Field__c) , val.Value__c , val.Operation__c ) ) {
                    passCheckCount++;
                }
            }
        }
        return passCheckCount;
    }

    private static void evaluateGroupedCriteria(
        Opportunity opp ,
        Map<String,List<SObject>> valObjectMap ,
        ValObjectAggregates valObjectAgs ,
        Map<String,List<Opportunity_Stage_Validation__mdt>> groupedStageValMap
        )
    {
        List<String> groupOrder = new List<String>(groupedStageValMap.keySet());
        groupOrder.sort();
        for ( String groupName : groupOrder ) {
            Boolean passCheck = false;
            Boolean passCheckDNE = true;
            String groupRelObjName = NSP_ValidateOpportunityStage.getGroupRelObjName( groupName , groupedStageValMap );
            Integer i = 0;
            if ( ( groupedStageValMap != null ) && ( valObjectMap != null ) ) {
                List<SObject> valObjectList = valObjectMap.get(groupRelObjName);
                do {
                    SObject valObject = ( ( valObjectList != null ) && ( valObjectList.size() > i ) ) ? valObjectList[i] : null;
                    Integer passCheckCount = NSP_ValidateOpportunityStage.evaluateOneCriteriaGroup(
                        opp ,
                        groupName ,
                        valObject , // must run even if valObject is null
                        valObjectAgs ,
                        groupedStageValMap
                    );

                    if( passCheckCount >= groupedStageValMap.get(groupName).size() ) {
                        passCheck = true;
                    }

                    if( passCheckCount == NSP_ValidateOpportunityStage.ERROR_DOES_NOT_EXIST ) { // when any record violates DOES NOT EXIST case
                        passCheckDNE = false;
                    }

                    i++;
                } while ( i < valObjectList.size() );
                NSP_ValidateOpportunityStage.addValError(
                    opp ,
                    passCheck ,
                    passCheckDNE ,
                    groupedStageValMap.get( groupName )[0].Error_Message__c
                );
            }
        }
    }

    private static void addValError(
        Opportunity opp ,
        String errMsg
        )
    {
        NSP_ValidateOpportunityStage.addValError(
            opp ,
            0 ,
            errMsg
        );
    }

    private static void addValError(
        Opportunity opp ,
        Integer passCheckCount ,
        String errMsg
        )
    {
        if( ( passCheckCount != null ) && ( passCheckCount < 1 ) ) {
            NSP_ValidateOpportunityStage.addValError(
                opp ,
                false ,
                true ,
                errMsg
            );
        }
    }

    private static void addValError(
        Opportunity opp ,
        Boolean passCheck ,
        Boolean passCheckDNE ,
        String errMsg
        )
    {
        if ( !opp.hasErrors()
            && ( !passCheck || !passCheckDNE )
            )
        {
            if ( checkOnly ) {
                opp.NextStep = NSP_ValidateOpportunityStage.FAILED;
            } else {
                opp.addError( errMsg );
            }
        }
    }

    private static Integer evaluateOneCriteriaGroup(
        Opportunity opp ,
        String groupName ,
        SObject valObject ,
        ValObjectAggregates valObjectAgs ,
        Map<String,List<Opportunity_Stage_Validation__mdt>> groupedStageValMap
        )
    {
        Integer passCheckCount = 0;
        Boolean groupCheckDNE = false; // if group is a DOES NOT EXIST case
        Boolean groupConditionFailed = false; // if group is a mixed object case
        if ( ( groupedStageValMap != null ) && groupedStageValMap.containsKey( groupName ) ) {
            for ( Opportunity_Stage_Validation__mdt val : groupedStageValMap.get( groupName ) ) {
                Object valFieldValue = null;
                if ( val.Operation__c == Operator.DOES_NOT_EXIST.name() ) {
                    groupCheckDNE = true;
                } else if ( val.Object__c == OPPORTUNITY_OBJ ) {
                    valFieldValue = opp.get( val.Field__c );
                } else {
                    valFieldValue = valObject?.get( val.Field__c );
                }
                if ( String.isNotBlank( val.Object__c ) && ( val.Object__c.indexOf( AGGREGATES ) > -1 ) ) {
                    passCheckCount = NSP_ValidateOpportunityStage.evaluateAggregateVal(
                        opp ,
                        passCheckCount ,
                        valObjectAgs ,
                        val
                    );
                } else if ( NSP_ValidateOpportunityStage.checkCondition( valFieldValue , val.Value__c , val.Operation__c ) ){
                    passCheckCount++;
                } else if ( val.Group_Condition__c ) { // checkCondition failed for a Group Condition
                    groupConditionFailed = true;
                }
            }
            // handle special cases
            passCheckCount = NSP_ValidateOpportunityStage.evaluateSpecialCases(
                passCheckCount ,
                groupCheckDNE ,
                groupConditionFailed ,
                groupName ,
                groupedStageValMap
            );
        }
        return passCheckCount;
    }

    private static Integer evaluateSpecialCases(
        Integer passCheckCount ,
        Boolean groupCheckDNE ,
        Boolean groupConditionFailed ,
        String groupName ,
        Map<String,List<Opportunity_Stage_Validation__mdt>> groupedStageValMap
        )
    {
        if ( ( groupedStageValMap != null ) && groupedStageValMap.containsKey( groupName ) ) {
            if ( groupCheckDNE ) { // check Does Not Exist case first
                if ( passCheckCount >= ( groupedStageValMap.get(groupName).size() - 1 ) ) {
                    passCheckCount = NSP_ValidateOpportunityStage.ERROR_DOES_NOT_EXIST; // if record exists that should not, trip error message
                } else {
                    passCheckCount = groupedStageValMap.get(groupName).size(); // if not all DNE criteria met, make sure error message is skipped
                }
            } else if ( groupConditionFailed ) {
                passCheckCount = groupedStageValMap.get(groupName).size(); // if group condition doesn't pass, whole group passes
            }
        }
        return passCheckCount;
    }

    private static String getGroupRelObjName( String groupName , Map<String,List<Opportunity_Stage_Validation__mdt>> groupedStageValMap ) {
        String groupRelObjName = OPPORTUNITY_OBJ;
        if ( groupedStageValMap != null ) {
            for ( Opportunity_Stage_Validation__mdt groupOptyStageVal : groupedStageValMap.get(groupName) ) {
                if ( groupOptyStageVal.Object__c != OPPORTUNITY_OBJ ) { // first object name other than Opportunity
                    groupRelObjName = groupOptyStageVal.Object__c;
                    break;
                }
            }
        }
        return groupRelObjName; // if no other object name found, entire group is based on Opportunity
    }

    private static List<Opportunity_Stage_Validation__mdt> getCurrentOptyStageVals(Opportunity opp){
        List<Opportunity_Stage_Validation__mdt> currentOptyStageVals = new List<Opportunity_Stage_Validation__mdt>();
        String currentPrimProduct = ( String.isNotBlank(opp.NSP_PrimaryProduct__c) ) ? opp.NSP_PrimaryProduct__c : NSP_SalesConstants.WO; // treat empty opty Product as WO

        for(Opportunity_Stage_Validation__mdt optyStageVal : optyStageVals){
            List<String> valPrimProducts = optyStageVal.Primary_Product__c.split(',');
            if( optyStageVal.IsActive__c && valPrimProducts.contains(currentPrimProduct) && optyStageVal.Stage__c == opp.StageName ){
                currentOptyStageVals.add(optyStageVal);
            }
        }
        if( currentOptyStageVals.size() == 0 ){ // if not match for Product/Stage combo, see if there is a Default Product match for the Stage
            for(Opportunity_Stage_Validation__mdt optyStageVal : optyStageVals){
                List<String> valPrimProducts = optyStageVal.Primary_Product__c.split(',');
                if( optyStageVal.IsActive__c && valPrimProducts.contains(DEFAULT_PRODUCT) && optyStageVal.Stage__c == opp.StageName ){
                    currentOptyStageVals.add(optyStageVal);
                }
            }
        }
        return currentOptyStageVals;
    }

    private static List<Opportunity_Stage_Validation__mdt> getSingleStageVals( List<Opportunity_Stage_Validation__mdt> currentOptyStageVals ) {
        List<Opportunity_Stage_Validation__mdt> singleOptyStageVals = new List<Opportunity_Stage_Validation__mdt>();
        if ( currentOptyStageVals != null ) {
            for ( Opportunity_Stage_Validation__mdt singleVal : currentOptyStageVals ) {
                if ( String.isBlank( singleVal.Group__c ) ) {
                    singleOptyStageVals.add( singleVal );
                }
            }
        }
        return singleOptyStageVals;
    }

    private static Map<String,List<Opportunity_Stage_Validation__mdt>> getGroupedStageValMap( List<Opportunity_Stage_Validation__mdt> currentOptyStageVals ) {
        Map<String,List<Opportunity_Stage_Validation__mdt>> groupedStageValMap = new Map<String,List<Opportunity_Stage_Validation__mdt>>();
        Set<String> groupNames = new Set<String>();
        if ( currentOptyStageVals != null ) {
            for ( Opportunity_Stage_Validation__mdt currentOptyStageVal : currentOptyStageVals ) {
                if( String.isNotBlank( currentOptyStageVal.Group__c ) ){
                    groupNames.add( currentOptyStageVal.Group__c );
                }
            }
            for ( String groupName : groupNames ) {
                List<Opportunity_Stage_Validation__mdt> groupedStageVals = new List<Opportunity_Stage_Validation__mdt>();
                for ( Opportunity_Stage_Validation__mdt currentOptyStageVal : currentOptyStageVals ) {
                    if ( groupName == currentOptyStageVal.Group__c ) {
                        groupedStageVals.add( currentOptyStageVal );
                    }
                }
                groupedStageValMap.put( groupName , groupedStageVals );
            }
        }
        return groupedStageValMap;
    }

    public static void evaluateQuoteCriteria( Opportunity opp , Map<Id,SBQQ__Quote__c> quoteMap ) {
        try {
            // 205583/208335 - bypass QuoteCriteria is Fee Inclusive is checked
            if ( !opp.Fee_Inclusive__c
                && !validHRProducts.contains( opp.NSP_PrimaryProduct__c )
                )
            {
                SBQQ__Quote__c primaryQuote = quoteMap?.get( opp.SBQQ__PrimaryQuote__c ); // prevent NullPointerExceptions...
                if ( exitCriteriaProductException.contains( opp.NSP_PrimaryProduct__c ) ) {
                    NSP_ValidateOpportunityStage.evaluateQuoteCriteriaProductException( opp , primaryQuote );
                } else if ( ( opp.SBQQ__PrimaryQuote__c != null ) && ( primaryQuote != null ) ) {
                    NSP_ValidateOpportunityStage.evaluateQuoteExistingQuote( opp , primaryQuote );
                } else if ( ( opp.SBQQ__PrimaryQuote__c == null )
                    && ( ( opp.Type == NSP_SalesConstants.NEW_BUSINESS_OPPORTUNITY )
                        || ( ( opp.Type == NSP_SalesConstants.OPPORTUNITY_TYPE_EXISTING_PRODUCT )
                            && ( opp.NSP_AddonType__c == NSP_SalesConstants.OPPORTUNITY_SUBTYPE_AMENDMENT )
                            )
                        )
                    )
                {
                    NSP_ValidateOpportunityStage.addValError(
                        opp ,
                        System.Label.NSP_AddPrimaryQuote
                    );
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ValidateOpportunityStage.class.getName() ,
                'evaluateQuoteCriteria' ,
                e
            );
        }
    }

    @TestVisible
    private static void evaluateQuoteExistingQuote( Opportunity opp , SBQQ__Quote__c primaryQuote ){
        try {
            if ( primaryQuote?.SBQQ__Status__c != NSP_SalesConstants.APPROVAL_STATUS_APPROVED ){
                opp.addError( System.Label.NSP_Approve_Primary_Quote );
            } else if ( !test.isRunningTest()
                && opp.StageName.equals( NSP_SalesConstants.CLOSED_WON )
                && ( ( opp.NSP_PrimaryProduct__c != primaryQuote?.NSP_Opportunity_Primary_Product__c )
                    || ( opp.NSP_Client_For_Life__c != primaryQuote?.NSP_Client_For_Life__c ) )
                )
            {
                NSP_ValidateOpportunityStage.addValError(
                    opp ,
                    System.Label.NSP_Sync_Primary_Quote_With_Opportunity
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ValidateOpportunityStage.class.getName() ,
                'evaluateQuoteExistingQuote' ,
                e
            );
        }
    }

    private static void evaluateQuoteCriteriaProductException( Opportunity opp , SBQQ__Quote__c primaryQuote ){
        try {
            if ( ( opp.NSP_PrimaryProduct__c == NSP_SalesConstants.HR_CONSULTING_SERVICES )
                && ( opp.NSP_Client_For_Life__c != NSP_SalesConstants.WO_WS )
                && !test.isRunningTest() )
            {
                if ( opp.SBQQ__PrimaryQuote__c != null && primaryQuote != null ) {
                    if ( primaryQuote.SBQQ__Status__c != NSP_SalesConstants.APPROVAL_STATUS_APPROVED ) {
                        opp.addError(System.Label.NSP_Approve_Primary_Quote);
                    } else if ( opp.StageName.equals( NSP_SalesConstants.CLOSED_WON )
                        && ( ( opp.NSP_PrimaryProduct__c != primaryQuote.NSP_Opportunity_Primary_Product__c )
                            || ( opp.NSP_Client_For_Life__c != primaryQuote.NSP_Client_For_Life__c ) )
                        )
                    {
                        NSP_ValidateOpportunityStage.addValError(
                            opp ,
                            System.Label.NSP_Sync_Primary_Quote_With_Opportunity
                        );
                    }
                } else {

                    NSP_ValidateOpportunityStage.addValError(
                        opp ,
                        System.Label.NSP_AddPrimaryQuote
                    );
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ValidateOpportunityStage.class.getName() ,
                'evaluateQuoteCriteriaProductException' ,
                e
            );
        }
    }

    private static void evaluateClosedWonStageCriteria( Opportunity opp ) {
        Integer canClosedWon = 0;
        if ( NSP_ValidateOpportunityStage.permittedCWOppOwnerUserMap.containsKey( opp.OwnerId )
            && ( !hasAllowCWNCSUserPerm )
            && ownerBasedCriteriaProducts.contains( opp.NSP_PrimaryProduct__c )
            )
        {
            canClosedWon++;
        } else if ( nonOwnerBasedCriteriaProducts.contains( opp.NSP_PrimaryProduct__c )
            && ( UserInfo.getUserId() != opp.OwnerId )
            && ( !hasAllowCWNCSUserPerm )
            )
        {
            canClosedWon++;
        } else if ( ownerBasedCriteriaProducts.contains( opp.NSP_PrimaryProduct__c )
            && !NSP_ValidateOpportunityStage.permittedCWOppOwnerUserMap.containsKey( opp.OwnerId )
            && ( UserInfo.getUserId() != opp.OwnerId )
            && ( !hasAllowCWNCSUserPerm )
            )
        {
            canClosedWon++;
        } else if ( !hasAllowCWNCSUserPerm
            && validHR360Products.contains( opp.NSP_PrimaryProduct__c )
            )
        {
            canClosedWon++;
        }
        if ( canClosedWon > 0 ) {
            NSP_ValidateOpportunityStage.addValError(
                opp ,
                System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON
            );
        }
    }

    public static void evaluateClosedLostStageCriteria( Opportunity opp, Map<Id,User> opportunityOwnerRoleMap ) {
        Boolean canCloseLostOpty = checkClosedLostStageCriteria( opp , opportunityOwnerRoleMap );
        if ( !canCloseLostOpty ) {
            NSP_ValidateOpportunityStage.addValError(
                opp ,
                System.Label.NSP_CANNOT_MOVE_TO_CLOSEDLOST
            );
        }
    }

    public static Boolean checkClosedLostStageCriteria( Opportunity opp , Map<Id,User> opportunityOwnerRoleMap ) {
        Boolean canCloseLostOpty = true;
        Map<Id,Opportunity> oppSalesOfficeMap = new Map<Id,Opportunity>(
            [
                SELECT Id , ToLabel( NSP_Sales_Office__c )
                FROM Opportunity
                WHERE ( Id = :opp.Id )
            ]
            );
        List<String> salesOfficeList = new List<String>();
        if ( ( oppSalesOfficeMap != null )
            && !oppSalesOfficeMap.isEmpty()
            && oppSalesOfficeMap.containsKey( opp.Id )
            )
        {
            Opportunity check = oppSalesOfficeMap.get( opp.Id );
            if ( ( check != null )
                && ( check.NSP_Sales_Office__c != null )
                )
            {
                salesOfficeList.add( check.NSP_Sales_Office__c );
            }
        }

        //Added for 579280
        String opportunitySalesOffMemb = null;
        if ( opportunityOwnerRoleMap.containsKey( opp.OwnerId ) ) {
            User opportunityOwner = opportunityOwnerRoleMap.get( opp.OwnerId );
            if ( opportunityOwner != null ) {
                opportunitySalesOffMemb = opportunityOwner.NSP_Sales_Office_Membership__c;
            }
        }

        List<String> salesOfficeMembership = new List<String>();
        if(String.isNotBlank(opportunitySalesOffMemb)){
            salesOfficeMembership.addAll(opportunitySalesOffMemb.split(';'));
        }
        List<ID> teamMemberList = new List<ID>();
        List<OpportunityTeamMember> opportunityTeamMemberList = [
            SELECT Id , UserId , TeamMemberRole
            FROM OpportunityTeamMember
            WHERE (
                ( OpportunityId = :opp.Id )
                AND ( TeamMemberRole = :closeLostRoleinOpportunityTeam )
            )
        ];
        if(!opportunityTeamMemberList.isEmpty()) {
            for(OpportunityTeamMember oppTeamMember : opportunityTeamMemberList){
                teamMemberList.add(oppTeamMember.UserId);
            }
        }

        Integer canCloseLost = checkAllowClosedLost(
            opp ,
            teamMemberList ,
            salesOfficeMembership ,
            salesOfficeList
        );
        if ( canCloseLost == 0 ) {
            canCloseLostOpty = false;
        }
        return canCloseLostOpty;
    }

    private static Integer checkAllowClosedLost( Opportunity opp , List<ID> teamMemberList , List<String> salesOfficeMembership , List<String> salesOfficeList ) {
        Integer canCloseLost = checkProductAllowClosedLost( opp );
        if ( NSP_ValidateOpportunityStage.hasAllowClosedLostPermission ) {
            canCloseLost++;
        } else if ( opp.ownerid == UserInfo.getUserId() ) {
            canCloseLost++;
        } else if ( teamMemberList.contains( UserInfo.getUserId() ) ) {
            canCloseLost++;
        } else if ( ( opp.NSP_Account_Segment__c == NSP_SalesConstants.MIDMARKET_SALES ) && hasAllowCLMMPerm ) {
            canCloseLost++;
        } else if ( getSalesOfficeGroup( UserInfo.getUserId() , salesOfficeMembership ) && hasCLSOOppOwnerPermission ) {
            canCloseLost++;
        } else if ( getSalesOfficeGroup( UserInfo.getUserId() , salesOfficeList ) && hasCLSOOppPermission ) {
            canCloseLost++;
        }
        return canCloseLost;
    }

    private static Integer checkProductAllowClosedLost( Opportunity opp ) {
        Integer canCloseLost = 0;
        if ( NSP_ValidateOpportunityStage.permittedBPCUserMap.containsKey( opp.OwnerId )
            && hasAllowCLMMPerm
            )
        {
            canCloseLost++;
        } else if ( NSP_ValidateOpportunityStage.permittedRETSCUserMap.containsKey( opp.OwnerId )
            && hasAllowCLRETPerm
            )
        {
            canCloseLost++;
        } else if ( NSP_ValidateOpportunityStage.permittedInsSalesUserMap.containsKey( opp.OwnerId )
            && hasAllowCLInsurancePerm
            )
        {
            canCloseLost++;
        } else if ( NSP_ValidateOpportunityStage.permittedRecSalesUserMap.containsKey( opp.OwnerId )
            && hasAllowCLRecruitingPerm
            )
        {
            canCloseLost++;
        } else if ( NSP_ValidateOpportunityStage.permittedTechSalesUserMap.containsKey( opp.OwnerId )
            && hasAllowCLTechnologyPerm
            )
        {
            canCloseLost++;
        }
        return canCloseLost;
    }

    public static Boolean getSalesOfficeGroup( Id recordId , List<String> salesOffices ){
        Boolean isMember = false;
        for (String salesOffice : salesOffices) {
            if (NSP_ValidateOpportunityStage.userGroupMembership.contains(salesOffice)) {
                isMember = true;
                break;
            }
        }
        return isMember;
    }

    public static Map<Id,User> getUserRole( List<Id> recordId ) {
        Map<Id,User> userMap= new Map<Id,User>(
            [
                SELECT Id , UserRole.Name , ToLabel(NSP_Sales_Office__c) , ToLabel(NSP_Sales_Office_Membership__c)
                FROM User
                WHERE ( Id IN :recordId )
            ]
        );
        return userMap;
    }

    // NSP_ValidateOpportunityStageTest
    @TestVisible
    public static Boolean checkCondition( Object fieldValue , String ruleValue , String operation ) {
        Boolean retVal = false;
        if ( operation == Operator.IS_BLANK.name() ) {
            retVal = ( String.isBlank( String.valueOf( fieldValue ) ) || ( fieldValue == null ) );
        } else if ( operation == Operator.IS_NOT_BLANK.name() ) {
            retVal = ( String.isNotBlank( String.valueOf( fieldValue ) ) && ( fieldValue != null ) );
        } else if ( String.isNotBlank( ruleValue )
            && ( ( operation == Operator.EQUALS.name() )
                || ( operation == Operator.DOES_NOT_EQUAL.name() )
                || ( operation == Operator.GREATER_THAN_OR_EQUALS.name() )
                || ( operation == Operator.LESS_THAN_OR_EQUALS.name() )
                )
            )
        {
            if ( ( fieldValue instanceOf Date )
                && ( ruleValue.indexOf( 'TODAY' ) > -1 )
                )
            {
                Date ruleValueDate = Date.today();
                retVal = NSP_ValidateOpportunityStage.checkConditionDate(
                    Date.valueOf( fieldValue ) ,
                    ruleValueDate ,
                    operation
                );
            } else if ( ruleValue.replaceFirst( '[.]' , '' ).isNumeric() // Prevent System.TypeException: Invalid decimal: Field Value: *****
                && ( ( fieldValue instanceOf Decimal )
                    || ( fieldValue instanceOf Double )
                    || ( fieldValue instanceOf Integer )
                    )
                )
            {
                retVal = NSP_ValidateOpportunityStage.checkConditionDecimal(
                    Decimal.valueOf( String.valueOf( fieldValue ) ) ,
                    Decimal.valueOf( ruleValue ) ,
                    operation
                );
            } else if ( fieldValue instanceOf Boolean ) {
                retVal = NSP_ValidateOpportunityStage.checkConditionString(
                    String.valueOf( fieldValue ).toLowerCase() ,
                    ruleValue.toLowerCase() ,
                    operation
                );
            } else {
                retVal = NSP_ValidateOpportunityStage.checkConditionString(
                    fieldValue ,
                    ruleValue ,
                    operation
                );
            }
        } else {
            retVal = NSP_ValidateOpportunityStage.checkConditionString(
                fieldValue ,
                ruleValue ,
                operation
            );
        }
        return retVal;
    }

    private static Boolean checkConditionString( Object fieldValue , Object ruleValue , String operation ) {
        Boolean retVal = false;
        if ( operation == Operator.EQUALS.name() ) {
            retVal = ( fieldValue == ruleValue );
        } else if ( operation == Operator.DOES_NOT_EQUAL.name() ) {
            retVal = ( fieldValue != ruleValue );
        } else if ( operation == Operator.CONTAINS.name() ) {
            retVal = (
                ( fieldValue != null )
                && String.valueOf( fieldValue ).contains( String.valueOf( ruleValue ) )
            );
        } else if ( operation == Operator.DOES_NOT_CONTAIN.name() ) {
            retVal = (
                ( fieldValue != null )
                && !String.valueOf( fieldValue ).contains( String.valueOf( ruleValue ) )
            );
        } else if (
            ( operation == Operator.IS_IN.name() )
            && ( ruleValue != null )
            && String.isNotBlank( String.valueOf( ruleValue ) )
            )
        {
            Set<String> ruleValueSet = new Set<String>(
                String.valueOf( ruleValue ).split( ',' )
            );
            retVal = ruleValueSet.contains( String.valueOf( fieldValue ) );
        } else if (
            ( operation == Operator.IS_NOT_IN.name() )
            && ( ruleValue != null )
            && String.isNotBlank( String.valueOf( ruleValue ) )
            )
        {
            Set<String> ruleValueSet = new Set<String>(
                String.valueOf( ruleValue ).split( ',' )
            );
            retVal = !ruleValueSet.contains( String.valueOf( fieldValue ) );
        }
        return retVal;
    }

    private static Boolean checkConditionDate( Date fieldValue , Date ruleValue , String operation ){
        Boolean retVal = false;
        if ( operation == Operator.EQUALS.name() ) {
            retVal = fieldValue == ruleValue;
        } else if ( operation == Operator.DOES_NOT_EQUAL.name() ) {
            retVal = fieldValue != ruleValue;
        } else if ( operation == Operator.GREATER_THAN_OR_EQUALS.name() ) {
            retVal = fieldValue != null && String.isNotBlank(String.valueOf(fieldValue)) && fieldValue >= ruleValue;
        } else if ( operation == Operator.LESS_THAN_OR_EQUALS.name() ) {
            retVal = fieldValue != null && String.isNotBlank(String.valueOf(fieldValue)) && fieldValue <= ruleValue;
        }
        return retVal;
    }

    private static Boolean checkConditionDecimal( Decimal fieldValue , Decimal ruleValue , String operation ){
        Boolean retVal = false;
        if ( operation == Operator.EQUALS.name() ) {
            retVal = fieldValue == ruleValue;
        } else if ( operation == Operator.DOES_NOT_EQUAL.name() ) {
            retVal = fieldValue != ruleValue;
        } else if ( operation == Operator.GREATER_THAN_OR_EQUALS.name() ) {
            retVal = fieldValue != null && String.isNotBlank(String.valueOf(fieldValue)) && fieldValue >= ruleValue;
        } else if ( operation == Operator.LESS_THAN_OR_EQUALS.name() ) {
            retVal = fieldValue != null && String.isNotBlank(String.valueOf(fieldValue)) && fieldValue <= ruleValue;
        }
        return retVal;
    }

    //
    //
    //

    @TestVisible
    private static Boolean hasAllowClosedLostPermission {
        private get {
            if ( hasAllowClosedLostPermission == null ) {
                hasAllowClosedLostPermission = CustomPermissionController.checkUserPermission( 'Allow_Closed_Lost_Opportunity' , UserInfo.getUserId() );
            }
            return hasAllowClosedLostPermission;
        }
        private set;
    }

    @TestVisible
    private static Boolean hasCLSOOppOwnerPermission {
        private get {
            if ( hasCLSOOppOwnerPermission == null ) {
                hasCLSOOppOwnerPermission = CustomPermissionController.checkUserPermission( 'Opportunity_Closed_Lost_SO_Opp_Owner' , UserInfo.getUserId() );
            }
            return hasCLSOOppOwnerPermission;
        }
        private set;
    }

    @TestVisible
    private static Boolean hasCLSOOppPermission {
        private get {
            if ( hasCLSOOppPermission == null ) {
                hasCLSOOppPermission = CustomPermissionController.checkUserPermission( 'Opportunity_Closed_Lost_SO_Opp' , UserInfo.getUserId() );
            }
            return hasCLSOOppPermission;
        }
        private set;
    }

    @TestVisible
    private static Boolean hasAllowCLMMPerm {
        private get {
            if ( hasAllowCLMMPerm == null ) {
                hasAllowCLMMPerm = CustomPermissionController.checkUserPermission( 'Opportunity_Allow_Closed_Lost_MM' , UserInfo.getUserId() );
            }
            return hasAllowCLMMPerm;
        }
        private set;
    }

    @TestVisible
    private static Boolean hasAllowCLRETPerm {
        private get {
            if ( hasAllowCLRETPerm == null ) {
                hasAllowCLRETPerm = CustomPermissionController.checkUserPermission( 'Opportunity_Allow_Closed_Lost_RET' , UserInfo.getUserId() );
            }
            return hasAllowCLRETPerm;
        }
        private set;
    }

    @TestVisible
    private static Boolean hasAllowCLInsurancePerm {
        private get {
            if ( hasAllowCLInsurancePerm == null ) {
                hasAllowCLInsurancePerm = CustomPermissionController.checkUserPermission( 'Opportunity_Allow_Closed_Lost_Insurance' , UserInfo.getUserId() );
            }
            return hasAllowCLInsurancePerm;
        }
        private set;
    }

    @TestVisible
    private static Boolean hasAllowCLRecruitingPerm {
        private get {
            if ( hasAllowCLRecruitingPerm == null ) {
                hasAllowCLRecruitingPerm = CustomPermissionController.checkUserPermission( 'Opportunity_Allow_Closed_Lost_Recruiting' , UserInfo.getUserId() );
            }
            return hasAllowCLRecruitingPerm;
        }
        private set;
    }

    @TestVisible
    private static Boolean hasAllowCLTechnologyPerm {
        private get {
            if ( hasAllowCLTechnologyPerm == null ) {
                hasAllowCLTechnologyPerm = CustomPermissionController.checkUserPermission( 'Opportunity_Allow_Closed_Lost_Technology' , UserInfo.getUserId() );
            }
            return hasAllowCLTechnologyPerm;
        }
        private set;
    }

    @TestVisible
    private static Boolean hasAllowCWNCSUserPerm {
        private get {
            if ( hasAllowCWNCSUserPerm == null ) {
                hasAllowCWNCSUserPerm = CustomPermissionController.checkUserPermission( 'Opportunity_Closed_Won_NCS_User' , UserInfo.getUserId() );
            }
            return hasAllowCWNCSUserPerm;
        }
        private set;
    }

    //
    //
    //

    @TestVisible
    private static Map<Id,User> permittedRETSCUserMap {
        private get {
            if ( permittedRETSCUserMap == null ) {
                permittedRETSCUserMap = CustomPermissionController.getPermittedUsersMap( 'Opportunity_Owner_RET_Sales_Consultant' );
            }
            return permittedRETSCUserMap;
        }
        private set;
    }

    @TestVisible
    private static Map<Id,User> permittedInsSalesUserMap {
        private get {
            if ( permittedInsSalesUserMap == null ) {
                permittedInsSalesUserMap = CustomPermissionController.getPermittedUsersMap( 'Opportunity_Owner_Insurance_Sales' );
            }
            return permittedInsSalesUserMap;
        }
        private set;
    }

    @TestVisible
    private static Map<Id,User> permittedRecSalesUserMap {
        private get {
            if ( permittedRecSalesUserMap == null ) {
                permittedRecSalesUserMap = CustomPermissionController.getPermittedUsersMap( 'Opportunity_Owner_Recruiting_Sales' );
            }
            return permittedRecSalesUserMap;
        }
        private set;
    }

    @TestVisible
    private static Map<Id,User> permittedTechSalesUserMap {
        private get {
            if ( permittedTechSalesUserMap == null ) {
                permittedTechSalesUserMap = CustomPermissionController.getPermittedUsersMap( 'Opportunity_Owner_Technology_Sales' );
            }
            return permittedTechSalesUserMap;
        }
        private set;
    }

    @TestVisible
    private static Map<Id,User> permittedBPCUserMap {
        private get {
            if ( permittedBPCUserMap == null ) {
                permittedBPCUserMap = CustomPermissionController.getPermittedUsersMap( 'Opportunity_Owner_BPC' );
            }
            return permittedBPCUserMap;
        }
        private set;
    }

    @TestVisible
    private static Map<Id,User> permittedCWOppOwnerUserMap {
        private get {
            if ( permittedCWOppOwnerUserMap == null ) {
                permittedCWOppOwnerUserMap = CustomPermissionController.getPermittedUsersMap( 'Opportunity_Closed_Won_Opp_Owner' );
            }
            return permittedCWOppOwnerUserMap;
        }
        private set;
    }

    //
    //
    //

    private static Set<String> userGroupMembership {
        private get {
            if ( userGroupMembership == null ) {
                userGroupMembership = new Set<String>();
                for ( GroupMember userGroupMember : [
                            SELECT Id , Group.Name , UserOrGroupId
                            FROM GroupMember
                            WHERE (
                                ( Group.Type = 'Regular' )
                                AND (
                                    ( UserOrGroupId = :UserInfo.getUserId() )
                                    OR ( UserOrGroupId = :UserInfo.getUserRoleId() )
                                    OR ( UserOrGroup.ManagerId = :UserInfo.getUserId() )
                                    OR ( UserOrGroup.Manager.UserRoleId = :UserInfo.getUserRoleId() )
                                    OR ( UserOrGroup.Manager.ManagerId = :UserInfo.getUserId() )
                                    OR ( UserOrGroup.Manager.Manager.UserRoleId = :UserInfo.getUserRoleId() )
                                    OR ( UserOrGroup.Manager.Manager.ManagerId = :UserInfo.getUserId() )
                                    OR ( UserOrGroup.Manager.Manager.Manager.UserRoleId = :UserInfo.getUserRoleId() )
                                )
                            )
                        ]
                    )
                {
                    userGroupMembership.add(userGroupMember.Group.Name);
                }
            }
            return userGroupMembership;
        }
        private set;
    }

    private enum Operator {
        CONTAINS ,
        DOES_NOT_CONTAIN ,
        DOES_NOT_EQUAL ,
        DOES_NOT_EXIST ,
        EQUALS ,
        GREATER_THAN_OR_EQUALS ,
        IS_BLANK ,
        IS_IN ,
        IS_NOT_BLANK ,
        IS_NOT_IN ,
        LESS_THAN_OR_EQUALS
    }
}
//