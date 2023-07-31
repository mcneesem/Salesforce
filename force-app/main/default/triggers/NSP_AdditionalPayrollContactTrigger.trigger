/**
 * Represents the Additional Payroll Contact trigger.
 */
trigger NSP_AdditionalPayrollContactTrigger on Additional_Payroll_Contact__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    NSP_TriggerDispatcher.run(new NSP_AdditionalPayrollContactHandler(), 'AdditionalPayrollContact_Trigger');
}