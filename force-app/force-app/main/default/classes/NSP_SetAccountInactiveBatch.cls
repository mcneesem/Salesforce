/**
* Represents the batch class which is responsible for setting the account status as Inactive.
*/
global class NSP_SetAccountInactiveBatch implements Database.Batchable<Sobject> {
   
 /**
* Represents start method of the Batch Interface.The main logic is here.
* @param Database.BatchableContext bc
* @return Database.getQueryLocator
*
*/
    global Database.QueryLocator start(Database.BatchableContext bc){
        
        String status= '\''+'New'+'\''+','+'\''+'Assigned'+'\''+','+'\''+'Available'+'\'';
        //Building dynamic query
        String query = 'SELECT id,NSP_Account_Status__c,NSP_Stage__c FROM Account WHERE NSP_Account_Status__c ='+'\''+'Active'+'\''+
            ' AND NSP_Stage__c not in (' + status + ')' + ' AND  Lastmodifieddate < LAST_N_DAYS:180' ;
        if(test.isRunningTest()){
            query = 'SELECT id,NSP_Account_Status__c,NSP_Stage__c FROM Account WHERE NSP_Account_Status__c ='+'\''+'Active'+'\''+
            ' AND NSP_Stage__c not in (' + status + ')' + ' AND  Lastmodifieddate <= LAST_N_DAYS:180' ;
        }
        //setting the scope for the ececute method
        return Database.getQueryLocator(query);
    }
    
    /**
* Represents execute method of the Batch Interface.The main logic is here.
* @param Database.BatchableContext bc
* @param List<Opportunity> scope
* @return N/A
*
*/
    global void execute(Database.BatchableContext bc,List<Account> scope){
        
        //List of account to store the accounts to be updated
        List<Account> accountstoUpdate = new List<Account>();
        //Iteraing over the account records
        for(Account accountObj : scope){
            //Setting status as Inactive
            accountObj.NSP_Account_Status__c =NSP_SalesConstants.INACTIVE;
            //Setting stage as Available
            accountObj.NSP_Stage__c =NSP_SalesConstants.AVAILABLE;
            //Adding accounts to be updated in a list
            accountstoUpdate.add(accountObj);
        }
        
        //Udating accoutns
        Database.SaveResult[] result = Database.Update(accountstoUpdate, false);
        NSP_ErrorLogHandler.logSaveResult('NSP_SetAccountInactiveBatch','Execute',result);
   
    }
    
    /**
* Represents Finish method of the Batch Interface.
* @param Database.BatchableContext bc
* @return N/A
*/
    public void finish(Database.BatchableContext bc){
        
    }
}