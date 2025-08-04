public class AutomateOpportunityStageQueueable implements Queueable {
    // test w/ AutomateOpportunityStageTest (100%)
    private List<Id> autoStageOppIds;

    public AutomateOpportunityStageQueueable(List<Id> autoStageOppIds) {
        this.autoStageOppIds = autoStageOppIds;
    }

    public void execute(QueueableContext context) {
        if ( ( autoStageOppIds != null ) && !autoStageOppIds.isEmpty() ) {
            AutomateOpportunityStage.automateOpportunityStage( autoStageOppIds );
        }
    }
}