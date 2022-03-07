/**
* Represents Batch class which sets account stage as per the oppty stage related to that account.
*/
global class NSP_SetAccountStageBatch implements Database.Batchable<Sobject>,Database.Stateful{
    /**
* Represents start method of the Batch Interface.Fetches all the opty's that are created or editted in last 4 hours
* @param Database.BatchableContext bc.
* @return Database.QueryLocator
*
*/
        
    //remove upselling from query
    global Database.QueryLocator start(Database.BatchableContext bc){
        //Calculating time 
       DateTime dtNow = System.Now().addHours(-4);
        
        //Setting the date format so that it can be queried
        String timeStamp = String.valueOfGmt(dtNow).replace(' ','T')+'.000+0000';
        //Dynamic query to fetch opprtunities created or editted in last 4 hours
        String query = 'SELECT id,account.NSP_Account_Status__c,Account.NSP_Stage__c,stagename,accountid FROM OPPORTUNITY'+
            ' WHERE account.NSP_Stage__c !='+'\''+'Upselling'+'\''+' AND account.NSP_Account_Status__c='+'\''+'Active'+'\''
            +' AND lastmodifieddate >=' +timeStamp;
        
        
        // passing the opportunity list to the execute method
        return Database.getQueryLocator(query);
    }
    
    /**
* Represents execute method of the Batch Interface.The main logic is here.
* @param Database.BatchableContext bc
* @param List<Opportunity> scope
* @return N/A
*
*/
    global void execute(Database.BatchableContext bc,List<Opportunity> scope){
       
        //List to store all opportunities for all account that would fall in scope
        List<Opportunity> allOptyForAccounts = new  List<Opportunity>();
        // Set to store account id that are on opportunity
        Set<String> accountidSet = new Set<String>();
        //Map to hold account id and list of opportunities associated to that account
        Map<String,List<Opportunity>> accountOptyMap = new Map<String,List<Opportunity>>();
        //map to store account id and would be stage value
        Map<String,String> accountMap = new Map<String,String>();
        
       
        // Iterating over the opprtunities identified and fetching the account realted to it
        for(Opportunity optyObject : scope){
            //Adding account ids to the accountidSet
            accountidSet.add(optyObject.accountid);
        }    
        
        //Get all the opportunities realted to the account id's in the accountidSet
        allOptyForAccounts = [SELECT id,account.NSP_Account_Status__c,Account.NSP_Stage__c,stagename,accountid FROM OPPORTUNITY WHERE accountid in :accountidSet LIMIT 50000];
        
        // Iterating over all the opportunities realted to the accounts in the accountidSet
        for(Opportunity optyObject : allOptyForAccounts){
            //Checking if account id is already present in the Map
            if(accountOptyMap.containsKey(optyObject.accountid)){
                //Adding account id as key and opputunity object to the list
                accountOptyMap.get(optyObject.accountid).add(optyObject);
            }else{
                //Temporary list to hold opportunity object so that it can be added to the Map
                List<Opportunity> optyList = new List<Opportunity>();
                //adding opportunity object to the list
                optyList.add(optyObject);
                //Adding account id as key and opportunity list
                accountOptyMap.put(optyObject.accountid,optyList);
            }
        }
        
        //Iterating over all the account present in accountOptyMap
        for(String accntid : accountOptyMap.keySet()){
            Boolean isOpen = false; // to identify whether the opportunity is open or not
            Boolean isWon = false; // to identify whether the opportunity is closed won or not
            
            //Getting all the opprtunities related to an account and iterating over them
            for(Opportunity obj : accountOptyMap.get(accntid)){
                // Checking if the opprtunity is open or Closed
                if(String.isNotBlank(obj.account.NSP_Account_Status__c) && 
                   obj.stageName.equals(NSP_SalesConstants.CLOSED_WON) && obj.account.NSP_Account_Status__c.equals(NSP_SalesConstants.ACTIVE)){
                       
                       isWon = true;
                   }
                if(String.isNotBlank(obj.account.NSP_Account_Status__c) &&
                   !obj.stageName.equals(NSP_SalesConstants.CLOSED_WON) && obj.account.NSP_Account_Status__c.equals(NSP_SalesConstants.ACTIVE)){
                       isOpen = true;
                   }
            }
         
            //calling the method to determine the correct stage for account based on the opportunity stages
            determineAccountStage(accountMap,isOpen,isWon,accntid);
        }
        //Method to update the account with the stage values identified
        setAccountStage(accountMap);    
            
       
        
    }
    
    /**
* Represents Finish method of the Batch Interface.
* @param Database.BatchableContext bc
* @return N/A
*/
    public void finish(Database.BatchableContext bc){
        
    }
    /**
* Determines the account stage based on the stages of the opportunitys related to that account.
* @param Map of account id and would be account stage
* @param Boolen fields to determine whether the opportunity is open or not
* @param Boolen fields to determine whether the opportunity is closed won or not
* @param string that contains the accountid
* @return N/A
*/
    public void determineAccountStage (Map<String,String> accountMap,Boolean isOpen,Boolean isWon,String accntid){
        //if all opportunity is open set the stage to Prospecting
        if(isOpen){
            accountMap.put(accntid,NSP_SalesConstants.PROSPECTING);
        }
        //if one or more opportunity is won and no opportunites are open set the stage to Sold
        if(isWon){
            accountMap.put(accntid,NSP_SalesConstants.SOLD);
        }
        //if one or some opportunities are won and some opprtunities are open set stage to Upselling
        if(isOpen && isWon){
            accountMap.put(accntid,NSP_SalesConstants.UPSELLING);
        }
        
       
        
    }
    
    /**
* Updates the account record with their respective stages identified.
* @param Map of account id and would be account stage
* @return N/A
*/
    public void setAccountStage (Map<String,String> accountMap){
        List<Account> accountList = new List<Account>();
        //Get all the account records based on the account id's in accountMap
        for(Account acc : [Select id,NSP_Stage__c,NSP_Account_Status__c from account WHERE id in : accountMap.keyset() and NSP_Account_Status__c = :NSP_SalesConstants.ACTIVE]){
            
            if(String.isNotBlank(acc.NSP_Stage__c) && 
               (!acc.NSP_Stage__c.equalsIgnoreCase(NSP_SalesConstants.STR_NEW) && !acc.NSP_Stage__c.equalsIgnoreCase(NSP_SalesConstants.AVAILABLE))){
                   //Setting the account Stage   
                   if(!acc.NSP_Stage__c.equals(accountMap.get(acc.id))){
                       acc.NSP_Stage__c = accountMap.get(acc.id);
                       accountList.add(acc);
                   }
                   
               }
            
        }
        // Updating the accounts
        if(!accountList.isEmpty()){
            Database.SaveResult[] result = Database.Update(accountList, false);
            NSP_ErrorLogHandler.logSaveResult('NSP_SetAccountStageBatch','setAccountStage',result);
        }
        
        
    }
    
    
}