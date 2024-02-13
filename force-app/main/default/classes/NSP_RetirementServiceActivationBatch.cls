/**
 Apex Class Name      :  NSP_RetirementServiceActivationBatch
 Version              :  1.0
 Created Date         :  13/12/2022
 Function             :  Represents batch class for NSP_RetirementServiceActivationBatch
 Story                :  STY-03601
 Modification Log     :
 *--------------------------------------------------------------------------------------------------
 * Developer                   Date                   Description
 * -------------------------------------------------------------------------------------------------
 * Manikantan Mohan           13/12/2022              Retirement Service Activation on Order Products(which has order activation trigger as 'Plan Activation') Related to Asset object in the Client sub plan History.
 */
public class NSP_RetirementServiceActivationBatch implements Database.Batchable<sObject>, Database.Stateful{
    // test w/ NSP_RetirementServiceActivationBatchTest (92%)
    public NSP_RetirementServiceActivationBatch(){
    }

    //Querying the data from client sub plan history which has Start date as today and current subplan is true
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id, NSP_Start_Date__c,NSP_Asset__r.NSP_OrderProduct__r.SBQQ__Status__c,NSP_Asset__r.NSP_OrderProduct__r.OrderId,NSP_Asset__r.NSP_OrderProduct__r.NSP_Order_Activation_Trigger__c, NSP_Asset__c,NSP_Current_Subplan__c FROM NSP_Client_Sub_Plan_History__c where NSP_Current_Subplan__c = true AND NSP_Start_Date__c <= ' + String.valueOf(system.today());
        return Database.getQueryLocator(query);
    }

    // Collecting the order id from the order product associated to Asset and
    // Checking all order product for that order which has order trigger as Plan activation and Order product is not Active.
    public void execute(Database.BatchableContext bc, list<NSP_Client_Sub_Plan_History__c> clientSubPlanHistoryList){
        try{
            if (!clientSubPlanHistoryList.isEmpty()){
                Set<Id> orderIdSet = new Set<Id>();
                Set<Id> orderItemIdSet = new Set<Id>();
                Map<id,NSP_Client_Sub_Plan_History__c> mapOrderSubCLient = new Map<id,NSP_Client_Sub_Plan_History__c>();
                for (NSP_Client_Sub_Plan_History__c subPlan : clientSubPlanHistoryList){
                    orderIdSet.add(subPlan.NSP_Asset__r.NSP_OrderProduct__r.OrderId);
                    mapOrderSubCLient.put(subPlan.NSP_Asset__r.NSP_OrderProduct__r.OrderId,subPlan);
                }
                List<OrderItem> updateOrderItemList = new List<OrderItem>();
                for ( OrderItem orderItemRecord : [
                            SELECT Id , SBQQ__Status__c , OrderId , NSP_Order_Activation_Trigger__c
                            FROM OrderItem
                            WHERE ( OrderId IN :orderIdSet )
                        ]
                    )
                {
                    if (orderItemRecord.SBQQ__Status__c != NSP_SalesConstants.ACTIVATED_STATUS && orderItemRecord.NSP_Order_Activation_Trigger__c == NSP_SalesConstants.RET_Plan_Activation){
                        // updating the order products to 'Activated' status.
                        if ( !mapOrderSubCLient.isEmpty()
                            && mapOrderSubCLient.containsKey(orderItemRecord.OrderId)
                            && ( mapOrderSubCLient.get(orderItemRecord.OrderId) != null )
                            && ( mapOrderSubCLient.get(orderItemRecord.OrderId).NSP_Start_Date__c ! = null )
                            )
                        {
                            orderItemRecord.ServiceDate = mapOrderSubCLient.get(orderItemRecord.OrderId).NSP_Start_Date__c.toStartOfMonth();
                        }
                        orderItemRecord.SBQQ__Status__c = NSP_SalesConstants.ACTIVATED_STATUS;
                        updateOrderItemList.add(orderItemRecord);
                    }

                }
                if (!updateOrderItemList.isEmpty()){
                    Database.SaveResult[] srList = Database.update (updateOrderItemList, false);
                    NSP_ErrorLogHandler.logSaveResult('NSP_RetirementServiceActivationBatch', 'execute', srList);
                }

            }
        } Catch (Exception ex){
            NSP_CustomException.LogException(ex, 'NSP_RetirementServiceActivationBatch');
        }
    }

    public void finish(Database.BatchableContext bc){
    }

}