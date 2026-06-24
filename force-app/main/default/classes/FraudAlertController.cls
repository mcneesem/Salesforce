/**
 * @description AuraEnabled controller for the Fraud Alert Banner LWC component.
 *              Determines whether a Fraud Alert should be displayed on Contact,
 *              Account, Opportunity, and Case record pages by evaluating the
 *              Fraud_Alert__c field on related Contact records.
 */
public with sharing class FraudAlertController {

    // test w/ FraudAlertControllerTest (80%)

    private static final String OBJECT_ACCOUNT     = 'Account';
    private static final String OBJECT_CASE        = 'Case';

    // ─────────────────────────────────────────────────────────────────────────
    // Public AuraEnabled API
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description Determines whether a fraud alert should be displayed for the
     *              given record.
     * @param recordId      The Salesforce record Id of the current page context record.
     * @param objectApiName The API name of the object (Contact, Account, Opportunity, Case).
     * @return              True if at least one associated Contact has Fraud_Alert__c = true,
     *                      false otherwise.
     * @throws AuraHandledException if an unexpected error occurs during execution.
     * @example
     * Boolean result = FraudAlertController.hasFraudAlert(contactId, 'Contact');
     */

    @AuraEnabled(cacheable=false)
    public static Boolean hasFraudAlert(Id recordId, String objectApiName) {
        Boolean isFraudAlert = false;
        try {
            if (recordId != null && !String.isBlank(objectApiName)) {
                String objectName = objectApiName.trim();

                if (objectName == OBJECT_ACCOUNT) {
                    isFraudAlert = checkAccountFraudAlert(recordId);
                }
                else if (objectName == OBJECT_CASE) {
                    isFraudAlert = checkCaseFraudAlert(recordId);
                }
            }

            return isFraudAlert ;

        } catch (Exception ex) {
            throw new AuraHandledException(
                'Unable to evaluate fraud alert status. Please contact your system administrator.'
            );
        }
    }


    /**
     * @description Checks whether any Contact related to the Account via
     *              AccountContactRelation has Fraud_Alert__c = true.
     * @param accountId The Account record Id.
     * @return          True if at least one related Contact has Fraud_Alert__c = true,
     *                  false otherwise.
     */
    private static Boolean checkAccountFraudAlert(Id accountId) {
        List<AccountContactRelation> relations = [
            SELECT Id
            FROM AccountContactRelation
            WHERE AccountId = :accountId
              AND Contact.Fraud_Alert__c = true
            WITH USER_MODE
            LIMIT 1
        ];
        return !relations.isEmpty();
    }

    /**
     * @description Checks whether the Contact linked to the Case via ContactId has Fraud_Alert__c = true.
     * @param caseId The Case record Id.
     * @return       True if the associated Contact has Fraud_Alert__c = true,
     *               false otherwise.
     */
    private static Boolean checkCaseFraudAlert(Id caseId) {
        List<NSP_Case_Contacts__c> caseContacts = [
            SELECT Id
            FROM NSP_Case_Contacts__c
            WHERE NSP_Case__c = :caseId
            AND NSP_Contact__r.Fraud_Alert__c = true
            WITH USER_MODE
            LIMIT 1
        ];
        return !caseContacts.isEmpty();
    }
}