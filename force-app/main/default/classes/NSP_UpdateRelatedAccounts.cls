// intentionally `without sharing` to prevent ~ INSUFFICIENT_ACCESS_OR_READONLY, insufficient access rights on object id
// ~ Sales Engineers updating Opportunity records do not neccessariy have access to the associated Account record...
public without sharing class NSP_UpdateRelatedAccounts implements Queueable {
    // test w/ NSP_UpdateRelatedAccountsTest (94%)
    // test w/ NSP_OpportunityTriggerHelperTest (64%)

    //
    // Queueable
    //

    private Set<String> recordIds = null;
    private String action = null;

    private NSP_UpdateRelatedAccounts( Set<String> accountIds , String mode ) {
        this.recordIds = accountIds;
        this.action = mode;
    }

    private static void enqueueJob( Set<String> accountIds , String mode ) {
        if ( NSP_UpdateRelatedAccounts.isEnabledQueueable
            && ( accountIds != null )
            && !accountIds.isEmpty()
            && !System.isQueueable() // prevent AsyncExceptions...
            && ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) // prevent LimitExceptions...
            )
        {
            System.enqueueJob(
                new NSP_UpdateRelatedAccounts(
                    accountIds ,
                    mode
                ) ,
                NSP_UpdateRelatedAccounts.delayMinutes
            );
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

    private static Boolean isEnabledFuture {
        private get {
            if ( isEnabledFuture == null ) {
                Boolean local = false;
                if ( NSP_UpdateRelatedAccounts.settings != null ) {
                    local = NSP_UpdateRelatedAccounts.settings.IsEnabledFuture__c;
                }
                isEnabledFuture = local;
            }
            return isEnabledFuture;
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
                // step size must non-negative...
                if ( local < 0 ) {
                    local = 0;
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
        } else if ( NSP_UpdateRelatedAccounts.isEnabledFuture
            && !System.isFuture() // prevent AsyncExceptions...
            && Limits.getFutureCalls() < Limits.getLimitFutureCalls() // prevent LimitExceptions...
            )
        {
            NSP_UpdateRelatedAccounts.updateRelatedAccountsFuture( accountIdSet );
        }
    }

    @future
    private static void updateRelatedAccountsFuture( Set<String> accountIdSet ) {
        NSP_UpdateRelatedAccounts.updateRelatedAccountsInternal( accountIdSet );
    }

    private static void updateRelatedAccountsInternal( Set<String> accountIdSet ) {
        try {
            List<Account> accountTobeUpdatedList = new List<Account>();
            for ( Account accountObj : [
                        SELECT Id , NSP_Last_Updated__c
                        FROM Account
                        WHERE (
                            ( Id IN :accountIdSet )
                            AND ( NSP_Last_Updated__c != TODAY )
                        )
                    ]
                )
            {
                accountObj.NSP_Last_Updated__c = Date.today(); // DEPRECATED
                accountTobeUpdatedList.add( accountObj );
            }
            if ( !accountTobeUpdatedList.isEmpty() ) {
                update accountTobeUpdatedList;
            }
        } catch( Exception e ) {
            NSP_UpdateRelatedAccounts.handleException( e , 'updateRelatedAccountsInternal' );
        }
    }

    // Update Account status to 'Prospecting' once opportunity is added and there are no assets
    public static void updateAccountStatus( Set<String> accountIdSet ) {
        if ( NSP_UpdateRelatedAccounts.isEnabledQueueable ) {
            NSP_UpdateRelatedAccounts.enqueueJob( accountIdSet , 'updateAccountStatus' );
        } else if ( NSP_UpdateRelatedAccounts.isEnabledFuture
            && !System.isFuture() // prevent AsyncExceptions...
            && Limits.getFutureCalls() < Limits.getLimitFutureCalls() // prevent LimitExceptions...
            )
        {
            NSP_UpdateRelatedAccounts.updateAccountStatusFuture( accountIdSet );
        }
    }

    @future
    private static void updateAccountStatusFuture( Set<String> accountIdSet ) {
        NSP_UpdateRelatedAccounts.updateAccountStatusInternal( accountIdSet );
    }

    private static void updateAccountStatusInternal( Set<String> accountIdSet ) {
        try {
            List<Account> accountTobeUpdatedList = new List<Account>();
            for ( Account accountObj : [
                        SELECT
                            Id ,
                            NSP_Sales_Service_Account_Status__c ,
                            ( SELECT Id , RecordType.Name FROM Assets ) ,
                            (
                                SELECT Id , StageName
                                FROM Opportunities
                                WHERE ( StageName NOT IN ( 'Closed Won' , 'Closed Lost' ) )
                            )
                        FROM Account
                        WHERE (
                            ( Id IN :accountIdSet )
                            AND ( NSP_Sales_Service_Account_Status__c != :NSP_SalesConstants.PROSPECTING )
                        )
                    ]
                )
            {
                List<Asset> filteredAssets = NSP_AssetServiceTriggerHelper.filterOnAssetRecordTypes( accountObj.Assets );
                if ( ( filteredAssets != null )
                    && ( filteredAssets.isEmpty() )
                    )
                {
                    accountObj.NSP_Sales_Service_Account_Status__c = NSP_SalesConstants.PROSPECTING;
                    accountTobeUpdatedList.add( accountObj );
                }
            }
            if ( !accountTobeUpdatedList.isEmpty() ) {
                update accountTobeUpdatedList;
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