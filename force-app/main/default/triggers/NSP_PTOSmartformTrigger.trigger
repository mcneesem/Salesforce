trigger NSP_PTOSmartformTrigger on NSP_PTO_Smartform__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
	NSP_TriggerDispatcher.run(new NSP_PTOSmartformTriggerHandler(), 'NSP_PTO_Smartform_Trigger');
}