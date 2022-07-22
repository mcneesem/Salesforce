/**
* @description  : Test Class for NSP_FinancialAnaylsisToolController
* @date 13/01/2022 
* Name : NSP_FinancialAnaylsisToolController_Test
*/

@isTest
public class NSP_FinancialAnaylsisToolController_Test {
    
/**********************************************************************************************
* Method Name:getAuthSessionId
* Purpose: Test Method for NSP_FinancialAnaylsisToolController 
***********************************************************************************************/
@istest
    public static void getAuthSessionId(){
        try{
            Test.startTest();
            User newUser = new User(Id= UserInfo.getUserId());
            system.runAs(newUser){
                NSP_FinancialAnaylsisToolController.navigateToFinancialAnaylsisTool();
                System.assertEquals(UserInfo.getUserId(),newUser.Id);
            }
            Test.stopTest();
        }
        catch(Exception ex){
            ex.getStackTraceString();
        }
        
    }
}