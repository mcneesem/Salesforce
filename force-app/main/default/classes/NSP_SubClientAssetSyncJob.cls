/*
*--------------------------------------------------------------------------------------------------
* Developer         Date         Description
*--------------------------------------------------------------------------------------------------
* Virendra          10/20/2022   First Iteration
* Agentforce        12/01/2025   Documentation only: clarified header/comments (no functional changes)
*/

public with sharing class NSP_SubClientAssetSyncJob implements Database.Batchable<sObject>, Schedulable {
    // test w/ NSP_SubClientAssetSyncJob_Test (97%)
    
    // start: Selects Sub Client Contacts whose relevant union fields changed in the past 4 hours.
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        DateTime last4Hours = system.now().addHours(-4);
        
        // Get sub client contact history records constrained by Changed fields
        return Database.getQueryLocator(
            [SELECT Id, NSP_Sub_Client__c, NSP_Paid_Non_Paid__c, NSP_Employee_Status__c, NSP_Union_Employee__c 
             FROM 
             NSP_Sub_Client_Contact__c 
             WHERE 
             Id IN (
                 SELECT ParentId 
                 FROM NSP_Sub_Client_Contact__History 
                 WHERE 
                 CreatedDate >= :last4Hours 
                 AND 
                 (
                     Field IN (
                         'NSP_Employee_Status__c', 
                         'NSP_Paid_Non_Paid__c', 
                         'NSP_Union_Employee__c' 
                     )
                 )
             )
            ]
        );
        
    }
    
    // execute: For the current scope chunk
    // - Groups Contacts by Sub Client
    // - Recomputes Sub Client union flag (true if any active, paid, union contact)
    // - Recomputes Asset union flag (true if any related Sub Client has union employees)
    // - Performs partial DML and logs results via NSP_ErrorLogHandler
    public void execute( Database.BatchableContext bc, List<NSP_Sub_Client_Contact__c> scope ) {
        // Local variables
        Map<Id, List<NSP_Sub_Client_Contact__c>> subClientContactMap 	= new Map<Id, List<NSP_Sub_Client_Contact__c>>();
        Map<Id, List<NSP_Sub_Client__c>> updateListOfSubClientMap 		= new Map<Id, List<NSP_Sub_Client__c>>();
        List<NSP_Sub_Client__c> updateSubClientList						= new List<NSP_Sub_Client__c>();
        Map<Id, Asset> updateAssetMap									= new Map<Id, Asset>();
        
        for( NSP_Sub_Client_Contact__c subClientCon : scope ) {
            if( subClientCon.NSP_Sub_Client__c != null ) {
                if( !subClientContactMap.containsKey( subClientCon.NSP_Sub_Client__c) ) {
                    subClientContactMap.put( subClientCon.NSP_Sub_Client__c, new List<NSP_Sub_Client_Contact__c>{ subClientCon } );
                } else {
                    subClientContactMap.get( subClientCon.NSP_Sub_Client__c ).add( subClientCon );
                }
            } 
        }
        
        if( !subClientContactMap?.isEmpty() ) {
            updateListOfSubClientMap = NSP_SubClientAssetSyncJob.processSubClientRecords( subClientContactMap );
        }
        
        if( !updateListOfSubClientMap?.isEmpty() ) {
            updateSubClientList = NSP_SubClientAssetSyncJob.getUpdateList( updateListOfSubClientMap );
            updateAssetMap 		= NSP_SubClientAssetSyncJob.processSubClientRelatedAssetRecords( updateListOfSubClientMap );
        }
        
        try {
            // Partial success DML; failures are captured and logged without halting the batch chunk
            if( !updateSubClientList?.isEmpty() ) {
                Database.SaveResult[] subClientResults = Database.Update( updateSubClientList, false );
                NSP_ErrorLogHandler.logResults( 'NSP_SubClientAssetSyncJob', 'ExecuteMethod - Sub Client Updates', subClientResults );
            }
            
            if( !updateAssetMap?.isEmpty() && updateAssetMap?.values() != null ) {
                Database.SaveResult[] assetResults = Database.Update(updateAssetMap?.values(), false);
                NSP_ErrorLogHandler.logResults( 'NSP_SubClientAssetSyncJob', 'ExecuteMethod - Asset Updates', assetResults );
            }
        } catch( Exception ex ) {
            // Catch-all to ensure chunk processing continues; details persisted by central handler
            NSP_ErrorLogHandler.logException( 'NSP_SubClientAssetSyncJob', 'ExecuteMethod', ex );
        } 
    }
    
    // For Assets related to impacted Sub Clients, determine whether the union flag should flip.
    // Returns a map of Asset Id -> minimal Asset sObjects that require update.
    private static Map<Id, Asset> processSubClientRelatedAssetRecords( Map<Id, List<NSP_Sub_Client__c>> updateListOfSubClientMap ) {
        List<Asset> assetList = NSP_SubClientAssetSyncJob.getAssetRecordsBasedOnSubClients( updateListOfSubClientMap.keySet() );
        Map<Id, Asset> returnMap = new Map<Id, Asset>();
        if( assetList != null && !assetList.isEmpty() ) {
            for( Asset assetRec : assetList ) {
                Asset filteredAsset = NSP_SubClientAssetSyncJob.setUnionFlagOnAsset( assetRec );
                if ( filteredAsset != null ) {
                    returnMap.put( filteredAsset.Id, filteredAsset );
                }
            }
        }
        return returnMap;
    }
    
    // setUnionFlagOnAsset: true if any related Sub Client has NSP_Union_Employees__c = true.
    // Returns a minimal Asset (Id + changed field) if an update is needed; otherwise an empty Asset.
    private static Asset setUnionFlagOnAsset( Asset assetRec ) {
        Asset returnRec = new Asset();
        Boolean unionFlag = false;
        List<NSP_Sub_Client__c> subClientRecs = assetRec.Sub_Clients__r;
        if ( subClientRecs != null && !subClientRecs.isEmpty() ) {
            for( NSP_Sub_Client__c subClientRec : subClientRecs ) {
                if( subClientRec.NSP_Union_Employees__c == true ) {
                    unionFlag = true;
                    break;
                }
            }
        }
        if( assetRec.NSP_Union_Employees__c != unionFlag ) {
            returnRec 							= assetRec;
            returnRec.NSP_Union_Employees__c 	= unionFlag;
        }
        
        return returnRec;
    }
    
    // For each Sub Client, recompute NSP_Union_Employees__c based on its Contacts and
    // bucket the changed Sub Clients by their parent Asset for downstream Asset evaluation.
    private static Map<Id, List<NSP_Sub_Client__c>> processSubClientRecords( Map<Id, List<NSP_Sub_Client_Contact__c>> subClientContactMap ) {
        List<NSP_Sub_Client__c> subClients = NSP_SubClientAssetSyncJob.getSubClientRecordsBasedOnSubClientIds( subClientContactMap.keySet() );
        Map<Id, List<NSP_Sub_Client__c>> updateListOfSubClientMap = new Map<Id, List<NSP_Sub_Client__c>>();
        
        if( subClients != null && !subClients.isEmpty() ) {
            for( NSP_Sub_Client__c subClient : subClients ) {
                NSP_Sub_Client__c filteredSubClient = NSP_SubClientAssetSyncJob.setUnionEmployeeStatus( subClient );
                if ( filteredSubClient != null &&  filteredSubClient.NSP_Asset__c != null) {
                    if ( !updateListOfSubClientMap.containsKey( filteredSubClient.NSP_Asset__c ) ) {
                        updateListOfSubClientMap.put( filteredSubClient.NSP_Asset__c, new List<NSP_Sub_Client__c>());
                    } else {
                        updateListOfSubClientMap.get( filteredSubClient.NSP_Asset__c ).add( filteredSubClient );
                    }
                }
            }
        }
        return updateListOfSubClientMap;
    }
    
    // setUnionEmployeeStatus: true if any Contact is:
    //  - NSP_Paid_Non_Paid__c = 'Paid WSEE'
    //  - NSP_Employee_Status__c != 'TERMINATED'
    //  - NSP_Union_Employee__c = true
    // Returns the subClient with field updated if a change is needed; otherwise returns an empty sObject.
    private static NSP_Sub_Client__c setUnionEmployeeStatus( NSP_Sub_Client__c subClient ) {
        NSP_Sub_Client__c returnSubClient = new NSP_Sub_Client__c();
        Boolean unionFlag = false;
        List<NSP_Sub_Client_Contact__c> subClientContacts = subClient.NSP_Sub_Client_Contacts__r;
        if (subClientContacts != null && !subClientContacts.isEmpty()) {
            for( NSP_Sub_Client_Contact__c subClientContact : subClientContacts ) {
                if( subClientContact.NSP_Paid_Non_Paid__c == 'Paid WSEE' && 
                   subClientContact.NSP_Employee_Status__c != 'TERMINATED' && 
                   subClientContact.NSP_Union_Employee__c == true ) {
                       unionFlag = true;
                       
                       break;
                   } 
            }
            
            if( subClient.NSP_Union_Employees__c != unionFlag ) {
                returnSubClient								= subClient;
                returnSubClient.NSP_Union_Employees__c 		= unionFlag;
            }
        }
        
        return returnSubClient;
    }
    
    private static List<NSP_Sub_Client__c> getUpdateList( Map<Id, List<NSP_Sub_Client__c>> subClientMap ) {
        List<NSP_Sub_Client__c> returnList = new List<NSP_Sub_Client__c>();
        if( !subClientMap?.isEmpty() ) {
            for( List<NSP_Sub_Client__c> subClients : subClientMap.values() ) {
                if( !subClients?.isEmpty() ) {
                    returnList.addAll( subClients );
                }
            }
        }
        
        return returnList;
    }
    
    // Returns Sub Client records along with related Contacts for the given Sub Client Ids
    private static List<NSP_Sub_Client__c> getSubClientRecordsBasedOnSubClientIds( Set<Id> subClientIds ) {
        List<NSP_Sub_Client__c> returnList = new List<NSP_Sub_Client__c>();
        if( subClientIds != null && !subClientIds.isEmpty() ) {
            returnList = [SELECT Id, 
                          NSP_Asset__c, 
                          NSP_Union_Employees__c, 
                          (
                              SELECT Id, 
                              NSP_Sub_Client__c, 
                              NSP_Paid_Non_Paid__c, 
                              NSP_Employee_Status__c, 
                              NSP_Union_Employee__c 
                              FROM NSP_Sub_Client_Contacts__r)
                          FROM 
                          NSP_Sub_Client__c 
                          WHERE 
                          Id IN :subClientIds
                         ];
        }
        
        return returnList;
    }
    
    // Returns Asset records and their related Sub Clients for the given Asset Ids
    private static List<Asset> getAssetRecordsBasedOnSubClients( Set<Id> assetRecIds ) {
        List<Asset> returnList = new List<Asset>();
        if( !assetRecIds?.isEmpty() ) {
            returnList = [
                SELECT ID, 
                NSP_Union_Employees__c, 
                (
                    SELECT Id, 
                    NSP_Asset__c, 
                    NSP_Union_Employees__c 
                    FROM 
                    Sub_Clients__r 
                ) 
                FROM 
                Asset 
                WHERE 
                Id = :assetRecIds
            ];
        }
        
        return returnList;
    }
    
    // Schedulable entry point: enqueues the batch with scope size 200
    public void execute( SchedulableContext scon ) {
        //Executes Batch
        Database.executeBatch( new NSP_SubClientAssetSyncJob(), 200 );
    }
    
    // No-op finish; reserved for future notifications or post-processing
    public void finish( Database.BatchableContext bc ){
        
    }  
    
}