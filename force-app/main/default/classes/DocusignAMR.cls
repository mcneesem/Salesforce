public with sharing class DocusignAMR {
    // test w/ DocusignAMRTest (94%)
    
    @AuraEnabled(cacheable=true)  
    public static Map<Id, String> getPrimaryAccount(Id accountId) {
        Map<Id, String> accountMap = new Map<Id, String>();
        if (accountId != null) {
            // Query to get the primary account Id associated with the given accountId
            List<NSP_Account_Group_Member__c> accountGroupMembers = [
                SELECT NSP_Group__r.Account__c 
                FROM NSP_Account_Group_Member__c 
                WHERE NSP_Type__c =: NSP_ServiceConstants.RENEWAL_PROBABILITY 
                AND NSP_Member_Account__c = :accountId
                LIMIT 1
            ];
            NSP_Account_Group_Member__c accountGroupMember = null;
            if ( ( accountGroupMembers != null ) && !accountGroupMembers.isEmpty() ) {
                accountGroupMember = accountGroupMembers[0];
            }
            
            Id primaryAccountId = accountId;
            if (accountGroupMember != null && accountGroupMember.NSP_Group__r != null && accountGroupMember.NSP_Group__r.Account__c != null) {
                primaryAccountId = accountGroupMember.NSP_Group__r.Account__c;
            }
            
            // Query to get the account name
            List<Account> records = null;
            if ( primaryAccountId != null ) {
                records = [
                    SELECT Name 
                    FROM Account 
                    WHERE Id = :primaryAccountId
                    LIMIT 1
                ];
            }
            if ( ( records != null ) && !records.isEmpty() ) {
                accountMap.put( primaryAccountId , records[0].Name );
            }
        }
        return accountMap;
    }
    
    @AuraEnabled(cacheable=true)
    public static NSP_Docusign_Account_Details__c getDocusignURL() {
        return NSP_Docusign_Account_Details__c.getInstance( UserInfo.getUserId() );
    }
}