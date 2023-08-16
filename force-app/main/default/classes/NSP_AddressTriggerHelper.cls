/**
Apex Class Name      :  NSP_AddressTriggerHelper
Version              :  1.0                                                                          
Created Date         :  11/09/2022
Author               :  Virendra Kumar
Function             :  Represents the Address trigger helper which handles all the logic.
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -----------------------------------------------------------------------------------------------
*/
public class NSP_AddressTriggerHelper {
    
    public static void updateSCCAddressWithStreet(List<NSP_Address__c> newAddress, Map<Id, NSP_Address__c> oldMap) {
        Map<Id, String> addressByStreet = new Map<Id, String>();
        List<NSP_Sub_Client_Contact_Address__c> sccAddressToUpdate = new List<NSP_Sub_Client_Contact_Address__c>();
        List<Profile> profile = [SELECT Id FROM Profile WHERE Id =:Userinfo.getProfileId() AND Name  =: NSP_ServiceConstants.INTEGRATION_USER];
        Set<Id> addressUpdateForState = new Set<Id>();
        
        for (NSP_Address__c address : newAddress) {
            if (address.NSP_Street__c != null && address.NSP_Street__c != oldMap.get(address.Id).NSP_Street__c && profile.size() > 0) {  
                addressByStreet.put(address.Id, address.NSP_Street__c);
            }
            if (address.NSP_State__c != oldMap.get(address.Id).NSP_State__c) {  
                addressUpdateForState.add(address.Id);
            }
        }
        
        if (!addressByStreet.isEmpty()) {
            updateChildAddressesAsync(JSON.serialize(addressByStreet));
        }
        
        if(!addressUpdateForState.isEmpty()) {
            for (NSP_Sub_Client_Contact_Address__c address : [SELECT Id, Name, NSP_Address__c FROM NSP_Sub_Client_Contact_Address__c WHERE NSP_Address__c =:addressUpdateForState]) {
                address.NSP_Address_State_Changed_Date__c = System.today();
                sccAddressToUpdate.add(address);
            }
            if(!sccAddressToUpdate.isEmpty()) {
                update sccAddressToUpdate;
            }
            
        }
    }
    
    @future
    public static void updateChildAddressesAsync(String addresses) {
        
        Map<Id, String> deserilizedAddressess = (Map<Id, String>) JSON.deserialize(addresses, Map<Id, String>.class);
        List<NSP_Sub_Client_Contact_Address__c> sccAddressToUpdate = new List<NSP_Sub_Client_Contact_Address__c>();
        
        for (NSP_Sub_Client_Contact_Address__c address : [SELECT Id, Name, NSP_Address__c FROM NSP_Sub_Client_Contact_Address__c WHERE NSP_Address__c =:deserilizedAddressess.keySet()]) {
            if(deserilizedAddressess.containsKey(address.NSP_Address__c)) {
                address.Name = deserilizedAddressess.get(address.NSP_Address__c);
                sccAddressToUpdate.add(address);
            }
            
        }
        if(!sccAddressToUpdate.isEmpty()) {
            List<Database.SaveResult> results =  Database.update( sccAddressToUpdate , false );
            NSP_ErrorLogHandler.logSaveResultsException('NSP_AddressTriggerHelper', 'updateChildAddressesAsync', results );
        }
    }
    
    
}