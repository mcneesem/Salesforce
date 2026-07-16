/**
* @description  :  Helper class for NSP_SubClientContactAddress Trigger.
* @date 10/18/2022
* Author : Virendra Kumar
+
* Name : NSP_SubClientContactAddressTriggerHelper
*/
public class NSP_SubClientContactAddressTriggerHelper {   
    /***********************************************************************************************
* MethodName: syncSPHistoryOnSubplan
* Description : This method is used to sync NSP_SubClientContactAddress related fields on to Sub Plan.
* Params:       List<NSP_Sub_Client_Contact_Address__c> SubCCAddressList, Boolean isInsert
* ********************************************************************************************/ 
    public static Boolean isFirstTime = true;
    
    public static void updateNameByStreetAddress(List<NSP_Sub_Client_Contact_Address__c> newList, Map<Id,NSP_Sub_Client_Contact_Address__c> oldMap) {
        
        if(isFirstTime) {
            isFirstTime = false;
            List<NSP_Sub_Client_Contact_Address__c> subClientAddToBeUpdated = New List<NSP_Sub_Client_Contact_Address__c>();
            Set<Id> addressIds = New Set<Id>();
            Set<Id> ownerUsers = new  Set<Id>();
            Map<Id , NSP_Address__c> mapAddress = New Map<Id , NSP_Address__c>();
            String userId = '';
            
            for(NSP_Sub_Client_Contact_Address__c subClientConAddress : newList) {
                if((subClientConAddress.NSP_Address__c != null && oldMap == null) || (oldMap != null && (subClientConAddress.Name != oldMap.get(subClientConAddress.Id).Name || subClientConAddress.NSP_Address__c != oldMap.get(subClientConAddress.Id).NSP_Address__c))) {
                    addressIds.add(subClientConAddress.NSP_Address__c);
                    // Add User based on Insert Or After Update
                    userId = oldMap == null ? subClientConAddress.OwnerId : subClientConAddress.LastModifiedById;
                    ownerUsers.add(userId);
                }           
            }
            
            if(!addressIds.isEmpty()) {
                Map<Id, User> integrationUsers = new Map<Id, User>();
                
                //Find whether Integration User has created or updated the record
                for(User intUser : [SELECT Id FROM User WHERE Id =: ownerUsers AND Profile.Name = 'Integration User']) {
                    integrationUsers.put(intUser.Id, intUser);
                }
                
                if(integrationUsers.size() > 0) {
                    for(NSP_Address__c address : [SELECT Id, NSP_Street__c FROM NSP_Address__c WHERE Id =: addressIds AND NSP_Street__c != null]) {
                        mapAddress.put(address.Id, address);
                    }
                }
                
                if(mapAddress.size() > 0) {
                    for(NSP_Sub_Client_Contact_Address__c subCliConAddress : newList) {
                        //Update name by street in case of insert.
                        if(oldMap == null && integrationUsers.containsKey(subCliConAddress.OwnerId) && mapAddress.containsKey(subCliConAddress.NSP_Address__c)) {
                            subCliConAddress.Name = mapAddress.get(subCliConAddress.NSP_Address__c).NSP_Street__c;
                        }
                        
                        //update name by street in case of update
                        if(oldMap != null && integrationUsers.containsKey(subCliConAddress.LastModifiedById) && mapAddress.containsKey(subCliConAddress.NSP_Address__c) 
                           && subCliConAddress.Name != mapAddress.get(subCliConAddress.NSP_Address__c).NSP_Street__c) {
                               
                               NSP_Sub_Client_Contact_Address__c sccAddress  = new NSP_Sub_Client_Contact_Address__c(Id = subCliConAddress.Id);
                               sccAddress.Name = mapAddress.get(subCliConAddress.NSP_Address__c).NSP_Street__c;
                               subClientAddToBeUpdated.add(sccAddress);
                           }
                    }
                    
                    if(!subClientAddToBeUpdated.isEmpty()) {
                        update subClientAddToBeUpdated;
                    }
                }  
            }
        }
    }
    
    /***********************************************************************************************
* MethodName: assignSubClientContactToWorkAddress
* Description : This method is used to update Contact Field on before Insert.
    * Params:       List<NSP_Sub_Client_Contact_Address__c> NSP_Sub_Client_Contact_Address__c, Boolean isInsert
* ********************************************************************************************/ 
    
    public static void assignSubClientContactToWorkAddress(List<NSP_Sub_Client_Contact_Address__c> newList){
        set<Id> subClientContact = new set<Id>();
        for(NSP_Sub_Client_Contact_Address__c subClietContactAddress : newList){
            subClientContact.add(subClietContactAddress.NSP_Sub_Client_Contact__c);
        }
        
        Map<Id,NSP_Sub_Client_Contact__c> subClietContactById = new map<Id,NSP_Sub_Client_Contact__c>(([SELECT id , NSP_Contact__c FROM NSP_Sub_Client_Contact__c WHERE id =: subClientContact]));
        for(NSP_Sub_Client_Contact_Address__c subClietContactAddressForAssignment : newList){
            if(subClietContactAddressForAssignment.NSP_Sub_Client_Contact__c != null && subClietContactById.containsKey(subClietContactAddressForAssignment.NSP_Sub_Client_Contact__c) && subClietContactById.get(subClietContactAddressForAssignment.NSP_Sub_Client_Contact__c).NSP_Contact__c != null){
                subClietContactAddressForAssignment.NSP_Contact__c = subClietContactById.get(subClietContactAddressForAssignment.NSP_Sub_Client_Contact__c).NSP_Contact__c;
            }   
        }
    }	
    
    /***********************************************************************************************
* MethodName: updateChildAddressesAsync
* Description : This method is used to update Addess State Date Field on before Insert and update.
* ********************************************************************************************/ 
    public static void updateAddressStateDate(List<NSP_Sub_Client_Contact_Address__c> newList, Map<Id,NSP_Sub_Client_Contact_Address__c> oldMap) {
        
        for(NSP_Sub_Client_Contact_Address__c subClientConAddress : newList) {
            if((subClientConAddress.NSP_Address__c != null && oldMap == null) || 
               (oldMap != null && oldMap.get(subClientConAddress.Id) != null && subClientConAddress.NSP_Address__c != oldMap.get(subClientConAddress.Id).NSP_Address__c))
            subClientConAddress.NSP_Address_State_Changed_Date__c = System.today();
        }
    }
    
}