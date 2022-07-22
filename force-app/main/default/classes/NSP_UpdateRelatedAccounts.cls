/*
 * @Description: This class is created to update nsp_last_updated__c on Account When ever Opportunity is updated. And this is running in without sharing 
 * 				 context because while creating quote, Sales Engineering will not have access to Account. So to update nsp_last_updated__c on Account, this 
 * 				 class is running in Without Sharing Context and is referred in NSP_OpportunityTriggerHelper class
 * @CreatedDate: 1/25/2022
 * @Story/Defect: DF-01058
 * */  
public without sharing class NSP_UpdateRelatedAccounts { 
    
    /**
* Updates the last updated date on the related accounts(this helps in identifying the account that can be set as inactive).
* @param accountIdSet Set of account ids related to opportunity.    
* @return void             
*                
*/  
    public static void updateRelatedAccounts(Set<String> accountIdSet){
        //List of accounts to be updated
        List<Account> accountTobeUpdatedList = new List<Account>();
        //Iterating over the account set to get the account records
        for(Account accountObj : [SELECT id,nsp_last_updated__c FROM account WHERE id in :accountIdSet]){
            //Stamping last updated date on the account records
            accountObj.nsp_last_updated__c = date.today();
            //adding account records to the list
            accountTobeUpdatedList.add(accountObj);
        }
        
        //Updating the accounts
        if(!accountTobeUpdatedList.isEmpty()){
            try{
             update accountTobeUpdatedList; 
            }catch(exception ex){
                NSP_CustomException.LogException(ex);
            }
        }
                
    }
}