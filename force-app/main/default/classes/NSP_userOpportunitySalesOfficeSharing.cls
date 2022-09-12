/**
* @description  : Queueable class for Sharing Opportunity  records .
* @date 05/25/2022
* Author : Nischay Jindal
* Name : NSP_userOpportunitySalesOfficeSharing
*/
public class NSP_userOpportunitySalesOfficeSharing implements Queueable {
    /***********************************************************************************************
    * Variables
    * ********************************************************************************************/
    public  Map<String,Set<String>> mapnewSalesofficeSetUserId = new Map<String,Set<String>> ();
    public  Set<Id>ownerIdSet = new Set <Id>(); 
    public  Map<String,Set<String>> mapUserIdSetOldSalesOffice = new Map<String,Set<String>>();
    
    /***********************************************************************************************
    * MethodName: NSP_userOpportunitySalesOfficeSharing
    * Description : Class Constructor for Assigning Values to the variables 
    * Params:       Map<String,Set<String>> mapnewSalesofficeSetUserId, Map<String,Set<String>> mapUserIdSetOldSalesOffice, Set<Id>ownerIdSet 
    * 
    * ********************************************************************************************/       
    public NSP_userOpportunitySalesOfficeSharing(Map<String,Set<String>> mapnewSalesofficeSetUserId, Map<String,Set<String>> mapUserIdSetOldSalesOffice, Set<Id>ownerIdSet) {  
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
        List<OpportunityShare> newSalesOpportunityShareList = new  List<OpportunityShare>();
        List<OpportunityShare> deleteOldOpportunityShareList = new  List<OpportunityShare>();
        Map<String,String> mapSalesOfficePublicGroupId = new Map<String,String> (); 
        try{
            List<OpportunityShare> oldOpportunityShareList =[Select Id, OpportunityId ,Opportunity.OwnerId, UserorGroup.Name , UserorGroupId from OpportunityShare WHERE 
                                                             Opportunity.OwnerId IN: this.mapUserIdSetOldSalesOffice.KeySet() AND Rowcause =:NSP_SalesConstants.manualRowCause];
            if(mapnewSalesofficeSetUserId != null){
                mapSalesOfficePublicGroupId = NSP_salesOfficeRecordSharing.mapSalesOfficePublicGroup(mapnewSalesofficeSetUserId.KeySet());
            }
            Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>([SELECT Id, OwnerId, ToLabel(Owner.NSP_Sales_Office_Membership__c)  FROM Opportunity
                                                                          WHERE OwnerId IN:this.ownerIdSet AND Owner.NSP_Sales_Office_Membership__c != null  
                                                                          AND (StageName !=: NSP_SalesConstants.CLOSED_WON OR StageName !=: NSP_SalesConstants.CLOSED_LOST)  ]); 
            
            for(Opportunity opp : opportunityMap.values()){
                // creating Opportunity Sharing
                Set<String> newOpportunitySalesOfficeSet = new Set<String>(new List<String>(opp.Owner.NSP_Sales_Office_Membership__c.Split(';')));  
                for(String newSalesOffice: newOpportunitySalesOfficeSet){
                    if(mapSalesOfficePublicGroupId != null && mapSalesOfficePublicGroupId.containsKey(newSalesOffice)){
                        OpportunityShare opshare = new OpportunityShare();
                        opShare.RowCause = NSP_SalesConstants.manualRowCause;
                        opShare.UserOrGroupId = mapSalesOfficePublicGroupId.get(newSalesOffice);
                        opShare.OpportunityAccessLevel = NSP_SalesConstants.editSharingAccess;
                        opShare.OpportunityId = opp.Id;
                        newSalesOpportunityShareList.add(opShare);
                    }
                }     
            }
            if(!newSalesOpportunityShareList.isEmpty()){
                Database.Insert(newSalesOpportunityShareList,False);
            }
            for(OpportunityShare oldOpportunityShare : oldOpportunityShareList){
                if(mapUserIdSetOldSalesOffice.containsKey(oldOpportunityShare.Opportunity.OwnerId) && 
                   mapUserIdSetOldSalesOffice.get(oldOpportunityShare.Opportunity.OwnerId).Contains(oldOpportunityShare.UserorGroup.Name) ){
                       deleteOldOpportunityShareList.add(oldOpportunityShare);
                   }
            }
            
            if(!deleteOldOpportunityShareList.isEmpty()){
                delete deleteOldOpportunityShareList;
            }
            // updating Sharing for all the related Leads 
            System.enqueueJob( new NSP_userLeadSalesOfficeSharing( this.mapNewSalesOfficeSetUserId,this.mapUserIdSetOldSalesOffice,this.ownerIdSet) );  
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_userOpportunitySalesOfficeSharing', 'Execute', ex.getMessage());
        }  
    }
    
}