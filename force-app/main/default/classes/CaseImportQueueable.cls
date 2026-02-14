public with sharing class CaseImportQueueable implements Queueable {
    // test w/ FileUploadControllerTest (88%)

    private List<Case> caseList = null;
    private List<Id> caseSuccessList = null;
    private List<List<String>> allRowValue = null;
    private Map<Case,List<String>> rowCaseMap = null;
    private Map<List<String>,String> failureMap = null;

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
        this.caseSuccessList = ( ( caseSuccessListLocal != null ) ? caseSuccessListLocal : new List<Id>() );
        this.failureMap = ( ( failureMapLocal != null ) ? failureMapLocal : new Map<List<String>, String>() );
    }

    public void execute( QueueableContext context ) {
        try {
            List<Case> batchList = this.dequeueNextBatch();
            List<Database.SaveResult> srList = null;
            Map<Id,Case> batchMap = new Map<Id,Case>();
            if ( ( batchList != null ) && !batchList.isEmpty() ) {
                srList = Database.insert( batchList , false );
                for ( Case recordIds : batchList ) {
                    if ( recordIds != null ) {
                        batchMap.put( recordIds.Id, recordIds );
                    }
                }
            }
            Map<List<String>,String> createRecordMap = this.getError( srList , batchMap );
            if ( !createRecordMap.isEmpty() ) {
                FileUploadController.createImportError( createRecordMap );
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
                FileUploadController.sendEmail( this.caseSuccessList , this.failureMap );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                CaseImportQueueable.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    private Map<List<String>,String> getError( List<Database.SaveResult> srList , Map<Id,Case> batchMap ) {
        Map<List<String>,String> createRecordMap = new Map<List<String>,String>();
        if ( ( srList != null ) && ( batchMap != null ) ) {
            for ( Database.SaveResult sr : srList ) {
                Case c = batchMap.get( sr.getId() );
                if ( c != null ) {
                    if ( sr.isSuccess() && ( this.caseSuccessList != null ) ) {
                        this.caseSuccessList.add( c.Id );
                    } else {
                        createRecordMap = this.getFailureMap( sr , c );
                    }
                }
            }
        }
        return createRecordMap;
    }

    private Map<List<String>,String> getFailureMap( Database.SaveResult sr , Case c ) {
        String errorRowMessage = '. Error occurred at row number - ';
        Map<List<String>,String> response = new Map<List<String>,String>();
        if ( ( this.rowCaseMap != null )
            && ( c != null )
            && ( this.rowCaseMap.get( c ) != null )
            && this.rowCaseMap.containsKey( c )
            && ( sr != null )
            && ( this.allRowValue != null )
            )
        {
            List<String> rowCase = this.rowCaseMap.get( c );
            if ( rowCase != null ) {
                for ( Database.Error err : sr.getErrors() ) {
                    if ( this.allRowValue.contains( rowCase ) ) {
                        Integer rowNumber = ( this.allRowValue.indexOf( rowCase ) + 2 );
                        String message = ( err.getMessage() + errorRowMessage + rowNumber );
                        response.put( rowCase , message );
                        if ( this.failureMap == null ) {
                            this.failureMap = new Map<List<String>, String>();
                        }
                        this.failureMap.put( rowCase , message );
                    }
                }
            }
        }
        return response;
    }

    // Returns and removes the next batch of Case records from caseList
    private List<Case> dequeueNextBatch() {
        List<Case> batchList = new List<Case>();
        if ( ( this.caseList != null ) && !this.caseList.isEmpty() ) {
            for ( Integer i = 0 ; i < CaseImportQueueable.batchSize ; i++ ) {
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

    //
    //
    //

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

}
//