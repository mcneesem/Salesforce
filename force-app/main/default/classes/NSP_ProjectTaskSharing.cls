/**
* @description  :  Helper class for Project Task Sharing trigger.
* @date 12/02/2022
* Author : Nischay Jindal
* Name : NSP_ProjectTaskSharing
*/
public class NSP_ProjectTaskSharing {
    
    /***********************************************************************************************
    * MethodName: projectTaskRecordSharing 
    * Description : Method for sharing records With Community Users
    * Params:       Map<Id,pse__Project_Task__c> newPrjTaskMap, Map<Id,pse__Project_Task__c> oldPrjTaskMap
    * 
    * ********************************************************************************************/      
    public static void projectTaskRecordSharing(Set<Id> newProjectTaskIdSet, Set<Id> oldProjectTaskIdSet){
        Set<Id> contactIdSet = new Set<Id> ();
        Map<Id,Set<Id>> mapOfAccountContacts=new Map<Id,Set<Id>>();//accountidsetofContactidmap
        Map<Id,Id> mapOfUserContact=new Map<Id,Id>();//contactiduseridmap
        Map<Id,List<pse__Project_Task__c>> mapAccountIdSetPrjTaskId = new Map<Id,List<pse__Project_Task__c>>();
        List<pse__Project_Task__share> prjTaskList = new  List<pse__Project_Task__share> ();
        try{
           
            if(newProjectTaskIdSet!=null && !newProjectTaskIdSet.isEmpty()){
                Map<Id,pse__Project_Task__c> projTaskMap = new Map<Id,pse__Project_Task__c>([SELECT Id , pse__Project__c , pse__Project__r.pse__Account__c, NSP_Visible_to_Client__c FROM pse__Project_Task__c WHERE 
                                                                                                Id IN:newProjectTaskIdSet AND  pse__Project__r.pse__Account__c !=NUll AND 
                                                                                                NSP_Visible_to_Client__c = True AND pse__Project__c != Null   ]);  
                if(projTaskMap.size()>0){
                    for(pse__Project_Task__c proj : projTaskMap.Values()){
                        if(!mapAccountIdSetPrjTaskId.containsKey(proj.pse__Project__r.pse__Account__c)){
                            mapAccountIdSetPrjTaskId.put(proj.pse__Project__r.pse__Account__c, new List<pse__Project_Task__c>());
                        }
                        mapAccountIdSetPrjTaskId.get(proj.pse__Project__r.pse__Account__c).add(proj);
                    } 
                    
                    
                    if(!mapAccountIdSetPrjTaskId.KeySet().isEmpty()){
                        //fetch all the acr associated to the project account
                        
                        for(AccountContactRelation acr : [SELECT ContactId,AccountId FROM AccountContactRelation 
                                                                WHERE AccountId in : mapAccountIdSetPrjTaskId.keySet() 
                                                                AND NSP_Community_Access__c INCLUDES (: NSP_ServiceConstants.peoCommunityAccess)]){
                            //get all contacts of acr where community access is peo projects
                            contactIdSet.add(acr.ContactId);
                            if(mapOfAccountContacts.get(acr.AccountId)==null){
                                mapOfAccountContacts.put(acr.AccountId,new Set<Id>());
                            }
                            mapOfAccountContacts.get(acr.AccountId).add(acr.ContactId);
                        }
                        
                        
                        if(!contactIdSet.isEmpty()){
                            //get all community users to whom project record need to be shared
                            for(User oUser : [SELECT Id,ContactId FROM User WHERE ContactId IN : contactIdSet  
                                            AND Profile.Name =: NSP_ServiceConstants.CUSTOMER_COMMUNITY_PLUS AND isActive=TRUE] ){
                                mapOfUserContact.put(oUser.ContactId,oUser.Id);
                            }      
                            for(pse__Project_Task__c proj : projTaskMap.values()){
                                if(mapOfAccountContacts.containskey(proj.pse__Project__r.pse__Account__c)){
                                    for(Id contactId : mapOfAccountContacts.get(proj.pse__Project__r.pse__Account__c)){
                                        if(mapOfUserContact.get(contactId) != null){
                                            pse__Project_Task__share projShare = createProjectTaskSharing ( mapOfUserContact.get(contactId), proj.Id );
                                            prjTaskList.add(projShare);
                                        }
                                    }  
                                } 
                            }   
                        }
                    }
                } 
            }           
            
            if(!prjTaskList.isEmpty()){
                Database.insert(prjTaskList,false);
            }
             //Seacrhing for existing Project Share Records
            if(oldProjectTaskIdSet!=null && !oldProjectTaskIdSet.isEmpty()){
           
                List<pse__Project_Task__share> oldProjShareList = getProjectTaskShareList(oldProjectTaskIdSet);    
                // Inserting new  Project Shares Records
                // Deleting old  Project Shares Records
                if(!oldProjShareList.isEmpty()){
                    Database.delete(oldProjShareList,false);   
                }
            }
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_ProjectTaskSharing', 'projectTaskRecordSharing', ex.getMessage());
        }
    }
    
    
    
    /***********************************************************************************************
    * MethodName: createProjectTaskSharing 
    * Description : Method to retrieve community users 
    * Params:       String userorGroupId , String projectTaskId
    * 
    * ********************************************************************************************/    
    public static pse__Project_Task__share createProjectTaskSharing(String userorGroupId , String projectTaskId ){
        
        pse__Project_Task__share projShare = new pse__Project_Task__share();
        projShare.RowCause = Schema.pse__Project_Task__share.RowCause.InsperitySharing__c;
        projShare.UserOrGroupId = userorGroupId;
        projShare.AccessLevel = NSP_ServiceConstants.READ_ACCESS;
        projShare.ParentId = projectTaskId;
        return projShare;
    }
    
    /***********************************************************************************************
    * MethodName: createProjectTaskSharing 
    * Description : Method to retrieve community users 
    * Params:       String userorGroupId , String projectTaskId
    * 
    * ********************************************************************************************/    
    public static List<pse__Project_Task__share> getProjectTaskShareList(Set<Id> projectTaskIdSet ){
       List<pse__Project_Task__share> prjTaskShareList =[SELECT Id, ParentId, 
                                                              UserorGroup.Profile.Name,
                                                              UserorGroupId 
                                                              FROM pse__Project_Task__share 
                                                              WHERE ParentId IN: projectTaskIdSet AND 
                                                              Rowcause =:Schema.pse__Project_Task__share.RowCause.InsperitySharing__c AND
                                                              UserorGroup.Profile.Name =: NSP_ServiceConstants.CUSTOMER_COMMUNITY_PLUS];
     return prjTaskShareList;        
    }   
}