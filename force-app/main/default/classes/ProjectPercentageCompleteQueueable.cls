public with sharing class ProjectPercentageCompleteQueueable implements Queueable {
    // test w/ ProjectPercentageCompleteQueueableTest (86%)

    //
    // public entry points...
    //

    public static void enqueueJob( Set<Id> local ) {
        if ( local != null ) {
            ProjectPercentageCompleteQueueable.enqueueJob( new List<Id>( local ) );
        }
    }

    public static void enqueueJob( List<Id> local ) {
        if ( ( local != null )
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
        if ( this.projectIds != null ) {
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
                pse__Proj__c record = null;
                for ( AggregateResult ar : groupedResults ) {
                    if ( ( ar.get( 'pse__Project__c' ) != null )
                        && ( projectId == (Id)ar.get( 'pse__Project__c' ) )
                        )
                    {
                        Decimal count = (Decimal)ar.get( 'expr0' );
                        Decimal countOfRecords = (Decimal)ar.get( 'expr1' );
                        record = new pse__Proj__c(
                            Id=projectId ,
                            NSP_Project_Complete__c = ( count / countOfRecords )
                        );
                    }
                }
                if ( record != null ) {
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

}
//