public class CaseImportQueueable implements Queueable {
    // test w/ FileUploadControllerTest (88%)
    private List<Case> caseList;
    private List<ID> caseSuccessList;
    private List<list<String>> allRowValue;
    private Map<Case,list<String>> rowCaseMap;
    private Map<list<String>,String> failureMap;
    private static Case_Import_Tool_Settings__c settings {
        private get {
            if ( settings == null ) {
                settings = Case_Import_Tool_Settings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }
    private static Email_Deliverability_Settings__c emailDeliverability {
        private get {
            if ( emailDeliverability == null ) {
                emailDeliverability = Email_Deliverability_Settings__c.getInstance( UserInfo.getUserId() );
            }
            return emailDeliverability;
        }
        private set;
    }
    private static Notification_Deliverability_Settings__c emailSettings {
        private get {
            if ( emailSettings == null ) {
                emailSettings = Notification_Deliverability_Settings__c.getInstance( UserInfo.getUserId() );
            }
            return emailSettings;
        }
        private set;
    }

    private static Integer batchSize {
        private get {
            if ( batchSize == null ) {
                Integer local = 20;
                if ( ( CaseImportQueueable.settings != null )
                    && ( CaseImportQueueable.settings.BatchSize__c != null )
                   )
                {
                    local = CaseImportQueueable.settings.BatchSize__c.intValue();
                }
                // batch size must be greater than zero...
                if ( local < 1 ) {
                    local = 1;
                }
                batchSize = local;
            }
            return batchSize;
        }
        private set;
    }

    public static void enqueueJob(
        List<Case> caseList ,
        List<list<String>> allRowValue ,
        Map<Case,List<String>> rowCaseMap ,
        List<Id> caseSuccessList ,
        Map<list<String>,String> createRecordMap
    )
    {
        if ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) {
            System.enqueueJob(
                new CaseImportQueueable(
                    caseList ,
                    allRowValue ,
                    rowCaseMap ,
                    null ,
                    createRecordMap
                )
            );
        }
    }

    private CaseImportQueueable(List<Case> caseList,List<list<String>> allRowValue, Map<Case,list<String>> rowCaseMap,List<ID> caseSuccessList ,Map<list<String>,String> failureMap ) {
        this.caseList = caseList;
        this.allRowValue = allRowValue;
        this.rowCaseMap = rowCaseMap;
        this.caseSuccessList = caseSuccessList != null ? caseSuccessList : new List<ID>();
        this.failureMap = failureMap != null ? failureMap : new Map<List<String>, String>();
    }

    public void execute(QueueableContext context) {
        try{
            List<Case> batchList = this.dequeueNextBatch();
            Database.SaveResult[] srList = null;
            Map<Id,Case> batchMap = new Map<Id,Case>();
            Map<list<String>,String> createRecordMap = new Map<list<String>,String>();
            if( batchList != null && !batchList.isEmpty() ) {
                srList = Database.insert( batchList , false );
                for( Case ids :batchList ) {
                    if( ids != null ) {
                        batchMap.put( ids.Id, ids );
                    }
                }
            }
            
            createRecordMap = this.getError( srList,batchMap );
            if (createRecordMap.size() > 0) {
                FileUploadController.createImportError(createRecordMap);
            }

            if (caseList.size() > 0) {
                CaseImportQueueable.enqueueJob(
                    caseList ,
                    allRowValue ,
                    rowCaseMap ,
                    caseSuccessList ,
                    failureMap
                );
            } else {
                CaseImportQueueable.settings.Bypass_Opened_Date__c = false;
                update CaseImportQueueable.settings;

                CaseImportQueueable.emailDeliverability.IsEnabledOutbound__c = true;
                update CaseImportQueueable.emailDeliverability;

                CaseImportQueueable.emailSettings.IsEnabledOutbound__c = true;
                update CaseImportQueueable.emailSettings;
                FileUploadController.sendEmail(caseSuccessList, failureMap);
            }
        } catch(Exception e ) {
            NSP_ErrorLogHandler.logException(
                CaseImportQueueable.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    private Map<list<String>,String> getError( Database.SaveResult[] srList,Map<Id,Case> batchMap ) {
        Map<list<String>,String> createRecordMap = new Map<list<String>,String>();
        if ( ( srList != null ) && ( batchMap != null ) ) {
            for ( Database.SaveResult sr : srList ) {
                Case c = batchMap.get( sr.getId() );
                if ( c != null ) {
                    if ( sr.isSuccess() ) {
                        caseSuccessList.add( c.Id );
                    } else {
                        createRecordMap = this.getFailureMap( sr,c );
                    }
                }
            }
        }
        return createRecordMap;
    }
    
    private Map<list<String>,String> getFailureMap( Database.SaveResult sr, Case c ) {
        String errorRowMessage = '. Error occurred at row number - ';
        Map<list<String>,String> createRecordMap = new Map<list<String>,String>();
        for (Database.Error err : sr.getErrors()) {
            if (rowCaseMap.containsKey(c) && allRowValue.contains(rowCaseMap.get(c))) {
                Integer rowNumber = allRowValue.indexOf(rowCaseMap.get(c)) + 2;
                createRecordMap.put(rowCaseMap.get(c), err.getMessage() + errorRowMessage + rowNumber);
                if (failureMap == null) {
                    failureMap = new Map<List<String>, String>();
                }
                failureMap.put(rowCaseMap.get(c), err.getMessage() + errorRowMessage + rowNumber);
            }
        }
        return createRecordMap;
    }
    // Returns and removes the next batch of Case records from caseList
    private List<Case> dequeueNextBatch() {
        List<Case> batchList = new List<Case>();
        if ( ( this.caseList != null ) && !this.caseList.isEmpty() ) {
            for (Integer i = 0; i < CaseImportQueueable.batchSize; i++) {
                if ( !this.caseList.isEmpty() ) {
                    Case head = this.caseList.remove( 0 );
                    if ( head != null ) {
                        batchList.add( head );
                    }
                }
            }
        }
        return batchList;
    }
}