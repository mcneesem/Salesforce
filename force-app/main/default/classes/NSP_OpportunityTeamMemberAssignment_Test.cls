/*
*@Description: This class is used to cover the NSP_OpportunityTeamMemberAssignment Class.
@createdDate: 01/18/2022
@Story : STY-02066
*/
@isTest(SeeAllData=false)
public class NSP_OpportunityTeamMemberAssignment_Test {
    
    public static final String OPP_NSP_UPSELL_PRODUCT_ADD_ONS_RETIREMENT_SERVICES = 'Retirement Services';
    /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    
    @testSetup
    static void testData() {
        //Creating User
        User userRecord = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id,
            LastName = 'TestClassUser',
            Email = 'testuser@test.com',
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
    
    /**
* This Method is used to cover insertOppTeamMember method
* @param N/A. 
* @return void                          
*/
    @isTest
    static void insertOppTeamMemberTest() {
        List<Opportunity> oppList = [SELECT Id, Name, OwnerId FROM Opportunity WHERE NSP_PrimaryProduct__c = 'WX' LIMIT 1];
        Test.startTest();
        NSP_OpportunityTeamMemberAssignment.insertOppTeamMember(oppList);
        Test.stopTest();
        
        List<OpportunityTeamMember> assertOppTeam = [SELECT Id, 
                                                     OpportunityId,
                                                     UserId
                                                     FROM OpportunityTeamMember 
                                                     WHERE OpportunityId =: oppList[0].Id ];
        system.assertEquals(1, assertOppTeam.size());
    }
    
    /**
* This Method is used to cover updateAndInsertOppTeamMember method
* @param N/A. 
* @return void                          
*/
    @isTest
    static void updateAndInsertOppTeamMemberTest() {
        
        Opportunity opp = [SELECT Id, 
                           OwnerId,
                           Name 
                           FROM Opportunity
                           WHERE NSP_PrimaryProduct__c = 'WX'
                           LIMIT 1];
        User getUser = [SELECT Id, 
                        Email,
                        Name 
                        FROM User 
                        WHERE Email = 'testuser@test.com' 
                        LIMIT 1 ];
        Test.startTest();
        opp.OwnerId = getUser.Id;
        Database.update(opp);
        Test.stopTest();
         List<OpportunityTeamMember> assertOppTeam = [SELECT Id, 
                                                     OpportunityId,
                                                     UserId
                                                     FROM OpportunityTeamMember 
                                                     WHERE OpportunityId =: opp.Id ];
        system.assertEquals(2, assertOppTeam.size());
        
    }
    
    
}