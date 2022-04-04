/**
 * @description  :  class for set up manual sharing rules.
 * @date 01/16/2022
 * Author : Nischay Jindal
 * Name : NSP_recordSharing
 */
public class NSP_recordSharing {
    private static final string NSP_recordSharing = 'NSP_recordSharing';

    /***********************************************************************************************
     * MethodName: nonBPALeadSharing
     * Description : Share Lead with Non-BPA members of Lead Owner Sales Office Public Group
     * Params:       List<Lead> leadList
     * ********************************************************************************************/
    public static void nonBPALeadSharing(List < Lead > leadList) {
        Set < Id > ownerIds = new Set < Id > ();
        List < LeadShare > leadShares = new List < LeadShare > ();
        try {
            for (Lead lead: leadList) {
                ownerIds.add(lead.OwnerId);
             //Give read access to logged in user
                if (lead.OwnerId.getSobjectType() == Group.SObjectType) {
                LeadShare ldshare = new LeadShare();
                ldshare.RowCause = NSP_SalesConstants.manualRowCause;
                ldshare.UserOrGroupId = userinfo.getUserId();
                ldshare.LeadAccessLevel = NSP_SalesConstants.readSharingAccess;
                ldshare.LeadId = lead.Id;
                leadShares.add(ldshare);
            }
            }
            // getting non BPA users
            List < User > nonBPAUsers = getnonBPAUsers(ownerIds);
            if (!nonBPAUsers.isEmpty()) {
                for (Lead lead: leadList) {
                    for (User nonbpaUser: nonBPAUsers) {
                        LeadShare ldshare = new LeadShare();
                        ldshare.RowCause = NSP_SalesConstants.manualRowCause;
                        ldshare.UserOrGroupId = nonbpaUser.Id;
                        ldshare.LeadAccessLevel = NSP_SalesConstants.editSharingAccess;
                        ldshare.LeadId = lead.Id;
                        leadShares.add(ldshare);
                    }
                }
            }
            // sharing lead with users 
            if (!leadShares.isEmpty()) {
                insert leadShares;
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_recordSharing, 'nonBPALeadSharing', ex.getMessage());
        }
    }
    /***********************************************************************************************
     * MethodName: queuedLeadRecordSharing
     * Description : Share Lead with created by user if lead owner is queue
     * Params:       List<Lead> leadList
     * ********************************************************************************************/
    public static void queuedLeadRecordSharing(List < Lead > leadList) {
        //List holds share records of created by user
        List < LeadShare > leadShares = new List < LeadShare > ();
        for (Lead lead: leadList) {
            if (lead.OwnerId.getSobjectType() == Group.SObjectType) {
                LeadShare ldshare = new LeadShare();
                ldshare.RowCause = NSP_SalesConstants.manualRowCause;
                ldshare.UserOrGroupId = lead.CreatedById;
                ldshare.LeadAccessLevel = NSP_SalesConstants.readSharingAccess;
                ldshare.LeadId = lead.Id;
                leadShares.add(ldshare);
            }
        }
        // sharing lead with users 
        if (!leadShares.isEmpty() && !Auth.CommunitiesUtil.isGuestUser()) {
            insert leadShares;
        }
    }

    /***********************************************************************************************
     * MethodName: shareLeadsonUpdate
     * Description : update Sharing access for Non-BPA members of Lead on Lead Owner Change
     * Params:       Map<Id,Lead> newLeadMap, Map<Id,Lead>oldLead
     * ********************************************************************************************/
    public static void shareLeadsonUpdate(Map < Id, Lead > newLeadMap, Map < Id, Lead > oldLead) {
        Set < Id > oldLeadIds = new Set < Id > ();
        try {
            for (Lead lead: newLeadMap.values()) {

                if (lead.ownerId != oldLead.get(lead.Id).OwnerId) {
                    oldLeadIds.add(lead.Id);

                }
            }
            if (!oldLeadIds.isEmpty()) {
                List < LeadShare > leadShares = [Select Id from LeadShare WHERE RowCause =: NSP_SalesConstants.manualRowCause AND LeadId IN: oldLeadIds];

                // delete sharing with old owner Sales Office Public Group 
                if (!leadShares.isEmpty()) {
                    delete leadShares;
                }
                // share leads with new onwer Sales Office Public Group
                nonBPALeadSharing(newLeadMap.values());
            }

        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_recordSharing, 'shareLeadsonUpdate', ex.getMessage());
        }


    }
    /***********************************************************************************************
     * MethodName: nonBPAAccountSharing
     * Description : Share Account with Non-BPA members of Account Owner Sales Office Public Group
     * Params:       Map<Id,Account> accountMap
     * ********************************************************************************************/
    public static void nonBPAAccountSharing(Map < Id, Account > accountMap) {
        Set < Id > ownerIds = new Set < Id > ();
        try {
            for (Account account: accountMap.values()) {
                ownerIds.add(account.OwnerId);
            }
            List < User > nonBPAUsers = getnonBPAUsers(ownerIds);
            List < AccountShare > accountshareList = new List < AccountShare > ();
            if (!nonBPAUsers.isEmpty()) {
                for (Account account: accountMap.values()) {
                    for (User nonbpaUser: nonBPAUsers) {
                        AccountShare acshare = new AccountShare();
                        acshare.RowCause = NSP_SalesConstants.manualRowCause;
                        acshare.UserOrGroupId = nonbpaUser.Id;
                        acshare.AccountAccessLevel = NSP_SalesConstants.editSharingAccess;
                        acShare.OpportunityAccessLevel = Label.NSP_OpportunityAccess;
                        acshare.AccountId = account.Id;
                        accountshareList.add(acshare);
                    }
                }
            }
            if (!accountshareList.isEmpty()) {
                insert accountshareList;
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_recordSharing, 'nonBPAAccountSharing', ex.getMessage());
        }
    }

    /***********************************************************************************************
     * MethodName: shareAccountonUpdate
     * Description : update Sharing access for Non-BPA members of Account on Account Owner Change
     * Params:       Map<Id,Account> newAccountMap, Map<Id,Account>oldAccountMap
     * ********************************************************************************************/
    public static void shareAccountonUpdate(Map < Id, Account > newAccountMap, Map < Id, Account > oldAccountMap) {
        Set < Id > oldAccountIds = new Set < Id > ();
        try {
            for (Account account: newAccountMap.values()) {
                if (account.ownerId != oldAccountMap.get(account.Id).OwnerId) {

                    oldAccountIds.add(account.Id);
                }
            }
            if (!oldAccountIds.isEmpty()) {
                List < AccountShare > oldAccountShare = [Select Id from AccountShare WHERE RowCause =: NSP_SalesConstants.manualRowCause AND AccountId IN: oldAccountIds];

                // delete sharing with old owner Sales Office Public Group 
                if (!oldAccountShare.isEmpty()) {
                    delete oldAccountShare;
                }
                // share account with new onwer Sales Office Public Group
                nonBPAAccountSharing(newAccountMap);
            }

        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_recordSharing, 'shareAccountonUpdate', ex.getMessage());
        }

    }

    /***********************************************************************************************
     * MethodName: accountTeamMembersharing
     * Description : Share Account account team members sales office public group
     * Params:       Map<Id,Account> accountMap
     * ********************************************************************************************/
    public static void accountTeamMembersharing(List < NSP_Account_Team__c > accountTeamList) {
        Set < Id > accountId = new Set < Id > ();
        Set < Id > ATMUser = new Set < Id > ();
        Map < String, Id > SalesOfficeAccountMap = new Map < String, Id > ();
        Map < String, List < Id >> SalesOfficeUsersMap = new Map < String, List < Id >> ();
        Map < String, Set < Id >> SalesOffAccountMap = new Map < String, Set < Id >> ();
        try {
            for (NSP_Account_Team__c acTeam: accountTeamList) {
                accountId.add(acTeam.NSP_Account__c);
                ATMUser.add(acTeam.NSP_User__c);
                // accountTeamUserMap.put(acTeam.NSP_User__c,acTeam.NSP_Account__c);
            }
            // Querying ATM User and its Sales Office
            Map < Id, User > ATMUserMap = new Map < Id, User > ([Select Id, Name, NSP_Sales_Office__c from User
                WHERE Id IN: ATMUser
            ]);

            // Querying ATM Account and its Sales Office
            Map < Id, Account > accountSalesOfficeMap = new Map < Id, Account > ([Select Id, Name, OwnerId, Owner.NSP_Sales_Office__c from account
                WHERE Id IN: accountId
            ]);

            List < AccountShare > accountshareList = new List < AccountShare > ();
            Map < String, String > getSalesOffice = getPicklistLabel();
            for (NSP_Account_Team__c acTeam: accountTeamList) {
                if (accountSalesOfficeMap.containsKey(acTeam.NSP_Account__c) && getSalesOffice.get(ATMUserMap.get(acTeam.NSP_User__c).NSP_Sales_Office__c) != getSalesOffice.get(accountSalesOfficeMap.get(acTeam.NSP_Account__c).Owner.NSP_Sales_Office__c) &&
                    acTeam.NSP_Role__c == System.Label.NSP_AccountTeamMemberRole) {
                    // Creating a set of ATM User SalesOffice to fetch the related Public Group 
                    SalesOfficeAccountMap.put(getSalesOffice.get(ATMUserMap.get(acTeam.NSP_User__c).NSP_Sales_Office__c), acTeam.NSP_Account__c);
                    // Provide Edit Access to BPA User
                    if (SalesOffAccountMap.get(getSalesOffice.get(ATMUserMap.get(acTeam.NSP_User__c).NSP_Sales_Office__c)) == null) {
                        SalesOffAccountMap.put(getSalesOffice.get(ATMUserMap.get(acTeam.NSP_User__c).NSP_Sales_Office__c), new Set < Id > ());
                    }
                    SalesOffAccountMap.get(getSalesOffice.get(ATMUserMap.get(acTeam.NSP_User__c).NSP_Sales_Office__c)).add(acTeam.NSP_Account__c);

                    AccountShare bpaAccountShare = new AccountShare();
                    bpaAccountShare.RowCause = NSP_SalesConstants.manualRowCause;
                    bpaAccountShare.UserOrGroupId = acTeam.NSP_User__c;
                    bpaAccountShare.AccountAccessLevel = NSP_SalesConstants.editSharingAccess;
                    bpaAccountShare.OpportunityAccessLevel = Label.NSP_OpportunityAccess;
                    bpaAccountShare.AccountId = acTeam.NSP_Account__c;
                    accountshareList.add(bpaAccountShare);
                }
            }
            SalesOfficeUsersMap = getATMgroupMembers(SalesOfficeAccountMap);
            if (SalesOfficeUsersMap.Size() > 0) {
                for (String salesOffice: SalesOfficeUsersMap.keyset()) {
                    for (Id grpMember: SalesOfficeUsersMap.get(salesOffice)) {
                        if (SalesOffAccountMap.containsKey(salesOffice) == SalesOfficeUsersMap.containsKey(salesOffice)) {
                            for (Id AccId: SalesOffAccountMap.get(salesOffice)) {
                                AccountShare acshare = new AccountShare();
                                acshare.RowCause = NSP_SalesConstants.manualRowCause;
                                acshare.UserOrGroupId = grpMember;
                                acshare.AccountAccessLevel = NSP_SalesConstants.editSharingAccess;
                                acShare.OpportunityAccessLevel = Label.NSP_OpportunityAccess;
                                acshare.AccountId = AccId;
                                accountshareList.add(acshare);
                            }
                        }
                    }
                }
            }
            if (!accountshareList.isEmpty()) {
                Database.Insert(accountshareList, false);
            }

        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_recordSharing, 'accountTeamMembersharing', ex.getMessage());
        }

    }
    /***********************************************************************************************
     * MethodName: updateAccessOnATMRemoval
     * Description : remove Sharing access for ATM members after removal
     * Params:       Map<Id,Account> newAccountMap, Map<Id,Account>oldAccountMap
     * ********************************************************************************************/
    public static void updateAccessOnATMRemoval(List < NSP_Account_Team__c > oldATMList, Map < Id, NSP_Account_Team__c > oldMap) {
        Set < Id > accountId = new Set < Id > ();
        Set < Id > ATMUser = new Set < Id > ();
        Set < String > acTeamSalesOffice = new Set < String > ();
        Map < String, String > getSalesOffice = getPicklistLabel();
        for (NSP_Account_Team__c accountTeam: oldATMList) {
            if (accountTeam.NSP_Role__c == System.Label.NSP_AccountTeamMemberRole) {
                accountId.add(accountTeam.NSP_Account__c);
            }
        }
        Map < Id, NSP_Account_Team__c > NSPTeamMap = new Map < Id, NSP_Account_Team__c > ([Select Id, NSP_Account_Team__c.NSP_Role__c, NSP_Account__c, NSP_User__c from NSP_Account_Team__c
            WHERE NSP_Account__c IN: accountId
        ]);

        List < AccountTeamMember > accountTeamMemberList = new List < AccountTeamMember > ();
        for (NSP_Account_Team__c Atm: NSPTeamMap.values()) {
            if (!oldMap.containsKey(Atm.Id)) {
                AccountTeamMember accountTeamMemberObj = new AccountTeamMember();
                accountTeamMemberObj.AccountId = Atm.NSP_Account__c;
                accountTeamMemberObj.AccountAccessLevel = NSP_IntegrationConstants.ACCOUNTACCESSLEVEL;
                accountTeamMemberObj.TeamMemberRole = NSP_IntegrationConstants.TEAMMEMBERROLE;
                accountTeamMemberObj.UserId = Atm.NSP_User__c;
                accountTeamMemberList.add(accountTeamMemberObj);
            }

        }
        // Fetching Standard ATM records 
        List < AccountTeamMember > accountTeamList = [Select UserId, AccountId from AccountTeamMember WHERE
            AccountId IN: accountId
        ];

        List < AccountShare > acShare = [Select Id, AccountAccessLevel, AccountId, RowCause, UserOrGroupId
            from accountShare WHERE AccountId IN: accountId And RowCause =: NSP_SalesConstants.manualRowCause
        ];
        // Removing Account Access for ATM Users and its related public group  

        if (!acShare.isEmpty()) {
            delete acShare;
        }
        // Deleting Standard Account Team record 
        if (!accountTeamList.isEmpty()) {
            delete accountTeamList;
        }
        // creating Standard AccountTeam Member records
        if (!accountTeamMemberList.isEmpty()) {
            Database.Insert(accountTeamMemberList, false);
        }
        Map < Id, Account > ATMAccountMap = new Map < Id, Account > ([Select Id, Name, OwnerId from account WHERE Id IN: accountId]);
        nonBPAAccountSharing(ATMAccountMap);
        accountTeamMembersharing(NSPTeamMap.values());
    }
    /***********************************************************************************************
     * MethodName: shareAccountonATMUpdate
     * Description : update Sharing access for Non-BPA members of Account on Account Owner Change
     * Params:       Map<Id,Account> newAccountMap, Map<Id,Account>oldAccountMap
     * ********************************************************************************************/
    public static void shareAccountonATMUpdate(Map < Id, NSP_Account_Team__c > newATMMap, Map < Id, NSP_Account_Team__c > oldATMMap) {
        Set < String > acTeamSalesOffice = new Set < String > ();
        Set < Id > accountIds = new Set < Id > ();
        try {
            Map < String, String > getSalesOffice = getPicklistLabel();
            for (NSP_Account_Team__c acTeam: newATMMap.values()) {
                if (acTeam.NSP_Sales_Office__c != oldATMMap.get(acTeam.Id).NSP_Sales_Office__c &&
                    oldATMMap.get(acTeam.Id).NSP_Role__c == System.Label.NSP_AccountTeamMemberRole) {
                    acTeamSalesOffice.add(getSalesOffice.get(acTeam.NSP_Sales_Office__c));
                    accountIds.add(acTeam.NSP_Account__c);
                }
            }
            Set < Id > oldATMsalesofficeGroupUsers = getgroupMembers(acTeamSalesOffice);
            List < AccountShare > oldAccountShare = [Select Id, UserOrGroupId, RowCause, AccountAccessLevel, AccountId from AccountShare
                WHERE RowCause =: NSP_SalesConstants.manualRowCause AND UserOrGroupId IN: oldATMsalesofficeGroupUsers AND AccountId IN: accountIds
            ];

            // delete sharing with old owner Sales Office Public Group 
            if (!oldAccountShare.isEmpty()) {
                delete oldAccountShare;
            }

            // share account with new ATM Sales Office Public Group
            accountTeamMembersharing(newATMMap.values());
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_recordSharing, 'shareAccountonATMUpdate', ex.getMessage());
        }

    }
    /***********************************************************************************************
     * MethodName: nonBPAOpportunitySharing
     * Description : Share Opportunity with Public Group
     * Params:       List<Opportunity> opportunityList
     * ********************************************************************************************/
    public static void nonBPAOpportunitySharing(List < Opportunity > opportunityList) {
        Set < Id > ownerIds = new Set < Id > ();
        Set < Id > bpaOwnerIds = new Set < Id > ();
        List < String > oppPublicGroup = System.Label.NSP_opportunityPublicGroup.split(',');
        Set < String > publicGroups = new Set < String > ();
        publicGroups.addAll(oppPublicGroup);
        List < OpportunityShare > OpportunityshareList = new List < OpportunityShare > ();
        Map < Id, String > ownerRoleMap = new Map < Id, String > ();

        try {
            for (Opportunity opp: opportunityList) {
                ownerIds.add(opp.OwnerId);
            }

            List < User > bpaUser = [Select Id, UserRole.Name from User WHERE Id IN: ownerIds
                And UserRole.Name =: NSP_SalesConstants.BPARole
            ];

            for (User usr: bpaUser) {
                ownerRoleMap.put(usr.Id, usr.UserRole.Name);
            }
            for (Opportunity opp: opportunityList) {
                if ((opp.StageName != NSP_SalesConstants.CLOSED_WON || opp.StageName != NSP_SalesConstants.CLOSED_LOST) &&
                    ownerRoleMap.get(opp.OwnerId) == NSP_SalesConstants.BPARole && ownerRoleMap.containsKey(opp.OwnerId)) {
                    bpaOwnerIds.add(opp.OwnerId);
                }
            }
            // Share opportunity with Channel Operations Role Users
            List < User > channelOperationUsers = [Select Id, Name, UserRole.Name from User WHERE UserRole.Name =: NSP_SalesConstants.channelOperation];
            if (!channelOperationUsers.isEmpty() && !bpaOwnerIds.isEmpty()) {
                for (Opportunity opp: opportunityList) {
                    for (User usr: channelOperationUsers) {
                        OpportunityShare opshare = new OpportunityShare();
                        opshare.RowCause = NSP_SalesConstants.manualRowCause;
                        opshare.UserOrGroupId = usr.Id;
                        opshare.OpportunityAccessLevel = NSP_SalesConstants.editSharingAccess;
                        opshare.OpportunityId = opp.Id;
                        OpportunityshareList.add(opshare);
                    }
                }
            }
            // Share opportunity with Data Science and NCS public Group
            List < Group > pgroupList = [SELECT Id, Name FROM group WHERE Name IN: publicGroups];
            if (!pgroupList.isEmpty() && !bpaOwnerIds.isEmpty()) {
                for (Opportunity opp: opportunityList) {
                    for (Group pgrp: pgroupList) {
                        OpportunityShare opshare = new OpportunityShare();
                        opshare.RowCause = NSP_SalesConstants.manualRowCause;
                        opshare.UserOrGroupId = pgrp.Id;
                        opshare.OpportunityAccessLevel = NSP_SalesConstants.editSharingAccess;
                        opshare.OpportunityId = opp.Id;
                        OpportunityshareList.add(opshare);
                    }
                }
            }
            // Share opportunity with NOn BPA User
            List < User > nonBPAUsers = getnonBPAUsers(bpaOwnerIds);
            if (!nonBPAUsers.isEmpty()) {
                for (Opportunity opp: opportunityList) {

                    for (User nonbpaUser: nonBPAUsers) {
                        OpportunityShare opshare = new OpportunityShare();
                        opshare.RowCause = NSP_SalesConstants.manualRowCause;
                        opshare.UserOrGroupId = nonbpaUser.Id;
                        opshare.OpportunityAccessLevel = NSP_SalesConstants.editSharingAccess;
                        opshare.OpportunityId = opp.Id;
                        OpportunityshareList.add(opshare);
                    }

                }
            }

            if (!OpportunityshareList.isEmpty()) {
                Database.Insert(OpportunityshareList, false);
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_recordSharing, 'nonBPAOpportunitySharing', ex.getMessage());
        }
    }
    /***********************************************************************************************
     * MethodName: shareOpportunityonUpdate
     * Description : update Sharing access on  Opportunity Owner Change
     * Params:       Map<Id,Opportunity> newAccountMap, Map<Id,Opportunity>oldAccountMap
     * ********************************************************************************************/
    public static void shareOpportunityonUpdate(Map < Id, Opportunity > newOpportunityMap, Map < Id, Opportunity > oldOpportunityMap) {
        Set < Id > oldOpportunityIds = new Set < Id > ();
        try {
            for (Opportunity opp: newOpportunityMap.values()) {
                if (opp.ownerId != oldOpportunityMap.get(opp.Id).OwnerId) {
                    oldOpportunityIds.add(opp.Id);

                }
            }
            if (!oldOpportunityIds.isEmpty()) {
                List < OpportunityShare > oldOppShare = [Select Id from OpportunityShare WHERE RowCause =: NSP_SalesConstants.manualRowCause AND OpportunityId IN: oldOpportunityIds];

                // delete sharing with old owner Sales Office Public Group 
                if (!oldOppShare.isEmpty()) {
                    delete oldOppShare;
                }
                // share Opportunity with new onwer Sales Office Public Group
                nonBPAOpportunitySharing(newOpportunityMap.values());
            }

        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_recordSharing, 'shareOpportunityonUpdate', ex.getMessage());
        }

    }

    /***********************************************************************************************
     * MethodName: getnonBPAUsers
     * Description : Method to retrieve non BPA members of Onwer Sales Office Public Group
     * Params:       Set<Id> ownerIds
     * ********************************************************************************************/
    public static List < User > getnonBPAUsers(Set < Id > ownerIds) {
        Set < String > objectOwnerOffice = new Set < String > ();
        Map < Id, String > onwerSaleofficeMap = new Map < Id, String > ();
        List < User > nonBPAUsers = new List < User > ();
        Map < Id, User > objectOwnerMap = new Map < Id, User > ([Select Id, Name, Username, NSP_Sales_Office__c, UserRole.Name
            from User WHERE Id IN: ownerIds And UserRole.Name =: NSP_SalesConstants.BPARole
        ]);
        Map < String, String > getSalesOffice = getPicklistLabel();
        for (User usr: objectOwnerMap.values()) {
            if (objectOwnerMap.containsKey(usr.Id) && usr.NSP_Sales_Office__c != null) {
                onwerSaleofficeMap.put(usr.Id, getSalesOffice.get(usr.NSP_Sales_Office__c));
                objectOwnerOffice.add(getSalesOffice.get(usr.NSP_Sales_Office__c));
            }
        }
        Set < Id > groupMemberUsers = getgroupMembers(objectOwnerOffice);
        nonBPAUsers = new List < User > ([Select Id, Name, Username, NSP_Sales_Office__c, UserRole.Name
            from User WHERE Id IN: groupMemberUsers AND(UserRole.Name !=: NSP_SalesConstants.BPARole AND UserRole.Name !=: NSP_SalesConstants.aBPARole)
        ]);

        return nonBPAUsers;
    }

    /***********************************************************************************************
     * MethodName: getgroupMembers
     * Description : Method to retrieve group members from Public Group
     * Params:       Set<String> salesOffice
     * ********************************************************************************************/
    public static Set < Id > getgroupMembers(Set < String > salesOffice) {
        Set < Id > groupIdList = new Set < Id > ();
        Set < Id > groupMemberUsers = new Set < Id > ();
        List < Group > pgroup = [SELECT id, name FROM group WHERE name IN: salesOffice];
        for (Group gp: pgroup) {
            groupIdList.add(gp.Id);
        }
        List < groupMember > groupMemberList = [Select GroupId, userOrGroupId from groupMember WHERE GroupId IN: groupIdList];
        for (groupMember gp: groupMemberList) {
            groupMemberUsers.add(gp.userOrGroupId);
        }
        return groupMemberUsers;
    }

    /***********************************************************************************************
     * MethodName: getPicklistLabel
     * Description : Method to retrieve the selected Sales Office 
     * Params:       salesOffice
     * ********************************************************************************************/
    public static Map < String, String > getPicklistLabel() {
        Map < String, String > salesOfficePicklist = new Map < String, String > ();
        Schema.SObjectType getObject = Schema.getGlobalDescribe().get(NSP_SalesConstants.SalesOfficeObject);
        Schema.DescribeSObjectResult getPicklist = getObject.getDescribe();
        Map < String, Schema.SObjectField > fields = getPicklist.fields.getMap();
        Schema.DescribeFieldResult fieldResult = fields.get(NSP_SalesConstants.SalesOffice).getDescribe();
        List < Schema.PicklistEntry > picklistMap = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal: picklistMap) {
            salesOfficePicklist.put(pickListVal.getValue(), pickListVal.getLabel());
        }
        return salesOfficePicklist;
    }


    /***********************************************************************************************
     * MethodName: getATMgroupMembers
     * Description : Method to retrieve group members from Public Group of ATM
     * Params:      Map<String,Id> salesOfficeMap
     * ********************************************************************************************/
    public static Map < String, List < Id >> getATMgroupMembers(Map < String, Id > salesOfficeMap) {
        Set < Id > groupIdList = new Set < Id > ();
        Set < Id > groupMemberUsers = new Set < Id > ();
        Map < String, List < Id >> SalesGroupsMember = New Map < String, List < Id >> ();
        Map < Id, Group > SalesGroupMap = new Map < Id, Group > ([SELECT id, name FROM group
            WHERE name IN: salesOfficeMap.KeySet()
        ]);

        Map < Id, groupMember > groupMemberList = new Map < Id, groupMember > ([SELECT GroupId, userOrGroupId FROM groupMember
            WHERE GroupId IN: SalesGroupMap.KeySet()
        ]);
        for (groupMember gp: groupMemberList.values()) {
            if (SalesGroupMap.containsKey(gp.GroupId)) {
                if (SalesGroupsMember.get(SalesGroupMap.get(gp.GroupId).Name) == null) {
                    SalesGroupsMember.put(SalesGroupMap.get(gp.GroupId).Name, new List < Id > ());
                }
                SalesGroupsMember.get(SalesGroupMap.get(gp.GroupId).Name).add(gp.userOrGroupId);
            }
        }
        return SalesGroupsMember;
    }

}