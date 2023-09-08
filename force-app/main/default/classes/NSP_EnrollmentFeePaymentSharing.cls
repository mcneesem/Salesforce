public class NSP_EnrollmentFeePaymentSharing
{
    public static void onEfpRecordInsert(List<NSP_Enrollment_Fee_Payment__c> listOfEnrollmentFee)
    {
        Set<id> opportunityIds=new Set<id>();
        List<NSP_Enrollment_Fee_Payment__Share> efpShareList = new List<NSP_Enrollment_Fee_Payment__Share>();

        try{
            //Getting all the opportunity Ids for the efp records
            for(NSP_Enrollment_Fee_Payment__c feepayment : listOfEnrollmentFee){
                opportunityIds.add(feepayment.NSP_Opportunity__c);
            }
            Map<Id, List<OpportunityTeamMember>> oppToOppTeamMembersMap = new Map<Id, List<OpportunityTeamMember>>();
            Map<Id, String> oppToSalesOfficeMap = new Map<Id, String>();
            Map<String, List<User>> salesOfficeDADMMap = new Map<String, List<User>>();
            Set<String> salesOffices = new Set<String>();

            //Getting Opportunity team members related to the opportunity ids
            List<OpportunityTeamMember> oppTeamMembers = [SELECT OpportunityId, OpportunityTeamMember.Opportunity.StageName, OpportunityTeamMember.Opportunity.NSP_Sales_Office__c, UserId, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId IN:opportunityIds];
            
            //Creating a map of opportunity to opportunityTeamMembers
            for(OpportunityTeamMember oppTeamMember : oppTeamMembers)
            {
                if(oppToOppTeamMembersMap.containsKey(oppTeamMember.OpportunityId)){
                    oppToOppTeamMembersMap.get(oppTeamMember.OpportunityId).add(oppTeamMember);
                } else {
                    oppToOppTeamMembersMap.put(oppTeamMember.OpportunityId, new List<OpportunityTeamMember> {oppTeamMember});
                }
                oppToSalesOfficeMap.put(oppTeamMember.opportunityId, oppTeamMember.Opportunity.NSP_Sales_Office__c);
            }
			
            //Getting the list of sales offices to the opportunity ids
            salesOffices.addAll(oppToSalesOfficeMap.values());

            //Getting DAs and DMs for the list of sales offices
            List<User> dADMUsers = [SELECT Id, Name, Userrole.Name, NSP_Sales_Office_Membership__c from user where NSP_Sales_Office_Membership__c IN: salesOffices and Userrole.Name IN ('District Administrator', 'District Manager')];
            
            //Creating a map of sales office to DA and DMs
            for(User user : dADMUsers)
            {
                if(salesOfficeDADMMap.containsKey(user.NSP_Sales_Office_Membership__c)){
                    salesOfficeDADMMap.get(user.NSP_Sales_Office_Membership__c).add(user);
                } else {
                    salesOfficeDADMMap.put(user.NSP_Sales_Office_Membership__c, new List<User> {user});
                }
            }
            
            //Sharing the efp records with DA, DM related to sales office and Opportunity Team Members
            for(NSP_Enrollment_Fee_Payment__c feepayment : listOfEnrollmentFee){
                String opportunityId = feepayment.NSP_Opportunity__c;
                List<OpportunityTeamMember> teamMembersByOppId = oppToOppTeamMembersMap.get(opportunityId);
                String opportunityStageName = '';
                
                for(OpportunityTeamMember oppTeamMember : teamMembersByOppId)
                {
                    opportunityStageName = oppTeamMember.Opportunity.StageName;
                    NSP_Enrollment_Fee_Payment__Share efpshare = createEFPSharing(feePayment.Id, oppTeamMember.UserId, opportunityStageName, oppTeamMember.teamMemberRole, false);
                    efpShareList.add(efpshare);
                }

                String salesOffice = oppToSalesOfficeMap.get(opportunityId);
                List<User> salesOfficeDADMUsers = salesOfficeDADMMap.get(salesOffice);

                for(User user : salesOfficeDADMUsers)
                {
                    NSP_Enrollment_Fee_Payment__Share efpshare = createEFPSharing(feePayment.Id, user.Id, opportunityStageName, '', true);
                    efpShareList.add(efpshare);
                }
            }
    
            if(!efpShareList.isEmpty()){                
                Database.insert(efpShareList,false);
            }
            
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_EnrollmentFeePaymentTriggerClass', 'efpRecordSharing', ex.getMessage());
        }
    }

    public static void onOppTeamMemberInsert(List<OpportunityTeamMember> newList)
    {
        Set<Id> opportunityIds=new Set<Id>();

        for(OpportunityTeamMember oppTeamMemberObj : newList) {
            opportunityIds.add(oppTeamMemberObj.OpportunityId);
        }

        List<NSP_Enrollment_Fee_Payment__c> efpRecordsByOppIds = [SELECT Id, NSP_Opportunity__c FROM NSP_Enrollment_Fee_Payment__c WHERE NSP_Opportunity__c IN:opportunityIds];
        List<NSP_Enrollment_Fee_Payment__Share> efpShareList = new List<NSP_Enrollment_Fee_Payment__Share>();
        Map<Id, List<NSP_Enrollment_Fee_Payment__c>> oppIdEfpRecordsMap = new Map<Id, List<NSP_Enrollment_Fee_Payment__c>>();

        for(NSP_Enrollment_Fee_Payment__c feePayment : efpRecordsByOppIds)
        {
            if(oppIdEfpRecordsMap.containsKey(feePayment.NSP_Opportunity__c)){
                oppIdEfpRecordsMap.get(feePayment.NSP_Opportunity__c).add(feePayment);
            } else {
                oppIdEfpRecordsMap.put(feePayment.NSP_Opportunity__c, new List<NSP_Enrollment_Fee_Payment__c> {feePayment});
            }
        }
        
        for(OpportunityTeamMember oppTeamMember : newList) {
            List<NSP_Enrollment_Fee_Payment__c> relatedEfpRecords = oppIdEfpRecordsMap.get(oppTeamMember.OpportunityId);

            for(NSP_Enrollment_Fee_Payment__c feePayment : relatedEfpRecords)
            {
                NSP_Enrollment_Fee_Payment__Share efpshare = createEFPSharing(feePayment.Id, oppTeamMember.UserId, oppTeamMember.Opportunity.StageName, oppTeamMember.TeamMemberRole, false);
                efpShareList.add(efpshare);
            }
        }
    
        if(!efpShareList.isEmpty()){
            Database.insert(efpShareList,false);
        }
    }

    public static void onOppTeamMemberDelete(List<OpportunityTeamMember> oldList)
    {
        Set<Id> opportunityIds=new Set<Id>();
        for(OpportunityTeamMember oppTeamMember : oldList) {
            opportunityIds.add(oppTeamMember.OpportunityId);
        }

        Map<Id, List<NSP_Enrollment_Fee_Payment__Share>> oppIdEfpShareRecordsMap = efpSharedRecordsToProcess(opportunityIds);

        List<NSP_Enrollment_Fee_Payment__Share> efpDeleteList = new List<NSP_Enrollment_Fee_Payment__Share>();
        
        for(OpportunityTeamMember oppTeamMember : oldList) {
            List<NSP_Enrollment_Fee_Payment__Share> relatedEfpShareRecords = oppIdEfpShareRecordsMap.get(oppTeamMember.OpportunityId);

            for(NSP_Enrollment_Fee_Payment__Share efpShare : relatedEfpShareRecords)
            {
                if(oppTeamMember.UserId == efpShare.UserOrGroupId)
                {
                    efpDeleteList.add(efpShare);  
                }
            }
        }
        
        if(!efpDeleteList.isEmpty()){                
            Database.delete(efpDeleteList,false);
        }
    }

    public static void onOppClose(Map<Id, Opportunity> opportunities)
    {
        Set<Id> closedOpps = new Set<Id>();

        for(Opportunity opp : opportunities.values())
        {
            if(opp.StageName == 'Closed Won' || opp.StageName == 'Closed Lost')
            {
                closedOpps.add(opp.Id);
            }
        }


        //SOQL Fix 
        Map<Id, List<NSP_Enrollment_Fee_Payment__Share>> oppIdEfpShareRecordsMap = new Map<Id, List<NSP_Enrollment_Fee_Payment__Share>>();
        if(closedOpps.size() > 0){
            oppIdEfpShareRecordsMap = efpSharedRecordsToProcess(closedOpps);
        }

        List<NSP_Enrollment_Fee_Payment__Share> efpUpdateList = new List<NSP_Enrollment_Fee_Payment__Share>();
        //SOQL Fix 
        if(oppIdEfpShareRecordsMap.size() > 0){
        for(List<NSP_Enrollment_Fee_Payment__Share> efpShareRecords : oppIdEfpShareRecordsMap.values()) {
            for(NSP_Enrollment_Fee_Payment__Share efpShareRecord : efpShareRecords)
            {
                if(efpShareRecord.RowCause != 'Rule')
                {
                    efpShareRecord.AccessLevel = NSP_SalesConstants.readSharingAccess;
            	    efpUpdateList.add(efpShareRecord);
                }
            }
        }
        }
        if(!efpUpdateList.isEmpty()){                
            Database.update(efpUpdateList,false);
        }
    }
    
    public static NSP_Enrollment_Fee_Payment__Share createEFPSharing(String efpId, String userorGroupId, String stageName, String teamMemberRole, Boolean isSalesOfficeDAOrDM){
        
        NSP_Enrollment_Fee_Payment__Share efpshare= new NSP_Enrollment_Fee_Payment__Share();

        if((stageName != 'Closed Won' && stageName != 'Closed Lost') && (isSalesOfficeDAOrDM || (teamMemberRole == 'District Administrator' || teamMemberRole == 'District Manager' || teamMemberRole == 'Sales Support Specialist')))
        {
            efpshare.AccessLevel = NSP_SalesConstants.editSharingAccess;
        }
        else
        {
            efpshare.AccessLevel = NSP_SalesConstants.readSharingAccess;
        }
        
        efpshare.ParentId = efpId;
        efpshare.RowCause = NSP_SalesConstants.manualRowCause;
        efpshare.UserOrGroupId = userorGroupId;
        return efpshare;
    }
    
    public static Map<Id, List<NSP_Enrollment_Fee_Payment__Share>> efpSharedRecordsToProcess(Set<Id> opportunityIds)
    {
        List<NSP_Enrollment_Fee_Payment__c> efpRecordsByOppIds = [SELECT Id, NSP_Opportunity__c FROM NSP_Enrollment_Fee_Payment__c WHERE NSP_Opportunity__c IN:opportunityIds];
        List<NSP_Enrollment_Fee_Payment__Share> efpShareRecordsByEfpIds = [SELECT Id, ParentId, UserOrGroupId, RowCause FROM NSP_Enrollment_Fee_Payment__Share WHERE ParentId IN:efpRecordsByOppIds];
        
        Map<Id, List<NSP_Enrollment_Fee_Payment__Share>> oppIdEfpShareRecordsMap = new Map<Id, List<NSP_Enrollment_Fee_Payment__Share>>();
        Map<Id, List<NSP_Enrollment_Fee_Payment__Share>> recordIdShareRecordsMap = new Map<Id, List<NSP_Enrollment_Fee_Payment__Share>>();
        
        for(NSP_Enrollment_Fee_Payment__Share feePaymentShare : efpShareRecordsByEfpIds)
        {
            if(recordIdShareRecordsMap.containsKey(feePaymentShare.ParentId)){
                recordIdShareRecordsMap.get(feePaymentShare.ParentId).add(feePaymentShare);
            } else {
                recordIdShareRecordsMap.put(feePaymentShare.ParentId, new List<NSP_Enrollment_Fee_Payment__Share> {feePaymentShare});
            }
        }
        
        for(NSP_Enrollment_Fee_Payment__c feePayment : efpRecordsByOppIds)
        {
            if(oppIdEfpShareRecordsMap.containsKey(feePayment.NSP_Opportunity__c)){
                oppIdEfpShareRecordsMap.get(feePayment.NSP_Opportunity__c).addAll(recordIdShareRecordsMap.get(feePayment.Id));
            } else {
                oppIdEfpShareRecordsMap.put(feePayment.NSP_Opportunity__c, new List<NSP_Enrollment_Fee_Payment__Share>(recordIdShareRecordsMap.get(feePayment.Id)));
            }
        }

        return oppIdEfpShareRecordsMap;
    }
}