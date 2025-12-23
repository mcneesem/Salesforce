public class NSP_ContractRenewal_Scheduler implements Schedulable {
    // test w/ NSP_ContractRenewal_Scheduler_Test (100%)

    // DEPRECATED
    public void execute( SchedulableContext sc ) {
        NSP_ContractRenewal_Batch helper = new NSP_ContractRenewal_Batch();
        helper.run();
    }

}
//