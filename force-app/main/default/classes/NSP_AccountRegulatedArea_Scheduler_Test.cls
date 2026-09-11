@isTest(seeAllData=false)
private class NSP_AccountRegulatedArea_Scheduler_Test
{
    // test w/ NSP_AccountRegulatedArea_Scheduler (100%)

    @isTest
    static void testExecute_ScheduledJob_CompletesWithoutError()
    {
        NSP_AccountRegulatedArea_Scheduler scheduler = new NSP_AccountRegulatedArea_Scheduler();

        Test.startTest();
        String jobId = System.schedule(
            'Test NSP_AccountRegulatedArea_Scheduler',
            '0 0 0 * * ?',
            scheduler
        );
        Test.stopTest();

        System.Assert.isNotNull(
            jobId,
            'Scheduled job ID should not be null after scheduling NSP_AccountRegulatedArea_Scheduler'
        );
    }
}
