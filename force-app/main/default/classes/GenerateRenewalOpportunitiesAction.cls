public with sharing class GenerateRenewalOpportunitiesAction {
    // test w/ GenerateRenewalOpportunitiesActionTest(100%)

    @InvocableMethod(label='Generate Renewal Opportunities' description='Launch Renewals Batch and pass Month and Year values selected in Flow')
    public static void invoke( List<MonthYearData> inputs ) {
        if ( ( inputs != null ) && !inputs.isEmpty() ) {
            for ( MonthYearData input : inputs ) {
                if ( ( input != null )
                    && String.isNotBlank( input.monthValue )
                    && monthMap.containsKey( input.monthValue )
                    && ( monthMap.get( input.monthValue ) != null )
                    )
                {
                    GenerateRenewalOpportunitiesJob.executeBatch(
                        monthMap.get( input.monthValue ) ,
                        input.yearValue
                    );
                }
            }
        }
    }

    public class MonthYearData {
        @InvocableVariable(label='Month Value' required=true)
        public String monthValue;
        @InvocableVariable(label='Year Value' required=true)
        public Integer yearValue;
    }

    private static final Map<String,Integer> monthMap = new Map<String,Integer>{
        'Jan' => 1 ,
        'Feb' => 2 ,
        'Mar' => 3 ,
        'Apr' => 4 ,
        'May' => 5 ,
        'Jun' => 6 ,
        'Jul' => 7 ,
        'Aug' => 8 ,
        'Sep' => 9 ,
        'Oct' => 10 ,
        'Nov' => 11 ,
        'Dec' => 12
    };

}
//