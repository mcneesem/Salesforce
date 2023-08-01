/**
* @description  :  Helper class for Milestone Sharing trigger.
* @date 12/02/2022
* Author : Nischay Jindal
* Name : NSP_MilestoneTaskSharing
*/
public class NSP_MilestoneTaskSharing {

/***********************************************************************************************
* MethodName: mileStoneRecordSharing 
* Description : Method for sharing records With Community Users
* Params:       Map<Id,pse__Milestone__c> newMileMap, Map<Id,pse__Milestone__c> oldMileMap
* 
* ********************************************************************************************/      
    public static void mileStoneRecordSharing(Set<Id> newMilestoneIdSet, Set<Id> oldMilestoneIdSet){
        Set<Id> contactIdSet = new Set<Id> ();
        Map<Id,Set<Id>> mapOfAccountContacts=new Map<Id,Set<Id>>();//accountidsetofContactidmap
        Map<Id,Id> mapOfUserContact=new Map<Id,Id>();//contactiduseridmap
        Map<Id,List<pse__Milestone__c>> mapAccountIdSetMilestone = new Map<Id,List<pse__Milestone__c>>();
        List<pse__Milestone__Share> milestoneShareList = new  List<pse__Milestone__Share> ();
        try{
            
            if(newMilestoneIdSet!=null && !newMilestoneIdSet.isEmpty()){
                Map<Id,pse__Milestone__c> mileStoneMap = new Map<Id,pse__Milestone__c>([SELECT Id , pse__Project__c , pse__Project__r.pse__Account__c, NSP_Visible_to_Client__c FROM pse__Milestone__c WHERE 
                                                                                                Id IN:newMilestoneIdSet AND  pse__Project__r.pse__Account__c !=NUll AND 
                                                                                                NSP_Visible_to_Client__c = True AND pse__Project__c != Null   ]);  
                
                for(pse__Milestone__c mile : mileStoneMap.Values()){
                    if(!mapAccountIdSetMilestone.containsKey(mile.pse__Project__r.pse__Account__c)){
                        mapAccountIdSetMilestone.put(mile.pse__Project__r.pse__Account__c, new List<pse__Milestone__c>());
                    }
                    mapAccountIdSetMilestone.get(mile.pse__Project__r.pse__Account__c).add(mile);
                } 
            
            
                if(!mapAccountIdSetMilestone.KeySet().isEmpty()){
                    //fetch all the acr associated to the project account
                    
                    for(AccountContactRelation acr : [SELECT ContactId,AccountId FROM AccountContactRelation 
                                                            WHERE AccountId in : mapAccountIdSetMilestone.keySet() 
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
                        for(pse__Milestone__c mile : mileStoneMap.Values()){
                            if(mapOfAccountContacts.containskey(mile.pse__Project__r.pse__Account__c)){
                                for(Id contactId : mapOfAccountContacts.get(mile.pse__Project__r.pse__Account__c)){
                                    if(mapOfUserContact.get(contactId) != null){
                                        pse__Milestone__Share mileShare = createMileStoneSharing ( mapOfUserContact.get(contactId), mile.Id );
                                        milestoneShareList.add(mileShare);
                                    }
                                }  
                            } 
                        }   
                    }
                    
                }  
            }
            if(!milestoneShareList.isEmpty()){
                Database.insert(milestoneShareList,false);
            }
            //Seacrhing for existing Project Share Records
            if(oldMilestoneIdSet!=null && !oldMilestoneIdSet.isEmpty()){
                List<pse__Milestone__Share> oldMileShareList = getMilestoneShareList(oldMilestoneIdSet);
            // Inserting new  Project Shares Records
           
            // Deleting old  Project Shares Records
                if(!oldMileShareList.isEmpty()){
                    Database.delete(oldMileShareList,false);   
                }
            }
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_ProjectTaskSharing', 'projectTaskRecordSharing', ex.getMessage());
        }
    }
    
    
    
    /***********************************************************************************************
    * MethodName: createProjectTaskSharing 
    * Description : Method to retrieve community users 
    * Params:       String userorGroupId , String milestoneId
    * 
    * ********************************************************************************************/    
    public static pse__Milestone__Share createMileStoneSharing(String userorGroupId , String milestoneId ){
        
        pse__Milestone__Share mileShare = new pse__Milestone__Share();
        mileShare.RowCause = Schema.pse__Milestone__Share.RowCause.InsperitySharing__c;
        mileShare.UserOrGroupId = userorGroupId;
        mileShare.AccessLevel = NSP_ServiceConstants.READ_ACCESS;
        mileShare.ParentId = milestoneId;
        return mileShare;
    }
    
    /***********************************************************************************************
    * MethodName: createProjectTaskSharing 
    * Description : Method to retrieve community users 
    * Params:       String userorGroupId , String projectTaskId
    * 
    * ********************************************************************************************/    
    public static List<pse__Milestone__Share> getMilestoneShareList(Set<Id> oldMilestoneIdSet ){
       List<pse__Milestone__Share> milestoneShareList =[SELECT Id, ParentId, 
                                                              UserorGroup.Profile.Name,
                                                              UserorGroupId 
                                                              FROM pse__Milestone__Share 
                                                              WHERE ParentId IN: oldMilestoneIdSet AND 
                                                              Rowcause =:Schema.pse__Milestone__Share.RowCause.InsperitySharing__c AND
                                                              UserorGroup.Profile.Name =: NSP_ServiceConstants.CUSTOMER_COMMUNITY_PLUS];
     return milestoneShareList;        
    }   
}