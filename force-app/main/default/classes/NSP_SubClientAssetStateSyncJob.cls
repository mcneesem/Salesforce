public with sharing class NSP_SubClientAssetStateSyncJob implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<sObject> {
    // test w/ NSP_SubClientAssetSyncJob_Test (90%)

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_SubClientAssetStateSyncJob() {
    }

    //
    // ISelfSchedulable
    //

    // runs M-F every 4 hours...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_SubClientAssetStateSyncJob ~ When Paid/NonPaid, Employee Status and State fields in sub client contact Address are updated, then it will rollup updated values in Sub Client and Asset level ~ M-F every 4 hours' + suffix ,
            '0 0 0,4,8,12,16,20 ? * MON-FRI *' ,
            new NSP_SubClientAssetStateSyncJob()
        );
    }

    //
    // Schedulable
    //

    public void execute( SchedulableContext sc ) {
        this.call( 'run' , null );
    }

    //
    // Callable
    //

    public Object call( String action , Map<String,Object> args ) {
        Object response = null;
        if ( action == 'run' ) {
            response = this.run();
        }
        return response;
    }

    //
    // IJobRunnable
    //

    public Id run() {
        Id response = null;
        if ( NSP_SubClientAssetStateSyncJob.isEnabled ) {
            response = Database.executeBatch(
                new NSP_SubClientAssetStateSyncJob() ,
                NSP_SubClientAssetStateSyncJob.batchSize
            );
        }
        return response;
    }

    //
    // Batchable
    //

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        Set<Id> assetIds = new Set<Id>();
        DateTime last4Hours = System.now().addHours( -4 );
        // collect all Assets with modififed related NSP_Sub_Client_Contact_Address__c records...
        List<NSP_Sub_Client_Contact_Address__History> addressChanges = [
            SELECT
                Id ,
                OldValue ,
                NewValue ,
                Field ,
                DataType ,
                ParentId ,
                Parent.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Asset__c
            FROM NSP_Sub_Client_Contact_Address__History
            WHERE (
                ( CreatedDate >= :last4Hours )
                AND ( Field = 'NSP_Address_State_Changed_Date__c' )
                AND ( ParentId != null )
                AND ( Parent.NSP_Sub_Client_Contact__c != null )
                AND ( Parent.NSP_Sub_Client_Contact__r.NSP_Sub_Client__c != null )
                AND ( Parent.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Asset__c != null )
            )
            LIMIT :NSP_SubClientAssetStateSyncJob.soqlAddressHistoryLimit
        ];
        for ( NSP_Sub_Client_Contact_Address__History existingSubClientConAddress : addressChanges ) {
            assetIds.add( existingSubClientConAddress.Parent.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Asset__c );
        }
        // collect all Assets with modififed related NSP_Sub_Client_Contact__c records...
        List<NSP_Sub_Client_Contact__History> contactChanges = [
            SELECT
                Id ,
                OldValue ,
                NewValue ,
                Field ,
                DataType ,
                ParentId ,
                Parent.NSP_Sub_Client__r.NSP_Asset__c
            FROM NSP_Sub_Client_Contact__History
            WHERE (
                ( CreatedDate >= :last4Hours )
                AND (
                    Field IN (
                        'NSP_Employee_Status__c' ,
                        'NSP_Paid_Non_Paid__c'
                    )
                )
                AND ( ParentId != null )
                AND ( Parent.NSP_Sub_Client__c != null )
                AND ( Parent.NSP_Sub_Client__r.NSP_Asset__c != null )
            )
            LIMIT :NSP_SubClientAssetStateSyncJob.soqlContactHistoryLimit
        ];
        if ( !contactChanges.isEmpty() ) {
            for ( NSP_Sub_Client_Contact__History existingSubClientContacts : contactChanges ) {
                assetIds.add( existingSubClientContacts.Parent.NSP_Sub_Client__r.NSP_Asset__c );
            }
        }
        // start the batch with the Assets that need to be re-evaluated...
        return Database.getqueryLocator(
            [
                SELECT Id
                FROM Asset
                WHERE ( Id IN :assetIds )
            ]
        );
    }

    public void execute( Database.BatchableContext bc , List<Asset> scope ) {
        try {
            Set<Id> assetIds = new Set<Id>();
            for ( Asset record : scope ) {
                assetIds.add( record.Id );
            }
            this.handleAssets( assetIds );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_SubClientAssetStateSyncJob.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    public Boolean handleAssets( Set<Id> assetIds ) {
        Boolean response = false;
        try{
            if ( ( assetIds != null ) && !assetIds.isEmpty() ) {
                Map<Id,NSP_Sub_Client__c> existingSubClients = new Map<Id,NSP_Sub_Client__c>(
                    [
                        SELECT Id
                        FROM NSP_Sub_Client__c
                        WHERE ( NSP_Asset__c = :assetIds )
                    ]
                );
                if ( !existingSubClients.isEmpty() ) {
                    //Get details for sub client contact where sub client != null
                    List<NSP_Sub_Client_Contact__c> subClientContact = [
                        SELECT
                        Id ,
                        NSP_Sub_Client__c ,
                        NSP_Paid_Non_Paid__c ,
                        NSP_Employee_Status__c ,
                        NSP_Union_Employee__c
                        FROM NSP_Sub_Client_Contact__c
                        WHERE ( NSP_Sub_Client__c = :existingSubClients.keyset() )
                        LIMIT :NSP_SubClientAssetStateSyncJob.soqlContactLimit
                    ];
                    if ( !subClientContact.isEmpty() ) {
                        response  = NSP_SubClientAssetStateSyncJob.updateStateOfOperation(
                            subClientContact ,
                            existingSubClients ,
                            assetIds
                        );
                    }
                }
            }
        }catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_SubClientAssetStateSyncJob.class.getName() ,
                'handleAssets' ,
                e
            );
        }
        return response;
    }

    public void finish( Database.BatchableContext bc ) {
        // intentionally blank...
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionlly static to allow Custom Settings to modify the attributes a Scheduled job...
    //

    private static SubClientAssetStateSyncJobSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = SubClientAssetStateSyncJobSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    // is the Schedulable enabled for execution???
    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( NSP_SubClientAssetStateSyncJob.settings != null ) {
                    local = NSP_SubClientAssetStateSyncJob.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    private static Integer batchSize {
        private get {
            if ( batchSize == null ) {
                Integer local = 200;
                if ( ( NSP_SubClientAssetStateSyncJob.settings != null )
                    && ( NSP_SubClientAssetStateSyncJob.settings.BatchSize__c != null )
                    )
                {
                    local = NSP_SubClientAssetStateSyncJob.settings.BatchSize__c.intValue();
                }
                // batch size must be greater than zero...
                if ( local < 1 ) {
                    local = 1;
                }
                // batch size must be less than or equal to 2000...
                if ( local > 2000 ) {
                    local = 2000;
                }
                batchSize = local;
            }
            return batchSize;
        }
        private set;
    }

    private static Integer soqlAddressHistoryLimit {
        private get {
            if ( soqlAddressHistoryLimit == null ) {
                Integer local = 25000;
                if ( ( NSP_SubClientAssetStateSyncJob.settings != null )
                    && ( NSP_SubClientAssetStateSyncJob.settings.SoqlAddressHistoryLimit__c != null )
                    )
                {
                    local = NSP_SubClientAssetStateSyncJob.settings.SoqlAddressHistoryLimit__c.intValue();
                }
                // limit must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                soqlAddressHistoryLimit = local;
            }
            return soqlAddressHistoryLimit;
        }
        private set;
    }

    private static Integer soqlContactHistoryLimit {
        private get {
            if ( soqlContactHistoryLimit == null ) {
                Integer local = 25000;
                if ( ( NSP_SubClientAssetStateSyncJob.settings != null )
                    && ( NSP_SubClientAssetStateSyncJob.settings.SoqlContactHistoryLimit__c != null )
                    )
                {
                    local = NSP_SubClientAssetStateSyncJob.settings.SoqlContactHistoryLimit__c.intValue();
                }
                // limit must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                soqlContactHistoryLimit = local;
            }
            return soqlContactHistoryLimit;
        }
        private set;
    }

    private static Integer soqlAddressLimit {
        private get {
            if ( soqlAddressLimit == null ) {
                Integer local = 25000;
                if ( ( NSP_SubClientAssetStateSyncJob.settings != null )
                    && ( NSP_SubClientAssetStateSyncJob.settings.SoqlAddressLimit__c != null )
                    )
                {
                    local = NSP_SubClientAssetStateSyncJob.settings.SoqlAddressLimit__c.intValue();
                }
                // limit must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                soqlAddressLimit = local;
            }
            return soqlAddressLimit;
        }
        private set;
    }

    private static Integer soqlContactLimit {
        private get {
            if ( soqlContactLimit == null ) {
                Integer local = 25000;
                if ( ( NSP_SubClientAssetStateSyncJob.settings != null )
                    && ( NSP_SubClientAssetStateSyncJob.settings.SoqlContactLimit__c != null )
                    )
                {
                    local = NSP_SubClientAssetStateSyncJob.settings.SoqlContactLimit__c.intValue();
                }
                // limit must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                soqlContactLimit = local;
            }
            return soqlContactLimit;
        }
        private set;
    }

    //
    //
    //

    // ********************************************************************************************
    // MethodName: updateStateOfOperation
    // Description : This method is used to Update State of Operation field on Asset and Sub Client based on State under SCCA.
    // Params:       List<NSP_Sub_Client_Contact__c> subClientContact
    // ********************************************************************************************
    private static Boolean updateStateOfOperation(
        List<NSP_Sub_Client_Contact__c> subClientContact ,
        Map<Id,NSP_Sub_Client__c> existingSubClients ,
        Set<Id> setOfParentIds
    )
    {
        Boolean response = true;
        Map<Id, String> subClientByStates = new  Map<Id, String>();
        Map<Id, String> assetByStates = new  Map<Id, String>();
        List<NSP_Sub_Client__c> subClientStateToBeUpdated = new List<NSP_Sub_Client__c>();
        List<Asset> assetStateToBeUpdated = new List<Asset>();
        //Below code helps to store states for respective sub client
        List<NSP_Sub_Client_Contact_Address__c> subClientConAddresses = [
            SELECT
            Id , NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Asset__c , NSP_Address_Type__c ,
            NSP_State__c , NSP_Sub_Client_Contact__c , NSP_Sub_Client_Contact__r.NSP_Sub_Client__c
            FROM NSP_Sub_Client_Contact_Address__c
            WHERE (
                NSP_Sub_Client_Contact__c = :subClientContact
                AND NSP_Sub_Client_Contact__r.NSP_Sub_Client__c != null
                AND NSP_State__c != null
                AND NSP_Sub_Client_Contact__r.NSP_Paid_Non_Paid__c = 'Paid WSEE'
                AND NSP_Sub_Client_Contact__r.NSP_Employee_Status__c != 'TERMINATED'
            )
            LIMIT :NSP_SubClientAssetStateSyncJob.soqlAddressLimit
        ];
        for(NSP_Sub_Client_Contact_Address__c subClientConAddress : subClientConAddresses ) {
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
            Database.SaveResult[] results = Database.update(subClientStateToBeUpdated, false);
            if( !NSP_SubClientAssetStateSyncJob.isUpdateSuccessful(results) ) {
                response = false;
            }
        }
        if(!assetStateToBeUpdated.isEmpty()) {
            Database.SaveResult[] results = Database.update(assetStateToBeUpdated, false);
            if( !NSP_SubClientAssetStateSyncJob.isUpdateSuccessful(results) ) {
                response = false;
            }
        }
        return response;
    }

    private static Boolean isUpdateSuccessful( Database.SaveResult[] results ) {
        for( Database.SaveResult result : results ) {
            if( !result.isSuccess() ) {
                return false;
            }
        }
        return true;
    }
}
//