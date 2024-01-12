/**
* @description  :  class for set up manual sharing rules after User Update.
* @date 05/24/2022
* Author : Nischay Jindal
* Name : NSP_userSalesOfficeRecordSharing
*/
public class NSP_userSalesOfficeRecordSharing {
     //Added for 579280
     public static List<string> BusinessPerformanceRoles = System.Label.NSP_Business_Performance_Roles.split(',');    
    /***********************************************************************************************
    * MethodName: ownerSalesofficeSharing
    * Description : Method to share records with related Objects on User sales Office Update
    * Params: Map<Id,User> userNewMap ,Map<Id,User> userOldMap
    * ********************************************************************************************/
    public static void ownerSalesofficeSharing(Map<Id,User> userNewMap ,Map<Id,User> userOldMap  ){
        Set<Id> newUserIdSet = new Set<Id>();
        Map<String,Set<String>> mapNewSalesOfficeSetUserId = new Map<String,Set<String>>();
        Map<String,Set<String>> mapUserIdSetOldSalesOffice= new Map<String,Set<String>>();
        Map<String,String> mapSalesOfficeLabels =salesOfficePicklistLabelsMap();
        List<User> updateUserList = new  List<User>();
        try{
            Map<Id,User> newUserMap =new Map<Id,User>([SELECT Id,NSP_Office_Processing__c, UserRole.Name,UserRoleId, ToLabel(NSP_Sales_Office_Membership__c)  FROM User 
                                                       WHERE Id IN:userNewMap.Keyset()  AND IsActive = True AND UserRole.Name IN:BusinessPerformanceRoles 
                                                      AND (NSP_Office_Processing__c=null OR NSP_Office_Processing__c=:NSP_SalesConstants.officeProcessing)]);
            
            for(User usr: newUserMap.Values() ){
                if(userNewMap.get(usr.Id).NSP_Sales_Office_Membership__c!=userOldMap.get(usr.Id).NSP_Sales_Office_Membership__c){
                    Set<String> oldSalesOfficeMembershipSet = new Set<String>();
                    Set<String> newSalesOfficeMembershipSet = new Set<String>();
                    // update Account , Account Team , Opportunity and Lead Sharing when there is a change in User Sales Office
                    newUserIdSet.add(usr.Id);
                    // creating list of old Sales Offices
                    if(userOldMap.get(usr.Id).NSP_Sales_Office_Membership__c != null){
                        for(String oldSalesOffice: userOldMap.get(usr.Id).NSP_Sales_Office_Membership__c.Split(';')){
                            oldSalesOfficeMembershipSet.add(mapSalesOfficeLabels.get(oldSalesOffice));  
                        }  
                    }
                    if(usr.NSP_Sales_Office_Membership__c != null ){
                        // creating a Set of new Sales Offices
                        newSalesOfficeMembershipSet.addAll(new List<String>(usr.NSP_Sales_Office_Membership__c.Split(';')));
                        
                        // comparing new Sales Office MemberShip with old Sales Office MemberShip
                        // Creating a map of Sales Office and Set of User Id
                        for(String newSalesOffice: newSalesOfficeMembershipSet){
                            // if new Sales office not matches Old sales Office or Old sales Office is Empty
                            if((!oldSalesOfficeMembershipSet.isEmpty() && !oldSalesOfficeMembershipSet.contains(newSalesOffice))
                               || oldSalesOfficeMembershipSet.isEmpty() ) {
                                   if(mapNewSalesOfficeSetUserId.get(newSalesOffice)==null){
                                       mapNewSalesOfficeSetUserId.put(newSalesOffice, new Set<String>());
                                   }
                                   mapNewSalesOfficeSetUserId.get(newSalesOffice).add(usr.Id);
                               }
                            
                            // remove duplicate Sales Offices from the Old Sales Office Membership 
                            if(!oldSalesOfficeMembershipSet.isEmpty() && oldSalesOfficeMembershipSet.contains(newSalesOffice)){
                                oldSalesOfficeMembershipSet.remove(newSalesOffice);
                            }   
                        }
                    } 
                    // create map of User Id Set old Sales Office
                    if(!oldSalesOfficeMembershipSet.isEmpty()){
                        mapUserIdSetOldSalesOffice.put(usr.Id,oldSalesOfficeMembershipSet);
                        
                        // updating old Offices on User 
                        User user = new User ();
                        user.Id=usr.Id;
                        user.NSP_Office_Processing__c= String.join(new List<String>(oldSalesOfficeMembershipSet),';');
                        updateUserList.add(user);
                    }
                }
            }
            if(!newUserIdSet.isEmpty()){
                // calling Queueable Job for Account
              System.enqueueJob( new NSP_userAccountSalesOfficeSharing( mapNewSalesOfficeSetUserId,mapUserIdSetOldSalesOffice,newUserIdSet ) ); 
             }
            if(!updateUserList.isEmpty()){
                Update updateUserList;
            }
            
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_userSalesOfficeRecordSharing', 'ownerSalesofficeSharing', ex.getMessage());
        } 
    }
    
    /***********************************************************************************************
    * MethodName: salesOfficePicklistLabelsMap
    * Description : Method to retrieve the selected Sales Office 
    *
    * ********************************************************************************************/
    public static Map < String, String > salesOfficePicklistLabelsMap() {
        Map < String, String > salesOfficePicklistMap = new Map < String, String > ();
        Schema.SObjectType getObject = Schema.getGlobalDescribe().get(NSP_SalesConstants.SalesOfficeObject);
        Schema.DescribeSObjectResult getPicklist = getObject.getDescribe();
        Map < String, Schema.SObjectField > fields = getPicklist.fields.getMap();
        Schema.DescribeFieldResult fieldResult = fields.get(NSP_SalesConstants.SalesOffice).getDescribe();
        List < Schema.PicklistEntry > picklistMap = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal: picklistMap) {
            salesOfficePicklistMap.put(pickListVal.getValue(), pickListVal.getLabel());
        }
        return salesOfficePicklistMap;
    }    
    
}