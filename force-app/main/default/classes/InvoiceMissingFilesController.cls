public with sharing class InvoiceMissingFilesController {
    // test w/ InvoiceMissingFilesControllerTest (??%)

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
                 InvoiceMissingFilesController.handleException( e , 'executeBatch' );
            }
        }
    }
     // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            InvoiceMissingFilesController.handleException( e , methodName );
        }
    }
    
    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            InvoiceMissingFilesController.class.getName() ,
            methodName ,
            e
        );
    }
}