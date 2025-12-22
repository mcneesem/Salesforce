@isTest
private class NSP_GenericEmailUtilityTest {

    @isTest
    private static void testSendEmail() {
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;
        Messaging.SingleEmailMessage[] emails = new Messaging.SingleEmailMessage[1];
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{'test@example.com'});
        email.setSubject('Test Email');
        email.setPlainTextBody('This is a test email.');
        emails[0] = email;
        Test.startTest();
        Integer emailSentCount = NSP_GenericEmailUtility.sendSingleEmailMessages(emails, false);
        NSP_GenericEmailUtility.testHandleException(null,null);
        Test.stopTest();
    }

    @isTest
    private static void testNoSendEmail() {
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;
        Messaging.SingleEmailMessage[] emails = new Messaging.SingleEmailMessage[1];
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{''});
        email.setSubject('Test Email');
        email.setPlainTextBody('This is a test email.');
        emails[0] = email;
        Test.startTest();
        Integer emailSentCount = NSP_GenericEmailUtility.sendSingleEmailMessages(emails, false);
        Test.stopTest();
    }

    @isTest
    private static void testGenerateSingleMessageWithTemplate() {
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com');
        insert testContact;
        OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        EmailTemplate et = [SELECT Id,DeveloperName FROM EmailTemplate LIMIT 1];
        Test.startTest();
        Messaging.SingleEmailMessage email = NSP_GenericEmailUtility.generateSingleMessageWithTemplate(
            NSP_GenericEmailUtility.getTemplateIdFromDevName(et.DeveloperName),
            testContact.Id,
            testContact.Id,
            owea.Id,
            new List<String>{'recipient@example.com'},
            new List<String>{'cc@example.com'},
            'Test Subject',
            'Test Body'
        );
        //Without Template Id
        Messaging.SingleEmailMessage email_noTemplate = NSP_GenericEmailUtility.generateSingleMessageWithTemplate(
            null,
            testContact.Id,
            testContact.Id,
            owea.Id,
            new List<String>{'recipient@example.com'},
            new List<String>{'cc@example.com'},
            'Test Subject',
            'Test Body'
        );
        Test.stopTest();
        System.assertNotEquals(null, email, 'Email should not be null.');
    }

    @isTest
    private static void testGetOrgWideAddress() {
        OrgWideEmailAddress owea = [SELECT Id,DisplayName FROM OrgWideEmailAddress LIMIT 1];
        Test.startTest();
        OrgWideEmailAddress retrievedEmail = NSP_GenericEmailUtility.getOrgWideAddress(owea.DisplayName);
        Test.stopTest();
        System.assertNotEquals(null, retrievedEmail, 'OrgWideEmailAddress should not be null.');
    }

}
//