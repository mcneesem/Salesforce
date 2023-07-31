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

/**
* Update Account status to 'Prospecting' once opportunity is added and there are no assets
* @param accountIdSet Set of account ids related to opportunity.    
* @return void             
*                
*/  
    public static void updateAccountStatus(Set<String> accountIdSet){
        List<Account> accountTobeUpdatedList = new List<Account>();
        //Iterating over the account set to get the account records
        for(Account accountObj : [SELECT Id , NSP_Sales_Service_Account_Status__c, (SELECT Id FROM Assets),
        (SELECT ID, StageName FROM Opportunities where StageName NOT IN('Closed Won', 'Closed Lost'))
        FROM Account WHERE Id IN :accountIdSet]){
            if(accountObj.Assets.size()== 0){
                accountObj.NSP_Sales_Service_Account_Status__c = NSP_SalesConstants.PROSPECTING;
                accountTobeUpdatedList.add(accountObj);
            }
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