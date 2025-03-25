public with sharing class AssetMismatchSyncUp {
    // test w/ NSP_OrderItemTriggerHelperTest (76%)
    
        // STY-341702

                /**
* Method Name : assetOrderProductLinkUp 
* Description : Method to link asset and order product2822
* Author : CPQ Team     Date : 03/17/2025

* @param set orderId  
* @return void  
*/
    @InvocableMethod(label='Link Asset Mismatch' description='links all mismatched assets.' category='Asset')
    public static void assetOrderProductLinkUp(List<String> orderId){
        
        List<OrderItem> orditems = [SELECT Id,Mismatch_AssetId__c 
                                  FROM OrderItem 
                                  WHERE orderid IN:OrderId AND Mismatch_AssetId__c != null];
        List<OrderItem> ordItemsToBeUpdated = new List<OrderItem>();
        List<Order> ordsTobeUpdated = new List<Order>();
        
        Map<String,String> mapOpAst = new Map<String,String>();
		
		if(!orditems.isempty())
        {
             for(OrderItem oi:orditems)
            {
                mapOpAst.put(oi.Mismatch_AssetId__c,oi.Id);
                oi.Mismatch_AssetId__c = '';
                ordItemsToBeUpdated.add(oi);
            }
        }

            
        List<Asset> assetLst = [SELECT Id,NSP_OrderProduct__c 
                                FROM Asset 
                                WHERE Id IN:mapOpAst.keyset()];
        
        List<Asset> asstsUpdated = new List<Asset>();
        if(!assetLst.isempty())
        {
            for(Asset ast:assetLst)
            {
                Asset asst = new Asset();
                asst.Id = ast.Id;
                asst.NSP_OrderProduct__c =  mapOpAst.get(asst.Id);
                asstsUpdated.add(asst);
            }  
        }
       
        try{
            
           if(!asstsUpdated.isempty())
           {
               Database.update(asstsUpdated);
           }
            
            List<Order> ords = [SELECT Id,Mismatch_Asset__c
                                FROM Order 
                                WHERE Id IN:OrderId  AND Mismatch_Asset__c = true];
        
           if(!ords.isempty())
           {
               for(Order ord:ords)
               {
                   ord.Mismatch_Asset__c =false;
                   ordsTobeUpdated.add(ord);
               }
           }

           if(!ordItemsToBeUpdated.IsEmpty() && !ordsTobeUpdated.IsEmpty())
           {
                Database.update(ordItemsToBeUpdated);
                Database.update(ordsTobeUpdated);
           }

           
        }
        catch(Exception ex)
        {
             NSP_ErrorLogHandler.logException(
                AssetMismatchSyncUp.class.getName() ,
                    'assetOrderProductLinkUp ' ,
                    ex
                );
        }
    }
}