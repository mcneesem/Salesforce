public with sharing class DocusignAMR {
    // test w/ DocusignAMRTest (95%)
    
    @AuraEnabled(cacheable=true)  
    public static Map<Id, String> getPrimaryAccount(Id accountId) {
        Map<Id, String> accountMap = new Map<Id, String>();
        if (accountId != null) {
            // Query to get the primary account Id associated with the given accountId
            NSP_Account_Group_Member__c accountGroupMember = [
                SELECT NSP_Group__r.Account__c 
                FROM NSP_Account_Group_Member__c 
                WHERE NSP_Type__c =: NSP_ServiceConstants.RENEWAL_PROBABILITY 
                AND NSP_Member_Account__c = :accountId
                LIMIT 1
            ];
            
            Id primaryAccountId = null;
            if (accountGroupMember != null && accountGroupMember.NSP_Group__r != null && accountGroupMember.NSP_Group__r.Account__c != null) {
                primaryAccountId = accountGroupMember.NSP_Group__r.Account__c;
            } else {
                //If no Primary Account in Acc Group Member, take the current Account ID
                primaryAccountId = accountId;
            }
            
            // Query to get the account name
            Account account = null;
            if(primaryAccountId != null){
                account = [
                    SELECT Name 
                    FROM Account 
                    WHERE Id = :primaryAccountId
                    LIMIT 1
                ];
            }
            if (account != null) {
                accountMap.put(primaryAccountId, account.Name);
            }
        }
        return accountMap;
    }
    
    @AuraEnabled(cacheable=true)
    public static DocuSign_Settings__c getDocusignURL() {
        DocuSign_Settings__c result = null;
        
        // Query to get the DocuSign settings where IsEnabled__c is TRUE
        List<DocuSign_Settings__c> docusignSettingsList = [
            SELECT AccountId__c, AccountNumber__c, CLMBaseUrl__c 
            FROM DocuSign_Settings__c 
            WHERE IsEnabled__c = TRUE
            LIMIT 1
        ];
        
        if (!docusignSettingsList.isEmpty()) {
            result = docusignSettingsList[0];
        }
        
        return result;
    }
}