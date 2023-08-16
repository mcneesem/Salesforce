/**
Apex Class Name      :  NSP_OpportunityTriggerHelperFunctions for Opportunity Trigger Helper
Version              :  1.0                                                                          
Created Date         :  07/02/2021   
Function             :  This class is used as a helper to Opportunity Trigger Handler. 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Rakesh                 	07/02/2021            First Iteration
*/
public class NSP_OpportunityTriggerHelperFunctions {
    // test w/ NSP_OpportunityTriggerHelperTest,NSP_AccountTriggerHelperTest (88%)

    public NSP_OpportunityTriggerHelperFunctions() {

    }

    /**
     * Stamps email of the account owner on the oportunity record
     * @param opportunityList lsit of New Opportunity.    
     * @param accountIdSet set of account ids.   
     * @return void             
     *                
     */
    public void setDirectOpptyFieldsAssignments(List < Opportunity > opportunityList) {
        List < Pricebook2 > priceBookList = [SELECT id, name FROM pricebook2 WHERE name =: NSP_SalesConstants.NON_CPQ_PRICEBOOK];
		
        for (Opportunity opportunityObject: opportunityList) {
            //stamping Mid-Market sales team email on opportunity record
            opportunityObject.NSP_Mid_Market_Sales_Email__c = Label.NSP_Mid_Market_Sales_Email; //'midmarketleads@insperity.com'
            //stamping new client sales email on opportunity record.
            //DF-01858
            //opportunityObject.NSP_New_Client_Sales_Email__c = Label.NSP_New_Client_Sales_Email;
             /*Added if condition as part of DF-01369 */
            
            if(opportunityObject.NSP_Account_Name__c != null){
            String accountName = opportunityObject.NSP_Account_Name__c;
        	Integer accountNameLength = accountName.length();
            String trimmedAccountName;
            if(trigger.isBefore && trigger.isInsert){
                if(accountNameLength > 97) {
                    trimmedAccountName = accountName.left(94) + '...';
                }
                else{
                    trimmedAccountName = accountName;
                }
                opportunityObject.Name = trimmedAccountName + ' - ' + DateTime.now().format();
            
            }
            }
            //STY-01818 - Setting Client for Life
            opportunityObject.NSP_Client_For_Life__c = setClientForLifeOnOppty(opportunityObject.NSP_Client_For_Life__c, opportunityObject.NSP_PrimaryProduct__c);
            /*DF-01858-Start -NCS Notification trigger based on primary product & owner role*/
            if(opportunityObject.NSP_Opportunity_Owner_Role__c!=NULL && opportunityObject.NSP_PrimaryProduct__c!=NULL){
                if(!opportunityObject.NSP_Opportunity_Owner_Role__c.contains(System.label.NSP_CustomerSuccessTeam_And_BPSAdministrator_Role) && opportunityObject.NSP_PrimaryProduct__c.contains(System.label.NSP_Workforce_Primary_Product)){
                    //stamping new client sales email on opportunity record.
                    opportunityObject.NSP_New_Client_Sales_Email__c = Label.NSP_New_Client_Sales_Email;
                }else if(!opportunityObject.NSP_Opportunity_Owner_Role__c.contains(System.label.NSP_CustomerSuccessTeam_And_BPSAdministrator_Role) && opportunityObject.NSP_PrimaryProduct__c.contains(System.label.NSP_OtherthanWorkforce_Primary_Product)){
                    opportunityObject.NSP_New_Client_Sales_Email__c = Label.NSP_Salepprwk_Email;    
                }else if(opportunityObject.NSP_Opportunity_Owner_Role__c.contains(System.label.NSP_Core_And_MidMarket_Hierarchy_Role) && opportunityObject.NSP_PrimaryProduct__c.contains(System.label.NSP_Other_Primary_Product)){
                    opportunityObject.NSP_New_Client_Sales_Email__c = Label.NSP_Salepprwk_Email;     
                }
            }
            /*DF-01858-End*/
            //If backout fields are not blank checking backout check box to true
            if (opportunityObject.NSP_BackOutDate__c != null && String.isnotBlank(opportunityObject.NSP_BackOutReason__c) && String.isnotBlank(opportunityObject.NSP_BackOutRequestor__c)) {
                opportunityObject.NSP_Back_Out__c = TRUE;
            }
            // update ready to sync to true whenever opportunity is cloned 
            // added as a part of DF-01145
            if (opportunityObject.isClone()) {
                opportunityObject.NSP_Ready_for_Integration_Sync__c = true;
            }
           
            //When Opportunity has primary product as WO then price is set to WO price book
            if (String.isNotBlank(opportunityObject.NSP_PrimaryProduct__c) && 'WO'.equals(opportunityObject.NSP_PrimaryProduct__c)) {
                if (priceBookList.size() > 0) {
                    opportunityObject.Pricebook2id = priceBookList[0].id;
                }
            }
        }
    }

    /**
     * Method to check conditions and return client for life
     * @param opptyCfl String for client for life    
     * @param opptyPrimaryProduct String for opportunity primary product   
     * @return void             
     *                
     */

    public static String setClientForLifeOnOppty(String opptyCfl, String opptyPrimaryProduct) {

        if (String.isnotBlank(opptyPrimaryProduct)) {
            if ((opptyPrimaryProduct.equals(NSP_SalesConstants.WO) || opptyPrimaryProduct.equals(NSP_SalesConstants.WS))) {
                opptyCfl = NSP_CPQConstants.CLIENT_WOWS;
            }
            if (opptyCfl != NSP_CPQConstants.CLIENT_WOWS) {
                if (opptyPrimaryProduct.equals(NSP_SalesConstants.WX)) {
                    opptyCfl = NSP_SalesConstants.WX;
                }
                if (opptyPrimaryProduct.equals(NSP_SalesConstants.WA)) {
                    opptyCfl = NSP_SalesConstants.WA;
                }
            }
        }

        return opptyCfl;
    }


    /**
     * Stamps email of the account owner on the oportunity record
     * @param opportunityList lsit of New Opportunity.    
     * @param accountIdSet set of account ids.   
     * @return void             
     *                
     */
    public void getAccountOwnerEmail(List < Opportunity > opportunityList, Set < String > accountIdSet) {
        //Map of account Id and Account object
        //  Modified by Nischay as a part of STY-02090 
         Map < Id, String > accountContactMap = new Map < Id, String > ();
         //Map of account Id and Contact Id
         for (AccountContactRelation accountObj: [Select Id , ContactId ,NSP_Is_Primary__c, AccountId, Account.Owner.Email from AccountContactRelation WHERE NSP_Is_Primary__c =true AND AccountId IN: accountIdSet]) {
                 accountContactMap.put(accountObj.AccountId,accountObj.ContactId );
             }
         
         //Iterating over the optys and stamping account owner email
         for (Opportunity opportunityObject: opportunityList) {
             if ( accountContactMap.containsKey(opportunityObject.AccountId) ) {
                 opportunityObject.NSP_Primary_Contact__c = accountContactMap.get(opportunityObject.AccountId);
                 opportunityObject.NSP_Customer_Signer__c = accountContactMap.get(opportunityObject.AccountId);
             }
         }
    }

    /**
     * Stamps the WO/WX emails on the Opportunity record depending on the product type selected
     * @param opportunityList lsit of New Opportunity.    
     * @param accountIdSet set of account ids.   
     * @return void             
     *                
     */
    public void stampWoWxEmailOnOpprtunity(List < Opportunity > opportunityList) {
        for (Opportunity opportunityObject: opportunityList) {
            //if product type is WO on opportunity the WO email DL
            if (opportunityObject.NSP_PrimaryProduct__c.equals(NSP_SalesConstants.WO) || opportunityObject.NSP_PrimaryProduct__c.equals(NSP_SalesConstants.WS)) {
                opportunityObject.NSP_WO_WX_Results__c = Label.NSP_WO_Email_DL; //'results@insperity.com';
                //if product type is WX on opportunity the WX email DL
            } else if (opportunityObject.NSP_PrimaryProduct__c.equals(NSP_SalesConstants.WX) || opportunityObject.NSP_PrimaryProduct__c.equals(NSP_SalesConstants.WA)) {
                opportunityObject.NSP_WO_WX_Results__c = Label.NSP_WX_Email_DL; //'WXresults@insperity.com';
            }
        }

    }



    /*
     * Description: This method takes all the opportunities where
     * the Opportunity Owner is changed and populates Engage Service Team email field
     * based on the Opportunity owner's sales office
     * @param: newOpportunityList, userIdSet 
     * @return: void
     * Modification History:
     * -------------------------------------------------------------------------------------
     * author           | Date              | Description
     * -------------------------------------------------------------------------------------
     * Tejas          	10/28/2021         	created this new method
     * 
     * 
     */
    public static void populateServiceEmail(List < Opportunity > newOpportunityList, Set < Id > userIdSet) {
        List < NSP_Service_Team_Office_Mapping__mdt > officeEmailsMappingList = [SELECT Id, NSP_Sales_Offices__c, NSP_Service_Team_Email__c
            FROM NSP_Service_Team_Office_Mapping__mdt WHERE NSP_Service_Team_Email__c != NULL
        ];
        //592123 - adde ToLabel in Query - Harsha
        Map < Id, User > usersMap = new Map < Id, User > ([SELECT Id, ToLabel(NSP_Sales_Office__c) FROM User WHERE Id IN: userIdSet]);

        for (Opportunity opportunityRecord: newOpportunityList) {
            for (NSP_Service_Team_Office_Mapping__mdt officeMapppingRecord: officeEmailsMappingList) {
                List < String > officeGroup = officeMapppingRecord.NSP_Sales_Offices__c.split('\\r?\\n|\\r');
                if (String.isNotBlank(usersMap.get(opportunityRecord.OwnerId).NSP_Sales_Office__c) &&
                    officeGroup.contains(usersMap.get(opportunityRecord.OwnerId).NSP_Sales_Office__c)) {
                    opportunityRecord.NSP_Service_Team_Email__c = officeMapppingRecord.NSP_Service_Team_Email__c;
                    break;
                }
            }
        }

    }

    /***********************************************************************************************
    * MethodName: getAccountOwnerEmail
    * Description : This method will update the Point of Contact and Customer Signer on Opportunity after Insert
    * Params:       Set<Id> accountId
    * Author : Nischay Jindal
    * ********************************************************************************************/
  
public static void getAccountOwnerEmail(Set<Id> accountId) {
    //  Added by Nischay as a part of STY-02090 
    Map<Id,Id> accountOpportunityMap = new Map<Id,Id>();
    List<Opportunity>opportunityList =[Select Id , Name,NSP_Customer_Signer__c ,NSP_Primary_Contact__c,AccountId from Opportunity WHERE AccountId IN:accountId];
     for(Opportunity opp:opportunityList){
         accountOpportunityMap.put(opp.AccountId,opp.Id);
     }
     Map < Id, String > accountContactMap = new Map < Id, String > ();
    for (AccountContactRelation accountObj: [Select Id , ContactId ,NSP_Is_Primary__c, AccountId, Account.Owner.Email from AccountContactRelation WHERE NSP_Is_Primary__c =true AND AccountId IN: accountId]) {
        accountContactMap.put(accountObj.AccountId,accountObj.ContactId );
    }
    List<Opportunity> UpdateOpplist = new List<Opportunity>();
    //Iterating over the optys and stamping account owner email
    for (Opportunity opportunityObject: opportunityList) {
        if (accountContactMap.containsKey(opportunityObject.AccountId)) {
            Opportunity opp = new opportunity();
            opp.Id=opportunityObject.Id;
            opp.NSP_Primary_Contact__c = accountContactMap.get(opportunityObject.AccountId);
            opp.NSP_Customer_Signer__c = accountContactMap.get(opportunityObject.AccountId);
            UpdateOpplist.add(opp);
        }
    }  
     if(!UpdateOpplist.isEmpty()){
         Database.update(UpdateOpplist,false);  
        }
    }
    
    /***********************************************************************************************
    * MethodName: updateOppOwnerPremier
    * Description : This method will update publish event for premier pathway opportunity owner update
    * Params:       newMap, oldMap
    * Author : Rahul Singh
    * Created Date : 9/29/22
    * Added as part of 569324 charwell request.
    * ********************************************************************************************/  
    
    public static void updateOppOwnerPremier(Map<Id, Account> newMap, Map<Id, Account> oldMap) {

        set<Id> accountIdSet = new set<Id>();
        for(Account newAccount: newMap.values()){
        Account oldAccount = oldMap != null ? oldMap.get(newAccount.Id):null;
            if(newAccount.OwnerId != oldAccount.OwnerId && newAccount.OwnerId != null){
                              accountIdSet.add(newAccount.Id);                              
            }
        
        }
        
        if(accountIdSet.Size() > 0){
            
             List<Opportunity>opportunityList =[Select Id , Name,OwnerId,AccountId from Opportunity WHERE AccountId  IN:accountIdSet];
           
             List<Integration_Opportunity_Event__e> opportunityEventList = New List<Integration_Opportunity_Event__e>();
        for(Opportunity opportunityObject: opportunityList){
            opportunityEventList.add(New Integration_Opportunity_Event__e(Id__c = opportunityObject.Id));
             
        }
            Id profileId=userinfo.getProfileId();
        String profileName=[SELECT Id,Name from Profile WHERE Id=:profileId].Name;
        /* Adding OR Condition as part of DF-01043 so that publishEventBus method will not trigger for Integration user profile*/
        if(String.isNotBlank(profileName) && !profileName.containsIgnoreCase(System.label.NSP_Integration_User_Profile_Name)){
            publishEventBus(opportunityEventList, opportunityList); 
        
        }
        }
        
  
    }
    public static void publishEventBus(List<Integration_Opportunity_Event__e> eventList, List<Opportunity> objectList) {
        if(!eventList.isEmpty()) {
            // Publishing records Event 
            List<Database.SaveResult> results = EventBus.publish(eventList);
            // Inspect publishing result for each event
            List<NSP_Error_Log__c> logList = new List<NSP_Error_Log__c>();
            for (Database.SaveResult sr : results) {
                NSP_Error_Log__c log = new NSP_Error_Log__c();
                log.NSP_Class__c = 'NSP_OpportunityTriggerHelperFunction';
                log.NSP_Method__c = 'publishEventBus';                
                log.NSP_Description__c = String.valueOf(sr.getErrors()[0].getMessage()) + '  '+String.valueOf(sr.getErrors()[0].getStatusCode());
                log.NSP_Record_Id__c = sr.getId();
                logList.add(log);  
            }
            
            if(logList.size() > 0){
                insert logList;
            }
            
            
           
        }
    }

}