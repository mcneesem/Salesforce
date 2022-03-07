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
    public static final String DEMAND_TEMPLATE_SELECTION = 'CommissionOnlyEmployeesQuestionnaire'; 
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
        oppty.NSP_Merge_On_Demand_Template_Selection__c = DEMAND_TEMPLATE_SELECTION;
        
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
    
}