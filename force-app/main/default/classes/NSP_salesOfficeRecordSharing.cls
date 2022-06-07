/**
* @description  :  class for set up manual sharing rules.
* @date 05/23/2022
* Author : Nischay Jindal
* Name : NSP_salesOfficeRecordSharing
*/
public class NSP_salesOfficeRecordSharing {
    
    /***********************************************************************************************
    * MethodName: accountRecordSharing 
    * Description : Method for sharing records With BPA Sales Offices
    * Params:       Map<Id,Account> newAccountMap
    * 
    * ********************************************************************************************/      
    public static void accountRecordSharing(Map<Id,Account> newAccountMap){
        Map<String,Set<String>> mapSalesOfficeSetAccountId = new  Map<String,Set<String>>();
        List<AccountShare> accountShareList = new List<AccountShare>();
        try{
            Map<Id,Account> accountMap = new Map<Id,Account>([SELECT Id,TOLabel(Owner.NSP_Sales_Office_Membership__c) FROM Account WHERE Id IN:newAccountMap.keySet() AND
                                                              Owner.UserRole.Name =:NSP_SalesConstants.BPARole AND Owner.NSP_Sales_Office_Membership__c != null]);
            
            for(Account acc: accountMap.Values()){
                List<String> userSalesOfficeList= acc.Owner.NSP_Sales_Office_Membership__c.split(';');
                for(String userSalesOffice:userSalesOfficeList){
                    // creating map of Sales office and Set of Account Id
                    if(mapSalesOfficeSetAccountId.get(userSalesOffice)==null){
                        mapSalesOfficeSetAccountId.put(userSalesOffice,new Set<String>());
                    } 
                    mapSalesOfficeSetAccountId.get(userSalesOffice).add(acc.Id);
                }
            } 
            // creating map of Sales Office Group name and Group Id
            Map<String,String> salesOfficeGroupMap = mapSalesOfficePublicGroup(mapSalesOfficeSetAccountId.KeySet());
            
            // Sharing Account Records with Sales Office Public Group
            for(String salesOffice:mapSalesOfficeSetAccountId.keySet() ){
                for(String accountId:mapSalesOfficeSetAccountId.get(salesOffice)){
                    if(salesOfficeGroupMap.containsKey(salesOffice)){
                        AccountShare accShare= createAccountSharing(salesOfficeGroupMap.get(salesOffice),accountId);
                        accountShareList.add(accShare);
                    }
                }
            }
            // Inserting Account Shares Records
            if(!accountShareList.isEmpty()){
                Database.insert(accountShareList,false);   
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_salesOfficerecordSharing', 'accountRecordSharing', ex.getMessage());
        } 
    }
    
    /***********************************************************************************************
    * MethodName: shareAccountonUpdate
    * Description : update Sharing access for Non-BPA members of Account on Account Owner Change
    * Params:       Map<Id,Account> newAccountMap, Map<Id,Account>oldAccountMap
    * ********************************************************************************************/
  	public static void shareAccountonUpdate(Map < Id, Account > newAccountMap, Map < Id,Account > oldAccountMap) {
        Map<String,Set<String>> mapAccountIdSetOldSalesOffice = new  Map<String,Set<String>>();
        Map<String,Set<String>> mapSalesOfficeSetAccountId = new  Map<String,Set<String>>();
        List<AccountShare> newAccountShareList = new List<AccountShare>();
        List<AccountShare> deleteAccountShareList = new List<AccountShare>();
        Set<Id> oldAccountOwnerIdSet = new Set<Id>();
        try{
            for(Account acc :newAccountMap.Values() ){
                if(acc.OwnerId != oldAccountMap.get(acc.Id).OwnerId){
                    oldAccountOwnerIdSet.add(oldAccountMap.get(acc.Id).OwnerId);
                }
            }
            Map<Id,User> oldAccOwnerMap = new Map<Id,User>([SELECT Id,UserRole.Name,TOLabel(NSP_Sales_Office_Membership__c) FROM USER WHERE Id IN:oldAccountOwnerIdSet AND
                                                            UserRole.Name =:NSP_SalesConstants.BPARole]);
            Map<Id,Account> newAccMap = new Map<Id,Account>([SELECT Id,Owner.UserRole.Name,TOLabel(Owner.NSP_Sales_Office_Membership__c),OwnerId FROM Account WHERE Id IN:newAccountMap.keySet()  ]);
            
            for(Account acc : newAccMap.values()){
                Set<String> oldAccSalesOfficeList = new Set<String>();
                Set<String> newAccSalesOfficeList = new Set<String>();
                // Store new Acc Owner Sales Office in the List
                if(newAccMap.get(acc.Id).Owner.NSP_Sales_Office_Membership__c!=null && newAccMap.get(acc.Id).Owner.UserRole.Name ==NSP_SalesConstants.BPARole ){
                    newAccSalesOfficeList.addAll(new List<String>(newAccMap.get(acc.Id).Owner.NSP_Sales_Office_Membership__c.Split(';')));
                }
                // Store old Acc Owner Sales Office in the List
                if(oldAccOwnerMap.containsKey(oldAccountMap.get(acc.Id).OwnerId) && oldAccOwnerMap.get(oldAccountMap.get(acc.Id).OwnerId).NSP_Sales_Office_Membership__c!=null){
                    oldAccSalesOfficeList.addAll(new List<String>(oldAccOwnerMap.get(oldAccountMap.get(acc.Id).OwnerId).NSP_Sales_Office_Membership__c.Split(';')));
                }
                if(!newAccSalesOfficeList.isEmpty()){
                    for(String newSalesOffice:newAccSalesOfficeList){
                        // creating a Map of Sales Office and Set of Account Id
                        if(mapSalesOfficeSetAccountId.get(newSalesOffice)==null){
                            mapSalesOfficeSetAccountId.put(newSalesOffice , new Set<String>());
                        }
                        mapSalesOfficeSetAccountId.get(newSalesOffice).add(acc.Id);
                        // removing exiting sales office from list of old sales Offices  
                        if(!oldAccSalesOfficeList.isEmpty() && oldAccSalesOfficeList.contains(newSalesOffice) ){
                            oldAccSalesOfficeList.remove(newSalesOffice);
                        }
                    }
                }
                // creating a map of  Opp Id and set of Old Sales office
                if(!oldAccSalesOfficeList.isEmpty()){
                    if(mapAccountIdSetOldSalesOffice.get(acc.Id)==null){
                        mapAccountIdSetOldSalesOffice.put(acc.Id, new Set<String>());
                    } 
                    mapAccountIdSetOldSalesOffice.get(acc.Id).addAll(oldAccSalesOfficeList);
                }
            } 
            // creating map of Sales Office Group name and Group Id
            Map<String,String> salesOfficeGroupMap = mapSalesOfficePublicGroup(mapSalesOfficeSetAccountId.KeySet());
            //Seacrhing for existing Account Share Records 
            if(mapAccountIdSetOldSalesOffice!=null){
                List<AccountShare> oldAccShareList =[Select Id, AccountId , UserorGroup.Name  from AccountShare WHERE 
                                                     AccountId IN: mapAccountIdSetOldSalesOffice.KeySet() AND Rowcause =:NSP_SalesConstants.manualRowCause];
                // creating a List of Account Share List Needs to be deleted 
                for(AccountShare acShare:oldAccShareList){
                    if(mapAccountIdSetOldSalesOffice.containsKey(acShare.AccountId) && mapAccountIdSetOldSalesOffice.get(acShare.AccountId).contains(acShare.UserorGroup.Name)){
                        deleteAccountShareList.add(acShare);
                    }  
                }
                // Deleting old  Acc Shares Records
                if(!deleteAccountShareList.isEmpty()){
                    Delete deleteAccountShareList;   
                } 
            }  
            // Sharing Acc Records with Sales Office Public Group
            for(String salesOffice:mapSalesOfficeSetAccountId.keySet() ){
                for(String accountId:mapSalesOfficeSetAccountId.get(salesOffice)){
                    if(salesOfficeGroupMap.containsKey(salesOffice)){
                        AccountShare accShare= createAccountSharing(salesOfficeGroupMap.get(salesOffice),accountId);
                        newAccountShareList.add(accShare);
                    }
                }
            }
            // Inserting new  Account Shares Records
            if(!newAccountShareList.isEmpty()){
                Database.insert(newAccountShareList,false);   
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_salesOfficerecordSharing', 'shareAccountonUpdate', ex.getMessage());
        }
    }
    
    /***********************************************************************************************
    * MethodName: accountTeamRecordSharing 
    * Description : Method for sharing records With BPA Sales Offices
    * Params:       Map<Id,NSP_Account_Team__c> newAccountTeamMap
    * 
    * ********************************************************************************************/      
    public static void accountTeamRecordSharing(Map<Id,NSP_Account_Team__c> newAccountTeamMap){
        Map<String,Set<String>> mapSalesOfficeSetAccountId = new  Map<String,Set<String>>();
        List<AccountShare> accountShareList = new List<AccountShare>();
        try{   
            Map<Id,NSP_Account_Team__c> accountTeamMap = new Map<Id,NSP_Account_Team__c>([SELECT Id,NSP_Role__c,NSP_Account__c,NSP_User__c,TOLabel(NSP_Account__r.Owner.NSP_Sales_Office_Membership__c),TOLabel(NSP_User__r.NSP_Sales_Office_Membership__c) FROM NSP_Account_Team__c 
                                                                                          WHERE Id IN:newAccountTeamMap.keySet() AND NSP_User__r.NSP_Sales_Office_Membership__c != null AND NSP_Role__c =:Label.NSP_AccountTeamMemberRole]);
            for(NSP_Account_Team__c acTeam:accountTeamMap.values()){
                List<String> accountSalesOfficeList= acTeam.NSP_Account__r.Owner.NSP_Sales_Office_Membership__c.Split(';');
                List<String> accountTeamUserSalesOfficeList = acTeam.NSP_User__r.NSP_Sales_Office_Membership__c.Split(';');
                for(String acTeamSalesOffice:accountTeamUserSalesOfficeList){
                    if(!accountSalesOfficeList.Contains(acTeamSalesOffice)){
                        // Share account Record With ATM BPA User if ATM BPA User Sales Office not equals to Account Owner Sales office 
                        AccountShare accShare= createAccountSharing(acTeam.NSP_User__c,acTeam.NSP_Account__c);
                        accountShareList.add(accShare);
                        // creating a map of ATM user Sales Office and ATM Account Id 
                        if(mapSalesOfficeSetAccountId.get(acTeamSalesOffice)==null){
                            mapSalesOfficeSetAccountId.put(acTeamSalesOffice, new Set<String>());
                        }
                        mapSalesOfficeSetAccountId.get(acTeamSalesOffice).add(acTeam.NSP_Account__c);
                    }
                }     
            }
            // creating map of Sales Office Group name and Group Id
            Map<String,String> salesOfficeGroupMap = mapSalesOfficePublicGroup(mapSalesOfficeSetAccountId.KeySet());
            
            // Sharing Account Records with Sales Office Public Group
            for(String salesOffice:mapSalesOfficeSetAccountId.keySet() ){
                for(String accountId:mapSalesOfficeSetAccountId.get(salesOffice)){
                    if(salesOfficeGroupMap.containsKey(salesOffice)){
                        AccountShare accShare= createAccountSharing(salesOfficeGroupMap.get(salesOffice),accountId);
                        accountShareList.add(accShare);
                    }
                }
            }
            // Inserting Account Shares Records
            if(!accountShareList.isEmpty()){
                Database.insert(accountShareList,false);   
            }
 
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_salesOfficerecordSharing', 'accountTeamRecordSharing', ex.getMessage());
        }                                                                        
    }
    
    
    /***********************************************************************************************
    * MethodName: updateAccessOnATMRemoval 
    * Description : Method for sharing records With BPA Sales Offices
    * Params:       Map<Id,NSP_Account_Team__c> newAccountTeamMap
    * 
    * ********************************************************************************************/      
    public static void updateAccessOnATMRemoval(List<NSP_Account_Team__c> oldAccountTeamList,Map<Id,NSP_Account_Team__c> oldAccountTeamMap){
        Set<Id> accountTeamUserSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Map<String,Set<String>> mapAccountIdSetAccountOwnerSalesOffice = new Map<String,Set<String>>();
        Map<String,Set<String>> mapAccountIdSetAcTeamOwnerSalesOffice = new Map<String,Set<String>>();
        List<AccountShare> deleteOldAccountShareList = new  List<AccountShare>();
        List<AccountTeamMember> deleteAccountTeamList = new  List<AccountTeamMember>();
        Set<String> accountIdUserIdSet = new Set<String>();
        try{ 
            for(NSP_Account_Team__c acTeam:oldAccountTeamList){
                accountIdSet.add(acTeam.NSP_Account__c);
                accountTeamUserSet.add(acTeam.NSP_User__c);
                String accountIdUserIdKey = acTeam.NSP_Account__c +''+ acTeam.NSP_User__c;
                accountIdUserIdSet.add(accountIdUserIdKey);
            }
            Map<Id,User> accountTeamOwnerMap= new Map<Id,User>([Select Id, TOLabel(NSP_Sales_Office_Membership__c) from User WHERE Id IN:accountTeamUserSet]);
            Map<Id, Account> accountTeamAccountMap = new Map<Id,Account>([Select Id,OwnerId, TOLabel(Owner.NSP_Sales_Office_Membership__c) from Account WHERE Id IN:accountIdSet]);
            
            // Fetching Standard ATM records for Deletion 
            List<AccountTeamMember> accountTeamList =[Select UserId, AccountId from AccountTeamMember WHERE AccountId IN: accountIdSet];
            for(AccountTeamMember acTeam :accountTeamList){
                String accountIdUserIdKey = acTeam.AccountId +''+ acTeam.UserId;
                if(accountIdUserIdSet.contains(accountIdUserIdKey)){
                    deleteAccountTeamList.add(acTeam);
                }
            }
            
            for(NSP_Account_Team__c acTeam:oldAccountTeamList){
                if(acTeam.NSP_Role__c ==Label.NSP_AccountTeamMemberRole ){
                    // creating a map of Account Id and Set of Account Owner Sales Office
                    if(accountTeamAccountMap.containsKey(acTeam.NSP_Account__c) && accountTeamAccountMap.get(acTeam.NSP_Account__c).Owner.NSP_Sales_Office_Membership__c != null ){
                        if(mapAccountIdSetAccountOwnerSalesOffice.get(acTeam.NSP_Account__c)==null){
                            mapAccountIdSetAccountOwnerSalesOffice.put(acTeam.NSP_Account__c, new Set<String>());
                        }
                        mapAccountIdSetAccountOwnerSalesOffice.get(acTeam.NSP_Account__c).addAll(new List<String>(accountTeamAccountMap.get(acTeam.NSP_Account__c).Owner.NSP_Sales_Office_Membership__c.Split(';')));
                        
                    }
                    // creating a map of Account Id and Set of Account Team Sales Office
                    if(accountTeamOwnerMap.containsKey(acTeam.NSP_User__c) && accountTeamOwnerMap.get(acTeam.NSP_User__c).NSP_Sales_Office_Membership__c != null ){
                        
                        if(mapAccountIdSetAcTeamOwnerSalesOffice.get(acTeam.NSP_Account__c)==null){
                            mapAccountIdSetAcTeamOwnerSalesOffice.put(acTeam.NSP_Account__c, new Set<String>());
                        }
                        mapAccountIdSetAcTeamOwnerSalesOffice.get(acTeam.NSP_Account__c).addAll(new List<String>(accountTeamOwnerMap.get(acTeam.NSP_User__c).NSP_Sales_Office_Membership__c.Split(';')));
                    } 
                }
            }
            // fetching old Sales Office Account Share of ATM Users 
            List<AccountShare> oldAccountTeamShareList = [Select Id , AccountId , UserorGroupId, UserOrGroup.Name from AccountShare WHERE 
                                                          AccountId IN :accountIdSet AND Rowcause =:NSP_SalesConstants.manualRowCause ];
            
            // deleting Sharing for Account Team Users after removal 
            for(AccountShare acShare :oldAccountTeamShareList){
                if(mapAccountIdSetAcTeamOwnerSalesOffice.get(acShare.AccountId).Contains(acShare.UserOrGroup.Name) &&
                   !mapAccountIdSetAccountOwnerSalesOffice.get(acShare.AccountId).Contains(acShare.UserOrGroup.Name) ){
                       deleteOldAccountShareList.add(acShare);
                   }
            }
            if(!deleteOldAccountShareList.isEmpty()){
                delete deleteOldAccountShareList;
            }
            if(!deleteAccountTeamList.isEmpty()){
                delete deleteAccountTeamList;
            }
            
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_salesOfficerecordSharing', 'updateAccessOnATMRemoval', ex.getMessage());
        }                                                                        
    }
    
    
    /***********************************************************************************************
    * MethodName: leadRecordSharing 
    * Description : Method for sharing records With BPA Sales Offices
    * Params:       Map<Id,Account> newAccountMap
    * 
    * ********************************************************************************************/      
    public static void leadRecordSharing(Map<Id,Lead> newLeadMap){
        Map<String,Set<String>> mapSalesOfficeSetLeadId = new  Map<String,Set<String>>();
        List<LeadShare> leadShareList = new List<LeadShare>();
        Map<String,Set<String>> mapOwnerIdSetLeadId = new Map<String,Set<String>>();
        try{    
            for(Lead lead:newLeadMap.values()){
                //Give read access to logged in user as after insert lead will be assigned to queue
                if (lead.OwnerId.getSobjectType() == Group.SObjectType || lead.OwnerId.getSobjectType() == User.SObjectType) {
                    if (!Auth.CommunitiesUtil.isGuestUser()) {
                    	LeadShare ldShare =createLeadShare(lead.CreatedById,lead.Id,NSP_SalesConstants.readSharingAccess); 
                    	leadShareList.add(ldShare);
                    }
                }
                if(String.valueOf(lead.OwnerId).startsWith(NSP_SalesConstants.userId)){
                    if(mapOwnerIdSetLeadId.get(lead.OwnerId)==null){
                        mapOwnerIdSetLeadId.put(lead.OwnerId, new Set <String>());
                    }
                    mapOwnerIdSetLeadId.get(lead.OwnerId).add(lead.Id);  
                }
            }
            Map<Id,User> leadOwnerMap = new Map<Id,User>([SELECT Id,ToLabel(NSP_Sales_Office_Membership__c) FROM User WHERE Id IN:mapOwnerIdSetLeadId.KeySet() AND
                                                          UserRole.Name =:NSP_SalesConstants.BPARole AND NSP_Sales_Office_Membership__c != null ]);
            for(User user:leadOwnerMap.Values() ){
                if(mapOwnerIdSetLeadId.get(user.Id)!=null &&  mapOwnerIdSetLeadId.containsKey(user.Id) 
                   && mapOwnerIdSetLeadId.containsKey(user.Id)==leadOwnerMap.containsKey(user.Id)){
                       List<String> userSalesOfficeList= user.NSP_Sales_Office_Membership__c.split(';');
                       for(String userSalesOffice:userSalesOfficeList){
                           // creating map of Sales office and Set of Account Id
                           if(mapSalesOfficeSetLeadId.get(userSalesOffice)==null){
                               mapSalesOfficeSetLeadId.put(userSalesOffice,new Set<String>());
                           } 
                           mapSalesOfficeSetLeadId.get(userSalesOffice).addAll(mapOwnerIdSetLeadId.get(user.Id));
                       }   
                   }
            }
            // creating map of Sales Office Group name and Group Id
            Map<String,String> salesOfficeGroupMap = mapSalesOfficePublicGroup(mapSalesOfficeSetLeadId.KeySet());
            
            // Sharing Lead Records with Sales Office Public Group
            for(String salesOffice:mapSalesOfficeSetLeadId.keySet() ){
                for(String leadId:mapSalesOfficeSetLeadId.get(salesOffice)){
                    if(salesOfficeGroupMap.containsKey(salesOffice)){
                        LeadShare leadShare= createLeadShare(salesOfficeGroupMap.get(salesOffice),
                                                             leadId,NSP_SalesConstants.editSharingAccess);
                        leadShareList.add(leadShare);
                    }
                }
            }
            // Inserting Account Shares Records
            if(!leadShareList.isEmpty()){
                Database.insert(leadShareList,false);   
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_salesOfficerecordSharing', 'leadRecordSharing', ex.getMessage());
        }
    }
    
    /***********************************************************************************************
    * MethodName: shareLeadsonUpdate
    * Description : update Sharing access  of Lead on Lead Owner Change
    * Params:       Map<Id,Lead> newLeadMap, Map<Id,Lead>oldLead
    * ********************************************************************************************/
    public static void shareLeadsonUpdate(Map < Id, Lead > newLeadMap, Map < Id, Lead > oldLeadMap) {
        Map<String,Set<String>> mapLeadIdSetOldSalesOffice = new  Map<String,Set<String>>();
        Map<String,Set<String>> mapSalesOfficeSetLeadId = new  Map<String,Set<String>>();
        Map<String,Set<String>> mapnewOwnerIdSetLeadId = new Map<String,Set<String>>();
        Map<String,Set<String>> mapoldOwnerIdSetLeadId = new Map<String,Set<String>>();
        List<LeadShare> deleteLeadShareList = new List<LeadShare>();
        List<LeadShare> newLeadShareList = new List<LeadShare>();
        try{    
            for(Lead lead:newLeadMap.values()){
                if(lead.OwnerId !=oldLeadMap.get(lead.Id).OwnerId && String.valueOf(lead.OwnerId).startsWith('005') ){
                    if(mapnewOwnerIdSetLeadId.get(lead.OwnerId)==null){
                        mapnewOwnerIdSetLeadId.put(lead.OwnerId, new Set <String>());
                    }
                    mapnewOwnerIdSetLeadId.get(lead.OwnerId).add(lead.Id);
                    if(String.valueOf(oldLeadMap.get(lead.Id).OwnerId).startsWith('005')){
                        if(mapoldOwnerIdSetLeadId.get(oldLeadMap.get(lead.Id).OwnerId)==null){
                            mapoldOwnerIdSetLeadId.put(oldLeadMap.get(lead.Id).OwnerId, new Set <String>());
                        }
                        mapoldOwnerIdSetLeadId.get(oldLeadMap.get(lead.Id).OwnerId).add(lead.Id);  
                    }
                }      
            }
            Map<Id,User> leadNewOwnerMap = new Map<Id,User>([SELECT Id,ToLabel(NSP_Sales_Office_Membership__c) FROM User WHERE Id IN:mapnewOwnerIdSetLeadId.KeySet() AND
                                                             UserRole.Name =:NSP_SalesConstants.BPARole ]);
            Map<Id,User> leadOldOwnerMap = new Map<Id,User>([SELECT Id,UserRole.Name,ToLabel(NSP_Sales_Office_Membership__c) FROM User WHERE Id IN:mapoldOwnerIdSetLeadId.KeySet() 
                                                             AND NSP_Sales_Office_Membership__c != null AND UserRole.Name =:NSP_SalesConstants.BPARole ]);
            for(Lead lead :newLeadMap.values()){
                Set<String> oldLeadSalesOfficeList = new Set<String>();
                Set<String> newLeadSalesOfficeList = new Set<String>();
                // creating List of New Owner Sales Office
                if(leadNewOwnerMap.containsKey(lead.OwnerId) && leadNewOwnerMap.get(lead.OwnerId).NSP_Sales_Office_Membership__c != null){
                    newLeadSalesOfficeList.addAll(new List<String>(leadNewOwnerMap.get(lead.OwnerId).NSP_Sales_Office_Membership__c.Split(';')));
                }
                // creating list of old owner sales office
                if(leadOldOwnerMap.containsKey(oldLeadMap.get(lead.Id).OwnerId)){
                    oldLeadSalesOfficeList.addAll(new List<String>(leadOldOwnerMap.get(oldLeadMap.get(lead.Id).OwnerId).NSP_Sales_Office_Membership__c.Split(';')));
                }
                // compairing new user sales Offices with Old User Sales Office
                if(!newLeadSalesOfficeList.isEmpty()){
                    for(String newSalesOffice: newLeadSalesOfficeList){
                        // creating a Map of Sales Office and Set of Lead Ids
                        if(mapSalesOfficeSetLeadId.get(newSalesOffice)==null){
                            mapSalesOfficeSetLeadId.put(newSalesOffice , new Set<String>());
                        }
                        mapSalesOfficeSetLeadId.get(newSalesOffice).add(lead.Id);
                        
                        // updating the list of Sales Office that will not have the lead access 
                        if(!oldLeadSalesOfficeList.isEmpty() && oldLeadSalesOfficeList.contains(newSalesOffice) ){
                            oldLeadSalesOfficeList.remove(newSalesOffice);
                        }
                    }  
                }
                // creating a map of  Lead Id and set of Old Sales office
                if(!oldLeadSalesOfficeList.isEmpty()){
                    if(mapLeadIdSetOldSalesOffice.get(lead.Id)==null){
                        mapLeadIdSetOldSalesOffice.put(lead.Id, new Set<String>());
                    } 
                    mapLeadIdSetOldSalesOffice.get(lead.Id).addAll(oldLeadSalesOfficeList);
                } 
            }
            // creating map of Sales Office Group name and Group Id
            Map<String,String> salesOfficeGroupMap = mapSalesOfficePublicGroup(mapSalesOfficeSetLeadId.KeySet());
            //Seacrhing for existing Lead Share Records 
            if(mapLeadIdSetOldSalesOffice!=null){
                List<LeadShare> oldLeadShareList =[Select Id, LeadId ,Lead.OwnerId, UserorGroup.Name , UserorGroupId from LeadShare WHERE 
                                                   LeadId IN: mapLeadIdSetOldSalesOffice.KeySet() AND Rowcause =:NSP_SalesConstants.manualRowCause];
                // creating a List of Lead Share List Needs to be deleted 
                for(LeadShare ldShare:oldLeadShareList){
                    if(mapLeadIdSetOldSalesOffice.containsKey(ldShare.LeadId) && mapLeadIdSetOldSalesOffice.get(ldShare.LeadId).contains(ldShare.UserorGroup.Name)){
                        deleteLeadShareList.add(ldShare);
                    }  
                }
                // Deleting old  Lead Shares Records
                if(!deleteLeadShareList.isEmpty()){
                    Delete deleteLeadShareList;   
                } 
            }  
            // Sharing Lead Records with Sales Office Public Group
            for(String salesOffice:mapSalesOfficeSetLeadId.keySet() ){
                for(String leadId:mapSalesOfficeSetLeadId.get(salesOffice)){
                    if(salesOfficeGroupMap.containsKey(salesOffice)){
                        LeadShare leadShare= createLeadShare(salesOfficeGroupMap.get(salesOffice),leadId,NSP_SalesConstants.editSharingAccess);
                        newLeadShareList.add(leadShare);
                    }
                }
            }
            // Inserting new  Lead Shares Records
            if(!newLeadShareList.isEmpty()){
                Database.insert(newLeadShareList,false);   
            }   
            
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_salesOfficerecordSharing', 'shareLeadsonUpdate', ex.getMessage());
        }
    } 
    
    /***********************************************************************************************
    * MethodName: shareOpportunityonUpdate
    * Description : update Sharing access for Non-BPA members of Opportunity  on Opportunity Owner Change
    * Params:      Map < Id, Opportunity > newOpportunityMap, Map < Id, Opportunity > oldOpportunityMap
    * ********************************************************************************************/
    public static void shareOpportunityonUpdate(Map < Id, Opportunity > newOpportunityMap, Map < Id, Opportunity > oldOpportunityMap) {
        Map<String,Set<String>> mapOppIdSetOldSalesOffice = new  Map<String,Set<String>>();
        Map<String,Set<String>> mapSalesOfficeSetOppId = new  Map<String,Set<String>>();
        List<OpportunityShare> newOpportunityShareList = new List<OpportunityShare>();
        List<OpportunityShare> deleteOpportunityShareList = new List<OpportunityShare>();
        Set<Id> oldOpportunityIdSet = new Set<Id>();
        try{
            for(Opportunity opp :newOpportunityMap.Values() ){
                if(opp.OwnerId != oldOpportunityMap.get(opp.Id).OwnerId){
                    oldOpportunityIdSet.add(oldOpportunityMap.get(opp.Id).OwnerId);
                }
            }
            Map<Id,User> OldOppOwnerMap = new Map<Id,User>([SELECT Id,UserRole.Name,TOLabel(NSP_Sales_Office_Membership__c) FROM USER WHERE Id IN:oldOpportunityIdSet AND
                                                            UserRole.Name =:NSP_SalesConstants.BPARole]);
            Map<Id,Opportunity> newOppMap = new Map<Id,Opportunity>([SELECT Id,Owner.UserRole.Name,TOLabel(Owner.NSP_Sales_Office_Membership__c),OwnerId FROM Opportunity WHERE Id IN:newOpportunityMap.keySet()  ]);
            
            for(Opportunity opp : newOppMap.values()){
                Set<String> oldOppSalesOfficeList = new Set<String>();
                Set<String> newOppSalesOfficeList = new Set<String>();
                // Store new Opp Owner Sales Office in the List
                if(newOppMap.get(opp.Id).Owner.NSP_Sales_Office_Membership__c!=null && newOppMap.get(opp.Id).Owner.UserRole.Name ==NSP_SalesConstants.BPARole ){
                    newOppSalesOfficeList.addAll(new List<String>(newOppMap.get(opp.Id).Owner.NSP_Sales_Office_Membership__c.Split(';')));
                }
                // Store old Opp Owner Sales Office in the List 
                if(OldOppOwnerMap.containsKey(oldOpportunityMap.get(opp.Id).OwnerId) && OldOppOwnerMap.get(oldOpportunityMap.get(opp.Id).OwnerId).NSP_Sales_Office_Membership__c!=null){
                    oldOppSalesOfficeList.addAll(new List<String>(OldOppOwnerMap.get(oldOpportunityMap.get(opp.Id).OwnerId).NSP_Sales_Office_Membership__c.Split(';')));
                }
                if(!newOppSalesOfficeList.isEmpty()){
                    for(String newSalesOffice:newOppSalesOfficeList){
                        // creating a Map of Sales Office and Set of Opp Id
                        if(mapSalesOfficeSetOppId.get(newSalesOffice)==null){
                            mapSalesOfficeSetOppId.put(newSalesOffice , new Set<String>());
                        }
                        mapSalesOfficeSetOppId.get(newSalesOffice).add(opp.Id);
                        // removing exiting sales office from list of old sales Offices  
                        if(!oldOppSalesOfficeList.isEmpty() && oldOppSalesOfficeList.contains(newSalesOffice) ){
                            oldOppSalesOfficeList.remove(newSalesOffice);
                        }
                    }
                }
                // creating a map of  Opp Id and set of Old Sales office
                if(!oldOppSalesOfficeList.isEmpty()){
                    if(mapOppIdSetOldSalesOffice.get(opp.Id)==null){
                        mapOppIdSetOldSalesOffice.put(opp.Id, new Set<String>());
                    } 
                    mapOppIdSetOldSalesOffice.get(opp.Id).addAll(oldOppSalesOfficeList);
                }
            } 
            // creating map of Sales Office Group name and Group Id
            Map<String,String> salesOfficeGroupMap = mapSalesOfficePublicGroup(mapSalesOfficeSetOppId.KeySet());
            //Seacrhing for existing Opportunity Share Records 
            if(mapOppIdSetOldSalesOffice!=null){
                List<OpportunityShare> oldOppShareList =[Select Id, OpportunityId ,Opportunity.OwnerId, UserorGroup.Name , UserorGroupId from OpportunityShare WHERE 
                                                         OpportunityId IN: mapOppIdSetOldSalesOffice.KeySet() AND Rowcause =:NSP_SalesConstants.manualRowCause];
                // creating a List of Opportunity Share List Needs to be deleted 
                for(OpportunityShare opShare:oldOppShareList){
                    if(mapOppIdSetOldSalesOffice.containsKey(opShare.OpportunityId) && mapOppIdSetOldSalesOffice.get(opShare.OpportunityId).contains(opShare.UserorGroup.Name)){
                        deleteOpportunityShareList.add(opShare);
                    }  
                }
                // Deleting old  Opp Shares Records
                if(!deleteOpportunityShareList.isEmpty()){
                    Delete deleteOpportunityShareList;   
                } 
            }  
            // Sharing Opp Records with Sales Office Public Group
            for(String salesOffice:mapSalesOfficeSetOppId.keySet() ){
                for(String oppId:mapSalesOfficeSetOppId.get(salesOffice)){
                    if(salesOfficeGroupMap.containsKey(salesOffice)){
                        OpportunityShare opShare= createOpportunitySharing(salesOfficeGroupMap.get(salesOffice),oppId);
                        newOpportunityShareList.add(opShare);
                    }
                }
            }
            // Inserting new  Opportunity Shares Records
            if(!newOpportunityShareList.isEmpty()){
                Database.insert(newOpportunityShareList,false);   
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_salesOfficerecordSharing', 'shareOpportunityonUpdate', ex.getMessage());
        }
    }
    
    /***********************************************************************************************
    * MethodName: opportunityRecordSharing
    * Description : Share Opportunity with Public Group
    * Params:       List<Opportunity> opportunityList
    * ********************************************************************************************/
    public static void opportunityRecordSharing(Map <Id, Opportunity > newopportunityMap) {
        Map<String,Set<String>> mapSalesOfficeSetOpportunityId = new  Map<String,Set<String>>();
        List<OpportunityShare> opportunityShareList = new List<OpportunityShare>();
        List<OpportunityShare> channelOperationsGroupShareList = new List<OpportunityShare>();
        try{
            Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>([SELECT Id,ToLabel(Owner.NSP_Sales_Office_Membership__c) FROM Opportunity WHERE Id IN:newopportunityMap.keySet() AND
                                                                          Owner.UserRole.Name =:NSP_SalesConstants.BPARole  AND (StageName !=: NSP_SalesConstants.CLOSED_WON OR StageName !=: NSP_SalesConstants.CLOSED_LOST)]);
            
            // Share Opportunities with Channel Operation Role Users and NCS , Data Science Public Groups 
            Set<Id> channelOperationsGroupShareIdSet = rolesPublicGroupShare();
            if(!channelOperationsGroupShareIdSet.isEmpty()){
                channelOperationsGroupShareList =shareOpportunityWithUsers(channelOperationsGroupShareIdSet,opportunityMap.KeySet());
            }
            OpportunityShareList.addAll(channelOperationsGroupShareList);
            
            for(Opportunity opp: opportunityMap.Values()){
                if(opp.Owner.NSP_Sales_Office_Membership__c!=null){
                    List<String> userSalesOfficeList= opp.Owner.NSP_Sales_Office_Membership__c.split(';');
                    for(String userSalesOffice:userSalesOfficeList){
                        // creating map of Sales office and Set of Opportunity Id
                        if(mapSalesOfficeSetOpportunityId.get(userSalesOffice)==null){
                            mapSalesOfficeSetOpportunityId.put(userSalesOffice,new Set<String>());
                        } 
                        mapSalesOfficeSetOpportunityId.get(userSalesOffice).add(opp.Id);
                    }
                }
            } 
            // creating map of Sales Office Group name and Group Id
            Map<String,String> salesOfficeGroupMap = mapSalesOfficePublicGroup(mapSalesOfficeSetOpportunityId.KeySet());
            
            // Sharing Account Records with Sales Office Public Group
            for(String salesOffice:mapSalesOfficeSetOpportunityId.keySet() ){
                for(String oppId:mapSalesOfficeSetOpportunityId.get(salesOffice)){
                    if(salesOfficeGroupMap.containsKey(salesOffice)){
                        OpportunityShare oppShare= createOpportunitySharing(salesOfficeGroupMap.get(salesOffice),oppId);
                        OpportunityShareList.add(oppShare);
                    }
                }
            }
            // Inserting Opportunity Shares Records
            if(!OpportunityShareList.isEmpty()){
                Database.insert(OpportunityShareList,false);   
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_salesOfficerecordSharing', 'opportunityRecordSharing', ex.getMessage());
        }
    }  
        
    /***********************************************************************************************
    * MethodName: rolesPublicGroupShare 
    * Description : Share Opportunity with Channel Operation role and NCS,Data public group Users
    * Params:       String userorGroupId , String opportunityId
    * 
    * ********************************************************************************************/    
    public static Set<Id> rolesPublicGroupShare(){
        Set<Id> userOrGroupIdSet = new Set<Id>();
        List<Id> channelPublicGroupUsers = new List<Id>();
        // searching for Channel Operations Role Users
        List <User> channelOperationUsers = [Select Id from User WHERE UserRole.Name =: NSP_SalesConstants.channelOperation];
        for(User chnlRoleUser:channelOperationUsers){
            channelPublicGroupUsers.add(chnlRoleUser.Id);
        }
        // searching Group Id's of NCS and Data Science Public Group 
        List < String > oppPublicGroup = System.Label.NSP_opportunityPublicGroup.split(',');
        Set < String > publicGroups = new Set < String > ();
        publicGroups.addAll(oppPublicGroup); 
        Map<String,String> opportunityPublicGroups = mapSalesOfficePublicGroup(publicGroups);
        channelPublicGroupUsers.addAll(opportunityPublicGroups.Values());
        userOrGroupIdSet.addAll(channelPublicGroupUsers);
        
        return userOrGroupIdSet;
    }  
    
    /***********************************************************************************************
    * MethodName: shareOpportunityWithUsers 
    * Description : 
    * Params:      
    * 
    * ********************************************************************************************/    
    public static List<OpportunityShare> shareOpportunityWithUsers(Set<Id> userOrGroupIdSet, Set<Id> recordIdSet){
        List<OpportunityShare> oppShareList = new List<OpportunityShare>();          
        // Sharing Opportunity with Channel Operation Role Users and NCS and Data Science Group
        for(Id oppId :recordIdSet){
            for(Id userGroupId:userOrGroupIdSet){
                OpportunityShare oppShare = createOpportunitySharing(userGroupId,oppId);
                oppShareList.add(oppShare);
            }
        }
        return oppShareList;
    }
    
    /***********************************************************************************************
    * MethodName: createOpportunitySharing 
    * Description : Creating Opportunity Share Records
    * Params:       String userorGroupId , String opportunityId
    * 
    * ********************************************************************************************/    
    public static OpportunityShare createOpportunitySharing(String userorGroupId , String opportunityId ){
        OpportunityShare opshare = new OpportunityShare();
        opshare.RowCause = NSP_SalesConstants.manualRowCause;
        opshare.UserOrGroupId = userorGroupId;
        opshare.OpportunityAccessLevel = NSP_SalesConstants.editSharingAccess;
        opshare.OpportunityId = opportunityId;
        return opShare;
    }
    
    /***********************************************************************************************
    * MethodName: createAccountSharing 
    * Description : Method to retrieve group members of Onwer Sales Office Public Group
    * Params:       String userorGroupId , String AccountId
    * 
    * ********************************************************************************************/    
    public static AccountShare createAccountSharing(String userorGroupId , String accountId ){
        AccountShare acshare= new AccountShare();
        acshare.RowCause=NSP_SalesConstants.manualRowCause;
        acshare.UserOrGroupId=userorGroupId;
        acshare.AccountAccessLevel=NSP_SalesConstants.editSharingAccess;
        acShare.OpportunityAccessLevel=Label.NSP_OpportunityAccess;
        acshare.AccountId=accountId;
        return acshare;
    }
    
    /***********************************************************************************************
    * MethodName: createLeadSharing 
    * Description : Method to retrieve group members of Onwer Sales Office Public Group
    * Params:       String userorGroupId , String LeadId , String recordAccess
    * 
    * ********************************************************************************************/    
    public static LeadShare createLeadShare(String userorGroupId , String leadId, String recordAccess){
        LeadShare ldshare = new LeadShare();
        ldshare.RowCause = NSP_SalesConstants.manualRowCause;
        ldshare.UserOrGroupId = userorGroupId;
        ldshare.LeadAccessLevel = recordAccess;
        ldshare.LeadId = leadId;
        return ldShare;
    }
    
    /***********************************************************************************************
    * MethodName: mapSalesOfficePublicGroup 
    * Description : This Method will fetch and create map of Sales Office Public Group and Group Id
    * Params:      Map<String,Set<String>> mapSalesOfficeSetRecordId
    * 
    * ********************************************************************************************/    
    public static Map<String,String> mapSalesOfficePublicGroup(Set<String> salesOfficeSet){
        Map<String,String> salesOfficeGroupMap = new Map<String,String>();
        List<Group> salesOfficeGroups= [SELECT Id, Name FROM Group WHERE Name IN:salesOfficeSet];
        for(Group grp:salesOfficeGroups){
            salesOfficeGroupMap.put(grp.Name,grp.Id);
        }
        return salesOfficeGroupMap;
        
    }
    
}