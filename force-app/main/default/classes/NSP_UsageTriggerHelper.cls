public class NSP_UsageTriggerHelper {
    public static void afterUpdateDirector(Map<Id,blng__Usage__c> usageNewMap, Map<Id,blng__Usage__c> usageOldMap) {
        List<String> partnerUsages= new List<String>();
        for(blng__Usage__c usage:usageNewMap.values()){
            blng__Usage__c oldUsage=usageOldMap.get(usage.Id);
            if(usage.NSP_Combined_partner_usage__c!=null && usage.blng__Status__c=='Processed' && oldUsage.blng__Status__c!=usage.blng__Status__c){
                partnerUsages.add(usage.Id);
                Integer delayInMinutes = 1;
                //make futrue call to process partner usages
                ID jobID = System.enqueueJob(new NSP_ProcessPartnerUsages(partnerUsages), delayInMinutes);
            }
        }
    }
    
}