/* **************************************************************************************************   
Component Name :  NSP_COntractController class
Version              :  1.0                                                                          
Created Date         :  October 10, 2021                                                             
Function             :  This component is used as for New Contract
					 : called from lightning page passing require paramter  	
Story                :                                                                             
Modification Log     :                                                                               
*	Rakesh           October 10, 2021          First Iteration
*
***************************************************************************************************
*/
public class NSP_ContractController {

    @AuraEnabled
    public static Boolean checkValidContractForReProcess(String contractId) {
        Boolean isvalid=false;
        try{
            if(contractId!=null){
                Set<String> subsProductType = new Set<String>();
                 for(SBQQ__Subscription__c subs: [Select Id, SBQQ__RequiredById__c, SBQQ__Product__c, SBQQ__Product__r.NSP_Product_Category__c, SBQQ__Contract__c, SBQQ__Product__r.NSP_Product_Type__c
                                                FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c =: contractId]) {
                   
                    if(subs.SBQQ__RequiredById__c!=null && subs.SBQQ__Product__r.NSP_Product_Category__c!=null){
                        subsProductType.add(subs.SBQQ__Product__r.NSP_Product_Category__c);
                    }
             }
                if(subsProductType.size()>1) {
                    isvalid=true;
                }
            }
        }
        catch(Exception ex){
            throw new AuraHandledException('checkValidContractForReProcess'+ex.getMessage());
      }
         return isvalid;
    }
    
    @AuraEnabled
    public static String callReProcessContract(String contractId) {
        String response;
        try{
            if(contractId!=null){
                NSP_MultipleContractFutureClass.createContractAndReparentSubscriptions(new List<String>{contractId});
                response = 'Success';
            }
        } 
        catch(Exception ex){
            throw new AuraHandledException('callReProcessContract'+ex.getMessage());
      }
        return response;
    }
}