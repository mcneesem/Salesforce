/**
* Represents test class for 
* Account trigger helper
* Author: Sales Team 
*/
@isTest(SeeAllData=false)
public class NSP_GuidanceForSuccessControllerTest {
    @testSetup
    static void testData(){
        Account accoutObject = new Account();
        accoutObject.Name = 'Test Account';
        //inserting account object
        insert accoutObject;
        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.accountId = accoutObject.Id;
        opportuniytObject.Name = 'Test Oppty';
        opportuniytObject.stagename = 'Discovery';
        opportuniytObject.CloseDate = date.today();
        opportuniytObject.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject.NSP_Number_of_Employees__c = 100;
        insert opportuniytObject;
    }
    
    @isTest
    public static void getGuidanceForSuccessMessagesTest(){
        Test.startTest();
        List<NSP_Opportunity_Stage_Guidance_Path__mdt> guidanceMessages = NSP_GuidanceForSuccessController.getGuidanceForSuccessMessages();
        Test.stopTest();
         system.assert(guidanceMessages.size()>1); // Added as part of code fix
    }
    
    @isTest
    public static void getOpportunityDetails(){
        Opportunity opp = [select id,Name, StageName, NSP_PrimaryProduct__c, NSP_Number_of_Employees__c from Opportunity where stagename = 'Discovery'];
        test.startTest();
        Opportunity oppty = NSP_GuidanceForSuccessController.getOpportunityDetails(opp.Id);
        test.stopTest();
        system.assertNotEquals(null, oppty);
    }
    
     @isTest
    public static void getOpportunityDetailsWithNoID(){
        test.startTest();
        try{
        	Opportunity oppty = NSP_GuidanceForSuccessController.getOpportunityDetails(null);
        }catch(Exception ex){
            ex.getMessage();
        }
        test.stopTest();
        
    }
}