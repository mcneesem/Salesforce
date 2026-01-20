public class NSP_TerminationForm_Batch implements ISelfSchedulable , Schedulable , Callable, IJobRunnable, Database.Batchable<SObject> , Database.Stateful {
    // test w/ NSP_TerminationForm_Batch_Test (88%)

    private List<String> ccEmailAddressList = new List<String>();

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_TerminationForm_Batch() {
    }

    //
    // ISelfSchedulable
    //

    // runs M-F at 3:45pm central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_TerminationForm_Batch ~ process the termination form records and send the notification email ~ M-F at 3:45 PM' + suffix ,
            '0 45 15 ? * MON-FRI *' ,
            new NSP_TerminationForm_Batch()
        );
    }

    //
    // Scheduleable
    //

    public void execute( SchedulableContext sc ) {
        this.call( 'run' , null );
    }

    //
    // Callable
    //

    public Object call( String action , Map<String,Object> args ) {
        Object response = null;
        if ( action == 'run' ) {
            response = this.run();
        }
        return response;
    }

    //
    // IJobRunnable
    //

    public Id run() {
        return Database.executeBatch( new NSP_TerminationForm_Batch() , 100 );
    }

    //
    // Batchable
    //
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator(
            [
                SELECT
                Id ,
                Name ,
                NSP_Last_Date_Wages_Paid_Through__c ,
                NSP_Status__c ,
                NSP_Term_Code__c ,
                NSP_Client_Term_Date__c ,
                NSP_Term_Reason__c ,
                Approval_Date__c ,
                NSP_Number_of_Active_Employees__c ,
                NSP_Benefit_Termination_Date__c ,
                NSP_Project_Task__r.pse__Project__r.pse__Account__c ,
                NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name ,
                NSP_Project_Task__r.pse__Project__r.pse__Account__r.NSP_AIMS_Client__c ,
                NSP_Project_Task__r.pse__Project__r.pse__Project_Status__c
                FROM NSP_Termination_Form__c
                WHERE (
                    ( Approval_Date__c > :NSP_TerminationForm_Batch.dateBefore )
                    AND ( Approval_Date__c < :NSP_TerminationForm_Batch.dateAfter )
                    AND ( NSP_Status__c = 'Term Team Approved' )
                )
            ]
        );
    }

    public void execute( Database.BatchableContext bc , List<NSP_Termination_Form__c> terminationsList ) {
        try {
            Set<Id> relatedAccoutIdSet = new Set<Id>();
            if ( ( terminationsList != null ) && !terminationsList.isEmpty() ) {
                for ( NSP_Termination_Form__c termination : terminationsList ) {
                    if ( ( termination != null )
                        && ( termination.NSP_Project_Task__r != null )
                        && ( termination.NSP_Project_Task__r.pse__Project__r != null )
                        && ( termination.NSP_Project_Task__r.pse__Project__r.pse__Account__c != null )
                        )
                    {
                        relatedAccoutIdSet.add( termination.NSP_Project_Task__r.pse__Project__r.pse__Account__c );
                    }
                }
            }
            Set<String> emailIdSet = new Set<String>();
            if ( !relatedAccoutIdSet.isEmpty() ) {
                for ( NSP_Account_Team__c AccTeamMember : [
                            SELECT Id, NSP_Role__c, NSP_Account__c, NSP_Email__c
                            FROM NSP_Account_Team__c
                            WHERE (
                                NSP_Account__c IN :relatedAccoutIdSet
                                AND NSP_Role__c IN :NSP_TerminationForm_Batch.accountTeamRoles
                            )
                        ]
                    )
                {
                    if ( AccTeamMember.NSP_Email__c != null ) {
                        emailIdSet.add( AccTeamMember.NSP_Email__c );
                    }
                }
            }
            ccEmailAddressList.addAll( emailIdSet );
            ccEmailAddressList.addAll( NSP_TerminationForm_Batch.ccAddressList);
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_TerminationForm_Batch.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    public void finish( Database.BatchableContext bc ) {
        if ( String.isNotBlank( System.Label.NSP_TerminationFormBatchGenericToAddress )
            && EmailDeliverabilityController.isEnabledOutbound
            )
        {
            try {
                EmailTemplate emailTemplate = [
                    SELECT Id , Body
                    FROM EmailTemplate
                    WHERE ( DeveloperName = 'NSP_Termination_Form_Email_Template' )
                ];
                List<String> toEmailAddressList = System.Label.NSP_TerminationFormBatchGenericToAddress.split( ',' );
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses( toEmailAddressList );
                email.setSaveAsActivity( false );
                email.setTemplateId( emailTemplate.Id );
                email.setTargetObjectId( userinfo.getUserId() );
                email.setCcAddresses( ccEmailAddressList );
                if ( NSP_TerminationForm_Batch.orgWideEmailAddressId != null) {
                    email.setOrgWideEmailAddressId( NSP_TerminationForm_Batch.orgWideEmailAddressId );
                }
                if ( !Test.isRunningTest() ) {
                    Messaging.sendEmail( new Messaging.SingleEmailMessage[]{ email } );
                }
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    NSP_TerminationForm_Batch.class.getName() ,
                    'finish' ,
                    e
                );
            }
        }
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a Scheduled job...
    //

    private static TerminationFormBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = TerminationFormBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    // translates soqlDaysBeforeLimit into a specific Date value...
    public static Date dateBefore {
        public get {
            if ( dateBefore == null ) {
                dateBefore = System.today().addDays( -1 * NSP_TerminationForm_Batch.soqlDaysBeforeLimit );
            }
            return dateBefore;
        }
        private set;
    }

    // how far before (in days) should be terminated???
    private static Integer soqlDaysBeforeLimit {
        private get {
            if ( soqlDaysBeforeLimit == null ) {
                Integer local = 90;
                if ( ( NSP_TerminationForm_Batch.settings != null )
                    && ( NSP_TerminationForm_Batch.settings.SoqlDaysBeforeLimit__c != null )
                   )
                {
                    local = NSP_TerminationForm_Batch.settings.SoqlDaysBeforeLimit__c.intValue();
                }
                // limit must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                soqlDaysBeforeLimit = local;
            }
            return soqlDaysBeforeLimit;
        }
        private set;
    }

    // translates soqlDaysAfterLimit into a specific Date value...
    public static Date dateAfter {
        public get {
            if ( dateAfter == null ) {
                dateAfter = System.today().addDays( 1 * NSP_TerminationForm_Batch.soqlDaysAfterLimit );
            }
            return dateAfter;
        }
        private set;
    }

    // how far after (in days) should be terminated???
    private static Integer soqlDaysAfterLimit {
        private get {
            if ( soqlDaysAfterLimit == null ) {
                Integer local = 90;
                if ( ( NSP_TerminationForm_Batch.settings != null )
                    && ( NSP_TerminationForm_Batch.settings.SoqlDaysAfterLimit__c != null )
                   )
                {
                    local = NSP_TerminationForm_Batch.settings.SoqlDaysAfterLimit__c.intValue();
                }
                // limit must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                soqlDaysAfterLimit = local;
            }
            return soqlDaysAfterLimit;
        }
        private set;
    }

    private static List<String> accountTeamRoles {
        private get {
            if ( accountTeamRoles == null ) {
                List<String> local = new List<String>();
                if ( NSP_TerminationForm_Batch.settings != null ) {
                    String rawAccountTeamRoles = NSP_TerminationForm_Batch.settings.Account_Team_Roles__c;
                    if ( String.isNotBlank( rawAccountTeamRoles ) ) {
                        List<String> splitAccountTeamRoles = rawAccountTeamRoles.split( ';' );
                        if ( ( splitAccountTeamRoles != null ) && ( splitAccountTeamRoles.size() > 0 ) ) {
                            local = splitAccountTeamRoles;
                        }
                    }
                }
                accountTeamRoles = local;
            }
            return accountTeamRoles;
        }
        private set;
    }

    private static List<String> ccAddressList {
        private get {
            if ( ccAddressList == null ) {
                List<String> local = new List<String>();
                if ( NSP_TerminationForm_Batch.settings != null ) {
                    String rawCcAddresses =  NSP_TerminationForm_Batch.settings.CcAddresses__c;
                    if ( String.isNotBlank( rawCcAddresses ) ) {
                        List<String> splitCcAddresses = rawCcAddresses.split( '\r\n' );
                        if ( ( splitCcAddresses != null ) && ( splitCcAddresses.size() > 0 ) ) {
                            local = splitCcAddresses;
                        }
                    }
                }
                ccAddressList = local;
            }
            return ccAddressList;
        }
        private set;
    }

    private static Id orgWideEmailAddressId {
        private get {
            if ( orgWideEmailAddressId == null ) {
                Id local = null;
                if ( ( NSP_TerminationForm_Batch.settings != null )
                    && String.isNotBlank( NSP_TerminationForm_Batch.settings.OrgWideEmailAddressId__c )
                )
                {
                    local = NSP_TerminationForm_Batch.settings.OrgWideEmailAddressId__c;
                }
                orgWideEmailAddressId = local;
            }
            return orgWideEmailAddressId;
        }
        private set;
    }

}
//