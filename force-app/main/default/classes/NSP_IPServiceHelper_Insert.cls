public class NSP_IPServiceHelper_Insert {

   public void updateAssetOnImpProfile(List<Implementation_Profile__c> Implprofls){
        Id woAssetRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();
        Map<String,String> mapAccountIdAssetId = new Map<String,String>();
        set<String> setAccountIds = new set<String>();
        for(Implementation_Profile__c obj: Implprofls){
            if(obj.NSP_Asset__c == null){
                setAccountIds.add(obj.Account__c);
            }
        }
        
        for(Asset asst: [SELECT Id,AccountId FROM Asset WHERE AccountId IN: setAccountIds AND RecordTypeId =:woAssetRecordTypeId ]){
            mapAccountIdAssetId.put(asst.AccountId,asst.Id);
        }
        
        for(Implementation_Profile__c imp : Implprofls){
            if(mapAccountIdAssetId.containskey(imp.Account__c)){
                imp.NSP_Asset__c  = mapAccountIdAssetId.get(imp.Account__c);
            }
        }
    }
    

}