/**
* @description  : Batch Class to process asset and create amendment on contract  for story STY-02703
* @author Sumit
* @date 10/01/2023
* Name : NSP_ProcessOrderCancellationBatch
*/
public class NSP_ProcessOrderCancellationBatch implements Database.Batchable<sObject>,Schedulable,Database.AllowsCallouts{
	
    // schedulable ecexute method
    public void execute(SchedulableContext SC) {
        //execute the batch with batch size 1 as contract amendment api works for 1 record.
        NSP_ProcessOrderCancellationBatch bch = new NSP_ProcessOrderCancellationBatch();
		Database.executeBatch(bch,1); 
    }
    
    public database.QueryLocator start(Database.BatchableContext bc){
         return Database.getQueryLocator([SELECT id,NSP_RET_lead_parent__r.AccountID,AccountId,NSP_OrderProduct__r.Order.SBQQ__Quote__c,NSP_OrderProduct__r.Order.SBQQ__Quote__r.RecordTypeId,NSP_OrderProduct__r.Order.OpportunityId,NSP_Change_Order_Process_Contract_Status__c 
                                         ,NSP_ReAssigned_Order_Id__c from Asset 
                                          WHERE NSP_Process_Order_Change__c = true 
                                          AND NSP_Change_Order_Process_Contract_Status__c = 'Ready To Close'
                                          AND 
                                          ((NSP_OrderProduct__c != null AND NSP_OrderProduct__r.OrderId != null) OR NSP_ReAssigned_Order_Id__c != null)]);
    }
    
     public void execute(Database.BatchableContext bc,list<Asset> scope){
        set<Id> orderIdSet = new set<Id>();
        for(Asset eachAsset : scope){
            	Id ordereIdStr = eachAsset.NSP_ReAssigned_Order_Id__c != null ? eachAsset.NSP_ReAssigned_Order_Id__c: eachAsset.NSP_OrderProduct__r.OrderId ;
                orderIdSet.add(ordereIdStr);
                eachAsset.NSP_Change_Order_Process_Contract_Status__c = 'Contract Closed';
        }
         
                
         if(orderIdSet.Size() > 0){
             list<OrderItem> orderItemUpdateList = new list<OrderItem>();
             list<SBQQ__Subscription__c> subscriptionUpdateList = new list<SBQQ__Subscription__c>();
             for(OrderItem eachItem : [SELECT id,SBQQ__TerminatedDate__c,SBQQ__SubscriptionType__c,EndDate  from OrderItem WHERE orderId IN : orderIdSet]){
                 eachItem.SBQQ__TerminatedDate__c = system.today().toStartOfMonth().addDays(-1);
                 /*if(eachItem.SBQQ__SubscriptionType__c != 'Evergreen'){
                     //eachItem.EndDate = system.today();
                 }*/
                 orderItemUpdateList.add(eachItem);
             }
             
             for(SBQQ__Subscription__c eachSub : [SELECT id,SBQQ__TerminatedDate__c,SBQQ__SubscriptionType__c,SBQQ__SubscriptionEndDate__c  from SBQQ__Subscription__c where SBQQ__OrderProduct__r.OrderId IN :orderIdSet ]){
                 eachSub.SBQQ__TerminatedDate__c = system.today().toStartOfMonth().addDays(-1);
                 if(eachSub.SBQQ__SubscriptionType__c != 'Evergreen'){
                     eachSub.SBQQ__SubscriptionEndDate__c = system.today().toStartOfMonth().addDays(-1);
                 }
                 subscriptionUpdateList.add(eachSub);
             }
             
             if(subscriptionUpdateList.Size() > 0){    
                 List<Database.SaveResult> subResults = Database.update(subscriptionUpdateList,false);
        		 NSP_ErrorLogHandler.logSaveResultsException('NSP_ProcessOrderCancellationBatch', 'ExecuteMethod', subResults ); //log the result
             }
             
             if(orderItemUpdateList.Size() > 0){
                 List<Database.SaveResult> orderitemResults = Database.update(orderItemUpdateList,false);
        		 NSP_ErrorLogHandler.logSaveResultsException('NSP_ProcessOrderCancellationBatch', 'ExecuteMethod', orderitemResults ); //log the result
             }

             List<Database.SaveResult> opptyResults = Database.update(scope,false);
        	 NSP_ErrorLogHandler.logSaveResultsException('NSP_ProcessOrderCancellationBatch', 'ExecuteMethod', opptyResults ); //log the result
             
             
         }
         
     }
    
     public void finish(Database.BatchableContext bc)
    {
        
    }
}