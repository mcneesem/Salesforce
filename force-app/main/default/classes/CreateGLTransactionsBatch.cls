public with sharing class CreateGLTransactionsBatch implements Database.Batchable<sObject> {
    // test w/ CreateGLTransactionsTest (86%)

    private static final String POSITIVE_ENTRY = 'Positive';
    private static final String NEGATIVE_ENTRY = 'Negative';
    private static final String GREATER_ENTRY = 'Greater';
    private static final String LESSER_ENTRY = 'Lesser';
    private static final String DELIMITTER = '_';
    private static final Map<String,String> objectAPINameMap = new Map<String,String>{
        'blng__InvoiceLine__c' => 'Invoice',
        'blng__CreditNoteLine__c' => 'Credit_Note',
        'blng__DebitNoteLine__c' => 'Debit_Note',
        'blng__Payment__c' => 'Payment',
        'blng__Refund__c' => 'Refund',
        'blng__RevenueTransaction__c' => 'Revenue_Schedule'
    };
    private static final Map<String,String> fieldAPIMap = new Map<String,String>{
        'blng__Subtotal__c' => 'Subtotal',
        'blng__TaxAmount__c' => 'TaxAmount',
        'blng__Amount__c' => 'Amount',
        'blng__RevenueAmount__c' => 'RevenueAmount'
    };
    //Used in chaining the batch jobs
    private static final Map<String,String> batchObjectApiMap = new Map<String,String>{
        'blng__InvoiceLine__c' => 'blng__CreditNoteLine__c',
        'blng__CreditNoteLine__c' => 'blng__DebitNoteLine__c',
        'blng__DebitNoteLine__c' => 'blng__Payment__c',
        'blng__Payment__c' => 'blng__Refund__c',
        'blng__Refund__c' => 'blng__RevenueTransaction__c'
    };
    //used in execute method to process the desired fields(fixed) for each object(fixed)
    private static final Map<String, List<String>> fieldsToProcessMap = new Map<String,List<String>>{
        'blng__InvoiceLine__c' => new List<String>{'blng__Subtotal__c','blng__TaxAmount__c'},
        'blng__CreditNoteLine__c' => new List<String>{'blng__Subtotal__c','blng__TaxAmount__c'},
        'blng__DebitNoteLine__c' => new List<String>{'blng__Subtotal__c','blng__TaxAmount__c'},
        'blng__Payment__c' => new List<String>{'blng__Amount__c'},
        'blng__Refund__c' => new List<String>{'blng__Amount__c'},
        'blng__RevenueTransaction__c' => new List<String>{'blng__RevenueAmount__c'}
    };
    private final Map<String,String> metadataTreatmentMap = createMetadataMap();

    //list of all finance periods
    private List<Id> financeperiods;
    private Id glPeriodId;
    private String objectAPI;

    public CreateGLTransactionsBatch (List<Id> financeperiodsList,Id glPeriod, String objectAPI){
        this.financeperiods = financeperiodsList;
        this.glPeriodId = glPeriod;
        this.objectAPI = objectAPI;
    }

    // Start method to query all 6 Objects: InvoiceLine, CreditNoteLine, DebitNoteLine, Payment, Refund, RevenueTransactions records
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        //construct queries for objects
        //each object has different fields and condtions
        String query = '';
        String fields = null;
        string filters = null;
        switch on objectAPI {
            when 'blng__InvoiceLine__c'{
                fields = 'Id, Processed_GL_Transactions__c, NSP_Tax_Credit_GL_Account_Number__c, NSP_Tax_Debit_GL_Account_Number__c, NSP_Billing_Credit_GL_Account_Number__c, NSP_Billing_Debit_GL_Account_Number__c,blng__Subtotal__c, blng__TaxAmount__c';
                filters = ' WHERE blng__billingFinancePeriod__c IN :financeperiods AND (blng__InvoiceLineStatus__c = \'Posted\' OR blng__InvoiceLineStatus__c = \'Rebilled\') AND Processed_GL_Transactions__c = false AND (blng__Subtotal__c != 0 OR blng__TaxAmount__c != 0)';
            }
            when 'blng__CreditNoteLine__c'{
                fields = 'Id, Processed_GL_Transactions__c, NSP_Tax_Credit_GL_Account_Number__c, NSP_Tax_Debit_GL_Account_Number__c, NSP_Billing_Credit_GL_Account_Number__c, NSP_Billing_Debit_GL_Account_Number__c,blng__Subtotal__c, blng__TaxAmount__c';
                filters = ' WHERE blng__FinancePeriod__c IN :financeperiods AND blng__Status__c = \'Posted\' AND Processed_GL_Transactions__c = false AND (blng__Subtotal__c != 0 OR blng__TaxAmount__c != 0)';
            }
            when 'blng__DebitNoteLine__c'{
                fields = 'Id, Processed_GL_Transactions__c,NSP_Tax_Debit_GL_Account_Number__c,NSP_Billing_Debit_GL_Account_Number__c,NSP_Tax_Credit_GL_Account_Number__c, NSP_Billing_Credit_GL_Account_Number__c,blng__Subtotal__c, blng__TaxAmount__c ';
                filters = ' WHERE blng__FinancePeriod__c IN :financeperiods AND blng__Status__c = \'Posted\' AND Processed_GL_Transactions__c = false AND (blng__Subtotal__c != 0 OR blng__TaxAmount__c != 0)';
            }
            when 'blng__Payment__c'{
                fields = 'Id, Processed_GL_Transactions__c, NSP_Credit_GL_Account_Number__c, NSP_Debit_GL_Account_Number__c, blng__Amount__c ';
                filters = ' WHERE blng__billingFinancePeriod__c IN :financeperiods AND blng__Status__c = \'Posted\' AND Processed_GL_Transactions__c = false AND blng__Amount__c != 0';
            }
            when 'blng__Refund__c'{
                fields = 'Id, Processed_GL_Transactions__c, blng__Amount__c, NSP_Credit_GL_Account_Number__c, NSP_Debit_GL_Account_Number__c';
                filters = ' WHERE Finance_Period__c IN :financeperiods AND blng__Status__c = \'Posted\' AND Processed_GL_Transactions__c = false AND blng__Amount__c != 0';
            }
            when 'blng__RevenueTransaction__c'{
                fields = 'Id, Processed_GL_Transactions__c, blng__RevenueAmount__c,NSP_Debit_GL_Account_Number__c, NSP_Credit_GL_Account_Number__c';
                filters  = ' WHERE blng__RevenueFinancePeriod__c IN :financeperiods AND blng__Status__c = \'Recognized\' AND Processed_GL_Transactions__c = false AND blng__RevenueAmount__c != 0';
            }
            when else{
                //do nothing
            }
        }
        if ( String.isNotBlank( fields ) && String.isNotBlank( filters ) ) {
            query = 'SELECT '+ fields + ' FROM ' + objectAPI +  filters;
        }
        return Database.getQueryLocator(query);
    }

    // Execute method to process 200 records(by default) per object at a time
    public void execute( Database.BatchableContext bc , List<sObject> scope ) {
        if ( CreateGLTransactionsBatch.isEnabled ){
            List<GL_Transaction__c> insertList = new List<GL_Transaction__c>();
            //process current object
            if(!scope.isEmpty()){
                List<String> fieldApis = new List<String>();
                if(fieldsToProcessMap.containsKey(objectAPI)){
                    //get the list of fields we need to process for the current object
                    fieldApis = fieldsToProcessMap.get(objectAPI);
                }
                if(fieldApis.size()>0){
                    //process the object for each field
                    for(String fieldAPI: fieldApis){
                        processObject(scope,fieldAPI,insertList);
                    }
                }
                //clear heap
                fieldApis = null;
            }
            //insert GL transaction records
            if(insertList.size()>0){
                try {
                    List<Database.SaveResult> results = Database.insert( insertList , false );
                    NSP_ErrorLogHandler.logResults(
                        CreateGLTransactionsBatch.class.getName() ,
                        'execute:insert' ,
                        results
                    );
                } catch ( Exception e ) {
                    NSP_ErrorLogHandler.logException(
                        CreateGLTransactionsBatch.class.getName() ,
                        'execute:insert' ,
                        e
                    );
                } finally {
                    //clear heap
                    insertList = null;
                }
            }
            //mark all records that have gl_transactions as processed
            //use dynamic query to fetch only id and related list(constant)
            String query = 'SELECT id, Processed_GL_Transactions__c, GL_Transactions_Created__c, (SELECT id FROM GL_Transactions__r)'
                + ' FROM ' + objectAPI
                + ' WHERE id IN:scope';
            List<sObject> records = Database.query(query);
            if(!records.isEmpty()){
                for(sObject record: records){
                    //get realted GL transaction records
                    List<GL_Transaction__c> glRecords = record.getsObjects('GL_Transactions__r');
                    Decimal recordsCount = glRecords.size();
                    //check if GL_transaction records are created
                    if(recordsCount > 0 && recordsCount != null){
                        //mark parent object flag(constant across all objects) as true
                        record.put('Processed_GL_Transactions__c', true);
                        record.put('GL_Transactions_Created__c', recordsCount);
                    }
                }
                try {
                    List<Database.SaveResult> results = Database.update( records , false );
                    NSP_ErrorLogHandler.logResults(
                        CreateGLTransactionsBatch.class.getName() ,
                        'execute:update' ,
                        results
                    );
                } catch ( Exception e ) {
                    NSP_ErrorLogHandler.logException(
                        CreateGLTransactionsBatch.class.getName() ,
                        'execute:update' ,
                        e
                    );
                } finally {
                    //clear heap
                    records = null;
                    query = null;
                }
            }
        }
    }

    // Finish method that will chain all batch jobs for the objects
    public void finish( Database.BatchableContext bc ) {
        if ( CreateGLTransactionsBatch.isEnabled ){
            try {
                //chain the batchjobs
                String batchObjectApi = null;
                if ( batchObjectApiMap.containsKey( objectAPI ) ) {
                    batchObjectApi = batchObjectApiMap.get( objectAPI );
                }
                if ( String.isNotBlank( batchObjectApi ) ) {
                    Database.executeBatch(
                        new CreateGLTransactionsBatch(
                            financePeriods,
                            glPeriodId,
                            batchObjectApi
                        ),
                        CreateGLTransactionsBatch.batchSize
                    );
                }
                // error handler log exception - method finish -> object api name for every processed object
                //email when all objects have been processed
                if(objectAPI == 'blng__RevenueTransaction__c'){
                    //email success batch job
                    String userId = UserInfo.getUserId();
                    List<User> records = [ SELECT Email FROM User WHERE Id = :userId LIMIT 1 ];
                    User record = null;
                    if ( ( records != null ) && !records.isEmpty() ) {
                        record = records[0];
                    }
                    if ( ( record != null ) && String.isNotBlank( record.Email ) ) {
                        List<String> toUsers = new List<String>();
                        toUsers.add(record.Email);
                        if ( ( CreateGLTransactionsBatch.monitorEmailAddresses != null )
                            && !CreateGLTransactionsBatch.monitorEmailAddresses.isEmpty()
                            )
                        {
                            toUsers.addAll( CreateGLTransactionsBatch.monitorEmailAddresses );
                        }
                        CreateGLTransactionsBatch.sendEmail(
                            toUsers ,
                            'Create GL Transactions Batch Job Complete' ,
                            'Hello, your batch job has completed.'
                        );
                    }
                }
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    CreateGLTransactionsBatch.class.getName() ,
                    'finally:' +  objectAPI ,
                    e
                );
            }
        }
    }

    //method to create +ve and -ve gl transaction records together
    private List<GL_Transaction__c> createGLEntries(Decimal amount, String glType, sObject record, String initialKey){
        //initialize list to return
        List<GL_Transaction__c> listOfBothEnteries = new List<GL_Transaction__c>();
        if(record != null){
            //create +ve entry
            GL_Transaction__c positiveEntry = new GL_Transaction__c();
            positiveEntry.Amount__c = amount;
            positiveEntry.Type__c = glType;
            positiveEntry.GL_Treatment__c = getTreatment(record, initialKey + DELIMITTER + POSITIVE_ENTRY);
            positiveEntry.GL_Period__c = glPeriodId;
            positiveEntry.Line_ID__c = record.id;
            positiveEntry.Entry_Type__c = 'Positive';
            populateLookup(positiveEntry, record.id, glType);
            listOfBothEnteries.add(positiveEntry);
            //create -ve entry
            GL_Transaction__c negativeEntry = new GL_Transaction__c();
            negativeEntry.Amount__c = amount * (-1);
            negativeEntry.Type__c = glType;
            negativeEntry.GL_Treatment__c = getTreatment(record, initialKey + DELIMITTER + NEGATIVE_ENTRY);
            negativeEntry.GL_Period__c = glPeriodId;
            negativeEntry.Line_ID__c = record.id;
            negativeEntry.Entry_Type__c = 'Negative';
            populateLookup(negativeEntry, record.id, glType);
            listOfBothEnteries.add(negativeEntry);
        }
        //return both enteries
        return listOfBothEnteries;
    }

    //method to populate record lookup
    private void populateLookup(GL_Transaction__c glEntry, Id recordId, String glType){
        switch on glType{
            when 'Invoice'{
                glEntry.Invoice_Line__c = recordId;
            }
            when 'Credit_Note'{
                glEntry.Credit_Note_Line__c = recordId;
            }
            when 'Debit_Note'{
                glEntry.Debit_Note_Line__c = recordId;
            }
            when 'Payment'{
                glEntry.Payment__c = recordId;
            }
            when 'Refund'{
                glEntry.Refund__c = recordId;
            }
            when 'Revenue_Schedule'{
                glEntry.Revenue_Transaction__c = recordId;
            }
            when else{
                //do nothing
            }
        }
    }

    //method to get gl_treatment
    private string getTreatment(sObject record, String key){
        String gl_treatment = 'Code Error - CreateGLTransactionsBatch';
        if(record != null  && key != null){   
            String fieldApi = metadataTreatmentMap.get(key);
            if(fieldApi != null){
                Object fieldValue = record.get(fieldApi);
                if ( ( fieldValue != null ) && ( fieldValue InstanceOf String ) ) {
                    //desired value from records
                    gl_treatment = (String) fieldValue;
                }else{
                    gl_treatment = 'No Value Found on ' + record.getsObjectType() + ' record.';
                }
            }else{
                gl_treatment = 'Custom Metadata Record for - ' + key + ', not configured correctly.';
            }
        }
        return gl_treatment;
    }

    //general method to process all sObjects for GLtransaction record creation
    private void processObject(
        List<sObject> recordList ,
        String fieldAPI ,
        List<GL_Transaction__c> insertList
        )
    {
        if(recordList != null && !recordList.isEmpty()){
            //use any record to create the field map for that object
            Schema.sObjectType soType = recordList[0].getSobjectType();
            Schema.DescribeSObjectResult soTypeDescribe = soType.getDescribe();
            String sObjectAPIName = soTypeDescribe.getName();
            Map<String, Schema.SobjectField> fieldMap = soTypeDescribe.fields.getMap();
            if(fieldMap.containsKey(fieldAPI)){
                for(sObject record: recordList){
                    Object fieldValue = record.get(fieldAPI);
                    if(( ( fieldValue != null ) && ( fieldValue InstanceOf Decimal ) )){
                        //convert object to decimal for comparison
                        Decimal value = (Decimal)fieldValue;
                        //all amount fields will be datatype decimal
                        if(value != null && value != 0){
                            //create object_field base key
                            String metadataKey = objectAPINameMap.get(sObjectAPIName) + DELIMITTER + fieldAPIMap.get(fieldAPI);
                            if ( value > 0 ) {
                                //handle >0
                                metadataKey += DELIMITTER + GREATER_ENTRY;
                            } else {
                                //handle <0
                                metadataKey += DELIMITTER + LESSER_ENTRY;
                            }
                            //insert list of 2 enteries into cumulative list
                            insertList.addAll(createGLEntries(value, objectAPINameMap.get(sObjectAPIName), record, metadataKey));
                        }
                    }
                }
            }
            //clear heap
            fieldMap = NULL;
        }
    }

    private Map<String,String> createMetadataMap() {
        Map<String,String> metadataMap = new Map<String,String>();
        List<FinanceBillingGLTransactions__mdt> metadataRecords = [
            SELECT id, Type__c, Amount_Field__c, Value__c, Entry_Type__c, GL_Treatment_Source__c
            FROM FinanceBillingGLTransactions__mdt 
            WHERE IsActive__c = True
        ];
        for(FinanceBillingGLTransactions__mdt record: metadataRecords){
            string key = record.Type__c + DELIMITTER
                + record.Amount_Field__c + DELIMITTER
                + record.Value__c + DELIMITTER
                + record.Entry_Type__c;
            metadataMap.put(key,record.GL_Treatment_Source__c);
        }
        return metadataMap;
    }

    private static void sendEmail( String[] listOfToAddresses , String subject , String body ) {
        Map<String,Object> inputs = new Map<String,Object>();
        if (!listOfToAddresses.isEmpty()){
            inputs.put('toEmailAddresses', listOfToAddresses);
            inputs.put('emailSubject', subject);
            inputs.put('emailBody', body);
            Flow.Interview.Send_Email sendEmailFlow = new Flow.Interview.Send_Email(inputs);
            sendEmailFlow.start(); 
        }
    }

    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a running job...
    //

    private static GLTransactionsBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = GLTransactionsBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( CreateGLTransactionsBatch.settings != null ) {
                    local = CreateGLTransactionsBatch.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    public static Integer batchSize {
        public get {
            if ( batchSize == null ) {
                Integer local = 200;
                if ( ( CreateGLTransactionsBatch.settings != null )
                    && ( CreateGLTransactionsBatch.settings.BatchSize__c != null )
                   )
                {
                    local = CreateGLTransactionsBatch.settings.BatchSize__c.intValue();
                }
                // batch size must be greater than zero...
                if ( local < 1 ) {
                    local = 1;
                }
                // batch size must be less than or equal to 2000...
                if ( local > 2000 ) {
                    local = 2000;
                }
                batchSize = local;
            }
            return batchSize;
        }
        private set;
    }

    private static List<String> monitorEmailAddresses  {
        private get {
            if ( monitorEmailAddresses == null ) {
                List<String> local = new List<String>();
                if ( CreateGLTransactionsBatch.settings != null ) {
                    String rawMonitorEmailAddresses = CreateGLTransactionsBatch.settings.MonitorEmailAddresses__c;
                    if ( String.isNotBlank( rawMonitorEmailAddresses ) ) {
                        List<String> splitMonitorEmailAddresses = rawMonitorEmailAddresses.split( '\r\n' );
                        if ( ( splitMonitorEmailAddresses != null ) && ( splitMonitorEmailAddresses.size() > 0 ) ) {
                            local = splitMonitorEmailAddresses;
                        }
                    }
                }
                monitorEmailAddresses = local;
            }
            return monitorEmailAddresses;
        }
        private set;
    }

}
//