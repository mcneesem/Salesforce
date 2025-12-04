public with sharing class NSP_SubClientAssetSyncJob implements ISelfSchedulable , Schedulable , IJobRunnable , Database.Batchable<sObject> {
    // test w/ NSP_SubClientAssetSyncJob_Test (94%)

    //
    // ISelfSchedulable
    //

    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_SubClientAssetSyncJob ~ When Paid/NonPaid, Employee Status and Union fields in sub client contact are updated, then it will rollup updated values in Sub Client and Asset level ~ Schedule to run every 4 hour' + suffix ,
            '0 0 */4 * * ?' ,
            new NSP_SubClientAssetSyncJob()
        );
    }

    //
    // Schedulable
    //

    // Executes the batch job to update client sub-plan history records
    // This method is called by the scheduler to initiate the batch process
    public void execute( SchedulableContext scon ) {
        NSP_SubClientAssetSyncJob.run();
    }

    //
    // IJobRunnable
    //

    public static Id run() {
        return Database.executeBatch( new NSP_SubClientAssetSyncJob() , 200 );
    }

    //
    // Batchable
    //

    // Batch Start: Query records updated in last 4 hours
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        DateTime last4Hours = System.now().addHours(-4);
        return Database.getQueryLocator(
            [
                SELECT
                    Id ,
                    NSP_Sub_Client__c ,
                    NSP_Paid_Non_Paid__c ,
                    NSP_Employee_Status__c ,
                    NSP_Union_Employee__c
                FROM NSP_Sub_Client_Contact__c
                WHERE (
                    Id IN (
                        SELECT ParentId
                        FROM NSP_Sub_Client_Contact__History
                        WHERE (
                            ( CreatedDate >= :last4Hours )
                            AND (
                                Field IN (
                                    'NSP_Employee_Status__c' ,
                                    'NSP_Paid_Non_Paid__c' ,
                                    'NSP_Union_Employee__c'
                                )
                            )
                        )
                    )
                )
            ]
        );
    }

    // Batch Execute: Process each chunk
    public void execute( Database.BatchableContext bc , List<NSP_Sub_Client_Contact__c> scope ) {
        Set<Id> subClientIds = new Set<Id>();
        for ( NSP_Sub_Client_Contact__c contactRec : scope ) {
            if ( contactRec.NSP_Sub_Client__c != null ) {
                subClientIds.add(contactRec.NSP_Sub_Client__c);
            }
        }
        if ( subClientIds != null && !subClientIds.isEmpty() ) {
            List<NSP_Sub_Client__c> subClients = NSP_SubClientAssetSyncJob.getSubClientRecords( subClientIds );
            Map<Id,NSP_Sub_Client__c> subClientMap = NSP_SubClientAssetSyncJob.filterSubClients( subClients );
            Set<Id> assetIds = NSP_SubClientAssetSyncJob.getAssetIds( subClients , subClientMap );
            List<Asset> assetRecords = NSP_SubClientAssetSyncJob.getAssetRecords( assetIds );
            List<Asset> updateAssetRecords = updateAssetRecords = NSP_SubClientAssetSyncJob.setUnionFlagOnAssets( assetRecords , subClientMap );
            if ( ( subClientMap != null ) && !subClientMap.isEmpty() ) {
                NSP_SubClientAssetSyncJob.updateRecords( subClientMap.values() , updateAssetRecords );
            }
        }
    }

    // Batch Finish: Optional cleanup
    public void finish( Database.BatchableContext bc ) {
    }

    // ---------------- Helper Methods ----------------

    private static void updateRecords( List<NSP_Sub_Client__c> subClients , List<Asset> assets ) {
        try {
            if ( ( subClients != null ) && !subClients.isEmpty() ) {
                Database.SaveResult[] results = Database.update( subClients , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_SubClientAssetSyncJob.class.getName() ,
                    'updateRecords:NSP_Sub_Client__c' ,
                    results
                );
            }
            if ( ( assets != null ) && !assets.isEmpty() ) {
                Database.SaveResult[] results = Database.update( assets , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_SubClientAssetSyncJob.class.getName() ,
                    'updateRecords:Asset' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_SubClientAssetSyncJob.class.getName() ,
                'updateRecords' ,
                e
            );
        }
    }

    private static List<NSP_Sub_Client__c> getSubClientRecords( Set<Id> subClientIds ) {
        List<NSP_Sub_Client__c> returnSubClientRecords = new List<NSP_Sub_Client__c>();
        if( ( subClientIds != null ) && !subClientIds.isEmpty() ) {
            returnSubClientRecords =  [
                SELECT
                    Id ,
                    NSP_Asset__c ,
                    NSP_Union_Employees__c ,
                    (
                        SELECT
                            Id ,
                            NSP_Sub_Client__c ,
                            NSP_Paid_Non_Paid__c ,
                            NSP_Employee_Status__c ,
                            NSP_Union_Employee__c
                        FROM NSP_Sub_Client_Contacts__r
                    )
                FROM NSP_Sub_Client__c
                WHERE ( Id IN :subClientIds )
            ];
        }

        return returnSubClientRecords;
    }

    private static Map<Id,NSP_Sub_Client__c> filterSubClients( List<NSP_Sub_Client__c> subClients ) {
        Map<Id,NSP_Sub_Client__c> resultMap = new Map<Id,NSP_Sub_Client__c>();
        if ( ( subClients != null ) && !subClients.isEmpty() ) {
            for ( NSP_Sub_Client__c subClient : subClients ) {
                Boolean unionFlag = NSP_SubClientAssetSyncJob.computeSubClientContacts( subClient );
                if ( subClient.NSP_Union_Employees__c != unionFlag ) {
                    subClient.NSP_Union_Employees__c = unionFlag;
                    resultMap.put( subClient.Id , subClient );
                }
            }
        }
        return resultMap;
    }

    private static Boolean computeSubClientContacts( NSP_Sub_Client__c subClient ) {
        String employmentStatus = 'TERMINATED';
        String paidNonPaidValue = 'Paid WSEE';
        Boolean returnValue = false;
        if ( ( subClient != null )
            && ( subClient.NSP_Sub_Client_Contacts__r != null )
            && !subClient.NSP_Sub_Client_Contacts__r.isEmpty()
            )
        {
             for ( NSP_Sub_Client_Contact__c contactRec : subClient.NSP_Sub_Client_Contacts__r ) {
                if ( ( contactRec.NSP_Paid_Non_Paid__c == paidNonPaidValue )
                    && ( contactRec.NSP_Employee_Status__c != employmentStatus )
                    && ( contactRec.NSP_Union_Employee__c == true )
                    )
                {
                    returnValue = true;
                    break;
                }
            }
        }
        return returnValue;
    }

    private static Set<Id> getAssetIds( List<NSP_Sub_Client__c> subClients, Map<Id,NSP_Sub_Client__c> subClientMap ) {
        Set<Id> assetIds = new Set<Id>();
        if ( ( subClients != null )
            && !subClients.isEmpty()
            && ( subClientMap != null )
            && !subClientMap.isEmpty()
            )
        {
            for ( NSP_Sub_Client__c subClient : subClients ) {
                if ( subClientMap.containsKey( subClient.Id )
                    && ( subClient.NSP_Asset__c != null )
                    )
                {
                    assetIds.add( subClient.NSP_Asset__c );
                }
            }
        }
        return assetIds;
    }

    private static List<Asset> getAssetRecords( Set<Id> assetIds ) {
        List<Asset> returnAssetList = new List<Asset>();
        if ( ( assetIds != null ) && !assetIds.isEmpty() ) {
            returnAssetList = [
                SELECT
                    Id ,
                    NSP_Union_Employees__c ,
                    (
                        SELECT
                            Id ,
                            NSP_Asset__c ,
                            NSP_Union_Employees__c
                        FROM Sub_Clients__r
                    )
                FROM Asset
                WHERE ( Id IN :assetIds )
            ];
        }
        return returnAssetList;
    }

    private static List<Asset> setUnionFlagOnAssets( List<Asset> assets , Map<Id,NSP_Sub_Client__c> subClientMap ) {
        List<Asset> updatedAssets = new List<Asset>();
        if ( ( assets != null )
            && !assets.isEmpty()
            && ( subClientMap != null )
            && !subClientMap.isEmpty()
            )
        {
            for ( Asset assetRec : assets ) {
                Boolean computedUnionFlag = NSP_SubClientAssetSyncJob.computeAssetUnionFlag( assetRec , subClientMap );
                if ( assetRec.NSP_Union_Employees__c != computedUnionFlag ) {
                    assetRec.NSP_Union_Employees__c = computedUnionFlag;
                    updatedAssets.add( assetRec );
                }
            }
        }
        return updatedAssets;
    }

    private static Boolean computeAssetUnionFlag( Asset assetRec , Map<Id,NSP_Sub_Client__c> subClientMap ) {
        Boolean returnValue = false;
        if ( ( assetRec != null )
            && ( assetRec.Sub_Clients__r != null )
            && !assetRec.Sub_Clients__r.isEmpty()
            )
        {
            for ( NSP_Sub_Client__c subClient : assetRec.Sub_Clients__r ) {
                if ( NSP_SubClientAssetSyncJob.subClientContributesUnion( subClient , subClientMap ) ) {
                    returnValue =  true;
                    break;
                }
            }
        }
        return returnValue;
    }

    private static Boolean subClientContributesUnion( NSP_Sub_Client__c subClient , Map<Id,NSP_Sub_Client__c> subClientMap ) {
        Boolean returnValue = false;
        if ( subClient != null ) {
            returnValue = subClient.NSP_Union_Employees__c;
            Boolean inMap = (
                subClientMap.containsKey( subClient.Id )
                && ( subClientMap.get( subClient.Id ) != null )
            );
            if ( inMap ) {
                returnValue = subClientMap.get(subClient.Id).NSP_Union_Employees__c;
            }
        }
        return returnValue;
    }

}
//