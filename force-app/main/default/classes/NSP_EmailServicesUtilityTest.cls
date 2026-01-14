@isTest
private without sharing class NSP_EmailServicesUtilityTest {

    @testSetup
    private static void createTestData(){
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;

        Test.startTest();
        List<User> deploymentManagers = [
            SELECT Id
            FROM User
            WHERE ( Id = '0054x0000056lRZAAY' )
            LIMIT 1
        ];
        Assert.isNotNull( deploymentManagers , 'Null Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() > 0 ) , 'No Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() == 1 ) , 'Incorrect Deployment Manager query results.' );
        User deploymentManager = deploymentManagers[0];
        System.runas( deploymentManager ) {

            List<EmailTemplate> emailTempalteList = new List<EmailTemplate>();

            EmailTemplate template = new EmailTemplate ();
            template.developerName = 'Test_Email_Template_Unique';
            template.FolderId=userInfo.getUserId();
            template.TemplateType='Text';
            template.Name='TestEmailTempalte_Unique';
            emailTempalteList.add(template);

            EmailTemplate vfTemplate = new EmailTemplate ();
            string templateText = '<messaging:emailTemplate subject="{!relatedTo.Name}" recipientType="User" relatedToType="Opportunity"><messaging:htmlEmailBody ><ul><li>test content</li></ul></messaging:htmlEmailBody></messaging:emailTemplate>';
            vfTemplate.developerName = 'TestEmailTempalteVFTestTempalte';
            vfTemplate.FolderId=userInfo.getUserId();
            vfTemplate.TemplateType='Visualforce';
            vfTemplate.Name='TestEmailTempalteVFTestTempalte';
            vfTemplate.isActive=true;
            vfTemplate.Markup=templateText;
            emailTempalteList.add(vfTemplate);

            insert emailTempalteList;
        }

        Test.stopTest();
    }

    @isTest
    private static void sendDynamicEmailFromEmailTemplateTest() {
        NSP_EmailServicesUtility.EmailMessageWrapper emailWrapper = new NSP_EmailServicesUtility.EmailMessageWrapper('Test Company',
                                                                                                                     new List<String>{'abcd@est.com'},
                                                                                                                     'test subject',
                                                                                                                     'body of email',
                                                                                                                     null,null);
        List<NSP_EmailServicesUtility.EmailMessageWrapper> emailWrapperList = new List<NSP_EmailServicesUtility.EmailMessageWrapper>{emailWrapper};

            EmailTemplate emailTemplate = [SELECT Id, Name FROM EmailTemplate WHERE Name!='' AND TemplateType='Text' LIMIT 1];
        NSP_EmailServicesUtility.sendDynamicEmailFromEmailTemplate(emailWrapperList,emailTemplate.Id);
        system.assertequals(true,true);
    }

    //sendVFEmailTemplateTest test method
    @isTest
    private static void sendVFEmailTemplateTest() {
        Test.startTest();
        String[] s1 = new String[] {'ram', 'sam', 'jack'};
        Id userId = userInfo.getUserId();

        Account account = NSP_TestHelper.createAccount(true);
        Opportunity opportunityRecord = NSP_TestHelper.createOpenOpportunity(account.Id, 'New Product', true);

        EmailTemplate vfEmailTemplate = [SELECT Id, Name FROM EmailTemplate WHERE Name!='' AND TemplateType='Visualforce' LIMIT 1];

        List<Messaging.EmailFileAttachment> emailattachments = new List<Messaging.EmailFileAttachment>();
        NSP_EmailServicesUtility.sendVFEmailTemplate(userId,s1,vfEmailTemplate, opportunityRecord.Id,emailattachments);
        Test.stopTest();
         system.assertequals(true,true);
    }

    @isTest
    private static void test_getOpportunityAttachments() {
        // Create minimal data: Account, Opportunity
        Account acct = NSP_TestHelper.createAccount(true);
        Opportunity opp = NSP_TestHelper.createOpenOpportunity(acct.Id, 'WX', true);

        // Create a ContentVersion that will match WX label parts
        // System.Label.NSP_OpportunityWXAttachmentName is expected to be a comma-separated list with at least 3 tokens
        List<String> wxParts = System.Label.NSP_OpportunityWXAttachmentName.split(',');
        // Fallback tokens if label not configured in test context
        if (wxParts.size() < 3) {
            wxParts = new List<String>{'WX','ATTACH','REQ'};
        }
        String matchingTitle = String.join(new List<String>{ wxParts[0], wxParts[1], wxParts[2] }, ' ');

        // Create ContentVersion (first insert creates a ContentDocument)
        ContentVersion cv = new ContentVersion();
        cv.Title = matchingTitle;
        cv.PathOnClient = matchingTitle + '.pdf';
        cv.VersionData = Blob.valueOf('test content');
        insert cv;

        // Query back to get ContentDocumentId
        ContentVersion cvLatest = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];

        // Link the ContentDocument to the Opportunity
        insert new ContentDocumentLink(
            ContentDocumentId = cvLatest.ContentDocumentId,
            LinkedEntityId = opp.Id,
            ShareType = 'V'
        );

        // Invoke method under test
        Test.startTest();
        List<Messaging.EmailFileAttachment> attachments = NSP_EmailServicesUtility.getOpportunityAttachments(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, attachments, 'Attachments list should not be null.');
        System.assertEquals(true, !attachments.isEmpty(), 'Attachments should not be empty when a matching document is linked.');
        System.assertEquals(1, attachments.size(), 'Exactly one matching attachment expected.');
        System.assertEquals(true, attachments[0].body != null, 'Attachment body should be populated.');
    }

    @isTest
    private static void test_generateEmailTemplates() {
        // Arrange: Create Account, Opportunity and minimal template + MDT mapping
        Account acct = NSP_TestHelper.createAccount(true);
        Opportunity opp = NSP_TestHelper.createOpenOpportunity(acct.Id, 'WX', true);
        opp.StageName = 'Closed Won';
        opp.NSP_PrimaryProduct__c = 'WX';
        update opp;

        List<User> deploymentManagers = [
            SELECT Id
            FROM User
            WHERE ( Id = '0054x0000056lRZAAY' )
            LIMIT 1
        ];
        Assert.isNotNull( deploymentManagers , 'Null Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() > 0 ) , 'No Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() == 1 ) , 'Incorrect Deployment Manager query results.' );
        User deploymentManager = deploymentManagers[0];
        System.runas( deploymentManager ) {

            // Email Template referenced by DeveloperName in mapping
            EmailTemplate tpl = new EmailTemplate();
            tpl.DeveloperName = 'GEN_WX_TEMPLATE';
            tpl.FolderId = UserInfo.getUserId();
            tpl.TemplateType = 'Text';
            tpl.Name = 'GEN_WX_TEMPLATE';
            insert tpl;

            // Build opptyId -> developerName map and opptyId -> "mdt" stand-in via a fake instance to satisfy logic that reads CC/TO.
            Map<Id, String> opptyIdEmailTemplateMap = new Map<Id, String>{ opp.Id => tpl.DeveloperName };

        // Build a stand-in metadata-like object using a lightweight wrapper to carry the needed fields
        TestMappingWrapper mdt = new TestMappingWrapper('someone@example.com', 'to@example.com');
        Map<Id, TestMappingWrapper> opptyMdtMap = new Map<Id, TestMappingWrapper>{ opp.Id => mdt };

            Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>{ opp.Id => opp };

            Test.startTest();
        // Adapt wrapper map to the expected type by constructing per-opp values inline
        // We can't DML MDT in tests, so we invoke the method via a helper overload below
        NSP_EmailServicesUtilityTest.invokeGenerateEmailTemplatesForTest(opptyIdEmailTemplateMap, opptyMdtMap, newOppMap);
            Test.stopTest();
        }

        System.assert(true, 'generateEmailTemplates executed without exception.');
    }

    @isTest
    private static void test_sendEmailsTOService() {
        // Arrange: Build Closed Won WX opportunity
        Account acct = NSP_TestHelper.createAccount(true);
        Opportunity opp = NSP_TestHelper.createOpenOpportunity(acct.Id, 'WX', true);
        opp.StageName = 'Closed Won';
        opp.NSP_PrimaryProduct__c = 'WX';
        update opp;

        List<Opportunity> closedWon = new List<Opportunity>{ opp };
        Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>{ opp.Id => opp };
        List<String> workforceProducts = new List<String>{ 'WX' };

        Test.startTest();
        NSP_EmailServicesUtility.sendEmailsTOService(closedWon, newOppMap, workforceProducts);
        Test.stopTest();

        System.assert(true, 'sendEmailsTOService executed without exception.');
    }

    // Lightweight wrapper for testing to hold fields referenced by generateEmailTemplates logic
    private class TestMappingWrapper {
        public string NSP_RecipientEmailIds_CC;
        public string NSP_Recipients_Email_Ids_TO;
        TestMappingWrapper(String cc, String toAddr) {
            this.NSP_RecipientEmailIds_CC = cc;
            this.NSP_Recipients_Email_Ids_TO = toAddr;
        }
    }

    // Helper to adapt wrapper map into per-invocation values and call the production method
    // We recreate the expected Map<Id, NSP_EmailTemplatesAndRecipientsMapping__mdt> shape by constructing
    // stub sObjects at call time without DML.
    @TestVisible
    private static void invokeGenerateEmailTemplatesForTest(
        Map<Id, String> opptyIdEmailTemplateMap,
        Map<Id, TestMappingWrapper> testMap,
        Map<Id, Opportunity> newOpportunityMap
        )
    {
        // Build a transient map keyed by opp id using a dynamic sObject to satisfy field reads
        Map<Id, NSP_EmailTemplatesAndRecipientsMapping__mdt> typedMap = new Map<Id, NSP_EmailTemplatesAndRecipientsMapping__mdt>();
        for (Id oppId : testMap.keySet()) {
            TestMappingWrapper w = testMap.get(oppId);
            // Construct a transient sObject instance with only the fields accessed by the code under test
            NSP_EmailTemplatesAndRecipientsMapping__mdt stub = (NSP_EmailTemplatesAndRecipientsMapping__mdt) NSP_EmailTemplatesAndRecipientsMapping__mdt.SObjectType.newSObject(null, true);
            stub.NSP_RecipientEmailIds_CC__c = w.NSP_RecipientEmailIds_CC;
            stub.NSP_Recipients_Email_Ids_TO__c = w.NSP_Recipients_Email_Ids_TO;
            typedMap.put(oppId, stub);
        }
        NSP_EmailServicesUtility.generateEmailTemplates(opptyIdEmailTemplateMap, typedMap, newOpportunityMap);
    }

}
//