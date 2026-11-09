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
        // Given
        TrustedUrlsCalloutMock mock = new TrustedUrlsCalloutMock();
        Test.setMock( HttpCalloutMock.class, mock );

        // When
        Test.startTest();
        NSP_PrepSandbox.doTrustedURLs();
        Test.stopTest();

        // Then — one PATCH per site with the correct endpoint URL
        System.Assert.areEqual( 3, mock.capturedPatchBodies.size(), 'Three PATCH requests should be sent, one per trusted site' );
        Set<String> patchBodies = new Set<String>( mock.capturedPatchBodies );
        System.Assert.isTrue( patchBodies.contains( '{"EndpointUrl":"https://testtableau.insperity.com"}' ), 'Tableau endpoint URL should be patched' );
        System.Assert.isTrue( patchBodies.contains( '{"EndpointUrl":"https://*.sandbox.my.salesforce-scrt.com"}' ), 'Salesforce_SCRT endpoint URL should be patched' );
        System.Assert.isTrue( patchBodies.contains( '{"EndpointUrl":"https://*.sandbox.my.salesforce-setup.com"}' ), 'Salesforce_Setup endpoint URL should be patched' );
    }

    @isTest
    private static void testDoGlobalValueSets_PreABXActivated() {
        // Given — Pre-ABX starts inactive; activating should flip it to true
        GlobalValueSetCalloutMock mock = new GlobalValueSetCalloutMock( false );
        Test.setMock( HttpCalloutMock.class, mock );

        // When
        Test.startTest();
        NSP_PrepSandbox.doGlobalValueSets( true );
        Test.stopTest();

        // Then — verify the PATCH body reflects the mutation
        Map<String, Object> patchBody = (Map<String, Object>) JSON.deserializeUntyped( mock.capturedPatchBody );
        Map<String, Object> metadata = (Map<String, Object>) patchBody.get( 'Metadata' );
        List<Object> customValues = (List<Object>) metadata.get( 'customValue' );
        Boolean preAbxIsActive = null;
        for ( Object cv : customValues ) {
            Map<String, Object> cvMap = (Map<String, Object>) cv;
            if ( 'Pre-ABX'.equals( cvMap.get( 'valueName' ) ) ) {
                preAbxIsActive = (Boolean) cvMap.get( 'isActive' );
            }
        }
        System.Assert.isNotNull( preAbxIsActive, 'Pre-ABX entry should be present in the PATCH body' );
        System.Assert.areEqual( true, preAbxIsActive, 'Pre-ABX isActive should be set to true when activating' );
    }

    @isTest
    private static void testDoGlobalValueSets_PreABXDeactivated() {
        // Given — Pre-ABX starts active; deactivating should flip it to false
        GlobalValueSetCalloutMock mock = new GlobalValueSetCalloutMock( true );
        Test.setMock( HttpCalloutMock.class, mock );

        // When
        Test.startTest();
        NSP_PrepSandbox.doGlobalValueSets( false );
        Test.stopTest();

        // Then — verify the PATCH body reflects the mutation
        Map<String, Object> patchBody = (Map<String, Object>) JSON.deserializeUntyped( mock.capturedPatchBody );
        Map<String, Object> metadata = (Map<String, Object>) patchBody.get( 'Metadata' );
        List<Object> customValues = (List<Object>) metadata.get( 'customValue' );
        Boolean preAbxIsActive = null;
        for ( Object cv : customValues ) {
            Map<String, Object> cvMap = (Map<String, Object>) cv;
            if ( 'Pre-ABX'.equals( cvMap.get( 'valueName' ) ) ) {
                preAbxIsActive = (Boolean) cvMap.get( 'isActive' );
            }
        }
        System.Assert.isNotNull( preAbxIsActive, 'Pre-ABX entry should be present in the PATCH body' );
        System.Assert.areEqual( false, preAbxIsActive, 'Pre-ABX isActive should be set to false when deactivating' );
    }

    // Handles the callouts made by doTrustedURLs:
    //   GET  → returns three CspTrustedSite records (Tableau, Salesforce_SCRT, Salesforce_Setup)
    //   PATCH (×3) → returns 204 for each site and captures the request bodies for assertions
    private class TrustedUrlsCalloutMock implements HttpCalloutMock {
        public List<String> capturedPatchBodies = new List<String>();

        public HTTPResponse respond( HTTPRequest request ) {
            HTTPResponse response = new HTTPResponse();
            if ( 'GET'.equals( request.getMethod() ) ) {
                response.setStatusCode( 200 );
                response.setBody(
                    '{"records":['
                    + '{"Id":"a1B000000000001AAA","DeveloperName":"Tableau"},'
                    + '{"Id":"a1B000000000002AAA","DeveloperName":"Salesforce_SCRT"},'
                    + '{"Id":"a1B000000000003AAA","DeveloperName":"Salesforce_Setup"}'
                    + ']}'
                );
            } else {
                capturedPatchBodies.add( request.getBody() );
                response.setStatusCode( 204 );
                response.setBody( '' );
            }
            return response;
        }
    }

    // Handles the two sequential callouts made by doGlobalValueSets:
    //   GET  → returns a GlobalValueSet record with Pre-ABX at the given initial state
    //   PATCH → returns 204 and captures the request body for assertions
    private class GlobalValueSetCalloutMock implements HttpCalloutMock {
        private Boolean initialPreAbxActive;
        public String capturedPatchBody;

        public GlobalValueSetCalloutMock( Boolean initialPreAbxActive ) {
            this.initialPreAbxActive = initialPreAbxActive;
        }

        public HTTPResponse respond( HTTPRequest request ) {
            HTTPResponse response = new HTTPResponse();
            if ( 'GET'.equals( request.getMethod() ) ) {
                response.setStatusCode( 200 );
                response.setBody(
                    '{"records":[{"Id":"a1B000000000001AAA","Metadata":{"urls":{},"customValue":['
                    + '{"valueName":"Pre-ABX","isActive":' + String.valueOf( initialPreAbxActive ) + ',"urls":{}},'
                    + '{"valueName":"Active","isActive":true,"urls":{}}'
                    + ']}}]}'
                );
            } else {
                capturedPatchBody = request.getBody();
                response.setStatusCode( 204 );
                response.setBody( '' );
            }
            return response;
        }
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
