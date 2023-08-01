/**
* Represents the Docusign Status trigger handler.
* Created By: Virendra Kumar
* Date:24/01/2023
*/
public class NSP_DocusignStatusHandler implements NSP_ITriggerHandler{
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
    * Handles before insert for Docusign Status
    * @param newList List of New Docusign Status. 
    * @return void             
    *                
    */
    public void beforeInsert(List<sObject> newList) {
    }
    
    /**
    * Handles after insert for Docusign Status
    * @param newList List of New Docusign Status.
    * @param newMap Map of New Docusign Status. 
    * @return void             
    *                
    */
        
    public void afterInsert(List < sObject > newList, Map < Id, sObject > newMap) {
        //Developed as part of STY-03872
        NSP_DocusignStatusHelper.updatePlatformEvent((List<dfsle__EnvelopeStatus__c>)newList, null);

        
    }    
    
    /**
    * Handles before update for Docusign Status
    * @param newMap Map of New Docusign Status.
    * @param oldMap Map of Old Docusign Status. 
    * @return void             
    *                
    */
    public void beforeUpdate(Map < Id, sObject > newMap, Map < Id, sObject > oldMap) {
    }
    
    /**
    * Handles after update for Docusign Status
    * @param newMap Map of New Docusign Status.
    * @param oldMap Map of Old Docusign Status. 
    * @return void             
    *                
    */
    
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        //Developed as part of STY-03872
        NSP_DocusignStatusHelper.updatePlatformEvent((List<dfsle__EnvelopeStatus__c>)newMap.Values(),(Map<Id, dfsle__EnvelopeStatus__c>)oldMap);
        
        
    }
    
    /**
    * Handles after delete for Docusign Status
    * @param oldList List of old Docusign Status
    * @param oldMap Map of Old Docusign Status
    * @return void             
    *                
    */ 
    
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
    
    public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}