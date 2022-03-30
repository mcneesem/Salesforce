
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
    
    public static List<string> analysisStageCriteraTypes = System.Label.NSP_AnalysisStageCriteria.split(',');
    public static List<string> proposeStageCriteraTypes = System.Label.NSP_ProposeStageCriteria.split(',');
    public static List<string> exitCriteriaProductException = System.Label.NSP_ExitCriteriaProductException.split(',');
    public static List<string> ownerBasedCriteriaProducts = System.Label.NSP_OwnerBasedCriteriaProducts.split(',');
    public static final String HAS_DISCOVERY = ' has Discovery ';
    public static final String HAS_OPEN_EVENT = ' has Open Event ';
    public static final String HAS_WO_TASK = ' has WO Task ';
    public static final String HAS_WO_EVENT = ' has WO Event ';
    public static final String HAS_WO = 'has WO';
    
    public static void validateOpportunityStage(List<Opportunity> newList){
        List<Id> oppIdList= new List<Id>();
        for(Opportunity opp:newList){
            oppIdList.add(opp.Id);
        }
        
        Map<ID, Opportunity> oppMapwithEventTask = new Map<ID, Opportunity>([SELECT AccountId,Id,
                                                                             (SELECT Id,Status, NSP_Task_Subtype__c FROM Tasks WHERE NSP_Task_Subtype__c != NULL),
                                                                             (SELECT Id, NSP_Event_Subtype__c,NSP_Status__c FROM Events WHERE NSP_Event_Subtype__c   != NULL)
                                                                             FROM Opportunity Where Id IN :oppIdList]);
        
        Map<Id,SBQQ__Quote__c> quoteMap = new Map<Id,SBQQ__Quote__c>([SELECT id, SBQQ__Status__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN :oppIdList AND SBQQ__Primary__c = TRUE]);
        
        
        for(Opportunity opp:newList){        
            Opportunity oppFromMap=oppMapwithEventTask.get(opp.Id);
            List<Task> taskList=oppFromMap?.Tasks;
            List<Event> eventList=oppFromMap?.Events;
            List<Quote> quotes=oppFromMap?.Quotes;
            
            //Analysis
            if(opp.StageName.equals(NSP_SalesConstants.ANALYSIS_STAGE) || 
               opp.StageName.equals(NSP_SalesConstants.PROPOSAL_STAGE) ||
               opp.StageName.equals(NSP_SalesConstants.CLOSING_STAGE) ){ //add Proposal
                   
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
                evaluateAnalysisStageCriteria(opp,eventList);
            }
            
            /////Proposal 
            
            if(opp.StageName.equals(NSP_SalesConstants.PROPOSAL_STAGE)){
                
                if(proposeStageCriteraTypes.contains(opp.Type)){
                    
                    //Modified: Primary Quote required only for Non WO opptys, hence moved Primary Quote validation to else if block
                    //Perform WO
                    if(opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO){
                        
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
                    } else if(opp.SBQQ__PrimaryQuote__c == null && (opp.Type == NSP_SalesConstants.NEW_BUSINESS_OPPORTUNITY || 
                                                                    (opp.Type == NSP_SalesConstants.OPPORTUNITY_TYPE_EXISTING_PRODUCT 
                                                                     && opp.NSP_AddonType__c == NSP_SalesConstants.OPPORTUNITY_SUBTYPE_AMENDMENT))){//DF-01080 subtype Amendment check added
                                                                         opp.addError(System.Label.NSP_AddPrimaryQuote);
                                                                     }
                }
                evaluateProposalStageCriteria(opp,quoteMap);
            }
            //CR-031 removed Executive summary check and have added BPS Products condition
            if(opp.StageName.equals(NSP_SalesConstants.CLOSING_STAGE)){
                if(opp.NSP_PrimaryProduct__c!=NSP_SalesConstants.WO && !opp.NSP_Bypass_Docusign_Signature__c && !opp.NSP_Order_Generated__c){
                    if(!exitCriteriaProductException.contains(opp.NSP_PrimaryProduct__c)){
                        opp.addError(System.Label.NSP_Create_Signed_Delivery_Order);
                    }else if(opp.NSP_PrimaryProduct__c == NSP_SalesConstants.HR_CONSULTING_SERVICES && opp.NSP_Client_For_Life__c != NSP_SalesConstants.WO_WS){
                        opp.addError(System.Label.NSP_Create_Signed_Delivery_Order);
                    }
                    
                }else if(opp.NSP_PrimaryProduct__c==NSP_SalesConstants.WO || (opp.NSP_PrimaryProduct__c!=NSP_SalesConstants.WO && opp.NSP_Order_Generated__c)){
                    if(opp.NSP_Docusign_Sent_Date__c == null && !opp.NSP_Closing_Appointment__c){
                        opp.addError(System.Label.NSP_WO_Closing_Appointment_or_Docusign);  
                    }
                }
            }
            
            //closed-won criteria CR-031
            if(opp.StageName.equals(NSP_SalesConstants.CLOSED_WON)){//evaluate criteria to move to closed won stage
                evaluateClosedWonStageCriteria(opp);
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
    public static void evaluateAnalysisStageCriteria(Opportunity opp,List<Event> eventList){
        String scannedTask='';
        
        if((opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO || opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WS)
           || (analysisStageCriteraTypes.contains(opp.Type) 
               && (opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WX || opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WA))){
                   
                   if(eventList!=null){
                       for(Event event:eventList){////looking for discovery
                           if(event.NSP_Event_Subtype__c == NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY){
                               scannedTask += HAS_DISCOVERY;
                           }
                       }
                   }
                   
                   //Show error
                   if(!scannedTask.contains(HAS_DISCOVERY)){
                       opp.addError(System.Label.NSP_AddDiscoveryCalls);
                   }
               }
        if(opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO || opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WX){
            if(eventList!=null){
                for(Event event:eventList){////looking for discovery
                    if(event.NSP_Event_Subtype__c == NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY){
                        if(event.NSP_Status__c !=NSP_SalesConstants.DISCOVERY_CALL_COMPLETED){
                            scannedTask += HAS_OPEN_EVENT;
                        }
                    }
                }
            }
            if(scannedTask.contains(HAS_OPEN_EVENT)){
                opp.addError(System.Label.NSP_CloseDiscoveryCallEvents);
            }
            
        }
        
    }
    
    /**
* Evaluate entry criteria for proposal stage
* @param opportunityList list of New Opportunity.  
* @param  list of events
* @param list of tasks
* @return void             
*   
*   added under CR-031          
*/ 
    public static void evaluateProposalStageCriteria(Opportunity opp,Map<Id,SBQQ__Quote__c> quoteMap){
        try{
            
            if(opp.NSP_PrimaryProduct__c != NSP_SalesConstants.WO 
               &&(!opp.NSP_Bypass_Docusign_Signature__c)){
                   if(exitCriteriaProductException.contains(opp.NSP_PrimaryProduct__c)){
                       if(opp.NSP_PrimaryProduct__c == NSP_SalesConstants.HR_CONSULTING_SERVICES && opp.NSP_Client_For_Life__c != NSP_SalesConstants.WO_WS){
                           if(opp.SBQQ__PrimaryQuote__c != null){
                               if(quoteMap.get(opp.SBQQ__PrimaryQuote__c).SBQQ__Status__c != NSP_SalesConstants.APPROVAL_STATUS_APPROVED ){
                                   opp.addError(System.Label.NSP_Approve_Primary_Quote);
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
                           }
                       }else{
                           if(!test.isRunningTest()){
                               opp.addError(System.Label.NSP_AddPrimaryQuote);
                           }
                       } 
                   }
               }
            
        }catch(Exception ex){
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
    public static void evaluateClosedWonStageCriteria(Opportunity opp){
        if(ownerBasedCriteriaProducts.contains(opp.NSP_PrimaryProduct__c) 
           && (opp.NSP_Opportunity_Owner_Role__c == NSP_SalesConstants.BPC_USER || opp.NSP_Opportunity_Owner_Role__c == NSP_SalesConstants.BPA_USER)
           && opp.NSP_Opportunity_Owner_Role__c != NSP_SalesConstants.NEW_CLIENT_SALES){
               opp.AddError(System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON);
           }else if(opp.NSP_Opportunity_Owner_Role__c != NSP_SalesConstants.NEW_CLIENT_SALES && (opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO || opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WS)){
               opp.AddError(System.Label.NSP_CANNOT_MOVE_TO_CLOSEDWON);
           }
        
    }
    
    
}