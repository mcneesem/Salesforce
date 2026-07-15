@isTest
private class FindContactVoiceFlowTest {

    @testSetup
    private static void prepare() {
        Find_Related_Contact_Settings__c settings = Find_Related_Contact_Settings__c.getOrgDefaults();
        settings.LimitSearch__c = 100;
        settings.LimitCreatedDateSearch__c = 300;
        settings.CountryCodes__c = '+1';
        upsert settings;
    }

    @isTest
    private static void testGetContactsByPhone() {
        // Create test contacts
        Contact contact1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            MobilePhone = '123-456-7890'
        );
        Contact contact2 = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            Phone = '123-456-7890',
            Email = 'jane.smith@example.com',
            HomePhone = '123-456-7890'
        );
        insert new List<Contact>{contact1, contact2};
        List<String> phoneNumbers = new List<String>{'+11234567890'};
        List<List<Contact>> result = FindContactVoiceFlow.getContactsByPhone(phoneNumbers);
        System.assertEquals(1, result.size(), 'Result list size should be 1');
    }

    @isTest
    private static void testNoPhoneNumbers() {
        // Call the method with no phone numbers
        List<String> phoneNumbers = new List<String>();
        List<List<Contact>> result = FindContactVoiceFlow.getContactsByPhone(phoneNumbers);
        System.assertEquals(0, result.size(), 'Result list size should be 0');
    }

    @isTest
    private static void testNullPhoneNumbers() {
        // Call the method with null phone numbers
        List<List<Contact>> result = FindContactVoiceFlow.getContactsByPhone(null);
        System.assertEquals(0, result.size(), 'Result list size should be 0');
    }

}
//