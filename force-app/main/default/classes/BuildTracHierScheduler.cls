public class BuildTracHierScheduler {
    // test w/ BuildTracHierSchedulerTest (100%)

    // ********************************************************************************************************
    //  MethodName:    runTracHierScheduler
    //  Description :  Method for executing the TracHier.HierarchyLinkerBatch.scheduleRun method provided
    //                 by the Traction Complete managed package
    // 
    //  Params:        cronExpression:      CRON Expression for the schedule frequency
    //                 queryClause:         Custom query clause
    //                 hierIDs:             ID of hierarchies to schedule a run for
    // ********************************************************************************************************

    public static String runTracHierScheduler(String cronExpression, String queryClause, List<String> hierIDs) {
        cronExpression = cronExpression ?? '0 0 9 ? * 6';
        queryClause = queryClause ?? 'dnb_connect_duns_number__c <> null and dnb_parent_duns__c <> null and dnb_global_ultimate_duns__c <> null and dnb_connect_duns_number__c <> \'000000000\' and dnb_parent_duns__c <> \'000000000\' and dnb_global_ultimate_duns__c <> \'000000000\'';
        hierIDs = hierIDs ?? new List<String>{'71a7906ee9f8ddea713b'};
        String result;
        if (!Test.isRunningTest()) {
            result = TracHier.HierarchyLinkerBatch.scheduleRun(cronExpression, queryClause, hierIDs);
        }
        return result;
    }

    public static String schedule() {
        return BuildTracHierScheduler.runTracHierScheduler(null, null, null);
    }

}