public without sharing class CancelCoreSalesEventsTasks_Scheduler implements ISelfSchedulable , Schedulable {
    // test w/ CancelCoreSalesEventsTasks_SchedulerTest (100%)

    public void execute( SchedulableContext context ) {
        Database.executeBatch(
            new CancelCoreSalesEventsTasksBatch( null ) ,
            200
        );
    }

    // runs everyday at 3am central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'CancelCoreSalesEventsTasks_Scheduler ~ everyday at 3 AM' + suffix ,
            '0 0 3 ? * * *' ,
            new CancelCoreSalesEventsTasks_Scheduler()
        );
    }

}
//