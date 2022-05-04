trigger UserTrigger on User (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
 //Calling Trigger Dispatcher
 NSP_TriggerDispatcher.run(new NSP_UserTriggerHandler(), 'User_Trigger');
}