public with sharing class SalesVisualIndicatorHelper {
    //  test w/ SalesVisualIndicatorHelperTest  100%
    
    // returns the account details
    // @param accId Id related to account.
    @AuraEnabled(cacheable=true)
    public static AccountWrapper getAccount(String accId ) {
        
        AccountWrapper accountWrapper = new  AccountWrapper();
        List<Account> account = [SELECT NSP_Current_Provider__c FROM Account WHERE id =: accId];

        if( !account.isEmpty() ){
            accountWrapper.isWorkday = account[0].NSP_Current_Provider__c != null && account[0].NSP_Current_Provider__c.equals('Workday');
        }

        return accountWrapper;
    }

    public class AccountWrapper{
        @AuraEnabled
        public Boolean isWorkday = false;
    }
}