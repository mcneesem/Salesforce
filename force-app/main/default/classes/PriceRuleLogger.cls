public with sharing class PriceRuleLogger {
    // test w/ PriceRuleLoggerTest (85%)
    
    public class RuleIdInput{
        @InvocableVariable(required = false)
        public Id ruleId;
    }
    
    public class RulesLoggedOutput{
        @InvocableVariable
        public Integer rulesLogged;
    }
    
    //price action formula structure
    //*DO NOT MODIFY*
    private static final List<String> formulaTemplate = new List<String>
    {
		'IF(OR(BEGINS(Price_Rule_Log__c,"',
		',"),CONTAINS(Price_Rule_Log__c,",',
		',")),Price_Rule_Log__c,NULLVALUE(Price_Rule_Log__c,"") & "',
		',")'
    };
    
    @InvocableMethod
    public static List<RulesLoggedOutput> logPriceRules(List<RuleIdInput> inputList){
        //provide output to the flow
        List<RulesLoggedOutput> outputList = new List<RulesLoggedOutput>();
        Integer actionsInserted = 0;
        
        //lists of price rules
        List<Id> ruleIds = new List<Id>();        

        //handle flow input
        if( ( inputList != null ) && !inputList.isEmpty() ){
            for(RuleIdInput input : inputList){
                if(input.ruleId != null){
                    ruleIds.add(input.ruleId);
                }
            } 
        }
        
        //perform query to fetch applicable records
        Map<id,SBQQ__PriceRule__c> priceRulesMap = new Map<id,SBQQ__PriceRule__c>((List<SBQQ__PriceRule__c>)Database.query(generateQuery(ruleIds)));
        
        //update number field on price rules
		List<SBQQ__PriceRule__c> priceRulesToUpdate = PriceRuleLogger.updatePriceRuleNum( priceRulesMap );
        
        //perform updates
        if(priceRulesToUpdate.size()>0){
            try{
                //price rule dml
                update priceRulesToUpdate;
                
                //insert price actions for the rules
                actionsInserted = insertActions(priceRulesToUpdate);
            }catch(exception e){
                logException(e,'logPriceRules');
            }
        }
        //return output to flow
        RulesLoggedOutput output = new RulesLoggedOutput();
        output.rulesLogged = actionsInserted;
        outputList.add(output);
        return outputList;
    }
    
    //method to return query based on input size
    private static String generateQuery(List<Id> ruleIds){
        //query structure
        String queryBase = 'SELECT id, Price_Rule_Number__c, (SELECT id FROM SBQQ__PriceActions__r WHERE SBQQ__Field__c = \'Price_Rule_Log__c\') FROM SBQQ__PriceRule__c';
        String queryCondition = ' ';
        String queryOrder = 'order by Name';
        
        if(
            ( ruleIds != null ) 
            && ( ruleIds.isEmpty() )
        ){
            //fetch all price rules when input is empty
            queryCondition = ' where SBQQ__TargetObject__c = \'Calculator\' ';
        }else{
            //fetch only single rule based on input
            queryCondition = ' where (SBQQ__TargetObject__c = \'Calculator\' AND Id IN :ruleIds) ';
        }
        return queryBase + queryCondition + queryOrder;
    }
    
    //method to update number field on price rules
    private static List<SBQQ__PriceRule__c> updatePriceRuleNum( Map<id,SBQQ__PriceRule__c> priceRulesMap ){
        List<SBQQ__PriceRule__c> priceRulesToUpdate = new List<SBQQ__PriceRule__c>();
        if(priceRulesMap != null){
            Decimal maxPriceRuleNum = getMaxNumber();
            for(SBQQ__PriceRule__c priceRule: priceRulesMap.values())
            {
                if(priceRule.SBQQ__PriceActions__r.isEmpty()){
                    if(priceRule.Price_Rule_Number__c == null){
                        priceRule.Price_Rule_Number__c = maxPriceRuleNum;
                        maxPriceRuleNum = maxPriceRuleNum + 1;   
                    }
                    priceRulesToUpdate.add(priceRule);
                }
            }
        }
        return priceRulesToUpdate;
    }
    
    //get max number from existing price rules
    private static Decimal getMaxNumber(){
        Decimal maxNum = 1;
        AggregateResult result = [SELECT MAX(Price_Rule_Number__c)maxNumber FROM SBQQ__PriceRule__c];
        if(
            ( result != null ) 
            && ( result.get('maxNumber') != null )
        ){
            maxNum = (Decimal)result.get('maxNumber') + 1;
        }
        return maxNum;
    }
    
    //method to insert price actions
    private static Integer insertActions(List<SBQQ__PriceRule__c> priceRules){
        //output of total actions inserted
        Integer outputActionCount = 0;
        
        //insert list
        List<SBQQ__PriceAction__c> insertList = new List<SBQQ__PriceAction__c>();
        
        if( priceRules!= null && !priceRules.isEmpty()){
            //create actions for each rule
            for(SBQQ__PriceRule__c rule: priceRules){
                if( rule.Price_Rule_Number__c != null ){
                    Integer num = (Integer)rule.Price_Rule_Number__c;
                    SBQQ__PriceAction__c action = new SBQQ__PriceAction__c();
                    action.SBQQ__TargetObject__c = 'Quote Line';
                    action.SBQQ__Field__c = 'Price_Rule_Log__c';
                    //insert PR num between template Strings to construct formula
                    action.SBQQ__Formula__c = String.join(formulaTemplate,String.valueOf(num));
                    action.SBQQ__Rule__c = rule.id;
                    insertList.add(action);
                }
            }
        }
        
        //insert actions
        if(insertList.size()>0){
            try{
                insert insertList;
                outputActionCount = insertList.size();
            }catch(exception e){
                logException(e,'insertActions');
            }
        }
        
        //return insert list size
        return outputActionCount;
    }
    
    //method to log exceptions in two dml operations
    private static void logException(Exception e, String methodName){
        NSP_ErrorLogHandler.logException(
            PriceRuleLogger.class.getName() ,
            methodName ,
            e
        );
    }
}