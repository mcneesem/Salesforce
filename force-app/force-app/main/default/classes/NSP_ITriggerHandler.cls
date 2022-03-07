/**
 * Represents the iTrigger interface .
 */
public interface NSP_ITriggerHandler {
    
   /**
   * Represents before insert operation
   * @param newList List of of sobjects. 
   */ 
	
  void beforeInsert(List<sObject> newList);
     
   /**
   * Represents after insert operation
   * @param newList List of of sobjects.  
   * @param newMap Map of Sobject id and Sobject         
   *                
   */ 
    void afterInsert(List<sObject> newList, Map<Id, sObject> newMap);
     
  /**
   * Represents before update operation
   * @param newMap Map of Sobject id and Sobject 
   * @param oldMap Map of Sobject id and Sobject         
   *                
   */
    void beforeUpdate(Map<Id, sObject> newMap, Map<Id, sObject> oldMap);
     
 /**
   * Represents after update operation
   * @param newMap Map of Sobject id and Sobject   
   * @param oldMap Map of Sobject id and Sobject         
   *                
   */
    void afterUpdate(Map<Id, sObject> newMap, Map<Id, sObject> oldMap);
          
   /* void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap);     

    void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap);

   void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap);*/

  // This method needs to be implemented to check whether or not trigger logic should run. You can remove this if this is not a requirement.
  Boolean isDisabled();
}