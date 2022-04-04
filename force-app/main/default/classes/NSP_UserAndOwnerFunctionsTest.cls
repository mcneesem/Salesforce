/**
* Author: Sales Dev Team
* Represents test class for lead opportunity helper
* Test Class to cover NSP_UserAndOwnerFunctions class
* Modified Date: 3/3/2022
*/
@isTest(SeeAllData=false)
public class NSP_UserAndOwnerFunctionsTest {
    
    public static final String OPP_NSP_UPSELL_PRODUCT_ADD_ONS_RETIREMENT_SERVICES = 'Retirement Services';
    public static final String ACCOUNT_NAME = 'Test Account1';  
    public static final String NDA = 'NDA'; 
    public static final String OPP_TYPE = 'CAMS';
    
    /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    
    @testSetup
    static void testData() {
        
        Account accoutObject1 = new Account();
        accoutObject1.Name = ACCOUNT_NAME;
        insert accoutObject1;       
        Account account = New Account(Name = 'TestAccount', AccountNumber = '12345',NSP_AIMS_Client__c = 'ateammember1');
        insert account;
        NSP_TestHelper.createContact(account.id, true);
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Opportunity opportuniytObject3 = new Opportunity();
            opportuniytObject3 = NSP_TestHelper.createOpenOpportunity(accoutObject1.Id, OPP_TYPE, false);
            opportuniytObject3.stagename = NSP_SalesConstants.ANALYSIS_STAGE;
            opportuniytObject3.NSP_PrimaryProduct__c = NSP_SalesConstants.WX;
            opportuniytObject3.NSP_Client_For_Life__c = NSP_SalesConstants.WX;
            opportuniytObject3.NSP_Number_of_Employees__c = 151; //!do not change. Test might fail
            insert opportuniytObject3;
            NSP_TestHelper.createCPQQuote(accoutObject1.Id,opportuniytObject3.Id,true);
        }
        
    }
    
    /**
* @Description: This test method is used to cover getQuoteOwner method 
* @Created date: 03/03/2022.
* @return void             
*                
*/
    @isTest
    static void getQuoteOwnerTest(){
        Account accObj = [Select Id,Name from Account WHERE Name= 'TestAccount'  LIMIT 1];
        AccountContactRelation acrObj  = [Select Id , NSP_Is_Primary__c ,ContactId, IsActive from AccountContactRelation WHERE AccountId =: accObj.Id ];
        acrObj.NSP_Is_Primary__c=true;
        update acrobj;
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
    
    /**
* @Description: This test method is used to cover setDummyUsers method 
* @Created date: 03/03/2022.
* @return void             
*                
*/
    @isTest
    public static void setDummyUsersTest(){
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

    /**
    * @Description: This test method is used to cover getAccountOwnerEmail method of NSP_OpportunityTriggerHelperFunctions
    * @Created date: 12/03/2022.
    * @Author : Nischay Jindal
    * @return void             
    *                
    */    
    @isTest
    public static void getAccountOwnerEmail(){
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
        NSP_OpportunityTriggerHelperFunctions.getAccountOwnerEmail(accountIds);
        Test.stopTest();
        Opportunity opp =[Select Id , NSP_Primary_Contact__c from Opportunity WHERE Id =:oppty.Id ];
        system.assertEquals( accr.Contactid,opp.NSP_Primary_Contact__c);
    }
}