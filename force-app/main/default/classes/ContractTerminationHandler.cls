public class ContractTerminationHandler {
    // test w/ ContractTerminationHandlerTest (95%)
   private static Id contractId;

   @InvocableMethod(label='runContractTerminationHandler' description='Method to trigger call for contract termination')
   public static void runContractTerminationHandler( List<ContractTerminationRequest> requests ) {
        Map<Id,Date> contractToTerminationDates = new Map<Id,Date>();
        if ( ( requests != null ) && !requests.isEmpty() ) {
            for ( ContractTerminationRequest request : requests ) {
                contractToTerminationDates.put( request.ContractId , request.TerminationDate );
            }
        }
        ContractTerminationHandler.handleTermination( contractToTerminationDates , null , 'runContractTerminationHandler:InvocableMethod' );
   }

    public class ContractTerminationRequest {
        @InvocableVariable(label='Contract ID' required=true)
        public Id contractId;
        @InvocableVariable(label='Termination Date' required=true)
        public Date terminationDate;
    }

    public static void runContractTerminationHandler( Id localContractId , Date terminationDate , String emailAddress ) {
        Map<Id,Date> contractToTerminationDates = new Map<Id,Date>();
        Map<Id,String> contractToEmails = new Map<Id,String>();
        if ( ( localContractId != null ) && ( terminationDate != null ) ) {
            contractToTerminationDates.put( localContractId , terminationDate );
            contractToEmails.put( localContractId , emailAddress );
        }
        ContractTerminationHandler.handleTermination( contractToTerminationDates , contractToEmails , 'runContractTerminationHandler' );
    }

    private static void handleTermination(
        Map<Id,Date> contractToTerminationDates ,
        Map<Id,String> contractToEmails ,
        String methodName
        )
    {
        String userEmailAddress = null;
        try {
            if ( ( contractToTerminationDates != null ) && !contractToTerminationDates.isEmpty() ) {
                ContractTerminationHandler.contractId = new List<Id>( contractToTerminationDates.keySet() )[0];
                if ( contractToEmails != null ) {
                    userEmailAddress = contractToEmails.get( ContractTerminationHandler.contractId );
                }
                if ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) {
                    System.enqueueJob( new ContractTerminationQueue( contractToTerminationDates , contractToEmails ) );
                } else {
                    ContractTerminationHandler.constructAndSendEmail( userEmailAddress , 'Enqueue Job for Contract (Id=' + ContractTerminationHandler.contractId + ')' );
                }
            }
        } catch ( Exception e ) {
            ContractTerminationHandler.handleException( e , 'handleTermination:' + methodName );
        }
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            ContractTerminationHandler.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            ContractTerminationHandler.class.getName() ,
            methodName ,
            e
        );
        ContractTerminationHandler.sendEmail( null , methodName + ' (Contract.Id=' + ContractTerminationHandler.contractId + ')' );
    }

    public static void constructAndSendEmail( String userEmailAddress , String failureMsg ) {
        List<String> toUsers = new List<String>();
        if ( !String.isBlank( userEmailAddress ) ) {
            toUsers.add( userEmailAddress );
        } else if ( !ContractTerminationHandler.autoTerminationEmailAddresses.isEmpty() ) {
            toUsers.addAll( ContractTerminationHandler.autoTerminationEmailAddresses );
        }
        if ( !toUsers.isEmpty() ) {
            ContractTerminationHandler.sendEmail( toUsers , failureMsg );
        }
    }

    public static void sendEmail( List<String> listOfToAddresses , String failureReason ) {
        if ( String.isBlank( failureReason ) ) {
            failureReason = '';
        }
        if ( listOfToAddresses == null ) {
            listOfToAddresses = new List<String>();
        }
        Map<String,Object> inputs = new Map<String,Object>();
        if ( !ContractTerminationHandler.adminEmailAddresses.isEmpty() ) {
            listOfToAddresses.addAll( ContractTerminationHandler.adminEmailAddresses );
        }
        if ( !listOfToAddresses.isEmpty() ) {
            inputs.put( 'toEmailAddresses' , listOfToAddresses );
            inputs.put( 'emailSubject' , 'Auto Termination Process Failed' );
            inputs.put(
                'emailBody' ,
                'Termination process failed at ' + failureReason + '. Reach out to salesforcehelpdesk@insperity.com for assistance.'
            );
            Flow.Interview.Send_Email sendEmailFlow = new Flow.Interview.Send_Email( inputs );
            sendEmailFlow.start();
        }
    }

    //
    // Custom Settings
    //

    private static Contract_Termination_Settings__c settings {
        private get {
            if ( settings == null ) {
                settings = Contract_Termination_Settings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    public static List<String> adminEmailAddresses  {
        public get {
            if ( adminEmailAddresses == null ) {
                List<String> local = new List<String>();
                if ( ContractTerminationHandler.settings != null ) {
                    String rawAddresses = ContractTerminationHandler.settings.AdminEmailAddresses__c;
                    if ( String.isNotBlank( rawAddresses ) ) {
                        List<String> splitAddresses = rawAddresses.split( '\r\n' );
                        if ( ( splitAddresses != null ) && ( splitAddresses.size() > 0 ) ) {
                            local = splitAddresses;
                        }
                    }
                }
                adminEmailAddresses = local;
            }
            return adminEmailAddresses;
        }
        private set;
    }

    public static List<String> autoTerminationEmailAddresses  {
        public get {
            if ( autoTerminationEmailAddresses == null ) {
                List<String> local = new List<String>();
                if ( ContractTerminationHandler.settings != null ) {
                    String rawAddresses = ContractTerminationHandler.settings.AutoTerminationEmailAddresses__c;
                    if ( String.isNotBlank( rawAddresses ) ) {
                        List<String> splitAddresses = rawAddresses.split( '\r\n' );
                        if ( ( splitAddresses != null ) && ( splitAddresses.size() > 0 ) ) {
                            local = splitAddresses;
                        }
                    }
                }
                autoTerminationEmailAddresses = local;
            }
            return autoTerminationEmailAddresses;
        }
        private set;
    }

    public static Boolean isEnabledAutoTermination {
        public get {
            if ( isEnabledAutoTermination == null ) {
                Boolean local = False;
                if ( ContractTerminationHandler.settings != null ) {
                    local = ContractTerminationHandler.settings.IsEnabledAutoTermination__c;
                }
                isEnabledAutoTermination = local;
            }
            return isEnabledAutoTermination;
        }
        private set;
    }

}
//