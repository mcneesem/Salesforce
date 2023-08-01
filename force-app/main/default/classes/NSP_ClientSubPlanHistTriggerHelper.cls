/**
* Represents the Client Sub Plan History trigger helper which handles all the logic.
* Version - STY           - DESCRIPTION                                      - TAG

* V1.0    - STY-02660     - RET - Automation - Client Subplan History - 	 - <STY-02660>
							Linked Asset(s) Field Updates 					 
*/

    public class NSP_ClientSubPlanHistTriggerHelper {
    
/***********************************************************************************************
* MethodName: beforeInsertDirector
* Description : Iterates throught the list of new Client Sub Plan History Records and passes the Asset Ids and Client Sub Plan History to other methods.
* Params:       List <NSP_Client_Sub_Plan_History__c> newList
* ********************************************************************************************/  

    public void beforeInsertDirector(List<NSP_Client_Sub_Plan_History__c> newList){
        Set<Id> assetIdSet = new Set<Id>();
        for(NSP_Client_Sub_Plan_History__c clnSubPlnHis : newList){
            if(clnSubPlnHis.NSP_Start_Date__c <= date.today() &&
               (clnSubPlnHis.NSP_End_Date__c == null || clnSubPlnHis.NSP_End_Date__c > date.today()) &&
               String.isNotBlank(clnSubPlnHis.NSP_Asset__c)){
                   assetIdSet.add(clnSubPlnHis.NSP_Asset__c);
               }
        }
        if(!assetIdSet.isEmpty()){
            checkCurrentSubPlan(assetIdSet, newList);
        } 
    }
    
/***********************************************************************************************
* MethodName: checkCurrentSubPlan
* Description : Check the current subplan checkbox on Client Sub Plan History Record if it matches the criteria mentioned in the story.
* Params:       Set<Id> assetIdSet and List <NSP_Client_Sub_Plan_History__c> clientSubPlanHistRecList
* ********************************************************************************************/  
    
    public void checkCurrentSubPlan(Set<Id> assetIdSet, List<NSP_Client_Sub_Plan_History__c> clientSubPlanHistRecList){
        //Map of Asset and Client Sub Plan History Recs which has current subplan checked
        Map<Id, NSP_Client_Sub_Plan_History__c> assetCheckedCurrentSubPlanMap = new Map<Id, NSP_Client_Sub_Plan_History__c>();
        List<NSP_Client_Sub_Plan_History__c> checkedCurrentSubPlanHistRecList = new List<NSP_Client_Sub_Plan_History__c>();
        try{
        
        //Iterate through the list of Client Sub Plan History Records whose current subplan checkbox is true and has an asset in assetIdSet
        for(NSP_Client_Sub_Plan_History__c checkedCurrentSubPlan : [SELECT Id, NSP_Start_Date__c, NSP_Asset__c
                                                                    FROM NSP_Client_Sub_Plan_History__c
                                                                    WHERE NSP_Asset__c IN: assetIdSet
                                                                    AND NSP_Current_Subplan__c = true]){
                                                                        assetCheckedCurrentSubPlanMap.put(checkedCurrentSubPlan.NSP_Asset__c, checkedCurrentSubPlan);
                                                                    }
        //Mark the current subplan checkbox to true for most recently created client subplan history record
        for(NSP_Client_Sub_Plan_History__c clientSubPlanHistRec : clientSubPlanHistRecList){
            if(!assetCheckedCurrentSubPlanMap.isEmpty()){
                if(clientSubPlanHistRec.NSP_Start_Date__c <= date.today()
                   && (clientSubPlanHistRec.NSP_End_Date__c == null || clientSubPlanHistRec.NSP_End_Date__c > date.today()) 
                   && String.isNotBlank(clientSubPlanHistRec.NSP_Asset__c)){
                    assetCheckedCurrentSubPlanMap.get(clientSubPlanHistRec.NSP_Asset__c).NSP_Current_Subplan__c = false;
                    clientSubPlanHistRec.NSP_Current_Subplan__c = true;
                    checkedCurrentSubPlanHistRecList.add(assetCheckedCurrentSubPlanMap.get(clientSubPlanHistRec.NSP_Asset__c));
                }  
            }
            else{
                clientSubPlanHistRec.NSP_Current_Subplan__c = true;
            }
        }
        if(!checkedCurrentSubPlanHistRecList.isEmpty()){
            Database.update(checkedCurrentSubPlanHistRecList);
        	}
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_ClientSubPlnHisTrgHelper', 'checkCurrentSubPlan', ex.getMessage());
        }
    }
}