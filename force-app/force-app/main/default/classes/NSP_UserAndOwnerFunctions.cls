public class NSP_UserAndOwnerFunctions {

    public static final String SELECT_PRIMARY_CONTACT = System.Label.NSP_Select_Primary_Contact;

/*
* Description: This method sets signer to dummy user if they are blank, customer signer to accoun't primary contact
* BPA to opportunity owner if role is BPA
* @param: setOpptyTemplateIdList , accountIdSet, ownerIdset
* @return: void
* Modification History:
* -------------------------------------------------------------------------------------
* author           | Date              | Description
* -------------------------------------------------------------------------------------
* Harsha         	12/22/2021         	created this new method
* 
* 
*/
    public void setDummyUsers(List<Opportunity> setOpptyTemplateIdList,Set<String> accountIdSet,Set<Id> ownerIdset){
        //get custom metadata for docusign template mapping
        
        try{
            Map<Id, Account> mapAccountObject = new Map<Id, Account>([SELECT Id,Name,owner.email,NSP_Primary_Contact__c FROM Account WHERE id IN : accountIdSet]);
            Map<Id, User> mapUserObject = new Map<Id, User>([SELECT Id,UserRole.Name,Manager.Id, Manager.Manager.Id FROM User WHERE Id IN :ownerIdset]);
            
            List<User> dummyUser = [select Id FROM User WHERE Name = :NSP_SalesConstants.DUMMY_USER_SIGNER LIMIT 1];
            for(Opportunity opportuntityObj : setOpptyTemplateIdList){
                if(opportuntityObj.NSP_BPA__c == null ){
                    if(opportuntityObj.NSP_Opportunity_Owner_Role__c == NSP_SalesConstants.BPA_User){
                        opportuntityObj.NSP_BPA__c = opportuntityObj.OwnerId;
                        opportuntityObj.NSP_DM_User__c = mapUserObject.get(opportuntityObj.OwnerId).ManagerID;
                        opportuntityObj.NSP_DA_User__c = mapUserObject.get(opportuntityObj.OwnerId).Manager.ManagerID;
                    }else{
                        opportuntityObj.NSP_BPA__c = dummyUser[0].Id;
                        opportuntityObj.NSP_DM_User__c = dummyUser[0].Id;
                        opportuntityObj.NSP_DA_User__c =  dummyUser[0].Id;
                    }
                }
                if(opportuntityObj.NSP_Insperity_Signer__c == null){
                    opportuntityObj.NSP_Insperity_Signer__c = dummyUser[0].Id;
                }
                if(opportuntityObj.Legals_Counter_Signer__c == null){
                    opportuntityObj.Legals_Counter_Signer__c = dummyUser[0].Id;
                }
                if(mapAccountObject.containsKey(opportuntityObj.AccountId) && !test.isRunningTest()){  
                    if(mapAccountObject.get(opportuntityObj.AccountId).NSP_Primary_Contact__c != null){
                        opportuntityObj.NSP_Primary_Contact__c = mapAccountObject.get(opportuntityObj.AccountId).NSP_Primary_Contact__c;
                        
                    }else{
                        opportuntityObj.adderror(SELECT_PRIMARY_CONTACT);
                    }              
                }  
            }
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }  
    }
	
	
	/**
* Stamps quote owner on the oportunity record
* @param opportunityList lsit of New Opportunity.    
* @param Primary quote Id.   
* @return void             
*                
*/    
    public void getQuoteOwner(List<Opportunity> opportunityList, Id primaryQuote){
        //Map of account id and account object
        Map<Id,SBQQ__Quote__c> mapQuoteObject = new Map<Id,SBQQ__Quote__c>();
        
        
        //Iterating over the account ids in the set and getting the email of the account owner
        // and adding it to the map
        for(SBQQ__Quote__c quote : [SELECT Id,OwnerId FROM SBQQ__Quote__c WHERE id =: primaryQuote]){
            
            mapQuoteObject.put(quote.id,quote);
        }
        
        
        //Iterating over the optys and stamping account owner email
        for(Opportunity opportunityObject : opportunityList){ 
            if(mapQuoteObject.containsKey(opportunityObject.SBQQ__PrimaryQuote__c)){                
                opportunityObject.NSP_Quote_Owner__c = mapQuoteObject.get(opportunityObject.SBQQ__PrimaryQuote__c).OwnerId;
            }            
        }
    }
    

	
    
}