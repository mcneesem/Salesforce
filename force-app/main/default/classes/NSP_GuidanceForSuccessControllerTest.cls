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
        String message1 = NSP_GuidanceForSuccessController.getMessage('Discovery', 'WS', null);
        String message2 = NSP_GuidanceForSuccessController.getMessage('Discovery', '', null);
        Test.stopTest();
        system.assert(message1.length() > 0); 
        system.assert(message2.length() > 0); 
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