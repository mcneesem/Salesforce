public class GenerateRenewalOpportunitiesAction {
// test w/ GenerateRenewalOpportunitiesActionTest(100%)

    public class MonthYearData {
        @InvocableVariable(label='Month Value' required=true)
        public string monthValue;

        @InvocableVariable(label='Year Value' required=true)
        public string yearValue;
    }

    @InvocableMethod(label = 'Launch Renewals Batch')
    public static void launchRenewalBatch(List<MonthYearData> monthYearValue) {

        if ( monthYearValue != null && !monthYearValue.isEmpty() ){
            MonthYearData input = monthYearValue[0];

            Map<String, Integer> monthMap = new Map<String, Integer>{
                'Jan' => 1,
                'Feb' => 2,
                'Mar' => 3,
                'Apr' => 4,
                'May' => 5,
                'Jun' => 6,
                'Jul' => 7,
                'Aug' => 8,
                'Sep' => 9,
                'Oct' => 10,
                'Nov' => 11,
                'Dec' => 12
            };

            Integer monthNumber = monthMap.get(input.monthValue);
            Integer yearNumber = Integer.valueOf(input.yearValue);

            GenerateRenewalOpportunitiesJob batchJob = new GenerateRenewalOpportunitiesJob(monthNumber, yearNumber);
            Database.executeBatch(batchJob, 50);
        }

    }
}