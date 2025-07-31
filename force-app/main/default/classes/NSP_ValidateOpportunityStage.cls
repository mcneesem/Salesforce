public with sharing class NSP_ValidateOpportunityStage {
    // test w/ NSP_ValidateOpportunityStageTest (83%)

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
    //                      3. When the records in a group are for Opportunity object and some related object, at least one 
    //                         related object record matching all the related object criteria in the group must be 
    //                         found but only if the Opportunity condition in the group is met. If the Opportunity condition
    //                         is not met, related object criteria in the group is not required and the validation passes.
    // ***************************************************************************************************************************

    public static Set<String> validHRProducts = new Set<String>{NSP_SalesConstants.WO, NSP_SalesConstants.WS, NSP_SalesConstants.HRScale};
    private static Set<String> validHR360Products = new Set<String>{NSP_SalesConstants.WO, NSP_SalesConstants.WS, NSP_SalesConstants.HRScale};
    public static List<string> analysisStageCriteraTypes = System.Label.NSP_AnalysisStageCriteria.split(',');
    public static List<string> proposeStageCriteraTypes = System.Label.NSP_ProposeStageCriteria.split(',');
    public static List<string> exitCriteriaProductException = System.Label.NSP_ExitCriteriaProductException.split(',');
    public static List<string> ownerBasedCriteriaProducts = System.Label.NSP_OwnerBasedCriteriaProducts.split(',');
    public static List<string> nonOwnerBasedCriteriaProducts = System.Label.NSP_NonOwnerBasedCriteriaProducts.split(',');
    public static List<string> closeLostRoleinOpportunityTeam = System.Label.Close_Lost_Role_in_Opportunity_Team.split(',');
    private static List<Opportunity_Stage_Validation__mdt> optyStageVals = Opportunity_Stage_Validation__mdt.getAll().values();
    private static String validationObjects = 'Opportunity,Event,Task,OpportunityContactRole,NSP_Employee_Split__c,SBQQ__Quote__c,NSP_Checklist__c';
    private static Boolean hasAllowClosedLostPermission = CustomPermissionController.checkUserPermission( 'Allow_Closed_Lost_Opportunity' , UserInfo.getUserId() );
    private static Boolean hasCLSOOppOwnerPermission = CustomPermissionController.checkUserPermission( 'Opportunity_Closed_Lost_SO_Opp_Owner' , UserInfo.getUserId() );
    private static Boolean hasCLSOOppPermission = CustomPermissionController.checkUserPermission( 'Opportunity_Closed_Lost_SO_Opp' , UserInfo.getUserId() );
    private static Boolean hasAllowCLMMPerm = CustomPermissionController.checkUserPermission( 'Opportunity_Allow_Closed_Lost_MM' , UserInfo.getUserId() );
    private static Boolean hasAllowCLRETPerm = CustomPermissionController.checkUserPermission( 'Opportunity_Allow_Closed_Lost_RET' , UserInfo.getUserId() );
    private static Boolean hasAllowCLInsurancePerm = CustomPermissionController.checkUserPermission( 'Opportunity_Allow_Closed_Lost_Insurance' , UserInfo.getUserId() );
    private static Boolean hasAllowCLRecruitingPerm = CustomPermissionController.checkUserPermission( 'Opportunity_Allow_Closed_Lost_Recruiting' , UserInfo.getUserId() );
    private static Boolean hasAllowCLTechnologyPerm = CustomPermissionController.checkUserPermission( 'Opportunity_Allow_Closed_Lost_Technology' , UserInfo.getUserId() );
    private static Boolean hasAllowCWNCSUserPerm = CustomPermissionController.checkUserPermission( 'Opportunity_Closed_Won_NCS_User' , UserInfo.getUserId() );
    private static final String DEFAULT_PRODUCT = 'Default';
    private static final String OPPORTUNITY_OBJ = 'Opportunity';
    private static final String SOLD_TO_PAID = 'Sold to Paid';
    public static final String HAS_DISCOVERY = ' has Discovery ';
    public static final String HAS_OPEN_EVENT = ' has Open Event ';
    public static final String HAS_WO_TASK = ' has WO Task ';
    public static final String HAS_WO_EVENT = ' has WO Event ';
    public static final String HAS_WO = 'has WO';

    public static void validateOpportunityStage(List<Opportunity> newList){
        List<Id> oppIdList = new List<Id>();
        List<Id> oppOwnerIdList= new List<Id>();
        oppOwnerIdList.add(UserInfo.getUserId());
        for(Opportunity opp : newList){
            oppIdList.add(opp.Id);
            oppOwnerIdList.add(opp.OwnerId);
        }
        Map<Id,User> opportunityOwnerRoleMap = getUserRole( oppOwnerIdList ); 

        if( !OpportunityStageSettings__c.getInstance(UserInfo.getUserId()).Is_Enabled_WO_WS_Stage_Entry__c ){ // Kill switch added on 6/10/2024
            validateOpportunityStageOld(newList , oppIdList , opportunityOwnerRoleMap);
        } else {
            validateOpportunityStageNew(newList , oppIdList , opportunityOwnerRoleMap);
        }
    }

    public static void validateOpportunityStageNew(List<Opportunity> newList , List<Id> oppIdList , Map<Id,User> opportunityOwnerRoleMap){
        try{
            Map<ID, Opportunity> oppEventTaskOCRMap = new Map<ID, Opportunity>(
                                    [ SELECT AccountId , Id , 
                                        (SELECT Id , Status , NSP_Task_Type__c , Subject 
                                            FROM Tasks WHERE CreatedBy.ProfileId = :NSP_ValidateOpportunityStage.integUserProfileId AND NSP_Task_Type__c != null) ,
                                        (SELECT Id , NSP_Event_Subtype__c , NSP_Method__c , NSP_Status__c 
                                            FROM Events WHERE NSP_Event_Subtype__c != NULL AND NSP_Status__c != :NSP_SalesConstants.Cancelled) ,
                                        (SELECT Id 
                                            FROM OpportunityContactRoles) ,
                                        (SELECT Id 
                                            FROM Employee_Splits__r) ,
                                        (SELECT Id , Status__c 
                                            FROM Checklists__r WHERE Checklist_Type__c = :SOLD_TO_PAID)
                                        FROM Opportunity
                                        WHERE Id IN :oppIdList
                                    ]);

            Map<Id, SBQQ__Quote__c> oppQuoteMap = new Map<Id,SBQQ__Quote__c>(
                                    [ SELECT Id , SBQQ__Status__c , NSP_Opportunity_Primary_Product__c , NSP_Client_For_Life__c 
                                        FROM SBQQ__Quote__c 
                                        WHERE SBQQ__Opportunity2__c IN :oppIdList AND SBQQ__Primary__c = TRUE 
                                    ]);

            for( Opportunity opp : newList ){
                if( String.isBlank(opp.StageName) || (hasAllowClosedLostPermission && opp.StageName.EQUALS(NSP_SalesConstants.CLOSED_LOST)) ){
                    continue;
                }

                Opportunity oppFromMap = oppEventTaskOCRMap.get(opp.Id);
                List<Task> taskList = oppFromMap?.Tasks;
                List<Event> eventList=oppFromMap?.Events;
                List<OpportunityContactRole> ocrList = oppFromMap?.OpportunityContactRoles;
                List<NSP_Employee_Split__c> oppCreditList = oppFromMap?.Employee_Splits__r;
                List<NSP_Checklist__c> stpList = oppFromMap?.Checklists__r;

                Map<String,List<SObject>> relObjectMap = new Map<String,List<SObject>>();
                relObjectMap.put('Opportunity' , new List<SObject>{opp});
                relObjectMap.put('Event' , eventList);
                relObjectMap.put('Task' , taskList);
                relObjectMap.put('OpportunityContactRole' , ocrList);
                relObjectMap.put('NSP_Employee_Split__c' , oppCreditList);
                relObjectMap.put('NSP_Checklist__c' , stpList);
                relObjectMap.put('SBQQ__Quote__c' , new List<SBQQ__Quote__c>{oppQuoteMap.get(opp.Id)});

                List<Opportunity_Stage_Validation__mdt> currentOptyStageVals = getCurrentOptyStageVals(opp);
                Map<String, List<Opportunity_Stage_Validation__mdt>> groupedStageValMap = getGroupedStageValMap(currentOptyStageVals);

                evaluateSingleCriteria(opp, relObjectMap, currentOptyStageVals);
                evaluateGroupedCriteria(opp, relObjectMap, groupedStageValMap);

                //Proposal
                if( opp.StageName.EQUALS(NSP_SalesConstants.PROPOSAL_STAGE) ){
                    evaluateQuoteCriteria( opp , oppQuoteMap );
                }

                //Closed Won
                if( opp.StageName.EQUALS(NSP_SalesConstants.CLOSED_WON) ){
                    //first check if primary quote is created and approved on primary products it is applicable on then check user based criteria
                    evaluateQuoteCriteria(opp , oppQuoteMap);
                    evaluateClosedWonStageCriteria( opp );
                }

                //Closed Lost
                if( opp.StageName.EQUALS(NSP_SalesConstants.CLOSED_LOST) ){
                    evaluateClosedLostStageCriteria( opp , opportunityOwnerRoleMap );
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

    private static void evaluateSingleCriteria(Opportunity opp, Map<String,List<SObject>> relObjectMap, List<Opportunity_Stage_Validation__mdt> currentOptyStageVals){
        for(Opportunity_Stage_Validation__mdt val : currentOptyStageVals){
            Integer passCheckCount = 0;
            if( String.isBlank(val.Group__c) ){
                for( SObject relObject : relObjectMap.get(val.Object__c) ){
                    if( checkCondition(relObject.get(val.Field__c) , val.Value__c , val.Operation__c) ){
                        passCheckCount++;
                    }
                }
                if( passCheckCount < 1 ){
                    opp.addError(val.Error_Message__c);
                }
            }
        }
    }

    private static void evaluateGroupedCriteria(Opportunity opp, Map<String,List<SObject>> relObjectMap, Map<String, List<Opportunity_Stage_Validation__mdt>> groupedStageValMap){
        for( String groupName : groupedStageValMap.keySet() ){
            Boolean passCheck = false;
            Boolean passCheckDNE = true;
            String groupRelObjName = getGroupRelObjName( groupName , groupedStageValMap );

            Integer i = 0;
            do {
                SObject relObject = ( relObjectMap.get(groupRelObjName).size() == 0 ) ? null : relObjectMap.get(groupRelObjName)[i];
                Integer passCheckCount = evaluateOneCriteriaGroup( opp, groupName , relObject , groupedStageValMap );
                if( passCheckCount >= groupedStageValMap.get(groupName).size() ){
                    passCheck = true;
                }
                if( passCheckCount == 99 ){ // when any record violates DOES NOT EXIST case
                    passCheckDNE = false;
                }
                i++;
            } while ( i < relObjectMap.get(groupRelObjName).size() );

            if( !passCheck || !passCheckDNE ){
                opp.addError(groupedStageValMap.get(groupName)[0].Error_Message__c);
            }
        }
    }

    public static Integer evaluateOneCriteriaGroup( Opportunity opp , String groupName , SObject relObject, Map<String, List<Opportunity_Stage_Validation__mdt>> groupedStageValMap ){
        Integer passCheckCount = 0;
        String groupCheckType = '';
        for( Opportunity_Stage_Validation__mdt val : groupedStageValMap.get(groupName) ){
            Object valFieldValue = null;
            if( val.Operation__c == Operator.DOES_NOT_EXIST.name() ){
                groupCheckType = Operator.DOES_NOT_EXIST.name();
            } else if( val.Object__c == OPPORTUNITY_OBJ ){
                valFieldValue = opp.get(val.Field__c);
            } else {
                if( relObject != null ){
                    valFieldValue = relObject.get(val.Field__c);
                }
            }
            if( checkCondition(valFieldValue , val.Value__c , val.Operation__c) )
            {
                passCheckCount++;
            }
        }

        // handle DOES_NOT_EXIST case
        if( groupCheckType == Operator.DOES_NOT_EXIST.name() ){
            if( passCheckCount >= (groupedStageValMap.get(groupName).size() - 1) ){
                passCheckCount = 99; // if record exists that should not, return 99 to trip error message
            } else {
                passCheckCount = groupedStageValMap.get(groupName).size(); // if not all criteria met, make sure error message is skipped
            }
        }

        return passCheckCount;
    }

    public static String getGroupRelObjName( String groupName , Map<String, List<Opportunity_Stage_Validation__mdt>> groupedStageValMap ){
        String groupRelObjName = OPPORTUNITY_OBJ;
        for( Opportunity_Stage_Validation__mdt groupOptyStageVal : groupedStageValMap.get(groupName) ){
            if( groupOptyStageVal.Object__c != OPPORTUNITY_OBJ){ // first object name other than Opportunity
                groupRelObjName = groupOptyStageVal.Object__c;
                break;
            }
        }
        return groupRelObjName; // if no other object name found, entire group is based on Opportunity
    }

    public static List<Opportunity_Stage_Validation__mdt> getCurrentOptyStageVals(Opportunity opp){
        List<Opportunity_Stage_Validation__mdt> currentOptyStageVals = new List<Opportunity_Stage_Validation__mdt>();
        String currentPrimProduct = ( String.isNotBlank(opp.NSP_PrimaryProduct__c) ) ? opp.NSP_PrimaryProduct__c : NSP_SalesConstants.WO; // treat empty opty Product as WO
               currentPrimProduct = ( NSP_ValidateOpportunityStage.namedProducts.CONTAINS(currentPrimProduct) ) ? currentPrimProduct : DEFAULT_PRODUCT; // treat unmatched Product as Default

        for(Opportunity_Stage_Validation__mdt optyStageVal : optyStageVals){
            String valPrimProductValues = ( String.isBlank(optyStageVal.Primary_Product__c) ) ? DEFAULT_PRODUCT : optyStageVal.Primary_Product__c; // treat empty Primary Product as Default
            List<String> valPrimProducts = valPrimProductValues.split(',');
            if( optyStageVal.IsActive__c && valPrimProducts.CONTAINS(currentPrimProduct) && optyStageVal.Stage__c == opp.StageName ){
                currentOptyStageVals.add(optyStageVal);
            }
        }
        return currentOptyStageVals;
    }

    public static Map<String, List<Opportunity_Stage_Validation__mdt>> getGroupedStageValMap(List<Opportunity_Stage_Validation__mdt> currentOptyStageVals){
        Map<String, List<Opportunity_Stage_Validation__mdt>> groupedStageValMap = new Map<String, List<Opportunity_Stage_Validation__mdt>>();
        Set<String> groupNames = new Set<String>();
        for(Opportunity_Stage_Validation__mdt currentOptyStageVal : currentOptyStageVals){
            if( String.isNotBlank(currentOptyStageVal.Group__c) ){
                groupNames.add(currentOptyStageVal.Group__c);
            }
        }
        for(String groupName : groupNames){
            List<Opportunity_Stage_Validation__mdt> groupedStageVals = new List<Opportunity_Stage_Validation__mdt>();
            for(Opportunity_Stage_Validation__mdt currentOptyStageVal : currentOptyStageVals){
                if( groupName == currentOptyStageVal.Group__c ){
                    groupedStageVals.add(currentOptyStageVal);
                }
            }
            groupedStageValMap.put(groupName, groupedStageVals);
        }
        return groupedStageValMap;
    }

    private static void validateOpportunityStageOld(List<Opportunity> newList , List<Id> oppIdList , Map<Id,User> opportunityOwnerRoleMap){
        Map<ID, Opportunity> oppMapwithEventTask = new Map<ID, Opportunity>([SELECT AccountId,Id,
                                                                             (SELECT Id,Status, NSP_Task_Subtype__c FROM Tasks WHERE NSP_Task_Subtype__c != NULL),
                                                                             (SELECT Id, NSP_Event_Subtype__c,NSP_Status__c FROM Events WHERE NSP_Event_Subtype__c != NULL)
                                                                             FROM Opportunity Where Id IN :oppIdList]);
        
        Map<Id,SBQQ__Quote__c> quoteMap = new Map<Id,SBQQ__Quote__c>([SELECT id, SBQQ__Status__c,NSP_Opportunity_Primary_Product__c ,NSP_Client_For_Life__c  FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN :oppIdList AND SBQQ__Primary__c = TRUE]);
        
        for(Opportunity opp:newList){
            Opportunity oppFromMap=oppMapwithEventTask.get(opp.Id);
            List<Task> taskList=oppFromMap?.Tasks;
            List<Event> eventList=oppFromMap?.Events;
            List<Quote> quotes=oppFromMap?.Quotes;
            
            if(opp.StageName != null){
                
                //  Added 275639
                if(FeatureManagement.checkPermission('Allow_Closed_Lost_Opportunity') && opp.StageName.EQUALS(NSP_SalesConstants.CLOSED_LOST)){
                    continue;
                }
                
                //Analysis
                if ( opp.StageName.EQUALS(NSP_SalesConstants.ANALYSIS_STAGE)
                    || opp.StageName.EQUALS(NSP_SalesConstants.PROPOSAL_STAGE)
                    || opp.StageName.EQUALS(NSP_SalesConstants.CLOSING_STAGE)
                    )
                {
                    //add Proposal
                    /* Added Or Condition as part of DF-01031 to show error When Number of Employees is equal to Zero */
                    if(opp.NSP_Number_of_Employees__c == null || opp.NSP_Number_of_Employees__c == 0){
                        opp.addError(System.Label.NSP_EnterNumberOfEmployees);
                    }
                    if(opp.NSP_PrimaryProduct__c == null){
                        opp.addError(System.Label.NSP_AddPrimaryProduct);
                    }
                    if(opp.Type == null){
                        opp.addError(System.Label.NSP_EnterOpportunityType);
                    }
                }
                if(opp.StageName.EQUALS(NSP_SalesConstants.ANALYSIS_STAGE)){//evaluate exit criteria to move to analysis stage
                    evaluateAnalysisStageCriteriaOld(opp,eventList);
                }
                /////Proposal
                if(opp.StageName.EQUALS(NSP_SalesConstants.PROPOSAL_STAGE)){
                    //Modified: Primary Quote required only for Non WO opptys, hence moved Primary Quote validation to else if block
                    //Perform WO
                    // Added WS condition as part of DF-01869
                    if ( proposeStageCriteraTypes.CONTAINS( opp.Type )
                        && validHRProducts.CONTAINS( opp.NSP_PrimaryProduct__c )
                        )
                    {
                        String scannedTask='';
                        if(taskList != null){
                            for(Task task:taskList){//looking for WO Profile
                                if(task.NSP_Task_Subtype__c == NSP_SalesConstants.WO_BUSINESS_PROFILE){
                                    scannedTask += HAS_WO_TASK;
                                }
                            }
                        }
                        if(eventList != null){
                            for(Event event:eventList){////looking for discovery
                                if(event.NSP_Event_Subtype__c == NSP_SalesConstants.WO_BUSINESS_PROFILE){
                                    scannedTask += HAS_WO_EVENT;
                                }
                            }
                        }
                        //Show error
                        if(!scannedTask.CONTAINS(HAS_WO) ){
                            opp.addError(System.Label.NSP_AddWOBusinessProfile);
                        }
                        if(opp.NSP_BidNumber__c == '' || opp.NSP_BidNumber__c == null){
                            opp.addError(System.Label.NSP_AddBidNumber);
                        }
                    }
                    evaluateQuoteCriteria(opp,quoteMap);
                }
                //CR-031 removed Executive summary check and have added BPS Products condition
                // 205583/208335 - bypass QuoteCriteria is Fee Inclusive is checked
                if(!opp.Fee_Inclusive__c && opp.StageName.EQUALS(NSP_SalesConstants.CLOSING_STAGE)){
                    if(opp.NSP_PrimaryProduct__c!=NSP_SalesConstants.WO && !opp.NSP_Bypass_Docusign_Signature__c && !opp.NSP_Order_Generated__c){
                        if(!exitCriteriaProductException.CONTAINS(opp.NSP_PrimaryProduct__c)){
                            opp.addError(System.Label.NSP_Create_Signed_Delivery_Order);
                        } else if(opp.NSP_PrimaryProduct__c == NSP_SalesConstants.HR_CONSULTING_SERVICES && opp.NSP_Client_For_Life__c != NSP_SalesConstants.WO_WS){
                            opp.addError(System.Label.NSP_Create_Signed_Delivery_Order);
                        }
                    } else if (
                        ( validHRProducts.CONTAINS( opp.NSP_PrimaryProduct__c ) || opp.NSP_Order_Generated__c )
                        && !opp.NSP_Closing_Appointment__c
                        )
                    {
                        opp.addError( System.Label.NSP_WO_Closing_Appointment_or_Docusign );
                    }
                }
                //closed-won criteria CR-031
                if(opp.StageName.EQUALS(NSP_SalesConstants.CLOSED_WON)){//evaluate criteria to move to closed won stage
                    //first check if primary quote is created and approved on primary products it is applicable on then check user based criteria
                    evaluateQuoteCriteria(opp,quoteMap);
                    evaluateClosedWonStageCriteriaOld(opp);
                }
                //closed-Lost criteria DF-1769
                if(opp.StageName.EQUALS(NSP_SalesConstants.CLOSED_LOST)){//evaluate criteria to move to closed lost stage
                    evaluateClosedLostStageCriteria(opp, opportunityOwnerRoleMap);
                }
            }
        }
    }

    private static void evaluateAnalysisStageCriteriaOld( Opportunity opp , List<Event> eventList ) {
        String scannedTask='';
        if ( !validHRProducts.CONTAINS( opp.NSP_PrimaryProduct__c )
              && ( !analysisStageCriteraTypes.CONTAINS( opp.Type )
                || (
                        ( opp.NSP_PrimaryProduct__c != NSP_SalesConstants.WX )
                     && ( opp.NSP_PrimaryProduct__c != NSP_SalesConstants.WA )
                   )
                )
            )
        {
            return;
        }

        for(Event event : eventList){////looking for discovery
            if( event.NSP_Event_Subtype__c == NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY
                && event.NSP_Status__c !=NSP_SalesConstants.Cancelled )
            {
                scannedTask += HAS_DISCOVERY;
                if(event.NSP_Status__c !=NSP_SalesConstants.DISCOVERY_CALL_COMPLETED)
                {
                    scannedTask += HAS_OPEN_EVENT;
                }
            }
        }
        
        //Show error
        if( !scannedTask.CONTAINS(HAS_DISCOVERY) ){
            opp.addError(System.Label.NSP_AddDiscoveryCalls);
        }
        if( scannedTask.CONTAINS(HAS_OPEN_EVENT) ){
            opp.addError(System.Label.NSP_CloseDiscoveryCallEvents);
        }
       
    }

    // Evaluate criteria related to quote
    // @param opportunityList list of New Opportunity.
    // @param  list of events
    // @param list of tasks
    // @return void
    public static void evaluateQuoteCriteria( Opportunity opp , Map<Id,SBQQ__Quote__c> quoteMap ) {
        try {
            // 205583/208335 - bypass QuoteCriteria is Fee Inclusive is checked
            if ( opp.Fee_Inclusive__c || validHR360Products.CONTAINS( opp.NSP_PrimaryProduct__c ) ){
                return;
            }

            SBQQ__Quote__c primaryQuote = null;
            if ( quoteMap != null ) {
                primaryQuote = quoteMap.get( opp.SBQQ__PrimaryQuote__c ); // prevent NullPointerExceptions...
            }
            if ( exitCriteriaProductException.CONTAINS( opp.NSP_PrimaryProduct__c ) ){
                evaluateQuoteCriteriaProductException( opp , primaryQuote );
            } else if ( opp.SBQQ__PrimaryQuote__c != null && primaryQuote != null ){
                evaluateQuoteExistingQuote( opp , primaryQuote );
            } else if ( ( opp.SBQQ__PrimaryQuote__c == null )
                   && ( ( opp.Type == NSP_SalesConstants.NEW_BUSINESS_OPPORTUNITY )
                        || ( ( opp.Type == NSP_SalesConstants.OPPORTUNITY_TYPE_EXISTING_PRODUCT )
                          && ( opp.NSP_AddonType__c == NSP_SalesConstants.OPPORTUNITY_SUBTYPE_AMENDMENT ) )
                      )
                )
            {
                opp.addError(System.Label.NSP_AddPrimaryQuote);
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ValidateOpportunityStage.class.getName() ,
                'evaluateQuoteCriteria' ,
                e
            );
        }
    }

    public static void evaluateQuoteExistingQuote( Opportunity opp , SBQQ__Quote__c primaryQuote ){
        try {
            if ( primaryQuote.SBQQ__Status__c != NSP_SalesConstants.APPROVAL_STATUS_APPROVED ){
                opp.addError( System.Label.NSP_Approve_Primary_Quote );
            } else if ( !test.isRunningTest()
                        && opp.StageName.EQUALS( NSP_SalesConstants.CLOSED_WON )
                        && ( ( opp.NSP_PrimaryProduct__c != primaryQuote.NSP_Opportunity_Primary_Product__c ) 
                            || ( opp.NSP_Client_For_Life__c != primaryQuote.NSP_Client_For_Life__c ) )
                        )
            {
                opp.addError( System.label.NSP_Sync_Primary_Quote_With_Opportunity );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ValidateOpportunityStage.class.getName() ,
                'evaluateQuoteExistingQuote' ,
                e
            );
        }
    }

    public static void evaluateQuoteCriteriaProductException( Opportunity opp , SBQQ__Quote__c primaryQuote ){
        try {
            if ( ( opp.NSP_PrimaryProduct__c == NSP_SalesConstants.HR_CONSULTING_SERVICES )
                && ( opp.NSP_Client_For_Life__c != NSP_SalesConstants.WO_WS ) 
                && !test.isRunningTest() )
            {
                if ( opp.SBQQ__PrimaryQuote__c != null && primaryQuote != null ) {
                    if ( primaryQuote.SBQQ__Status__c != NSP_SalesConstants.APPROVAL_STATUS_APPROVED ) {
                        opp.addError(System.Label.NSP_Approve_Primary_Quote);
                    } else if ( opp.StageName.EQUALS( NSP_SalesConstants.CLOSED_WON )
                                && ( ( opp.NSP_PrimaryProduct__c != primaryQuote.NSP_Opportunity_Primary_Product__c )
                                  || ( opp.NSP_Client_For_Life__c != primaryQuote.NSP_Client_For_Life__c ) )
                              )
                    {
                        opp.addError(System.label.NSP_Sync_Primary_Quote_With_Opportunity);
                    }
                } else {
                    opp.addError( System.Label.NSP_AddPrimaryQuote );
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
        if ( NSP_ValidateOpportunityStage.permittedCWOppOwnerUserMap.CONTAINSKey( opp.OwnerId )
            && ( !hasAllowCWNCSUserPerm )
            && ownerBasedCriteriaProducts.CONTAINS( opp.NSP_PrimaryProduct__c )
            )
        {
            opp.addError( System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON );
        } else if ( nonOwnerBasedCriteriaProducts.CONTAINS( opp.NSP_PrimaryProduct__c )
            && ( UserInfo.getUserId() != opp.OwnerId )
            && ( !hasAllowCWNCSUserPerm )
            )
        {
            opp.addError( System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON );
        } else if ( ownerBasedCriteriaProducts.CONTAINS( opp.NSP_PrimaryProduct__c )
            && !NSP_ValidateOpportunityStage.permittedCWOppOwnerUserMap.CONTAINSKey( opp.OwnerId )
            && ( UserInfo.getUserId() != opp.OwnerId )
            && ( !hasAllowCWNCSUserPerm )
            )
        {
            opp.addError( System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON );
        } else if ( !hasAllowCWNCSUserPerm
            && validHR360Products.CONTAINS( opp.NSP_PrimaryProduct__c )
            )
        {
            opp.addError( System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON );
        }
    }

    private static void evaluateClosedWonStageCriteriaOld( Opportunity opp ) {
        if ( ownerBasedCriteriaProducts.CONTAINS(opp.NSP_PrimaryProduct__c)
            && !hasAllowCWNCSUserPerm
            && NSP_ValidateOpportunityStage.permittedCWOppOwnerUserMap.CONTAINSKey( opp.OwnerId )
            )
        {
            opp.AddError(System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON);
        } else if ( nonOwnerBasedCriteriaProducts.CONTAINS(opp.NSP_PrimaryProduct__c)
            && ( UserInfo.getUserId() != opp.OwnerId )
            && !hasAllowCWNCSUserPerm
            )
        {
            opp.AddError(System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON);
        } else if ( ownerBasedCriteriaProducts.CONTAINS(opp.NSP_PrimaryProduct__c)
            && !hasAllowCWNCSUserPerm
            && !NSP_ValidateOpportunityStage.permittedCWOppOwnerUserMap.CONTAINSKey( opp.OwnerId )
            && ( UserInfo.getUserId() != opp.OwnerId )
            )
        {
            opp.AddError(System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON);
        } else if ( !hasAllowCWNCSUserPerm
            && validHRProducts.CONTAINS( opp.NSP_PrimaryProduct__c )
            )
        {
            opp.AddError( System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON );
        }
    }

    public static void evaluateClosedLostStageCriteria( Opportunity opp, Map<Id,User> opportunityOwnerRoleMap ) {
        //Added for 579279
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
            && oppSalesOfficeMap.CONTAINSKey( opp.Id )
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
        if ( opportunityOwnerRoleMap.CONTAINSKey( opp.OwnerId ) ) {
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
        
        Integer canCloseLost = checkAllowClosedLost(opp, teamMemberList, salesOfficeMembership, salesOfficeList);
        if(canCloseLost == 0){
            opp.AddError(System.Label.NSP_CANNOT_MOVE_TO_CLOSEDLOST);
        }
    }

    private static Integer checkAllowClosedLost(Opportunity opp, List<ID> teamMemberList, List<String> salesOfficeMembership, List<String> salesOfficeList) {
        Integer canCloseLost = checkProductAllowClosedLost(opp);
        if( hasAllowClosedLostPermission ){
            canCloseLost++;
        } else if( opp.ownerid == UserInfo.getUserId() ){
            canCloseLost++;
        } else if( teamMemberList.CONTAINS(UserInfo.getUserId()) ){
            canCloseLost++;
        } else if( ( opp.NSP_Account_Segment__c == NSP_SalesConstants.MIDMARKET_SALES )
             && hasAllowCLMMPerm ){
            canCloseLost++;
        } else if( ( getSalesOfficeGroup(UserInfo.getUserId(),salesOfficeMembership) )
             && hasCLSOOppOwnerPermission ){
            canCloseLost++;
        } else if( ( getSalesOfficeGroup(UserInfo.getUserId(),salesOfficeList) )
             && hasCLSOOppPermission){
            canCloseLost++;
        }

        return canCloseLost;
    }

    private static Integer checkProductAllowClosedLost( Opportunity opp ) {
        Integer canCloseLost = 0;
        if ( NSP_ValidateOpportunityStage.permittedBPCUserMap.CONTAINSKey( opp.OwnerId )
            && hasAllowCLMMPerm
            )
        {
            canCloseLost++;
        } else if ( NSP_ValidateOpportunityStage.permittedRETSCUserMap.CONTAINSKey( opp.OwnerId )
            && hasAllowCLRETPerm
            )
        {
            canCloseLost++;
        } else if ( NSP_ValidateOpportunityStage.permittedInsSalesUserMap.CONTAINSKey( opp.OwnerId )
            && hasAllowCLInsurancePerm
            )
        {
            canCloseLost++;
        } else if ( NSP_ValidateOpportunityStage.permittedRecSalesUserMap.CONTAINSKey( opp.OwnerId )
            && hasAllowCLRecruitingPerm
            )
        {
            canCloseLost++;
        } else if ( NSP_ValidateOpportunityStage.permittedTechSalesUserMap.CONTAINSKey( opp.OwnerId )
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

    public static Boolean checkCondition( Object fieldValue , String ruleValue , String operation ){
        Boolean retVal = false;
        if( operation == Operator.IS_BLANK.name() ){
            retVal = String.isBlank(String.valueOf(fieldValue)) || fieldValue == null;
        } else if ( operation == Operator.IS_NOT_BLANK.name() ){
            retVal = !String.isBlank(String.valueOf(fieldValue)) && fieldValue != null;
        } else if ( !String.isBlank(ruleValue)
             && (operation == Operator.EQUALS.name()
              || operation == Operator.DOES_NOT_EQUAL.name()
              || operation == Operator.GREATER_THAN_OR_EQUALS.name()
              || operation == Operator.LESS_THAN_OR_EQUALS.name()) ){
            if (fieldValue instanceOf Date) {
                Date ruleValueDate = null;
                if( ruleValue.indexOf('TODAY') > -1 ){
                    ruleValueDate = Date.today();
                    retVal = checkConditionDate( Date.valueOf(fieldValue) , ruleValueDate , operation );
                }
            } else if ( (fieldValue instanceOf Decimal) || (fieldValue instanceOf Double) || (fieldValue instanceOf Integer) ){
                retVal = checkConditionDecimal( Decimal.valueOf(String.valueOf(fieldValue)) , Decimal.valueOf(ruleValue) , operation );
            } else if ( fieldValue instanceOf Boolean ){
                retVal = checkConditionString( String.valueOf(fieldValue).toLowerCase() , ruleValue.toLowerCase() , operation );
            } else {
                retVal = checkConditionString( fieldValue , ruleValue , operation );
            }
        } else {
            retVal = checkConditionString( fieldValue , ruleValue , operation );
        }
        return retVal;
    }

    public static Boolean checkConditionString( Object fieldValue , Object ruleValue , String operation ){
        Boolean retVal = false;
        if ( operation == Operator.EQUALS.name() ){
            retVal = fieldValue == ruleValue;
        } else if ( operation == Operator.DOES_NOT_EQUAL.name() ){
            retVal = fieldValue != ruleValue;
        } else if ( operation == Operator.CONTAINS.name() ){
            retVal = fieldValue != null && String.valueOf(fieldValue).contains(String.valueOf(ruleValue));
        } else if ( operation == Operator.DOES_NOT_CONTAIN.name() ){
            retVal = fieldValue != null && !String.valueOf(fieldValue).contains(String.valueOf(ruleValue));
        } else if ( operation == Operator.IS_IN.name() ){
            if ( ruleValue != null && !String.isBlank(String.valueOf(ruleValue)) ){
                Set<String> ruleValueSet = new Set<String>(String.valueOf(ruleValue).split(','));
                retVal = ruleValueSet.contains(String.valueOf(fieldValue));
            }
        } else if ( operation == Operator.IS_NOT_IN.name() ){
            if ( ruleValue != null && !String.isBlank(String.valueOf(ruleValue)) ){
                Set<String> ruleValueSet = new Set<String>(String.valueOf(ruleValue).split(','));
                retVal = !ruleValueSet.contains(String.valueOf(fieldValue));
            }
        }
        return retVal;
    }

    public static Boolean checkConditionDate( Date fieldValue , Date ruleValue , String operation ){
        Boolean retVal = false;
        if ( operation == Operator.EQUALS.name() ) {
            retVal = fieldValue == ruleValue;
        } else if ( operation == Operator.DOES_NOT_EQUAL.name() ) {
            retVal = fieldValue != ruleValue;
        } else if ( operation == Operator.GREATER_THAN_OR_EQUALS.name() ) {
            retVal = fieldValue != null && !String.isBlank(String.valueOf(fieldValue)) && fieldValue >= ruleValue;
        } else if ( operation == Operator.LESS_THAN_OR_EQUALS.name() ) {
            retVal = fieldValue != null && !String.isBlank(String.valueOf(fieldValue)) && fieldValue <= ruleValue;
        }
        return retVal;
    }

    public static Boolean checkConditionDecimal( Decimal fieldValue , Decimal ruleValue , String operation ){
        Boolean retVal = false;
        if ( operation == Operator.EQUALS.name() ) {
            retVal = fieldValue == ruleValue;
        } else if ( operation == Operator.DOES_NOT_EQUAL.name() ) {
            retVal = fieldValue != ruleValue;
        } else if ( operation == Operator.GREATER_THAN_OR_EQUALS.name() ) {
            retVal = fieldValue != null && !String.isBlank(String.valueOf(fieldValue)) && fieldValue >= ruleValue;
        } else if ( operation == Operator.LESS_THAN_OR_EQUALS.name() ) {
            retVal = fieldValue != null && !String.isBlank(String.valueOf(fieldValue)) && fieldValue <= ruleValue;
        }
        return retVal;
    }
   
    private static Map<Id,User> permittedRETSCUserMap {
        private get {
            if ( permittedRETSCUserMap == null ) {
                permittedRETSCUserMap = CustomPermissionController.getPermittedUsersMap( 'Opportunity_Owner_RET_Sales_Consultant' );
            }
            return permittedRETSCUserMap;
        }
        private set;
    }
    
    private static Map<Id,User> permittedInsSalesUserMap {
        private get {
            if ( permittedInsSalesUserMap == null ) {
                permittedInsSalesUserMap = CustomPermissionController.getPermittedUsersMap( 'Opportunity_Owner_Insurance_Sales' );
            }
            return permittedInsSalesUserMap;
        }
        private set;
    }
    
    private static Map<Id,User> permittedRecSalesUserMap {
        private get {
            if ( permittedRecSalesUserMap == null ) {
                permittedRecSalesUserMap = CustomPermissionController.getPermittedUsersMap( 'Opportunity_Owner_Recruiting_Sales' );
            }
            return permittedRecSalesUserMap;
        }
        private set;
    }
    
    private static Map<Id,User> permittedTechSalesUserMap {
        private get {
            if ( permittedTechSalesUserMap == null ) {
                permittedTechSalesUserMap = CustomPermissionController.getPermittedUsersMap( 'Opportunity_Owner_Technology_Sales' );
            }
            return permittedTechSalesUserMap;
        }
        private set;
    }
    
    private static Map<Id,User> permittedBPCUserMap {
        private get {
            if ( permittedBPCUserMap == null ) {
                permittedBPCUserMap = CustomPermissionController.getPermittedUsersMap( 'Opportunity_Owner_BPC' );
            }
            return permittedBPCUserMap;
        }
        private set;
    }

    private static Map<Id,User> permittedCWOppOwnerUserMap {
        private get {
            if ( permittedCWOppOwnerUserMap == null ) {
                permittedCWOppOwnerUserMap = CustomPermissionController.getPermittedUsersMap( 'Opportunity_Closed_Won_Opp_Owner' );
            }
            return permittedCWOppOwnerUserMap;
        }
        private set;
    }

    private static Set<String> namedProducts {
        private get {
            if ( namedProducts == null ) {
                namedProducts = new Set<String>();
                List<Opportunity_Stage_Validation__mdt> optyStageVals = [ SELECT Primary_Product__c 
                                                                          FROM Opportunity_Stage_Validation__mdt 
                                                                          WHERE Primary_Product__c != null ];
                if ( optyStageVals != null && !optyStageVals.isEmpty() ) {
                    for ( Opportunity_Stage_Validation__mdt optyStageVal : optyStageVals ) {
                        List<String> valPrimProducts = optyStageVal.Primary_Product__c.split(',');
                        namedProducts.addAll(valPrimProducts);
                    }
                }
            }
            return namedProducts;
        }
        private set;
    }

    private static Set<String> userGroupMembership {
        private get {
            if ( userGroupMembership == null ) {
                userGroupMembership = new Set<String>();
                for ( GroupMember userGroupMember : [ SELECT Id , Group.Name , UserOrGroupId
                                                      FROM GroupMember
                                                      WHERE
                                                        ( UserOrGroupId = :UserInfo.getUserId() )
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

    private static Id integUserProfileId {
        private get {
            if ( integUserProfileId == null ) {
                List<NSP_Profile_Detail__mdt> profileDetailList = [ SELECT Profile_ID__c , Profile_Name__c 
                                                                    FROM NSP_Profile_Detail__mdt 
                                                                    WHERE Profile_Name__c =: System.label.NSP_Integration_User_Profile_Name LIMIT 1 ];
                integUserProfileId = NSP_SalesConstants.INTEGRATION_USER_PROFILE_ID;
                if(profileDetailList != null && !profileDetailList.isEmpty())
                {
                    integUserProfileId = profileDetailList[0].Profile_ID__c;
                }
            }
            return integUserProfileId;
        }
        private set;
    }

    public enum Operator { EQUALS, DOES_NOT_EQUAL, CONTAINS, DOES_NOT_CONTAIN, IS_IN, IS_NOT_IN , GREATER_THAN_OR_EQUALS, LESS_THAN_OR_EQUALS, IS_BLANK, IS_NOT_BLANK, DOES_NOT_EXIST }
}
//