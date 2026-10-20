@isTest
private class NSP_AccountRegulatedArea_Scheduler_Test {

    @isTest
    private static void testAccountRegulatedBatchScheduler() {
        Test.startTest();
        System.schedule( 'NSP_AccountRegulatedArea_Scheduler ~ TEST' , '0 0 0 ? * * *' , new NSP_AccountRegulatedArea_Scheduler() );
        Test.stopTest();
    }

}
//