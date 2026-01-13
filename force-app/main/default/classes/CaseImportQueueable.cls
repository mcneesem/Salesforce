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
    private static CaseFlowSettings__c flowSettings {
        private get {
            if ( flowSettings == null ) {
                flowSettings = CaseFlowSettings__c.getInstance( UserInfo.getUserId() );
            }
            return flowSettings;
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
                    && ( CaseImportQueueable.settings.Batch_Size_Case_Import__c != null )
                   )
                {
                    local = CaseImportQueueable.settings.Batch_Size_Case_Import__c.intValue();
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
    public CaseImportQueueable(List<Case> caseList,List<list<String>> allRowValue, Map<Case,list<String>> rowCaseMap,List<ID> caseSuccessList ,Map<list<String>,String> failureMap ) {
        this.caseList = caseList;
        this.allRowValue = allRowValue;
        this.rowCaseMap = rowCaseMap;
        this.caseSuccessList = caseSuccessList != null ? caseSuccessList : new List<ID>();
        this.failureMap = failureMap;
    }

    public void execute(QueueableContext context) {
        String errorRowMessage = '.Error occurred at row number - ';
        List<Case> batchList = this.dequeueNextBatch(); 

        Map<list<String>,String> createRecordMap = new Map<list<String>,String>();
        Database.SaveResult[] srList = Database.insert(batchList, false); 
        for (Integer i = 0; i < srList.size(); i++) {
            if (srList[i].isSuccess()) {
                caseSuccessList.add(srList[i].getId());
            } else {
                for (Database.Error err : srList[i].getErrors()) {
                    if(rowCaseMap.containskey(batchList[i]) && allRowValue.contains(rowCaseMap.get(batchList[i]))){
                        Integer rowNumber = allRowValue.indexof(rowCaseMap.get(batchList[i]))+2;
                        createRecordMap.put(rowCaseMap.get(batchList[i]), err.getMessage() + errorRowMessage + rowNumber);
                        failureMap.put(rowCaseMap.get(batchList[i]), err.getMessage() + errorRowMessage + rowNumber);
                    }
                }
            }
        }

        if (createRecordMap.size() > 0) {
            FileUploadController.createImportError(createRecordMap);
        }

        if (caseList.size() > 0) {
            System.enqueueJob(new CaseImportQueueable(caseList, allRowValue,rowCaseMap,caseSuccessList,failureMap ));
        } else {
            CaseImportQueueable.settings.Bypass_Opened_Date__c = false;
            update CaseImportQueueable.settings;
            CaseImportQueueable.flowSettings.IsEnabled__c = true;
            update CaseImportQueueable.flowSettings;
            CaseImportQueueable.emailSettings.IsEnabledOutbound__c = true;
            update CaseImportQueueable.emailSettings;
            FileUploadController.sendEmail(caseSuccessList, failureMap);
        }
    }

    // Returns and removes the next batch of Case records from caseList
    private List<Case> dequeueNextBatch() {
        List<Case> batchList = new List<Case>();
        if (caseList.size() > CaseImportQueueable.batchSize) {
            for (Integer i = 0; i < CaseImportQueueable.batchSize; i++) {
                if(caseList[0]!=null){
                    batchList.add(caseList[0]);
                    caseList.remove(0); 
                }
            }
        } else {
            batchList = caseList;
            caseList = new List<Case>();
        }
        return batchList;
    }
}