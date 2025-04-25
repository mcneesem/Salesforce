public with sharing class SalesVisualIndicatorHelper {
    //  test w/ SalesVisualIndicatorHelperTest  100%
    
    // returns the account details
    // @param accId Id related to account.
    @AuraEnabled(cacheable=true)
    public static AccountWrapper getAccount(String accId ) {
        
        AccountWrapper accountWrapper = new  AccountWrapper();
        Account account = [SELECT NSP_Current_Provider__c FROM Account WHERE id =: accId];

        if(account != null){
            accountWrapper.isWorkday = account.NSP_Current_Provider__c != null && account.NSP_Current_Provider__c.equals('Workday');
        }

        return accountWrapper;
    }

    public class AccountWrapper{
        @AuraEnabled
        public Boolean isWorkday = false;
    }
}