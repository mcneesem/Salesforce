@isTest
private class NSP_OpportunityTeamMemberAssignment_Test {

    private static final String OPP_NSP_UPSELL_PRODUCT_ADD_ONS_RETIREMENT_SERVICES = 'Retirement Services';

    @testSetup
    private static void testData() {
        //Creating User
        User userRecord = new User(
            ProfileId = '00e4x000001r0zsAAA' , // System Administrator
            LastName = 'TestClassUser',
            Email = 'testuser@insperity.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        //Inserting users that can be used in the test class data setup
        insert userRecord;

        Account accoutObject1 = new Account();
        accoutObject1.Name = 'Test Account1';
        //inserting account object
        insert accoutObject1;

        //Create Opportunity
        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Name = 'Test Oppty';
        opportuniytObject.AccountId = accoutObject1.id;
        opportuniytObject.stagename = 'Discovery';
        opportuniytObject.CloseDate = date.today();
        opportuniytObject.CurrencyIsoCode ='USD';
        opportuniytObject.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject.NSP_Number_of_Employees__c = 100;
        opportuniytObject.Type ='CAMS';
        opportuniytObject.NSP_Upsell_Product_add_ons__c = OPP_NSP_UPSELL_PRODUCT_ADD_ONS_RETIREMENT_SERVICES;
        insert opportuniytObject;
    }

    @isTest
    private static void insertOppTeamMemberTest() {
        List<Opportunity> oppList = [
            SELECT Id, Name, OwnerId
            FROM Opportunity
            WHERE NSP_PrimaryProduct__c = 'WX'
            LIMIT 1
        ];
        Test.startTest();
        NSP_OpportunityTeamMemberAssignment.insertOppTeamMember(oppList);
        Test.stopTest();
        List<OpportunityTeamMember> assertOppTeam = [
            SELECT Id,
            OpportunityId,
            UserId
            FROM OpportunityTeamMember
            WHERE OpportunityId =: oppList[0].Id
        ];
        System.assertEquals(1, assertOppTeam.size());
    }

    @isTest
    private static void updateAndInsertOppTeamMemberTest() {
        Opportunity opp = [
            SELECT Id,
            OwnerId,
            Name
            FROM Opportunity
            WHERE NSP_PrimaryProduct__c = 'WX'
            LIMIT 1
        ];
        User getUser = [
            SELECT Id,
            Email,
            Name
            FROM User
            WHERE Email = 'testuser@insperity.com'
            LIMIT 1
        ];
        Test.startTest();
        opp.OwnerId = getUser.Id;
        Database.update(opp);
        Test.stopTest();
        List<OpportunityTeamMember> assertOppTeam = [
            SELECT Id,
            OpportunityId,
            UserId
            FROM OpportunityTeamMember
            WHERE OpportunityId =: opp.Id
        ];
        System.assertEquals(2, assertOppTeam.size());

    }

}
//