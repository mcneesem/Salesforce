public with sharing class SalesVisualIndicatorHelper {
    // test w/ SalesVisualIndicatorHelperTest (100%)

    // returns the account details
    // @param accId Id related to account.
    @AuraEnabled(cacheable=true)
    public static AccountWrapper getAccount( String accId ) {
        List<Account> records = [
            SELECT NSP_Current_Provider__c
            FROM Account
            WHERE ( Id = :accId )
        ];
        Account record = null;
        if ( ( records != null ) && !records.isEmpty() ) {
            record = records[0];
        }
        AccountWrapper response = new AccountWrapper();
        if ( record != null ) {
            response.isWorkday = (
                String.isNotBlank( record.NSP_Current_Provider__c )
                && record.NSP_Current_Provider__c.equals( 'Workday' )
            );
        }
        return response;
    }

    public class AccountWrapper{
        @AuraEnabled
        public Boolean isWorkday = false;
    }

}
//
