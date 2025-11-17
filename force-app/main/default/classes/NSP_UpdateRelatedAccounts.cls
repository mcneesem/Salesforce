//
// @Description: This class is created to update nsp_last_updated__c on Account
// When ever Opportunity is updated. And this is running in without sharing
// context because while creating quote, Sales Engineering will not have access
// to Account. So to update NSP_Last_Updated__c on Account, this class is
// running in Without Sharing Context and is referred in
// NSP_OpportunityTriggerHelper class
//
// @CreatedDate: 1/25/2022
// @Story/Defect: DF-01058
//
public without sharing class NSP_UpdateRelatedAccounts {
    // test w/ NSP_UpdateRelatedAccountsTest (90%)
    // test w/ NSP_OpportunityTriggerHelperTest (64%)

    // Updates the last updated date on the related accounts(this helps in identifying the account that can be set as inactive).
    // @param accountIdSet Set of account ids related to opportunity.
    // @return void
    public static void updateRelatedAccounts( Set<String> accountIdSet ) {
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
            //Stamping last updated date on the account records
            accountObj.NSP_Last_Updated__c = Date.today();
            accountTobeUpdatedList.add( accountObj );
        }
        if ( !accountTobeUpdatedList.isEmpty() ) {
            try {
                update accountTobeUpdatedList;
            } catch( Exception e ) {
                NSP_UpdateRelatedAccounts.handleException( e , 'updateRelatedAccounts' );
            }
        }
    }

    public static void updateAccountStatus( Set<String> accountIdSet ) {
        if ( Limits.getFutureCalls() < Limits.getLimitFutureCalls() ) { // prevent LimitExceptions...
            NSP_UpdateRelatedAccounts.updateAccountStatusFuture( accountIdSet );
        }
    }

    // Update Account status to 'Prospecting' once opportunity is added and there are no assets
    // @param accountIdSet Set of account ids related to opportunity.
    // @return void
    @future
    public static void updateAccountStatusFuture( Set<String> accountIdSet ) {
        updateAccountStatusInternal(accountIdSet);
    }

    // Update Account status to 'Prospecting' once opportunity is added and there are no assets
    // @param accountIdSet Set of account ids related to opportunity.
    // @return void
    private static void updateAccountStatusInternal( Set<String> accountIdSet ){
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
        } catch( Exception e ) {
            NSP_UpdateRelatedAccounts.handleException( e , 'updateAccountStatus' );
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