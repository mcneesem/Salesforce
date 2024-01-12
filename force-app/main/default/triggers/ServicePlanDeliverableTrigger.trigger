trigger ServicePlanDeliverableTrigger on NSP_Service_Plan_Deliverable__c (before insert, before update, before delete) {
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    if(!triggerSwitch.NSP_Service_Plan_Deliverable_Trigger__c) {
        NSP_TriggerDispatcher.run(new NSP_ServicePlanDeliverableTriggerHandler(), 'Service_Plan_Deliverable_Trigger');
    }
}