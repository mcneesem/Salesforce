/**
 * Represents the Campaign trigger.
 * Created By: Rahul Singh
 * Date:8/10/2022
 */

trigger CampaignTrigger on Campaign (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
 NSP_TriggerDispatcher.run(new NSP_CampaignTriggerHandler(), 'Campaign_Trigger');
}