/**
Apex Class Name      :  NSP_ShowContractExceptionsController
Version              :  1.0                                                                          
Created Date         :  6/1/2022   
Function             :  NSP_ShowContractExceptionsController
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Nishkarsh                    07/02/2022           First Iteration
* Harsha                       13/03/2022           Update to return service exceptions from all related accounts
*/
public with sharing class NSP_ShowContractExceptionsController {
    public NSP_ShowContractExceptionsController() {

    }
    
    @AuraEnabled(Cacheable=true)
    public static List<NSP_Service_Exception__c> getExceptionList(Id contactId) {
        Set<Id> accountIdSet = new Set<Id>();
        try{
            for(AccountContactRelation acr : [SELECT Id, AccountId
            FROM AccountContactRelation 
            WHERE ContactId=: contactId]){
                accountIdSet.add(acr.AccountId);
            }
            return [SELECT Id, Name, NSP_Account__r.Name , NSP_Account__r.NSP_AIMS_Client__c, NSP_Exception_Notes__c, CreatedBy.Name, LastModifiedBy.Name, CreatedDate, LastModifiedDate,
            NSP_Start_Date__c, NSP_End_Date__c FROM NSP_Service_Exception__c WHERE NSP_Account__c IN :accountIdSet]; 
        }catch(Exception Ex){
            throw new AuraHandledException('ErrorOccured' + ex.getMessage());
        }
    }
    
    @AuraEnabled(Cacheable=true)
    public static List<NSP_Service_Exception__c> getExceptionListFromContact(Id conId) {
        try{
    	Id accId = [SELECT Id, AccountId FROM Contact WHERE Id =: conId].AccountId;
        return getExceptionList(accId); 
           }catch(Exception Ex){
           throw new AuraHandledException('ErrorOccured' + ex.getMessage());           
        }
    }
}