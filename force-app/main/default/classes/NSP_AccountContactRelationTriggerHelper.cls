/* Represents the AccountContactRelation trigger helper which handles all the logic.
* 
* Modification History:
* -------------------------------------------------------------------------------------
* author           | Date              | Description
* -------------------------------------------------------------------------------------
* Hemali Patel     Iterates through AccountContactRelation
* Rahul Singh       10/26/2022          Create Contact Role
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
            
            createContactRole(newList,newMap);
            
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
            
            createContactRole(newMap.values(),oldMap);
            
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
            Set<Id> accountIdSet = new Set<Id>();
            for(AccountContactRelation accConObj : newList){
                if(accConObj.NSP_Is_Primary__c){
                    accountIdSet.add(accConObj.AccountId);
                }
            }
            Map<Id,AccountContactRelation> accountContactRelationMap= new Map<Id,AccountContactRelation>([Select Id ,ContactId ,NSP_Is_Primary__c, AccountId from AccountContactRelation WHERE AccountId IN:accountIdSet AND NSP_Is_Primary__c = True ]);
            for(AccountContactRelation accConObj : newList){
                if(accountContactRelationMap.size() > 0 && !accountContactRelationMap.containsKey(accConObj.Id)  ){
                         accConObj.NSP_Is_Primary__c.addError(System.label.NSP_PrimaryContactValidation);
                }
            }
            }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_AccountContactRelationTriggerHelper','beforeUpsertDirector',ex.getMessage()); 
        }
     }
    
 /***********************************************************************************************
    * MethodName: createContactRole
    * Description : This method will create OCR
    * Params:       List<AccountContactRelation> newList,Map<Id, AccountContactRelation> oldMap
    * Author : Rahul Singh
	* Created Date:10/26/22
	* Created as part of User story - 128223
    * ********************************************************************************************/   
    
   
      public void createContactRole(List<AccountContactRelation> newList,Map<Id, AccountContactRelation> oldMap)
    {
        map<Id,Id> accAndCon = new map<Id,Id>();
        map<Id,Id> oppAndAcc = new map<Id,Id>();
        map<id,AccountContactRelation> acrMap = new map<id,AccountContactRelation>();
        map<id,OpportunityContactRole> ocrMap = new map<id,OpportunityContactRole>();
        list<OpportunityContactRole> ocrInsertList = new list<OpportunityContactRole>();
        list<OpportunityContactRole> ocrUpdateList = new list<OpportunityContactRole>(); 
        for(AccountContactRelation newAcr: newList)
        {
           AccountContactRelation oldAcr = oldMap != null ? oldMap.get(newAcr.Id):null;
            if((Trigger.isInsert&& newAcr.AccountId != null && newAcr.NSP_Is_Primary__c == TRUE) ||(Trigger.isUpdate && newAcr.NSP_Is_Primary__c != oldAcr.NSP_Is_Primary__c)  ) 
            {
               
                acrMap.put(newAcr.AccountId,newAcr);
                
            }
            
            
        }
        if(acrMap.Size() >0)
        {   
        
         for(Opportunity oppList: [Select Id, AccountId from opportunity where AccountId in : acrMap.keyset()])
        {
           oppAndAcc.put(oppList.Id,oppList.AccountId);
        }
        }
        
        if(oppAndAcc.Size() > 0)
        {   
         for(OpportunityContactRole eachOCR : [SELECT Id, OpportunityId, ContactId
                                               FROM OpportunityContactRole WHERE opportunityId in : oppAndAcc.keySet()])
            {
              
                if (eachOCR.ContactId == acrMap.get(oppAndAcc.get(eachOCR.OpportunityId)).ContactId )
                {
                  ocrMap.put(eachOCR.OpportunityId,eachOCR);   
                 
                }

            }
        }
        
        if(oppAndAcc.Size() > 0 && acrMap.Size() >0 ){
        for(id oppId : oppAndAcc.keySet() ){
            
            if(ocrMap.keySet().contains(oppId)){
               OpportunityContactRole eachOcrList =  ocrMap.get(oppId);
               AccountContactRelation eachACRList = acrMap.get(oppAndAcc.get(oppId));
               OpportunityContactRole newOcrToUpdate = new OpportunityContactRole();
                 newOcrToUpdate.Id = eachOcrList.Id;
                 newOcrToUpdate.IsPrimary = eachACRList.NSP_Is_Primary__c;
                 ocrUpdateList.add(newOcrToUpdate);
            }
            else {
                 OpportunityContactRole newOcr = new OpportunityContactRole();
                 AccountContactRelation eachACRList = acrMap.get(oppAndAcc.get(oppId));
                 newOcr.OpportunityId = oppId;
                 newOcr.ContactId = eachACRList.ContactId;
                 newOcr.IsPrimary = eachACRList.NSP_Is_Primary__c;
                 newOcr.CurrencyIsoCode = eachACRList.CurrencyIsoCode;
                 newOcr.NSP_Nonprofit_Organization_Name__c = eachACRList.NSP_Nonprofit_Organization_Name__c;
                 newOcr.NSP_Nonprofit_Organization_Tax_Id__c = eachACRList.NSP_Nonprofit_Organization_Tax_Id__c;
                 newOcr.NSP_Referralbenefitsanonprofitorg__c = eachACRList.NSP_Referralbenefitsanonprofitorg__c;
                 newOcr.NSP_isReferral__c = eachACRList.NSP_isReferral__c;
                 ocrInsertList.add(newOcr);
                 
            }
            
            
        }
        }
        
        try{
		if((ocrInsertList.Size() > 0 || ocrUpdateList.Size() >0))
                
        {  
            update ocrUpdateList;
            insert ocrInsertList;
            
                
        }            
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        } 


    }
}