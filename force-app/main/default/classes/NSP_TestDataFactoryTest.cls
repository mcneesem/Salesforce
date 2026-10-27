@isTest
private class NSP_TestDataFactoryTest {

    private static final String PKG = 'NSP_TestDataFactory.';

    @isTest
    static void createSObject_noInsert_appliesDefaults() {
        Test.startTest();
        Account acc = (Account) NSP_TestDataFactory.createSObject(new Account());
        Test.stopTest();

        System.assertEquals(null, acc.Id, 'Record should not be inserted');
        System.assertEquals('Test New Acc - 01', acc.Name);
        System.assertEquals('New York', acc.BillingCity);
        System.assertEquals('10021', acc.BillingPostalCode);
    }

    @isTest
    static void createSObject_doInsertTrue_insertsRecord() {
        Test.startTest();
        Account acc = (Account) NSP_TestDataFactory.createSObject(new Account(), true);
        Test.stopTest();

        System.assertNotEquals(null, acc.Id, 'Record should be inserted');
        System.assertEquals(1, [SELECT COUNT() FROM Account WHERE Id = :acc.Id]);
    }

    @isTest
    static void createSObject_doInsertFalse_doesNotInsert() {
        Account acc = (Account) NSP_TestDataFactory.createSObject(new Account(), false);

        System.assertEquals(null, acc.Id);
        System.assertEquals(0, [SELECT COUNT() FROM Account]);
    }

    @isTest
    static void createSObject_explicitClassName_appliesDefaults() {
        Lead l = (Lead) NSP_TestDataFactory.createSObject(new Lead(), PKG + 'LeadDefaults');

        System.assertEquals('John', l.FirstName);
        System.assertEquals('Doe', l.LastName);
        System.assertEquals('Test', l.Company);
        System.assertEquals('Mocktest@test.com', l.Email, 'Last duplicate key in map literal wins');
    }

    @isTest
    static void createSObject_explicitClassNameAndInsert_insertsRecord() {
        Test.startTest();
        Campaign c = (Campaign) NSP_TestDataFactory.createSObject(new Campaign(), PKG + 'CampaignDefaults', true);
        Test.stopTest();

        System.assertNotEquals(null, c.Id);
        System.assertEquals('Test Campaign', [SELECT Name FROM Campaign WHERE Id = :c.Id].Name);
    }

    @isTest
    static void createSObject_doesNotOverridePopulatedFields() {
        Account acc = new Account(Name = 'Custom Name', BillingCity = 'Mumbai');

        Account result = (Account) NSP_TestDataFactory.createSObject(acc);

        System.assertEquals('Custom Name', result.Name, 'Populated field must be preserved');
        System.assertEquals('Mumbai', result.BillingCity, 'Populated field must be preserved');
        System.assertEquals('10021', result.BillingPostalCode, 'Unpopulated field gets default');
        System.assertEquals('United States', result.BillingCountry);
    }

    @isTest
    static void createSObject_noDefaultsClass_returnsUnchanged() {
        Contact con = new Contact(LastName = 'Original');

        Contact result = (Contact) NSP_TestDataFactory.createSObject(con);

        System.assertEquals('Original', result.LastName);
        System.assertEquals(null, result.FirstName, 'No defaults should have been applied');
    }

    @isTest
    static void createSObject_invalidClassName_throwsException() {
        Boolean thrown = false;
        try {
            NSP_TestDataFactory.createSObject(new Account(), PKG + 'DoesNotExistDefaults');
        } catch (NSP_TestDataFactory.TestFactoryException e) {
            thrown = true;
            System.assertEquals('Invalid defaults class.', e.getMessage());
        }
        System.assert(thrown, 'TestFactoryException expected for invalid defaults class');
    }

    @isTest
    static void generateUniqTestData_createsAccount() {
        Test.startTest();
        NSP_TestDataFactory.generateUniqTestData();
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Account]);
    }

    @isTest
    static void leadAndCampaignAndCase_defaults() {
        Case cs = (Case) NSP_TestDataFactory.createSObject(new Case());
        System.assertEquals('Web', cs.Origin);
        System.assertEquals('Open', cs.Status);
        System.assertEquals('Test Subject', cs.Subject);

        Lead l = (Lead) NSP_TestDataFactory.createSObject(new Lead(), true);
        System.assertNotEquals(null, l.Id);
    }

    @isTest
    static void taskDefaults_applied() {
        Task t = (Task) NSP_TestDataFactory.createSObject(new Task(), PKG + 'TaskDefault', true);

        System.assertNotEquals(null, t.Id);
        System.assertEquals('Completed', t.Status);
        System.assertEquals(UserInfo.getUserId(), t.OwnerId);
    }

    @isTest
    static void userDefaults_applied() {
        User u = (User) NSP_TestDataFactory.createSObject(new User(), PKG + 'UserDefaults');

        System.assertEquals('Bla', u.LastName);
        System.assertEquals('sas', u.Alias);
        System.assertEquals('UTF-8', u.EmailEncodingKey);
        System.assertNotEquals(null, u.ProfileId, 'System Administrator profile should be resolved');
        System.assert(u.Username.contains(UserInfo.getOrganizationId()));
    }

    @isTest
    static void userDefaults_insert() {
        User u;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            u = (User) NSP_TestDataFactory.createSObject(new User(), PKG + 'UserDefaults', true);
        }
        System.assertNotEquals(null, u.Id);
    }

    @isTest
    static void collaborationGroupAndGroup_defaults() {
        CollaborationGroup cg = (CollaborationGroup) NSP_TestDataFactory.createSObject(
            new CollaborationGroup(), PKG + 'CollaborationGroupDefaults', true);
        System.assertNotEquals(null, cg.Id);
        System.assertEquals('Private', cg.CollaborationType);

        Group g = (Group) NSP_TestDataFactory.createSObject(new Group(), PKG + 'GroupDefaults');
        System.assertEquals('Contact Center', g.Name);
    }

    @isTest
    static void orderDefaults_applied() {
        Order o = (Order) NSP_TestDataFactory.createSObject(new Order());

        System.assertEquals('Draft', o.Status);
        System.assertEquals(System.today(), o.EffectiveDate);
    }

    @isTest
    static void emailMessageDefaults_applied() {
        EmailMessage em = (EmailMessage) NSP_TestDataFactory.createSObject(
            new EmailMessage(), PKG + 'emailMessageDefaults');

        System.assertEquals(true, em.Incoming);
        System.assertEquals('test@xyz.com', em.ToAddress);
        System.assertEquals('Test email Subject', em.Subject);
    }

    @isTest
    static void documentDefaults_applied() {
        Document d = (Document) NSP_TestDataFactory.createSObject(new Document(), PKG + 'DocumentDefaults');

        System.assertEquals('SampleTest_Document', d.Name);
        System.assertEquals('application/pdf', d.ContentType);
        System.assertEquals(true, d.IsPublic);
        System.assertNotEquals(null, d.Body);
    }

    @isTest
    static void product2AndPricebook2_defaults() {
        Product2 p = (Product2) NSP_TestDataFactory.createSObject(new Product2(), true);
        System.assertNotEquals(null, p.Id);
        System.assertEquals(true, p.IsActive);

        Pricebook2 pb = (Pricebook2) NSP_TestDataFactory.createSObject(new Pricebook2(), true);
        System.assertNotEquals(null, pb.Id);
        System.assertEquals('Sample Test Pricebook', pb.Name);
    }

    @isTest
    static void opportunityDefaults_createsAccountAndOpportunity() {
        Test.startTest();
        Opportunity opp = (Opportunity) NSP_TestDataFactory.createSObject(new Opportunity(), true);
        Test.stopTest();

        System.assertNotEquals(null, opp.Id);
        System.assertNotEquals(null, opp.AccountId);
        System.assertEquals('Qualification', opp.StageName, 'Last duplicate key in map literal wins');
        System.assertEquals(System.today(), opp.CloseDate);
    }

    @isTest
    static void opportunityLineItemDefaults_createsFullHierarchy() {
        Test.startTest();
        OpportunityLineItem oli = (OpportunityLineItem) NSP_TestDataFactory.createSObject(
            new OpportunityLineItem(), PKG + 'OpportunityLineItemDefaults', true);
        Test.stopTest();

        System.assertNotEquals(null, oli.Id);
        System.assertEquals(2, oli.Quantity);
        System.assertNotEquals(null, oli.OpportunityId);
        System.assertNotEquals(null, oli.PricebookEntryId);
    }

    @isTest
    static void contentVersionAndLink_defaults() {
        Test.startTest();
        ContentVersion cv = (ContentVersion) NSP_TestDataFactory.createSObject(
            new ContentVersion(), PKG + 'ContentVersionDefaults', true);
        Test.stopTest();

        System.assertNotEquals(null, cv.Id);
        System.assertEquals('ABC Test', cv.Title);

        ContentVersion queried = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        System.assertNotEquals(null, queried.ContentDocumentId);
    }

    @isTest
    static void attachmentAndFeedItem_defaults() {
        Attachment att = (Attachment) NSP_TestDataFactory.createSObject(
            new Attachment(), PKG + 'AttachmentDefaults', true);
        System.assertNotEquals(null, att.Id);
        System.assertEquals('test.txt', att.Name);

        FeedItem fi = (FeedItem) NSP_TestDataFactory.createSObject(
            new FeedItem(), PKG + 'FeedItemDefaults', true);
        System.assertNotEquals(null, fi.Id);
        System.assertEquals('Hello', fi.Body);
    }

    @isTest
    static void contentDocumentLinkDefaults_applied() {
        Test.startTest();
        ContentDocumentLink cdl = (ContentDocumentLink) NSP_TestDataFactory.createSObject(
            new ContentDocumentLink(), PKG + 'ContentDocumentLinkDefaults');
        Test.stopTest();

        System.assertEquals('V', cdl.ShareType);
        System.assertEquals('InternalUsers', cdl.Visibility);
        System.assertNotEquals(null, cdl.ContentDocumentId);
        System.assertNotEquals(null, cdl.LinkedEntityId);
    }

    @isTest
    static void getAccount_createsOnceAndCaches() {
        System.assertEquals(0, [SELECT COUNT() FROM Account]);

        Account first = NSP_TestDataFactory.getAccount;
        Account second = NSP_TestDataFactory.getAccount;

        System.assertNotEquals(null, first.Id);
        System.assertEquals(first.Id, second.Id, 'Getter should return cached instance');
        System.assertEquals(1, [SELECT COUNT() FROM Account]);
    }

    @isTest
    static void getAccount_usesExistingRecordWhenPresent() {
        Account existing = new Account(Name = 'Existing');
        insert existing;

        Account result = NSP_TestDataFactory.getAccount;

        System.assertEquals(existing.Id, result.Id);
        System.assertEquals(1, [SELECT COUNT() FROM Account]);
    }

    @isTest
    static void getProduct_createsWhenNoneExist() {
        Product2 p = NSP_TestDataFactory.getProduct;

        System.assertNotEquals(null, p.Id);
        System.assertEquals(p.Id, NSP_TestDataFactory.getProduct.Id);
    }

    @isTest
    static void getProduct_usesExistingRecordWhenPresent() {
        Product2 existing = new Product2(Name = 'Existing Product', IsActive = true);
        insert existing;

        System.assertEquals(existing.Id, NSP_TestDataFactory.getProduct.Id);
    }

    @isTest
    static void getPriceBookEntry_createsWhenNoneExist() {
        PricebookEntry pbe = NSP_TestDataFactory.getPriceBookEntry;

        System.assertNotEquals(null, pbe.Id);
        System.assertEquals(pbe.Id, NSP_TestDataFactory.getPriceBookEntry.Id);
    }

    @isTest
    static void getOpportunity_createsWhenNoneExist() {
        Opportunity opp = NSP_TestDataFactory.getOpportunity;

        System.assertNotEquals(null, opp.Id);
        System.assertEquals(opp.Id, NSP_TestDataFactory.getOpportunity.Id);
    }

    @isTest
    static void getContentVersion_createsWhenNoneExist() {
        ContentVersion cv = NSP_TestDataFactory.getContentVersion;

        System.assertNotEquals(null, cv.Id);
        System.assertNotEquals(null, cv.ContentDocumentId);
    }

    @isTest
    static void getAccountGroup_createsWhenNoneExist() {
        NSP_Account_Group__c grp = NSP_TestDataFactory.getAccountGroup;

        System.assertNotEquals(null, grp.Id);
        System.assertEquals(grp.Id, NSP_TestDataFactory.getAccountGroup.Id);
    }

    @isTest
    static void getAsset_createsWhenNoneExist() {
        Asset a = NSP_TestDataFactory.getAsset;

        System.assertNotEquals(null, a.Id);
        System.assertEquals(a.Id, NSP_TestDataFactory.getAsset.Id);
    }

    @isTest
    static void getSubClientContact_createsWhenNoneExist() {
        NSP_Sub_Client_Contact__c c = NSP_TestDataFactory.getSubClientContact;

        System.assertNotEquals(null, c.Id);
    }

    @isTest
    static void getAccrualProfile_createsWhenNoneExist() {
        NSP_Accrual_Profile__c ap = NSP_TestDataFactory.getAccrualProfile;

        System.assertNotEquals(null, ap.Id);
        System.assertEquals(ap.Id, NSP_TestDataFactory.getAccrualProfile.Id);
    }

    @isTest
    static void getProjectAndProjectTask_createWhenNoneExist() {
        pse__Proj__c proj = NSP_TestDataFactory.getProject;
        System.assertNotEquals(null, proj.Id);

        pse__Project_Task__c task = NSP_TestDataFactory.getProjectTask;
        System.assertNotEquals(null, task.Id);
    }

    @isTest
    static void getWorkType_createsWhenNoneExist() {
        WorkType wt = NSP_TestDataFactory.getWorkType;

        System.assertNotEquals(null, wt.Id);
    }

    @isTest
    static void customObjectDefaults_populateExpectedFields() {
        NSP_Account_Group__c grp = (NSP_Account_Group__c) NSP_TestDataFactory.createSObject(
            new NSP_Account_Group__c(), PKG + 'AccountGroupDefaults');
        System.assertEquals('Test New Acc Grp- 01', grp.Name);
        System.assertEquals(true, grp.NSP_Watchlist__c);

        NSP_Address__c addr = (NSP_Address__c) NSP_TestDataFactory.createSObject(
            new NSP_Address__c(), PKG + 'AddressDefaults');
        System.assertEquals('Chicago', addr.NSP_City__c);
        System.assertEquals('Worksite', addr.NSP_Address_Type__c);

        NSP_Regulated_Area__c ra = (NSP_Regulated_Area__c) NSP_TestDataFactory.createSObject(
            new NSP_Regulated_Area__c(), PKG + 'RegulatedAreaDefaults');
        System.assertEquals('test city', ra.NSP_City__c);
        System.assertEquals(System.today(), ra.NSP_Start_Date__c);

        NSP_Service_Plan__c sp = (NSP_Service_Plan__c) NSP_TestDataFactory.createSObject(
            new NSP_Service_Plan__c(), PKG + 'ServicePlanDefaults');
        System.assertEquals('Test Service Plan', sp.Name);

        NSP_Plan__c plan = (NSP_Plan__c) NSP_TestDataFactory.createSObject(
            new NSP_Plan__c(), PKG + 'PlanDefaults');
        System.assertEquals('test@gmail.com', plan.NSP_Email__c);

        NSP_Note__c note = (NSP_Note__c) NSP_TestDataFactory.createSObject(
            new NSP_Note__c(), PKG + 'NSPNoteDefaults');
        System.assertEquals('Test Note', note.Note__c);

        NSP_Eligibility__c elig = (NSP_Eligibility__c) NSP_TestDataFactory.createSObject(
            new NSP_Eligibility__c(), PKG + 'EligibilityDefaults');
        System.assertEquals(5, elig.NSP_Age__c);
    }

    @isTest
    static void customObjectDefaults_withLookups_resolveParents() {
        NSP_Account_Team__c team = (NSP_Account_Team__c) NSP_TestDataFactory.createSObject(
            new NSP_Account_Team__c(), PKG + 'AccountTeamMemberDefaults');
        System.assertEquals('Client Liaison', team.NSP_Role__c);
        System.assertEquals(UserInfo.getUserId(), team.NSP_User__c);
        System.assertNotEquals(null, team.NSP_Account__c);

        NSP_Accrual_Profile_Account_Relationship__c rel =
            (NSP_Accrual_Profile_Account_Relationship__c) NSP_TestDataFactory.createSObject(
                new NSP_Accrual_Profile_Account_Relationship__c(),
                PKG + 'AccrualProfileAccountRelationshipDefaults');
        System.assertNotEquals(null, rel.NSP_Accrual_Profile__c);
        System.assertNotEquals(null, rel.NSP_Account__c);
    }

    @isTest
    static void allSimpleDefaultsClasses_returnNonNullMaps() {
        List<String> classNames = new List<String>{
            'AccountDefaults', 'AccountGroupDefaults', 'LeadDefaults', 'CampaignDefaults',
            'ContactDefaultsLight', 'AdditionalPayrollContactDefaults', 'PayrollDataSheetDefaults',
            'PTOSmartformDefaults', 'CollaborationGroupDefaults', 'DocumentDefaults', 'GroupDefaults',
            'Pricebook2Defaults', 'CaseDefaults', 'ServicePlanDefaults', 'TaskDefault',
            'ContentVersionDefaults', 'Product2Defaults', 'RegulatedAreaDefaults', 'PlanDefaults',
            'SubPlanDefaults', 'SubPlanChangeHistoryDefaults', 'SubClientContactDefaults',
            'AddressDefaults', 'SubClientContactAddressDefaults', 'ProjectTaskDefaults',
            'WorkTypeDefaults', 'CatSubCatMappingDefaults', 'EligibilityDefaults',
            'EducationDefaults', 'AssetRETEducationAssociationDefaults', 'NSPNoteDefaults',
            'OrderDefaults', 'ReportRequestDefaults', 'fLSAMappingDefaults', 'emailMessageDefaults',
            'caseContactDefaults', 'acrDefaults', 'AccountGroupMemberDefaults', 'FocusItemDefaults',
            'ImplementationProfileDefaults', 'ImplementationProfileAutomationsDefaults',
            'ClientSubPlanHistoryDefaults', 'RegionDefaults', 'PermissionControlDefaults',
            'AssignmentDefaults', 'ScheduleDefaults', 'AccrualProfileDefaults'
        };

        for (String className : classNames) {
            Type t = Type.forName(PKG + className);
            System.assertNotEquals(null, t, 'Missing defaults class: ' + className);

            NSP_TestDataFactory.FieldDefaults fd = (NSP_TestDataFactory.FieldDefaults) t.newInstance();
            System.assertNotEquals(null, fd.getFieldDefaults(), 'Null defaults map from: ' + className);
        }
    }
}