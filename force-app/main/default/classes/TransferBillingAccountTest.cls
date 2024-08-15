@isTest private class TransferBillingAccountTest {

    @isTest private static void doTest() {
        TransferBillingAccount.FlowInputs flowInputA = new TransferBillingAccount.FlowInputs();
        flowInputA.previousmonthaccountname = 'testAccountNameA';
        flowInputA.CurrentMonthAccountId = '0017f00000vQ4k5AAA';

        TransferBillingAccount.FlowInputs flowInputB = new TransferBillingAccount.FlowInputs();
        flowInputB.previousmonthaccountname = 'testAccountNameB';
        flowInputB.CurrentMonthAccountId = '0017f00000vQ4k5BBB';

        List<TransferBillingAccount.FlowInputs> listOfFlowInputs = new List<TransferBillingAccount.FlowInputs>();
        listOfFlowInputs.add(flowInputA);
        listOfFlowInputs.add(flowInputB);

        Test.startTest();
        TransferBillingAccount.transfer(listOfFlowInputs);
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'BatchApex'];
        System.assertEquals(1, jobs.size(), 'One batch job should have been enqueued.');
        System.assertEquals('Completed', jobs[0].Status, 'The batch job should be in Holding status.');
    }

}