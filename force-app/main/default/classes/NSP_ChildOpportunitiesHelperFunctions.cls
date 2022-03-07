/**
Apex Class Name      :  NSP_ChildOpportunitiesHelperFunctions for Opportunity Trigger Helper that deals with child opportunities
Version              :  1.0                                                                          
Created Date         :  07/02/2021   
Function             :  This class is used as a helper extension to Opportunity Trigger Handler. 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Rakesh                   07/02/2021            First Iteration
*/
public class NSP_ChildOpportunitiesHelperFunctions {

    public NSP_ChildOpportunitiesHelperFunctions() {

    }


    /**
     * Updates the child opportunity with retirement service as product to close lost.
     * @param opportunityList lsit of New Opportunity.    
     * @return void             
     *                
     */

    public void updatesOnChildOpportunity(List < String > opportunityList) {

        List < Opportunity > opportunityToUpdateList = new List < Opportunity > ();
        //Querying the child oppotunities that has product type as Retirement Services
        //and is not closed lost and is not parent
        for (Opportunity opportunityObject: [SELECT Id, stagename, NSP_PrimaryProduct__c, NSP_Parent_Opportunity__r.NSP_PrimaryProduct__c
                FROM OPPORTUNITY WHERE NSP_Parent_Opportunity__c IN: opportunityList AND stagename !=: NSP_SalesConstants.CLOSED_LOST]) {
            if (opportunityObject.NSP_PrimaryProduct__c == NSP_SalesConstants.RETIREMENT_SERVICE) {
                //Update the stage to closed lost on child optys
                opportunityObject.stagename = NSP_SalesConstants.CLOSED_LOST;
                //Entering the lost reason as well
                opportunityObject.NSP_Lost_Reason__c = 'Other';
                opportunityToUpdateList.add(opportunityObject);
            }

            if (opportunityObject.NSP_PrimaryProduct__c == NSP_SalesConstants.INSURANCE_SERVICE && opportunityObject.NSP_Parent_Opportunity__r.NSP_PrimaryProduct__c == NSP_SalesConstants.WO) {
                //Update the is parent closed check box on child records
                opportunityObject.NSP_Is_Parent_Opportunity_Closed_Lost__c = TRUE;
                opportunityToUpdateList.add(opportunityObject);
            }
        }

        // updating the child opportunity records
        if (!opportunityToUpdateList.isEmpty()) {
            update opportunityToUpdateList;
        }


    }

    /**
     * Updates when primary product is changed on parent opportunity from WO to WX or vice versa
     * @param opportunityList lsit of New Opportunity.    
     * @return void             
     *                
     */

    public void updateChildOpportunityOnProductChange(List < String > opportunityList) {

        List < Opportunity > opportunityToUpdateList = new List < Opportunity > ();
        //Querying the child oppotunities that has product type as Retirement Services
        //and is not closed lost and is not parent
        for (Opportunity opportunityObject: [SELECT Id, stagename
                FROM OPPORTUNITY WHERE NSP_Parent_Opportunity__c IN: opportunityList 
        AND NSP_PrimaryProduct__c =: NSP_SalesConstants.RETIREMENT_SERVICE
                AND stagename !=: NSP_SalesConstants.CLOSED_LOST ]) {
            //Update the stage to closed lost on child optys
            opportunityObject.NSP_Parent_Primary_Product_Changed__c = true;
            opportunityToUpdateList.add(opportunityObject);
        }

        // updating the child opportunity records
        if (!opportunityToUpdateList.isEmpty()) {
            update opportunityToUpdateList;
        }

    }

    /*
     * Description: Iterates through all new child Opportunties(Opportunity where NSP_Parent_Opportunity__c is populated)
     * and copies Client for Life value from parent opportunity to child opportunity
     * @return: void
     * Modification History:
     * -------------------------------------------------------------------------------------
     * author           | Date              | Description
     * -------------------------------------------------------------------------------------
     * Tejas          10-19-2021          created this new method
     * 
     * 
     */
    public static void defaultFieldsOnChildOpportunity(List < Opportunity > newChildOpportunityList, Set < Id > parentOpportunityIdsSet) {
        Map < Id, Opportunity > parentOpportunityMap = new Map < Id, Opportunity > ([SELECT Id, NSP_PrimaryProduct__c, NSP_Client_For_Life__c FROM Opportunity
            WHERE Id IN: parentOpportunityIdsSet ]);

        for (Opportunity opportunityObject: newChildOpportunityList) {
            opportunityObject.NSP_Client_For_Life__c = parentOpportunityMap.get(opportunityObject.NSP_Parent_Opportunity__c).NSP_Client_For_Life__c;
        }
    }


}