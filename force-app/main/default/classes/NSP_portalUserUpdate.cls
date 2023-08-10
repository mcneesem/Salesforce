/**
* @description  :  Class to update the user activation and deactivation
* @date 08/02/2023
* Author : Nischay Jindal
* Name : NSP_portalUserUpdate
*/
public class NSP_portalUserUpdate implements Queueable  {
    
    /***********************************************************************************************
    * Variables --> userIdSet , activeStatus , permIdSet
    * ********************************************************************************************/   
    public Set<Id> userIdSet = new Set<Id>();
    public Boolean  activeStatus = false;
    public Set<Id> permIdSet = new Set<Id>();
    public Set<Id> removePermUserIdSet = new Set<Id>();
    public Set<Id> permissionIdSet = new Set<Id>();
    public NSP_portalUserUpdate(Set<Id> userIdSet , Boolean activeStatus ,  Set<Id> permIdSet ,  Set<Id> removePermUserIdSet, Set<Id> permissionIdSet ){
        this.userIdSet = userIdSet;
        this.activeStatus = activeStatus;
        this.permIdSet =  permIdSet;
        this.removePermUserIdSet =  removePermUserIdSet;
        this.permissionIdSet =  permissionIdSet;
    }
    
    public void execute(QueueableContext qc) {  
        try{
            portalUsersActiveStatus(userIdSet,activeStatus,permIdSet,removePermUserIdSet,permissionIdSet);
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_portalUserUpdate', 'Execute', ex.getMessage());     
        }
    }
    
    /***********************************************************************************************
    * MethodName: portalUsersActiveStatus
    * Description :  This method will change the Active status of the user based on the account group relationship
    * Params:   Set<Id> userIdSet , Boolean activeStatus ,  Set<Id> permIdSet 
    * ********************************************************************************************/    
     public static void portalUsersActiveStatus(Set<Id> userIdSet , Boolean activeStatus ,  Set<Id> permIdSet , Set<Id> removePermUserIdSet, Set<Id> permissionIdSet){
        List <User> updatedUserList = new List <User>();
        for(User usr:[SELECT Id , isActive FROM User WHERE Id IN: userIdSet ]){
            usr.isActive = activeStatus;
            updatedUserList.add(usr);
        }       
        if(!updatedUserList.isEmpty()){
            Database.update(updatedUserList,false) ;
            if(!removePermUserIdSet.isEmpty()){
                NSP_AccountContactServiceHelper.removeUserPermissions(removePermUserIdSet,permissionIdSet);
            }
        }
        if(activeStatus){
            NSP_AccountContactServiceHelper.createUserPerm(userIdSet,permIdSet );
        }
       
    }
    
}