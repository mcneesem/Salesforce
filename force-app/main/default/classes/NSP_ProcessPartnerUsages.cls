/**
* @description  : Queueable Class to Process Partner Usages and override Subtotal on Usage Summary
* @author Samba Raju
* @date 05/17/2023
* Name : NSP_ProcessPartnerUsages
*/
public class NSP_ProcessPartnerUsages implements Queueable  {
    //varibales declaration
    private List<String> partnerUsages;
    //constructor
    public NSP_ProcessPartnerUsages(List<String> partnerUsages) {
        this.partnerUsages = partnerUsages;
    }
    //execute method implementation
    public void execute(QueueableContext context) {
        List<String> oitemConsumptionSchedule= new List<String>();
        Set<String> usageSummaries= new Set<String>();
        List<blng__Usage__c> usages=[SELECT Id,blng__UsageSummary__c,NSP_Combined_partner_usage__c,NSP_Order_Item_Consumption_Schedule__c FROM blng__Usage__c WHERE Id IN:partnerUsages];
        for(blng__Usage__c usage :usages){
            oitemConsumptionSchedule.add(usage.NSP_Order_Item_Consumption_Schedule__c);
            usageSummaries.add(usage.blng__UsageSummary__c);
        }
        if(oitemConsumptionSchedule.size()>0 && usageSummaries.size()>0){
            Map<Id,List<SBQQ__OrderItemConsumptionRate__c>> ratesMap= getOitemConsumptionRates(oitemConsumptionSchedule);
            Map<Id,SBQQ__OrderItemConsumptionRate__c> matchingRatecard=identifyMatchingRate(ratesMap,usages);
            overrideSubtotalOnUsageSummary(matchingRatecard,usageSummaries);
        }
    }
    /**
* Method Name : getOitemConsumptionRates 
* Description : Method to retrieve order item consumption rates.
* Author : CPQ      Date : 05/18/2023
* @param  List of oitemConsumptionSchedule Ids.   
* @return Map<Id,List<SBQQ__OrderItemConsumptionRate__c>>  
*/
    private Map<Id,List<SBQQ__OrderItemConsumptionRate__c>> getOitemConsumptionRates(List<String> oitemConsumptionSchedule){
        Map<Id,List<SBQQ__OrderItemConsumptionRate__c>> ratesMap= new Map<Id,List<SBQQ__OrderItemConsumptionRate__c>>(); // OItem Consumption schedule as key and list of rates as values
        for(SBQQ__OrderItemConsumptionRate__c rate:[SELECT Id,SBQQ__LowerBound__c,SBQQ__UpperBound__c,SBQQ__OrderItemConsumptionSchedule__c,SBQQ__Price__c FROM SBQQ__OrderItemConsumptionRate__c WHERE SBQQ__OrderItemConsumptionSchedule__c IN:oitemConsumptionSchedule]){
            if(!ratesMap.containsKey(rate.SBQQ__OrderItemConsumptionSchedule__c)){
                ratesMap.put(rate.SBQQ__OrderItemConsumptionSchedule__c,new List<SBQQ__OrderItemConsumptionRate__c>{rate});
            }
            else{
                ratesMap.get(rate.SBQQ__OrderItemConsumptionSchedule__c).add(rate);
            }
        }
        return ratesMap;
    }
    /**
* Method Name : identifyMatchingRate 
* Description : Method to identify matching tier from oitem consumption rates based on total partner usage quantity.
* Author : CPQ      Date : Date : 05/18/2023
* @param  Map<Id,List<SBQQ__OrderItemConsumptionRate__c>> ratesMap,List<blng__Usage__c> partnerUsages   
* @return Map<Id,SBQQ__OrderItemConsumptionRate__c>  
*/
    private Map<Id,SBQQ__OrderItemConsumptionRate__c> identifyMatchingRate(Map<Id,List<SBQQ__OrderItemConsumptionRate__c>> ratesMap,List<blng__Usage__c> partnerUsages){
        Map<Id,SBQQ__OrderItemConsumptionRate__c> matchingRatecard= new Map<Id,SBQQ__OrderItemConsumptionRate__c>(); // Usage Summary Id as key and matching tier as value
        for(blng__Usage__c usage:partnerUsages){
            for(SBQQ__OrderItemConsumptionRate__c rate:ratesMap.get(usage.NSP_Order_Item_Consumption_Schedule__c)){
                if(usage.NSP_Combined_partner_usage__c>=rate.SBQQ__LowerBound__c && usage.NSP_Combined_partner_usage__c<rate.SBQQ__UpperBound__c){
                    matchingRatecard.put(usage.blng__UsageSummary__c,rate);
                }
            }
        }
        return matchingRatecard;
    }
    /**
* Method Name : overrideSubtotalOnUsageSummary 
* Description : Method to update subtotal on usage summary.
* Author : CPQ      Date : Date : 05/18/2023
* @param  Map<Id,SBQQ__OrderItemConsumptionRate__c> matchingRatecard,Set<String> usageSummaries   
* @return void 
*/
    private void overrideSubtotalOnUsageSummary(Map<Id,SBQQ__OrderItemConsumptionRate__c> matchingRatecard,Set<String> usageSummaries){
        List<blng__UsageSummary__c> summariesToUpdate= new List<blng__UsageSummary__c>();
        for(blng__UsageSummary__c summary:[SELECT Id,blng__TotalQuantity__c,blng__Subtotal__c FROM blng__UsageSummary__c WHERE Id IN:usageSummaries]){
            blng__UsageSummary__c updatedSummary = new blng__UsageSummary__c(Id=summary.Id,NSP_Billed_Free__c=true);
            if(summary.blng__TotalQuantity__c!=null){
                updatedSummary.blng__Subtotal__c=matchingRatecard.get(summary.Id).SBQQ__Price__c*summary.blng__TotalQuantity__c;
                updatedSummary.blng__UnitPrice__c=matchingRatecard.get(summary.Id).SBQQ__Price__c;
                summariesToUpdate.add(updatedSummary);
            }
        }
        if(summariesToUpdate.size()>0){
            List<Database.SaveResult> results = Database.update(summariesToUpdate,false);
            NSP_ErrorLogHandler.logSaveResultsException('NSP_ProcessPartnerUsages','overrideSubtotalOnUsageSummary', results); 
        }
    }
}