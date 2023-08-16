/**
* @description  : Batch Class to process asset and create opportunity and quote for story STY-02703
* @author Sumit
* @date 10/01/2023
* Name : NSP_ProcessOrderChangeBatch
*/
global class NSP_ProcessOrderChangeBatch implements Database.Batchable<sObject>,Schedulable {
    
    // schedulable ecexute method
    public void execute(SchedulableContext SC) {
        //execute the batch with batch size 10.
        NSP_ProcessOrderChangeBatch bch = new NSP_ProcessOrderChangeBatch();
		Database.executeBatch(bch,Integer.valueof(system.label.NSP_OrderChangeBatchSize)); 
    }
    
    public database.QueryLocator start(Database.BatchableContext bc)
    {
        return Database.getQueryLocator([SELECT id,NSP_RET_lead_parent__c,NSP_RET_lead_parent__r.AccountID,AccountId,NSP_OrderProduct__r.Order.SBQQ__Quote__c,NSP_OrderProduct__r.Order.SBQQ__Quote__r.RecordTypeId,
                                          NSP_OrderProduct__r.Order.SBQQ__Quote__r.NSP_Product_Type__c,NSP_OrderProduct__r.Order.SBQQ__Quote__r.NSP_Price_Book__c,NSP_ReAssigned_Order_Quote_Id__c,
                                         NSP_OrderProduct__r.Order.OpportunityId,NSP_Change_Order_Process_Contract_Status__c,NSP_OrderProduct__r.Order.NSP_Billing_Account__c 
                                         FROM Asset WHERE NSP_Process_Order_Change__c = true AND (NSP_Change_Order_Process_Contract_Status__c = null OR NSP_Change_Order_Process_Contract_Status__c = '') 
                                         AND NSP_RET_lead_parent__c != null AND ((NSP_OrderProduct__c != null AND NSP_OrderProduct__r.Order.SBQQ__Quote__c != null) OR NSP_ReAssigned_Order_Quote_Id__c != null) ]);
    }
    
    public void execute(Database.BatchableContext bc,list<Asset> scope)
    {
        Map<Id,Opportunity> assetIdToOpportunityMap = new Map<Id,Opportunity>();
        set<Id> opportunityIdSet = new set<Id>();
        for(Asset eachAsset : scope)
        {
            opportunityIdSet.add(eachAsset.NSP_OrderProduct__r.Order.OpportunityId);
        }
        
        
        for(Asset eachAsset : scope)
        {
            eachAsset.NSP_Change_Order_Process_Contract_Status__c ='Change Order Created' ;
            string quoteIdStr = eachAsset.NSP_ReAssigned_Order_Quote_Id__c != null ? eachAsset.NSP_ReAssigned_Order_Quote_Id__c : eachAsset.NSP_OrderProduct__r.Order.SBQQ__Quote__c ;
            QuoteReader reader = new QuoteReader();
            QuoteModel quoteModel = reader.read(quoteIdStr);
            
            SBQQ__Quote__c objNewQuote = QuoteModel.record;
            objNewQuote.SBQQ__Account__c = eachAsset.NSP_RET_lead_parent__r.AccountID;
            objNewQuote.SBQQ__Opportunity2__c = null;
            objNewQuote.SBQQ__Primary__c = true;
            objNewQuote.SBQQ__Ordered__c = false;
            objNewQuote.NSP_Change_Order_Process_Quote__c = true;
            objNewQuote.RecordTypeId = NSP_GenericRecordType.getRecordTypeId('SBQQ__Quote__c',NSP_ServiceConstants.RETIREMENT_SERVICES); //eachAsset.NSP_OrderProduct__r.Order.SBQQ__Quote__r.RecordTypeId;
            objNewQuote.NSP_Product_Type__c = eachAsset.NSP_OrderProduct__r.Order.SBQQ__Quote__r.NSP_Product_Type__c;
            objNewQuote.NSP_Price_Book__c = eachAsset.NSP_OrderProduct__r.Order.SBQQ__Quote__r.NSP_Price_Book__c;
            objNewQuote.NSP_Original_Order_Bill_To_Account__c = eachAsset.NSP_OrderProduct__r.Order.NSP_Billing_Account__c;
            objNewQuote.id  = null;
            objNewQuote.SBQQ__StartDate__c = system.today().toStartOfMonth();
            //system.debug(objNewQuote.RecordTypeId);
            objNewQuote.NSP_Change_Order_Process_Source_Asset__c = eachAsset.Id;
            objNewQuote.NSP_Lead_Parent_Asset_Id__c = eachAsset.NSP_RET_lead_parent__c;
            if(quoteModel.lineItems.size()>0){
                for (QuoteLineModel qlm : quoteModel.lineItems){
                    //qlm.record.SBQQ__Quote__c = null;
                    qlm.record.Id = null;
                }
            }
            
            String quoteJSON = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteModel)); 
            QuoteModel newquoteModel = (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
              
        }
        
        List<Database.SaveResult> opptyResults = Database.update(assetIdToOpportunityMap.values(),false);
        NSP_ErrorLogHandler.logSaveResultsException('NSP_ProcessOrderChangeBatch', 'ExecuteMethod', opptyResults ); //log the result
        
        List<Database.SaveResult> assetResults = Database.update(scope,false);
        NSP_ErrorLogHandler.logSaveResultsException('NSP_ProcessOrderChangeBatch', 'ExecuteMethod', assetResults ); //log the result
        
    }
    
    public void finish(Database.BatchableContext bc)
    {
        
    }
      
    
}