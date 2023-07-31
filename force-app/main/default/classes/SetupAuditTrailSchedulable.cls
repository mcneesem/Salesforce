public with sharing class SetupAuditTrailSchedulable implements Schedulable {
    // test w/ SetupAuditTrailSchedulableTest (91%)
    private static String CLASS_NAME = ' ~ SetupAuditTrailSchedulable';
    private static final String DEFAULT_CRON_EXPRESSION = '3 3 3 * * ?';
    private static final String DEFAULT_CRON_NAME = 'SetupAuditTrailSchedulable ~ SetupAuditTrail Reporting';

    //
    // examples...
    //

    // SetupAuditTrailSchedulable.ScheduleJob();
    // SetupAuditTrailSchedulable.ScheduleJob( null );
    // SetupAuditTrailSchedulable.ScheduleJob( 4 );

    // Schedulable Interface implementation...
    public void execute( SchedulableContext context ) {
        String METHOD_NAME = 'execute';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ context=' + context );
        SetupAuditTrailQueueable.startReport();
    }

    private static String jobNamePrefix {
        private get {
            if ( jobNamePrefix == null ) {
                String local = '';
                if ( String.isNotBlank( SetupAuditTrailQueueable.sandboxName ) ) {
                    local = SetupAuditTrailQueueable.sandboxName + ': ';
                }
                jobNamePrefix = local;
            }
            return jobNamePrefix;
        }
        private set;
    }

    public static void ScheduleJob() {
        SetupAuditTrailSchedulable.ScheduleJob( null );
    }

    public static void ScheduleJob( Integer hour ) {
        // build the cron name...
        String cronJobDetailName = SetupAuditTrailSchedulable.jobNamePrefix + DEFAULT_CRON_NAME;
        // build the cron expression...
        String cronExpression = DEFAULT_CRON_EXPRESSION;
        if ( ( hour != null ) && ( hour >= 0 ) && ( hour < 24 ) ) {
            cronJobDetailName += ' @' + hour + 'hr';
            cronExpression = '47 47 ' + hour + ' * * ?';
        }
        // schedule the job...
        System.schedule(
            cronJobDetailName ,
            cronExpression ,
            new SetupAuditTrailSchedulable()
        );
    }

}
//