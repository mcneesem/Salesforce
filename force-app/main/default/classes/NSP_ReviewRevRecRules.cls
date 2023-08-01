public class NSP_ReviewRevRecRules {
    private NSP_ReviewRevRecRules(){}

    static final string ADD_PRODUCT = 'Add Product';
    static final string ANNUAL = 'Annual';
    static final string MONTHLY = 'Monthly';
    static final string RENEWAL = 'Renewal';

@InvocableMethod(label='Review Rev Rec Rules' description='Override Rev Rec Rules')
public static void overrideRevRecRules(List<String> records){
    //system.debug('review rev rec called');
    List<String> amendVal= new List<String>{'Amend/Upsell','Amend/Downgrade','Upsell','Downgrade'};
    List<OrderItem> orderItemsToUpdate= new List<OrderItem>();
    Map<String,Id> revRecRulesMap=retrieveRevRecRules();
    Map<String,NSP_Revenue_Distribution_Scenario__c> rulesTableMap=retrievRulesTable();
    List<OrderItem> orderLines= [SELECT Id,OrderId,Order.NSP_Project_Name__c,Order.Type,blng__RevenueRecognitionRule__c,blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c,NSP_Revenue_Recognition_Rule_Credit__c,SBQQ__BillingFrequency__c,Product2.SBQQ__BillingFrequency__c,NSP_Action_Type__c,NSP_QL_ActionType__c,Product2Id
                                    FROM OrderItem 
                                    WHERE OrderId IN :records];
    for(OrderItem oitem :orderLines){
        String key=oitem.blng__RevenueRecognitionRule__c+'_'+oitem.Product2Id;
        if(rulesTableMap.get(key)!=null && oitem.Product2Id==rulesTableMap.get(key).NSP_Product__c && oitem.blng__RevenueRecognitionRule__c==rulesTableMap.get(key).NSP_Primary_Rev_Rec_Rule__c){
            if(oitem.blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c=='Project Rev Rec'){
                if((oitem.Order.Type=='New Product'||oitem.NSP_QL_ActionType__c==ADD_PRODUCT||(oitem.Order.Type==RENEWAL &&oitem.NSP_Action_Type__c==ADD_PRODUCT))&& oitem.Product2.SBQQ__BillingFrequency__c==MONTHLY && oitem.SBQQ__BillingFrequency__c==ANNUAL && rulesTableMap.get(key).NSP_Project_Rev_Rec_Rule12_Inv__c!=null){
                    OrderItem op= new OrderItem(Id=oitem.Id);
                    op.blng__RevenueRecognitionRule__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_Project_Rev_Rec_Rule12_Inv__c);
                    op.NSP_Revenue_Recognition_Rule_Credit__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_Project_Rev_Rec_Rule12_Cred__c);
                    orderItemsToUpdate.add(op);
                }
                else if((oitem.NSP_Action_Type__c==RENEWAL ||amendVal.contains(oitem.NSP_QL_ActionType__c)) && oitem.Product2.SBQQ__BillingFrequency__c==MONTHLY && oitem.SBQQ__BillingFrequency__c==ANNUAL && rulesTableMap.get(key).NSP_X12_Month_Rule_Inv__c!=null){
                    OrderItem op= new OrderItem(Id=oitem.Id);
                    op.blng__RevenueRecognitionRule__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_X12_Month_Rule_Inv__c);
                    op.NSP_Revenue_Recognition_Rule_Credit__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_X12_Month_Rule_Cred__c);
                    orderItemsToUpdate.add(op); 
                }
                else if(oitem.OrderId!=null && oitem.Order.NSP_Project_Name__c==null && rulesTableMap.get(key).NSP_Immediate_Rule_Inv__c!=null){
                    OrderItem op= new OrderItem(Id=oitem.Id);
                    op.blng__RevenueRecognitionRule__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_Immediate_Rule_Inv__c);
                    op.NSP_Revenue_Recognition_Rule_Credit__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_Immediate_Rule_Cred__c);
                    orderItemsToUpdate.add(op);
                }
            }
            else if(oitem.blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c=='12 Delay 1' && (oitem.NSP_Action_Type__c==RENEWAL ||amendVal.contains(oitem.NSP_QL_ActionType__c)) && rulesTableMap.get(key).NSP_X12_Month_Rule_Inv__c!=null){
                OrderItem op= new OrderItem(Id=oitem.Id);
                op.blng__RevenueRecognitionRule__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_X12_Month_Rule_Inv__c);
                op.NSP_Revenue_Recognition_Rule_Credit__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_X12_Month_Rule_Cred__c);
                orderItemsToUpdate.add(op);
            }
            else if(oitem.blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c=='12 Month' && oitem.Product2.SBQQ__BillingFrequency__c==ANNUAL && oitem.SBQQ__BillingFrequency__c==MONTHLY && rulesTableMap.get(key).NSP_Immediate_Rule_Inv__c!=null){
                OrderItem op= new OrderItem(Id=oitem.Id);
                op.blng__RevenueRecognitionRule__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_Immediate_Rule_Inv__c);
                op.NSP_Revenue_Recognition_Rule_Credit__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_Immediate_Rule_Cred__c);
                orderItemsToUpdate.add(op);
            }
            else if(oitem.blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c=='Immediate'){
                if((oitem.Order.Type=='New Product'||oitem.NSP_QL_ActionType__c==ADD_PRODUCT||(oitem.Order.Type==RENEWAL &&oitem.NSP_Action_Type__c==ADD_PRODUCT))&& oitem.Product2.SBQQ__BillingFrequency__c==MONTHLY && oitem.SBQQ__BillingFrequency__c==ANNUAL && rulesTableMap.get(key).NSP_Project_Rev_Rec_Rule12_Inv__c!=null){
                    OrderItem op= new OrderItem(Id=oitem.Id);
                    op.blng__RevenueRecognitionRule__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_Project_Rev_Rec_Rule12_Inv__c);
                    op.NSP_Revenue_Recognition_Rule_Credit__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_Project_Rev_Rec_Rule12_Cred__c);
                    orderItemsToUpdate.add(op);
                }
                else if((oitem.NSP_Action_Type__c==RENEWAL ||amendVal.contains(oitem.NSP_QL_ActionType__c)) && oitem.Product2.SBQQ__BillingFrequency__c==MONTHLY && oitem.SBQQ__BillingFrequency__c==ANNUAL && rulesTableMap.get(key).NSP_X12_Month_Rule_Inv__c!=null){
                    OrderItem op= new OrderItem(Id=oitem.Id);
                    op.blng__RevenueRecognitionRule__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_X12_Month_Rule_Inv__c);
                    op.NSP_Revenue_Recognition_Rule_Credit__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_X12_Month_Rule_Cred__c);
                    orderItemsToUpdate.add(op); 
                }
                else if(oitem.OrderId!=null && oitem.Order.NSP_Project_Name__c!=null && rulesTableMap.get(key).NSP_Project_Rev_Rec_Rule_Inv__c!=null){
                    OrderItem op= new OrderItem(Id=oitem.Id);
                    op.blng__RevenueRecognitionRule__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_Project_Rev_Rec_Rule_Inv__c);
                    op.NSP_Revenue_Recognition_Rule_Credit__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_Project_Rev_Rec_Rule_Cred__c);
                    orderItemsToUpdate.add(op);
                }
            }
            else if(oitem.blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c=='Project Rev Rec 12'){
                if(oitem.Product2.SBQQ__BillingFrequency__c==ANNUAL && oitem.SBQQ__BillingFrequency__c==MONTHLY && rulesTableMap.get(key).NSP_Immediate_Rule_Inv__c!=null){
                    OrderItem op= new OrderItem(Id=oitem.Id);
                    op.blng__RevenueRecognitionRule__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_Immediate_Rule_Inv__c);
                    op.NSP_Revenue_Recognition_Rule_Credit__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_Immediate_Rule_Cred__c);
                    orderItemsToUpdate.add(op);
                }
                else if(oitem.NSP_Action_Type__c==RENEWAL ||amendVal.contains(oitem.NSP_QL_ActionType__c) && rulesTableMap.get(key).NSP_X12_Month_Rule_Inv__c!=null){
                    OrderItem op= new OrderItem(Id=oitem.Id);
                    op.blng__RevenueRecognitionRule__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_X12_Month_Rule_Inv__c);
                    op.NSP_Revenue_Recognition_Rule_Credit__c=revRecRulesMap.get(rulesTableMap.get(key).NSP_X12_Month_Rule_Cred__c);
                    orderItemsToUpdate.add(op); 
                }
            }
        }
    }
    if(orderItemsToUpdate.size()>0){
        update orderItemsToUpdate;
    }
}
private static Map<String,Id> retrieveRevRecRules(){
    Map<String,Id> revRecRulesMap= new Map<String,Id>();
    List<blng__RevenueRecognitionRule__c> revRecRules=[Select Id,blng__Active__c,Name FROM blng__RevenueRecognitionRule__c WHERE blng__Active__c=TRUE];
    for(blng__RevenueRecognitionRule__c rule:revRecRules){
        revRecRulesMap.put(rule.Name,rule.Id);
    }
    return revRecRulesMap;
}
private static Map<String,NSP_Revenue_Distribution_Scenario__c> retrievRulesTable(){
    Map<String,NSP_Revenue_Distribution_Scenario__c> rulesTableMap= new Map<String,NSP_Revenue_Distribution_Scenario__c>();
    List<NSP_Revenue_Distribution_Scenario__c> rulesTable=[SELECT Id,NSP_Primary_Rev_Rec_Rule__c,NSP_Product__c,NSP_X12_Delay_1Rule_Cred__c,NSP_X12_Delay_1Rule_Inv__c,NSP_X12_Month_Rule_Cred__c,NSP_X12_Month_Rule_Inv__c,NSP_Immediate_Rule_Cred__c,
                                                            NSP_Immediate_Rule_Inv__c,NSP_Project_Rev_Rec_Rule_Cred__c,NSP_Project_Rev_Rec_Rule_Inv__c,NSP_Project_Rev_Rec_Rule12_Cred__c,NSP_Project_Rev_Rec_Rule12_Inv__c,NSP_Primary_Rule_Prod_Key__c
                                                            FROM NSP_Revenue_Distribution_Scenario__c];
    for(NSP_Revenue_Distribution_Scenario__c rule:rulesTable){
        rulesTableMap.put(rule.NSP_Primary_Rule_Prod_Key__c,rule);
    }
    return rulesTableMap;
}
}