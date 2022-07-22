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
        
        // Commenting out this code. Please refer to the latest comments on DF-01750
        // Validation on Opportunity Product is no longer required.
        /* Set<Id> opportunityIdSet = new Set<Id>();
        for(OpportunityLineItem oliRecord : oliNewMap.values()){
            opportunityIdSet.add(oliRecord.OpportunityId);
        }
        Map<Id,Opportunity> opportunityDetailsMap = new Map<Id,Opportunity>([Select Id, Name, StageName,NSP_PrimaryProduct__c,SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.ApprovalStatus__c from Opportunity where Id IN : opportunityIdSet ]);
        List<String> opptyProductsToSkip = new List<String>{'WO','WS'};
        Set<String> profilesToSkip = new Set<String>(System.label.NSP_Profile_To_Skip_OLI_Validation.split(','));
        
        Id userprofileId=userinfo.getProfileId();
        String userprofileName=[SELECT Id,Name FROM Profile WHERE Id=:userprofileId].Name;
        
        for(OpportunityLineItem newOli : oliNewMap.values()){
            if(opportunityDetailsMap.containsKey(newOli.OpportunityId)) {
                Opportunity oppParentRec = opportunityDetailsMap.get(newOli.OpportunityId);
                if(oppParentRec.SBQQ__PrimaryQuote__r.ApprovalStatus__c == 'Approved') {
             //   if((oppParentRec.StageName =='Closed Won' || oppParentRec.StageName =='Closed Lost') ||
             //       (oppParentRec.StageName !='Closed Won' && oppParentRec.StageName !='Closed Lost' && oppParentRec.SBQQ__PrimaryQuote__r.ApprovalStatus__c == 'Approved')) {
                    
                    if(!profilesToSkip.contains(userprofileName)) {
                            OpportunityLineItem oldOliRec = oliOldMap.get(newOli.Id);
                        if(newOli.ServiceDate != oldOliRec.ServiceDate || newOli.Product2Id != oldOliRec.Product2Id ||  newOli.UnitPrice != oldOliRec.UnitPrice || newOli.OpportunityId != oldOliRec.OpportunityId
                            || newOli.Quantity != oldOliRec.Quantity || newOli.Description != oldOliRec.Description || newOli.NSP_Status__c != oldOliRec.NSP_Status__c
                            || newOli.sbaa__ApprovalStatus__c != oldOliRec.sbaa__ApprovalStatus__c || newOli.NSP_Margin__c != oldOliRec.NSP_Margin__c || newOli.NSP_Reserve__c != oldOliRec.NSP_Reserve__c ) {
                                
                                newOli.addError(System.Label.Opportunity_Product_Update_Error_Message);							
                        }
                    }
                }  
            }   
        } */
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