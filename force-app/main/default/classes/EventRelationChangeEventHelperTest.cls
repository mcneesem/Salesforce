@isTest private without sharing class EventRelationChangeEventHelperTest {

    @testSetup private static void setupTestData(){
        User tUser =  NSP_TestHelper.createUser(false);
        tUser.Phone = '(112)6475261 ext495';
        tUser.Username = 'jroytest99@test.com.abc'+System.currentTimeMillis();
        tUser.NSP_Service_Region__c = 'MMSO - Southeast';
        tUser.NSP_Salesforce_Field_Service__c = NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_DISPATCHER_RESOURCE;
        tUser.NSP_Dispatch_Region__c = NSP_ServiceConstants.CHILD_DISPATCH_REGION;
        insert tUser;
        User tUser2 =  NSP_TestHelper.createUser(false);
        tUser2.Phone = '(112)6475261 ext415';
        tUser2.Username = 'jroytest99@test.com.abc'+System.currentTimeMillis();
        tUser2.NSP_Service_Region__c = 'MMSO - Southeast';
        tUser2.NSP_Salesforce_Field_Service__c = NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_DISPATCHER_RESOURCE;
        tUser2.NSP_Dispatch_Region__c = NSP_ServiceConstants.CHILD_DISPATCH_REGION;
        insert tUser2;
        Event newEventRec = new Event();
        newEventRec.OwnerId = tUser2.Id;
        newEventRec.Subject = 'Test Subject For Event';
        newEventRec.DurationInMinutes = 60;
        newEventRec.ActivityDateTime = system.today();
        newEventRec.StartDateTime = system.today();
        newEventRec.IsAllDayEvent =false;
        newEventRec.DurationInMinutes =60;
        system.runAs(tUser2){
            insert newEventRec; 
        }
    }
    
    @isTest private static void eventRelationCreation(){
        Test.enableChangeDataCapture();
        List<Event> eventList = [SELECT ID, Subject, IsRecurrence, StartDateTime FROM Event WHERE Subject = 'Test Subject For Event' LIMIT 1];
        List<User> userList = [SELECT ID, NSP_Service_Region__c FROM User where NSP_Service_Region__c = 'MMSO - Southeast' AND Phone = '(112)6475261 ext495'];
        if(eventList.size() > 0 && userList.size() > 0){
            EventRelation er = new EventRelation();
            er.RelationId= userList[0].Id;
            er.EventId = eventList[0].Id;
            er.IsInvitee = True;
            insert er;
        }
        Test.getEventBus().deliver();
    }
    
    @isTest private static void handlerTest(){
        Test.startTest();
        List<EventRelationChangeEvent> erList = new List<EventRelationChangeEvent>();
        Map<Id,EventRelationChangeEvent> erMap = new Map<Id,EventRelationChangeEvent>(erList);
        EventRelationChangeEventTriggerHandler.beforeInsert(erList);
        EventRelationChangeEventTriggerHandler.afterUpdate(erMap, erMap);
        EventRelationChangeEventTriggerHandler.beforeUpdate(erMap, erMap);
        EventRelationChangeEventTriggerHandler.afterDelete(erList, erMap);
        EventRelationChangeEventTriggerHandler.beforeDelete(erList, erMap);
        Test.stopTest();
    }

}