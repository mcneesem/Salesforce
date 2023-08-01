public class NSP_BudgetaryQuoteTaxController {

    private NSP_BudgetaryQuoteTaxController(){}
     /**
     * Iterates through the opportunities where Sales Tax is changed
     * @param opportunityIdList of Opportunities Id where Sales Tax is changed
     * @return void             
     * 
     */
    public static void stampTaxFieldsToQuote(List <String> opportunityIdList) {
        List<SBQQ__Quote__c> quoteToUpdate = new List<SBQQ__Quote__c>();
        List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
        
		for(Opportunity op : [SELECT Id, AVA_SFCLOUD__Sales_Tax__c, SBQQ__PrimaryQuote__c, (SELECT Id, AVA_SFCLOUD__Sales_Tax_Rate__c, AVA_SFCLOUD__Sales_Tax_Details__c, AVA_SFCLOUD__SalesTax_Line__c,SBQQ__QuoteLine__c from OpportunityLineItems) FROM Opportunity WHERE SBQQ__PrimaryQuote__r.NSP_Budgetary_Quote__c = true AND  Id IN : opportunityIdList]){
            SBQQ__Quote__c qt = new SBQQ__Quote__c();
			qt.Id = op.SBQQ__PrimaryQuote__c;
			qt.NSP_Sales_Tax__c = op.AVA_SFCLOUD__Sales_Tax__c;
            quoteToUpdate.add(qt);
            
            for (OpportunityLineItem oli : op.OpportunityLineItems) {
                SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c();
                qli.id = oli.SBQQ__QuoteLine__c;
                qli.NSP_Sales_Tax_Amount__c = oli.AVA_SFCLOUD__SalesTax_Line__c;
                qli.NSP_Sales_Tax_Rate__c = oli.AVA_SFCLOUD__Sales_Tax_Rate__c;
				qli.NSP_Sales_Tax_Details__c = oli.AVA_SFCLOUD__Sales_Tax_Details__c;
                
                quoteLinesToUpdate.add(qli);
            }
        }
        
        if(quoteToUpdate.size() > 0){ update quoteToUpdate;}
        if(quoteLinesToUpdate.size() > 0){ update quoteLinesToUpdate;}
    }
}