/**
* @description  : Queueable class for Sharing Lead records .
* @date 05/25/2022
* Author : Nischay Jindal
* Name : NSP_userLeadSalesOfficeSharing
*/
public class NSP_userLeadSalesOfficeSharing  implements Queueable {
    /***********************************************************************************************
    * Variables
    * ********************************************************************************************/    
    public  Map<String,Set<String>> mapnewSalesofficeSetUserId = new Map<String,Set<String>> ();
    public  Set<Id>ownerIdSet = new Set <Id>(); 
    public  Map<String,Set<String>> mapUserIdSetOldSalesOffice = new Map<String,Set<String>>();
    
    /***********************************************************************************************
    * MethodName: NSP_userLeadSalesOfficeSharing
    * Description : Class Constructor for Assigning Values to the variables 
    * Params:       Map<String,Set<String>> mapnewSalesofficeSetUserId, Map<String,Set<String>> mapUserIdSetOldSalesOffice, Set<Id>ownerIdSet 
    * 
    * ********************************************************************************************/       
    public NSP_userLeadSalesOfficeSharing(Map<String,Set<String>> mapnewSalesofficeSetUserId, Map<String,Set<String>> mapUserIdSetOldSalesOffice, Set<Id>ownerIdSet ) {  
        this.mapnewSalesofficeSetUserId = mapnewSalesofficeSetUserId;  
        this.ownerIdSet = ownerIdSet;  
        this.mapUserIdSetOldSalesOffice = mapUserIdSetOldSalesOffice;
    }  
    /***********************************************************************************************
    * MethodName: Queueable Execute Method
    * Description : Execute method that will allow the Account record Sharing 
    * 
    * ********************************************************************************************/     
    public void execute(QueueableContext qc) { 
        List<LeadShare> newSalesLeadShareList = new  List<LeadShare>();
        List<LeadShare> deleteOldLeadShareList = new  List<LeadShare>();
        Map<String,String> mapSalesOfficePublicGroupId = new Map<String,String> (); 
        try{
          List<LeadShare> oldLeadShareList =[Select Id, LeadId ,Lead.OwnerId, UserorGroup.Name , UserorGroupId from LeadShare WHERE 
                                           Lead.OwnerId IN: this.mapUserIdSetOldSalesOffice.KeySet() AND Rowcause =:NSP_SalesConstants.manualRowCause];
        
        if(mapnewSalesofficeSetUserId != null){
            mapSalesOfficePublicGroupId = NSP_salesOfficeRecordSharing.mapSalesOfficePublicGroup(mapnewSalesofficeSetUserId.KeySet());
        }
        Map<Id,User> leadOwnerMap = new Map<Id,User>([SELECT Id,ToLabel(NSP_Sales_Office_Membership__c) FROM User WHERE Id IN:this.ownerIdSet AND NSP_Sales_Office_Membership__c != null ]);
        
        Map<Id,Lead> LeadMap = new Map<Id,Lead>([SELECT Id, OwnerId FROM Lead WHERE OwnerId IN:this.ownerIdSet ]); 
        for(Lead lead : LeadMap.values()){
            if(leadOwnerMap.containsKey(lead.OwnerId) && leadOwnerMap.get(lead.OwnerId).NSP_Sales_Office_Membership__c != null){
                // creating Lead Sharing
                Set<String> newLeadSalesOfficeSet = new Set<String>(new List<String>(leadOwnerMap.get(lead.OwnerId).NSP_Sales_Office_Membership__c.Split(';')));  
                for(String newSalesOffice: newLeadSalesOfficeSet){
                    if(mapSalesOfficePublicGroupId != null && mapSalesOfficePublicGroupId.containsKey(newSalesOffice)){
                        LeadShare ldshare = new LeadShare();
                        ldshare.RowCause = NSP_SalesConstants.manualRowCause;
                        ldshare.UserOrGroupId = mapSalesOfficePublicGroupId.get(newSalesOffice);
                        ldshare.LeadAccessLevel = NSP_SalesConstants.editSharingAccess;
                        ldshare.LeadId = lead.Id;
                        newSalesLeadShareList.add(ldshare);
                    }
                } 
            }   
        }
        if(!newSalesLeadShareList.isEmpty()){
            Database.Insert(newSalesLeadShareList,False);
        }
        for(LeadShare oldLeadShare : oldLeadShareList){
            if(mapUserIdSetOldSalesOffice.containsKey(oldLeadShare.Lead.OwnerId) && 
               mapUserIdSetOldSalesOffice.get(oldLeadShare.Lead.OwnerId).Contains(oldLeadShare.UserorGroup.Name) ){
                   deleteOldLeadShareList.add(oldLeadShare);
               }
        }
        
        if(!deleteOldLeadShareList.isEmpty()){
            delete deleteOldLeadShareList;
        }
        // updating Sharing for all the related Account Team Members 
        System.enqueueJob( new NSP_userAccountTeamSalesOfficeSharing( this.mapNewSalesOfficeSetUserId,this.mapUserIdSetOldSalesOffice,this.ownerIdSet ) );  
          
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_userLeadSalesOfficeSharing', 'Execute', ex.getMessage());
        } 
        
    }
}