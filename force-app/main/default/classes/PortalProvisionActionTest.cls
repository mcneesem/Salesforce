@isTest
private class PortalProvisionActionTest {

    @testSetup
    private static void setupData() {
        //
        Portal_Access_Settings__c settings = Portal_Access_Settings__c.getOrgDefaults();
        settings.IsEnabled__c = true;
        settings.IsDryRun__c = true;
        settings.CommunityProfileId__c = '00e4x0000013MV2AAM'; // Customer Community Plus
        settings.MembershipPermissionSetName__c = 'Portal_Site_Access';
        settings.AllowedPermissionSetNames__c = 'Portal_Site_Access\r\nPortal_Use_File_Actions';
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
    }

    @isTest
    private static void testAction() {
        //
        List<AccountContactRelation> relations = [
            SELECT
                Id ,
                AccountId ,
                ContactId ,
                NSP_Work_Email__c
            FROM AccountContactRelation
        ];
        //
        Test.startTest();
        PortalProvisionAction.FlowInput input = new PortalProvisionAction.FlowInput();
        input.recordId = ( ( ( relations != null ) && !relations.isEmpty() ) ? relations[0].Id : '' );
        List<PortalProvisionAction.FlowInput> inputs = new List<PortalProvisionAction.FlowInput>();
        inputs.add( input );
        List<PortalProvisionAction.FlowOutput> outputs = PortalProvisionAction.provision( inputs );
        Test.stopTest();
    }

}
//