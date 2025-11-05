public with sharing class ProjectPercentageCompleteQueueable implements Queueable {
    // test w/ ProjectPercentageCompleteQueueableTest (90%)

    //
    // public entry points...
    //

    public static void enqueueJob( Set<Id> local ) {
        if ( local != null ) {
            ProjectPercentageCompleteQueueable.enqueueJob( new List<Id>( local ) );
        }
    }

    public static void enqueueJob( List<Id> local ) {
        if ( ProjectPercentageCompleteQueueable.isEnabled
            && ( local != null )
            && ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() )
            )
        {
            System.enqueueJob( new ProjectPercentageCompleteQueueable( local ) );
        }
    }

    //
    // Queueable
    //

    private List<Id> projectIds = null;

    private ProjectPercentageCompleteQueueable( List<Id> local ) {
        if ( local != null ) {
            this.projectIds = local;
        }
    }

    public void execute( QueueableContext context ) {
        if ( ProjectPercentageCompleteQueueable.isEnabled
            && ( this.projectIds != null )
            )
        {
            if ( !this.projectIds.isEmpty() ) {
                Id projectId = this.projectIds.remove( 0 ); // remove top projectId for each link in the queueable chain...
                this.updateProjectPercentageComplete( projectId );
            }
            if ( !this.projectIds.isEmpty() ) {
                System.enqueueJob( new ProjectPercentageCompleteQueueable( this.projectIds ) ); // chain new queueable job for remaining projectIds...
            }
        }
    }

    private void updateProjectPercentageComplete( Id projectId ) {
        try {
            if ( projectId != null ) {
                AggregateResult[] groupedResults = [
                    SELECT
                        SUM(NSP_PercentageCompleteFormula__c) ,
                        COUNT(Id) ,
                        pse__Project__c
                    FROM pse__Project_Task__c
                    WHERE (
                        ( pse__Project__c = :projectId )
                        AND (
                            ( pse__Status__c != :NSP_ServiceConstants.PROJECT_TASK_CANCELLED )
                            OR ( pse__Status__c != :NSP_ServiceConstants.PROJECTSTATUSCOMPLETED )
                        )
                    )
                    GROUP BY pse__Project__c
                ];
                // select the current record for percent complete comparions...
                List<pse__Proj__c> currentRecords = [
                    SELECT
                        Id ,
                        NSP_Project_Complete__c ,
                        TemplateName__c ,
                        Project_Implementer__c ,
                        pse__End_Date__c
                    FROM pse__Proj__c
                    WHERE ( Id = :projectId )
                ];
                pse__Proj__c currentRecord = null;
                if ( ( currentRecords != null ) && !currentRecords.isEmpty() ) {
                    currentRecord = currentRecords[0];
                }
                Boolean isUpdateRestricted = false;
                Decimal currentPercentComplete = null;
                if ( currentRecord != null ) {
                    currentPercentComplete = currentRecord.NSP_Project_Complete__c;
                    // Prevent DmlExceptions: FIELD_CUSTOM_VALIDATION_EXCEPTION: Please enter the value for End Date
                    isUpdateRestricted = (
                        ( currentRecord.TemplateName__c == 'ITA-Implementation' )
                        && String.isNotBlank( currentRecord.Project_Implementer__c )
                        && ( currentRecord.pse__End_Date__c == null )
                    );
                }
                // conditionally calculate new percent complete values...
                pse__Proj__c record = this.calculateProjectPercentageComplete(
                    groupedResults ,
                    projectId ,
                    currentPercentComplete
                );
                // only update the project when the current percent is blank, or when the new percent is significantly changed...
                if ( ( record != null ) && !isUpdateRestricted ) {
                    List<Database.SaveResult> results = Database.update( new List<pse__Proj__c>{ record } , false );
                    NSP_ErrorLogHandler.logResults(
                        ProjectPercentageCompleteQueueable.class.getName() ,
                        'updateProjectPercentageComplete:update' ,
                        results
                    );
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                ProjectPercentageCompleteQueueable.class.getName() ,
                'updateProjectPercentageComplete' ,
                e
            );
        }
    }

    private pse__Proj__c calculateProjectPercentageComplete( AggregateResult[] groupedResults , Id projectId , Decimal current ) {
        pse__Proj__c record = null;
        if ( ( groupedResults != null ) && !groupedResults.isEmpty() ) {
            for ( AggregateResult ar : groupedResults ) {
                if ( ( ar.get( 'pse__Project__c' ) != null )
                    && ( projectId == (Id)ar.get( 'pse__Project__c' ) )
                    )
                {
                    // only update the project when the current percent is blank, or when the new percent is significantly changed...
                    record = this.calculateProjectPercentageComplete(
                        projectId ,
                        current ,
                        (Decimal)ar.get( 'expr0' ) ,
                        (Decimal)ar.get( 'expr1' )
                    );
                }
            }
        }
        return record;
    }

    private pse__Proj__c calculateProjectPercentageComplete( Id projectId , Decimal current , Decimal count , Decimal total ) {
        pse__Proj__c record = null;
        if ( ( projectId != null )
            && ( count != null )
            && ( total != null )
            && ( total > 0 )
            )
        {
            // translate current and new value to incremental steps...
            current = this.getStepValue( current );
            Decimal newPercentComplete = this.getStepValue( count / total );
            // only re-populate for significant changes...
            if ( current != newPercentComplete ) {
                record = new pse__Proj__c(
                    Id=projectId ,
                    NSP_Project_Complete__c=newPercentComplete
                );
            }
        }
        return record;
    }

    public Decimal getStepValue( Decimal value ) {
        // enforce 0% floor...
        if ( value == null ) {
            value = 0.0;
        }
        // cap value within a defined step size...
        // ~ i.e. when stepSize=1, the result will always be: 0, 1, 2, 3, etc...
        // ~ i.e. when stepSize=5, the result will always be: 0, 5, 10, 15, etc...
        // ~ i.e. when stepSize=10, the result will always be: 0, 10, 20, 30, etc...
        value = ( ( value / ProjectPercentageCompleteQueueable.stepSize ).round( System.RoundingMode.HALF_UP ) * ProjectPercentageCompleteQueueable.stepSize ).intValue();
        // enforce 100% ceiling...
        if ( value > 100.0 ) {
            value = 100.0;
        }
        return value;
    }

    //
    // Custom Settings
    //

    private static ProjectPercentageCompleteSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = ProjectPercentageCompleteSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( ProjectPercentageCompleteQueueable.settings != null ) {
                    local = ProjectPercentageCompleteQueueable.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    private static Integer stepSize {
        private get {
            if ( stepSize == null ) {
                Integer local = 1;
                if ( ( ProjectPercentageCompleteQueueable.settings != null )
                    && ( ProjectPercentageCompleteQueueable.settings.StepSize__c != null )
                   )
                {
                    local = ProjectPercentageCompleteQueueable.settings.StepSize__c.intValue();
                }
                // step size must be greater than zero...
                if ( local < 1 ) {
                    local = 1;
                }
                // step size must be less than or equal to 100...
                if ( local > 100 ) {
                    local = 100;
                }
                stepSize = local;
            }
            return stepSize;
        }
        private set;
    }

}
//