@IsTest
public class LaunchRenewalOpportunitiesBatchTest {

    @IsTest
    static void testLaunchRenewalBatch() {

        LaunchRenewalOpportunitiesBatch.MonthYearData input =
            new LaunchRenewalOpportunitiesBatch.MonthYearData();

        input.monthValue = 'Jan';
        input.yearValue = '2026';

        List<LaunchRenewalOpportunitiesBatch.MonthYearData> inputs =
            new List<LaunchRenewalOpportunitiesBatch.MonthYearData>{ input };

        Test.startTest();
        LaunchRenewalOpportunitiesBatch.launchRenewalBatch(inputs);
        Test.stopTest();
    }
}