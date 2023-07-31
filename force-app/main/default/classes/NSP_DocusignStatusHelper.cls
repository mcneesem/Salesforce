/**
Apex Class Name      :  NSP_DocusignStatusHelper
Version              :  1.0                                                                          
Created Date         :  01/24/2023
Author               :  Virendra Kumar
Function             :  Represents the Docusign Status helper which handles all the logic.
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Virendra Kumar               01/24/2023           First Iteration
*/
public class NSP_DocusignStatusHelper {
    
     /**
        * Iterates throught the list of new Docusign Status
        * Method Name: updateplatformevent
        * @param newList List of New Docusign Status.  
        * @return void
        *                
     */
    private NSP_DocusignStatusHelper(){}
    public static void updatePlatformEvent(List<dfsle__EnvelopeStatus__c> newList, map<Id, dfsle__EnvelopeStatus__c> oldMap){
        List<NSP_Docusign_Status_Event__e> docusignList = new List<NSP_Docusign_Status_Event__e>();        
        //List<NSP_Error_Log__c> logList = new List<NSP_Error_Log__c>();
        Set<Id> opportunitySet = new Set <Id>();
        Map<Id, NSP_Enrollment_Fee_Payment__c> oppIdByEnrollment = new Map<Id, NSP_Enrollment_Fee_Payment__c>();        
        //Check if the Status is Completed and collect the opportunity
        for(dfsle__EnvelopeStatus__c docusignStatus : newList){
            if(docusignStatus.dfsle__Status__c	== Label.NSP_Docusign_Status_Completed && (oldMap == null  || (oldMap != null && (docusignStatus.dfsle__Status__c != oldMap.get(docusignStatus.Id).dfsle__Status__c || 
                                                                                      docusignStatus.DS_Opportunity__c != oldMap.get(docusignStatus.Id).DS_Opportunity__c ||
                                                                                      docusignStatus.dfsle__DocuSignId__c != oldMap.get(docusignStatus.Id).dfsle__DocuSignId__c)))){
                opportunitySet.add(docusignStatus.DS_Opportunity__c);
            }
        }
        
        if(!opportunitySet.isEmpty()) {
            //Build Opportunity Map
            Map<Id, Opportunity> oppIdByOpp = new Map<Id, Opportunity>([SELECT Id, AccountId, Account.NSP_AIMS_Client__c,NSP_PrimaryProduct__c FROM Opportunity WHERE Id =:opportunitySet ]);
            
            //Build Enrollment Fee Payment Map to have key as opportunity Id
            for(NSP_Enrollment_Fee_Payment__c enrollmentFee : [SELECT Id, NSP_Opportunity__c, NSP_Opportunity__r.Account.NSP_AIMS_Client__c From NSP_Enrollment_Fee_Payment__c WHERE NSP_Opportunity__c =:opportunitySet ORDER BY CreatedDate ASC ]){
                oppIdByEnrollment.put(enrollmentFee.NSP_Opportunity__c, enrollmentFee);
            }
            
            for(dfsle__EnvelopeStatus__c docusignStatus : newList){
                
                NSP_Docusign_Status_Event__e  docusignEventToBeCreated = New NSP_Docusign_Status_Event__e();
                //Update AIMS Client if it is not null
                if(oppIdByOpp.containsKey(docusignStatus.DS_Opportunity__c) && oppIdByOpp.get(docusignStatus.DS_Opportunity__c).AccountId != null && oppIdByOpp.get(docusignStatus.DS_Opportunity__c).Account.NSP_AIMS_Client__c != null) {
                    docusignEventToBeCreated.NSP_AIMS_Client__c = oppIdByOpp.get(docusignStatus.DS_Opportunity__c).Account.NSP_AIMS_Client__c;
                }
                if(oppIdByEnrollment.containsKey(docusignStatus.DS_Opportunity__c) ) {
                    docusignEventToBeCreated.NSP_Enrollment_Fee_ID__c = oppIdByEnrollment.get(docusignStatus.DS_Opportunity__c).Id;
                    
                    if(oppIdByOpp.get(docusignStatus.DS_Opportunity__c).NSP_PrimaryProduct__c != null){
                        docusignEventToBeCreated.NSP_Primary_Product__c = oppIdByOpp.get(docusignStatus.DS_Opportunity__c).NSP_PrimaryProduct__c;
                    }
                }
                
                docusignEventToBeCreated.NSP_Opportunity_ID__c = docusignStatus.DS_Opportunity__c;
                docusignEventToBeCreated.NSP_Docusign_Envelope_ID__c = docusignStatus.dfsle__DocuSignId__c; 
                docusignList.add(docusignEventToBeCreated);
                
        	}
        }
        
        if(!docusignList.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(docusignList);
            // Inspect publishing result for each event
            NSP_ErrorLogHandler.logSaveResult('DocusignStatusHelper', 'updatePlatformEvent', results);
        }
        
    } 
}