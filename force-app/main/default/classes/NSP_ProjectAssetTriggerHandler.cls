/**
* Represents the Project Asset trigger handler.
*/
public class NSP_ProjectAssetTriggerHandler implements NSP_ITriggerHandler {
    //Use this variable to disable this trigger from transaction
      public static Boolean TriggerDisabled = false;
      public static Boolean runOnce = true;
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
      * Handles before insert for Project Asset
      * @param newList List of New Project Asset. 
      * @return void             
      *                
      */
      public void beforeInsert(List<sObject> newList) {
       }
      
      /**
      * Handles after insert for Project Asset
      * @param newList List of New Project Asset.
      * @param newMap Map of New Project Asset. 
      * @return void             
      *                
      */
      public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
		  NSP_ProjectAssetTriggerHelper.afterInsertDirector((list<Project_Asset__c>) newList);
      }
      
      /**
      * Handles before update for Project Asset
      * @param newMap Map of New Project Asset.
      * @param oldMap Map of Old Project Asset. 
      * @return void             
      *                
      */
      public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {

        }
      
      
      /**
      * Handles after update for Project Asset
      * @param newMap Map of New Project Asset.
      * @param oldMap Map of Old Project Asset. 
      * @return void             
      *                
      */
      public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
	 }
  
      /**
      * Handles after delete for Project Task
      * @param oldList List of old Project Task
      * @param oldMap Map of Old Project Task
      * @return void             
      *                
      */
      
      public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {

      }

      public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
      }
  }