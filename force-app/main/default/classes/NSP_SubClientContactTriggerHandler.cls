/**
* Represents the Sub Client Contact trigger handler.
* Created by : Virendra Kumar
* Created Date : 7/4/2022
*/
public class NSP_SubClientContactTriggerHandler implements NSP_ITriggerHandler{
    
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
    * Handles before insert for Sub Client
    * @param newList List of New Sub Client. 
    * @return void             
    *                
    */
    public void beforeInsert(List<sObject> newList) {
        NSP_SubClientContactTriggerHelper subClientContactTriggerObj = new NSP_SubClientContactTriggerHelper();
        subClientContactTriggerObj.updatePaperlessBatchDateBeforeInsertOrUpdate((List<NSP_Sub_Client_Contact__c>)newList, null);
        subClientContactTriggerObj.deleteAddressRecordsBasedOnStatus((List<NSP_Sub_Client_Contact__c>)newList, null);
    }
    
    /**
    * Handles after insert for Sub Client
    * @param newList List of New Sub Client.
    * @param newMap Map of New Sub Client. 
    * @return void             
    *                
    */
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
    }
    
    /**
    * Handles before update for Sub Client
    * @param newMap Map of New Sub Client.
    * @param oldMap Map of Old Sub Client. 
    * @return void             
    *                
    */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
     NSP_SubClientContactTriggerHelper subClientContactTriggerObj = new NSP_SubClientContactTriggerHelper();
        subClientContactTriggerObj.updatePaperlessBatchDateBeforeInsertOrUpdate((List<NSP_Sub_Client_Contact__c>)newMap.Values(), (Map<Id, NSP_Sub_Client_Contact__c>)oldMap);
        subClientContactTriggerObj.deleteAddressRecordsBasedOnStatus((List<NSP_Sub_Client_Contact__c>)newMap.Values(),(Map<Id, NSP_Sub_Client_Contact__c>)oldMap);

    }
    
    
    /**
    * Handles after update for Sub Client
    * @param newMap Map of New Sub Client.
    * @param oldMap Map of Old Sub Client. 
    * @return void             
    *                
    */
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_SubClientContactTriggerHelper.updatePDSContactRelatedFieldsBasedOnSCC((Map<Id, NSP_Sub_Client_Contact__c>) newMap,(Map<Id, NSP_Sub_Client_Contact__c>) oldMap);
    }
     /**
    * Handles after delete for Sub Client
    * @param oldList List of old Sub Client
    * @param oldMap Map of Old Sub Client
    * @return void             
    *                
    */ 
     public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }

    public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}