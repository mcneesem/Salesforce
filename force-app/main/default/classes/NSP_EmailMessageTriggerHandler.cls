/**
* Represents the EmailMessage trigger handler.
*/
public with sharing class NSP_EmailMessageTriggerHandler implements NSP_ITriggerHandler{
    //Use this variable to disable this trigger from transaction
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
    * Handles before insert for EmailMessage
    * @param newList List of New EmailMessage. 
    * @return void             
    *                
    */
    public void beforeInsert(List<sObject> newList) {
        NSP_EmailMessageTriggerHelper oEmailMessageTriggerHelper = new NSP_EmailMessageTriggerHelper();
    	oEmailMessageTriggerHelper.beforeInsertionEmailMessage(newList);   
    }
    
    /**
    * Handles after insert for EmailMessage
    * @param newList List of New EmailMessage.
    * @param newMap Map of New EmailMessage. 
    * @return void             
    *                
    */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        NSP_EmailMessageTriggerHelper oEmailMessageTriggerHelper =new NSP_EmailMessageTriggerHelper();
        oEmailMessageTriggerHelper.afterInsertionEmailMessage((List<EmailMessage>)newList,(Map<Id,EmailMessage>)newMap);
        //Story - STY-03853
        NSP_EmailMessageTriggerHelper.updateEmailMessageFields((List<EmailMessage>)newList);
    }
    
    /**
    * Handles before update for EmailMessage
    * @param newMap Map of New EmailMessage.
    * @param oldMap Map of Old EmailMessage. 
    * @return void             
    *                
    */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
    }
    
    
    /**
    * Handles after update for EmailMessage
    * @param newMap Map of New EmailMessage.
    * @param oldMap Map of Old EmailMessage. 
    * @return void             
    *                
    */
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {  
        
    }

    /**
    * Handles after delete for EmailMessage
    * @param oldList List of old EmailMessage
    * @param oldMap Map of Old EmailMessage
    * @return void             
    *                
    */
    
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        
    }

     /**
 * Handles before delete for EmailMessage
 * @param oldList List of old EmailMessage
 * @param oldMap Map of Old EmailMessage
 * @return void             
 *                
 */
 
 public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
     
}
}