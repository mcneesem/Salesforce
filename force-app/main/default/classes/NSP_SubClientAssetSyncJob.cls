/**
Apex Class Name      :  NSP_SubClientAssetSyncJob
Version              :  1.0 
Author               :  Virendra Kumar                                                                          
Created Date         :  10/20/22 
Function             :  Represents test class for NSP_SubClientAssetSyncJob_Test class
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Virendra                  10/20/2022                First Iteration
*/

global class NSP_SubClientAssetSyncJob implements Database.Batchable<sObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime last4Hours = system.now().addHours(-4);
        //Get sub client contact history records
        Return Database.getqueryLocator([SELECT Id, OldValue, NewValue, Field, ParentId, DataType FROM NSP_Sub_Client_Contact__History 
                                        WHERE CreatedDate >=: last4Hours AND (Field = 'NSP_Employee_Status__c' OR Field = 'NSP_Paid_Non_Paid__c' OR Field = 'NSP_Union_Employee__c')]);
        
    }
    
    global void execute(Database.BatchableContext bc, List<NSP_Sub_Client_Contact__History> scope) {
        
        system.debug('scope' + scope);
        
        Set<Id> setOfParentIds = New Set<Id>();
        Set<Id> setSubClient = new Set<Id>();
        
        Map<Id, Boolean> ismapSubClientUnionStatus = new Map<Id, Boolean>();        
        
        List<NSP_Sub_Client__c> subClientHasUnionToBeUpdated = new List<NSP_Sub_Client__c>();
        List<Asset> assetHasUnionToBeUpdated = new List<Asset>();
        
        //collect all sub client Contact where NSP_Employee_Status__c Or NSP_Paid_Non_Paid__c or NSP_Union_Employee__c is changed
        for(NSP_Sub_Client_Contact__History existingSubClientCon : scope ) {   
            
            system.debug('existingSubClientCon' + existingSubClientCon);
            If(String.valueof(existingSubClientCon.ParentId).startsWith(Label.Sub_Client_Contact_Initial)) {
                setOfParentIds.Add(existingSubClientCon.ParentId);
            }
        }
        //Get details for sub client contact where sub client != null
        List<NSP_Sub_Client_Contact__c> subClientContact = [SELECT Id, NSP_Sub_Client__c, NSP_Paid_Non_Paid__c, NSP_Employee_Status__c, NSP_Union_Employee__c FROM 
                                                            NSP_Sub_Client_Contact__c WHERE Id =:setOfParentIds AND NSP_Sub_Client__c != null];
        
        
        //Collect all sub client 
        for(NSP_Sub_Client_Contact__c subClientCon : subClientContact) {
            setSubClient.add(subClientCon.NSP_Sub_Client__c);
            
        }
        
        try{
            for(Id idVal : setSubClient){
                NSP_Sub_Client__c subClient = new NSP_Sub_Client__c();
                
                //Collect all union satisfying records
                for(NSP_Sub_Client_Contact__c subClientCon : subClientContact){
                    ismapSubClientUnionStatus.put(subClientCon.NSP_Sub_Client__c,false);
                    if(subClientCon.NSP_Sub_Client__c == idVal && subClientCon.NSP_Paid_Non_Paid__c == 'Paid WSEE' && subClientCon.NSP_Employee_Status__c != 'TERMINATED' && subClientCon.NSP_Union_Employee__c == true) {
                        if(ismapSubClientUnionStatus.get(subClientCon.NSP_Sub_Client__c) == false){
                            ismapSubClientUnionStatus.put(subClientCon.NSP_Sub_Client__c,true);
                        } 
                    } 
                    
                    if (ismapSubClientUnionStatus != null && ismapSubClientUnionStatus.containsKey(idVal)) {
                        subClient.Id = idVal;
                        
                        // Set NSP_Union_Employees__c based on map value
                        subClient.NSP_Union_Employees__c = Boolean.valueOf(
                            ismapSubClientUnionStatus.get(subClientCon.NSP_Sub_Client__c)
                        );
                    }
                    
                }
                
                if(subClient.Id != null) {
                    subClientHasUnionToBeUpdated.add(subClient);
                }
            }
            //DML to partial save records for has employee union.
            if(subClientHasUnionToBeUpdated.size() > 0) {
                Database.update(subClientHasUnionToBeUpdated, false);
            }
            
            //Logic to update State of Operation
            /*if(subClientContact.size() > 0){
                updateStateOfOperation(subClientContact);
            }*/
            
        }catch(Exception exp){
            
        }finally{
            Set<Id> setAssets = new Set<Id>();
            Map<Id, Boolean> ismapAssetUnionStatus = new Map<Id, Boolean>();
            //Get Sub Client details
            List<NSP_Sub_Client__c> listSubClients = [select Id, NSP_Asset__c, NSP_Union_Employees__c from NSP_Sub_Client__c WHERE Id =: setSubClient];
            
            system.debug('listSubClients' + listSubClients);
            
            //Store asset Ids for sub clients
            for(NSP_Sub_Client__c subClient : listSubClients) {
                setAssets.add(subClient.NSP_Asset__c);
                
                system.debug('setAssets' + setAssets);
            }
            
            for(Id idVal : setAssets){
                Asset asset = new Asset();
                //Filter all Asset to be updated based on Union Employee
                for(NSP_Sub_Client__c subClient : listSubClients){
                    ismapAssetUnionStatus.put(subClient.NSP_Asset__c, false);
                    system.debug('ismapAssetUnionStatus' + ismapAssetUnionStatus);
                    if(subClient.NSP_Asset__c == idVal && subClient.NSP_Union_Employees__c == true) {
                        if(ismapAssetUnionStatus.get(idVal) == false){
                            ismapAssetUnionStatus.put(idVal,true);
                        } 
                    }
                    
                    if (ismapAssetUnionStatus != null && ismapAssetUnionStatus.containsKey(idVal)) {
                        asset.Id = idVal;
                        
                        // Directly assign based on map value
                        asset.NSP_Union_Employees__c = Boolean.valueOf(ismapAssetUnionStatus.get(idVal));
                    }
                }
                
                if(asset.Id != null) {
                    assetHasUnionToBeUpdated.add(asset);
                }
            }
            //update Asset with Union Employee checkbox
            
            if(assetHasUnionToBeUpdated.size() > 0) {
                
                Database.update(assetHasUnionToBeUpdated, false);
                
                system.debug('assetHasUnionToBeUpdated' + assetHasUnionToBeUpdated);

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
    
    /*public static void updateStateOfOperation(List<NSP_Sub_Client_Contact__c> subClientContact) {
        
        system.debug('subClientContact' +  subClientContact);
        
        Map<Id, String> subClientByStates = new  Map<Id, String>();
        Map<Id, String> assetByStates = new  Map<Id, String>();
        
        List<NSP_Sub_Client__c> subClientStateToBeUpdated = new List<NSP_Sub_Client__c>();
        List<Asset> assetStateToBeUpdated = new List<Asset>();
        
        //Below code helps to store states for respective sub client
        for(NSP_Sub_Client_Contact_Address__c subClientConAddress : [SELECT Id, NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Asset__c, 
                                                                     NSP_Address_Type__c, NSP_State__c, NSP_Sub_Client_Contact__c,
                                                                     NSP_Sub_Client_Contact__r.NSP_Sub_Client__c FROM NSP_Sub_Client_Contact_Address__c 
                                                                     WHERE NSP_Sub_Client_Contact__r.NSP_Paid_Non_Paid__c = 'Paid WSEE' AND NSP_Sub_Client_Contact__r.NSP_Employee_Status__c = 'HIRED' 
                                                                     AND NSP_Address_Type__c = 'Worksite' AND NSP_Sub_Client_Contact__c =:subClientContact AND NSP_Sub_Client_Contact__r.NSP_Sub_Client__c != null AND NSP_State__c != null]) {
                                                                         
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
        if(!subClientByStates.isEmpty()) {
            
            for(Id subClientId : subClientByStates.keyset()) {
                NSP_Sub_Client__c updatedSubClient = new NSP_Sub_Client__c();
                updatedSubClient.Id = subClientId;
                updatedSubClient.NSP_States_of_Operations__c = subClientByStates.get(subClientId);
                system.debug('updatedSubClient' + updatedSubClient);
                
                subClientStateToBeUpdated.add(updatedSubClient);
            }
        }
        //build state of operation field for Asset
        if(!assetByStates.isEmpty()) {
            for(Id assetId : assetByStates.keyset()) {
                Asset updatedAsset = new Asset();
                updatedAsset.Id = assetId;
                updatedAsset.NSP_States_of_Operations__c = assetByStates.get(assetId);
                
                system.debug('updatedAsset' + updatedAsset);
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
        
    }*/
    
    global void finish(Database.BatchableContext bc){
        
    }  
    
}