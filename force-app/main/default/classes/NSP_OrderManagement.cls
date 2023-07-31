/**************************************************************************************************   
Apex Controller Name :  NSP_OrderManagement
Version              :  1.0                                                                          
Created Date         :  AUG 2,2021                                                       
Function             :  This class is called from 'NSP_OrderManagement' component for Order Management functionality .
Story                :                                                                            
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  

* Utpal Utkalit            AUG 2,2021               First Iteration
***************************************************************************************************/


public class NSP_OrderManagement {
    
@AuraEnabled
	public static List<Contract> getContractRecord(Id recordId){
        try{
           List<Contract> contractList= [SELECT Id,Status,ContractNumber,NSP_Product_Type__c, SBQQ__Evergreen__c,StartDate,EndDate,Account.Name FROM Contract WHERE AccountId=:recordId AND Status='Activated' LIMIT 50000]; //AND Status='Activated // Added Limit condition as part of code fix
           return contractList;
        }catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
     }
    
    
    @AuraEnabled
    public static User getCurrentUserInfo(){
        try{
            return [SELECT Id,Name,	Profile.Name FROM User WHERE Id =: Userinfo.getUserId()]; 
        }catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        }    
    
    @AuraEnabled
    public static Boolean updateContract(Id contractId, String transactionType){
        Boolean isContractUpdated;
        try {
             //update contract record as per renewals and amendments
            Contract contract= new Contract (Id = contractId);
            contract.NSP_TransactionType__c=transactionType;
            contract.SBQQ__PreserveBundleStructureUponRenewals__c = true;
            //DML on Contract
            update contract;
            isContractUpdated = true;
        }
        catch (Exception ex) {
            isContractUpdated = false;
             // "Convert" the exception into an AuraHandledException
            throw new AuraHandledException(ex.getMessage());
        }
        return isContractUpdated;
    }
    
}