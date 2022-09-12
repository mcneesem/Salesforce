/**
* @description  : Queueable class for Sharing Account records .
* @date 05/24/2022
* Author : Nischay Jindal
* Name : NSP_userAccountSalesOfficeSharing
*/
public class NSP_userAccountSalesOfficeSharing implements Queueable  {
    /***********************************************************************************************
    * Variables
    * ********************************************************************************************/   
    public  Map<String,Set<String>> mapnewSalesofficeSetUserId = new Map<String,Set<String>> ();
    public  Set<Id>ownerIdSet = new Set <Id>(); 
    public  Map<String,Set<String>> mapUserIdSetOldSalesOffice = new Map<String,Set<String>>();
    
    /***********************************************************************************************
    * MethodName: NSP_userAccountSalesOfficeSharing
    * Description : Class Constructor for Assigning Values to the variables 
    * Params:       Map<String,Set<String>> mapnewSalesofficeSetUserId, Map<String,Set<String>> mapUserIdSetOldSalesOffice, Set<Id>ownerIdSet 
    * 
    * ********************************************************************************************/   
    public NSP_userAccountSalesOfficeSharing(Map<String,Set<String>> mapnewSalesofficeSetUserId, Map<String,Set<String>> mapUserIdSetOldSalesOffice, Set<Id>ownerIdSet ) {  
        
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
        List<AccountShare> newSalesAccountShareList = new  List<AccountShare>();
        List<AccountShare> deleteOldAccountShareList = new  List<AccountShare>(); 
        Map<String,String> mapSalesOfficePublicGroupId = new Map<String,String> (); 
        try{
            List<AccountShare> oldAccountShareList =[Select Id, AccountId ,Account.OwnerId, UserorGroup.Name , UserorGroupId from AccountShare WHERE 
                                                     Account.OwnerId IN: this.mapUserIdSetOldSalesOffice.KeySet() AND Rowcause =:NSP_SalesConstants.manualRowCause];
            if(mapnewSalesofficeSetUserId != null){
                mapSalesOfficePublicGroupId = NSP_salesOfficeRecordSharing.mapSalesOfficePublicGroup(mapnewSalesofficeSetUserId.KeySet());
            }
            Map<Id,Account> accountMap = new Map<Id,Account>([SELECT Id, OwnerId, ToLabel(Owner.NSP_Sales_Office_Membership__c)  FROM Account
                                                              WHERE OwnerId IN:this.ownerIdSet AND Owner.NSP_Sales_Office_Membership__c != null ]); 
            
            for(Account acc : accountMap.values()){
                // creating Account Sharing
                Set<String> newAccountSalesOfficeSet = new Set<String>(new List<String>(acc.Owner.NSP_Sales_Office_Membership__c.Split(';')));  
                for(String newSalesOffice: newAccountSalesOfficeSet){
                    if(mapSalesOfficePublicGroupId != null && mapSalesOfficePublicGroupId.containsKey(newSalesOffice)){
                        AccountShare acShare = new AccountShare();
                        acshare.RowCause=NSP_SalesConstants.manualRowCause;
                        acshare.UserOrGroupId=mapSalesOfficePublicGroupId.get(newSalesOffice);
                        acshare.AccountAccessLevel=NSP_SalesConstants.editSharingAccess;
                        acShare.OpportunityAccessLevel=Label.NSP_OpportunityAccess;
                        acshare.AccountId=acc.Id;
                        newSalesAccountShareList.add(acShare);
                    }
                }
            }
            if(!newSalesAccountShareList.isEmpty()){
                Database.Insert(newSalesAccountShareList,False);
            }
            for(AccountShare oldAccountShare : oldAccountShareList){
                if(mapUserIdSetOldSalesOffice.containsKey(oldAccountShare.Account.OwnerId) && 
                   mapUserIdSetOldSalesOffice.get(oldAccountShare.Account.OwnerId).Contains(oldAccountShare.UserorGroup.Name) ){
                       deleteOldAccountShareList.add(oldAccountShare);
                   }
            } 
            if(!deleteOldAccountShareList.isEmpty()){
                delete deleteOldAccountShareList;
            }
            // updating Sharing for all the related Opportunities   
            System.enqueueJob( new NSP_userOpportunitySalesOfficeSharing( this.mapNewSalesOfficeSetUserId,this.mapUserIdSetOldSalesOffice,this.ownerIdSet ) );  
              
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_userAccountSalesOfficeSharing', 'Execute', ex.getMessage());
        } 
        
    }    
}