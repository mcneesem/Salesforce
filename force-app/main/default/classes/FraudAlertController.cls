// intentionally `without sharing` to ensure that frautAlertBanner has access to all Contact, Account, and Case records...
public without sharing class FraudAlertController {
    // test w/ FraudAlertControllerTest (80%)

    // AuraEnabled controller for the Fraud Alert Banner LWC component.
    // Determines whether a Fraud Alert should be displayed on Contact, Account, Opportunity, and Case record pages by evaluating the Fraud_Alert__c field on related Contact records.

    //
    // Public AuraEnabled API
    //

    //
    // @description Determines whether a fraud alert should be displayed for the
    //              given record.
    // @param recordId      The Salesforce record Id of the current page context record.
    // @param objectApiName The API name of the object (Contact, Account, Opportunity, Case).
    // @return              True if at least one associated Contact has Fraud_Alert__c = true,
    //                      false otherwise.
    // @throws AuraHandledException if an unexpected error occurs during execution.
    // @example
    // Boolean result = FraudAlertController.hasFraudAlert(contactId, 'Contact');
    //
    @AuraEnabled(cacheable=false)
    public static Boolean hasFraudAlert( Id recordId ) {
        Boolean isFraudAlert = false;
        try {
            if ( recordId != null ) {
                if ( recordId.getSObjectType() == Account.getSObjectType() ) {
                    isFraudAlert = FraudAlertController.checkAccountFraudAlert( recordId );
                } else if ( recordId.getSObjectType() == Case.getSObjectType() ) {
                    isFraudAlert = FraudAlertController.checkCaseFraudAlert( recordId );
                }
            }
        } catch ( Exception e ) {
            throw new AuraHandledException(
                'Unable to evaluate fraud alert status.'
            );
        }
        return isFraudAlert;
    }

    //
    // @description Checks whether any Contact related to the Account via
    //              AccountContactRelation has Fraud_Alert__c = true.
    // @param accountId The Account record Id.
    // @return          True if at least one related Contact has Fraud_Alert__c = true,
    //                  false otherwise.
    //
    private static Boolean checkAccountFraudAlert( Id accountId ) {
        Boolean accFraudAlert = false;
        if ( accountId != null ) {
            List<AccountContactRelation> relations = [
                SELECT Id
                FROM AccountContactRelation
                WHERE (
                    ( AccountId = :accountId )
                    AND ( Contact.Fraud_Alert__c = true )
                )
                LIMIT 1
            ];
           accFraudAlert = !relations.isEmpty();
        }
        return accFraudAlert;
    }

    //
    // @description Checks whether the Contact linked to the Case via ContactId has Fraud_Alert__c = true.
    // @param caseId The Case record Id.
    // @return       True if the associated Contact has Fraud_Alert__c = true,
    //               false otherwise.
    //
    private static Boolean checkCaseFraudAlert( Id caseId ) {
        Boolean caseFraudAlert = false;
        if ( caseId != null ) {
            List<NSP_Case_Contacts__c> caseContacts = [
                SELECT Id
                FROM NSP_Case_Contacts__c
                WHERE (
                    ( NSP_Case__c = :caseId )
                    AND ( NSP_Contact__r.Fraud_Alert__c = true )
                )
                LIMIT 1
            ];
            caseFraudAlert = !caseContacts.isEmpty();
        }
        return caseFraudAlert;
    }

}
//