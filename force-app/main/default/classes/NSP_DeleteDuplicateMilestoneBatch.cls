// intentionally `without sharing` to preserve default sharing at api version 56...
public without sharing class NSP_DeleteDuplicateMilestoneBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<SObject> {
    // test w/ NSP_DeleteDuplicateMilestoneBatchTest (95%)

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_DeleteDuplicateMilestoneBatch() {
    }

    //
    // ISelfSchedulable
    //

    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_DeleteDuplicateMilestoneBatch ~ Duplicate milestones should not be created when project tasks are added from a template ~ run Hourly' + suffix ,
            '0 0 * * * ? *' ,
            new NSP_DeleteDuplicateMilestoneBatch()
        );
    }

    //
    // Schedulable
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
        return Database.executeBatch(
            new NSP_DeleteDuplicateMilestoneBatch() ,
            200
        );
    }

    //
    // Batchable
    //

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator(
            [ SELECT Id , Name , pse__Project__c FROM pse__Milestone__c WHERE NSP_isDuplicate__c = true ]
        );
    }

    //Execute
    public void execute( Database.BatchableContext bc , List<pse__Milestone__c> milestoneList ) {
        try {
            List<Id> milestoneIds = new List<Id>();
            List<String> milestoneNameList = new List<String>();
            Map<String,Id> mapOldMilestoneName = new Map<String,Id>();
            List<pse__Project_Task__c> projectTaskListToUpdate = new List<pse__Project_Task__c>();
            //iterate over queried milestone to store id and name
            for(pse__Milestone__c eachMilestone : milestoneList ){
                milestoneIds.add(eachMilestone.Id);
                milestoneNameList.add(eachMilestone.Name);
            }
            //iterate over milstones with same name w
            if( !milestoneNameList.isEmpty()){
                for(pse__Milestone__c eachOldMilestone : [SELECT ID,Name FROM pse__Milestone__c WHERE NAME IN: milestoneNameList AND NSP_isDuplicate__c = false]){
                    mapOldMilestoneName.put(eachOldMilestone.Name, eachOldMilestone.Id);
                }
            }
            //iterate over project having reference of duplicate Milestones
            if(!milestoneIds.isEmpty()){
                for(pse__Project_Task__c eachProjectTask : [SELECT ID,Name,pse__Milestone__c,pse__Milestone__r.Name  FROM pse__Project_Task__c WHERE pse__Milestone__c IN: milestoneIds ]){
                    eachProjectTask.pse__Milestone__c = mapOldMilestoneName.get(eachProjectTask.pse__Milestone__r.Name);
                    projectTaskListToUpdate.add(eachProjectTask);
                }
            }
            //update project task's milestone reference
            if ( !projectTaskListToUpdate.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( projectTaskListToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_DeleteDuplicateMilestoneBatch.class.getName() , 
                    'execute:update:pse__Project_Task__c' ,
                    results
                );
            }
            //delete duplicate milestones
            if ( !milestoneIds.isEmpty() ) {
                List<Database.DeleteResult> results = Database.delete( milestoneIds , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_DeleteDuplicateMilestoneBatch.class.getName() , 
                    'execute:delete:pse__Milestone__c' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_DeleteDuplicateMilestoneBatch.class.getName() , 
                'execute' ,
                e
            );
        }
    }

    public void finish( Database.BatchableContext bc ) {
    }

}
//
