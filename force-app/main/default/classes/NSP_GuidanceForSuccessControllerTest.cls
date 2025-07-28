/**
* Represents test class for 
* Account trigger helper
* Author: Sales Team 
*/
@isTest(SeeAllData=false)
public class NSP_GuidanceForSuccessControllerTest {
   
    @isTest
    public static void getGuidanceForSuccessMessagesTest(){
        Test.startTest();
        String message1 = NSP_GuidanceForSuccessController.getMessage('Discovery', 'WS', null);
        String message2 = NSP_GuidanceForSuccessController.getMessage('Discovery', '', null);
        Test.stopTest();
        system.assert(message1.length() > 0); 
        system.assert(message2.length() > 0); 
    }
     
}