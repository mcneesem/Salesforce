@isTest
private class NSP_PrepSandboxTest {

    @isTest
    private static void testUpdateUserLogins() {
        String suffix = String.valueOf(System.now().getTime());
        String local = 'testuser@example.com.' + suffix;
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User user = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = local,
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;

        User testUser = [SELECT Id FROM User WHERE Username = :local];
        UserLogin ulogin = [SELECT Id, IsFrozen, UserId FROM UserLogin WHERE UserId = :testUser.Id LIMIT 1];
        ulogin.IsFrozen = true;
        update ulogin;

        Database.UpsertResult userResult = (Database.UpsertResult) JSON.deserialize(
            '{"success":true,"id":"' + testUser.Id + '"}',
            Database.UpsertResult.class
        );

        Test.startTest();
        NSP_PrepSandbox.updateUserLogins(new List<Database.UpsertResult>{ userResult });
        Test.stopTest();

        UserLogin updatedUserLogin = [SELECT Id, IsFrozen FROM UserLogin WHERE UserId = :testUser.Id];
        System.Assert.areEqual(false, updatedUserLogin.IsFrozen, 'UserLogin record should have IsFrozen set to false');
    }

    @isTest
    private static void testSandboxPrep() {
        Integer queueCount = 0;

        Test.startTest();
        Test.testSandboxPostCopyScript(new NSP_PrepSandbox(), UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(), UserInfo.getOrganizationName(), true);
        Test.stopTest();

        for (Group queue : [SELECT id, email FROM Group WHERE type = 'Queue' AND email > '']) {
            if (queue.email.indexOf('.invalid') == -1) {
                queueCount++;
            }
        }
        System.Assert.areEqual(0, queueCount);
    }

    // SeeAllData required: doCSettings and doCMetadata read live Custom Settings and Custom Metadata
    // that cannot be created in test context (DocuSign_Settings__c, NSP_DocuSign_Signers__mdt, etc.)
    @isTest(SeeAllData=true)
    private static void testManualSteps() {
        Test.startTest();
        NSP_PrepSandbox.doE2CAddresses('test');
        NSP_PrepSandbox.doCLabels('merge');
        NSP_PrepSandbox.doCLabels('test');
        NSP_PrepSandbox.doCLabels('stage');
        NSP_PrepSandbox.doCSettings('merge');
        NSP_PrepSandbox.doCSettings('test');
        NSP_PrepSandbox.doCMetadata('test');
        NSP_PrepSandbox.doAvaTaxSettings();
        Test.stopTest();
    }

    @isTest
    private static void testIsCurrentUserAllowedE2C_allowed() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User allowedUser = new User(
            FirstName = 'Paul',
            LastName = 'McCluskey',
            Email = 'paul.mccluskey@insperity.com',
            Username = 'paul.mccluskey@insperity.com.' + String.valueOf(System.now().getTime()),
            Alias = 'pmcclus',
            TimeZoneSidKey = 'America/Chicago',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert allowedUser;

        Boolean result;
        System.runAs(allowedUser) {
            Test.startTest();
            result = NSP_PrepSandbox.isCurrentUserAllowedE2C();
            Test.stopTest();
        }

        System.Assert.areEqual(true, result, 'User with matching email should be allowed');
    }

    @isTest
    private static void testDoTrustedURLs() {
        Test.startTest();
        NSP_PrepSandbox.doTrustedURLs();
        Test.stopTest();

        System.Assert.isTrue(true, 'doTrustedURLs should complete without throwing an exception');
    }

    @isTest
    private static void testDoGlobalValueSets_PreABXActivated() {
        Test.startTest();
        NSP_PrepSandbox.doGlobalValueSets( true );
        Test.stopTest();

        System.Assert.isTrue(true, 'doGlobalValueSets should complete without throwing an exception');
    }

    @isTest
    private static void testDoGlobalValueSets_PreABXDeactivated() {
        Test.startTest();
        NSP_PrepSandbox.doGlobalValueSets( false );
        Test.stopTest();

        System.Assert.isTrue(true, 'doGlobalValueSets with false should complete without throwing an exception');
    }

    @isTest
    private static void testPageRef() {
        Test.startTest();
        PageReference pageRef = Page.SandboxManualSteps;
        Test.setCurrentPage(pageRef);
        NSP_PrepSandbox prep = new NSP_PrepSandbox();
        System.Assert.areEqual(null, prep.resetResult());
        System.Assert.areEqual(null, prep.doUserImportPage());
        System.Assert.areEqual(null, prep.runManualStepsButton());
        System.Assert.areEqual(null, prep.runManualStepsButton2());
        System.Assert.areEqual(null, prep.runE2CAddressesButton());
        Test.stopTest();
    }

}
