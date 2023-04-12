public with sharing class NSP_Lib {

    public static String getRoleIdByApiName(String apiName){
        UserRole role = [SELECT Id FROM UserRole WHERE developerName =:apiName];
        if(role != null){
            return role.Id;
        }
        return '';
    }

    public static List<UserRole> getRolesIdByApiName(List<String> apiNames){
        List<UserRole> roles = [SELECT Id FROM UserRole WHERE developerName IN:apiNames];
        return roles;
    }
    
   
}