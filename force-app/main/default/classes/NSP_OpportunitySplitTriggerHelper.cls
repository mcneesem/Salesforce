/**
* Represents the Opportunity Split trigger helper which handles all the logic.
* Class Name: NSP_OpportunitySplitTriggerHelper
*/
public class NSP_OpportunitySplitTriggerHelper {
    /**
* Iterates throught the list of new Opportunity Split and passes the required attributes to other methods.
* @param newList List of New Opportunity Split.  
* @return void             
*                
*/
    public void beforeInsertDirector(List<NSP_Employee_Split__c> newList){
        List<NSP_Employee_Split__c> listOfOpportunitySplit = new List<NSP_Employee_Split__c> ();
        List<NSP_Employee_Split__c> listOfOpptySplit       = new List<NSP_Employee_Split__c> ();
        Set<Id> setOfOpportunityId                         = new Set<Id> ();
        Set<Id> setOfOpptyId                               = new Set<Id> ();
        // Iterating over Opportunity Split records
        for(NSP_Employee_Split__c oppSplit : newList){
           if(oppSplit.NSP_Opportunity__c != null && oppSplit.NSP_Number_of_Employees__c != null){
                listOfOpportunitySplit.add(oppSplit);
                setOfOpportunityId.add(oppSplit.NSP_Opportunity__c);
           }
           
           if(oppSplit.NSP_Opportunity__c != null){
                listOfOpptySplit.add(oppSplit);
                setOfOpptyId.add(oppSplit.NSP_Opportunity__c);
           }
        }
        // Added check if Opportunity and Number of EE are not null. If true, run the functionality
        if(!listOfOpportunitySplit.isEmpty()){
            throwErrorWhenSumOfEmployeeExceed(listOfOpportunitySplit, setOfOpportunityId);
        }
        // Added check if Opportunity is not null and auto populating account on Opportunity Split
        if(!listOfOpptySplit.isEmpty()){
            autoPopulateAccount(listOfOpptySplit, setOfOpptyId);
        }
    }

    public void beforeUpdateDirector(Map<Id, NSP_Employee_Split__c> opportunitySplitNewMap, Map<Id, NSP_Employee_Split__c> opportunitySplitOldMap){
        List<NSP_Employee_Split__c> listOfOpportunitySplit = new List<NSP_Employee_Split__c> ();
        Set<Id> setOfOpportunityId                         = new Set<Id> ();
        // Iterating over Opportunity Split records
        for(Id oppSplitId : opportunitySplitNewMap.keyset()){
           if(opportunitySplitNewMap.get(oppSplitId).NSP_Opportunity__c != null 
            && opportunitySplitNewMap.get(oppSplitId).NSP_Number_of_Employees__c != null 
            && opportunitySplitNewMap.get(oppSplitId).NSP_Number_of_Employees__c != opportunitySplitOldMap.get(oppSplitId).NSP_Number_of_Employees__c){
                listOfOpportunitySplit.add(opportunitySplitNewMap.get(oppSplitId));
                setOfOpportunityId.add(opportunitySplitNewMap.get(oppSplitId).NSP_Opportunity__c);
           } 
        }
        // Added check if Opportunity and Number of EE are not null. If true, run the functionality
        if(!listOfOpportunitySplit.isEmpty()){
            throwErrorWhenSumOfEmployeeExceed(listOfOpportunitySplit, setOfOpportunityId);
        }
    }

    /**
* This method is used to check if Sum of EE on Opportunity Split is greater than Number of Employees on Opportunity or not.
* If Yes, it will throw error message.
* @param newList List of New Opportunity Split.  
* @param setOfOpp Set of Opportunity id.
* @return void             
*                
*/
    public void throwErrorWhenSumOfEmployeeExceed(List<NSP_Employee_Split__c> newList, Set<Id> setOfOpp){
        Map<Id, Decimal> mapOfOpportunityIdAndSumOfEE         = new Map<Id, Decimal> ();
        Map<Id, Opportunity> mapOfOpportunityIdAndOpportunity = new Map<Id, Opportunity> ();
        Decimal finalSumOfEE;
		// Aggregate query to get Sum of Number of EE on Opportunity Split
        AggregateResult[] groupedResults = [SELECT SUM(NSP_Number_of_Employees__c),NSP_Opportunity__c 
                                            FROM NSP_Employee_Split__c 
                                            WHERE NSP_Opportunity__c IN :setOfOpp and ID NOT IN : newList
                                            GROUP BY NSP_Opportunity__c ];
        // Iterating over aggregateResult and Creating map of Opportunity id and Sum of EE on Opp Split
        for(AggregateResult ar:groupedResults) {
            Id oppId = (ID)ar.get('NSP_Opportunity__c');
            Decimal sumOfNumberOfEE = (Decimal)ar.get('expr0');

            if(!mapOfOpportunityIdAndSumOfEE.containsKey(oppId)){
                mapOfOpportunityIdAndSumOfEE.put(oppId, sumOfNumberOfEE);
            }
        }
        // Iterating over opportunity and creating map of Opportunity Id and Opportunity record
        for(Opportunity opp : [SELECT NSP_Number_of_Employees__c FROM Opportunity WHERE ID IN : setOfOpp]){
            if(opp.NSP_Number_of_Employees__c != null ){
                mapOfOpportunityIdAndOpportunity.put(opp.id, opp);
            }
        }
        // Iterating over Opportunity Split record and check if Number of EE is greater than Number of Employees on Opportunity or not.
        for(NSP_Employee_Split__c empSplit : newList){
            if(mapOfOpportunityIdAndSumOfEE.containsKey(empSplit.NSP_Opportunity__c) && mapOfOpportunityIdAndSumOfEE.get(empSplit.NSP_Opportunity__c) != null){
                finalSumOfEE = empSplit.NSP_Number_of_Employees__c + mapOfOpportunityIdAndSumOfEE.get(empSplit.NSP_Opportunity__c);
            }else{
                finalSumOfEE = empSplit.NSP_Number_of_Employees__c;
            }
            if(mapOfOpportunityIdAndOpportunity.containsKey(empSplit.NSP_Opportunity__c)){
                if(finalSumOfEE > mapOfOpportunityIdAndOpportunity.get(empSplit.NSP_Opportunity__c).NSP_Number_of_Employees__c){
                	empSplit.addError(System.Label.NSP_ErrorMessageSumOfEEIsGreaterThanNumberOfEmployeesOnOppty);
            	}
            }
        }
    }

    /**
* This method is used to auto-populate Account from related opportunity
* @param newList List of New Opportunity Split.  
* @param setOfOpp Set of Opportunity id.
* @return void             
*                
*/

    public void autoPopulateAccount(List<NSP_Employee_Split__c> newList, Set<Id> setOfOpp){
        Map<Id, Id> mapOfOpportunityIdAndAccountId = new Map<Id, Id> ();
        // Iterating over Opportunity and creating a map of Opportunity Id and account id
        for(Opportunity opp : [SELECT AccountId FROM Opportunity WHERE ID IN : setOfOpp]){
            if(opp.AccountId != null){
                mapOfOpportunityIdAndAccountId.put(opp.id, opp.AccountId);
            }
        }
        // Iterating over Opportunity Split and auto populating Account with Opportunity Account
        for(NSP_Employee_Split__c empSplit : newList){
            if(mapOfOpportunityIdAndAccountId.containsKey(empSplit.NSP_Opportunity__c)){
                empSplit.NSP_Account__c = mapOfOpportunityIdAndAccountId.get(empSplit.NSP_Opportunity__c);
            }
        }
    }
}