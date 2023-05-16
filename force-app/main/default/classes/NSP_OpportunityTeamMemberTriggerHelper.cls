/**
 * Represents the OpportunityTeamMember trigger helper which handles all the logic.
 */

public class NSP_OpportunityTeamMemberTriggerHelper {
		
    /**
     * Iterates throught the list of new OpportunityTeamMember and passes the required attributes to other methods.
     * @param newList List of New OpportunityTeamMember.
     * @return void
     *                
     */

    public void afterInsertDirector(List<OpportunityTeamMember> newList, Map<Id, OpportunityTeamMember> newMap) {
        try{
            Set<Id> oppIdSet = new Set<Id>();
            
            for(OpportunityTeamMember oppTeamMemberObj : newList) {
                if(oppTeamMemberObj.TeamMemberRole == NSP_IntegrationConstants.BPAROLE || oppTeamMemberObj.TeamMemberRole == NSP_IntegrationConstants.BPCROLE){
                	oppIdSet.add(oppTeamMemberObj.OpportunityId);
                }
            }
             
            if(oppIdSet.size() > 0){
                List<Opportunity> oppList = new List<Opportunity>();
                for(ID oppId : oppIdSet){
                    Opportunity oppObj = new Opportunity();
                    oppObj.Id = oppId; 
                    oppObj.NSP_Ready_for_Integration_Sync__c = true;
                    oppList.add(oppObj);
                }
                
                if(oppList.size() > 0){
                    update oppList;
                }
            }
            NSP_EnrollmentFeePaymentSharing.onOppTeamMemberInsert(newList);
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }
    
    
    /**
     * Iterates throught the list of new OpportunityTeamMember and passes the required attributes to other methods.
     * @param newMap Map of OpportunityTeamMember.
     * @param oldMap Map of OpportunityTeamMember.
     * @return void
     *                
     */

    public void afterUpdateDirector(Map<Id, OpportunityTeamMember> newMap,Map<Id, OpportunityTeamMember> oldMap) {
        try{
            Map<Id, OpportunityTeamMember> newOpptyMap = new Map<Id, OpportunityTeamMember>();
            Map<Id, OpportunityTeamMember> oldOpptyMap = new Map<Id, OpportunityTeamMember>();
            for(OpportunityTeamMember opptyTeamMemberObj : newMap.values()){
                if(opptyTeamMemberObj.TeamMemberRole !=  oldMap.get(opptyTeamMemberObj.Id).TeamMemberRole && 
                   (opptyTeamMemberObj.TeamMemberRole == NSP_IntegrationConstants.BPAROLE || opptyTeamMemberObj.TeamMemberRole == NSP_IntegrationConstants.BPCROLE )){
                    newOpptyMap.put(opptyTeamMemberObj.Id,opptyTeamMemberObj);
                    oldOpptyMap.put(opptyTeamMemberObj.Id,oldMap.get(opptyTeamMemberObj.Id));
                }
            } 
            
            Set<Id> opptyIdSetToUpdateResyncFLag = new Set<Id>();
            NSP_SObjectUpdateTriggerHelper sObjectUpdateObj = new NSP_SObjectUpdateTriggerHelper();
            opptyIdSetToUpdateResyncFLag.addAll(sObjectUpdateObj.fetchUpdFieldsLst(NSP_IntegrationConstants.SOBJECT_OPPORTUNITYTEAMMEMBER, (Map<Id, sObject>) newOpptyMap, (Map<Id, sObject>) oldOpptyMap));
            
            if(opptyIdSetToUpdateResyncFLag.size() > 0){
                List<Opportunity> updateOppList = new List<Opportunity>();
                for(Id opptyId : opptyIdSetToUpdateResyncFLag){
                    Opportunity oppObj = new Opportunity();	
                    oppObj.NSP_Ready_for_Integration_Sync__c = true;
                    oppObj.Id = opptyId; 
                    updateOppList.add(oppObj);
                }
                if(updateOppList.size() > 0){
                    update updateOppList;
                }
            }
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }
    
    public void afterDeleteDirector(List<OpportunityTeamMember> oldList,Map<Id, OpportunityTeamMember> oldMap) {
        try{
            NSP_EnrollmentFeePaymentSharing.onOppTeamMemberDelete(oldList);
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }
}