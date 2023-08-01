/**
* @description  : Class to generate order from Opportunity
* @author Rakesh Das
* @date 03/20/2023
* Name : NSP_GenerateOrderFromOpportunity
*/

public class NSP_GenerateOrderFromOpportunity {
    private NSP_GenerateOrderFromOpportunity(){}
    private static final String CLOSED_LOST_STAGE = 'Closed Lost';
    private static final String CLOSED_WON_STAGE = 'Closed Won';
    private static final String SUBMITTED_TO_ORDER = 'Submitted To Order';
    private static final String STATUS_ACTIVATED = 'Activated';
    private static final String ORDER_CREATION = 'NSP_OrderCreation';
    private static final String CONTRACT_CREATION = 'NSP_ContractCreation';
    /**
* Method for generating orders from quote using CPQ Ordered checkbox
* Called from Platform Event Trigger
* Moves the Quote to Submitted to order state and enables ordered flag
* @param  List of Opportunity ids from event. 
*/
    public static void orderQuoteOnOpptyCloseWon(List < String > closedOpptyIds) {
        
        List<SBQQ__Quote__c> quotesToOrder = new List<SBQQ__Quote__c>(); 
        boolean createOrder = true;
        Map<String,NSP_AutomationSetting__mdt> autoMationSettingMap = NSP_AutomationSetting__mdt.getAll();
        if (closedOpptyIds != null)  {
            // logic to bypass order creation
            if(autoMationSettingMap.containsKey(ORDER_CREATION) && autoMationSettingMap.get(ORDER_CREATION).NSP_Disable__c){
                createOrder = false;
            }
            
            if(createOrder || Test.isrunningTest()){
                for (SBQQ__Quote__c qt : [SELECT Id, SBQQ__Status__c, SBQQ__Ordered__c, SBQQ__Primary__c, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.StageName 
                                          FROM SBQQ__Quote__c
                                          WHERE SBQQ__Status__c !=: SUBMITTED_TO_ORDER AND SBQQ__Primary__c=TRUE AND SBQQ__Ordered__c = FALSE
                                          AND SBQQ__Opportunity2__c!=null AND SBQQ__Opportunity2__r.StageName =:CLOSED_WON_STAGE AND SBQQ__Opportunity2__c IN : closedOpptyIds]) {
                                              qt.SBQQ__Ordered__c = TRUE;
                                              qt.SBQQ__Status__c = SUBMITTED_TO_ORDER;
                                              quotesToOrder.add(qt);                
                                          }
            }
        }
        
        if(quotesToOrder.size()>0){
            Savepoint orderSP = Database.setSavepoint(); //in case of exception the order cretaion should roll back
            try {
                Database.update(quotesToOrder);
            } catch (Exception ex){
                Database.rollback(orderSP);
                NSP_CustomException.LogException(ex);
            }
        }
    }
    
        /**
* Method for generating contracts from orders using CPQ Contracted checkbox
* Called from Platform Event Trigger
* Creates Contracts using the CPQ Contracted checkbox
* @param  List of order ids from event. 
*/
    public static void createContractOnOrderActivation(List < String > activatedOrderIds) {
        
          List<Order> ordersToContract = new List<Order>(); 
        boolean createContract = true;
        NSP_AutomationSetting__mdt contractGenerationDisabled = NSP_AutomationSetting__mdt.getInstance(CONTRACT_CREATION);
        if (activatedOrderIds != null)  {
            // logic to bypass order creation
            if(contractGenerationDisabled.NSP_Disable__c){
                createContract = false;
            }
            
            if(createContract || Test.isrunningTest()){
                for (Order ord : [SELECT Id, Status, SBQQ__Contracted__c 
                                          FROM Order
                                          WHERE Status = : STATUS_ACTIVATED AND SBQQ__Contracted__c = FALSE
                                          AND Id IN : activatedOrderIds]) {
                                              ord.SBQQ__Contracted__c = TRUE;
                                              ordersToContract.add(ord);                
                                          }
            }
        }
        
        if(ordersToContract.size()>0){
            Savepoint contractSP = Database.setSavepoint(); //in case of exception the order cretaion should roll back
            try {
                Database.update(ordersToContract);
            } catch (Exception ex){
                Database.rollback(contractSP);
                NSP_CustomException.LogException(ex);
            }
        }
    }
    
}