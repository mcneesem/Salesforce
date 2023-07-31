public class NSP_QuoteLineTriggerHelper {
    /**
* Iterates throught the list of new Quote Lines and passes the required attributes to other methods.
* @param newList List of New Quote Lines.  
* @return void             
*                
*/
   public void beforeUpdateDirector(List<SBQQ__Quoteline__c> newList){         
        validateQuoteLines(newList);
    }
    private void validateQuoteLines(List<SBQQ__Quoteline__c> quoteLines){
        List<Id> renewedSubIds= new List<Id>();
        List<Id> originalPriceNullIds = new List<Id>();
        for(SBQQ__Quoteline__c qline:quoteLines){
            if(qline.NSP_Action_Type__c==NSP_CPQConstants.QUOTE_TYPE_RENEWAL && qline.SBQQ__RenewedSubscription__c!=null){
                renewedSubIds.add(qline.SBQQ__RenewedSubscription__c);
            }
            if(qline.NSP_Original_Price__c == null){
                originalPriceNullIds.add(qline.Id);
            }
        }
        if(originalPriceNullIds != null){
            updateOriginalPriceOnAmend(originalPriceNullIds, quoteLines);
        }
        Map<Id,List<String>> flggedForETMap=retrieveEntitlementsFlggedForET(renewedSubIds);
        for(SBQQ__Quoteline__c qline:quoteLines){
            if(qline.NSP_Action_Type__c==NSP_CPQConstants.QUOTE_TYPE_RENEWAL && flggedForETMap.get(qline.SBQQ__RenewedSubscription__c)!=null){
                String serialIds = String.join(flggedForETMap.get(qline.SBQQ__RenewedSubscription__c), ',');  
                qLine.NSP_ET_Checked_Serial_Ids__c=serialIds;
            }
            //Early Termination is flgged for that hardware/support, we will not allow the user to renew fully
            if(qline.NSP_Action_Type__c==NSP_CPQConstants.QUOTE_TYPE_RENEWAL && flggedForETMap.get(qline.SBQQ__RenewedSubscription__c)!=null &&flggedForETMap.get(qline.SBQQ__RenewedSubscription__c).size()>0 && qline.NSP_Quoted_Quantity__c==qline.NSP_Previous_subQty__c){
                qline.addError('Perform Partial Renewal for '+qline.SBQQ__ProductName__c+' '+' as it is Due for Early Termination');
            }
        }
    }
    private Map<Id,List<String>> retrieveEntitlementsFlggedForET(List<Id> renewedSubIds){
        Map<Id,List<String>> flggedForETMap= new Map<Id,List<String>>();
        for(NSP_Support_Entitlement__c entitlement:[SELECT Id,NSP_Supported_Subscription__c,NSP_Serial_ID__c FROM NSP_Support_Entitlement__c WHERE NSP_Early_Termination_Notice__c=true and NSP_Supported_Subscription__c IN:renewedSubIds]){
            if(!flggedForETMap.containsKey(entitlement.NSP_Supported_Subscription__c)){
                flggedForETMap.put(entitlement.NSP_Supported_Subscription__c,new List<String>{entitlement.NSP_Serial_ID__c});
            }
            else{
                flggedForETMap.get(entitlement.NSP_Supported_Subscription__c).add(entitlement.NSP_Serial_ID__c);
            }
        }
        return flggedForETMap;
    }

    // This method updates the original price field on all the quote line on amendment
    private void updateOriginalPriceOnAmend(List<Id> originalPriceNullIds, List<SBQQ__QuoteLine__c>quoteLines){
        Map<Id,SBQQ__QuoteLine__c> quoteLinesQueried = new Map<Id,SBQQ__QuoteLine__c> ([SELECT Id, SBQQ__UpgradedSubscription__c, SBQQ__Quote__r.SBQQ__Type__c, SBQQ__UpgradedSubscription__r.NSP_Net_Total__c, NSP_Original_Price__c
                                                      FROM SBQQ__QuoteLine__c WHERE Id IN: originalPriceNullIds]);
        for(SBQQ__QuoteLine__c qline: quoteLines){
            if(originalPriceNullIds.contains(qline.Id) && qline.SBQQ__UpgradedSubscription__c != null && quoteLinesQueried.get(qline.Id).SBQQ__Quote__r.SBQQ__Type__c == 'Amendment' && qline.NSP_Original_Price__c == null){
                qline.NSP_Original_Price__c = quoteLinesQueried.get(qline.Id).SBQQ__UpgradedSubscription__r.NSP_Net_Total__c;
            }
        }
    }
    
    
}