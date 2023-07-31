/**
* Represents the NSP_SubClientContactAddress trigger handler.
* Created by : Virendra Kumar
* Created Date : 9/29/2022
*/
public class NSP_SubCCAddressTriggerHandler implements NSP_ITriggerHandler{
    
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
    * Handles before insert for NSP_SubClientContactAddress
    * @param newList List of New NSP_SubClientContactAddress. 
    * @return void             
    *                
    */
    public void beforeInsert(List<sObject> newList) {  
        NSP_SubClientContactAddressTriggerHelper.updateNameByStreetAddress((List<NSP_Sub_Client_Contact_Address__c>)newList, null);
        NSP_SubClientContactAddressTriggerHelper.assignSubClientContactToWorkAddress((List<NSP_Sub_Client_Contact_Address__c>) newList);
        NSP_SubClientContactAddressTriggerHelper.updateAddressStateDate((List<NSP_Sub_Client_Contact_Address__c>) newList, null);
    }
    
    /**
    * Handles after insert for NSP_SubClientContactAddress
    * @param newList List of New NSP_SubClientContactAddress.
    * @param newMap Map of New NSP_SubClientContactAddress. 
    * @return void             
    *                
	*/
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {        
    }
    
    /**
    * Handles before update for NSP_SubClientContactAddress
    * @param newMap Map of New NSP_SubClientContactAddress.
    * @param oldMap Map of Old NSP_SubClientContactAddress. 
    * @return void             
    *                
    */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_SubClientContactAddressTriggerHelper.updateAddressStateDate((List<NSP_Sub_Client_Contact_Address__c>) newMap.Values(), (Map<Id, NSP_Sub_Client_Contact_Address__c>)oldMap);
    }
    
    
    /**
    * Handles after update for NSP_SubClientContactAddress
    * @param newMap Map of New NSP_SubClientContactAddress.
    * @param oldMap Map of Old NSP_SubClientContactAddress. 
    * @return void             
    *                
    */
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_SubClientContactAddressTriggerHelper.updateNameByStreetAddress((List<NSP_Sub_Client_Contact_Address__c>)newMap.Values(),(Map<Id, NSP_Sub_Client_Contact_Address__c>)oldMap); 
    }

    public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
    
     /**
    * Handles after delete for NSP_SubClientContactAddress
    * @param oldList List of old NSP_SubClientContactAddress
    * @param oldMap Map of Old NSP_SubClientContactAddress
    * @return void             
    *                
    */ 
     public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}