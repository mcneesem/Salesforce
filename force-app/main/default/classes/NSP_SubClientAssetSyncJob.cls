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

public with sharing class NSP_SubClientAssetSyncJob implements Database.Batchable<sObject>, Schedulable {
    // test w/ NSP_SubClientAssetSyncJob_Test (97%)
    
    // Batch Start: Query records updated in last 4 hours
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        DateTime last4Hours = System.now().addHours(-4);
        return Database.getQueryLocator(
            [
                SELECT 
                Id, 
                NSP_Sub_Client__c, 
                NSP_Paid_Non_Paid__c, 
                NSP_Employee_Status__c, 
                NSP_Union_Employee__c
                FROM 
                NSP_Sub_Client_Contact__c
                WHERE 
                Id IN (
                    SELECT 
                    ParentId
                    FROM 
                    NSP_Sub_Client_Contact__History
                    WHERE 
                    CreatedDate >= :last4Hours
                    AND 
                    Field IN (
                        'NSP_Employee_Status__c', 
                        'NSP_Paid_Non_Paid__c', 
                        'NSP_Union_Employee__c'
                    )
                )
            ]
        );
    }
    
    // Batch Execute: Process each chunk
    public void execute( Database.BatchableContext bc, List<NSP_Sub_Client_Contact__c> scope ) {
        Set<Id> subClientIds = new Set<Id>();
        
        for ( NSP_Sub_Client_Contact__c contact : scope ) {
            if ( contact.NSP_Sub_Client__c != null ) {
                subClientIds.add(contact.NSP_Sub_Client__c);
            }
        }
        
        if ( subClientIds != null && !subClientIds.isEmpty() ) {
            List<NSP_Sub_Client__c> subClients = getSubClientRecords( subClientIds );
            Map<Id, NSP_Sub_Client__c> subClientMap = filterSubClients( subClients );
            Set<Id> assetIds = getAssetIds( subClients, subClientMap );
            
            List<Asset> updateAssetRecords = new List<Asset>();
            if ( !assetIds.isEmpty() ) {
                List<Asset> assetRecords = getAssetRecords( assetIds );
                updateAssetRecords = setUnionFlagOnAssets( assetRecords );
            }
            
            updateRecords( subClientMap.values(), updateAssetRecords );
        }
    }
    
    // Batch Finish: Optional cleanup
    public void finish( Database.BatchableContext bc ) {}
    
    // Schedulable Execute
    public void execute( SchedulableContext scon ) {
        Database.executeBatch( new NSP_SubClientAssetSyncJob(), 200 );
    }
    
    // ---------------- Helper Methods ----------------
    
    private static void updateRecords( List<NSP_Sub_Client__c> subClients, List<Asset> assets ) {
        try {
            if ( subClients!= null && !subClients.isEmpty() ) {
                Database.SaveResult[] subClientResults = Database.update( subClients, false );
                NSP_ErrorLogHandler.logResults( 'NSP_SubClientAssetSyncJob', 'Sub Client Updates', subClientResults );
            }
            if ( assets != null && !assets.isEmpty() ) {
                Database.SaveResult[] assetResults = Database.update( assets, false );
                NSP_ErrorLogHandler.logResults( 'NSP_SubClientAssetSyncJob', 'Asset Updates', assetResults );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException( 'NSP_SubClientAssetSyncJob', 'ExecuteMethod', e );
        }
    }
    
    private static List<NSP_Sub_Client__c> getSubClientRecords( Set<Id> subClientIds ) {
        List<NSP_Sub_Client__c> returnSubClientRecords =  [
            SELECT Id, 
            NSP_Asset__c, 
            NSP_Union_Employees__c,
            (
                SELECT 
                Id, 
                NSP_Sub_Client__c, 
                NSP_Paid_Non_Paid__c, 
                NSP_Employee_Status__c, 
                NSP_Union_Employee__c
                FROM 
                NSP_Sub_Client_Contacts__r
            )
            FROM 
            NSP_Sub_Client__c
            WHERE 
            Id IN :subClientIds
        ];
        
        return returnSubClientRecords;
    }
    
    private static Map<Id, NSP_Sub_Client__c> filterSubClients( List<NSP_Sub_Client__c> subClients ) {
        Map<Id, NSP_Sub_Client__c> resultMap = new Map<Id, NSP_Sub_Client__c>();
        for ( NSP_Sub_Client__c subClient : subClients ) {
            Boolean unionFlag = false;
            for ( NSP_Sub_Client_Contact__c contact : subClient.NSP_Sub_Client_Contacts__r ) {
                if ( contact.NSP_Paid_Non_Paid__c == 'Paid WSEE' && 
                   contact.NSP_Employee_Status__c != 'TERMINATED' && 
                   contact.NSP_Union_Employee__c == true ) {
                    unionFlag = true;
                    break;
                }
            }
            if ( subClient.NSP_Union_Employees__c != unionFlag ) {
                subClient.NSP_Union_Employees__c = unionFlag;
                resultMap.put( subClient.Id, subClient );
            }
        }
        return resultMap;
    }
    
    private static Set<Id> getAssetIds( List<NSP_Sub_Client__c> subClients, Map<Id, NSP_Sub_Client__c> subClientMap ) {
        Set<Id> assetIds = new Set<Id>();
        for ( NSP_Sub_Client__c subClient : subClients ) {
            if ( subClientMap.containsKey(subClient.Id) && subClient.NSP_Asset__c != null ) {
                assetIds.add( subClient.NSP_Asset__c );
            }
        }
        return assetIds;
    }
    
    private static List<Asset> getAssetRecords( Set<Id> assetIds ) {
        
        List<Asset> returnAssetList = [
            SELECT 
            Id, 
            NSP_Union_Employees__c,
            (
                SELECT 
                Id, 
                NSP_Asset__c, 
                NSP_Union_Employees__c 
                FROM 
                Sub_Clients__r
            )
            FROM 
            Asset
            WHERE 
            Id IN :assetIds
        ];
        
        return returnAssetList;
    }
    
    private static List<Asset> setUnionFlagOnAssets( List<Asset> assets ) {
        List<Asset> updatedAssets = new List<Asset>();
        for ( Asset asset : assets ) {
            Boolean unionFlag = false;
            for ( NSP_Sub_Client__c subClient : asset.Sub_Clients__r ) {
                if ( subClient.NSP_Union_Employees__c ) {
                    unionFlag = true;
                    break;
                }
            }
            if ( asset.NSP_Union_Employees__c != unionFlag ) {
                asset.NSP_Union_Employees__c = unionFlag;
                updatedAssets.add( asset );
            }
        }
        return updatedAssets;
    }
}