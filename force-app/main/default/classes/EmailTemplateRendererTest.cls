@isTest
private class EmailTemplateRendererTest {

    @isTest
    private static void testRenderTemplates_ValidTemplate() {
        EmailTemplate template = [
            SELECT Id, Subject FROM EmailTemplate
            WHERE DeveloperName = 'NSP_Termination_Form_Email_Template'
            LIMIT 1
        ];

        System.assertNotEquals(null, template, 'Email template must exist in org data');

        EmailTemplateRenderer.Input input = new EmailTemplateRenderer.Input();
        input.templateId = template.Id;

        List<EmailTemplateRenderer.Input> inputs = new List<EmailTemplateRenderer.Input>{ input };
        Test.startTest();
        List<EmailTemplateRenderer.Output> outputs = EmailTemplateRenderer.renderTemplates(inputs);
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'Expected exactly one output');

        EmailTemplateRenderer.Output result = outputs[0];
        String expectedSubject = 'Client Termination Activity - ' + System.today().format();

        System.assertEquals(expectedSubject, result.subject, 'Email subject should match expected');
        System.assertNotEquals(null, result.plainTextBody, 'Plain text body should not be null');
        System.assertNotEquals(null, result.htmlBody, 'HTML body should not be null');
    }

    @isTest
    private static void testRenderTemplates_InvalidTemplate_LogsError() {

        EmailTemplateRenderer.Input input = new EmailTemplateRenderer.Input();
        input.templateId = 'invalidTemplateId'; 

        List<EmailTemplateRenderer.Input> inputs = new List<EmailTemplateRenderer.Input>{ input };
        Test.startTest();
        List<EmailTemplateRenderer.Output> outputs = EmailTemplateRenderer.renderTemplates(inputs);
        Test.stopTest();

        List<NSP_Error_Log__c> errorLogs = [
            SELECT Id, NSP_Class__c
            FROM NSP_Error_Log__c
            WHERE NSP_Class__c = 'EmailTemplateRenderer'
            LIMIT 1
        ];

        System.assert(!errorLogs.isEmpty(), 'Expected an error log to be created');
        System.assertEquals('EmailTemplateRenderer', errorLogs[0].NSP_Class__c, 'Error log class name should match');
    }
}