@isTest
public class GenerateRenewalOpportunitiesActionTest {

    @isTest
    static void testLaunchRenewalBatch() {

        GenerateRenewalOpportunitiesAction.MonthYearData input =
            new GenerateRenewalOpportunitiesAction.MonthYearData();

        input.monthValue = 'Jan';
        input.yearValue = '2026';

        List<GenerateRenewalOpportunitiesAction.MonthYearData> inputs =
            new List<GenerateRenewalOpportunitiesAction.MonthYearData>{ input };

        Test.startTest();
        GenerateRenewalOpportunitiesAction.launchRenewalBatch(inputs);
        Test.stopTest();
    }
}