/**
Apex Class Name      :  NSP_ValidateOpportunityStage
    Version              :  1.0
    Created Date         :  12/24/2021
    Function             :  class for validating opportunity stages rules
    Story                :
    Modification Log     :
     *--------------------------------------------------------------------------------------------------
 * Developer                   Date                   Description
 * -------------------------------------------------------------------------------------------------
 * Tejas                 12/24/2021            First Iteration
 */
public with sharing class NSP_ValidateOpportunityStage {
    // test w/ NSP_ValidateOpportunityStageTest (83%)

    public static Id soldToCheckListRecordTypeId = NSP_GenericRecordType.getRecordTypeId('NSP_Checklist__c' , 'NSP_Sold_to_Paid_Checklist');
    public static Set<String> validHRProducts = new Set<String>{NSP_SalesConstants.WO, NSP_SalesConstants.WS, NSP_SalesConstants.HRScale};
    public static List<string> analysisStageCriteraTypes = System.Label.NSP_AnalysisStageCriteria.split(',');
    public static List<string> proposeStageCriteraTypes = System.Label.NSP_ProposeStageCriteria.split(',');
    public static List<string> exitCriteriaProductException = System.Label.NSP_ExitCriteriaProductException.split(',');
    public static List<string> ownerBasedCriteriaProducts = System.Label.NSP_OwnerBasedCriteriaProducts.split(',');
    public static List<string> nonOwnerBasedCriteriaProducts = System.Label.NSP_NonOwnerBasedCriteriaProducts.split(',');
    public static List<string> closeLostRoleinOpportunityTeam = System.Label.Close_Lost_Role_in_Opportunity_Team.split(',');
    public static List<Opportunity_Stage_Validation__mdt> optyStageVals = Opportunity_Stage_Validation__mdt.getAll().values();
    public static Map<String, String> opptyBidStatus = retrieveFieldPicklistValues(Opportunity.NSP_Bid_Status__c);
    private static Boolean hasAllowClosedLostPermission = CustomPermissionController.checkUserPermission( 'Allow_Closed_Lost_Opportunity' , UserInfo.getUserId() );
    private static Boolean hasCLSOOppOwnerPermission = CustomPermissionController.checkUserPermission( 'Opportunity_Closed_Lost_SO_Opp_Owner' , UserInfo.getUserId() );
    private static Boolean hasCLSOOppPermission = CustomPermissionController.checkUserPermission( 'Opportunity_Closed_Lost_SO_Opp' , UserInfo.getUserId() );
    private static Boolean hasAllowCLMMPerm = CustomPermissionController.checkUserPermission( 'Opportunity_Allow_Closed_Lost_MM' , UserInfo.getUserId() );
    private static Boolean hasAllowCLRETPerm = CustomPermissionController.checkUserPermission( 'Opportunity_Allow_Closed_Lost_RET' , UserInfo.getUserId() );
    private static Boolean hasAllowCLInsurancePerm = CustomPermissionController.checkUserPermission( 'Opportunity_Allow_Closed_Lost_Insurance' , UserInfo.getUserId() );
    private static Boolean hasAllowCLRecruitingPerm = CustomPermissionController.checkUserPermission( 'Opportunity_Allow_Closed_Lost_Recruiting' , UserInfo.getUserId() );
    private static Boolean hasAllowCLTechnologyPerm = CustomPermissionController.checkUserPermission( 'Opportunity_Allow_Closed_Lost_Technology' , UserInfo.getUserId() );
    private static Boolean hasAllowCWNCSUserPerm = CustomPermissionController.checkUserPermission( 'Opportunity_Closed_Won_NCS_User' , UserInfo.getUserId() );
    public static final String DEFAULT_PRODUCT = 'Default';
    public static final String ID_FIELD = 'Id';
    public static final String OPPORTUNITY_OBJ = 'Opportunity';
    public static final String DOES_NOT_EXIST = 'Does Not Exist';
    public static final String HAS_DISCOVERY = ' has Discovery ';
    public static final String HAS_OPEN_EVENT = ' has Open Event ';
    public static final String HAS_OPEN_WO_PROP = ' has Open WO Proposal Event ';
    public static final String HAS_WO_TASK = ' has WO Task ';
    public static final String HAS_WO_EVENT = ' has WO Event ';
    public static final String HAS_WO = 'has WO';
    public static final String HAS_BUSINESS_PROFILE_STARTED_TASK_COMPLETED = ' Business profile started task completed ';
    public static final String HAS_BID_GENERATED_IN_AIMS_TASK_COMPLETED = ' Bid Generated In AIMS task completed ';
    public static final String HAS_BID_SENT_FROM_PRICING_REVIEW_TASK_COMPLETED = ' Sent From Pricing Review Task completed ';
    public static final String HAS_COMPLETED_STP = ' Sold to Paid Checklist completed ';

    public static void validateOpportunityStage(List<Opportunity> newList){
        List<Id> oppIdList= new List<Id>();
        List<Id> oppOwnerIdList= new List<Id>();
        oppOwnerIdList.add(UserInfo.getUserId());
        if((newList != null) && !newList.isEmpty()) {
            for(Opportunity opp:newList){
                oppIdList.add(opp.Id);
                oppOwnerIdList.add(opp.OwnerId);
            }
        }
        Map<Id,User> opportunityOwnerRoleMap = getUserRole( oppOwnerIdList ); 

        //  Kill switch added on 6/10/2024
        if( !OpportunityStageSettings__c.getInstance(UserInfo.getUserId()).Is_Enabled_WO_WS_Stage_Entry__c ){ // Kill switch added on 6/10/2024
            validateOpportunityStageOld(newList, opportunityOwnerRoleMap);
        } else if( (newList != null) && !newList.isEmpty() ){
            Map<ID, Opportunity> oppEventTaskOCRMap = new Map<ID, Opportunity>(
                                    [ SELECT AccountId , Id , 
                                        (SELECT Id , Status , NSP_Task_Type__c , Subject 
                                            FROM Tasks WHERE NSP_Task_Type__c != NULL),
                                            //FROM Tasks WHERE CreatedBy.ProfileId =: NSP_ValidateOpportunityStage.integUserProfileId AND NSP_Task_Type__c != NULL),
                                        (SELECT Id , NSP_Event_Subtype__c , NSP_Method__c , NSP_Status__c 
                                            FROM Events WHERE NSP_Event_Subtype__c != NULL AND NSP_Status__c != :NSP_SalesConstants.Cancelled),
                                        (SELECT Id 
                                            FROM OpportunityContactRoles),
                                        (SELECT Id 
                                            FROM Employee_Splits__r),
                                        (SELECT Id , Status__c 
                                            FROM Checklists__r WHERE RecordTypeId =: soldToCheckListRecordTypeId)
                                        FROM Opportunity
                                        WHERE Id IN :oppIdList
                                    ]);

            Map<Id, SBQQ__Quote__c> oppQuoteMap = new Map<Id,SBQQ__Quote__c>(
                                    [ SELECT Id , SBQQ__Status__c , NSP_Opportunity_Primary_Product__c , NSP_Client_For_Life__c 
                                        FROM SBQQ__Quote__c 
                                        WHERE SBQQ__Opportunity2__c IN :oppIdList AND SBQQ__Primary__c = TRUE 
                                    ]);

            for( Opportunity opp : newList ){
                if( String.isBlank(opp.StageName) || (hasAllowClosedLostPermission && opp.StageName.equals(NSP_SalesConstants.CLOSED_LOST)) ){
                    continue;
                }

                Opportunity oppFromMap = oppEventTaskOCRMap.get(opp.Id);
                List<Task> taskList = oppFromMap?.Tasks;
                List<Event> eventList=oppFromMap?.Events;
                List<OpportunityContactRole> ocrList = oppFromMap?.OpportunityContactRoles;
                List<NSP_Employee_Split__c> oppCreditList = oppFromMap?.Employee_Splits__r;
                List<NSP_Checklist__c> stpList = oppFromMap?.Checklists__r;

                Map<String,List<SObject>> relatedObjectMap = new Map<String,List<SObject>>();
                relatedObjectMap.put('Event' , eventList);
                relatedObjectMap.put('Task' , taskList);
                relatedObjectMap.put('OpportunityContactRole' , ocrList);
                relatedObjectMap.put('NSP_Employee_Split__c' , oppCreditList);
                relatedObjectMap.put('NSP_Checklist__c' , stpList);
                relatedObjectMap.put('SBQQ__Quote__c' , new List<SBQQ__Quote__c>{oppQuoteMap.get(opp.Id)});

                List<Opportunity_Stage_Validation__mdt> currentOptyStageVals = getCurrentOptyStageVals(opp);
                List<Opportunity_Stage_Validation__mdt> ungroupedStageVals = getUngroupedStageVals(currentOptyStageVals);
                Map<String, List<Opportunity_Stage_Validation__mdt>> groupedStageValMap = getGroupedStageValMap(currentOptyStageVals);
                Boolean passCheck = false;
                Integer passCheckCount = 0;
                String checkType = '';

                evaluateSingleCriteria(opp, relatedObjectMap, ungroupedStageVals);
                evaluateGroupedCriteria(opp, relatedObjectMap, groupedStageValMap);

                //Analysis
                if( opp.StageName.equals(NSP_SalesConstants.ANALYSIS_STAGE) ){//evaluate exit criteria to move to analysis stage
                    evaluateAnalysisStageCriteria( opp , eventList , taskList );
                }

                //Proposal
                if( opp.StageName.equals(NSP_SalesConstants.PROPOSAL_STAGE) ){
                    evaluateQuoteCriteria( opp , oppQuoteMap );
                }

                //Closing
                if( opp.StageName.equals( NSP_SalesConstants.CLOSING_STAGE ) ){
                    evaluateClosingStageCriteria( opp );
                }

                //Closed Won
                if( opp.StageName.equals(NSP_SalesConstants.CLOSED_WON) ){
                    //first check if primary quote is created and approved on primary products it is applicable on then check user based criteria
                    evaluateQuoteCriteria(opp , oppQuoteMap);
                    evaluateClosedWonStageCriteria( opp );
                }

                //Closed Lost
                if( opp.StageName.equals(NSP_SalesConstants.CLOSED_LOST) ){
                    evaluateClosedLostStageCriteria( opp , opportunityOwnerRoleMap );
                }
            }
        }
    }

    private static void evaluateSingleCriteria(Opportunity opp, Map<String,List<SObject>> relatedObjectMap, List<Opportunity_Stage_Validation__mdt> currentOptyStageVals){
        Integer passCheckCount = 0;
        for(Opportunity_Stage_Validation__mdt currentOptyStageVal : currentOptyStageVals){
            if( currentOptyStageVal.Object__c == OPPORTUNITY_OBJ ){
                if( !checkCondition(opp.get(currentOptyStageVal.Field__c), currentOptyStageVal.Value__c, currentOptyStageVal.Operation__c) ){
                    opp.addError(currentOptyStageVal.Error_Message__c);
                }
            } else if( String.isBlank(currentOptyStageVal.Group__c) ){ // check any related objects
                passCheckCount = 0;
                for( SObject relatedObject : relatedObjectMap.get(currentOptyStageVal.Object__c) ){
                    if( checkCondition(relatedObject.get(currentOptyStageVal.Field__c), currentOptyStageVal.Value__c, currentOptyStageVal.Operation__c) ){
                        passCheckCount++;
                    }
                }
                if( passCheckCount < 1 ) opp.addError(currentOptyStageVal.Error_Message__c);
            }
        }
    }

    private static void evaluateGroupedCriteria(Opportunity opp, Map<String,List<SObject>> relatedObjectMap, Map<String, List<Opportunity_Stage_Validation__mdt>> groupedStageValMap){
        Boolean passCheck = false;
        Integer passCheckCount = 0;
        String checkType = '';
        for( String groupName : groupedStageValMap.keySet() ){
            checkType = '';
            passCheck = false;
            String errMsg = groupedStageValMap.get(groupName)[0].Error_Message__c;
            String relatedObjName = '';
            for( Opportunity_Stage_Validation__mdt groupOptyStageVal : groupedStageValMap.get(groupName) ){
                if( groupedStageValMap.get(groupName)[0].Object__c != OPPORTUNITY_OBJ){
                    relatedObjName = groupedStageValMap.get(groupName)[0].Object__c;
                    break;
                }
            }
            for( SObject relatedObject : relatedObjectMap.get(relatedObjName) ){
                passCheckCount = 0;
                for( Opportunity_Stage_Validation__mdt groupOptyStageVal : groupedStageValMap.get(groupName) ){
                    if( groupOptyStageVal.Field__c == ID_FIELD && groupOptyStageVal.Operation__c == DOES_NOT_EXIST ){
                        checkType = DOES_NOT_EXIST;
                        continue;
                    } else if( groupOptyStageVal.Object__c == OPPORTUNITY_OBJ ){ // in case criteria group is blend of Opportunity and related object
                        // when a group contains an Opportunity object val record, it means the rest of the group only needs checking if the Opty condition is true
                        if( checkCondition(opp.get(groupOptyStageVal.Field__c), groupOptyStageVal.Value__c, groupOptyStageVal.Operation__c) ){
                            passCheckCount++;
                        } else {
                            passCheck = true;
                            break;
                        }
                    } else if( checkCondition(relatedObject.get(groupOptyStageVal.Field__c), groupOptyStageVal.Value__c, groupOptyStageVal.Operation__c) ){
                        passCheckCount++;
                    }
                }
                if( checkType == DOES_NOT_EXIST && passCheckCount < groupedStageValMap.get(groupName).size() - 1 ){
                    passCheck = true;
                } else if( passCheckCount >= groupedStageValMap.get(groupName).size() ){
                    passCheck = true;
                }
            }
            if( !passCheck ){
                opp.addError(errMsg);
            }
        }
    }

    public static List<Opportunity_Stage_Validation__mdt> getCurrentOptyStageVals(Opportunity opp){
        List<Opportunity_Stage_Validation__mdt> currentOptyStageVals = new List<Opportunity_Stage_Validation__mdt>();
        String primProduct = ( String.isNotBlank(opp.NSP_PrimaryProduct__c) ) ? opp.NSP_PrimaryProduct__c : NSP_SalesConstants.WO; // treat empty opty Product as WO
               primProduct = ( NSP_ValidateOpportunityStage.namedProducts.contains(primProduct) ) ? primProduct : DEFAULT_PRODUCT; // treat unmatched Product as Default

        for(Opportunity_Stage_Validation__mdt optyStageVal : optyStageVals){
            List<String> valPrimProducts = optyStageVal.Primary_Product__c.split(',');
            if( optyStageVal.IsActive__c && valPrimProducts.contains(primProduct) && optyStageVal.Stage__c == opp.StageName ){
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

    public static List<Opportunity_Stage_Validation__mdt> getUngroupedStageVals(List<Opportunity_Stage_Validation__mdt> currentOptyStageVals){
        List<Opportunity_Stage_Validation__mdt> ungroupedStageVals = new List<Opportunity_Stage_Validation__mdt>();
        for(Opportunity_Stage_Validation__mdt currentOptyStageVal : currentOptyStageVals){
            if( String.isBlank(currentOptyStageVal.Group__c) ){
                ungroupedStageVals.add(currentOptyStageVal);
            }
        }
        return ungroupedStageVals;
    }

    private static void validateOpportunityStageOld(List<Opportunity> newList, Map<Id,User> opportunityOwnerRoleMap){
        List<Id> oppIdList= new List<Id>();
        for(Opportunity opp:newList){
            oppIdList.add(opp.Id);
        }
        
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
                if(FeatureManagement.checkPermission('Allow_Closed_Lost_Opportunity') && opp.StageName.equals(NSP_SalesConstants.CLOSED_LOST)){
                    continue;
                }
                
                //Analysis
                if ( opp.StageName.equals(NSP_SalesConstants.ANALYSIS_STAGE)
                    || opp.StageName.equals(NSP_SalesConstants.PROPOSAL_STAGE)
                    || opp.StageName.equals(NSP_SalesConstants.CLOSING_STAGE)
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
                if(opp.StageName.equals(NSP_SalesConstants.ANALYSIS_STAGE)){//evaluate exit criteria to move to analysis stage
                    evaluateAnalysisStageCriteriaOld(opp,eventList);
                }
                /////Proposal
                if(opp.StageName.equals(NSP_SalesConstants.PROPOSAL_STAGE)){
                    //Modified: Primary Quote required only for Non WO opptys, hence moved Primary Quote validation to else if block
                    //Perform WO
                    // Added WS condition as part of DF-01869
                    if ( proposeStageCriteraTypes.contains( opp.Type )
                        && validHRProducts.contains( opp.NSP_PrimaryProduct__c )
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
                        if(!scannedTask.contains(HAS_WO) ){
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
                if(!opp.Fee_Inclusive__c && opp.StageName.equals(NSP_SalesConstants.CLOSING_STAGE)){
                    if(opp.NSP_PrimaryProduct__c!=NSP_SalesConstants.WO && !opp.NSP_Bypass_Docusign_Signature__c && !opp.NSP_Order_Generated__c){
                        if(!exitCriteriaProductException.contains(opp.NSP_PrimaryProduct__c)){
                            opp.addError(System.Label.NSP_Create_Signed_Delivery_Order);
                        } else if(opp.NSP_PrimaryProduct__c == NSP_SalesConstants.HR_CONSULTING_SERVICES && opp.NSP_Client_For_Life__c != NSP_SalesConstants.WO_WS){
                            opp.addError(System.Label.NSP_Create_Signed_Delivery_Order);
                        }
                    } else if (
                        ( validHRProducts.contains( opp.NSP_PrimaryProduct__c ) || opp.NSP_Order_Generated__c )
                        && !opp.NSP_Closing_Appointment__c
                        )
                    {
                        opp.addError( System.Label.NSP_WO_Closing_Appointment_or_Docusign );
                    }
                }
                //closed-won criteria CR-031
                if(opp.StageName.equals(NSP_SalesConstants.CLOSED_WON)){//evaluate criteria to move to closed won stage
                    //first check if primary quote is created and approved on primary products it is applicable on then check user based criteria
                    evaluateQuoteCriteria(opp,quoteMap);
                    evaluateClosedWonStageCriteriaOld(opp);
                }
                //closed-Lost criteria DF-1769
                if(opp.StageName.equals(NSP_SalesConstants.CLOSED_LOST)){//evaluate criteria to move to closed lost stage
                    evaluateClosedLostStageCriteria(opp, opportunityOwnerRoleMap);
                }
            }
        }
    }

    private static void evaluateAnalysisStageCriteria(Opportunity opp, List<Event> eventList, List<Task> taskList){
        String scannedTask='';
        String evalTaskMsg='';
        if( analysisStageCriteraTypes.contains(opp.Type)
            && (opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WX || opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WA) ){
            
            if(eventList!=null){
                for(Event event:eventList){////looking for discovery
                    if(event.NSP_Event_Subtype__c == NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY &&
                    event.NSP_Status__c !=NSP_SalesConstants.Cancelled){
                        scannedTask += HAS_DISCOVERY;
                        if(event.NSP_Status__c !=NSP_SalesConstants.DISCOVERY_CALL_COMPLETED){
                            scannedTask += HAS_OPEN_EVENT;
                        }
                    }
                }
            }
            
            //Show error
            if(!scannedTask.contains(HAS_DISCOVERY)){
                opp.addError(System.Label.NSP_AddDiscoveryCalls);
            }
            if(scannedTask.contains(HAS_OPEN_EVENT)){
                opp.addError(System.Label.NSP_CloseDiscoveryCallEvents);
            }
        }
    }

    private static void evaluateAnalysisStageCriteriaOld( Opportunity opp , List<Event> eventList ) {
        String scannedTask='';
        if ( validHRProducts.contains( opp.NSP_PrimaryProduct__c )
            || (
                analysisStageCriteraTypes.contains( opp.Type )
                && (
                    ( opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WX )
                    || ( opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WA )
                    )
                )
            )
        {
            if(eventList!=null){
                for(Event event:eventList){////looking for discovery
                    if(event.NSP_Event_Subtype__c == NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY &&
                    event.NSP_Status__c !=NSP_SalesConstants.Cancelled){
                        scannedTask += HAS_DISCOVERY;
                        if(event.NSP_Status__c !=NSP_SalesConstants.DISCOVERY_CALL_COMPLETED){
                            scannedTask += HAS_OPEN_EVENT;
                        }
                    }
                }
            }
            
            //Show error
            if(!scannedTask.contains(HAS_DISCOVERY)){
                opp.addError(System.Label.NSP_AddDiscoveryCalls);
            }
            if(scannedTask.contains(HAS_OPEN_EVENT)){
                opp.addError(System.Label.NSP_CloseDiscoveryCallEvents);
            }
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
            if ( !opp.Fee_Inclusive__c
                && !validHRProducts.contains( opp.NSP_PrimaryProduct__c )
                )
            {
                SBQQ__Quote__c primaryQuote = null;
                if ( quoteMap != null ) {
                    primaryQuote = quoteMap.get( opp.SBQQ__PrimaryQuote__c ); // prevent NullPointerExceptions...
                }
                if ( exitCriteriaProductException.contains( opp.NSP_PrimaryProduct__c ) ) {
                    if ( ( opp.NSP_PrimaryProduct__c == NSP_SalesConstants.HR_CONSULTING_SERVICES )
                        && ( opp.NSP_Client_For_Life__c != NSP_SalesConstants.WO_WS )
                        )
                    {
                        if ( opp.SBQQ__PrimaryQuote__c != null ) {
                            if ( primaryQuote != null ) {
                                if ( primaryQuote.SBQQ__Status__c != NSP_SalesConstants.APPROVAL_STATUS_APPROVED ) {
                                    opp.addError(System.Label.NSP_Approve_Primary_Quote);
                                } else if ( !test.isRunningTest()
                                    && opp.StageName.equals( NSP_SalesConstants.CLOSED_WON )
                                    && ( ( opp.NSP_PrimaryProduct__c != primaryQuote.NSP_Opportunity_Primary_Product__c ) || ( opp.NSP_Client_For_Life__c != primaryQuote.NSP_Client_For_Life__c ) )
                                    )
                                {
                                    opp.addError(System.label.NSP_Sync_Primary_Quote_With_Opportunity);
                                }
                            }
                        } else {
                            if ( !test.isRunningTest() ) {
                                opp.addError( System.Label.NSP_AddPrimaryQuote );
                            }
                        }
                    }
                } else {
                    if ( opp.SBQQ__PrimaryQuote__c != null ) {
                        if ( primaryQuote != null ) {
                            if ( primaryQuote.SBQQ__Status__c != NSP_SalesConstants.APPROVAL_STATUS_APPROVED ) {
                                opp.addError( System.Label.NSP_Approve_Primary_Quote );
                            } else if ( !test.isRunningTest()
                                && opp.StageName.equals( NSP_SalesConstants.CLOSED_WON )
                                && ( ( opp.NSP_PrimaryProduct__c != primaryQuote.NSP_Opportunity_Primary_Product__c ) || ( opp.NSP_Client_For_Life__c != primaryQuote.NSP_Client_For_Life__c ) )
                                )
                            {
                                opp.addError( System.label.NSP_Sync_Primary_Quote_With_Opportunity );
                            }
                        }
                    } else {
                        if ( ( opp.SBQQ__PrimaryQuote__c == null )
                            && (
                                ( opp.Type == NSP_SalesConstants.NEW_BUSINESS_OPPORTUNITY )
                                || ( ( opp.Type == NSP_SalesConstants.OPPORTUNITY_TYPE_EXISTING_PRODUCT ) && ( opp.NSP_AddonType__c == NSP_SalesConstants.OPPORTUNITY_SUBTYPE_AMENDMENT ) )
                                )
                            )
                        {
                            //DF-01080 subtype Amendment check added
                            opp.addError(System.Label.NSP_AddPrimaryQuote);
                        }
                    }
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
 
    private static void evaluateClosingStageCriteria( Opportunity opp ) {
        if ( !opp.Fee_Inclusive__c )
        {
            if ( !validHRProducts.contains( opp.NSP_PrimaryProduct__c )
                && !opp.NSP_Bypass_Docusign_Signature__c
                && !opp.NSP_Order_Generated__c
                )
            {
                if ( !exitCriteriaProductException.contains( opp.NSP_PrimaryProduct__c ) ) {
                    opp.addError( System.Label.NSP_Create_Signed_Delivery_Order );
                } else if ( ( opp.NSP_PrimaryProduct__c == NSP_SalesConstants.HR_CONSULTING_SERVICES )
                            && ( opp.NSP_Client_For_Life__c != NSP_SalesConstants.WO_WS )
                          )
                {
                    opp.addError( System.Label.NSP_Create_Signed_Delivery_Order );
                }
            } else if ( !opp.NSP_Closing_Appointment__c
                        && ( validHRProducts.contains(opp.NSP_PrimaryProduct__c) || opp.NSP_Order_Generated__c )
                      )
            {
                opp.addError(System.Label.NSP_WO_Closing_Appointment_or_Docusign);
            }
        }
    }
 
    private static void evaluateClosedWonStageCriteria( Opportunity opp ) {
        String scannedSTP = '';
        if ( NSP_ValidateOpportunityStage.permittedCWOppOwnerUserMap.containsKey( opp.OwnerId )
            && ( !hasAllowCWNCSUserPerm )
            && ownerBasedCriteriaProducts.contains( opp.NSP_PrimaryProduct__c )
            )
        {
            opp.addError( System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON );
        } else if ( nonOwnerBasedCriteriaProducts.contains( opp.NSP_PrimaryProduct__c )
            && ( UserInfo.getUserId() != opp.OwnerId )
            && ( !hasAllowCWNCSUserPerm )
            )
        {
            opp.addError( System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON );
        } else if ( ownerBasedCriteriaProducts.contains( opp.NSP_PrimaryProduct__c )
            && !NSP_ValidateOpportunityStage.permittedCWOppOwnerUserMap.containsKey( opp.OwnerId )
            && ( UserInfo.getUserId() != opp.OwnerId )
            && ( !hasAllowCWNCSUserPerm )
            )
        {
            opp.addError( System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON );
        } else if ( !hasAllowCWNCSUserPerm
            && validHRProducts.contains( opp.NSP_PrimaryProduct__c )
            )
        {
            opp.addError( System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON );
        }
    }

    private static void evaluateClosedWonStageCriteriaOld( Opportunity opp ) {
        if ( ownerBasedCriteriaProducts.contains(opp.NSP_PrimaryProduct__c)
            && !hasAllowCWNCSUserPerm
            && NSP_ValidateOpportunityStage.permittedCWOppOwnerUserMap.containsKey( opp.OwnerId )
            )
        {
            opp.AddError(System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON);
        } else if ( nonOwnerBasedCriteriaProducts.contains(opp.NSP_PrimaryProduct__c)
            && ( UserInfo.getUserId() != opp.OwnerId )
            && !hasAllowCWNCSUserPerm
            )
        {
            opp.AddError(System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON);
        } else if ( ownerBasedCriteriaProducts.contains(opp.NSP_PrimaryProduct__c)
            && !hasAllowCWNCSUserPerm
            && !NSP_ValidateOpportunityStage.permittedCWOppOwnerUserMap.containsKey( opp.OwnerId )
            && ( UserInfo.getUserId() != opp.OwnerId )
            )
        {
            opp.AddError(System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON);
        } else if ( !hasAllowCWNCSUserPerm
            && validHRProducts.contains( opp.NSP_PrimaryProduct__c )
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
        } else if( teamMemberList.contains(UserInfo.getUserId()) ){
            canCloseLost++;
        } else if( ( opp.NSP_Account_Segment__c == NSP_SalesConstants.MIDMARKET_SALES )
             && hasAllowCLMMPerm ){
            canCloseLost++;
        } else if( ( getSalesOfficeGroup(UserInfo.getUserId(),salesOfficeMembership) != '' )
             && hasCLSOOppOwnerPermission ){
            canCloseLost++;
        } else if( ( getSalesOfficeGroup(UserInfo.getUserId(),salesOfficeList) != '' )
             && hasCLSOOppPermission){
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

    public static String getSalesOfficeGroup( Id recordId , List<String> salesOffice ) {
        List <GroupMember> groupMemberList = [
            SELECT Id , Group.Name , UserOrGroupId
            FROM GroupMember
            WHERE (
                ( UserOrGroupId = :recordId )
                AND ( Group.Name IN :salesOffice )
            )
        ];
        if(!groupMemberList.isEmpty()){
            return groupMemberList[0].Group.Name;
        }
        return '';
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
    
    private static Map<String, String> retrieveFieldPicklistValues(Schema.sObjectField field) {
        Map<String, String> fieldPicklistValues = new Map<String, String>();
        if(field != null)
        {
            for(Schema.PicklistEntry sp : field.getDescribe().getPicklistValues()) {
                fieldPicklistValues.put(sp.getValue(), sp.getLabel());
            }
        }
        return fieldPicklistValues;
    }

    public static Boolean checkCondition(Object fieldValue, String ruleValue, String operation){
        if (fieldValue instanceOf Date) {
            Date ruleValueDate = null;
            if( ruleValue == null || String.isBlank(ruleValue) ){
                ruleValueDate = ruleValueDate;
            } else if( ruleValue.indexOf('TODAY') > -1 ) {
                ruleValueDate = Date.today();
            } else if( ruleValue.indexOf('TOMORROW') > -1 ) {
                ruleValueDate = Date.today().addDays(1);
            } else if( ruleValue.indexOf('YESTERDAY') > -1 ) {
                ruleValueDate = Date.today().addDays(-1);
            }
            return checkConditionTyped(Date.valueOf(fieldValue), ruleValueDate, operation);
        } else if (fieldValue instanceOf Double) {
            Double ruleValueDouble = null;
            if( !String.isBlank(ruleValue) ){
                ruleValueDouble = Double.valueOf(ruleValue);
            }
            return checkConditionTyped(Double.valueOf(fieldValue), ruleValueDouble, operation);
        } else if (fieldValue instanceOf Integer) {
            Integer ruleValueInteger = null;
            if( !String.isBlank(ruleValue) ){
                ruleValueInteger = Integer.valueOf(ruleValue);
            }
            return checkConditionTyped(Integer.valueOf(fieldValue), ruleValueInteger, operation);
        } else if (fieldValue instanceOf String) {
            return checkConditionTyped(String.valueOf(fieldValue), ruleValue, operation);
        } else if (fieldValue instanceOf Boolean) {
            Boolean ruleValueBoolean = null;
            if( !String.isBlank(ruleValue) ){
                ruleValueBoolean = Boolean.valueOf(ruleValue);
            }
            return checkConditionTyped(Boolean.valueOf(fieldValue), ruleValueBoolean, operation);
        }
        return false;
    }

    public static Boolean checkConditionTyped(Date fieldValue, Date ruleValue, String operation){
        switch on operation {
            when 'Equals' {
                return fieldValue == ruleValue;
            }
            when 'Does Not Equal' {
                return fieldValue != ruleValue;
            }
            when 'Greater Than or Equals' {
                return fieldValue != null && !String.isBlank(String.valueOf(fieldValue)) && fieldValue >= ruleValue;
            }
            when 'Less Than or Equals' {
                return fieldValue != null && !String.isBlank(String.valueOf(fieldValue)) && fieldValue <= ruleValue;
            }
            when 'Is Blank' {
                return fieldValue == null || String.isBlank(String.valueOf(fieldValue));
            }
            when 'Is Not Blank' {
                return fieldValue != null && !String.isBlank(String.valueOf(fieldValue));
            }
        }
        return false;
    }

    public static Boolean checkConditionTyped(Double fieldValue, Double ruleValue, String operation){
        switch on operation {
            when 'Equals' {
                return fieldValue == ruleValue;
            }
            when 'Does Not Equal' {
                return fieldValue != ruleValue;
            }
            when 'Greater Than or Equals' {
                return fieldValue != null && !String.isBlank(String.valueOf(fieldValue)) && fieldValue >= ruleValue;
            }
            when 'Less Than or Equals' {
                return fieldValue != null && !String.isBlank(String.valueOf(fieldValue)) && fieldValue <= ruleValue;
            }
            when 'Is Blank' {
                return fieldValue == null || String.isBlank(String.valueOf(fieldValue));
            }
            when 'Is Not Blank' {
                return fieldValue != null && !String.isBlank(String.valueOf(fieldValue));
            }
        }
        return false;
    }

    public static Boolean checkConditionTyped(Integer fieldValue, Integer ruleValue, String operation){
        switch on operation {
            when 'Equals' {
                return fieldValue == ruleValue;
            }
            when 'Does Not Equal' {
                return fieldValue != ruleValue;
            }
            when 'Greater Than or Equals' {
                return fieldValue != null && !String.isBlank(String.valueOf(fieldValue)) && fieldValue >= ruleValue;
            }
            when 'Less Than or Equals' {
                return fieldValue != null && !String.isBlank(String.valueOf(fieldValue)) && fieldValue <= ruleValue;
            }
            when 'Is Blank' {
                return fieldValue == null || String.isBlank(String.valueOf(fieldValue));
            }
            when 'Is Not Blank' {
                return fieldValue != null && !String.isBlank(String.valueOf(fieldValue));
            }
        }
        return false;
    }

    public static Boolean checkConditionTyped(String fieldValue, String ruleValue, String operation){
        switch on operation {
            when 'Equals' {
                return fieldValue == ruleValue;
            }
            when 'Does Not Equal' {
                return fieldValue != ruleValue;
            }
            when 'Contains' {
                return fieldValue != null && fieldValue.contains(ruleValue);
            }
            when 'Does Not Contain' {
                return fieldValue != null && !fieldValue.contains(ruleValue);
            }
            when 'In' {
            if (fieldValue != null && ruleValue != null) {
                Set<String> ruleValueSet = new Set<String>(ruleValue.split(','));
                return ruleValueSet.contains(fieldValue);
            }
                return false;
            }
            when 'Not In' {
                if (fieldValue != null && ruleValue != null) {
                    Set<String> ruleValueSet = new Set<String>(ruleValue.split(','));
                    return !ruleValueSet.contains(fieldValue);
                }
                return true;
            }
            when 'Is Blank' {
                return String.isBlank(fieldValue) || fieldValue == null;
            }
            when 'Is Not Blank' {
                return !String.isBlank(fieldValue) && fieldValue != null;
            }   
        }
        return false;
    }

    public static Boolean checkConditionTyped(Boolean fieldValue, Boolean ruleValue, String operation){
        switch on operation {
            when 'Equals' {
                return fieldValue == ruleValue;
            }
            when 'Does Not Equal' {
                return fieldValue != ruleValue;
            }  
        }
        return false;
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
}
//