public with sharing class UpdateInvoiceLinesBatch implements Database.Batchable<sObject> {
    // test w/ UpdateInvoiceLinesControllerTest (87%)

    //
    // External Entry Point
    //

    public static void executeBatch( List<Id> invoiceRunIds ) {
        if ( ( invoiceRunIds != null ) && ( !invoiceRunIds.isEmpty() ) ) {
            Database.executeBatch(
                new UpdateInvoiceLinesBatch( invoiceRunIds ) ,
                UpdateInvoiceLinesBatch.batchSize
            );
        }
    }

    //
    // Batchable
    //

    private List<Id> invoiceRunIds;

    private UpdateInvoiceLinesBatch(List<Id> localInvoiceRunIds){
        this.invoiceRunIds = localInvoiceRunIds;
    }

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        List<Id> idList = new List<Id>();
        if ( ( this.invoiceRunIds != null ) && ( !this.invoiceRunIds.isEmpty() ) ) {
            idList = this.invoiceRunIds;
        }
        return Database.getQueryLocator(
            [
                SELECT
                    Id ,
                    Invoice_Run_Completed__c
                FROM blng__InvoiceLine__c
                WHERE ( blng__InvoiceRun__c IN :idList )
            ]
        );
    }

    public void execute( Database.BatchableContext bc , List<blng__InvoiceLine__c> scope ) {
        if ( ( scope != null )
            && ( !scope.isEmpty() )
            && ( UpdateInvoiceLinesBatch.isEnabled )
            )
        {
            for ( blng__InvoiceLine__c invoiceLine : scope ) {
                invoiceLine.Invoice_Run_Completed__c = true;
            }
            try {
                Database.SaveResult[] invoiceLinesSaveResult = Database.update( scope , false );
                NSP_ErrorLogHandler.logResults(
                    UpdateInvoiceLinesBatch.class.getName() ,
                    'execute',
                    invoiceLinesSaveResult
                );
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    UpdateInvoiceLinesBatch.class.getName() ,
                    'execute' ,
                    e
                );
            }
        }
    }

    public void finish( Database.BatchableContext bc ) {
        try {
            if ( UpdateInvoiceLinesBatch.isEnabled
                && ( this.invoiceRunIds != null )
                && !this.invoiceRunIds.isEmpty()
                )
            {
                List<blng__InvoiceRun__c> invoiceRuns = [
                    SELECT Id , Ready_For_Posting__c
                    FROM blng__InvoiceRun__c
                    WHERE ( Id IN :this.invoiceRunIds )
                ];
                for ( blng__InvoiceRun__c invoiceRun : invoiceRuns ) {
                    invoiceRun.Ready_For_Posting__c = true;
                }
                List<Database.SaveResult> results = Database.update( invoiceRuns , false );
                NSP_ErrorLogHandler.logResults(
                    UpdateInvoiceLinesBatch.class.getName() ,
                    'finish:update',
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                UpdateInvoiceLinesBatch.class.getName() ,
                'finish' ,
                e
            );
        }
    }

    //
    // Custom Settings
    //

    private static UpdateInvoiceLinesBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = UpdateInvoiceLinesBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private  get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( UpdateInvoiceLinesBatch.settings != null ) {
                    local = UpdateInvoiceLinesBatch.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    private static Integer batchSize {
        private get {
            if ( batchSize == null ) {
                Integer local = 200;
                if ( ( UpdateInvoiceLinesBatch.settings != null )
                    && ( UpdateInvoiceLinesBatch.settings.BatchSize__c != null )
                   )
                {
                    local = UpdateInvoiceLinesBatch.settings.BatchSize__c.intValue();
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

}
//