public with sharing class InvoiceMissingFilesController {

    @InvocableMethod(label='Run InvoiceMissingFilesAlert Batch Job')
    public static void executeBatch( List<Id> recIds ) {
        if ( ( recIds != null ) && !recIds.isEmpty() ) {
            try {
                List<blng__Invoice__c> allinvs = [
                    SELECT Id
                    FROM blng__Invoice__c
                    WHERE (
                        ( blng__InvoiceStatus__c = 'Posted' )
                        AND ( blng__InvoiceRunCreatedBy__c IN :recIds )
                    )
                    LIMIT :InvoiceMissingFilesAlertBatch.soqlInvoiceLimit
                ];
                List<String> invsID = new List<String>();
                for ( blng__Invoice__c inv : allinvs ) {
                    invsID.add( inv.Id );
                }
                if ( ( invsID != null ) && !invsID.isEmpty() ) {
                    Database.executeBatch(
                        new InvoiceMissingFilesAlertBatch( invsID ) ,
                        InvoiceMissingFilesAlertBatch.batchSize
                    );
                }
            } catch ( Exception e ) {
                 NSP_ErrorLogHandler.logException(
                        InvoiceMissingFilesController.class.getName() ,
                        'executeBatch' ,
                        e
                 );
            }
        }
    }

}
//