trigger NSP_TerminationFormTrigger on NSP_Termination_Form__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    NSP_TriggerDispatcher.run(new NSP_TerminationFormTriggerHandler(), 'TerminationForm_Trigger');
}