@isTest
private class PriceRuleLoggerTest {

    @IsTest
    private static void testLogPriceRules() {
        // Create test data
        SBQQ__PriceRule__c priceRule = new SBQQ__PriceRule__c();
        priceRule.SBQQ__Active__c = true;
        priceRule.SBQQ__ConditionsMet__c = 'All';
        priceRule.SBQQ__EvaluationEvent__c = 'Always';
        priceRule.SBQQ__TargetObject__c = 'Calculator';
        priceRule.Name = 'Test Price Rule';
        insert priceRule;

        // Create test input
        PriceRuleLogger.RuleIdInput input = new PriceRuleLogger.RuleIdInput();
        input.ruleId = priceRule.Id;

        // Call the method to test
        Test.startTest();
        List<PriceRuleLogger.RulesLoggedOutput> outputList = PriceRuleLogger.logPriceRules(new List<PriceRuleLogger.RuleIdInput>{input});
        Test.stopTest();

        // Verify the results
        System.assertEquals(1, outputList.size()); 
        System.assertEquals(1, outputList[0].rulesLogged);
    }

}
//