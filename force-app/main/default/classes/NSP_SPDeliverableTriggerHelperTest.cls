@IsTest
private class NSP_SPDeliverableTriggerHelperTest { 
            /**
* @Description: This test method is used to cover beforeInsertDirector
* @Created date: 08/16/2022. 
* @return void             
*     */  
    @IsTest
    static void onInsertshouldCheckDeliverablePicklistFirst(){
        // GIVEN
        String expectedErrorMessage = 'Please add "Random Value" to Deliverable picklist, and Additional Detail picklist items if required, in the Deliverable Object.';
        NSP_Service_Plan_Deliverable__c servicePlanDeliverable = new NSP_Service_Plan_Deliverable__c();
        servicePlanDeliverable.Name = 'Random Value';

        // WHEN
        try{
            test.startTest();
	        insert servicePlanDeliverable;
            test.stopTest();
        } catch(Exception exp){
            // THEN
			System.assert(exp.getMessage().contains(expectedErrorMessage));
        }
    }
            /**
             * @Method Name: onUpdateshouldCheckDeliverablePicklistFirst
* @Description: This test method is used to cover beforeUpdateDirector
* @Created date: 08/16/2022. 
* @return void             
*     */ 
    @IsTest
    static void onUpdateshouldCheckDeliverablePicklistFirst(){
        // GIVEN
        String expectedErrorMessage = 'Please update "Random Value" in the Deliverable picklist in Deliverable object first.';
        NSP_Service_Plan_Deliverable__c servicePlanDeliverable = new NSP_Service_Plan_Deliverable__c();
        servicePlanDeliverable.Name = 'Training Administration';

        insert servicePlanDeliverable;

        try{
            // WHEN
            test.startTest();
            servicePlanDeliverable.Name = 'Random Value';
	        update servicePlanDeliverable;
            test.stopTest();
            System.assert(false, 'Should throw exception');
        } catch(Exception exp){
            // THEN
			System.assert(exp.getMessage().contains(expectedErrorMessage));            
        }
    }
    
    @IsTest
    static void afterDelete() {
        new NSP_ServicePlanDeliverableTriggerHandler().afterDelete(null, null);
        System.assert(new NSP_ServicePlanDeliverableTriggerHandler().afterDelete(null, null) == null);
    }
    @IsTest
    static void afterUnDelete() {
        new NSP_ServicePlanDeliverableTriggerHandler().afterUnDelete(null, null);
        System.assert(new NSP_ServicePlanDeliverableTriggerHandler().afterUnDelete(null, null) == null);
    }
    @IsTest
    static void afterUpdate() {
        new NSP_ServicePlanDeliverableTriggerHandler().afterUpdate(null, null);
        System.assert(new NSP_ServicePlanDeliverableTriggerHandler().afterUpdate(null, null) == null);
    }
    @IsTest
    static void afterInsert() {
        new NSP_ServicePlanDeliverableTriggerHandler().afterInsert(null, null);
        System.assert(new NSP_ServicePlanDeliverableTriggerHandler().afterInsert(null, null) == null);
    }
    @IsTest
    static void beforeDelete() {
        new NSP_ServicePlanDeliverableTriggerHandler().beforeDelete(null, null);
        System.assert(new NSP_ServicePlanDeliverableTriggerHandler().beforeDelete(null, null) == null);
    }
    
    
}