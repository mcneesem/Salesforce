global with sharing class MyCallback implements SBQQ.CalculateCallback {
    
    /**
    * Method Name: callback
    * Parameters: String 
    * Return Type: void             
    *                
    */
    global void callback(String quoteJSON){
        
        
        try {      
            //Calling Service API to save price to quote
            SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', quoteJSON);  
            //Variables declaration
            Map<String, Object> n1 = (Map<String, Object>) JSON.deserializeUntyped(quoteJSON);
            //Map<String, Object> qrec = (Map<String, Object>)n1.get('record');
            List<Object> qlnode2 = (List<Object>)n1.get('lineItems');
            List<Object> qlines = new List<Object>();  
            Map<String, Decimal> qliIdToUnitPriceMap = new Map<String, Decimal>();
            //Map<String, Date> qliIdToActivateDateMap = new Map<String, Date>();
            //Loop over the first level nodes
            for (Object ql : qlnode2) {
                Map<String, Object> qli = (Map<String, Object>)ql;   
                qlines.add(qli.get('record'));
            }
            //Loop over quote lines within quote node
            for (Object qlrec : qlines) {   
                Map<String, Object> qlirec = (Map<String, Object>)qlrec;
                qliIdToUnitPriceMap.put((String)qlirec.get('Id'),(Decimal)qlirec.get('SBQQ__NetPrice__c'));        
            }
            //querying order items to update
            List<OrderItem> orderLinesToUpdate = new List<OrderItem>();
            for (OrderItem op : [SELECT Id, NSP_ReCalculation_Status_Internal__c, UnitPriceForceOverride__c,NSP_Override_Start_Date__c,SBQQ__QuoteLine__c FROM OrderItem WHERE NSP_ReCalculation_Status_Internal__c = 'Processing' AND SBQQ__QuoteLine__c IN:qliIdToUnitPriceMap.keyset()  ]) {
                op.NSP_ReCalculation_Status_Internal__c = 'Complete';
                op.UnitPriceForceOverride__c = qliIdToUnitPriceMap.get(op.SBQQ__QuoteLine__c);
                orderLinesToUpdate.add(op);
            }
            if(orderLinesToUpdate.size()>0){ 
                update orderLinesToUpdate;
                for(OrderItem op : orderLinesToUpdate) { op.SBQQ__Activated__c = true; }
                update orderLinesToUpdate;
            }
        } catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('MyCallback','callback',ex.getMessage());
        }
    }
}