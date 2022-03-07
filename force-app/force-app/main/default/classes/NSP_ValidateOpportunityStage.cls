
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
    
    public static void validateOpportunityStage(List<Opportunity> newList){
        List<Id> oppIdList= new List<Id>();
        for(Opportunity opp:newList){
            oppIdList.add(opp.Id);
		}
        
        Map<ID, Opportunity> oppMapwithEventTask = new Map<ID, Opportunity>([SELECT AccountId,Id,
                                                                             (SELECT Id,Status, NSP_Task_Subtype__c FROM Tasks WHERE NSP_Task_Subtype__c != NULL),
                                                                             (SELECT Id, NSP_Event_Subtype__c,NSP_Status__c FROM Events WHERE NSP_Event_Subtype__c   != NULL) 
                                                                             FROM Opportunity Where Id IN :oppIdList]);
        
        
        for(Opportunity opp:newList){        
            Opportunity oppFromMap=oppMapwithEventTask.get(opp.Id);
            List<Task> taskList=oppFromMap?.Tasks;
            List<Event> eventList=oppFromMap?.Events;
            
            
            if(analysisStageCriteraTypes.contains(opp.Type)){
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
            }
            /////Proposal 
            if(proposeStageCriteraTypes.contains(opp.Type)){
                if(opp.StageName.equals(NSP_SalesConstants.PROPOSAL_STAGE)){
                    
                    //Modified: Primary Quote required only for Non WO opptys, hence moved Primary Quote validation to else if block
                    //Perform WO
                    if(opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO){
                        
                        String scannedTask='';
                        if(taskList != null){
                            for(Task task:taskList){//looking for WO Profile
                                if(task.NSP_Task_Subtype__c == NSP_SalesConstants.WO_BUSINESS_PROFILE){
                                    scannedTask +=' has WO Task ';
                                }
                            }
                        }
                        if(eventList != null){
                            for(Event event:eventList){////looking for discovery
                                if(event.NSP_Event_Subtype__c == NSP_SalesConstants.WO_BUSINESS_PROFILE){
                                    scannedTask +=' has WO Event ';
                                }
                            }
                        }                    
                        
                        //Show error
                        if(!scannedTask.contains('has WO') ){
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
            }
            
            if(opp.StageName.equals(NSP_SalesConstants.CLOSING_STAGE)){
         //STY-01878 Code start
                if(opp.NSP_Executive_Summary_Generated__c==TRUE){
                    if(opp.NSP_PrimaryProduct__c==NSP_SalesConstants.WO){
                        if(opp.NSP_Docusign_Sent_Date__c == null || ! opp.NSP_Closing_Appointment__c){
                            //check if either docusign date or closing appointment event is scheduled, else throw error
                            opp.addError(System.Label.NSP_WO_Closing_Appointment_or_Docusign);
                        }
                    } 
                    if(opp.NSP_PrimaryProduct__c!=NSP_SalesConstants.WO && opp.NSP_Order_Generated__c==TRUE	){
                        if(opp.NSP_Docusign_Sent_Date__c == null || !opp.NSP_Closing_Appointment__c){
                            opp.addError(System.Label.NSP_WO_Closing_Appointment_or_Docusign);  
                        }
                        
                    }
                }
                //STY-01878 Code End
            }
        }								
    }
}