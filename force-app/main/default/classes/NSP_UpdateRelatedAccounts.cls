// intentionally `without sharing` to prevent ~ INSUFFICIENT_ACCESS_OR_READONLY, insufficient access rights on object id
// ~ Sales Engineers updating Opportunity records do not neccessariy have access to the associated Account record...
public without sharing class NSP_UpdateRelatedAccounts implements Queueable {
    // test w/ NSP_UpdateRelatedAccountsTest (93%)
    // test w/ NSP_OpportunityTriggerHelperTest (64%)

    //
    // Invocable
    //

    @InvocableMethod(label='Update Related Accounts' description='Centralize updates from Flow for Account.NSP_Last_Updated__c (action=updateRelatedAccounts) and Account.NSP_Sales_Service_Account_Status__c (action=updateAccountStatus).')
    public static void invoke( List<FlowInput> inputs ) {
        String mode = 'updateRelatedAccounts';
        Set<String> accountIds = new Set<String>();
        if ( ( inputs != null ) && !inputs.isEmpty() ) {
            for ( FlowInput input : inputs ) {
                if ( ( input.action == 'updateRelatedAccounts' )
                    || ( input.action == 'updateAccountStatus' )
                    )
                {
                    mode = input.action;
                }
                if ( String.isNotBlank( input.accountId ) ) {
                    accountIds.add( input.accountId );
                }
            }
        }
        NSP_UpdateRelatedAccounts.enqueueJob( accountIds , mode );
    }

    public class FlowInput {
        @InvocableVariable(label='Account Id' required=true)
        public String accountId;
        @InvocableVariable(label='Action' defaultValue='updateRelatedAccounts')
        public String action;
    }

    //
    // Queueable
    //

    private Set<String> recordIds = null;
    private String action = null;

    private NSP_UpdateRelatedAccounts( Set<String> accountIds , String mode ) {
        this.recordIds = accountIds;
        this.action = mode;
    }

    private static Map<String,Set<String>> recordIdsEnqueuedMap {
        private get {
            if ( recordIdsEnqueuedMap == null ) {
                Map<String,Set<String>> local = new Map<String,Set<String>>();
                local.put( 'updateRelatedAccounts' , new Set<String>() );
                local.put( 'updateAccountStatus' , new Set<String>() );
                recordIdsEnqueuedMap = local;
            }
            return recordIdsEnqueuedMap;
        }
        private set;
    }

    private static void enqueueJob( Set<String> accountIds , String mode ) {
        if ( NSP_UpdateRelatedAccounts.isEnabledQueueable
            && !System.isQueueable() // prevent AsyncExceptions...
            && ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) // prevent LimitExceptions...
            && ( accountIds != null )
            && !accountIds.isEmpty()
            && String.isNotBlank( mode )
            && ( NSP_UpdateRelatedAccounts.recordIdsEnqueuedMap != null )
            && NSP_UpdateRelatedAccounts.recordIdsEnqueuedMap.containsKey( mode )
            && ( NSP_UpdateRelatedAccounts.recordIdsEnqueuedMap.get( mode ) != null )
            )
        {
            // exclude any Account.Id values that were previously enqueued within the same Apex Transaction...
            accountIds.removeAll( NSP_UpdateRelatedAccounts.recordIdsEnqueuedMap.get( mode ) );
            if ( !accountIds.isEmpty() ) {
                // track all enqueued Account.Id values to prevent re-enqueue within the same Apex Transaction...
                NSP_UpdateRelatedAccounts.recordIdsEnqueuedMap.get( mode ).addAll( accountIds );
                // randomize delay to further defend against the double-DML found within our Opportunity/Account record-triggered logic...
                Integer delay = Math.mod(
                    System.now().millisecond() ,
                    NSP_UpdateRelatedAccounts.delayMinutes
                );
                // maintain single location where the operations of class is enqueued within our code base...
                System.enqueueJob(
                    new NSP_UpdateRelatedAccounts(
                        accountIds ,
                        mode
                    ) ,
                    delay
                );
            }
        }
    }

    public void execute( QueueableContext context ) {
        if ( NSP_UpdateRelatedAccounts.isEnabledQueueable
            && ( this.recordIds != null )
            && !this.recordIds.isEmpty()
            && String.isNotBlank( this.action )
            )
        {
            if ( this.action == 'updateRelatedAccounts' ) {
                NSP_UpdateRelatedAccounts.updateRelatedAccountsInternal( this.recordIds );
            } else if ( this.action == 'updateAccountStatus' ) {
                NSP_UpdateRelatedAccounts.updateAccountStatusInternal( this.recordIds );
            }
        }
    }

    //
    // Custom Settings
    //

    private static AccountTriggerSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = AccountTriggerSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabledQueueable {
        private get {
            if ( isEnabledQueueable == null ) {
                Boolean local = false;
                if ( NSP_UpdateRelatedAccounts.settings != null ) {
                    local = NSP_UpdateRelatedAccounts.settings.IsEnabledQueueable__c;
                }
                isEnabledQueueable = local;
            }
            return isEnabledQueueable;
        }
        private set;
    }

    private static Integer delayMinutes {
        private get {
            if ( delayMinutes == null ) {
                Integer local = 1;
                if ( ( NSP_UpdateRelatedAccounts.settings != null )
                    && ( NSP_UpdateRelatedAccounts.settings.DelayMinutes__c != null )
                    )
                {
                    local = NSP_UpdateRelatedAccounts.settings.DelayMinutes__c.intValue();
                }
                // step size must be positive...
                if ( local < 1 ) {
                    local = 1;
                }
                // step size must be less than or equal to 100...
                if ( local > 10 ) {
                    local = 10;
                }
                delayMinutes = local;
            }
            return delayMinutes;
        }
        private set;
    }

    //
    // External Entry Points
    // ~ updateRelatedAccounts
    // ~ updateAccountStatus
    //

    // Updates the last updated date on the related accounts(this helps in identifying the account that can be set as inactive).
    public static void updateRelatedAccounts( Set<String> accountIdSet ) {
        if ( NSP_UpdateRelatedAccounts.isEnabledQueueable ) {
            NSP_UpdateRelatedAccounts.enqueueJob( accountIdSet , 'updateRelatedAccounts' );
        }
    }

    private static void updateRelatedAccountsInternal( Set<String> accountIdSet ) {
        try {
            List<Account> records = new List<Account>();
            for ( Account record : [
                        SELECT Id , NSP_Last_Updated__c
                        FROM Account
                        WHERE (
                            ( Id IN :accountIdSet )
                            AND ( NSP_Last_Updated__c != TODAY )
                        )
                    ]
                )
            {
                record.NSP_Last_Updated__c = Date.today(); // DEPRECATED
                records.add( record );
            }
            if ( !records.isEmpty() ) {
                update records;
            }
        } catch ( Exception e ) {
            NSP_UpdateRelatedAccounts.handleException( e , 'updateRelatedAccountsInternal' );
        }
    }

    // Update Account status to 'Prospecting' once opportunity is added and there are no assets
    public static void updateAccountStatus( Set<String> accountIdSet ) {
        if ( NSP_UpdateRelatedAccounts.isEnabledQueueable ) {
            NSP_UpdateRelatedAccounts.enqueueJob( accountIdSet , 'updateAccountStatus' );
        }
    }

    private static void updateAccountStatusInternal( Set<String> accountIdSet ) {
        try {
            List<Account> records = new List<Account>();
            for ( Account record : [
                        SELECT
                            Id ,
                            NSP_Sales_Service_Account_Status__c ,
                            (
                                SELECT
                                    Id ,
                                    RecordType.Name ,
                                    RecordType.Id
                                FROM Assets
                            ) ,
                            (
                                SELECT Id , StageName
                                FROM Opportunities
                                WHERE (
                                    StageName NOT IN (
                                        'Closed Won' ,
                                        'Closed Lost'
                                    )
                                )
                            )
                        FROM Account
                        WHERE (
                            ( Id IN :accountIdSet )
                            AND (
                                NSP_Sales_Service_Account_Status__c NOT IN (
                                    'Prospecting' ,
                                    'Active' ,
                                    'On Demand' ,
                                    'Onboarding'
                                )
                            )
                        )
                    ]
                )
            {
                List<Asset> filteredAssets = NSP_AssetServiceTriggerHelper.filterOnAssetRecordTypes( record.Assets );
                if ( ( filteredAssets != null )
                    && ( filteredAssets.isEmpty() )
                    )
                {
                    record.NSP_Sales_Service_Account_Status__c = 'Prospecting';
                    records.add( record );
                }
            }
            if ( !records.isEmpty() ) {
                update records;
            }
        } catch ( Exception e ) {
            NSP_UpdateRelatedAccounts.handleException( e , 'updateAccountStatusInternal' );
        }
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_UpdateRelatedAccounts.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_UpdateRelatedAccounts.class.getName() ,
            methodName ,
            e
        );
    }

}
//