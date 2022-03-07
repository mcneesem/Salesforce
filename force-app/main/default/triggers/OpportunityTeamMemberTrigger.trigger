/**
 * Represents the OpportunityTeamMemberTrigger trigger.
 */
trigger OpportunityTeamMemberTrigger on OpportunityTeamMember (after insert,after update) {
	NSP_TriggerDispatcher.run(new NSP_OpportunityTeamMemberTriggerHandler(), 'OpportunityTeamMember_Trigger');
}