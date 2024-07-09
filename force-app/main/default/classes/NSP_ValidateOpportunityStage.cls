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

 public class NSP_ValidateOpportunityStage {
    // test w/ NSP_ValidateOpportunityStageTest (84%)
    
    public static List<string> analysisStageCriteraTypes = System.Label.NSP_AnalysisStageCriteria.split(',');
    public static List<string> proposeStageCriteraTypes = System.Label.NSP_ProposeStageCriteria.split(',');
    public static List<string> exitCriteriaProductException = System.Label.NSP_ExitCriteriaProductException.split(',');
    public static List<string> ownerBasedCriteriaProducts = System.Label.NSP_OwnerBasedCriteriaProducts.split(',');
    public static List<string> nonOwnerBasedCriteriaProducts = System.Label.NSP_NonOwnerBasedCriteriaProducts.split(',');
    public static List<string> ownerBasedCriteriaRoles = System.Label.NSP_OwnerBasedCriteriaRoles.split(',');
    public static List<string> closedLostCriteriaRoles = System.Label.NSP_Close_Lost_Criteria_Roles.split(',');
    public static List<string> closeLostRolesforBusinessPerformanceConsultant = System.Label.Close_Lost_Roles_for_Business_Performance_Consultant.split(',');
    public static List<string> closeLostRolesforRetirementSalesConsultant = System.Label.Close_Lost_Roles_for_Retirement_Sales_Consultant.split(',');
    public static List<string> closeLostRolesforInsuranceSales = System.Label.Close_Lost_Roles_for_Insurance_Sales.split(',');
    public static List<string> closeLostRolesforTechnologySales = System.Label.Close_Lost_Roles_for_Technology_Sales.split(',');
    public static List<string> closeLostRolesforRecruitingSales = System.Label.Close_Lost_Roles_for_Recruiting_Sales.split(',');
    public static List<string> closeLostRoleinOpportunityTeam = System.Label.Close_Lost_Role_in_Opportunity_Team.split(',');
    public static List<string> closeLostRolesforsamesalesofficeonOppOwner = System.Label.Close_Lost_Roles_for_same_sales_office_on_Opp_Owner.split(',');
    public static List<string> closeLostRolesforsamesalesofficeonOpp = System.Label.Close_Lost_Roles_for_same_sales_office_on_Opp.split(',');
    public static Map<String, String> opptyBidStatus = retrieveFieldPicklistValues(Opportunity.NSP_Bid_Status__c);
    public static final String HAS_DISCOVERY = ' has Discovery ';
    public static final String HAS_OPEN_EVENT = ' has Open Event ';
    public static final String HAS_WO_TASK = ' has WO Task ';
    public static final String HAS_WO_EVENT = ' has WO Event ';
    public static final String HAS_WO = 'has WO';
    public static final String HAS_BUSINESS_PROFILE_STARTED_TASK_COMPLETED = ' Business profile started task completed ';
    public static final String HAS_BID_GENERATED_IN_AIMS_TASK_COMPLETED = ' Bid Generated In AIMS task completed ';
    public static final String HAS_BID_SENT_FROM_PRICING_REVIEW_TASK_COMPLETED = ' Sent From Pricing Review Task completed ';
    public static final String HAS_COMPLETED_STP = ' Sold to Paid Checklist completed ';
    
    public static void validateOpportunityStage(List<Opportunity> newList){

        //  Kill switch added on 6/10/2024
        if(!NSP_hotfix_Switch__c.getInstance(UserInfo.getUserId()).Is_Enabled_WO_WS_Stage_Entry__c){
            validateOpportunityStageOld(newList);
        }
        else{
            List<Id> oppIdList= new List<Id>();
            for(Opportunity opp:newList){
                oppIdList.add(opp.Id);
            }
            
            Id soldToCheckListRecordTypeId = Schema.SObjectType.NSP_Checklist__c.getRecordTypeInfosByDeveloperName().get('NSP_Sold_to_Paid_Checklist').getRecordTypeId();
            
            List<NSP_Profile_Detail__mdt> profileDetailList = [SELECT Profile_ID__c, Profile_Name__c FROM NSP_Profile_Detail__mdt WHERE Profile_Name__c =: System.label.NSP_Integration_User_Profile_Name LIMIT 1 ];
            Id integrationUserprofileId = NSP_SalesConstants.INTEGRATION_USER_PROFILE_ID;
            if(profileDetailList != null && !profileDetailList.isEmpty())
            {
                integrationUserprofileId = profileDetailList[0].Profile_ID__c;
            }
            Map<ID, Opportunity> oppMapwithEventTask = new Map<ID, Opportunity>([SELECT AccountId,Id,
                                                                             (SELECT Id, Status, NSP_Task_Type__c, Subject FROM Tasks WHERE CreatedBy.ProfileId =: integrationUserprofileId AND NSP_Task_Type__c != NULL),
                                                                             (SELECT Id, NSP_Event_Subtype__c, NSP_Status__c FROM Events WHERE NSP_Event_Subtype__c != NULL),
                                                                             (SELECT Id FROM OpportunityContactRoles)
                                                                             FROM Opportunity Where Id IN :oppIdList]);
            
            Map<Id,SBQQ__Quote__c> quoteMap = new Map<Id,SBQQ__Quote__c>([SELECT Id, SBQQ__Status__c, NSP_Opportunity_Primary_Product__c, NSP_Client_For_Life__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN :oppIdList AND SBQQ__Primary__c = TRUE]);
            
            Map<Id,NSP_Checklist__c> checklistMap = new Map<Id,NSP_Checklist__c>();

            for (NSP_Checklist__c stp : [SELECT NSP_Opportunity__c, Status__c FROM NSP_Checklist__c WHERE NSP_Opportunity__c IN :oppIdList 
                                     AND recordtypeId =: soldToCheckListRecordTypeId AND Status__c =: NSP_SalesConstants.COMPLETED]){
                checklistMap.put(stp.NSP_Opportunity__c, stp);
            }
            
            if((newList != null) && !newList.isEmpty()) {
                for(Opportunity opp:newList){

                    Opportunity oppFromMap=oppMapwithEventTask.get(opp.Id);
                    List<Task> taskList=oppFromMap?.Tasks;
                    List<Event> eventList=oppFromMap?.Events;
                    List<OpportunityContactRole> ocrList = oppFromMap?.OpportunityContactRoles;
                    
                    if(String.isNotBlank(opp.StageName)){
                        
                        //  Added 275639
                        if(FeatureManagement.checkPermission('Allow_Closed_Lost_Opportunity') && opp.StageName.equals(NSP_SalesConstants.CLOSED_LOST)){
                            continue;
                        }
                        
                        //Discovery
                        if ( opp.StageName.equals(NSP_SalesConstants.DISCOVERY_STAGE))
                        {
                            String scannedEvent='';
                            if(eventList!=null){
                                for(Event event:eventList){
                                    if(event.NSP_Event_Subtype__c == NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY &&
                                    event.NSP_Status__c !=NSP_SalesConstants.Cancelled){
                                        scannedEvent += HAS_DISCOVERY;
                                    }
                                }
                            }
                            
                            if(!scannedEvent.contains(HAS_DISCOVERY)){
                                opp.addError(System.Label.AddDiscoveryCalls_Discovery);
                            }
                            
                            if(ocrList == null || ocrList.size() == 0)
                            {
                                opp.addError(System.Label.AddContact_Discovery);
                            }
                        }
                        
                        //Data Collection
                        if(opp.StageName.equals(NSP_SalesConstants.DATA_COLLECTION_STAGE))
                        {
                            if(opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO
                                || opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WS)
                            {
                                String scannedEvent='';
                                if(eventList!=null)
                                {
                                    for(Event event:eventList){
                                        if(event.NSP_Event_Subtype__c == NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY &&
                                            event.NSP_Status__c !=NSP_SalesConstants.Cancelled)
                                        {
                                            scannedEvent += HAS_DISCOVERY;
                                            if(event.NSP_Status__c !=NSP_SalesConstants.DISCOVERY_CALL_COMPLETED)
                                            {
                                                scannedEvent += HAS_OPEN_EVENT;
                                            }
                                        }
                                    }
                                }
                                
                                if(!scannedEvent.contains(HAS_DISCOVERY)){
                                    opp.addError(System.Label.AddDiscoveryCalls_DataColl);
                                }
                                if(scannedEvent.contains(HAS_OPEN_EVENT)){
                                    opp.addError(System.Label.NSP_CloseDiscoveryCallEvents);
                                }
                            }
                            //Primary product should be selected by the time they reach this stage.
                            else if(opp.NSP_PrimaryProduct__c == null)
                            {
                                opp.addError(System.Label.NSP_AddPrimaryProduct);
                            }
                        }
                        
                        //Analysis
                        if (opp.StageName.equals(NSP_SalesConstants.ANALYSIS_STAGE)
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
                        if (opp.StageName.equals(NSP_SalesConstants.ANALYSIS_STAGE)){//evaluate exit criteria to move to analysis stage
                            evaluateAnalysisStageCriteria(opp, eventList, taskList);
                        }
                        /////Proposal
                        if (opp.StageName.equals(NSP_SalesConstants.PROPOSAL_STAGE)){
                            if(proposeStageCriteraTypes.contains(opp.Type)){
                                //Modified: Primary Quote required only for Non WO opptys, hence moved Primary Quote validation to else if block
                                //Perform WO
                                // Added WS condition as part of DF-01869
                                if ( opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO || opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WS )
                                {
                                    if(opptyBidStatus != null && opptyBidStatus.get(opp.NSP_Bid_Status__c) != NSP_SalesConstants.BID_STATUS_APPROVED){
                                        opp.addError(System.Label.BidApproved_Proposal);
                                    }
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
                            } else if((opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO || opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WS)
                            || ((opp.NSP_PrimaryProduct__c != NSP_SalesConstants.WO || opp.NSP_PrimaryProduct__c != NSP_SalesConstants.WS) &&
                                opp.NSP_Order_Generated__c))
                            {
                                if(!opp.NSP_Closing_Appointment__c){
                                    opp.addError(System.Label.NSP_WO_Closing_Appointment_or_Docusign);
                                }
                            }
                        }
                        //closed-won criteria CR-031
                        if(opp.StageName.equals(NSP_SalesConstants.CLOSED_WON)){//evaluate criteria to move to closed won stage
                            //first check if primary quote is created and approved on primary products it is applicable on then check user based criteria
                            evaluateQuoteCriteria(opp,quoteMap);
                            evaluateClosedWonStageCriteria(opp, checklistMap);
                        }
                        //closed-Lost criteria DF-1769
                        if(opp.StageName.equals(NSP_SalesConstants.CLOSED_LOST)){//evaluate criteria to move to closed lost stage
                            evaluateClosedLostStageCriteria(opp);
                        }
                    }
                }
            }
        }
    }
    
    private static void validateOpportunityStageOld(List<Opportunity> newList){
        List<Id> oppIdList= new List<Id>();
        for(Opportunity opp:newList){
            oppIdList.add(opp.Id);
        }
        
        Map<ID, Opportunity> oppMapwithEventTask = new Map<ID, Opportunity>([SELECT AccountId,Id,
                                                                             (SELECT Id,Status, NSP_Task_Subtype__c FROM Tasks WHERE NSP_Task_Subtype__c != NULL),
                                                                             (SELECT Id, NSP_Event_Subtype__c,NSP_Status__c FROM Events WHERE NSP_Event_Subtype__c   != NULL)
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
                    if(proposeStageCriteraTypes.contains(opp.Type)){
                        //Modified: Primary Quote required only for Non WO opptys, hence moved Primary Quote validation to else if block
                        //Perform WO
                        // Added WS condition as part of DF-01869
                        if ( opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO
                            || opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WS
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
                    }
                    evaluateQuoteCriteria(opp,quoteMap);
                }
                //CR-031 removed Executive summary check and have added BPS Products condition
                // 205583/208335 - bypass QuoteCriteria is Fee Inclusive is checked
                if(!opp.Fee_Inclusive__c && opp.StageName.equals(NSP_SalesConstants.CLOSING_STAGE)){
                    if(opp.NSP_PrimaryProduct__c!=NSP_SalesConstants.WO && !opp.NSP_Bypass_Docusign_Signature__c && !opp.NSP_Order_Generated__c){
                        if(!exitCriteriaProductException.contains(opp.NSP_PrimaryProduct__c)){
                            opp.addError(System.Label.NSP_Create_Signed_Delivery_Order);
                        }else if(opp.NSP_PrimaryProduct__c == NSP_SalesConstants.HR_CONSULTING_SERVICES && opp.NSP_Client_For_Life__c != NSP_SalesConstants.WO_WS){
                            opp.addError(System.Label.NSP_Create_Signed_Delivery_Order);
                        }
                    }else if(
                    (opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO || opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WS)
                        || ((opp.NSP_PrimaryProduct__c != NSP_SalesConstants.WO || opp.NSP_PrimaryProduct__c != NSP_SalesConstants.WS) && opp.NSP_Order_Generated__c)
                        )
                    {
                        if(!opp.NSP_Closing_Appointment__c){
                            opp.addError(System.Label.NSP_WO_Closing_Appointment_or_Docusign);
                        }
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
                    evaluateClosedLostStageCriteria(opp);
                }
            }
        }
    }
    
    
    /**
     * Evaluate entry criteria for analysis stage
     * @param opportunityList list of New Opportunity.
     * @param  list of events
     * @return void
     *
     *
     */
    private static void evaluateAnalysisStageCriteria(Opportunity opp, List<Event> eventList, List<Task> taskList){
        
        //  Kill switch added on 6/10/2024
        if (!NSP_hotfix_Switch__c.getInstance( UserInfo.getUserId() ).Is_Enabled_WO_WS_Stage_Entry__c){
            evaluateAnalysisStageCriteriaOld(opp, eventList);
        }
        else{
            
            String scannedTask='';
            String evalTaskMsg='';
            if((opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO || opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WS))
            {
                if(taskList != null){
                    for(Task task:taskList){
                        if(task.Subject == System.Label.Business_Profile_Started && task.Status == NSP_SalesConstants.COMPLETED){
                            scannedTask += HAS_BUSINESS_PROFILE_STARTED_TASK_COMPLETED;
                        }
                        if(task.Subject == System.Label.Bid_Generated_in_AIMS && task.Status == NSP_SalesConstants.COMPLETED){
                            scannedTask += HAS_BID_GENERATED_IN_AIMS_TASK_COMPLETED;
                        }
                        if(task.Subject == System.Label.Bid_Sent_to_Pricing_and_Review && task.Status == NSP_SalesConstants.COMPLETED){
                            scannedTask += HAS_BID_SENT_FROM_PRICING_REVIEW_TASK_COMPLETED;
                        }
                    }
                }
                
                if(!(scannedTask.contains(HAS_BUSINESS_PROFILE_STARTED_TASK_COMPLETED)))
                {
                    evalTaskMsg += ', ' + System.Label.Business_Profile_Started;
                }
                if(!(scannedTask.contains(HAS_BID_GENERATED_IN_AIMS_TASK_COMPLETED)))
                {
                    evalTaskMsg += ', ' + System.Label.Bid_Generated_in_AIMS;
                }
                if(!(scannedTask.contains(HAS_BID_SENT_FROM_PRICING_REVIEW_TASK_COMPLETED)))
                {
                    evalTaskMsg += ', ' + System.Label.Bid_Sent_to_Pricing_and_Review;
                }
                
                if(String.isNotBlank(evalTaskMsg))
                {
                    opp.addError(System.Label.EvalTaskPrefix_Analysis + ' ' + evalTaskMsg.substringAfter(', '));
                }
                if(opptyBidStatus != null && opptyBidStatus.get(opp.NSP_Bid_Status__c) != NSP_SalesConstants.BID_STATUS_LOCKED)
                {
                    opp.addError(System.Label.BidLocked_Analysis);
                }
            }
            
            if((analysisStageCriteraTypes.contains(opp.Type)
            && (opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WX || opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WA))){
                
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
    }
    
    private static void evaluateAnalysisStageCriteriaOld(Opportunity opp,List<Event> eventList){
        String scannedTask='';
        
        if((opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO || opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WS)
            || (analysisStageCriteraTypes.contains(opp.Type)
        && (opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WX || opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WA))){
            
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
    public static void evaluateQuoteCriteria(Opportunity opp,Map<Id,SBQQ__Quote__c> quoteMap){
        try{
            // 205583/208335 - bypass QuoteCriteria is Fee Inclusive is checked
            if(!opp.Fee_Inclusive__c && opp.NSP_PrimaryProduct__c != NSP_SalesConstants.WO && opp.NSP_PrimaryProduct__c != NSP_SalesConstants.WS){
                if(exitCriteriaProductException.contains(opp.NSP_PrimaryProduct__c)){
                    if(opp.NSP_PrimaryProduct__c == NSP_SalesConstants.HR_CONSULTING_SERVICES && opp.NSP_Client_For_Life__c != NSP_SalesConstants.WO_WS){
                        if(opp.SBQQ__PrimaryQuote__c != null){
                            if(quoteMap.get(opp.SBQQ__PrimaryQuote__c).SBQQ__Status__c != NSP_SalesConstants.APPROVAL_STATUS_APPROVED ){
                                opp.addError(System.Label.NSP_Approve_Primary_Quote);
                            }else if(!test.isRunningTest() && opp.StageName.equals(NSP_SalesConstants.CLOSED_WON) && (opp.NSP_PrimaryProduct__c != quoteMap.get(opp.SBQQ__PrimaryQuote__c).NSP_Opportunity_Primary_Product__c || opp.NSP_Client_For_Life__c != quoteMap.get(opp.SBQQ__PrimaryQuote__c).NSP_Client_For_Life__c)){
                                opp.addError(System.label.NSP_Sync_Primary_Quote_With_Opportunity);
                            }
                        }else{
                            if(!test.isRunningTest()){
                                opp.addError(System.Label.NSP_AddPrimaryQuote);
                            }
                        }
                    }
                }else{
                    if(opp.SBQQ__PrimaryQuote__c != null){
                        if(quoteMap.get(opp.SBQQ__PrimaryQuote__c).SBQQ__Status__c != NSP_SalesConstants.APPROVAL_STATUS_APPROVED ){
                            opp.addError(System.Label.NSP_Approve_Primary_Quote);
                        }else if(!test.isRunningTest() && opp.StageName.equals(NSP_SalesConstants.CLOSED_WON) && (opp.NSP_PrimaryProduct__c != quoteMap.get(opp.SBQQ__PrimaryQuote__c).NSP_Opportunity_Primary_Product__c || opp.NSP_Client_For_Life__c != quoteMap.get(opp.SBQQ__PrimaryQuote__c).NSP_Client_For_Life__c)){
                            opp.addError(System.label.NSP_Sync_Primary_Quote_With_Opportunity);
                        }
                    }else{
                        if(opp.SBQQ__PrimaryQuote__c == null && (opp.Type == NSP_SalesConstants.NEW_BUSINESS_OPPORTUNITY || (opp.Type == NSP_SalesConstants.OPPORTUNITY_TYPE_EXISTING_PRODUCT && opp.NSP_AddonType__c == NSP_SalesConstants.OPPORTUNITY_SUBTYPE_AMENDMENT))){
                            //DF-01080 subtype Amendment check added
                            opp.addError(System.Label.NSP_AddPrimaryQuote);
                        }
                    }
                }
            }
        } catch(Exception ex) {
            NSP_CustomException.LogException(ex);
        }
    }
    
    /**
     * Evaluate entry criteria for Closed Won stage
     * @param opportunityList list of New Opportunity.
     *
     * @return void
     *  *
     *
     */
    private static void evaluateClosedWonStageCriteria(Opportunity opp, Map<Id,NSP_Checklist__c> checklistMap){
        
        //  Kill switch added on 6/10/2024
        if (!NSP_hotfix_Switch__c.getInstance(UserInfo.getUserId()).Is_Enabled_WO_WS_Stage_Entry__c){
            evaluateClosedWonStageCriteriaOld(opp);
        }
        else{

            String scannedSTP = '';
            Map<Id,User> opportunityOwnerRoleMap = getUserRole( opp.OwnerId );
            String opportunityOwnerRoleName = null;
            if ( opportunityOwnerRoleMap.containsKey( opp.OwnerId ) ) {
                User opportunityOwner = opportunityOwnerRoleMap.get( opp.OwnerId );
                if ( ( opportunityOwner != null ) && ( opportunityOwner.UserRole != null ) ) {
                    opportunityOwnerRoleName = opportunityOwner.UserRole.Name;
                }
            }
            Map<Id,User> currentUserRoleMap = getUserRole( UserInfo.getUserId() );
            String currentUserRoleName = null;
            if ( currentUserRoleMap.containsKey( UserInfo.getUserId() ) ) {
                User currentUser = currentUserRoleMap.get( UserInfo.getUserId() );
                if ( ( currentUser != null ) && ( currentUser.UserRole != null ) ) {
                    currentUserRoleName = currentUser.UserRole.Name;
                }
            }
            if ( ( currentUserRoleName != null )
                && ownerBasedCriteriaRoles.contains( opportunityOwnerRoleName )
                && ( currentUserRoleName != NSP_SalesConstants.NEW_CLIENT_SALES )
                && ownerBasedCriteriaProducts.contains( opp.NSP_PrimaryProduct__c )
                )
            {
                opp.addError( System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON );
            } else if ( nonOwnerBasedCriteriaProducts.contains( opp.NSP_PrimaryProduct__c )
                && ( UserInfo.getUserId() != opp.OwnerId )
                && ( currentUserRoleName != NSP_SalesConstants.NEW_CLIENT_SALES )
                )
            {
                opp.addError( System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON );
            } else if ( ownerBasedCriteriaProducts.contains( opp.NSP_PrimaryProduct__c )
                && !ownerBasedCriteriaRoles.contains( opportunityOwnerRoleName )
                && ( UserInfo.getUserId() != opp.OwnerId )
                && ( currentUserRoleName != NSP_SalesConstants.NEW_CLIENT_SALES )
                )
            {
                opp.addError( System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON );
            } else if( ( currentUserRoleName != null )
                && ( currentUserRoleName != NSP_SalesConstants.NEW_CLIENT_SALES )
                && ( ( opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO )
                    || ( opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WS )
                    )
                )
            {
                opp.addError( System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON );
            }
            if((opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO || opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WS)){
                
                if(checklistMap.get(opp.Id) != null){
                    scannedSTP = HAS_COMPLETED_STP;
                }
                if(!scannedSTP.contains(HAS_COMPLETED_STP)){
                    opp.addError(System.Label.STPCompleted_ClosedWon);
                }
                if(opp.NSP_Forecast_Status__c != NSP_SalesConstants.FORECAST_STATUS_PENDING && opp.NSP_Forecast_Status__c != NSP_SalesConstants.FORECAST_STATUS_SOLDBOOKED){
                    opp.addError(System.Label.ForecastStatus_ClosedWon);
                }
            }
        }
    }
    
    private static void evaluateClosedWonStageCriteriaOld(Opportunity opp){
        Map<Id,User> OpportunityOwnerRoleMap= getUserRole(opp.OwnerId);
        Map<Id,User> currentUserRoleMap=getUserRole(userInfo.getUserId());
        if(currentUserRoleMap.get(userInfo.getUserId()).UserRole.Name !=null &&  ownerBasedCriteriaRoles.contains(OpportunityOwnerRoleMap.get(opp.OwnerId).UserRole.Name)
        && currentUserRoleMap.get(userInfo.getUserId()).UserRole.Name != NSP_SalesConstants.NEW_CLIENT_SALES && ownerBasedCriteriaProducts.contains(opp.NSP_PrimaryProduct__c) ){
            opp.AddError(System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON);
        }
        else if(nonOwnerBasedCriteriaProducts.contains(opp.NSP_PrimaryProduct__c)  && userInfo.getUserId()!= opp.OwnerId && currentUserRoleMap.get(userInfo.getUserId()).UserRole.Name != NSP_SalesConstants.NEW_CLIENT_SALES){
            opp.AddError(System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON);
        }
        else if(ownerBasedCriteriaProducts.contains(opp.NSP_PrimaryProduct__c) && !ownerBasedCriteriaRoles.contains(OpportunityOwnerRoleMap.get(opp.OwnerId).UserRole.Name)
        && userInfo.getUserId()!= opp.OwnerId && currentUserRoleMap.get(userInfo.getUserId()).UserRole.Name != NSP_SalesConstants.NEW_CLIENT_SALES){
            opp.AddError(System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON);
        }
        else if(currentUserRoleMap.get(userInfo.getUserId()).UserRole.Name !=null && currentUserRoleMap.get(userInfo.getUserId()).UserRole.Name != NSP_SalesConstants.NEW_CLIENT_SALES &&
        (opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO || opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WS)){
            opp.AddError(System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON);
        }
    }
    
    
    /***********************************************************************************************
     * MethodName: getUserRole
     * Description : This method is used to get the role of the User
     * Params:       String UserId
     * Author :     Nischay
     * ********************************************************************************************/
    public static  Map<Id,User> getUserRole(String UserId){
        Map<Id,User> userMap= new Map<Id,User>([SELECT Id, UserRole.Name, ToLabel(NSP_Sales_Office__c), ToLabel(NSP_Sales_Office_Membership__c) FROM User WHERE Id =:UserId]);
        return userMap;
    }
    
    // Checks if current user can modify opportunity stage to closed lost
    // @param Opportunity opp
    // @return void
    // @DF-01769
    // Modified Logic for Close Lost
    // Date- 8/4/2022
    // Developer- Ruchi
    // Ticket-10350
    // Modification Date- 9/30/2022
    public static void evaluateClosedLostStageCriteria( Opportunity opp ) {
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
        Map<Id,User> OpportunityOwnerRoleMap = getUserRole( opp.OwnerId );
        List<String> salesOfficeMembership = new List<String>();
        if(OpportunityOwnerRoleMap.get(opp.OwnerId).NSP_Sales_Office_Membership__c != null){
            salesOfficeMembership.addAll(OpportunityOwnerRoleMap.get(opp.OwnerId).NSP_Sales_Office_Membership__c.split(';'));
        }
        List<ID> TeamMemberList = new List<ID>();
        List<OpportunityTeamMember> OpportunityTeamMemberList = [SELECT Id, UserId, TeamMemberRole from OpportunityTeamMember where OpportunityId = : opp.Id and TeamMemberRole =: closeLostRoleinOpportunityTeam];
        if(!OpportunityTeamMemberList.isEmpty()) {
            for(OpportunityTeamMember oppTeamMember : OpportunityTeamMemberList){
                TeamMemberList.add(oppTeamMember.UserId);
            }
        }
        
        Integer canCloseLost =0;
        Map<Id,User> currentUserRoleMap = getUserRole( UserInfo.getUserId() );
        if(FeatureManagement.checkPermission('Allow_Closed_Lost_Opportunity')){
            canCloseLost++;
        }
        else if(OpportunityOwnerRoleMap.get(opp.OwnerId).UserRole.Name == NSP_SalesConstants.BUSINESS_PERFORMANCE_CONSULTANT && closeLostRolesforBusinessPerformanceConsultant.contains(currentUserRoleMap.get(userInfo.getUserId()).UserRole.Name)){
            canCloseLost++;
        }else if(OpportunityOwnerRoleMap.get(opp.OwnerId).UserRole.Name == NSP_SalesConstants.RETIREMENT_SALES_CONSULTANT && closeLostRolesforRetirementSalesConsultant.contains(currentUserRoleMap.get(userInfo.getUserId()).UserRole.Name)){
            canCloseLost++;
        }else if(OpportunityOwnerRoleMap.get(opp.OwnerId).UserRole.Name == NSP_SalesConstants.INSURANCE_SALES && closeLostRolesforInsuranceSales.contains(currentUserRoleMap.get(userInfo.getUserId()).UserRole.Name)){
            canCloseLost++;
        }else if(OpportunityOwnerRoleMap.get(opp.OwnerId).UserRole.Name == NSP_SalesConstants.RECRUITING_SALES && closeLostRolesforRecruitingSales.contains(currentUserRoleMap.get(userInfo.getUserId()).UserRole.Name)){
            canCloseLost++;
        }else if(OpportunityOwnerRoleMap.get(opp.OwnerId).UserRole.Name == NSP_SalesConstants.TECHNOLOGY_SALES && closeLostRolesforTechnologySales.contains(currentUserRoleMap.get(userInfo.getUserId()).UserRole.Name)){
            canCloseLost++;
        }else if(opp.ownerid == userInfo.getUserId()){
            canCloseLost++;
        }else if(TeamMemberList.contains(userInfo.getUserId())){
            canCloseLost++;
        }
        //Added for 578774
        else if(opp.NSP_Account_Segment__c == NSP_SalesConstants.MIDMARKET_SALES && closeLostRolesforBusinessPerformanceConsultant.contains(currentUserRoleMap.get(userInfo.getUserId()).UserRole.Name)){
            canCloseLost++;
        }
        //Added for 579280
        else if(getSalesOfficeGroup(userInfo.getUserId(),salesOfficeMembership) != '' && closeLostRolesforsamesalesofficeonOppOwner.contains(currentUserRoleMap.get(userInfo.getUserId()).UserRole.Name)){
            canCloseLost++;
        }
        //Added for 579279
        else if(getSalesOfficeGroup(userInfo.getUserId(),salesOfficeList) != '' && closeLostRolesforsamesalesofficeonOpp.contains(currentUserRoleMap.get(userInfo.getUserId()).UserRole.Name)){
            canCloseLost++;
        }
        if(canCloseLost == 0){
            opp.AddError(System.Label.NSP_CANNOT_MOVE_TO_CLOSEDLOST);
        }
    }
    
    /**
     * gets the group id of sales office group of which user is member
     * @param Id userId
     * @param String SalesOffice
     *
     * @return void
     * @DF-01769
     */
    public static String getSalesOfficeGroup(Id userId, List<String> SalesOffice){
        List <GroupMember> groupMemberList = [SELECT Id, Group.Name, UserOrGroupId FROM GroupMember WHERE UserOrGroupId = : userId and Group.Name IN:SalesOffice];
        if(!groupMemberList.isEmpty()){
            return groupMemberList[0].Group.Name;
        }
        return '';
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
}