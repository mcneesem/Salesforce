public with sharing class NSP_OpportunityTriggerHelperFunctions {
    // test w/ NSP_OpportunityTriggerHelperTest, NSP_AccountTriggerHelperTest (90%)
    // test w/ NSP_OpportunityTriggerHelperTest (84%)
    // test w/ NSP_AccountTriggerHelperTest (65%)

    private static Map<Id,User> customerSuccessUsers;
    private static Map<Id,User> coreMidMarketUsers;
    private static Pricebook2 woPriceBookCache;
    private static final String I9ASSIST_EVERIFY ='I-9 Assist & E-Verify';
    private static final String WX ='WX';

    public NSP_OpportunityTriggerHelperFunctions() {
    }

    //
    // Stamps email of the account owner on the oportunity record
    // @param opportunityList lsit of New Opportunity.
    // @param accountIdSet set of account ids.
    // @return void
    //
    public void setDirectOpptyFieldsAssignments(List<Opportunity> opportunityList) {
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        // Use CustomPermissionController to check custom permissions for all owners
        if (customerSuccessUsers == null) {
            customerSuccessUsers = CustomPermissionController.getPermittedUsersMap('Opportunity_NCS_Email_Customer_Success');
        }
        if (coreMidMarketUsers == null) {
            coreMidMarketUsers = CustomPermissionController.getPermittedUsersMap('Opportunity_NCS_Email_Core_MidMarket');
        }
        for (Opportunity opportunityObject: opportunityList) {
            //stamping Mid-Market sales team email on opportunity record
            opportunityObject.NSP_Mid_Market_Sales_Email__c = Label.NSP_Mid_Market_Sales_Email; //'midmarketleads@insperity.com'
            //stamping new client sales email on opportunity record.
            //DF-01858
            // Added if condition as part of DF-01369
            setOpportunityName(opportunityObject);
            //STY-01818 - Setting Client for Life
            opportunityObject.NSP_Client_For_Life__c = setClientForLifeOnOppty(opportunityObject.NSP_Client_For_Life__c, opportunityObject.NSP_PrimaryProduct__c);
            // DF-01858 -NCS Notification trigger based on primary product & owner role
            setNewClientSalesEmail(opportunityObject);
            //If backout fields are not blank checking backout check box to true
            setBackOutCheckbox(opportunityObject);
            //When Opportunity has primary product as WO then price is set to WO price book
            setPriceBookForWO(opportunityObject);
        }
    }

    private void setNewClientSalesEmail(Opportunity opp) {
        if (String.isNotBlank(opp.NSP_PrimaryProduct__c)) {
            String primaryProductLower = opp.NSP_PrimaryProduct__c.toLowerCase();
            Boolean hasCustomerSuccessPerm = customerSuccessUsers.containsKey(opp.OwnerId);
            Boolean hasCoreMidMarketPerm = coreMidMarketUsers.containsKey(opp.OwnerId);
            if (!hasCustomerSuccessPerm && getLabelValuesAsSet(System.Label.NSP_Workforce_Primary_Product).contains(primaryProductLower)) {
                opp.NSP_New_Client_Sales_Email__c = Label.NSP_New_Client_Sales_Email;
            } else if (!hasCustomerSuccessPerm && getLabelValuesAsSet(System.Label.NSP_OtherthanWorkforce_Primary_Product).contains(primaryProductLower)) {
                opp.NSP_New_Client_Sales_Email__c = Label.NSP_Salepprwk_Email;
            } else if (hasCoreMidMarketPerm && getLabelValuesAsSet(System.Label.NSP_Other_Primary_Product).contains(primaryProductLower)) {
                opp.NSP_New_Client_Sales_Email__c = Label.NSP_Salepprwk_Email;
            }
        }
    }

    private void setPriceBookForWO(Opportunity opp) {
        if (String.isNotBlank(opp.NSP_PrimaryProduct__c) && 'WO'.equals(opp.NSP_PrimaryProduct__c)) {
            Pricebook2 woPriceBook = fetchWOPriceBook();
            if (woPriceBook != null) {
                opp.Pricebook2Id = woPriceBook.Id;
            }
        }
    }

    private void setBackOutCheckbox(Opportunity opp) {
        if (opp.NSP_BackOutDate__c != null && String.isNotBlank(opp.NSP_BackOutReason__c) && String.isNotBlank(opp.NSP_BackOutRequestor__c)) {
            opp.NSP_Back_Out__c = true;
        }
    }

    private Pricebook2 fetchWOPriceBook() {
        if (woPriceBookCache == null) {
            List<Pricebook2> priceBookList = [
                SELECT Id , Name
                FROM Pricebook2
                WHERE ( Name = :NSP_SalesConstants.NON_CPQ_PRICEBOOK )
                LIMIT 1
            ];
            woPriceBookCache = priceBookList.isEmpty() ? null : priceBookList[0];
        }
        return woPriceBookCache;
    }

    private void setOpportunityName(Opportunity opp) {
        if (opp.NSP_Account_Name__c != null && Trigger.isBefore && Trigger.isInsert) {
            String accountName = opp.NSP_Account_Name__c;
            Integer accountNameLength = accountName.length();
            String trimmedAccountName = (accountNameLength > 97)
                ? accountName.left(94) + '...'
                : accountName;
            opp.Name = trimmedAccountName + ' - ' + DateTime.now().format();
        }
    }

    //
    // Method to get product values from System Label and return list of String Set
    // @param string with Products
    //
    public static set<String> getLabelValuesAsSet(String labelValue){
        set<String> values = new Set<String>();
        if(String.isNotBlank(labelValue)){
            for(String value : labelValue.split(',')){
                values.add(value.trim().toLowerCase());
            }
        }
        return values;
    }

    //
    // Method to check conditions and return client for life
    // @param opptyCfl String for client for life
    // @param opptyPrimaryProduct String for opportunity primary product
    // @return void
    //
    private static String setClientForLifeOnOppty( String opptyCfl , String opptyPrimaryProduct ) {
        if ( String.isnotBlank( opptyPrimaryProduct ) ) {
            if ( opptyPrimaryProduct.equals( NSP_SalesConstants.WO )
                || opptyPrimaryProduct.equals( NSP_SalesConstants.WS )
                )
            {
                opptyCfl = NSP_CPQConstants.CLIENT_WOWS;
            }
            if ( opptyPrimaryProduct.equals( NSP_SalesConstants.WX ) ) {
                opptyCfl = NSP_SalesConstants.WX;
            }
            if ( ( opptyCfl != NSP_CPQConstants.CLIENT_WOWS )
                && opptyPrimaryProduct.equals( NSP_SalesConstants.WA )
                )
            {
                opptyCfl = NSP_SalesConstants.WA;
            }
            if ( opptyPrimaryProduct.equals( NSP_SalesConstants.CONTRACTOR_MANAGEMENT ) ) {
                opptyCfl = NSP_SalesConstants.STAND_ALONE;
            }
            if ( ( opptyCfl != NSP_OpportunityTriggerHelperFunctions.WX )
                 && opptyPrimaryProduct.equals( NSP_OpportunityTriggerHelperFunctions.I9ASSIST_EVERIFY ) ) {
                opptyCfl = NSP_CPQConstants.CLIENT_WOWS;
            }
        }
        return opptyCfl;
    }

    //
    // Stamps email of the account owner on the oportunity record
    // @param opportunityList lsit of New Opportunity.
    // @param accountIdSet set of account ids.
    // @return void
    //
    public void getAccountOwnerEmail( List<Opportunity> opportunityList , Set<String> accountIdSet ) {
        //Map of account Id and Account object
        //Modified by Nischay as a part of STY-02090
        Map<Id,String> accountContactMap = new Map<Id,String>();
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

    //
    // Stamps the WO/WX emails on the Opportunity record depending on the product type selected
    // @param opportunityList lsit of New Opportunity.
    // @param accountIdSet set of account ids.
    // @return void
    //
    public void stampWoWxEmailOnOpprtunity( List<Opportunity> opportunityList ) {
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

    //
    // Description: This method takes all the opportunities where
    // the Opportunity Owner is changed and populates Engage Service Team email field
    // based on the Opportunity owner's sales office
    // @param: newOpportunityList, userIdSet
    // @return: void
    //
    public static void populateServiceEmail( List<Opportunity> newOpportunityList , Set<Id> userIdSet ) {
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

    //
    // MethodName: getAccountOwnerEmail
    // Description : This method will update the Point of Contact and Customer Signer on Opportunity after Insert
    // Params: Set<Id> accountId
    //
    public static void getAccountOwnerEmail( Set<Id> accountId ) {
        // STY-02090
        Map<Id,Id> accountOpportunityMap = new Map<Id,Id>();
        List<Opportunity>opportunityList =[Select Id , Name,NSP_Customer_Signer__c ,NSP_Primary_Contact__c,AccountId from Opportunity WHERE AccountId IN:accountId];
        for(Opportunity opp:opportunityList){
            accountOpportunityMap.put(opp.AccountId,opp.Id);
        }
        Map<Id,String> accountContactMap = new Map<Id,String>();
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

    // Account-after-update
    // when an Account changes ownership, publish a Platform Event to Premier Pathway for each Opportunity related to the transferred Account...
    public static void updateOppOwnerPremier( Map<Id,Account> newMap , Map<Id,Account> oldMap ) {
        try {
            Set<Id> accountIdSet = new Set<Id>();
            if ( ( newMap != null ) && !newMap.isEmpty() ) {
                for ( Account newAccount : newMap.values() ) {
                    Account oldAccount = ( ( oldMap != null ) ? oldMap.get( newAccount.Id ) : null );
                    if ( ( oldAccount != null )
                        && ( newAccount.OwnerId != oldAccount.OwnerId )
                        && ( newAccount.OwnerId != null )
                        )
                    {
                        accountIdSet.add( newAccount.Id );
                    }
                }
            }
            if ( !accountIdSet.isEmpty() ) {
                NSP_OpportunityTriggerHelper.publishIntegrationSyncEvents([
                    SELECT Id
                    FROM Opportunity
                    WHERE ( AccountId IN :accountIdSet )
                ]);
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_OpportunityTriggerHelperFunctions.class.getName() ,
                'updateOppOwnerPremier' ,
                e
            );
        }
    }

}
//