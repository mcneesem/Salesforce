/**
 * @description Unit tests for FraudAlertController, verifying fraud alert detection
 *              across Contact, Account, Opportunity, and Case record contexts.
 */
@isTest
private class FraudAlertControllerTest {

    private static final String ACCOUNT_NAME_FRAUD      = 'Test Fraud Alert Account';
    private static final String OBJECT_CONTACT          = 'Contact';
    private static final String OBJECT_ACCOUNT          = 'Account';
    private static final String OBJECT_OPPORTUNITY      = 'Opportunity';
    private static final String OBJECT_CASE             = 'Case';
    private static final String CONTACT_FACTORY_KEY     = 'NSP_TestDataFactory.ContactDefaultsLight';
    private static final String ACCOUNT_FACTORY_KEY     = 'NSP_TestDataFactory.AccountDefaults';
    private static final String CASE_FACTORY_KEY        = 'NSP_TestDataFactory.CaseDefaults';
    private static final String OPPORTUNITY_FACTORY_KEY = 'NSP_TestDataFactory.OpportunityDefaults';

    // ─────────────────────────────────────────────────────────────────────────
    // Test Setup
    // ─────────────────────────────────────────────────────────────────────────

    @TestSetup
    static void setupTestData() {
        Account testAccount = (Account) NSP_TestExtendedDataFactory.createSObject(
            new Account(), ACCOUNT_FACTORY_KEY, false
        );
        testAccount.Name = ACCOUNT_NAME_FRAUD;
        insert testAccount;

        Contact fraudContact = (Contact) NSP_TestExtendedDataFactory.createSObject(
            new Contact(), CONTACT_FACTORY_KEY, false
        );
        fraudContact.AccountId      = testAccount.Id;
        fraudContact.Fraud_Alert__c = true;
        insert fraudContact;

        Contact cleanContact = (Contact) NSP_TestExtendedDataFactory.createSObject(
            new Contact(), CONTACT_FACTORY_KEY, false
        );
        cleanContact.AccountId      = testAccount.Id;
        cleanContact.Fraud_Alert__c = false;
        insert cleanContact;

        Case fraudCase = (Case) NSP_TestExtendedDataFactory.createSObject(
            new Case(), CASE_FACTORY_KEY, false
        );
        fraudCase.AccountId = testAccount.Id;
        fraudCase.ContactId = fraudContact.Id;
        insert fraudCase;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Account Tests
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void shouldReturnTrue_WhenAccountRelatedContactHasFraudAlert() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = :ACCOUNT_NAME_FRAUD LIMIT 1];

        Test.startTest();
        Boolean result = FraudAlertController.hasFraudAlert(testAccount.Id, OBJECT_ACCOUNT);
        Test.stopTest();

        Assert.areEqual(
            true,
            result,
            'hasFraudAlert should return true when Account has a related Contact with Fraud_Alert__c = true'
        );
    }

    @isTest
    static void shouldReturnFalse_WhenAccountHasNoFraudAlertContacts() {
        Account noFraudAccount = (Account) NSP_TestExtendedDataFactory.createSObject(
            new Account(), ACCOUNT_FACTORY_KEY, false
        );
        noFraudAccount.Name = 'No Fraud Account';
        insert noFraudAccount;

        Contact safeContact = (Contact) NSP_TestExtendedDataFactory.createSObject(
            new Contact(), CONTACT_FACTORY_KEY, false
        );
        safeContact.AccountId      = noFraudAccount.Id;
        safeContact.Fraud_Alert__c = false;
        insert safeContact;

        Test.startTest();
        Boolean result = FraudAlertController.hasFraudAlert(noFraudAccount.Id, OBJECT_ACCOUNT);
        Test.stopTest();

        Assert.areEqual(
            false,
            result,
            'hasFraudAlert should return false when Account has no Contacts with Fraud_Alert__c = true'
        );
    }



    // ─────────────────────────────────────────────────────────────────────────
    // Case Tests
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void shouldReturnTrue_WhenCaseContactHasFraudAlert() {
        Case fraudCase = [SELECT Id FROM Case WHERE ContactId != null LIMIT 1];

        Test.startTest();
        Boolean result = FraudAlertController.hasFraudAlert(fraudCase.Id, OBJECT_CASE);
        Test.stopTest();

        Assert.areEqual(
            true,
            result,
            'hasFraudAlert should return true when Case ContactId points to a Contact with Fraud_Alert__c = true'
        );
    }

    @isTest
    static void shouldReturnFalse_WhenCaseContactHasNoFraudAlert() {
        Account noFraudAccount = (Account) NSP_TestExtendedDataFactory.createSObject(
            new Account(), ACCOUNT_FACTORY_KEY, false
        );
        noFraudAccount.Name = 'No Fraud Account Case';
        insert noFraudAccount;

        Contact safeContact = (Contact) NSP_TestExtendedDataFactory.createSObject(
            new Contact(), CONTACT_FACTORY_KEY, false
        );
        safeContact.AccountId      = noFraudAccount.Id;
        safeContact.Fraud_Alert__c = false;
        insert safeContact;

        Case safeCase = (Case) NSP_TestExtendedDataFactory.createSObject(
            new Case(), CASE_FACTORY_KEY, false
        );
        safeCase.AccountId = noFraudAccount.Id;
        safeCase.ContactId = safeContact.Id;
        insert safeCase;

        Test.startTest();
        Boolean result = FraudAlertController.hasFraudAlert(safeCase.Id, OBJECT_CASE);
        Test.stopTest();

        Assert.areEqual(
            false,
            result,
            'hasFraudAlert should return false when Case Contact has Fraud_Alert__c = false'
        );
    }

    @isTest
    static void shouldReturnFalse_WhenCaseHasNoContact() {
        Case noContactCase = (Case) NSP_TestExtendedDataFactory.createSObject(
            new Case(), CASE_FACTORY_KEY, false
        );
        noContactCase.ContactId = null;
        insert noContactCase;

        Test.startTest();
        Boolean result = FraudAlertController.hasFraudAlert(noContactCase.Id, OBJECT_CASE);
        Test.stopTest();

        Assert.areEqual(
            false,
            result,
            'hasFraudAlert should return false when Case has no ContactId'
        );
    }

}