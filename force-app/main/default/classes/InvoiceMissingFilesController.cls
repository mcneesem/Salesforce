public with sharing class InvoiceMissingFilesController {

    @InvocableMethod(label='Run InvoiceMissingFilesAlert Batch Job')
    public static void executeBatch(List<Id> recIds) {
        System.debug('recIds: ' + recIds);
        if(recIds != null && !recIds.isEmpty()){
            try {
                List<blng__Invoice__c> allinvs = [
                    SELECT Id 
                    FROM blng__Invoice__c 
                    WHERE blng__InvoiceStatus__c = 'Posted' 
                        AND blng__InvoiceRunCreatedBy__c IN : recIds 
                    LIMIT 10000
                ];
    
                List<String> invsID = new List<String>();
                for (blng__Invoice__c inv : allinvs) {
                    invsID.add(inv.Id);
                }
                if(invsID != null && !invsID.isEmpty()){
                    Id batchJobId = Database.executeBatch(
                        new InvoiceMissingFilesAlertBatch(invsID),
                        batchSize
                    );
                }
    
            } catch (Exception e) {
                 NSP_ErrorLogHandler.logException(
                        InvoiceMissingFilesController.class.getName() ,
                        'executeBatch' ,
                        e
                 );    
            }
        }
    }

    private static InvoiceMissingFilesBatchSettings__c settings {
        private get {
            if (settings == null) {
                settings = InvoiceMissingFilesBatchSettings__c.getInstance(UserInfo.getUserId());
            }
            return settings;
        }
        private set;
    }

    public static Integer batchSize {
        private get {
            if (batchSize == null) {
                Integer local = 200;
                if (settings != null && settings.BatchSize__c != null) {
                    local = settings.BatchSize__c.intValue();
                }
                if (local < 1) local = 1;
                if (local > 2000) local = 2000;
                batchSize = local;
            }
            return batchSize;
        }
        private set;
    }
    
 	private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( settings != null ) {
                    local = settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }
    
 	private static List<String> bccAddresses  {
        private get {
            if ( bccAddresses == null ) {
                List<String> local = new List<String>();
                if ( settings != null ) {
                    String rawBccAddresses = settings.BccAddresses__c;
                    if ( String.isNotBlank( rawBccAddresses ) ) {
                        List<String> splitBccAddresses = rawBccAddresses.split( '\r\n' );
                        if ( ( splitBccAddresses != null ) && ( splitBccAddresses.size() > 0 ) ) {
                            local = splitBccAddresses;
                        }
                    }
                }
                bccAddresses = local;
            }
            return bccAddresses;
        }
        private set;
    }
}