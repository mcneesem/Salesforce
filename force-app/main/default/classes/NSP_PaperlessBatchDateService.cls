public class NSP_PaperlessBatchDateService {
    private NSP_PaperlessBatchDateService(){}
    public static void 	updatePaperlessOnAsset(List<NSP_Sub_Client_Contact__c> newSubClientContacts){
        
        Map<Id, Boolean> assetBYPaperless = new Map<Id, Boolean>();

        List<Asset> assetToBeUpdated = new List<Asset>();
        for(NSP_Sub_Client_Contact__c subClientContact : newSubClientContacts){
            if(assetBYPaperless.Containskey(subClientContact.NSP_Sub_Client__r.NSP_Asset__c) && assetBYPaperless.get(subClientContact.NSP_Sub_Client__r.NSP_Asset__c)) {
                continue;
            }
            Asset asset = new Asset();
            asset.Id = subClientContact.NSP_Sub_Client__r.NSP_Asset__c;      
            /*if(subClientContact.NSP_Sub_Client__r.NSP_Asset__r.Status == 'Terminated'){
                asset.NSP_Paperless__c = false;
                assetBYPaperless.put(subClientContact.NSP_Sub_Client__r.NSP_Asset__c, false);
                assetToBeUpdated.add(asset);
            } else*/ if(subClientContact.NSP_Sub_Client__r.NSP_Account_Status__c == 'Active'){                
                If(subClientContact.NSP_Paid_Non_Paid__c == 'Paid WSEE' && subClientContact.NSP_Employee_Status__c != 'TERMINATED' && subClientContact.NSP_IsPaperless__c == true){                    
                    asset.NSP_Paperless__c = true;
                    assetBYPaperless.put(subClientContact.NSP_Sub_Client__r.NSP_Asset__c, true);
                    assetToBeUpdated.add(asset);
                    
                }else if((subClientContact.NSP_Paid_Non_Paid__c == 'Active Non-Paid User' || subClientContact.NSP_Paid_Non_Paid__c == 'Inactive Non-Paid User') && subClientContact.NSP_IsPaperless__c == true){                    
                    asset.NSP_Paperless__c = true;
                    assetBYPaperless.put(subClientContact.NSP_Sub_Client__r.NSP_Asset__c, true);
                    assetToBeUpdated.add(asset);
                    
                } else{
                    asset.NSP_Paperless__c = false;
                    assetBYPaperless.put(subClientContact.NSP_Sub_Client__r.NSP_Asset__c, false);
                    assetToBeUpdated.add(asset);
                }
            }  
        }
        Map<id, Asset> allAssetsToBeUpdated = new Map<id, Asset>();
        if(assetToBeUpdated.size()>0){
            allAssetsToBeUpdated.putAll(assetToBeUpdated);
            
            if(allAssetsToBeUpdated.size() > 0) {
                update allAssetsToBeUpdated.values();
            }
        }
    }
}