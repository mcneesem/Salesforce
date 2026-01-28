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
    private static Notification_Deliverability_Settings__c notificationDeliverability {
        private get {
            if ( notificationDeliverability == null ) {
                notificationDeliverability = Notification_Deliverability_Settings__c.getInstance( UserInfo.getUserId() );
            }
            return notificationDeliverability;
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
        List<Case> caseListLocal ,
        List<List<String>> allRowValueLocal ,
        Map<Case,List<String>> rowCaseMapLocal ,
        List<Id> caseSuccessListLocal ,
        Map<List<String>,String> createRecordMapLocal
    )
    {
        if ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) {
            System.enqueueJob(
                new CaseImportQueueable(
                    caseListLocal ,
                    allRowValueLocal ,
                    rowCaseMapLocal ,
                    null ,
                    createRecordMapLocal
                )
            );
        }
    }

    private CaseImportQueueable(
        List<Case> caseListLocal ,
        List<List<String>> allRowValueLocal ,
        Map<Case,List<String>> rowCaseMapLocal ,
        List<Id> caseSuccessListLocal ,
        Map<List<String>,String> failureMapLocal
        )
    {
        this.caseList = caseListLocal;
        this.allRowValue = allRowValueLocal;
        this.rowCaseMap = rowCaseMapLocal;
        this.caseSuccessList = caseSuccessListLocal != null ? caseSuccessListLocal : new List<ID>();
        this.failureMap = failureMapLocal != null ? failureMapLocal : new Map<List<String>, String>();
    }

    public void execute(QueueableContext context) {
        try{
            List<Case> batchList = this.dequeueNextBatch();
            List<Database.SaveResult> srList = null;
            Map<Id,Case> batchMap = new Map<Id,Case>();
            Map<list<String>,String> createRecordMap = new Map<list<String>,String>();
            if( batchList != null && !batchList.isEmpty() ) {
                srList = Database.insert( batchList , false );
                for( Case recordIds :batchList ) {
                    if( recordIds != null ) {
                        batchMap.put( recordIds.Id, recordIds );
                    }
                }
            }
            
            createRecordMap = this.getError( srList,batchMap );
            if (createRecordMap.size() > 0) {
                FileUploadController.createImportError(createRecordMap);
            }

            if ( ( this.caseList != null ) && !this.caseList.isEmpty() ) {
                CaseImportQueueable.enqueueJob(
                    this.caseList ,
                    this.allRowValue ,
                    this.rowCaseMap ,
                    this.caseSuccessList ,
                    this.failureMap
                );
            } else {
                CaseImportQueueable.settings.Bypass_Opened_Date__c = false;
                update CaseImportQueueable.settings;

                CaseImportQueueable.emailDeliverability.IsEnabledOutbound__c = true;
                update CaseImportQueueable.emailDeliverability;

                CaseImportQueueable.notificationDeliverability.IsEnabledOutbound__c = true;
                update CaseImportQueueable.notificationDeliverability;
                FileUploadController.sendEmail(this.caseSuccessList, this.failureMap);
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
                    if ( sr.isSuccess() && ( this.caseSuccessList != null ) ) {
                        this.caseSuccessList.add( c.Id );
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
        List<String> rowCase = new List<String>();
        if( this.rowCaseMap != null
           && this.rowCaseMap.get( c ) != null 
           && this.rowCaseMap.containsKey(c) 
           && sr != null 
           && this.allRowValue != null) {
               rowCase = this.rowCaseMap.get(c);
               for (Database.Error err : sr.getErrors()) {
                   if ( this.allRowValue.contains(rowCase) ) {
                       Integer rowNumber = this.allRowValue.indexOf(rowCase) + 2;
                       createRecordMap.put(rowCase, err.getMessage() + errorRowMessage + rowNumber);
                       if (this.failureMap == null) {
                           this.failureMap = new Map<List<String>, String>();
                       }
                       this.failureMap.put(rowCase, err.getMessage() + errorRowMessage + rowNumber);
                   }
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