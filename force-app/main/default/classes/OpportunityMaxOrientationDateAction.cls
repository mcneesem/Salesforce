// @description Populates Opportunity.Max_Orientation_Date__c asynchronously via a
// Queueable enqueued with a randomized delay, gated by OpportunityTriggerSettings__c.
// See Custom Setting: OpportunityTriggerSettings__c
public with sharing class OpportunityMaxOrientationDateAction implements Queueable {
    // test w/ OpportunityMaxOrientationDateActionTest

    //
    // Invocable
    //

    // @description Flow entry point that collects Opportunity/date pairs and enqueues the async update.
    // @param inputs Flow-supplied Opportunity Id and Max Orientation Date pairs.
    // @throws Exception details are logged through NSP_ErrorLogHandler.
    @InvocableMethod(label='Opportunity Max Orientation Date' description='This method populates the max orientation date on the given Opportunity')
    public static void invoke( List<FlowInput> inputs ) {
        try {
            Map<Id,Date> maxOrientationDateByOpportunityId = new Map<Id,Date>();
            if ( ( inputs != null ) && !inputs.isEmpty() ) {
                for ( FlowInput input : inputs ) {
                    if ( ( input != null ) && ( input.opportunitytId != null ) ) {
                        maxOrientationDateByOpportunityId.put( input.opportunitytId , input.maxOrientationDate );
                    }
                }
            }
            OpportunityMaxOrientationDateAction.enqueueJob( maxOrientationDateByOpportunityId );
        } catch ( Exception e ) {
            OpportunityMaxOrientationDateAction.handleException( e , 'invoke' );
        }
    }

    public class FlowInput {
        @InvocableVariable(label='Opportunity Id' required=true)
        public String opportunitytId;
        @InvocableVariable(label='Max Orientation Date')
        public Date maxOrientationDate;
    }

    //
    // Queueable
    //

    private Map<Id,Date> maxOrientationDateByOpportunityId = null;

    private OpportunityMaxOrientationDateAction( Map<Id,Date> payload ) {
        this.maxOrientationDateByOpportunityId = payload;
    }

    private static Set<Id> opportunityIdsEnqueued {
        private get {
            if ( opportunityIdsEnqueued == null ) {
                opportunityIdsEnqueued = new Set<Id>();
            }
            return opportunityIdsEnqueued;
        }
        private set;
    }

    // @description Enqueues the Queueable when the setting is enabled and governor headroom exists,
    // excluding Opportunity Ids already enqueued within the same Apex transaction.
    // @param payload Max Orientation Date keyed by Opportunity Id.
    private static void enqueueJob( Map<Id,Date> payload ) {
        if ( OpportunityMaxOrientationDateAction.isEnabledQueueable
            && !System.isQueueable() // prevent AsyncExceptions...
            && ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) // prevent LimitExceptions...
            && ( payload != null )
            && !payload.isEmpty()
            )
        {
            // exclude any Opportunity.Id values that were previously enqueued within the same Apex Transaction...
            Map<Id,Date> filteredPayload = new Map<Id,Date>();
            for ( Id opportunityId : payload.keySet() ) {
                if ( !OpportunityMaxOrientationDateAction.opportunityIdsEnqueued.contains( opportunityId ) ) {
                    filteredPayload.put( opportunityId , payload.get( opportunityId ) );
                }
            }
            if ( !filteredPayload.isEmpty() ) {
                // track all enqueued Opportunity.Id values to prevent re-enqueue within the same Apex Transaction...
                OpportunityMaxOrientationDateAction.opportunityIdsEnqueued.addAll( filteredPayload.keySet() );
                // randomize delay to further defend against the double-DML found within our Opportunity/Account record-triggered logic...
                Integer delay = Math.mod(
                    System.now().millisecond() ,
                    OpportunityMaxOrientationDateAction.delayMinutes
                );
                // maintain single location where the operations of class is enqueued within our code base...
                System.enqueueJob(
                    new OpportunityMaxOrientationDateAction(
                        filteredPayload
                    ) ,
                    delay
                );
            }
        }
    }

    // @description Queueable execution entry point; re-validates the enable gate before updating.
    // @param context Queueable execution context.
    public void execute( QueueableContext context ) {
        if ( OpportunityMaxOrientationDateAction.isEnabledQueueable
            && ( this.maxOrientationDateByOpportunityId != null )
            && !this.maxOrientationDateByOpportunityId.isEmpty()
            )
        {
            OpportunityMaxOrientationDateAction.populateMaxOrientationDate( this.maxOrientationDateByOpportunityId );
        }
    }

    //
    // Custom Settings
    //

    private static OpportunityTriggerSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = OpportunityTriggerSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabledQueueable {
        private get {
            if ( isEnabledQueueable == null ) {
                Boolean local = false;
                if ( OpportunityMaxOrientationDateAction.settings != null ) {
                    local = OpportunityMaxOrientationDateAction.settings.IsEnabledQueueable__c;
                }
                isEnabledQueueable = local;
            }
            return isEnabledQueueable;
        }
        private set;
    }

    private static Integer delayMinutes {
        private get {
            if ( delayMinutes == null ) {
                Integer local = 1;
                if ( ( OpportunityMaxOrientationDateAction.settings != null )
                    && ( OpportunityMaxOrientationDateAction.settings.DelayMinutes__c != null )
                    )
                {
                    local = OpportunityMaxOrientationDateAction.settings.DelayMinutes__c.intValue();
                }
                // step size must be positive...
                if ( local < 1 ) {
                    local = 1;
                }
                // step size must be less than or equal to 10...
                if ( local > 10 ) {
                    local = 10;
                }
                delayMinutes = local;
            }
            return delayMinutes;
        }
        private set;
    }

    //
    // Internal Operation
    //

    // @description Updates Max_Orientation_Date__c only on Opportunities whose value actually changed.
    // @param maxOrientationDateByOpportunityId Target Max Orientation Date keyed by Opportunity Id.
    private static void populateMaxOrientationDate( Map<Id,Date> maxOrientationDateByOpportunityId ) {
        if ( ( maxOrientationDateByOpportunityId != null )
            && !maxOrientationDateByOpportunityId.isEmpty()
            )
        {
            List<Opportunity> records = [
                SELECT Id , Max_Orientation_Date__c
                FROM Opportunity
                WHERE ( Id IN :maxOrientationDateByOpportunityId.keySet() )
                WITH USER_MODE
            ];
            List<Opportunity> dmlRecords = new List<Opportunity>();
            if ( ( records != null ) && !records.isEmpty() ) {
                for ( Opportunity record : records ) {
                    if ( maxOrientationDateByOpportunityId.containsKey( record.Id ) ) {
                        Date max = maxOrientationDateByOpportunityId.get( record.Id );
                        if ( record.Max_Orientation_Date__c != max ) {
                            record.Max_Orientation_Date__c = max;
                            dmlRecords.add( record );
                        }
                    }
                }
            }
            if ( !dmlRecords.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( dmlRecords , false , AccessLevel.USER_MODE );
                NSP_ErrorLogHandler.logResults(
                    OpportunityMaxOrientationDateAction.class.getName() ,
                    'populateMaxOrientationDate' ,
                    results
                );
            }
        }
    }

    // for test code coverage only...
    @TestVisible
    private static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            OpportunityMaxOrientationDateAction.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            OpportunityMaxOrientationDateAction.class.getName() ,
            methodName ,
            e
        );
    }

}
//