@isTest
private class PortalProvisionActionTest {

    @testSetup
    private static void setupData() {
        //
        Account sharedAccount = new Account();
        sharedAccount.Name = 'sharedAccountName';
        insert sharedAccount;
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