public without sharing class NSP_AccountRegulatedArea_Scheduler implements Schedulable {
    // test w/ NSP_AccountRegulatedArea_Scheduler_Test (100%)

    public void execute( SchedulableContext context ) {
        Database.executeBatch(
            new NSP_RegulatedAreaBatch() ,
            2000
        );
    }

    // runs everyday at 12am central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_AccountRegulatedArea_Scheduler ~ When SCC is added to the account and the zip code or city is present in regulated area it will create case and account regulated area ~ everyday at 12 AM' + suffix ,
            '0 0 0 ? * * *' ,
            new NSP_AccountRegulatedArea_Scheduler()
        );
    }

}
//
