/**
* @description  : Queueable class for Sharing Account records .
* @date 05/24/2022
* Author : Nischay Jindal
* Name : NSP_userAccountTeamSalesOfficeSharing
*/
public class NSP_userAccountTeamSalesOfficeSharing implements Queueable  {
    /***********************************************************************************************
    * Variables
    * ********************************************************************************************/      
    public  Map<String,Set<String>> mapnewSalesofficeSetUserId = new Map<String,Set<String>> ();
    public  Set<Id>ownerIdSet = new Set <Id>(); 
    public  Map<String,Set<String>> mapUserIdSetOldSalesOffice = new Map<String,Set<String>>();
    
    /***********************************************************************************************
    * MethodName: NSP_userAccountTeamSalesOfficeSharing
    * Description : Class Constructor for Assigning Values to the variables 
    * Params:       Map<String,Set<String>> mapnewSalesofficeSetUserId, Map<String,Set<String>> mapUserIdSetOldSalesOffice, Set<Id>ownerIdSet 
    * 
    * ********************************************************************************************/       
    public NSP_userAccountTeamSalesOfficeSharing(Map<String,Set<String>> mapnewSalesofficeSetUserId, Map<String,Set<String>> mapUserIdSetOldSalesOffice, Set<Id>ownerIdSet ){
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
        Map<String,Set<String>> mapAccountIdSetAccTeamSalesOffice = new Map<String,Set<String>>();
        Map<String,Set<String>> mapAccountIdSetAccountOwnerSalesOffice = new Map<String,Set<String>>();
        List<User> updateUserList = new List<User>();
        try{
            if(mapnewSalesofficeSetUserId != null){
                mapSalesOfficePublicGroupId = NSP_salesOfficeRecordSharing.mapSalesOfficePublicGroup(mapnewSalesofficeSetUserId.KeySet());
            } 
            
            List<NSP_Account_Team__c> accountTeamList=[SELECT Id,NSP_Account__c,NSP_User__c,TOLabel(NSP_Account__r.Owner.NSP_Sales_Office_Membership__c),TOLabel(NSP_User__r.NSP_Sales_Office_Membership__c) FROM NSP_Account_Team__c 
                                                       WHERE  NSP_Role__c =:Label.NSP_AccountTeamMemberRole AND NSP_User__c IN :ownerIdSet    ];
            
            for(NSP_Account_Team__c acTeam: accountTeamList){
                // Creating Map of Account Id and Sales Offices of Account Team User Sales Office
                if( mapUserIdSetOldSalesOffice.containsKey(acTeam.NSP_User__c) ){
                    if(mapAccountIdSetAccTeamSalesOffice.get(acTeam.NSP_Account__c)==null){
                        mapAccountIdSetAccTeamSalesOffice.put(acTeam.NSP_Account__c , new Set<String>());
                    } 
                    mapAccountIdSetAccTeamSalesOffice.get(acTeam.NSP_Account__c).addAll(mapUserIdSetOldSalesOffice.get(acTeam.NSP_User__c));
                    
                }
                // Store Account Sales Office for compairing with Account Team Sales Office
                // creating a map of AccountId and set of account owner Sales office
                if(acTeam.NSP_Account__r.Owner.NSP_Sales_Office_Membership__c!=null){
                    if(mapAccountIdSetAccountOwnerSalesOffice.get(acTeam.NSP_Account__c)==null){
                        mapAccountIdSetAccountOwnerSalesOffice.put(acTeam.NSP_Account__c , new Set<String>());
                    }
                    mapAccountIdSetAccountOwnerSalesOffice.get(acTeam.NSP_Account__c).addAll(new List<String>(acTeam.NSP_Account__r.Owner.NSP_Sales_Office_Membership__c.Split(';')));
                }
                
                // create Account Sharing If Account Team Sales Office not Matches Account Sales Office
                if(acTeam.NSP_User__r.NSP_Sales_Office_Membership__c!=null){
                    for(String acTeamSalesOffice:acTeam.NSP_User__r.NSP_Sales_Office_Membership__c.Split(';') ){
                        if(!mapAccountIdSetAccountOwnerSalesOffice.get(acTeam.NSP_Account__c).contains(acTeamSalesOffice) && mapSalesOfficePublicGroupId.containsKey(acTeamSalesOffice) ){
                            AccountShare acShare = new AccountShare();
                            acshare.RowCause=NSP_SalesConstants.manualRowCause;
                            acshare.UserOrGroupId=mapSalesOfficePublicGroupId.get(acTeamSalesOffice);
                            acshare.AccountAccessLevel=NSP_SalesConstants.editSharingAccess;
                            acShare.OpportunityAccessLevel=Label.NSP_OpportunityAccess;
                            acshare.AccountId=acTeam.NSP_Account__c;
                            newSalesAccountShareList.add(acShare);                        
                        }
                    }
                }  
                
            }
            
            // fetching old Sales Office Account Share of ATM Users 
            List<AccountShare> oldAccountTeamShareList = [Select Id , AccountId , UserorGroupId, UserOrGroup.Name from AccountShare WHERE 
                                                          AccountId IN :mapAccountIdSetAccTeamSalesOffice.KeySet() AND Rowcause =:NSP_SalesConstants.manualRowCause ];
            
            // creating List of Old Sales Office Account Shares for Account Team 
            for(AccountShare acShare :oldAccountTeamShareList){
                if(mapAccountIdSetAccTeamSalesOffice.get(acShare.AccountId).Contains(acShare.UserOrGroup.Name) &&
                   !mapAccountIdSetAccountOwnerSalesOffice.get(acShare.AccountId).Contains(acShare.UserOrGroup.Name) ){
                       deleteOldAccountShareList.add(acShare);
                   }
            }
            
            // Inserting Account Shares for New Sales Office 
            if(!newSalesAccountShareList.isEmpty()){
                Database.Insert(newSalesAccountShareList,False);
            }
            
            // Deleting Account Shares for Old Sales Office 
            if(!deleteOldAccountShareList.isEmpty()){
                delete deleteOldAccountShareList;
            }
            //updating Users after Processing Complete
            if(mapUserIdSetOldSalesOffice!=null){
                for(Id userId:mapUserIdSetOldSalesOffice.KeySet()){
                    User usr = new User();
                    usr.Id=userId;
                    usr.NSP_Office_Processing__c= NSP_SalesConstants.officeProcessing;
                    updateUserList.add(usr);
                }
                if(!updateUserList.isEmpty()){
                    update updateUserList;
                }
            }  
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_userAccountTeamSalesOfficeSharing', 'Execute', ex.getMessage());
        }   
    }
}