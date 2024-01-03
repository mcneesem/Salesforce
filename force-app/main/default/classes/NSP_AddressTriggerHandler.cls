/**
* Represents the Address trigger handler.
* Created by : Virendra Kumar
* Created Date : 11/09/2022
*/
public class NSP_AddressTriggerHandler implements NSP_ITriggerHandler{
    
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
* Handles before insert for Address
* @param newList List of New Address. 
* @return void             
*                
*/
    public void beforeInsert(List<sObject> newList) {
    }
    
    /**
* Handles after insert for Address
* @param newList List of New Address.
* @param newMap Map of New Address. 
* @return void             
*                
*/
    
    public void afterInsert(List < sObject > newList, Map < Id, sObject > newMap) {
        //Added as a part of <STY-02841>
     //   NSP_AddressTriggerHelper.deleteAddressRelatedRecords((List<NSP_Address__c>)newList);
     NSP_AddressTriggerHelper oAddressTriggerHelper =new NSP_AddressTriggerHelper();
        oAddressTriggerHelper.afterInsertDirector((List<NSP_Address__c>)newList,(Map<Id,NSP_Address__c>)newMap);
    }
    
    
    /**
* Handles before update for Address
* @param newMap Map of New Address.
* @param oldMap Map of Old Address. 
* @return void             
*                
*/
    public void beforeUpdate(Map < Id, sObject > newMap, Map < Id, sObject > oldMap) {
        
        
    }
    
    /**
* Handles after update for Address
* @param newMap Map of New Address.
* @param oldMap Map of Old Address. 
* @return void             
*                
*/
    
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_AddressTriggerHelper.updateSCCAddressWithStreet((List<NSP_Address__c>)newMap.values(),( Map < Id, NSP_Address__c >)oldMap);
    }    
    /**
* Handles after delete for Address
* @param oldList List of old Address
* @param oldMap Map of Old Address
* @return void             
*                
*/ 
    
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
    
    public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
    
    
    
}