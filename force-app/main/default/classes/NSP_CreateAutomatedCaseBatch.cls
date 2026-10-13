// intentionally `without sharing` to preserve default sharing at api version 56...
public without sharing class NSP_CreateAutomatedCaseBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<SObject> {
    // test w/ NSP_CreateAutomatedCaseBatchTest (77%)

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_CreateAutomatedCaseBatch() {
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
            'NSP_CreateAutomatedCaseBatch ~ Create a case for accounts that meet criteria based on WO asset, AIMS renewal date and Account team Role (Bus. Team HRsp/CL) ~ Schedule to Run Everyday 10 pm' + suffix ,
            '0 0 22 * * ?' ,
            new NSP_CreateAutomatedCaseBatch()
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
            new NSP_CreateAutomatedCaseBatch() ,
            200
        );
    }

    //
    // Batchable
    //

    //Start method to query project records
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        List<String> accountTeamFields = new List<String>{
                'ID',
                'NSP_Role__c',
                'NSP_User__c',
                'NSP_Account__c',
                'NSP_PER_ID__c',
                'NSP_Account__r.NSP_AIMS_Renewal_Date__c'
                };

        // check Today Date -> AIMS Renewal Date on Account +150 days
        Date renewalDate = System.today().addDays(-150);
        String finalDate = String.valueOf(renewalDate).removeEnd(' 00:00:00');
        // Build the query
        String accountTeamObjectApiName = 'NSP_Account_Team__c';
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder(accountTeamObjectApiName, accountTeamFields)
            .addFilter('NSP_Role__c', NSP_ServiceConstants.BUS_TEAM_HRSP_CL  , NSP_QueryBuilder.Operator.EQUALS,true)
            .addFilter('NSP_PER_ID__c', System.Label.NSP_User_Employee_Number , NSP_QueryBuilder.Operator.EQUALS,true)
            .addFilter('NSP_Account__r.NSP_AIMS_Renewal_Date__c', finalDate, NSP_QueryBuilder.Operator.EQUALS, false)
            .setSecurityEnforce(false);
        String query = queryBuilder.build();
        return Database.getQueryLocator(query);
    }

    //Execute method to send email alert when ITA project is created
    public void execute( Database.BatchableContext bc , List<NSP_Account_Team__c>accountTeamList ) {
        try {
            Set<ID> accountIDs = new Set<ID>();
            ID WORecordType = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
            Map<ID,ID> accountWOAssetMap = new Map<ID,ID>();
            Map<ID,String> accountAIMSClientMap = new Map<ID,String>();
            List<Case> caseToInsert = new List<Case>();

            // get account id set
            for(NSP_Account_Team__c acctTeamId:accountTeamList){
                accountIDs.add(acctTeamId.NSP_Account__c);
            }
            // populate accountWOAssetMap,accountAIMSClientMap Map by querying Asset -> if Active WO asset is present for the account
            for(Asset asstID: [Select ID,AccountId, Account.NSP_AIMS_Client__c FROM Asset WHERE AccountId =: accountIDs AND recordTypeId =:  WORecordType AND NSP_Account_Status__c = : NSP_ServiceConstants.AIMS_STATUS ]){
                accountWOAssetMap.put(asstID.AccountID, asstID.ID);
                accountAIMSClientMap.put(asstID.AccountID, asstID.Account.NSP_AIMS_Client__c );
            }
            // create case records
            if(!accountIDs.isEmpty() && !accountWOAssetMap.isEmpty() && !accountAIMSClientMap.isEmpty()){
                caseToInsert = populateCaseList(accountIDs,accountWOAssetMap,accountAIMSClientMap);
            }
            // insert case records
            if(!caseToInsert.isEmpty()){
                createCase(caseToInsert);
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_CreateAutomatedCaseBatch.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    //finish method
    public void finish( Database.BatchableContext bc ) {
    }

    public static void createCase( List<Case> caseToInsert ) {
        try {
            // insert the case records
            if ( !caseToInsert.isEmpty() ) {
                Database.SaveResult[] results =  Database.insert( caseToInsert , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_CreateAutomatedCaseBatch.class.getName() ,
                    'createCase:insert' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_CreateAutomatedCaseBatch.class.getName() ,
                'createCase' ,
                e
            );
        }
    }

    public static List<Case> populateCaseList( Set<Id> accountIDs , Map<Id,Id> accountWOAssetMap , Map<Id,String> accountAIMSClientMap ) {
        Set<ID> accountToExclude = new Set<ID>();
        List<Case> caseToInsert = new List<Case>();
        try {
            // query to get National Business Team Queue ID
            List<Group> groupLst = [select Id FROM Group WHERE Type =: NSP_ServiceConstants.GROUPTYPE AND DeveloperName =: NSP_ServiceConstants.NATIONAL_BUSINESS_TEAM LIMIT 1 ];
            // loopthrough the case under same account with owner as ID to exclude case creation for those accounts
            for(Case caseID:[Select ID,AccountId FROM case WHERE AccountId =: accountIDs AND OwnerId =: groupLst[0].ID ]){
                accountToExclude.add(caseID.AccountId);
            }
            // loop through the Map for which WO asset is present
            if(!accountWOAssetMap.isEmpty()){
                for(ID accountID:accountWOAssetMap.keySet() ){
                    // check if the account already has case created
                    if(!accountToExclude.contains(accountID)){
                        //  create automated case record with following values
                        Case caseRec = new Case();
                        caseRec.OwnerId =  groupLst[0].ID;
                        caseRec.AccountId = accountID;
                        caseRec.NSP_Category__c = NSP_ServiceConstants.Client_Management;
                        caseRec.NSP_SubCategory__c =NSP_ServiceConstants.Renewal_Consultation;
                        caseRec.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
                        caseRec.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
                        caseRec.Subject = 'Upcoming Renewal/Determine Next Steps';
                        caseRec.AssetId =accountWOAssetMap.get(accountID);
                        caseRec.NSP_ClientNumber__c =accountAIMSClientMap.get(accountID);
                        caseRec.RecordTypeID=  NSP_GenericRecordType.getRecordTypeId('Case', NSP_ServiceConstants.PEO);
                        caseToInsert.add(caseRec)  ;
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_CreateAutomatedCaseBatch.class.getName() ,
                'populateCaseList' ,
                e
            );
        }
        return caseToInsert;
    }

}
//