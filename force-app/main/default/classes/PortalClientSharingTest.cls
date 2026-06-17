@isTest
private class PortalClientSharingTest {

    @testSetup
    private static void setupData() {
        //
        Portal_Client_Sharing_Settings__c settings = Portal_Client_Sharing_Settings__c.getOrgDefaults();
        settings.IsEnabled__c = true;
        settings.IsDryRun__c = true;
        upsert settings;
        //
        Account sharedAccount = new Account();
        sharedAccount.Name = 'sharedAccountName';
        //
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
            insert sharedAccount;
        }
        //
        Contact sharedContact = new Contact();
        sharedContact.AccountId = sharedAccount.Id;
        sharedContact.NSP_Work_Email__c = UserInfo.getUserEmail();
        sharedContact.NSP_Preferred_First_Name__c = 'sharedContactFirstName';
        sharedContact.LastName = 'sharedContactLastName';
        sharedContact.Portal_Alias__c = 'lastname.number';
        insert sharedContact;
        //
        Portal_Client__c sharedPortalClient = new Portal_Client__c();
        sharedPortalClient.Name = 'sharedPortalClientName';
        sharedPortalClient.Account__c = sharedAccount.Id;
        insert sharedPortalClient;
        //
        User sharedPortalUser = new User();
        sharedPortalUser.ContactId = sharedContact.Id;
        sharedPortalUser.ProfileId = '00e4x0000013MV2AAM'; // Customer Community Plus User
        sharedPortalUser.FederationIdentifier = 'sharedPortalUser@test.insperity.com.invalid';
        sharedPortalUser.UserName = 'sharedPortalUser@test.insperity.com.invalid' + System.currentTimeMillis();
        sharedPortalUser.Email = 'sharedPortalUser@test.insperity.com.invalid';
        sharedPortalUser.Alias = SchemaController.safeText(
            'sharedPortalUser' ,
            sObjectType.User.Fields.Alias
        );
        sharedPortalUser.CommunityNickname = SchemaController.safeText(
            'sharedPortalUser' ,
            sObjectType.User.Fields.CommunityNickname
        );
        sharedPortalUser.FirstName = SchemaController.safeText(
            sharedContact.NSP_Preferred_First_Name__c ,
            sObjectType.User.Fields.FirstName
        );
        sharedPortalUser.LastName = SchemaController.safeText(
            sharedContact.LastName ,
            sObjectType.User.Fields.LastName
        );
        sharedPortalUser.EmailEncodingKey = 'UTF-8';
        sharedPortalUser.LanguageLocaleKey = 'en_US';
        sharedPortalUser.LocaleSidKey = 'en_US';
        sharedPortalUser.TimeZoneSidKey = 'America/Chicago';
        System.runas( deploymentManager ) {
            insert sharedPortalUser;
        }
        //
    }

    @isTest
    private static void testAccount() {
        Map<Id,Account> records = new Map<Id,Account>(
            [
                SELECT Id
                FROM Account
                ORDER BY CreatedDate DESC
                LIMIT 1
            ]
        );
        Test.startTest();
        PortalClientSharing.enqueueJob( records.keySet() );
        Test.stopTest();
    }

    @isTest
    private static void testAccountContactRelation() {
        Map<Id,AccountContactRelation> records = new Map<Id,AccountContactRelation>(
            [
                SELECT Id
                FROM AccountContactRelation
                ORDER BY CreatedDate DESC
                LIMIT 1
            ]
        );
        Test.startTest();
        PortalClientSharing.enqueueJob( records.keySet() );
        Test.stopTest();
    }

    @isTest
    private static void testContact() {
        Map<Id,Contact> records = new Map<Id,Contact>(
            [
                SELECT Id
                FROM Contact
                ORDER BY CreatedDate DESC
                LIMIT 1
            ]
        );
        Test.startTest();
        PortalClientSharing.enqueueJob( records.keySet() );
        Test.stopTest();
    }

    @isTest
    private static void testPortalClient() {
        Map<Id,Portal_Client__c> records = new Map<Id,Portal_Client__c>(
            [
                SELECT Id
                FROM Portal_Client__c
                ORDER BY CreatedDate DESC
                LIMIT 1
            ]
        );
        Test.startTest();
        PortalClientSharing.enqueueJob( records.keySet() );
        Test.stopTest();
    }

    @isTest
    private static void testUser() {
        Map<Id,User> records = new Map<Id,User>(
            [
                SELECT Id
                FROM User
                WHERE ( ContactId != null )
                ORDER BY CreatedDate DESC
                LIMIT 1
            ]
        );
        Test.startTest();
        PortalClientSharing.enqueueJob( records.keySet() );
        Test.stopTest();
    }

    @isTest
    private static void testExistingShares() {
        Map<Id,Portal_Client__c> clients = new Map<Id,Portal_Client__c>(
            [
                SELECT Id
                FROM Portal_Client__c
                ORDER BY CreatedDate DESC
                LIMIT 1
            ]
        );
        //
        Map<Id,User> portalUsers = new Map<Id,User>(
            [
                SELECT Id
                FROM User
                WHERE ( ContactId != null )
                ORDER BY CreatedDate DESC
                LIMIT 1
            ]
        );
        //
        //insert new Portal_Client__Share(
        //    ParentId=clients.values()[0].Id ,
        //    UserOrGroupId=portalUsers.values()[0].Id ,
        //    AccessLevel='Read' ,
        //    RowCause=Schema.Portal_Client__Share.RowCause.InsperitySharing__c
        //);
        //
        Test.startTest();
        PortalClientSharing.enqueueJob( clients.keySet() );
        Test.stopTest();
    }

}
//