/**
* @description  : Batch Class to create renewal opportunity 120 days before Asset Renewal Date
* @author Tejas
* @date 22/09/2021
* Name : NSP_SalesAssetRenewalBatch
*/
public class NSP_SalesAssetRenewalBatch implements Database.Batchable<SObject>{
    
    public String sQuery;
    public Integer iNumberOfDays;
    public List<String>  WOProductNamesList;
    public String NSP_SalesAssetRenewalBatch = 'NSP_SalesAssetRenewalBatch';
    
    /**
* @description  : Start Method
* @author Tejas
* @date 22/09/2021
* Name : start (Database.BatchableContext bc)
*/ 
    public Database.QueryLocator start(Database.BatchableContext bc) {
        //Number of days before which new Renewal Opportunity has to be created for an asset record
        iNumberOfDays = Integer.valueOf(System.Label.NSP_Sales_NumberOfDaysBeforeRenewalDate);
        WOProductNamesList = System.Label.NSP_ProductNamesForAssetRenewalOpportunities.split(',');
        sQuery = 'SELECT Id, Name, NSP_Renewal_Date__c, AccountId, NSP_Active_No_Employees__c '
            +' FROM Asset WHERE Product2.Name IN :WOProductNamesList  AND NSP_Renewal_Date__c > TODAY '
            +' AND NSP_Renewal_Date__c > NEXT_N_DAYS:'+(iNumberOfDays-1)+' AND NSP_Renewal_Date__c = NEXT_N_DAYS:'+iNumberOfDays;
        return Database.getQueryLocator(sQuery);
    }
    
    /**
* @description  : execute method of batch class
* @author Tejas
* @date 22/09/2021
* Name : execute(Database.BatchableContext bc, List<Asset> assetList)
*/
    public void execute(Database.BatchableContext bc, List<Asset> assetList){
        List<Opportunity> opportunityList = new List<Opportunity>();
        for(Asset assetRecord : assetList) {
            Opportunity opportunity = new Opportunity();
            opportunity.Name = NSP_SalesConstants.RENEWAL_OPPORTUNITY;
            opportunity.CloseDate = assetRecord.NSP_Renewal_Date__c;//Removed renewal date field from here
            opportunity.StageName = NSP_SalesConstants.PROPOSAL_STAGE;
            opportunity.Type = NSP_SalesConstants.RENEWAL_OPPORTUNITY;
            opportunity.AccountId = assetRecord.AccountId;
            opportunity.NSP_Number_of_Employees__c = assetRecord.NSP_Active_No_Employees__c != null ? assetRecord.NSP_Active_No_Employees__c : 1;
            
            opportunityList.add(opportunity);
        }
        
        if(! opportunityList.isEmpty()) {
            try{
                Database.SaveResult[] sr = Database.insert(opportunityList, true);
            } catch(Exception ex) {
                NSP_CustomException.LogException(ex);
            }
        }
    }
    
    public void finish(Database.BatchableContext bc){
        
    }

}