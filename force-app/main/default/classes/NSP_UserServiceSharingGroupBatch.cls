/**************************************************************************************************   
Version              :  1.0                                                                          
Created Date         :  January 24, 2023                                                             
Function             :  Represents the NSP_UserServiceSharingGroupBatch which handles the adding of Service Profile members to Service Sharing Visibility Group.
Test class           :  NSP_UserServiceSharingGroupBatchTest
Story                :  STY-03841                                                                      
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* -------------------------------------------------------------------------------------------------  
***************************************************************************************************/
public class NSP_UserServiceSharingGroupBatch implements Database.Batchable < sObject > {
    
    public String createdByUserId;
    public String createdDate;
    
    public NSP_UserServiceSharingGroupBatch(string createdByUserId, String createdDate){
        this.createdByUserId = createdByUserId;
        this.createdDate = createdDate;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {  
        
        List<string> serviceProfiles = System.Label.NSP_ServiceProfiles.split(',');
        List<String> USER_FIELDS = new List<String>{'Id', 'NSP_Profile_Name__c', 'CreatedDate', 'CreatedById'};
            NSP_QueryBuilder userQuery = new NSP_QueryBuilder(NSP_ServiceConstants.USER_OBJECT, USER_FIELDS)
            .addFilter('CreatedById', createdByUserId)
            .addFilter('NSP_User_Profile_Name__c', serviceProfiles, NSP_QueryBuilder.Operator.INCLUDES)
            .setSecurityEnforce(false);
        String query = userQuery.build();
        query += ' AND CreatedDate =' + createdDate;
        return  Database.getQueryLocator(query);
       
       
    }
    
    /**
* @MethodName: execute
* @Description: This method describes about Sharing of Users with the Service Sharing Visibility Group.
* @param : List<Users> userList
* @createdDate : 01/24/2023
* @Story : STY-03841
* @return void                          
*/
    
    public void execute(Database.BatchableContext bc, List < User > serviceUserList) {
        Set<Id> serviceUserIdSet = new Set<Id>();
        for(User usr : serviceUserList){
            serviceUserIdSet.add(usr.Id);
        }
        try{
            if(!serviceUserIdSet.isEmpty()){
                NSP_UserTriggerHelper.addtoServiceProfilePublicGroup(serviceUserIdSet);
            }
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_UserServiceSharingGroupBatch', 'execute', ex.getMessage());
        }
    }
    
    /**
* @MethodName: finish
* @Description: This method describes about the finish method when the execution of batch completes.
* @param : 
* @createdDate : 01/24/2023
* @Story : STY-03841
* @return void                          
*/
    public void finish(Database.BatchableContext bc) {
        
    }
}