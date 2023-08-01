/**
* @description  :  Queuable class to share records for community users
* @date 11/11/2022
* Author : Nischay Jindal
* Name : NSP_portalUserSharing
*/

public  class NSP_portalUserSharing implements Queueable{
    //varibales declaration
    private Map<Id,Id> mapContactIdUserId;
    	//constructor
    public NSP_portalUserSharing( Map<Id,Id> mapContactIdUserId) {
        this.mapContactIdUserId = mapContactIdUserId;
    }

     /***********************************************************************************************
    * MethodName: execute
    * Description : This Method shares and create a list of eligible projects
    * Params:       Map<Id,Id> mapContactIdUserId
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    public void execute(QueueableContext context) {
    
   
        Map<Id,Set<Id>> mapAccountIdSetContactId = new Map<Id,Set<Id>>();
        List<pse__proj__share> projectShareList = new List<pse__proj__share> ();
        List<pse__Project_Task__share > projectTaskShareList = new  List<pse__Project_Task__share >();
        List<pse__Milestone__share > projectMilestoneShareList = new  List<pse__Milestone__share >();
        for(AccountContactRelation acr: [SELECT Id ,AccountId ,ContactId,NSP_Community_Access__c FROM AccountContactRelation WHERE ContactId IN:mapContactIdUserId.keySet() AND NSP_Community_Access__c includes ('PEO Projects') ]){
            if(!mapAccountIdSetContactId.containsKey(acr.accountId)){
                mapAccountIdSetContactId.put(acr.accountId, new Set<Id>());
            }
            mapAccountIdSetContactId.get(acr.accountId).add(acr.ContactId);
        }
        projectShareList = generateProjectShareList(mapContactIdUserId , mapAccountIdSetContactId );
        if(!projectShareList.isEmpty()){
            // inserting List of Project Shares 
            insert projectShareList;
            //  fething list of Milestone Shares 
            projectMilestoneShareList = generateMilestoneShareList(mapContactIdUserId , mapAccountIdSetContactId );
            if(!projectMilestoneShareList.isEmpty()){
                 // inserting list of Milsetone Shares
                insert projectMilestoneShareList;
            }
                //  fething list of Project Task Shares 
            projectTaskShareList = generateProjectTaskShareList(mapContactIdUserId , mapAccountIdSetContactId );
            if(!projectTaskShareList.isEmpty()){
                    // inserting list of Project Task Shares
                    insert projectTaskShareList; 
            }
        
            
        }
        
    }
    
    /***********************************************************************************************
    * MethodName: generateProjectShareList
    * Description : Internal method for record Share
    * Params:       Map<Id,Id> mapContactIdUserId , Map<Id,Set<Id>> mapAccountIdSetContactId
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    private static  List<pse__proj__share>  generateProjectShareList(Map<Id,Id> mapContactIdUserId , Map<Id,Set<Id>> mapAccountIdSetContactId){
        List<pse__proj__share> projectShareList = new  List<pse__proj__share>();
        for(pse__Proj__c project : [SELECT Id , pse__Account__c , NSP_Visible_to_Client__c FROM pse__Proj__c 
                                    WHERE pse__Account__c IN : mapAccountIdSetContactId.keySet() AND NSP_Visible_to_Client__c = True]){
                                        if(mapAccountIdSetContactId.containsKey(project.pse__Account__c) && 
                                           !mapAccountIdSetContactId.get(project.pse__Account__c).isEmpty() ){
                                               //map<id, set<conid> >Accountma
                                               for(Id contactId:mapAccountIdSetContactId.get(project.pse__Account__c)){
                                                   if(mapContactIdUserId.containsKey(contactId)){
                                                       pse__proj__share prShare = createProjectShare(project.Id, mapContactIdUserId.get(contactId));
                                                       projectShareList.add(prShare);
                                                   }
                                               }
                                               
                                           }
                                    }
        return projectShareList;
    }
    
    /***********************************************************************************************
    * MethodName: createProjectShare
    * Description : create instanse of Project share
    * Params:       Id projectId , Id userId
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    private static pse__proj__share createProjectShare(Id projectId , Id userId){
        pse__proj__share prjShare = new pse__proj__share();
        prjShare.RowCause =Schema.pse__Proj__Share.RowCause.InsperitySharing__c;
        prjShare.UserOrGroupId = userId;
        prjShare.AccessLevel  = NSP_ServiceConstants.readAccess;
        prjShare.ParentId = projectId;
        return prjShare;
    }
    
    /***********************************************************************************************
    * MethodName: generateProjectTaskShareList
    * Description : Internal method for record Share
    * Params:       Map<Id,Id> mapContactIdUserId , Map<Id,Set<Id>> mapAccountIdSetContactId
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    private static  List<pse__Project_Task__share >  generateProjectTaskShareList(Map<Id,Id> mapContactIdUserId , Map<Id,Set<Id>> mapAccountIdSetContactId){
        List<pse__Project_Task__share > projectTaskShareList = new  List<pse__Project_Task__share >();
        for(pse__Project_Task__c projectTask : [SELECT Id , pse__Project__c , pse__Project__r.pse__Account__c, NSP_Visible_to_Client__c FROM pse__Project_Task__c WHERE 
                                                pse__Project__r.pse__Account__c IN : mapAccountIdSetContactId.keySet() AND NSP_Visible_to_Client__c = True AND pse__Project__c !=null ]){
                                                    
                                                    if(mapAccountIdSetContactId.containsKey(projectTask.pse__Project__r.pse__Account__c) && 
                                                       !mapAccountIdSetContactId.get(projectTask.pse__Project__r.pse__Account__c).isEmpty() ){
                                                           for(Id contactId:mapAccountIdSetContactId.get(projectTask.pse__Project__r.pse__Account__c)){
                                                               if(mapContactIdUserId.containsKey(contactId)){
                                                                   pse__Project_Task__share prShare = createProjectTaskShare(projectTask.Id, mapContactIdUserId.get(contactId));
                                                                   projectTaskShareList.add(prShare);
                                                               }
                                                           }
                                                           
                                                       }
                                                }
        return projectTaskShareList;
    }
    
    /***********************************************************************************************
    * MethodName: createProjectTaskShare
    * Description : create instanse of Project TASK share
    * Params:       Id projectTaskId , Id userId
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    private static pse__Project_Task__share createProjectTaskShare(Id projectTaskId , Id userId){
        pse__Project_Task__share prjTskShare = new pse__Project_Task__share();
        prjTskShare.RowCause =Schema.pse__Project_Task__share.RowCause.InsperitySharing__c;
        prjTskShare.UserOrGroupId = userId;
        prjTskShare.AccessLevel  = NSP_ServiceConstants.readAccess;
        prjTskShare.ParentId = projectTaskId;
        return prjTskShare;
    } 
    
    /***********************************************************************************************
    * MethodName: generateMilestoneShareList
    * Description : Internal method for record Share
    * Params:       Map<Id,Id> mapContactIdUserId , Map<Id,Set<Id>> mapAccountIdSetContactId
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    private static  List<pse__Milestone__share >  generateMilestoneShareList(Map<Id,Id> mapContactIdUserId , Map<Id,Set<Id>> mapAccountIdSetContactId){
        List<pse__Milestone__share > projectMilestoneShareList = new  List<pse__Milestone__share >();
        for(pse__Milestone__c milestone : [SELECT Id , pse__Project__c , pse__Project__r.pse__Account__c, NSP_Visible_to_Client__c FROM pse__Milestone__c WHERE 
                                           pse__Project__r.pse__Account__c IN : mapAccountIdSetContactId.keySet() AND NSP_Visible_to_Client__c = True AND pse__Project__c !=null ]){
                                               
                                               if(mapAccountIdSetContactId.containsKey(milestone.pse__Project__r.pse__Account__c) && 
                                                  !mapAccountIdSetContactId.get(milestone.pse__Project__r.pse__Account__c).isEmpty() ){
                                                      for(Id contactId:mapAccountIdSetContactId.get(milestone.pse__Project__r.pse__Account__c)){
                                                          if(mapContactIdUserId.containsKey(contactId)){
                                                              pse__Milestone__share mlShare = createMilestoneShare(milestone.Id, mapContactIdUserId.get(contactId));
                                                              projectMilestoneShareList.add(mlShare);
                                                          }
                                                      }
                                                      
                                                  }
                                           }
        return projectMilestoneShareList;
    }
    
    /***********************************************************************************************
    * MethodName: createMilestoneShare
    * Description : create instanse of Milestone share
    * Params:       Id Milestone , Id userId
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    private static pse__Milestone__share createMilestoneShare(Id Milestone , Id userId){
        pse__Milestone__share mileShare = new pse__Milestone__share();
        mileShare.RowCause =Schema.pse__Milestone__share.RowCause.InsperitySharing__c;
        mileShare.UserOrGroupId = userId;
        mileShare.AccessLevel  = NSP_ServiceConstants.readAccess;
        mileShare.ParentId = Milestone;
        return mileShare;
    } 
}