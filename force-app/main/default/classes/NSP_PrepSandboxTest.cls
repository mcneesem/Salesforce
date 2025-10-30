@isTest
private class NSP_PrepSandboxTest {

    @IsTest
    private static void testUpdateUserLogins() {
        String suffix = String.valueOf( System.now().getTime() );
        String local = 'testuser@example.com.' + suffix; // Prevent DmlException DUPLICATE_USERNAME
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

        // Query the test user
        User testUser = [SELECT Id FROM User WHERE Username = :local];
        UserLogin ulogin = [SELECT Id, IsFrozen, UserId From UserLogin Where UserId = :testUser.Id LIMIT 1];
        if (ulogin != null) {
            ulogin.IsFrozen = true;
            update ulogin;
        }

        // Mock the Database.UpsertResult for the test user
        Database.UpsertResult userResult = (Database.UpsertResult) JSON.deserialize(
            '{"success":true,"id":"' + testUser.Id + '"}',
            Database.UpsertResult.class
        );

        // Call the updateUserLogins method with the mock result
        Test.startTest();
        NSP_PrepSandbox.updateUserLogins(new List<Database.UpsertResult>{ userResult });
        Test.stopTest();

        // Verify that the UserLogin record was updated
        UserLogin updatedUserLogin = [SELECT Id, IsFrozen FROM UserLogin WHERE UserId = :testUser.Id];
        System.assertEquals(false, updatedUserLogin.IsFrozen, 'UserLogin record should have IsFrozen set to false');
    }

    @isTest
    private static void testSandboxPrep() {
        // Insert logic here to create records of the objects that the class your testing manipulates.
        Integer queueCount = 0;

        Test.startTest();
        //Execute test script with RunAsAutoProcUser set to true
        Test.testSandboxPostCopyScript(new NSP_PrepSandbox(), UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(), UserInfo.getOrganizationName(), true);
        Test.stopTest();

        // Insert assert statements here to check that the records you created above have the values you expect.        
        for(Group queue:[SELECT id, email FROM Group WHERE type = 'Queue' AND email > ''])
        {
            if(queue.email.indexOf('.invalid') == -1){
                queueCount++;
            }
        }
        System.assertEquals(0, queueCount);
    }

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
        Test.stopTest();
    }

    @isTest
    private static void testPageRef() {
        Test.startTest();
        PageReference pageRef = Page.SandboxManualSteps;
        Test.setCurrentPage(pageRef);
        NSP_PrepSandbox prep = new NSP_PrepSandbox();
        System.assertEquals(null,prep.resetResult());
        System.assertEquals(null,prep.doUserImportPage());
        System.assertEquals(null,prep.runManualStepsButton());
        System.assertEquals(null,prep.runManualStepsButton2());
        System.assertEquals(null,prep.runE2CAddressesButton());
        Test.stopTest();
    }

}
//