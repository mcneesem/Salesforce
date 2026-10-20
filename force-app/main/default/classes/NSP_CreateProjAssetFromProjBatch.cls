// intentionally `without sharing` to preserve default sharing at api version 56...
public without sharing class NSP_CreateProjAssetFromProjBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<SObject> {
    // test w/ NSP_CreateProjAssetFromProjTest (91%)

    private static final String ASSET_OBJ = 'Asset';

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_CreateProjAssetFromProjBatch() {
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
            'NSP_CreateProjAssetFromProjBatch ~ When a new project is created (manually or automatically) or a new project account is added to a project, then create new project asset based on the asset type field on project ~ Schedule to Run Everyday 4 am' + suffix ,
            '0 0 4 * * ? *' ,
            new NSP_CreateProjAssetFromProjBatch()
        );
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
        Integer batchSize = Integer.valueOf( System.Label.NSP_Maximum_Batch_Size );
        return Database.executeBatch( new NSP_CreateProjAssetFromProjBatch() , batchSize );
    }

    //
    // Schedulable
    //

    // Schedulable execute method to fire the batch class
    public void execute( SchedulableContext scon ) {
        this.call( 'run' , null );
    }

    //
    // Batchable
    //

    //Start method to query project records
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        List<String> ProjFields = new List<String>{
            'ID',
                'NSP_Asset_Type__c',
                'pse__Account__c',
                'NSP_Is_Project_Asset_Created__c'
                };
                    String projObjectApiName = 'pse__Proj__c';
        //querying the above fields from project
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder(projObjectApiName, ProjFields)
            .addFilter('pse__Is_Template__c', false)
            .addFilter('NSP_Asset_Type__c', NULL, NSP_QueryBuilder.Operator.NOT_EQUALS, false)
            .addFilter('pse__Account__c', NULL, NSP_QueryBuilder.Operator.NOT_EQUALS, false)
            .setSecurityEnforce(false);
        String query = queryBuilder.build();
        return Database.getQueryLocator(query);
    }

    //Execute method to create the project asset records
    public void execute( Database.BatchableContext bc , List<pse__Proj__c> projectList ) {
        try {
            Set<ID> AccountIDList = new Set<ID>();
            Set<ID> RecordTypeIDList = new Set<ID>();
            List<pse__Proj__c> projList = new List<pse__Proj__c>();
            // Get List of projects with Is project asset created field set to false
            for(pse__Proj__c prj:projectList){
                if(prj.NSP_Is_Project_Asset_Created__c == false){
                    projList.add(prj);
                }
            }
            // get set of all accountIDs and record type IDs
            for(pse__Proj__c projId:projList){
                AccountIDList.add(projId.pse__Account__c)  ;
                RecordTypeIDList.add(NSP_GenericRecordType.getRecordTypeId(ASSET_OBJ, projId.NSP_Asset_Type__c));
            }
            // call method to populate map values and create project asset
            if(!AccountIDList.isEmpty() && !RecordTypeIDList.isEmpty()){
                populateMap(AccountIDList,RecordTypeIDList,projList,null);
            }
            createProjectAssetFromProjAccount();
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_CreateProjAssetFromProjBatch.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    //finish method
    public void finish( Database.BatchableContext bc ) {
    }

    //
    //
    //

    // Method to Loop through asset and populate Map values
    public static void populateMap(
        Set<Id> AccountIDList ,
        Set<Id> RecordTypeIDList ,
        List<pse__Proj__c> projList ,
        List<Project_Account__c> projAcctList
        )
    {
        try {
            Map<Id,Set<Id>> accountAssetMap = new Map<Id,Set<Id>>();
            Map<Id,Id> assetRecordTypeMap = new Map<Id,Id>();
            // Loop through asset and populate Map values
            for(Asset asst: [Select Id , AccountId , recordTypeID FROM Asset WHERE AccountId =: AccountIDList AND recordTypeId = : RecordTypeIDList AND NSP_Account_Status__c = : NSP_ServiceConstants.AIMS_STATUS ] ){
                //Store account and corresponding assets in MAP<AccountID , Set<AssetID>>
                Set<ID> assetIDSet =new Set<ID>();
                // check if the account key already exist in the map
                if(accountAssetMap.containskey(asst.AccountId)){
                    assetIDSet = accountAssetMap.get(asst.AccountId) ;
                }
                assetIDSet.add(asst.ID);
                accountAssetMap.put(asst.AccountId, assetIDSet);
                // store asset and record type in MAP
                assetRecordTypeMap.put(asst.ID, asst.RecordTypeId);
            }
            // method call to create project assets if match is found
            if(!accountAssetMap.isEmpty() && !assetRecordTypeMap.isEmpty() ){
                if(projList != null){
                    createProjectAssets(accountAssetMap,assetRecordTypeMap,projList);
                }
                if(projAcctList != null){
                    createProjectAssetsFromPrjAcct(accountAssetMap,assetRecordTypeMap,projAcctList);
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_CreateProjAssetFromProjBatch.class.getName() ,
                'populateMap' ,
                e
            );
        }
    }

    // Method to Loop through project records and check if the asset type (RT) matches with the account's asset records RT
    public static void  createProjectAssets(
        Map<Id,Set<Id>> accountAssetMap ,
        Map<Id,Id> assetRecordTypeMap ,
        List<pse__Proj__c> projList
        )
    {
        try {
            List<Project_Asset__c> projAsstLst = new  List<Project_Asset__c>();
            List<pse__Proj__c> projToUpdate = new List<pse__Proj__c>();
            for(pse__Proj__c projId:projList){
                // check if the account exist in the map
                if(accountAssetMap.containskey(projId.pse__Account__c)){
                    // get all assets associated to the account
                    Set<ID> assetIDSet = accountAssetMap.get(projId.pse__Account__c);
                    for(ID asstID: assetIDSet){
                        // check asset record type matches with project's asset type
                        if(assetRecordTypeMap.containskey(asstID) && NSP_GenericRecordType.getRecordTypeId(ASSET_OBJ, projId.NSP_Asset_Type__c) == assetRecordTypeMap.get(asstID)  ){
                            // Create a project asset record when asset record match is found for the project
                            Project_Asset__c projAsst = new Project_Asset__c();
                            projAsst.Asset__c = asstID;
                            projAsst.Project__c = projId.ID;
                            projAsstLst.add(projAsst);
                            if(!projToUpdate.contains(projId)){
                                projId.NSP_Is_Project_Asset_Created__c = true;
                                projToUpdate.add(projId);
                            }

                        }
                    }
                }
            }
            // insert the project asset records
            if ( !projAsstLst.isEmpty() ) {
                List<Database.SaveResult> result =  Database.insert( projAsstLst , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_CreateProjAssetFromProjBatch.class.getName() ,
                    'createProjectAssets:insert' ,
                    result
                );
            }
            //Update the Project records
            if ( !projToUpdate.isEmpty() ) {
                List<Database.SaveResult> result = Database.update( projToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_CreateProjAssetFromProjBatch.class.getName() ,
                    'createProjectAssets:update' ,
                    result
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_CreateProjAssetFromProjBatch.class.getName() ,
                'createProjectAssets' ,
                e
            );
        }
    }

    // Method to Loop through project records and check if the asset type (RT) matches with the account's asset records RT
    public static void  createProjectAssetsFromPrjAcct(
        Map<Id,Set<Id>> accountAssetMap ,
        Map<Id,Id> assetRecordTypeMap ,
        List<Project_Account__c> projAcctList
        )
    {
        try {
            List<Project_Asset__c> projAsstToInsert = new List<Project_Asset__c>();
            Map<Id,Set<Id>> projectAssetMap = new Map<Id,Set<Id>>();
            Set<Id> projectIDs = new Set<Id>();
            // Get list of project IDs to filter project assets related to these projects
            for(Project_Account__c projAcctId:projAcctList){
              if(projAcctId.Project__c != null)  {
                projectIDs.add(projAcctId.Project__c );
              }
            }
            // create a Map<Project, List<Asset>> from project asset records
            for(Project_Asset__c projectAsset: [Select ID,Project__c,Asset__c  FROM Project_Asset__c  WHERE Project__c IN : projectIDs]){
                Set<ID> assetSet =new Set<ID>();
                if(projectAssetMap.containskey(projectAsset.Project__c)){
                    assetSet = projectAssetMap.get(projectAsset.Project__c) ;
                }
                assetSet.add(projectAsset.Asset__c);
                projectAssetMap.put(projectAsset.Project__c, assetSet);
            }

            for(Project_Account__c projAcctId:projAcctList){
                // check if the account exist in the map
                if(accountAssetMap.containskey(projAcctId.Account__c)){
                    // get all assets associated to the account
                    Set<ID> assetIDSet = accountAssetMap.get(projAcctId.Account__c);
                    for(ID asstID: assetIDSet){
                        // check asset record type matches with project's asset type
                        if(assetRecordTypeMap.containskey(asstID) && NSP_GenericRecordType.getRecordTypeId(ASSET_OBJ, projAcctId.Project__r.NSP_Asset_Type__c) == assetRecordTypeMap.get(asstID)  ){
                            // check if this project asset combo is already found in project asset object
                            if(projectAssetMap.containsKey(projAcctId.Project__c) ){
                                Set<ID> assetIDLst = projectAssetMap.get(projAcctId.Project__c);
                                if(!assetIDLst.contains(asstID)){
                                    // Create a project asset record when asset record match is found for the project
                                    Project_Asset__c projAsst = new Project_Asset__c();
                                    projAsst.Asset__c = asstID;
                                    projAsst.Project__c = projAcctId.Project__c;
                                    projAsstToInsert.add(projAsst);
                                }
                            }
                        }
                    }
                }
            }
            // insert the project asset records
            if ( !projAsstToInsert.isEmpty() ) {
                List<Database.SaveResult> result = Database.insert( projAsstToInsert , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_CreateProjAssetFromProjBatch.class.getName() ,
                    'createProjectAssetsFromPrjAcct:insert' ,
                    result
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_CreateProjAssetFromProjBatch.class.getName() ,
                'createProjectAssetsFromPrjAcct' ,
                e
            );
        }
    }

    // Method to Loop through project records and check if the asset type (RT) matches with the account's asset records RT
    public static void  createProjectAssetFromProjAccount() {
        try {
            Set<Id> AccountIDList = new Set<Id>();
            Set<Id> RecordTypeIDList = new Set<Id>();
            //Query Project Accounts records
            List<Project_Account__c> projAcctLst = [Select Id, Project__c, Project__r.NSP_Asset_Type__c, Account__c FROM Project_Account__c WHERE Project__r.NSP_Asset_Type__c  != NULL AND Account__c != NULL ];

            //get set of all accountIDs and record type IDs
            for(Project_Account__c projAcctId: projAcctLst){
                AccountIDList.add(projAcctId.Account__c)  ;
                RecordTypeIDList.add(NSP_GenericRecordType.getRecordTypeId(ASSET_OBJ, projAcctId.Project__r.NSP_Asset_Type__c));
            }
            // call method to populate map values and create project asset
            if(!AccountIDList.isEmpty() && !RecordTypeIDList.isEmpty()){
                populateMap(AccountIDList,RecordTypeIDList,null,projAcctLst);
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_CreateProjAssetFromProjBatch.class.getName() ,
                'createProjectAssetFromProjAccount' ,
                e
            );
        }
    }

}
//