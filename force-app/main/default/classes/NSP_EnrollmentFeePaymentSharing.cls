// intentionally `without sharing` to prevent ~ INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, insufficient access rights on cross-reference id
public without sharing class NSP_EnrollmentFeePaymentSharing {
    // test w/ NSP_EnrollmentFeePaymentTriggerClassTest, NSP_OpportunityTeamMemberTriggerTest (81%)
    // test w/ NSP_EnrollmentFeePaymentTriggerClassTest (68%)
    // test w/ NSP_OpportunityTeamMemberTriggerTest (23%)

    // ~ EnrollmentFeePaymentTrigger
    public static void onEfpRecordInsert( List<NSP_Enrollment_Fee_Payment__c> listOfEnrollmentFee ) {
        try {
            Set<Id> opportunityIds = new Set<Id>();
            //Getting all the opportunity Ids for the efp records
            for ( NSP_Enrollment_Fee_Payment__c feepayment : listOfEnrollmentFee ) {
                opportunityIds.add( feepayment.NSP_Opportunity__c );
            }
            Map<Id,List<OpportunityTeamMember>> oppToOppTeamMembersMap = new Map<Id,List<OpportunityTeamMember>>();
            Map<Id,String> oppToSalesOfficeMap = new Map<Id,String>();
            Set<String> salesOffices = new Set<String>();
            //Getting Opportunity team members related to the opportunity ids
            List<OpportunityTeamMember> oppTeamMembers = [
                SELECT
                    OpportunityId ,
                    OpportunityTeamMember.Opportunity.StageName ,
                    OpportunityTeamMember.Opportunity.NSP_Sales_Office__c ,
                    UserId ,
                    TeamMemberRole
                FROM OpportunityTeamMember
                WHERE ( OpportunityId IN :opportunityIds )
            ];

            //Creating a map of opportunity to opportunityTeamMembers
            for ( OpportunityTeamMember oppTeamMember : oppTeamMembers ) {
                if ( oppToOppTeamMembersMap.containsKey( oppTeamMember.OpportunityId ) ) {
                    oppToOppTeamMembersMap.get( oppTeamMember.OpportunityId ).add( oppTeamMember );
                } else {
                    oppToOppTeamMembersMap.put( oppTeamMember.OpportunityId , new List<OpportunityTeamMember>{ oppTeamMember } );
                }
                oppToSalesOfficeMap.put( oppTeamMember.opportunityId , oppTeamMember.Opportunity.NSP_Sales_Office__c );
            }
            //Getting the list of sales offices to the opportunity ids
            salesOffices.addAll( oppToSalesOfficeMap.values() );
            //Getting DAs and DMs for the list of sales offices
            List<User> dADMUsersList = NSP_EnrollmentFeePaymentSharing.selectPermittedSalesOfficeUsers( salesOffices );
            //Creating a map of sales office to DA and DMs
            Map<String,List<User>> salesOfficeDADMMap = getsalesOfficeDADMMap( dADMUsersList );
            //Sharing the efp records with DA, DM related to sales office and Opportunity Team Members
            List<NSP_Enrollment_Fee_Payment__Share> efpShareList = new List<NSP_Enrollment_Fee_Payment__Share>();
            for ( NSP_Enrollment_Fee_Payment__c feepayment : listOfEnrollmentFee ) {
                String opportunityId = feepayment.NSP_Opportunity__c;
                List<OpportunityTeamMember> teamMembersByOppId = oppToOppTeamMembersMap.get( opportunityId );
                String opportunityStageName = '';
                for ( OpportunityTeamMember oppTeamMember : teamMembersByOppId ) {
                    opportunityStageName = oppTeamMember.Opportunity.StageName;
                    NSP_Enrollment_Fee_Payment__Share efpshare = NSP_EnrollmentFeePaymentSharing.createEFPSharing(
                        feePayment.Id ,
                        oppTeamMember.UserId ,
                        opportunityStageName ,
                        oppTeamMember.teamMemberRole ,
                        false
                    );
                    efpShareList.add( efpshare );
                }
                efpShareList = NSP_EnrollmentFeePaymentSharing.prepareEfpShareListOnInsert(
                    efpShareList ,
                    opportunityId ,
                    oppToSalesOfficeMap ,
                    salesOfficeDADMMap ,
                    feePayment.Id ,
                    opportunityStageName
                );
            }
            if ( !efpShareList.isEmpty() ) {
                List<Database.SaveResult> results = Database.insert( efpShareList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_EnrollmentFeePaymentSharing.class.getName() ,
                    'onEfpRecordInsert:insert' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_EnrollmentFeePaymentSharing.class.getName() ,
                'onEfpRecordInsert' ,
                e
            );
        }
    }

    // helper method to defeat sonar cognitive complexity...
    private static List<NSP_Enrollment_Fee_Payment__Share> prepareEfpShareListOnInsert(
        List<NSP_Enrollment_Fee_Payment__Share> efpShareList ,
        String opportunityId ,
        Map<Id,String> oppToSalesOfficeMap ,
        Map<String,List<User>> salesOfficeDADMMap ,
        Id feePaymentId ,
        String opportunityStageName
        )
    {
        if ( efpShareList == null ) {
            efpShareList = new List<NSP_Enrollment_Fee_Payment__Share>();
        }
        if ( ( oppToSalesOfficeMap != null ) && ( salesOfficeDADMMap != null ) ) {
            String salesOffice = oppToSalesOfficeMap.get( opportunityId );
            List<User> salesOfficeDADMUsers = salesOfficeDADMMap.get( salesOffice );
            if ( ( salesOfficeDADMUsers != null ) && !salesOfficeDADMUsers.isEmpty() ) {
                for ( User record : salesOfficeDADMUsers ) {
                    NSP_Enrollment_Fee_Payment__Share efpshare = NSP_EnrollmentFeePaymentSharing.createEFPSharing(
                        feePaymentId ,
                        record.Id ,
                        opportunityStageName ,
                        '' ,
                        true
                    );
                    efpShareList.add( efpshare );
                }
            }
        }
        return efpShareList;
    }

    // select the permitted Users for the Sales Offices...
    private static List<User> selectPermittedSalesOfficeUsers( Set<String> salesOffices ) {
        List<User> response = new List<User>();
        if ( ( NSP_EnrollmentFeePaymentSharing.efpSharingUserMap != null )
            && !NSP_EnrollmentFeePaymentSharing.efpSharingUserMap.isEmpty()
            )
        {
            List<User> salesOfficeUsers = new List<User>();
            if ( ( salesOffices != null ) && !salesOffices.isEmpty() ) {
                salesOfficeUsers = [
                    SELECT Id , Name , UserRole.Name , NSP_Sales_Office_Membership__c
                    FROM User
                    WHERE ( NSP_Sales_Office_Membership__c IN: salesOffices )
                ];
            }
            if ( ( salesOfficeUsers != null ) && !salesOfficeUsers.isEmpty() ) {
                for ( User record : salesOfficeUsers ) {
                    if ( NSP_EnrollmentFeePaymentSharing.efpSharingUserMap.containsKey( record.Id ) ) {
                        response.add( record );
                    }
                }
            }
        }
        return response;
    }

    private static Map<String,List<User>> getsalesOfficeDADMMap( List<User> dADMUsersList ) {
        Map<String,List<User>> salesOfficeDADMMap = new Map<String,List<User>>();
        for ( User record : dADMUsersList ) {
            if ( salesOfficeDADMMap.containsKey( record.NSP_Sales_Office_Membership__c ) ) {
                salesOfficeDADMMap.get( record.NSP_Sales_Office_Membership__c ).add( record );
            } else {
                salesOfficeDADMMap.put(
                    record.NSP_Sales_Office_Membership__c ,
                    new List<User>{ record }
                );
            }
        }
        return salesOfficeDADMMap;
    }

    // ~ NSP_OpportunityTeamMemberTriggerHelper
    public static void onOppTeamMemberInsert( List<OpportunityTeamMember> newList ) {
        Set<Id> opportunityIds = new Set<Id>();
        if ( newList != null ) {
            for ( OpportunityTeamMember oppTeamMemberObj : newList ) {
                opportunityIds.add( oppTeamMemberObj.OpportunityId );
            }
        }
        List<NSP_Enrollment_Fee_Payment__c> efpRecordsByOppIds = [
            SELECT Id , NSP_Opportunity__c
            FROM NSP_Enrollment_Fee_Payment__c
            WHERE ( NSP_Opportunity__c IN :opportunityIds )
        ];
        Map<Id,List<NSP_Enrollment_Fee_Payment__c>> oppIdEfpRecordsMap = new Map<Id,List<NSP_Enrollment_Fee_Payment__c>>();
        for ( NSP_Enrollment_Fee_Payment__c feePayment : efpRecordsByOppIds ) {
            if ( !oppIdEfpRecordsMap.containsKey( feePayment.NSP_Opportunity__c ) ) {
                oppIdEfpRecordsMap.put(
                    feePayment.NSP_Opportunity__c ,
                    new List<NSP_Enrollment_Fee_Payment__c>()
                );
            }
            oppIdEfpRecordsMap.get( feePayment.NSP_Opportunity__c ).add( feePayment );
        }
        List<NSP_Enrollment_Fee_Payment__Share> efpShareList = NSP_EnrollmentFeePaymentSharing.prepareEfpShareListOnMemberInsert(
            newList ,
            oppIdEfpRecordsMap
        );
        if ( ( efpShareList != null ) && !efpShareList.isEmpty() ) {
            List<Database.SaveResult> results = Database.insert( efpShareList , false );
            NSP_ErrorLogHandler.logResults(
                NSP_EnrollmentFeePaymentSharing.class.getName() ,
                'onOppTeamMemberInsert:insert' ,
                results
            );
        }
    }

    // helper method to defeat sonar cognitive complexity...
    private static List<NSP_Enrollment_Fee_Payment__Share> prepareEfpShareListOnMemberInsert(
        List<OpportunityTeamMember> newList ,
        Map<Id,List<NSP_Enrollment_Fee_Payment__c>> oppIdEfpRecordsMap
        )
    {
        List<NSP_Enrollment_Fee_Payment__Share> efpShareList = new List<NSP_Enrollment_Fee_Payment__Share>();
        if ( ( newList != null ) && ( oppIdEfpRecordsMap != null ) ) {
            for ( OpportunityTeamMember oppTeamMember : newList ) {
                if ( ( oppTeamMember.OpportunityId != null )
                    && oppIdEfpRecordsMap.containsKey( oppTeamMember.OpportunityId )
                    )
                {
                    List<NSP_Enrollment_Fee_Payment__c> relatedEfpRecords = oppIdEfpRecordsMap.get( oppTeamMember.OpportunityId );
                    if ( ( relatedEfpRecords != null ) && !relatedEfpRecords.isEmpty() ) {
                        for ( NSP_Enrollment_Fee_Payment__c feePayment : relatedEfpRecords ) {
                            NSP_Enrollment_Fee_Payment__Share efpshare = NSP_EnrollmentFeePaymentSharing.createEFPSharing(
                                feePayment.Id ,
                                oppTeamMember.UserId ,
                                oppTeamMember.Opportunity.StageName ,
                                oppTeamMember.TeamMemberRole ,
                                false
                            );
                            efpShareList.add( efpshare );
                        }
                    }
                }
            }

        }
        return efpShareList;
    }

    // ~ NSP_OpportunityTeamMemberTriggerHelper
    public static void onOppTeamMemberDelete( List<OpportunityTeamMember> oldList ) {
        List<NSP_Enrollment_Fee_Payment__Share> efpDeleteList = new List<NSP_Enrollment_Fee_Payment__Share>();
        Set<Id> opportunityIds = new Set<Id>();
        if ( ( oldList != null ) && !oldList.isEmpty() ) {
            for ( OpportunityTeamMember oppTeamMember : oldList ) {
                opportunityIds.add( oppTeamMember.OpportunityId );
            }
            Map<Id,List<NSP_Enrollment_Fee_Payment__Share>> oppIdEfpShareRecordsMap = NSP_EnrollmentFeePaymentSharing.efpSharedRecordsToProcess( opportunityIds );
            for ( OpportunityTeamMember oppTeamMember : oldList ) {
                List<NSP_Enrollment_Fee_Payment__Share> relatedEfpShareRecords = oppIdEfpShareRecordsMap.get( oppTeamMember.OpportunityId );
                for ( NSP_Enrollment_Fee_Payment__Share efpShare : relatedEfpShareRecords ) {
                    if ( oppTeamMember.UserId == efpShare.UserOrGroupId ) {
                        efpDeleteList.add( efpShare );
                    }
                }
            }
        }
        if ( !efpDeleteList.isEmpty() ) {
            List<Database.DeleteResult> results = Database.delete( efpDeleteList , false );
            NSP_ErrorLogHandler.logResults(
                NSP_EnrollmentFeePaymentSharing.class.getName() ,
                'onOppTeamMemberDelete:delete' ,
                results
            );
        }
    }

    // ~ NSP_OpportunityTriggerHelper
    public static void onOppClose( Map<Id,Opportunity> records ) {
        Set<Id> closedOpps = new Set<Id>();
        if ( ( records != null ) && !records.isEmpty() ) {
            for ( Opportunity opp : records.values() ) {
                if ( ( opp.StageName == 'Closed Won' ) || ( opp.StageName == 'Closed Lost' ) ) {
                    closedOpps.add( opp.Id );
                }
            }
        }
        Map<Id,List<NSP_Enrollment_Fee_Payment__Share>> oppIdEfpShareRecordsMap = new Map<Id,List<NSP_Enrollment_Fee_Payment__Share>>();
        if ( !closedOpps.isEmpty() ) {
            oppIdEfpShareRecordsMap = NSP_EnrollmentFeePaymentSharing.efpSharedRecordsToProcess( closedOpps );
        }
        List<NSP_Enrollment_Fee_Payment__Share> efpUpdateList = NSP_EnrollmentFeePaymentSharing.prepareEfpUpdateList( oppIdEfpShareRecordsMap );
        if ( !efpUpdateList.isEmpty() ) {
            List<Database.SaveResult> results = Database.update( efpUpdateList , false );
            NSP_ErrorLogHandler.logResults(
                NSP_EnrollmentFeePaymentSharing.class.getName() ,
                'onOppClose:update' ,
                results
            );
        }
    }

    // helper method to defeat sonar cognitive complexity...
    private static List<NSP_Enrollment_Fee_Payment__Share> prepareEfpUpdateList( Map<Id,List<NSP_Enrollment_Fee_Payment__Share>> oppIdEfpShareRecordsMap ) {
        List<NSP_Enrollment_Fee_Payment__Share> efpUpdateList = new List<NSP_Enrollment_Fee_Payment__Share>();
        if ( ( oppIdEfpShareRecordsMap != null ) && !oppIdEfpShareRecordsMap.isEmpty() ) {
            for ( List<NSP_Enrollment_Fee_Payment__Share> efpShareRecords : oppIdEfpShareRecordsMap.values() ) {
                for ( NSP_Enrollment_Fee_Payment__Share efpShareRecord : efpShareRecords ) {
                    if ( efpShareRecord.RowCause != 'Rule' ) {
                        efpShareRecord.AccessLevel = NSP_SalesConstants.readSharingAccess;
                        efpUpdateList.add( efpShareRecord );
                    }
                }
            }
        }
        return efpUpdateList;
    }

    private static NSP_Enrollment_Fee_Payment__Share createEFPSharing(
        String efpId ,
        String userorGroupId ,
        String stageName ,
        String teamMemberRole ,
        Boolean isSalesOfficeDAOrDM
        )
    {
        NSP_Enrollment_Fee_Payment__Share efpshare = new NSP_Enrollment_Fee_Payment__Share();
        Boolean isSpecificTeamMemberRole = (
            ( teamMemberRole == 'District Administrator' )
            || ( teamMemberRole == 'District Manager' )
            || ( teamMemberRole == 'Sales Support Specialist' )
        );
        // default to read-only sharing...
        efpshare.AccessLevel = NSP_SalesConstants.readSharingAccess;
        if ( ( stageName != 'Closed Won' )
            && ( stageName != 'Closed Lost' )
            && ( isSalesOfficeDAOrDM || isSpecificTeamMemberRole )
            )
        {
            efpshare.AccessLevel = NSP_SalesConstants.editSharingAccess;
        }
        efpshare.ParentId = efpId;
        efpshare.RowCause = NSP_SalesConstants.manualRowCause;
        efpshare.UserOrGroupId = userorGroupId;
        return efpshare;
    }

    private static Map<Id,List<NSP_Enrollment_Fee_Payment__Share>> efpSharedRecordsToProcess( Set<Id> opportunityIds ) {
        List<NSP_Enrollment_Fee_Payment__c> efpRecordsByOppIds = [
            SELECT Id , NSP_Opportunity__c
            FROM NSP_Enrollment_Fee_Payment__c
            WHERE ( NSP_Opportunity__c IN :opportunityIds )
        ];
        List<NSP_Enrollment_Fee_Payment__Share> efpShareRecordsByEfpIds = [
            SELECT Id , ParentId , UserOrGroupId , RowCause
            FROM NSP_Enrollment_Fee_Payment__Share
            WHERE ( ParentId IN :efpRecordsByOppIds )
        ];
        Map<Id,List<NSP_Enrollment_Fee_Payment__Share>> oppIdEfpShareRecordsMap = new Map<Id,List<NSP_Enrollment_Fee_Payment__Share>>();
        Map<Id,List<NSP_Enrollment_Fee_Payment__Share>> recordIdShareRecordsMap = new Map<Id,List<NSP_Enrollment_Fee_Payment__Share>>();
        for ( NSP_Enrollment_Fee_Payment__Share feePaymentShare : efpShareRecordsByEfpIds ) {
            if ( !recordIdShareRecordsMap.containsKey( feePaymentShare.ParentId ) ) {
                recordIdShareRecordsMap.put(
                    feePaymentShare.ParentId ,
                    new List<NSP_Enrollment_Fee_Payment__Share>()
                );
            }
            recordIdShareRecordsMap.get( feePaymentShare.ParentId ).add( feePaymentShare );
        }
        for ( NSP_Enrollment_Fee_Payment__c feePayment : efpRecordsByOppIds ) {
            if ( !oppIdEfpShareRecordsMap.containsKey( feePayment.NSP_Opportunity__c ) ) {
                oppIdEfpShareRecordsMap.put(
                    feePayment.NSP_Opportunity__c ,
                    new List<NSP_Enrollment_Fee_Payment__Share>()
                );
            }
            oppIdEfpShareRecordsMap.get( feePayment.NSP_Opportunity__c ).addAll( recordIdShareRecordsMap.get( feePayment.Id ) );
        }
        return oppIdEfpShareRecordsMap;
    }

    private static Map<Id,User> efpSharingUserMap {
        private get {
            if ( efpSharingUserMap == null ) {
                efpSharingUserMap = CustomPermissionController.getPermittedUsersMap( 'Enrollment_Fee_Payment_Edit_Sharing' );
            }
            return efpSharingUserMap;
        }
        private set;
    }

}
//