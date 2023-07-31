/**
Apex Class Name      :  NSP_DeliverableTriggerHelperTest
Version              :  1.0     
Author               :   Jatin                                                                     
Created Date         :    6/9/2022
Function             :   Represents test class for NSP_DeliverableTriggerHelper class
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Tejas                 8/22/2022            First Iteration
*/


@IsTest
private class NSP_DeliverableTriggerHelperTest {
    @testSetup
	static void testData() {
        NSP_Service_Plan__c servicePlan = new NSP_Service_Plan__c();
        insert servicePlan;

        List<NSP_Service_Plan_Deliverable__c> deliverablePlans = new List<NSP_Service_Plan_Deliverable__c>();

        // Create Service Plan Deliverable record
        NSP_Service_Plan_Deliverable__c deliverablePlan = new NSP_Service_Plan_Deliverable__c();
        deliverablePlan.Name = 'Culture Strategy';
        deliverablePlan.NSP_Associated_Business_Goal__c = 'Based on the results of an Employee Climate Survey, identify organizational development opportunities to attract, develop, and retain talent.';
        deliverablePlan.NSP_Business_Opportunity__c = 'Identify activities aligned with your organizations specific needs, to continue developing team synergy and culture.';
        deliverablePlan.NSP_Category__c = 'Performance Svc Needs Analysis';
        deliverablePlan.NSP_Sub_Category__c = 'Needs Analysis';
        deliverablePlan.NSP_Deliverable_Type__c = 'Strategic';
        deliverablePlans.add(deliverablePlan);

        // Create Service Plan Deliverable record
        NSP_Service_Plan_Deliverable__c deliverablePlan1 = new NSP_Service_Plan_Deliverable__c();
        deliverablePlan1.Name = 'Coaching';
        deliverablePlan1.NSP_Associated_Business_Goal__c = 'Provide coaching to help identify strengths and weaknesses, and develop tools to optimize performance and leadership.';
        deliverablePlan1.NSP_Business_Opportunity__c = 'Improve the capacity of your leaders to perform.';
        deliverablePlan1.NSP_Category__c = 'Performance Svc Needs Analysis';
        deliverablePlan1.NSP_Sub_Category__c = 'Needs Analysis';
        deliverablePlan1.NSP_Deliverable_Type__c = 'Strategic';
		deliverablePlans.add(deliverablePlan1);

        // Insert service plan deliverable into database.
        insert deliverablePlans;
    }
                    /**
* @Description: This test method is used to cover beforeInsertDirector
* @Created date: 08/16/2022. 
* @return void             
*     */ 
    
    @IsTest
    static void onInsertshouldCopyValuesFromCorrectServicePlan(){
        // GIVEN
        NSP_Service_Plan__c servicePlan = [SELECT ID FROM NSP_Service_Plan__c WHERE Id != NULL LIMIT 1];
        NSP_Deliverable__c deliverable = new NSP_Deliverable__c();
        deliverable.NSP_Deliverable__c = 'Coaching';
        deliverable.NSP_Service_Plan__c = servicePlan.Id;
        
        // WHEN
        test.startTest();
        insert deliverable;

        NSP_Deliverable__c updatedDeliverable = [SELECT Name, NSP_Associated_Business_Goal__c, NSP_Business_Opportunity__c, NSP_Category__c, NSP_Sub_Category__c, NSP_Deliverable_Type__c FROM NSP_Deliverable__c WHERE Id = :deliverable.Id LIMIT 1];
        test.stopTest();
        // THEN
        System.assertEquals(updatedDeliverable.NSP_Associated_Business_Goal__c, 'Provide coaching to help identify strengths and weaknesses, and develop tools to optimize performance and leadership.');
        System.assertEquals(updatedDeliverable.NSP_Business_Opportunity__c, 'Improve the capacity of your leaders to perform.');
        System.assertEquals(updatedDeliverable.NSP_Category__c, 'Performance Svc Needs Analysis');
        System.assertEquals(updatedDeliverable.NSP_Sub_Category__c, 'Needs Analysis');
        System.assertEquals(updatedDeliverable.NSP_Deliverable_Type__c, 'Strategic');
    }
                /**
* @Description: This test method is used to cover beforeUpdateDirector
* @Created date: 08/16/2022. 
* @return void             
*     */ 

    @IsTest
    static void onUpdateshouldCopyNewValuesFromCorrectServicePlan(){
        // GIVEN
        NSP_Service_Plan__c servicePlan = [SELECT ID FROM NSP_Service_Plan__c WHERE Id != NULL LIMIT 1];
        NSP_Deliverable__c deliverable = new NSP_Deliverable__c();
        deliverable.NSP_Deliverable__c = 'Culture Strategy';
        deliverable.NSP_Service_Plan__c = servicePlan.Id;
        
        insert deliverable;

        NSP_Deliverable__c insertedDeliverable = [SELECT Name, NSP_Associated_Business_Goal__c, NSP_Business_Opportunity__c, NSP_Category__c, NSP_Sub_Category__c, NSP_Deliverable_Type__c FROM NSP_Deliverable__c WHERE Id = :deliverable.Id LIMIT 1];
        System.assertEquals(insertedDeliverable.NSP_Associated_Business_Goal__c, 'Based on the results of an Employee Climate Survey, identify organizational development opportunities to attract, develop, and retain talent.');

        // WHEN
        test.startTest();
        insertedDeliverable.NSP_Deliverable__c = 'Coaching';
        update insertedDeliverable;

        NSP_Deliverable__c updatedDeliverable = [SELECT Name, NSP_Associated_Business_Goal__c, NSP_Business_Opportunity__c, NSP_Category__c, NSP_Sub_Category__c, NSP_Deliverable_Type__c FROM NSP_Deliverable__c WHERE Id = :deliverable.Id LIMIT 1];
        test.stopTest();
        // THEN
        System.assertEquals(updatedDeliverable.NSP_Associated_Business_Goal__c, 'Provide coaching to help identify strengths and weaknesses, and develop tools to optimize performance and leadership.');
        System.assertEquals(updatedDeliverable.NSP_Business_Opportunity__c, 'Improve the capacity of your leaders to perform.');
        System.assertEquals(updatedDeliverable.NSP_Category__c, 'Performance Svc Needs Analysis');
        System.assertEquals(updatedDeliverable.NSP_Sub_Category__c, 'Needs Analysis');
        System.assertEquals(updatedDeliverable.NSP_Deliverable_Type__c, 'Strategic');
    }
    
    /**
* @Description: This test method is used to cover beforeDeleteDirector
* @Created date: 05/18/2023. 
* @return void             
*     */ 
    
    @IsTest
    static void beforeDeleteDirectorTest(){
        
        List<String> SERVICE_PLAN_FIELDS = new List<String>{'Id', 'Name'};
            String getServicePlanDeliverableQuery = new NSP_QueryBuilder('NSP_Service_Plan_Deliverable__c', SERVICE_PLAN_FIELDS).addLimit(1).setSecurityEnforce(false).build();
        NSP_Service_Plan_Deliverable__c servicePlanDeliverableQuery =  Database.query(getServicePlanDeliverableQuery); 
        try{
            Test.startTest();
            database.delete(servicePlanDeliverableQuery);
        } catch (DmlException ex) {
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION' , ex.getDmlStatusCode(0),'Error Exception');
        } 
        Test.stopTest();
    }
    
    
    @IsTest
    static void afterInsert() {
        new NSP_DeliverableTriggerHandler().afterInsert(null, null);
        System.assert(new NSP_DeliverableTriggerHandler().afterInsert(null, null) == null);
    }
    @IsTest
    static void afterUpdate() {
        new NSP_DeliverableTriggerHandler().afterUpdate(null, null);
        System.assert(new NSP_DeliverableTriggerHandler().afterUpdate(null, null) == null);
    }
    @IsTest
    static void beforeDelete() {
        new NSP_DeliverableTriggerHandler().beforeDelete(null, null);
        System.assert(new NSP_DeliverableTriggerHandler().beforeDelete(null, null) == null);
    }
    @IsTest
    static void afterUndelete() {
        new NSP_DeliverableTriggerHandler().afterUndelete(null, null);
        System.assert(new NSP_DeliverableTriggerHandler().afterUndelete(null, null) == null);
    }
    @IsTest
    static void afterDelete() {
        new NSP_DeliverableTriggerHandler().afterDelete(null, null);
        System.assert(new NSP_DeliverableTriggerHandler().afterDelete(null, null) == null);
    }   
}