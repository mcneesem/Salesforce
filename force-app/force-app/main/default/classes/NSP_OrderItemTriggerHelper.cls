/**
* Represents the OrderItem trigger helper which handles all the logic.
*/
public class NSP_OrderItemTriggerHelper{
     /**
    * Iterates throught the list of new OrderItem and passes the required attributes to other methods.
    * @param newList List of New OrderItems.  
    * @return void             
    *                
    */
    
    public void processOrderItemForScholarshipCS(Map<Id, OrderItem> newMap)  {
        Map<Id,boolean> orderItemIdToScholarShipFeeMap = new Map<Id,boolean>();
        for(OrderItem eachItem : newMap.values()) {
            if(eachItem.NSP_IsScholarshipFee_Applicable__c) {
                orderItemIdToScholarShipFeeMap.put(eachItem.Id,eachItem.NSP_Scholarship_Price__c);
            }
        }
        
        // call future method to process consumption schedule
        if(orderItemIdToScholarShipFeeMap.Size() > 0) {
            processConsumptionSchedule(JSON.serialize(orderItemIdToScholarShipFeeMap));
        }
    }
    
    /**
    * Parse the string in to map and then process map to decide which recird to delete
    * @param OrderItemMapStr string of serialize Map.  
    * @return void             
    *                
    */
    @Future
    public static void processConsumptionSchedule(String OrderItemMapStr) {
        Set<Id> usageSummaryDeleteSet = new Set<Id>();
        Set<Id> consumptionScheduleDeleteSet = new Set<Id>();
        Map<Id,boolean> orderItemIdToScholarShipFeeMap = (Map<Id,boolean>) JSON.deserialize(OrderItemMapStr, Map<Id,boolean>.class);
        
        // process map to get two set to delete id.
        for(Id eachOrderItemId : orderItemIdToScholarShipFeeMap.keyset()) {
            if(orderItemIdToScholarShipFeeMap.get(eachOrderItemId)) {
                usageSummaryDeleteSet.add(eachOrderItemId);
            }
            else
            {
                consumptionScheduleDeleteSet.add(eachOrderItemId);
            }
        }
       
        // delete UsageSummary
        //if(usageSummaryDeleteSet.size() > 0) {
           // Delete [SELECT Id from blng__UsageSummary__c WHERE blng__OrderProduct__c IN : usageSummaryDeleteSet AND blng__MatchingAttribute__c = NULL];
        //}
        
        // delete OrderItemConsumptionSchedule of MatchingAttribute Scholarship
        if(consumptionScheduleDeleteSet.Size() > 0 ){
           Delete [SELECT Id FROM SBQQ__OrderItemConsumptionSchedule__c WHERE SBQQ__OrderItem__c IN : consumptionScheduleDeleteSet AND SBQQ__MatchingAttribute__c = 'Scholarship'];
           
        }
        
    }
}