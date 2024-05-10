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
    // test w/ NSP_OrderManagementTest (86%)

    @AuraEnabled
    public static List<Contract> getContractRecord(Id recordId){
        try{
            list<contract> lstTermContract = new list<contract>();
            List<Contract> contractList = [
                SELECT
                    Id, Status, ContractNumber, NSP_Product_Type__c,
                    SBQQ__Evergreen__c, StartDate, EndDate, Account.Name,
                    SBQQ__Order__c, SBQQ__Order__r.NSP_Transaction_Type__c,
                    (SELECT Id, NSP_Status__c FROM SBQQ__Subscriptions__r)
                FROM Contract
                WHERE (
                    ( AccountId = :recordId )
                    AND ( Status = 'Activated' )
                )
                LIMIT 50000
            ]; // Added Limit condition as part of code fix
            for (Contract cnt:contractList) {
                Boolean isTerminated = false;
                if(string.isNotBlank(cnt.SBQQ__Order__c)
                    && (cnt.SBQQ__Order__r.NSP_Transaction_Type__c == 'Termination')
                    )
                {
                    isTerminated = true;
                } else if (cnt.SBQQ__Subscriptions__r != null) {
                    isTerminated = true;
                    for (SBQQ__Subscription__c sub:cnt.SBQQ__Subscriptions__r) {                       
                        if (sub.NSP_Status__c != 'Terminated') {
                            isTerminated = false;
                            break;
                        }
                    }
                }
                if (isTerminated == false) {
                    lstTermContract.add(cnt);
                }
            }
            return lstTermContract;
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