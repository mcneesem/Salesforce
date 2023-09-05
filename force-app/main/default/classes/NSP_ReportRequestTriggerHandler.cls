public class NSP_ReportRequestTriggerHandler implements NSP_ITriggerHandler{
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
  * Handles before insert for ReportRequest 
  * @param newList List of New ReportRequest . 
  * @return void             
  *                
  */
   public void beforeInsert(List<sObject> newList) {
       NSP_ReportRequestTriggerHelper ReportRequest = new NSP_ReportRequestTriggerHelper();
       ReportRequest.beforeInsertDirector(newList, new Map<Id, NSP_ReportRequest__c>());

   }
   
   /**
  * Handles after insert for ReportRequest 
  * @param newList List of New ReportRequest .
  * @param newMap Map of New ReportRequest . 
  * @return void             
  *                
  */
   public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
       
   }
   
 /**
  * Handles before update for ReportRequest 
  * @param newMap Map of New ReportRequest .
  * @param oldMap Map of Old ReportRequest . 
  * @return void             
  *                
  */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {

        NSP_ReportRequestTriggerHelper ReportRequest = new NSP_ReportRequestTriggerHelper();
        ReportRequest.beforeUpdateDirector( (Map<Id,NSP_ReportRequest__c>) newMap, (Map<Id,NSP_ReportRequest__c>) oldMap );  
   } 
   

    /**
  * Handles after update for ReportRequest 
  * @param newMap Map of New ReportRequest .
  * @param oldMap Map of Old ReportRequest . 
  * @return void             
  *                
  */

   public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
       
   }

   /**
   * Handles after delete for ReportRequest
   * @param oldList List of Old ReportRequest.
   * @param oldMap Map of Old ReportRequest. 
   * @return void             
   *                
   */

  public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {

  }

  public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
      NSP_ReportRequestTriggerHelper ReportRequest = new NSP_ReportRequestTriggerHelper();
      ReportRequest.beforeDeleteDirector(oldList, (Map<Id,NSP_ReportRequest__c>) oldMap);
  }

}