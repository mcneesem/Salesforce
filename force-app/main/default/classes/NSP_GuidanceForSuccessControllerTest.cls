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
        List<NSP_Opportunity_Stage_Guidance_Path__mdt> guidanceMessages = NSP_GuidanceForSuccessController.getGuidanceForSuccessMessages();
        Test.stopTest();
         system.assert(guidanceMessages.size()>1); // Added as part of code fix
    }
}