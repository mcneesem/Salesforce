@isTest
private class GenerateRenewalOpportunitiesActionTest {

    @isTest
    private static void testLaunchRenewalBatch() {
        GenerateRenewalOpportunitiesAction.MonthYearData input = new GenerateRenewalOpportunitiesAction.MonthYearData();
        input.monthValue = 'Jan';
        input.yearValue = 2026;
        List<GenerateRenewalOpportunitiesAction.MonthYearData> inputs = new List<GenerateRenewalOpportunitiesAction.MonthYearData>{ input };
        Test.startTest();
        GenerateRenewalOpportunitiesAction.invoke(inputs);
        Test.stopTest();
    }

}
//