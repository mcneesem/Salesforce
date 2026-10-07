// intentionally `without sharing` to preserve default sharing at api version 56...
public without sharing class NSP_AcntEarliestFirstPayDateUpdateBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<SObject> , Database.Stateful {
    // test w/ NSP_ActEarliestFirstPayDateUpdtBatchTest (96%)

    Id woassetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'WO' );
    Id wxassetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'NSP_Asset_Product' );
    Id tsassetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'Time_Attendance' );

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_AcntEarliestFirstPayDateUpdateBatch() {
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
            'NSP_AcntEarliestFirstPayDateUpdateBatch ~ Replicate trigger-based functionality for Product First Pay Date field ~ Scheduled to run monthly' + suffix ,
            '0 0 23 1 * ? *' ,
            new NSP_AcntEarliestFirstPayDateUpdateBatch()
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
            new NSP_AcntEarliestFirstPayDateUpdateBatch() ,
            50
        );
    }

    //
    // Batchable
    //

    //start method
    //This method will query on Asset object with required filter conditions
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        List<String> assetTypes = new List<String>{woassetRecordTypeId,wxassetRecordTypeId,tsassetRecordTypeId};
        List<String> assetFields = new List<String>{'Id','AccountId','NSP_First_Pay_Date__c','NSP_AIMS_First_Pay_Date__c','RecordTypeId'};
        String query = new NSP_QueryBuilder( 'Asset' , assetFields )
            .addFilter('RecordTypeId', assetTypes, NSP_QueryBuilder.Operator.INCLUDES)
            .build();
        return Database.getQueryLocator(query);
    }

    //execute method to populate all the required assets in a map
    public void execute( Database.BatchableContext bc , List<Asset> scope ) {
        Map<Id,Date> mapOfAccntdToErlstPayDate = new Map<Id,Date>();
        List<Account> accountsToUpdateList = new List<Account>();
        List<Asset> woAssetsToUpdateList = new List<Asset>();
        try {

            for ( Asset eachAsset : scope ) {
                if(eachAsset.RecordTypeId == woassetRecordTypeId){
                    eachAsset.NSP_First_Pay_Date__c = eachAsset.NSP_AIMS_First_Pay_Date__c;
                    if(!woAssetsToUpdateList.contains(eachAsset)){
                        woAssetsToUpdateList.add(eachAsset);
                    }
                }

                if( eachAsset.NSP_First_Pay_Date__c != null){

                    if(mapOfAccntdToErlstPayDate.get(eachAsset.AccountId) == null){
                        mapOfAccntdToErlstPayDate.put(eachAsset.AccountId, eachAsset.NSP_First_Pay_Date__c);
                    }
                    else if(mapOfAccntdToErlstPayDate.get(eachAsset.AccountId) > eachAsset.NSP_First_Pay_Date__c){
                            mapOfAccntdToErlstPayDate.put(eachAsset.AccountId, eachAsset.NSP_First_Pay_Date__c);
                    }
                }
            }
            for( Account eachAccount : [ SELECT ID,NSP_Product_First_Pay_Date__c FROM Account WHERE Id IN: mapOfAccntdToErlstPayDate.keySet()]){

                if( eachAccount.NSP_Product_First_Pay_Date__c == null
                    ||  eachAccount.NSP_Product_First_Pay_Date__c > mapOfAccntdToErlstPayDate.get(eachAccount.Id)){
                        eachAccount.NSP_Product_First_Pay_Date__c = mapOfAccntdToErlstPayDate.get(eachAccount.Id);
                    accountsToUpdateList.add( eachAccount );
                }
            }

            //check if the list is empty and do update
            if ( !accountsToUpdateList.isEmpty() ) {
                //update the account list
                List<Database.SaveResult> results = Database.update( accountsToUpdateList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AcntEarliestFirstPayDateUpdateBatch.class.getName() ,
                    'execute:update:Account' ,
                    results
                );
            }
            if ( !woAssetsToUpdateList.isEmpty() ) {
                //update the asset list
                List<Database.SaveResult> results = Database.update( woAssetsToUpdateList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AcntEarliestFirstPayDateUpdateBatch.class.getName() ,
                    'execute:update:Asset' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AcntEarliestFirstPayDateUpdateBatch.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    public void finish( Database.BatchableContext bc ) {
    }

}
//
