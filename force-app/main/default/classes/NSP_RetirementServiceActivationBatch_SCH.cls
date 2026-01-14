public class NSP_RetirementServiceActivationBatch_SCH implements Schedulable {
    // test w/ NSP_RetirementServiceActivationBatchTest (100%)

    // DEPRECATED
    public void execute( SchedulableContext sc ) {
        NSP_RetirementServiceActivationBatch helper = new NSP_RetirementServiceActivationBatch();
        helper.run();
    }

}
//