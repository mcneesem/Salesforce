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
            opportunityObject.NSP_New_Client_Sales_Email__c = Label.NSP_New_Client_Sales_Email;
            opportunityObject.Name = opportunityObject.NSP_Account_Name__c + ' - ' + DateTime.now().format();
            //STY-01818 - Setting Client for Life
            opportunityObject.NSP_Client_For_Life__c = setClientForLifeOnOppty(opportunityObject.NSP_Client_For_Life__c, opportunityObject.NSP_PrimaryProduct__c);

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
            if (String.isNotBlank(opportunityObject.NSP_PrimaryProduct__c) && opportunityObject.NSP_PrimaryProduct__c.equals('WO')) {
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
        //Map of account id and account object
        Map < Id, Account > mapAccountObject = new Map < Id, Account > ();

        //Iterating over the account ids in the set and getting the email of the account owner
        // and adding it to the map
        for (Account accountObj: [SELECT Id, Name, owner.email, NSP_Primary_Contact__c FROM Account WHERE id IN: accountIdSet]) {

            mapAccountObject.put(accountObj.id, accountObj);
        }

        //Iterating over the optys and stamping account owner email
        for (Opportunity opportunityObject: opportunityList) {
            if (mapAccountObject.containsKey(opportunityObject.AccountId)) {
                opportunityObject.NSP_Account_Owner_s_Email__c = mapAccountObject.get(opportunityObject.AccountId).owner.email;
                opportunityObject.NSP_Primary_Contact__c = mapAccountObject.get(opportunityObject.AccountId).NSP_Primary_Contact__c;
                opportunityObject.NSP_Customer_Signer__c = mapAccountObject.get(opportunityObject.AccountId).NSP_Primary_Contact__c;
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
            if (opportunityObject.NSP_PrimaryProduct__c.equals(NSP_SalesConstants.WO)) {
                opportunityObject.NSP_WO_WX_Results__c = Label.NSP_WO_Email_DL; //'results@insperity.com';
                //if product type is WX on opportunity the WX email DL
            } else if (opportunityObject.NSP_PrimaryProduct__c.equals(NSP_SalesConstants.WX)) {
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

        Map < Id, User > usersMap = new Map < Id, User > ([SELECT Id, NSP_Sales_Office__c FROM User WHERE Id IN: userIdSet]);

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


    /*
     * Description: This method takes all the opportunities where template selection is not null to
     * populate template id based on custom metadata
     * @param: newOpportunityList 
     * @return: void
     * Modification History:
     * -------------------------------------------------------------------------------------
     * author           | Date              | Description
     * -------------------------------------------------------------------------------------
     * CPQ stream          	10/28/2021         	created this new method
     * 
     * 
     */
    public void setDocuSignTemplateId(List < Opportunity > setOpptyTemplateIdList, Set < String > templateName) {
        //get custom metadata for docusign template mapping
        Map < String, NSP_DocuSign_Template_Mapping__mdt > templateNameIdMap = new Map < String, NSP_DocuSign_Template_Mapping__mdt > ();
        List < NSP_DocuSign_Template_Mapping__mdt > docusignTemplateMappingList = [Select NSP_Template_Id__c, NSP_Template_Name__c
            From NSP_DocuSign_Template_Mapping__mdt WHERE NSP_Template_Name__c IN: templateName
        ];

        for (NSP_DocuSign_Template_Mapping__mdt docuSignTemplateObj: docusignTemplateMappingList) {
            templateNameIdMap.put(docuSignTemplateObj.NSP_Template_Name__c, docuSignTemplateObj);
        }

        for (Opportunity opportuntityObj: setOpptyTemplateIdList) {
            if (templateNameIdMap.containsKey(opportuntityObj.NSP_Merge_On_Demand_Template_Selection__c)) {
                opportuntityObj.NSP_Merge_On_Demand_DocuSign_Template_Id__c = templateNameIdMap.get(opportuntityObj.NSP_Merge_On_Demand_Template_Selection__c).NSP_Template_Id__c;
            }
        }
    }



}