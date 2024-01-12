/***************************************************************************************************
* @Class            : NSP_ServicePlanTriggerHandler
* @Author           : Simran Thukral
* @Version History  : 1.0
* @Creation         : 05/08/2023
* @Description      : Represents the Service Plan Trigger Handler
******************************************************************************************************/
public class NSP_ServicePlanTriggerHandler implements NSP_ITriggerHandler {

    public static Boolean TriggerDisabled = false;
    
     /**
    * Represents whether the trigger is disabled or not
    * @param N/A.  
    * @return Boolean             
    *                
    */     
    public Boolean isDisabled(){
        return TriggerDisabled;
    }
    
    
    /**
    * Handles before insert for Service Plan
    * @param newList List of New Service Plan. 
    * @return void             
    *                
    */
    public void beforeInsert(List<sObject> newList) {
         NSP_ServicePlanTriggerHelper servicePlanTriggerHelper = new   NSP_ServicePlanTriggerHelper();
        servicePlanTriggerHelper.beforeInsertDirector((List<NSP_Service_Plan__c>)newList);
    
    }
    
    /**
    * Handles after insert for Service Plan
    * @param newList List of New Service Plan.
    * @param newMap Map of New Service Plan. 
    * @return void             
    *                
    */
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
    }
    
    /**
    * Handles before update for Service Plan
    * @param newMap Map of New Service Plan.
    * @param oldMap Map of Old Service Plan. 
    * @return void             
    *                
    */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_ServicePlanTriggerHelper servicePlanTriggerHelper = new   NSP_ServicePlanTriggerHelper();
      servicePlanTriggerHelper.beforeUpdateDirector((Map<Id, NSP_Service_Plan__c>)newMap,(Map<Id, NSP_Service_Plan__c>)oldMap);
    
    }
    
    
    /**
    * Handles after update for Service Plan
    * @param newMap Map of New Service Plan.
    * @param oldMap Map of Old Service Plan. 
    * @return void             
    *                
    */
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
    }
    
    /**
    * Handles after delete for Service Plan
    * @param oldList List of Old Service Plan.
    * @param oldMap Map of Old Service Plan. 
    * @return void             
    *                
    */
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        
    }
    
    /**
    * Handles before delete for Service Plan
    * @param oldList List of Old Service Plan.
    * @param oldMap Map of Old Service Plan. 
    * @return void             
    *                
    */
    public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        
    }
}