public with sharing class NSP_ContractTriggerHelper {
    public NSP_ContractTriggerHelper() {

    }


 
    /**
* Iterates throught the list of new contracts and passes the required attributes to other methods.
* @param newList List of New contracts.  
* @return void             
*                
*/
    public void beforeInsertDirector(List<Contract> newList){        
        
     setRequiredFieldsOnInsert(newList);
 }

    /**
* Iterates throught the list of new contracts and passes the required attributes to other methods.
* @param newList List of New contracts.  
* @return void             
*                
*/
public void afterInsertDirector(List<Contract> newList){        
        

}

/**
* Iterates throught the Quote map and identifies the records that needs to worked based on various criterias.
* @param contractNewMap Map of New Quote. 
* @param contractOldMap Map of Old Quote. 
* @return void             
*                
*/
    
public void beforeUpdateDirector(Map<Id, Contract> contractNewMap,Map<Id, Contract> contractOldMap){

    
}   


/**
* Iterates throught the list of new contracts and passes the required attributes to other methods.
* @param contractNewMap Map of New Quote. 
* @param contractOldMap Map of Old Quote.   
* @return void             
*                
*/
    
public void afterUpdateDirector(Map<Id,Contract> contractNewMap,Map<Id, Contract> contractOldMap){        
        
  

}  


    /**
    * Method Name : setRequiredFieldsOnInsert 
    * Description : Method to set required fields on Contract Insert
    * Author : Rakesh Das       Date : 03/11/2021
    * @param newContractList List of New Contract. 
    * @return void  
    */ 
    public void setRequiredFieldsOnInsert(List<Contract> newContractList){ 
        Set<String> quoteids = new Set<String>();
        Set<String> opptyIds = new Set<String>();

        for ( Contract con : newContractList){

            if(con.SBQQ__Quote__c!=null) {
                quoteids.add(con.SBQQ__Quote__c);
            }
            if(con.SBQQ__Opportunity__c!=null) {
                opptyIds.add(con.SBQQ__Opportunity__c);
            }

        }

        Map<Id, SBQQ__Quote__c> conQuotes = new Map<Id,SBQQ__Quote__c>([Select Id, Name, NSP_Pricing_Model__c, NSP_Product_Type__c, SBQQ__PricebookId__c, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.NSP_Number_of_Employees__c,SBQQ__Opportunity2__r.NSP_PrimaryProduct__c  
                                            FROM SBQQ__Quote__c WHERE ID IN:quoteids ]);

        for ( Contract con : newContractList){ 
            if(con.SBQQ__Quote__c!=null && con.NSP_Created_From_Contract_Id__c==null) {
                SBQQ__Quote__c cquote = conQuotes.get(con.SBQQ__Quote__c);

                con.NSP_Number_of_Employees__c = cquote.SBQQ__Opportunity2__r.NSP_Number_of_Employees__c;
                con.NSP_Pricing_Model__c = cquote.NSP_Pricing_Model__c;
                con.NSP_Product_Type__c = cquote.NSP_Product_Type__c;
                con.Pricebook2Id = cquote.SBQQ__PricebookId__c;
                con.SBQQ__AmendmentPricebookId__c = cquote.SBQQ__PricebookId__c;
                con.SBQQ__RenewalPricebookId__c = cquote.SBQQ__PricebookId__c;
                con.SBQQ__RenewalOpportunityStage__c = NSP_CPQConstants.PROPOSAL;
                con.SBQQ__AmendmentOpportunityStage__c = NSP_CPQConstants.PROPOSAL;
                con.NSP_PrimaryProduct__c = cquote.SBQQ__Opportunity2__r.NSP_PrimaryProduct__c;
                //add primary product from oppty
            } 
        }

    }


}