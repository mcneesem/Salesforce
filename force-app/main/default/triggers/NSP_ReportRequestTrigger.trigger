trigger NSP_ReportRequestTrigger on NSP_ReportRequest__c (before insert, after insert, before update, before delete, after update) {
    NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
  //run if trigger switch is off
  if(!triggerSwitch.ReportRequestTrigger__c){
    NSP_TriggerDispatcher.run(new NSP_ReportRequestTriggerHandler(), 'ReportRequest_Trigger');
  }
}