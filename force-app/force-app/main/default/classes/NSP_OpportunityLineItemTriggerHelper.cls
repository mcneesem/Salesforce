public class NSP_OpportunityLineItemTriggerHelper {
    /**
* Iterates throught the oli map and identifies the records that needs to worked based on various criterias.
* @param oliNewMap Map of New OpportunityLineItem. 
* @param oliOldMap Map of Old OpportunityLineItem. 
* @return void             
*                
*/    
    public void beforeInsertDirector(List<OpportunityLineItem> oliNewList){
        
    
    }
    
    /*
     * iterates through oli map and identifies records with WO or WS products
     * to roll up WO, WS margin and Has WO, WS products checkbox on opportunity record
*/
    
    public void afterInsertDirector(List<OpportunityLineItem> oliNewList) {
        rollupMarginsOnOpportunity(oliNewList);        
    }
    
    /**
* Iterates throught the OpportunityLineItem map and identifies the records that needs to worked based on various criterias.
* @param oliNewMap Map of New OpportunityLineItem. 
* @param oliOldMap Map of Old OpportunityLineItem. 
* @return void             
*                
*/
    public void beforeUpdateDirector(Map<Id, OpportunityLineItem> oliNewMap,Map<Id, OpportunityLineItem> oliOldMap){
             
    }
    
    /**
* Iterates throught the OpportunityLineItem map and identifies the records that needs to worked based on various criterias.
* @param oliNewMap Map of New OpportunityLineItem. 
* @param oliOldMap Map of Old OpportunityLineItem. 
* @return void             
*                
*/
    public void afterUpdateDirector(Map<Id, OpportunityLineItem> oliNewMap,Map<Id, OpportunityLineItem> oliOldMap){
        
         List<OpportunityLineItem> marginsModifiedOlisList = new List<OpportunityLineItem>();
        
        
        for(OpportunityLineItem newOli : oliNewMap.values()){
                if(newOli.NSP_Margin__c != oliOldMap.get(newOli.Id).NSP_Margin__c
               || newOli.Quantity != oliOldMap.get(newOli.Id).Quantity){
                   marginsModifiedOlisList.add(newOli);
               }
            
        }
        
               if(! marginsModifiedOlisList.isEmpty()){
            rollupMarginsOnOpportunity(oliNewMap.values());             
        }  
    }
    
    
    
    /*
     * method used to rollup margins and quantity on its
     * parent opportunity record.
     * @params: list of OpportunityLineItems
     * @return: void
*/
    public static void rollupMarginsOnOpportunity(List<OpportunityLineItem> oliNewList){
        Set<Id> opportunityIdSet = new Set<Id>();
        for(OpportunityLineItem oliRecord : oliNewList){
            opportunityIdSet.add(oliRecord.OpportunityId);
        }
        List<Opportunity> opportunityList = new List<opportunity>();
               
        if(! opportunityIdSet.isEmpty()){
            opportunityList = [SELECT Id, NSP_WS_Margin__c, NSP_WO_Margin__c, NSP_WS_Number_of_Employees__c, 
                               NSP_WO_Number_of_Employees__c, NSP_Has_WS_Products__c, NSP_Has_WO_Products__c,
                               (SELECT Quantity, Name, NSP_Margin__c, NSP_Reserve__c FROM OpportunityLineItems)
                               FROM Opportunity WHERE Id IN :opportunityIdSet];
            for(Opportunity opportunityRecord : opportunityList){
                decimal oliWOMargin = 0;
                decimal oliWSMargin = 0;
                decimal opptyWOEmployees = 0;
                decimal opptyWSEmployees = 0;
                decimal oliWOReserve = 0;
                decimal oliWSReserve = 0;
                for(opportunityLineItem oliRecord : opportunityRecord.OpportunityLineItems){                    
                    if(oliRecord.Name.contains('Workforce Optimization')){
                        opportunityRecord.NSP_Has_WO_Products__c = true;
                        oliWOMargin = oliWOMargin + (oliRecord.NSP_Margin__c == null ? 0 : oliRecord.NSP_Margin__c);
                        opptyWOEmployees = opptyWOEmployees + (oliRecord.Quantity == null ? 0 : oliRecord.Quantity);
                        oliWOReserve = oliRecord.NSP_Reserve__c;
                    } else if(oliRecord.Name.contains('Workforce Syncronization')){
                        opportunityRecord.NSP_Has_WS_Products__c = true;
                        oliWSMargin = oliWSMargin + (oliRecord.NSP_Margin__c == null ? 0 : oliRecord.NSP_Margin__c);
                        opptyWSEmployees = opptyWSEmployees + (oliRecord.Quantity == null ? 0 : oliRecord.Quantity);
                        oliWSReserve = oliRecord.NSP_Reserve__c;
                    }
                }                
                opportunityRecord.NSP_WO_Number_of_Employees__c = opptyWOEmployees;
                opportunityRecord.NSP_WS_Number_of_Employees__c = opptyWSEmployees;
                opportunityRecord.NSP_WO_Margin__c = oliWOMargin;
                opportunityRecord.NSP_WS_Margin__c = oliWSMargin;
                opportunityRecord.NSP_WO_Reserve__c = oliWOReserve;
                opportunityRecord.NSP_WS_Reserve__c = oliWSReserve;  
                
            }
            
            update opportunityList;
        }
    }
    
}