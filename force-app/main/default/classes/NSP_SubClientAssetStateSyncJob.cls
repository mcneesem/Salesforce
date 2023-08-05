/**
Apex Class Name      :  NSP_SubClientAssetStateSyncJob
Version              :  1.0 
Author               :  Virendra Kumar                                                                          
Created Date         :  10/20/22 
Function             :  Represents test class for NSP_SubClientAssetSyncJob class
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Virendra                  10/20/2022                First Iteration
*/

global class NSP_SubClientAssetStateSyncJob implements Database.Batchable<sObject>, Schedulable {
    // test w/ NSP_SubClientAssetSyncJob_Test (93%)
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime last4Hours = system.now().addHours(-4);
        //Get sub client contact history records
        Return Database.getqueryLocator([SELECT Id, OldValue, NewValue, Field, ParentId, Parent.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Asset__c, 
                                         DataType FROM NSP_Sub_Client_Contact_Address__History WHERE Field = 'NSP_Address_State_Changed_Date__c']);
        
    }
    
    global void execute(Database.BatchableContext bc, List<NSP_Sub_Client_Contact_Address__History> scope) {
        
        system.debug('scope' + scope);
        
        Set<Id> setOfParentIds = New Set<Id>();
        Set<Id> setSubClient = new Set<Id>();
        
        Map<Id, Boolean> ismapSubClientUnionStatus = new Map<Id, Boolean>();        
        
        List<NSP_Sub_Client__c> subClientHasUnionToBeUpdated = new List<NSP_Sub_Client__c>();
        List<Asset> assetHasUnionToBeUpdated = new List<Asset>();
        
        //collect all sub client Contact where NSP_Employee_Status__c Or NSP_Paid_Non_Paid__c or NSP_Union_Employee__c is changed
        for(NSP_Sub_Client_Contact_Address__History existingSubClientConAddress : scope ) {  
            If(String.valueof(existingSubClientConAddress.ParentId).startsWith(Label.NSP_Sub_Client_Contact_Address_Initial)) {
                setOfParentIds.Add(existingSubClientConAddress.Parent.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Asset__c);
            }
        }
        
        if(!setOfParentIds.isEmpty()) {
            system.debug('setOfParentIds' + setOfParentIds);
            Map<Id, NSP_Sub_Client__c> existingSubClients = new Map<Id, NSP_Sub_Client__c>([SELECT Id FROM NSP_Sub_Client__c WHERE NSP_Asset__c =: setOfParentIds]);
            
            if(!existingSubClients.isEmpty()) {
                //Get details for sub client contact where sub client != null
                List<NSP_Sub_Client_Contact__c> subClientContact = [SELECT Id, NSP_Sub_Client__c, NSP_Paid_Non_Paid__c, NSP_Employee_Status__c, NSP_Union_Employee__c FROM 
                                                                    NSP_Sub_Client_Contact__c WHERE NSP_Sub_Client__c =: existingSubClients.keyset()];
                system.debug('subClientContact' + subClientContact);
                try{            
                    if(subClientContact.size() > 0){
                        updateStateOfOperation(subClientContact, existingSubClients, setOfParentIds);
                    }
                    
                }catch(Exception exp){
                    NSP_ErrorLogHandler.logSaveException('NSP_SubClientAssetStateSyncJob', 'execute', exp.getMessage());
                }
            }
            
        }
        
    }
    
    public void execute(SchedulableContext scon) {
        //Executes Batch
        Database.executeBatch(new NSP_SubClientAssetSyncJob(),200);
    }
    
    /***********************************************************************************************
* MethodName: updateStateOfOperation
* Description : This method is used to Update State of Operation field on Asset and Sub Client based on State under SCCA.
* Params:       List<NSP_Sub_Client_Contact__c> subClientContact
* ********************************************************************************************/ 
    
    public static void updateStateOfOperation(List<NSP_Sub_Client_Contact__c> subClientContact, Map<Id, NSP_Sub_Client__c> existingSubClients, Set<Id> setOfParentIds) {
        
        Map<Id, String> subClientByStates = new  Map<Id, String>();
        Map<Id, String> assetByStates = new  Map<Id, String>();
        
        List<NSP_Sub_Client__c> subClientStateToBeUpdated = new List<NSP_Sub_Client__c>();
        List<Asset> assetStateToBeUpdated = new List<Asset>();
        
        //Below code helps to store states for respective sub client
        for(NSP_Sub_Client_Contact_Address__c subClientConAddress : [SELECT Id, NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Asset__c, 
                                                                     NSP_Address_Type__c, NSP_State__c, NSP_Sub_Client_Contact__c,
                                                                     NSP_Sub_Client_Contact__r.NSP_Sub_Client__c FROM NSP_Sub_Client_Contact_Address__c 
                                                                     WHERE NSP_Sub_Client_Contact__r.NSP_Paid_Non_Paid__c = 'Paid WSEE' AND NSP_Sub_Client_Contact__r.NSP_Employee_Status__c != 'TERMINATED' AND NSP_Sub_Client_Contact__c =:subClientContact AND NSP_Sub_Client_Contact__r.NSP_Sub_Client__c != null AND NSP_State__c != null]) {
                                                                         
                                                                         if(subClientByStates.containsKey(subClientConAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__c)) {
                                                                             String states = subClientByStates.get(subClientConAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__c);
                                                                             states = states + (!states.contains(subClientConAddress.NSP_State__c) ? subClientConAddress.NSP_State__c + ';' : '');
                                                                             subClientByStates.put(subClientConAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__c, states);
                                                                         }else {
                                                                             subClientByStates.put(subClientConAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__c, subClientConAddress.NSP_State__c+ ';');
                                                                         }
                                                                         
                                                                         //Below code helps to store states for respective Asset
                                                                         if(assetByStates.containsKey(subClientConAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Asset__c)) {
                                                                             String states = assetByStates.get(subClientConAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Asset__c);
                                                                             states = states + (!states.contains(subClientConAddress.NSP_State__c) ? subClientConAddress.NSP_State__c + ';': '');
                                                                             assetByStates.put(subClientConAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Asset__c, states);
                                                                         }else {
                                                                             assetByStates.put(subClientConAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Asset__c, subClientConAddress.NSP_State__c + ';');
                                                                         }
                                                                     }
        //build state of operation field for sub client
        if(!existingSubClients.isEmpty()) {
            
            for(Id subClientId : existingSubClients.keyset()) {
                NSP_Sub_Client__c updatedSubClient = new NSP_Sub_Client__c();
                updatedSubClient.Id = subClientId;
                updatedSubClient.NSP_States_of_Operations__c = subClientByStates.containsKey(subClientId)? subClientByStates.get(subClientId) : null;
                subClientStateToBeUpdated.add(updatedSubClient);
            }
        }
        //build state of operation field for Asset
        if(!setOfParentIds.isEmpty()) {
            for(Id assetId : setOfParentIds) {
                Asset updatedAsset = new Asset();
                updatedAsset.Id = assetId;
                updatedAsset.NSP_States_of_Operations__c = assetByStates.containsKey(assetId) ? assetByStates.get(assetId) : null;
                assetStateToBeUpdated.add(updatedAsset);
            }
        }
        //Update Sub Client and Asset with updated State of Operation
        if(!subClientStateToBeUpdated.isEmpty()) {
            Database.update(subClientStateToBeUpdated, false);
        }
        
        if(!assetStateToBeUpdated.isEmpty()) {
            Database.update(assetStateToBeUpdated, false);
        }
        
    }
    
    global void finish(Database.BatchableContext bc){
        
    }  
    
}