/**
* Author: Sales Team
* Represents test class for FlowInterviewListController
* Test Class to cover FlowInterviewListController
* Modified Date: 02/07/2022
*/

@isTest(SeeAllData=false)
public class NSP_FlowInterviewListControllerTest {
    public static final String OPP_TYPE = 'CAMS';  
    /**
* @Description: This test method is used to cover getInterviews method
* @Created date: 02/11/2022.
* @return void             
*                
*/  
    static testMethod void getInterviewsTest() {
        Account  acc = NSP_TestHelper.createAccount(true);
        Opportunity  opportuniytObject = NSP_TestHelper.createOpenOpportunity(acc.Id, OPP_TYPE, true);
        Test.startTest();
        NSP_FlowInterviewListController.getInterviews(opportuniytObject.ID);
        try{
            NSP_FlowInterviewListController.deleteInterview(null);
        }catch (Exception ex) {
            NSP_CustomException.LogException(ex);
        }
        Test.stopTest();
        system.assertEquals(OPP_TYPE, opportuniytObject.Type);
    }
    
}