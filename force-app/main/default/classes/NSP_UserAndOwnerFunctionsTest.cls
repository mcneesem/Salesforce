@isTest
private class NSP_UserAndOwnerFunctionsTest {

    private static final String OPP_NSP_UPSELL_PRODUCT_ADD_ONS_RETIREMENT_SERVICES = 'Retirement Services';
    private static final String ACCOUNT_NAME = 'Test Account1';
    private static final String NDA = 'NDA';
    private static final String OPP_TYPE = 'CAMS';
    private static final String emailencodingkey = 'UTF-8';
    private static final String languagekey = 'en_US';
    private static final String timezonesidkey = 'America/Los_Angeles';

    @testSetup
    private static void testData() {
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile profileobj = [SELECT Id FROM Profile WHERE Name='System Administrator'];
            UserRole BPArole = [SELECT Id FROM UserRole WHERE Name='Business Performance Advisor'];
            UserRole SalesLeaderRole = [SELECT Id FROM UserRole WHERE Name='Sales Leader'];
            // Adding BPA User
            User BpaUser = new User(alias = 'jsmiths', email='jsmith@insperity.com',
                                    emailencodingkey=emailencodingkey, lastname='Smiths',
                                    languagelocalekey=languagekey,
                                    localesidkey=languagekey, profileid = profileobj.Id, userroleid = BPArole.Id,
                                    timezonesidkey=timezonesidkey ,
                                    username='insperitytestadminuser@insperity.com.testUsrs');
            insert BpaUser;

            Account accoutObject1 = new Account();
            accoutObject1.Name = ACCOUNT_NAME;
            accoutObject1.OwnerId = BpaUser.Id;
            insert accoutObject1;

            Account account = New Account(Name = 'TestAccount',AccountNumber = '12345',NSP_AIMS_Client__c = 'ateammember1',  OwnerId = BpaUser.Id);
            insert account;
            Test.startTest();
            NSP_TestHelper.createContact(account.id, true);
            AccountContactRelation acrObj  = [Select Id , NSP_Is_Primary__c ,ContactId, IsActive from AccountContactRelation WHERE AccountId =: account.Id ];
            acrObj.NSP_Is_Primary__c=true;
            update acrobj;

            Opportunity opportuniytObject3 = new Opportunity();
            opportuniytObject3 = NSP_TestHelper.createOpenOpportunity(accoutObject1.Id, OPP_TYPE, false);
            opportuniytObject3.stagename = NSP_SalesConstants.ANALYSIS_STAGE;
            opportuniytObject3.NSP_PrimaryProduct__c = NSP_SalesConstants.WX;
            opportuniytObject3.NSP_Client_For_Life__c = NSP_SalesConstants.WX;
            opportuniytObject3.NSP_Number_of_Employees__c = 151; //!do not change. Test might fail
            opportuniytObject3.OwnerId = BpaUser.Id;
            insert opportuniytObject3;
            NSP_TestHelper.createCPQQuote(accoutObject1.Id,opportuniytObject3.Id,true);
            Test.stopTest();
        }
    }

    @isTest
    private static void getQuoteOwnerTest() {
        List<Opportunity> opportunityList = [SELECT Id,AccountId, Name,NSP_Number_of_Employees__c,Type, NSP_PrimaryProduct__c,
                                             NSP_DM_User__c,NSP_DA_User__c,NSP_Merge_On_Demand_Template_Selection__c,SBQQ__PrimaryQuote__c,NSP_BPA__c,OwnerId FROM Opportunity
                                             WHERE NSP_Number_Of_Employees__c = 151 AND StageName =: NSP_SalesConstants.ANALYSIS_STAGE AND NSP_PrimaryProduct__c =: NSP_SalesConstants.WX LIMIT 1];

        Test.startTest();

        opportunity oppty = opportunityList[0];
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :oppty.Id LIMIT 1];

        NSP_UserAndOwnerFunctions triggerHelper = new NSP_UserAndOwnerFunctions();
        triggerHelper.getQuoteOwner(opportunityList, quote.id);

        oppty.SBQQ__PrimaryQuote__c = quote.Id;
        oppty.NSP_DM_User__c = oppty.OwnerId;
        oppty.NSP_DA_User__c = oppty.OwnerId;
        oppty.StageName = NSP_SalesConstants.ANALYSIS_STAGE;
        oppty.NSP_Merge_On_Demand_Template_Selection__c = NDA;

        update oppty;
        Test.stopTest();
        System.assertEquals(oppty.StageName, NSP_SalesConstants.ANALYSIS_STAGE);
    }

    @isTest
    private static void setDummyUsersTest() {
        List<Opportunity> opportunityList = [SELECT Id,AccountId, Name,NSP_Number_of_Employees__c,Type, NSP_PrimaryProduct__c,
                                             NSP_DM_User__c,NSP_DA_User__c,NSP_Merge_On_Demand_Template_Selection__c,SBQQ__PrimaryQuote__c,NSP_BPA__c,OwnerId FROM Opportunity
                                             WHERE NSP_Number_Of_Employees__c = 151 AND StageName =: NSP_SalesConstants.ANALYSIS_STAGE AND NSP_PrimaryProduct__c =: NSP_SalesConstants.WX LIMIT 1];
        opportunity oppty = opportunityList[0];
        oppty.NSP_BPA__c = UserInfo.getUserId();
        Test.startTest();
        Database.update(oppty);
        Test.stopTest();
        System.assertEquals(oppty.NSP_BPA__c, UserInfo.getUserId());
    }

    @isTest
    private static void populatePrimaryContactCustomerSigner() {
        Test.startTest();
        List<Opportunity> opportunityList = [SELECT Id,AccountId, NSP_Primary_Contact__c FROM Opportunity
                                             WHERE NSP_Number_Of_Employees__c = 151 AND StageName =: NSP_SalesConstants.ANALYSIS_STAGE AND NSP_PrimaryProduct__c =: NSP_SalesConstants.WX LIMIT 1];

        Account accRecord =[Select Id , Name from Account WHERE Name ='TestAccount' Limit 1];
        AccountContactRelation accr=[SELECT Id  ,ContactId,NSP_Is_Primary__c, AccountId from AccountContactRelation WHERE  AccountId =: accRecord.Id Limit 1  ];
        accr.NSP_Is_Primary__c= true;
        update accr;
        Set<Id> accountIds= new Set<Id>();
        accountIds.add(accRecord.Id);
        opportunity oppty = opportunityList[0];
        oppty.AccountId=accRecord.Id;
        update oppty;
        NSP_OpportunityTriggerHelperFunctions.populatePrimaryContactCustomerSigner(accountIds);
        Test.stopTest();
        Opportunity opp =[Select Id , NSP_Primary_Contact__c from Opportunity WHERE Id =:oppty.Id ];
        system.assertEquals( accr.Contactid,opp.NSP_Primary_Contact__c);
    }

    @isTest
    private static void setDummyUserTest() {
        Test.startTest();
        Account accObj = [Select Id,Name from Account WHERE Name= 'TestAccount'  LIMIT 1];
        AccountContactRelation acrObj  = [Select Id , NSP_Is_Primary__c ,ContactId, IsActive from AccountContactRelation WHERE AccountId =: accObj.Id AND NSP_Is_Primary__c = True ];
        User usr = [SELECT Id , LastName from User WHERE LastName ='Smiths'];
        System.runAs (usr){
            Opportunity opportuniytObject3 = new Opportunity();
            opportuniytObject3 = NSP_TestHelper.createOpenOpportunity(accObj.Id, OPP_TYPE, false);
            opportuniytObject3.stagename = NSP_SalesConstants.ANALYSIS_STAGE;
            opportuniytObject3.NSP_PrimaryProduct__c = NSP_SalesConstants.WX;
            opportuniytObject3.NSP_Client_For_Life__c = NSP_SalesConstants.WX;
            opportuniytObject3.NSP_Number_of_Employees__c = 151; //!do not change. Test might fail
            opportuniytObject3.OwnerId = Usr.Id;
            insert opportuniytObject3;
            List<Opportunity> OppList = new List<Opportunity>{opportuniytObject3};
            Set<String> accountId = new Set<String>{accObj.Id};
            Set<Id> OwnerId = new Set<Id>{Usr.Id};
            NSP_UserAndOwnerFunctions triggerHelper = new NSP_UserAndOwnerFunctions();
            triggerHelper.setDummyUsers(OppList,accountId,OwnerId);
        }
        Test.stopTest();
    }

}
//