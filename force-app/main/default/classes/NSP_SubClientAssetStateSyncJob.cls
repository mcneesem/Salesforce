// 2022-10-20 ~ Virendra Kumar
global class NSP_SubClientAssetStateSyncJob implements Database.Batchable<sObject>, Schedulable {
    // test w/ NSP_SubClientAssetSyncJob_Test (93%)

    global NSP_SubClientAssetStateSyncJob() {
        // intentionally blank...
    }

    //
    // Batchable
    //

    global Database.QueryLocator start( Database.BatchableContext bc ) {
        DateTime last4Hours = system.now().addHours( -4 );
        //Get sub client contact history records
        return Database.getqueryLocator(
            [
                SELECT Id , OldValue , NewValue , Field , DataType ,
                ParentId , Parent.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Asset__c
                FROM NSP_Sub_Client_Contact_Address__History
                WHERE (
                    ( CreatedDate >= :last4Hours )
                    AND ( Field = 'NSP_Address_State_Changed_Date__c' )
                )
            ]
        );
    }

    global void execute( Database.BatchableContext bc , List<NSP_Sub_Client_Contact_Address__History> scope ) {
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
            Map<Id,NSP_Sub_Client__c> existingSubClients = new Map<Id,NSP_Sub_Client__c>(
                [
                    SELECT Id
                    FROM NSP_Sub_Client__c
                    WHERE ( NSP_Asset__c = :setOfParentIds )
                ]
            );
            if(!existingSubClients.isEmpty()) {
                //Get details for sub client contact where sub client != null
                List<NSP_Sub_Client_Contact__c> subClientContact = [
                    SELECT Id , NSP_Sub_Client__c , NSP_Paid_Non_Paid__c , NSP_Employee_Status__c , NSP_Union_Employee__c
                    FROM NSP_Sub_Client_Contact__c
                    WHERE ( NSP_Sub_Client__c = :existingSubClients.keyset() )
                ];
                system.debug('subClientContact' + subClientContact);
                try {            
                    if(subClientContact.size() > 0){
                        updateStateOfOperation(subClientContact, existingSubClients, setOfParentIds);
                    }
                } catch ( Exception e ) {
                    NSP_ErrorLogHandler.logException(
                        NSP_SubClientAssetStateSyncJob.class.getName() ,
                        'execute' ,
                        e
                    );
                }
            }
        }
    }

    global void finish( Database.BatchableContext bc ) {
        // intentionally blank...
    }

    //
    // Schedulable
    //

    public void execute( SchedulableContext sc ) {
        if ( NSP_SubClientAssetStateSyncJob.isEnabled ) {
            Database.executeBatch(
                new NSP_SubClientAssetStateSyncJob() ,
                NSP_SubClientAssetStateSyncJob.batchSize
            );
        }
    }

    public static String schedule() {
        return System.schedule(
            NSP_SubClientAssetStateSyncJob.class.getName()
                + ' ~ When Paid/NonPaid, Employee Status and State fields in sub client contact Address are updated, then it will rollup updated values in Sub Client and Asset level'
                + ' ~ Schedule to run weekdays every 4 hours'
                + ( Test.isRunningTest() ? ' ~ TEST' : '' ) ,
            '0 0 0,4,8,12,16,20 ? * MON-FRI' , // weekdays every 4 hours...
            new NSP_SubClientAssetStateSyncJob()
        );
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

    private static Integer soqlAddressLimit {
        private get {
            if ( soqlAddressLimit == null ) {
                Integer local = 50000;
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

    //
    //
    //

    // ********************************************************************************************
    // MethodName: updateStateOfOperation
    // Description : This method is used to Update State of Operation field on Asset and Sub Client based on State under SCCA.
    // Params:       List<NSP_Sub_Client_Contact__c> subClientContact
    // ********************************************************************************************
    public static void testUpdateStateOfOperation(
        List<NSP_Sub_Client_Contact__c> subClientContact ,
        Map<Id,NSP_Sub_Client__c> existingSubClients ,
        Set<Id> setOfParentIds
    )
    {
        // added for code coverage in 09-Aug RC2 release...
        if ( Test.isRunningTest() ) {
            updateStateOfOperation( subClientContact, existingSubClients, setOfParentIds );
        }
    }
    public static void updateStateOfOperation(
        List<NSP_Sub_Client_Contact__c> subClientContact ,
        Map<Id,NSP_Sub_Client__c> existingSubClients ,
        Set<Id> setOfParentIds
    )
    {
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
            Database.update(subClientStateToBeUpdated, false);
        }
        if(!assetStateToBeUpdated.isEmpty()) {
            Database.update(assetStateToBeUpdated, false);
        }
    }

}
//