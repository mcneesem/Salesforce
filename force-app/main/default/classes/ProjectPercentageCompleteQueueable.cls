public with sharing class ProjectPercentageCompleteQueueable implements Queueable {
    // test w/ ProjectPercentageCompleteQueueableTest (88%)

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
                // select the current record for percent complete comparions...
                List<pse__Proj__c> currentRecords = [
                    SELECT Id , NSP_Project_Complete__c
                    FROM pse__Proj__c
                    WHERE ( Id = :projectId )
                ];
                Decimal currentPercentComplete = null;
                if ( ( currentRecords != null ) && !currentRecords.isEmpty() ) {
                    currentPercentComplete = currentRecords[0].NSP_Project_Complete__c;
                }
                // calculate new percent complete values...
                pse__Proj__c record = null;
                for ( AggregateResult ar : groupedResults ) {
                    if ( ( ar.get( 'pse__Project__c' ) != null )
                        && ( projectId == (Id)ar.get( 'pse__Project__c' ) )
                        )
                    {
                        // only update the project when the current percent is blank, or when the new percent is significantly changed...
                        record = this.calculateProjectPercentageComplete(
                            projectId ,
                            currentPercentComplete ,
                            (Decimal)ar.get( 'expr0' ) ,
                            (Decimal)ar.get( 'expr1' )
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

    private pse__Proj__c calculateProjectPercentageComplete( Id projectId , Decimal current , Decimal count , Decimal total ) {
        pse__Proj__c record = null;
        if ( ( projectId != null )
            && ( count != null )
            && ( total != null )
            && ( total > 0 )
            )
        {
            Decimal newPercentComplete = ( count / total );
            if ( ( current == null )
                || ( current.round() != newPercentComplete.round() )
                )
            {
                record = new pse__Proj__c(
                    Id=projectId ,
                    NSP_Project_Complete__c=newPercentComplete
                );
            }
        }
        return record;
    }

}
//