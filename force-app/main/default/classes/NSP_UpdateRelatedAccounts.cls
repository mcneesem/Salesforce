// intentionally `without sharing` to prevent ~ INSUFFICIENT_ACCESS_OR_READONLY, insufficient access rights on object id
// ~ Sales Engineers updating Opportunity records do not neccessariy have access to the associated Account record...
public without sharing class NSP_UpdateRelatedAccounts {
    // test w/ NSP_UpdateRelatedAccountsTest (90%)
    // test w/ NSP_OpportunityTriggerHelperTest (64%)

    // Updates the last updated date on the related accounts(this helps in identifying the account that can be set as inactive).
    public static void updateRelatedAccounts( Set<String> accountIdSet ) {
        if ( !System.isFuture() // prevent AsyncExceptions...
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
        if ( !System.isFuture() // prevent AsyncExceptions...
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