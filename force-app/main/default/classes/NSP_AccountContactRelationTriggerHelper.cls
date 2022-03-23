/* Represents the AccountContactRelation trigger helper which handles all the logic.
* 
* Modification History:
* -------------------------------------------------------------------------------------
* author           | Date              | Description
* -------------------------------------------------------------------------------------
* Hemali Patel     Iterates through AccountContactRelation
* 
* 
*/
public class NSP_AccountContactRelationTriggerHelper {
	
    /**
     * Iterates throught the list of new AccountContactRelation and passes the required attributes to other methods.
     * @param newList List of New AccountContactRelation.
     * @param newMap List of New AccountContactRelation.
     * @return void
     *                
     */

    public void afterInsertDirector(List<AccountContactRelation> newList, Map<Id, AccountContactRelation> newMap) {
        try{
            Set<Id> accountIdSet = new Set<Id>();
            for(AccountContactRelation accConObj : newList){
                if(accConObj.NSP_Is_Primary__c && accConObj.IsActive){
                    accountIdSet.add(accConObj.AccountId);
                }
            }
            
            if(accountIdSet.size() > 0){
                List<Account> accountList = new List<Account>();
                for(ID accountId : accountIdSet){
                    Account accountObj = new Account();
                    accountObj.Id = accountId;
                    accountObj.NSP_Ready_for_Integration_Sync__c = true;
                    accountList.add(accountObj);
                }
                
                if(accountList.size() > 0){
                    update accountList;
                }
            }
            
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }
    
    /**
     * Iterates throught the list of new AccountContactRelation and passes the required attributes to other methods.
     * @param newList List of New AccountContactRelation.
     * @param newMap List of New AccountContactRelation.
     * @return void
     *                
     */

    public void afterUpdateDirector(Map<Id, AccountContactRelation> newMap,Map<Id, AccountContactRelation> oldMap) {
        try{
            Map<Id,AccountContactRelation> contactOldMap = new Map<Id,AccountContactRelation>();
            Map<Id,AccountContactRelation> contactNewMap = new Map<Id,AccountContactRelation>();
            Set<Id> accountIdSet = new Set<Id>();
            
            for(AccountContactRelation conObj : newMap.values()){ 
                if((conObj.NSP_Is_Primary__c && oldMap.get(conObj.Id).NSP_Is_Primary__c != conObj.NSP_Is_Primary__c) || 
                    (conObj.IsActive && oldMap.get(conObj.Id).IsActive != conObj.IsActive)
                  ){
                    accountIdSet.add(conObj.AccountId);
                    contactOldMap.put(conObj.Id,oldMap.get(conObj.Id));
                    contactNewMap.put(conObj.Id,newMap.get(conObj.Id));
                }
            }
            
            Set<Id> accountIdSetToUpdateResyncFLag = new Set<Id>();
            NSP_SObjectUpdateTriggerHelper sObjectUpdateObj = new NSP_SObjectUpdateTriggerHelper();
            accountIdSetToUpdateResyncFLag = sObjectUpdateObj.fetchUpdFieldsLst(NSP_IntegrationConstants.SOBJECT_ACCOUNTCONTACTRELATION, contactNewMap, contactOldMap);
            
            if(accountIdSetToUpdateResyncFLag.size() > 0){
                List<Account> accountList = new List<Account>();
                for(Id accountId : accountIdSetToUpdateResyncFLag){
                    Account accountObj = new Account();
                    accountObj.Id = accountId;
                    accountObj.NSP_Ready_for_Integration_Sync__c = true;
                    accountList.add(accountObj);
                }
                
                if(accountList.size() > 0){
                    update accountList;
                }
            }
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        } 
    }
    /***********************************************************************************************
    * MethodName: beforeUpsertDirector
    * Description : This method will add the validation to not to create more than One ACR for an Account 
    * Params:       List<AccountContactRelation> newList
    *Author : Nischay Jindal
    * ********************************************************************************************/   
	public static void beforeUpsertDirector(List<AccountContactRelation> newList) {
        try{
            Set<Id> contactIdSet = new Set<Id>();
            Set<Id> accountIdSet = new Set<Id>();
            for(AccountContactRelation accConObj : newList){
                if(accConObj.NSP_Is_Primary__c){
                    contactIdSet.add(accConObj.ContactId);
                    accountIdSet.add(accConObj.AccountId);
                }
            }
            Map<Id,AccountContactRelation> accountContactMap= new Map<Id,AccountContactRelation>([Select Id ,ContactId ,NSP_Is_Primary__c, AccountId from AccountContactRelation
                                                                                                    WHERE (ContactId IN:contactIdSet OR AccountId IN:accountIdSet) AND NSP_Is_Primary__c = True ]);
            for(AccountContactRelation accConObj : newList){
                if(accountContactMap.size() > 0 && !accountContactMap.containsKey(accConObj.Id) ){
                    accConObj.NSP_Is_Primary__c.addError(System.label.NSP_PrimaryContactValidation);
                }
            }
            }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_AccountContactRelationTriggerHelper','beforeUpsertDirector',ex.getMessage()); 
        }
     }
}