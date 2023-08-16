/***************************************************************************************************
* @Trigger          : NSP_ServicePlanTrigger
* @Author           : Simran
* @Version History  : 1.0
* @Creation         : 5/08/2023
* @Description      : This trigger is on custom Service Plan object
******************************************************************************************************/
trigger NSP_ServicePlanTrigger on NSP_Service_Plan__c (before insert, before update) {
NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
    //run if trigger switch is off
    if(!triggerSwitch.NSP_Service_Plan_Trigger__c){
        NSP_TriggerDispatcher.run(new NSP_ServicePlanTriggerHandler(), 'Service_Plan_Trigger');
    }
}