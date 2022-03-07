/**
* @description  : Aura Handler Class to generate the Auth Session Id of Current User
* @date 12/01/2022
* Name : NSP_FinancialAnaylsisToolController
*/

public class NSP_FinancialAnaylsisToolController {
    
    
/**********************************************************************************************
* Method Name:navigateToFinancialAnaylsisTool
* Purpose: This aura method is used to get AuthSession Id of the Current User
* Return Type : NSPFinancialAnaylsisWrapper
***********************************************************************************************/
   
    @AuraEnabled
    public static NSPFinancialAnaylsisWrapper navigateToFinancialAnaylsisTool(){
        NSPFinancialAnaylsisWrapper nspwrapper= new NSPFinancialAnaylsisWrapper();
        try{
            List<AuthSession> userSession = [SELECT Id,SessionType,UsersId FROM AuthSession WHERE UsersId = :UserInfo.getUserId() and SessionType = 'AURA'];
            String AuthId=userSession[0].Id;
            String UserName = UserInfo.getName();
            nspwrapper.auth=AuthId;
            nspwrapper.UserName=UserName;
            nspwrapper.UserId=UserInfo.getUserId(); 
        }catch(Exception ex){
            throw new AuraHandledException('navigateToFinancialAnaylsisTool'+ex.getMessage());
        }
        return nspwrapper; 
    }
    
/**********************************************************************************************
* Wrapper Class :NSPFinancialAnaylsisWrapper
***********************************************************************************************/    
    public class NSPFinancialAnaylsisWrapper{
        @AuraEnabled
        public  String auth{get;set;}
        @AuraEnabled 
        public  string UserName {get;set;}
        @AuraEnabled 
        public  string UserId {get;set;}
    }
    
    
}