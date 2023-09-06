/**
* @description  :  class for set up manual sharing rules.
* @date 05/23/2022
* Added as part of STY-00721
* Name : NSP_ProjectRecordSharing
*/

public class NSP_ProjectRecordSharing {

    private static final String NSP_PROJECTRECORDSHARING = 'NSP_ProjectRecordSharing';
    
    /***********************************************************************************************
    * MethodName: projectRecordSharing 
	* Description : Method to share project records with community users
	* Params:       Map<Id, pse__Proj__c> mapOfProjects, Set<Id> accountIdSet
* ********************************************************************************************/      
    public static void projectRecordSharing ( Set<Id> accountIdSet, Map<Id, pse__Proj__c> mapOfProjects ) {
        
        List<pse__Proj__Share> newProjectShareList = new List<pse__Proj__Share>();
        Set<Id> contactIdSet = new Set<Id> ();
        Map<Id,Set<Id>> mapOfAccountContacts=new Map<Id,Set<Id>>();//accountidsetofContactidmap
        Map<Id,Id> mapOfUserContact=new Map<Id,Id>();//contactiduseridmap
        
        try{
            if(!accountIdSet.isEmpty()){
                //fetch all the acr associated to the project account
                List<AccountContactRelation> acrList = [SELECT ContactId,
                                                        AccountId 
                                                        FROM AccountContactRelation 
                                                        WHERE AccountId in : accountIdSet 
                                                        AND NSP_Community_Access__c INCLUDES (: NSP_ServiceConstants.peoCommunityAccess)];
                
                for(AccountContactRelation acr : acrList){
                    //get all contacts of acr where community access is peo projects
                    contactIdSet.add(acr.ContactId);
                    if(mapOfAccountContacts.get(acr.AccountId)==null){
                        mapOfAccountContacts.put(acr.AccountId,new Set<Id>());
                    }
                    mapOfAccountContacts.get(acr.AccountId).add(acr.ContactId);
                }
            
            
                if(!contactIdSet.isEmpty()){
                    //get all community users to whom project record need to be shared
                    List<User> userList =[SELECT Id,
                                        ContactId
                                        FROM User 
                                        WHERE ContactId IN : contactIdSet  
                                        AND Profile.Name =: NSP_ServiceConstants.CUSTOMER_COMMUNITY_PLUS AND isActive=TRUE];
                    for(User oUser : userList){
                        mapOfUserContact.put(oUser.ContactId,oUser.Id);
                    }
                    
                    for(pse__Proj__c proj : mapOfProjects.Values()){
                        Set<Id> contactSet = mapOfAccountContacts.get(proj.pse__Account__c);
                        if(!contactSet.isEmpty()){
                            for(Id contactId : contactSet){
                                if(mapOfUserContact.get(contactId) != null){
                                    pse__Proj__Share projShare = createProjectSharing ( mapOfUserContact.get(contactId), proj.Id );
                                    newProjectShareList.add(projShare);
                                }
                            }
                        }
                    }   
                }
            }
            
            
            // Inserting new  Project Shares Records
            if(!newProjectShareList.isEmpty()){
                List<Database.SaveResult> results = Database.insert(newProjectShareList,false); 
                NSP_ErrorLogHandler.logSaveResultsException(NSP_PROJECTRECORDSHARING, 'projectRecordSharing', results );
            }
            
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_PROJECTRECORDSHARING, 'projectRecordSharing', ex.getMessage());
        }
        
        
    }
     /***********************************************************************************************
    * MethodName: projectRecordSharing 
    * Description : Method to remove project records with community users
	* Params:        Set<Id> accountIdSet
	* 
* ********************************************************************************************/      
    public static void projectRemoveSharing(Set<Id> projectSharedIdSet){
        //Seacrhing for existing Project Share Records
        try{
            List<pse__Proj__Share> oldProjShareList =[SELECT Id, ParentId, 
                                                        UserorGroup.Profile.Name,
                                                        UserorGroupId 
                                                        FROM pse__Proj__Share 
                                                        WHERE ParentId IN: projectSharedIdSet AND 
                                                        Rowcause =:Schema.pse__Proj__Share.RowCause.InsperitySharing__c AND
                                                        UserorGroup.Profile.Name =: NSP_ServiceConstants.CUSTOMER_COMMUNITY_PLUS];
              
                
              // Deleting old  Project Shares Records
              if(!oldProjShareList.isEmpty()){
                List<Database.DeleteResult> results = Database.delete(oldProjShareList,false); 
                  NSP_ErrorLogHandler.logDeleteResultsException(NSP_PROJECTRECORDSHARING, 'projectRemoveSharings', results );  
              }
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_PROJECTRECORDSHARING, 'projectRemoveSharings', ex.getMessage());
        }
            
    }
    
    
    
    /***********************************************************************************************
* MethodName: createProjectSharing 
* Description : Method to retrieve community users 
* Params:       String userorGroupId , String projectId
* 
* ********************************************************************************************/    
    public static pse__Proj__Share createProjectSharing(String userorGroupId , String projectId ){
        
        pse__Proj__Share projShare = new pse__Proj__Share();
        projShare.RowCause = Schema.pse__Proj__Share.RowCause.InsperitySharing__c;
        projShare.UserOrGroupId = userorGroupId;
        projShare.AccessLevel = NSP_ServiceConstants.READ_ACCESS;
        projShare.ParentId = projectId;
        return projShare;
    }
    
}