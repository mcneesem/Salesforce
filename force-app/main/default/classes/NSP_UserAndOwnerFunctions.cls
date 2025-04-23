public with sharing class NSP_UserAndOwnerFunctions {
    // test w/ NSP_UserAndOwnerFunctionsTest (89%)

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
    public void setDummyUsers( List<Opportunity> setOpptyTemplateIdList , Set<String> accountIdSet , Set<Id> ownerIdset ) {
        //get custom metadata for docusign template mapping
        try{
            Map < Id, String > accountContactMap = new Map < Id, String > ();
        	for ( AccountContactRelation accountObj : [
                        SELECT
                            Id ,
                            ContactId ,
                            NSP_Is_Primary__c, 
                            AccountId ,
                            Account.Owner.Email
                        FROM AccountContactRelation
                        WHERE (
                            ( NSP_Is_Primary__c = true )
                            AND ( AccountId IN: accountIdSet )
                        )
                    ]
                )
            {
            	accountContactMap.put(accountObj.AccountId,accountObj.ContactId );
        	}
            Map<Id, User> mapUserObject = new Map<Id, User>([SELECT Id,UserRole.Name,Manager.Id, Manager.Manager.Id FROM User WHERE Id IN :ownerIdset]);

            for( Opportunity opportuntityObj : setOpptyTemplateIdList ){
                // if Opportunity owner is BPA
                // set BPA as owner or set as dummy user -- UPDATE: Dummy User retired; just leave NSP_BPA__c unassigned
                if( ( opportuntityObj.NSP_BPA__c == null )
                   && ( NSP_UserAndOwnerFunctions.templSelectUpdPermittedUserMap.keySet().contains( opportuntityObj.OwnerId ) ) ){
                        opportuntityObj.NSP_BPA__c = opportuntityObj.OwnerId;
                        opportuntityObj.NSP_DM_User__c = mapUserObject.get(opportuntityObj.OwnerId).ManagerID;
                        opportuntityObj.NSP_DA_User__c = mapUserObject.get(opportuntityObj.OwnerId).Manager.ManagerID;
                }
                if( accountContactMap.containsKey(opportuntityObj.AccountId) ){
                    if( accountContactMap.get(opportuntityObj.AccountId) != null ){
                        opportuntityObj.NSP_Primary_Contact__c = accountContactMap.get(opportuntityObj.AccountId);
                    } else {
                        opportuntityObj.adderror(SELECT_PRIMARY_CONTACT);
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_UserAndOwnerFunctions.class.getName() ,
                'setDummyUsers' ,
                e
            );
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
    
    private static Map<Id,User> templSelectUpdPermittedUserMap {
        private get {
            if ( templSelectUpdPermittedUserMap == null ) {
                templSelectUpdPermittedUserMap = CustomPermissionController.getPermittedUsersMap( 'Template_Selection_Owner_Update' );
            }
            return templSelectUpdPermittedUserMap;
        }
        private set;
    }
}
//