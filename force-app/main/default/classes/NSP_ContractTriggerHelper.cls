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
        
        setRequiredFieldsOnInsert(newList,false);
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
    setFieldsOnContract(contractNewMap.values(), contractOldMap);
    setRequiredFieldsOnInsert(contractNewMap.values(),true);
    
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
    public void setRequiredFieldsOnInsert(List<Contract> newContractList,Boolean isUpdate){ 
        Set<String> quoteids = new Set<String>();
        //Set<String> opptyIds = new Set<String>();

        for ( Contract con : newContractList){
            if((isUpdate && con.NSP_Product_Type__c == null) || !isUpdate ) {
                if(con.SBQQ__Quote__c!=null) {
                    quoteids.add(con.SBQQ__Quote__c);
                }
             }            
        }
        // querying quote and oppty fields
        if(quoteids.size() > 0){
            Map<Id, SBQQ__Quote__c> conQuotes = new Map<Id,SBQQ__Quote__c>([Select Id, Name, NSP_Pricing_Model__c, NSP_Product_Type__c, SBQQ__PricebookId__c, SBQQ__Opportunity2__r.NSP_Number_of_Employees__c,NSP_Opportunity_Primary_Product__c, SBQQ__Opportunity2__c  
                                            FROM SBQQ__Quote__c WHERE ID IN:quoteids ]);
            for ( Contract con : newContractList){ 
                if(con.SBQQ__Quote__c!=null && con.NSP_Created_From_Contract_Id__c==null && con.NSP_Contract_External_ID__c==null) {
                    SBQQ__Quote__c cquote = conQuotes.get(con.SBQQ__Quote__c);

                    con.NSP_Number_of_Employees__c = cquote.SBQQ__Opportunity2__c !=null ? cquote.SBQQ__Opportunity2__r.NSP_Number_of_Employees__c : 1;
                    con.NSP_Pricing_Model__c = cquote.NSP_Pricing_Model__c;
                    con.NSP_Product_Type__c = cquote.NSP_Product_Type__c;
                    con.Pricebook2Id = cquote.SBQQ__PricebookId__c;
                    con.SBQQ__AmendmentPricebookId__c = cquote.SBQQ__PricebookId__c;
                    con.SBQQ__RenewalPricebookId__c = cquote.SBQQ__PricebookId__c;
                    con.SBQQ__RenewalOpportunityStage__c = NSP_CPQConstants.PROPOSAL;
                    con.SBQQ__AmendmentOpportunityStage__c = NSP_CPQConstants.PROPOSAL;
                    con.NSP_PrimaryProduct__c = cquote.NSP_Opportunity_Primary_Product__c;
                } 
            }
        }
    }      
    
    /**
    * Method Name : setFieldsOnContract 
    * Description : Method to set  fields on Contract update
    * Author : Rakesh Das       Date : 26/01/2023
    * @param newContractList List of New Contract. 
    * @return void  
    */ 
    
    public void setFieldsOnContract(List<Contract> newContractList,Map<id,Contract> triggerOldMap)
    {
        for(Contract newContract :newContractList)
        {
            Contract oldContract = triggerOldMap != null ? triggerOldMap.get(newContract.Id):null;
            
            if((newContract.SBQQ__RenewalForecast__c != oldContract.SBQQ__RenewalForecast__c || 
                newContract.SBQQ__RenewalQuoted__c  != oldContract.SBQQ__RenewalQuoted__c ) &&
              String.isNotBlank(oldContract.NSP_Product_Type__c) && oldContract.NSP_Product_Type__c == 'Time and Attendance Hardware')
            {
                newContract.SBQQ__PreserveBundleStructureUponRenewals__c = false;
            }
        }
    }


}