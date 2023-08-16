/**************************************************************************************************   
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :   This class is invoked from Flow, 
* it will group the serial Ids of support products 
* and stamp them on correpsonding QLines.
Test class           :  NSP_ProcessSerialIds
Story                :                                                                             
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* -------------------------------------------------------------------------------------------------  

*	Samba Raju                    First Iteration
*
***************************************************************************************************/
public class NSP_ProcessSerialIds {
    private NSP_ProcessSerialIds(){}

    @InvocableMethod(label='Update Serial Ids' description='Update Serial Ids On Quote Line')
    public static void updateSerialIdsOnQuoteLines(List<InputVariables> inputVariables){
        Map<String,List<String>> supportMapWithSerialIds= new Map<String,List<String>>();
        List<SBQQ__QuoteLine__c> quoteLinesToUpdate= new List<SBQQ__QuoteLine__c>();
        
        //Get the inputs
        String quote=inputVariables.get(0).quoteId;
        List<NSP_Support_Entitlement__c> selectedProds=inputVariables.get(0).selectedEntitlements;
        for(NSP_Support_Entitlement__c entitlement:selectedProds){
            if(!supportMapWithSerialIds.containsKey(entitlement.NSP_Support_Product__c)){
                supportMapWithSerialIds.put(entitlement.NSP_Support_Product__c,new List<String>{entitlement.NSP_Serial_ID__c});
            }
            else{
                supportMapWithSerialIds.get(entitlement.NSP_Support_Product__c).add(entitlement.NSP_Serial_ID__c);
            }
        }
        for(SBQQ__QuoteLine__c qLine:[SELECT Id,SBQQ__Quote__r.SBQQ__Type__c,NSP_Serial_Ids__c,NSP_ActionType__c,SBQQ__Product__r.ProductCode,NSP_Original_Line__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=:quote]){
            if(qLine.SBQQ__Quote__r.SBQQ__Type__c==NSP_CPQConstants.QUOTE_TYPE_RENEWAL && supportMapWithSerialIds.get(qLine.SBQQ__Product__r.ProductCode)!=null){
                String serialIds = String.join( supportMapWithSerialIds.get(qLine.SBQQ__Product__r.ProductCode), ',' );  
                qLine.NSP_Serial_Ids__c=serialIds;
                quoteLinesToUpdate.add(qLine);
            }
            else if(qLine.SBQQ__Quote__r.SBQQ__Type__c==NSP_CPQConstants.QUOTE_TYPE_AMENDMENT && (qLine.NSP_ActionType__c==NSP_CPQConstants.ACTION_DOWNGRADE ||qLine.NSP_ActionType__c==NSP_CPQConstants.ACTION_UPSELL) && supportMapWithSerialIds.get(qLine.SBQQ__Product__r.ProductCode)!=null){
                String joinedIds = String.join( supportMapWithSerialIds.get(qLine.SBQQ__Product__r.ProductCode), ',' );  
                qLine.NSP_Serial_Ids__c=joinedIds;
                quoteLinesToUpdate.add(qLine);
            }
        }
        if(quoteLinesToUpdate.size()>0){
            List<Database.SaveResult> results = Database.update(quoteLinesToUpdate,false);
            NSP_ErrorLogHandler.logSaveResultsException('NSP_ProcessSerialIds','updateSerialIdsOnQuoteLines', results);
        }
    }
    public class InputVariables{
        @InvocableVariable
        public String quoteId;
        
        @InvocableVariable
        public List<NSP_Support_Entitlement__c> selectedEntitlements;
    }
    
}