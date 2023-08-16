public class NSP_customNewProjButtonController {

    private static final List<String> USER_FIELDS = new List<String>{ 
        'NSP_Profile_Name__c'
    };
/**
* @description  :  method to check if user is System admin
* Author : Abhishek Kumar
* Story : STY-01938
*/ 
@AuraEnabled(cacheable = false)
public static Boolean isUserPermittedToCreateProject( Id currentUserId){
    //query login in user
    try{
    User UserInfo = (User) new NSP_sObjectSelector('User', USER_FIELDS).selectById(currentUserId);
    return UserInfo.NSP_Profile_Name__c == 'System Administrator';
    }catch (Exception ex) { throw NSP_Utilities.getAuraException(ex); } //moving to one line for test class coverage.
}
    
}