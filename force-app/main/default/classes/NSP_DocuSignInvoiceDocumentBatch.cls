//
// @description  : Batch Class to generate invoice documents using DocuSIgn CLM API
// @author Rakesh Das
// @date 02/16/2023
// Name : NSP_DocuSignInvoiceDocumentBatch
//
public class NSP_DocuSignInvoiceDocumentBatch implements Schedulable , Database.Batchable<SObject> , Database.Stateful , Database.AllowsCallouts {
    // test w/ NSP_DocuSignInvoiceDocumentBatchTest (90%)

    //
    // Schedulable
    //

    public void execute( SchedulableContext sc ) {
        if ( NSP_DocuSignInvoiceDocumentBatch.isEnabled ) {
            Database.executeBatch(
                new NSP_DocuSignInvoiceDocumentBatch() ,
                Integer.valueOf( NSP_DocuSignInvoiceDocumentBatch.batchSize )
            );
        }
    }

    //
    // Batchable
    //

    private List<String> invcIdList = null;
    private List<String> processedInvcNumbers = new List<String>();
    private Map<Id,String> processedInvMap = new Map<Id,String>();

    public NSP_DocuSignInvoiceDocumentBatch() {
    }

    public NSP_DocuSignInvoiceDocumentBatch( List<String> sfInvIds ) {
        this.invcIdList = sfInvIds;
    }

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        if ( bc != null ) {
            AsyncApexJob job = this.selectAsyncApexJob( bc.getJobId() );
            if ( !Test.isRunningTest() ) {
                this.sendEmailNotification(
                    job ,
                    'The batch apex job started.'
                );
            }
        }
        Database.QueryLocator locator = Database.getQueryLocator(
            [
                SELECT
                    Id ,
                    Name ,
                    blng__InvoiceStatus__c
                FROM blng__Invoice__c
                WHERE (
                    blng__InvoiceStatus__c = 'Posted'
                    AND NSP_Invoice_Email_Sent__c = false
                    AND NSP_Invoice_External_ID__c = null
                )
                LIMIT 10000
            ]
        );
        if ( this.invcIdList != null ) {
            locator = Database.getQueryLocator(
                [
                    SELECT
                        Id ,
                        Name ,
                        blng__InvoiceStatus__c
                    FROM blng__Invoice__c
                    WHERE (
                        Id IN :this.invcIdList
                        AND blng__InvoiceStatus__c = 'Posted'
                        AND NSP_Invoice_External_ID__c = null
                    )
                    LIMIT 10000
                ]
            );
        }
        return locator;
    }

    public void execute( Database.BatchableContext bc , List<blng__Invoice__c> scope ) {
        if ( NSP_DocuSignInvoiceDocumentBatch.isEnabled ) {
            try {
                List<String> invIdsToGenerateDocs = new List<String> ();
                for ( blng__Invoice__c inv : scope ) {
                    invIdsToGenerateDocs.add( inv.id );
                    this.processedInvMap.put( inv.Id, inv.Name );
                }
                //Only Generate Docs when the Docs on the invoice is missing
                List<String> finalInvIdsToGenerateDocs =  getInvoicesMissingAttachments(invIdsToGenerateDocs).get('withoutAttachments');

                if ( finalInvIdsToGenerateDocs != null && !finalInvIdsToGenerateDocs.isEmpty() ) {
                     //Get the InvoiceNumbers for the finalInvIdsToGenerateDocs to send in email
                    for(String invoiceId: finalInvIdsToGenerateDocs){
                        if(processedInvMap.containsKey(invoiceId)){
                            this.processedInvcNumbers.add(processedInvMap.get(invoiceId));
                        }
                    }
                    // method to call DocuSign CLM API to invoke workflows
                    NSP_DocuSignRESTUtility.startInvoiceWorkflow( finalInvIdsToGenerateDocs );
                }
            } catch( Exception e ) {
                NSP_DocuSignInvoiceDocumentBatch.handleException(e,'execute');
            }
        }
    }

    public void finish( Database.BatchableContext bc ) {
        if ( bc != null ) {
            AsyncApexJob job = this.selectAsyncApexJob( bc.getJobId() );
            this.sendEmailNotification(
                job ,
                'The batch apex job processed ' + job.TotalJobItems
                + ' batches with ' + job.NumberOfErrors + ' failures.'
                + ' Total Records :' + this.processedInvcNumbers.size() + '\n'
                + '\n'
                + 'Invoice Numbers : \n'+ String.join( this.processedInvcNumbers , ',' )
            );
        }
    }

    public static Map<String, List<String>> getInvoicesMissingAttachments(List<String> invIdsToGenerateDocsStr) {
        Map<String, List<String>> resultMap = new Map<String, List<String>>();
        List<String> invWithAttachments = new List<String>();
        List<String> invWithoutAttachments = new List<String>();

        if (invIdsToGenerateDocsStr != null || !invIdsToGenerateDocsStr.isEmpty()) {

            for (ContentDocumentLink link : [
                SELECT LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :invIdsToGenerateDocsStr
            ]) {
                invWithAttachments.add(link.LinkedEntityId);
            }

            for (String idStr : invIdsToGenerateDocsStr) {
                if (!invWithAttachments.contains(idStr)) {
                    invWithoutAttachments.add(idStr);
                }
            }
        }
        resultMap.put('withAttachments', invWithAttachments);
        resultMap.put('withoutAttachments', invWithoutAttachments);
        return resultMap;
	}

    private AsyncApexJob selectAsyncApexJob( String jobId ) {
        List<AsyncApexJob> jobs = null;
        if ( String.isNotBlank( jobId ) ) {
            jobs = [
                SELECT Id , Status , NumberOfErrors , JobItemsProcessed , TotalJobItems , CreatedBy.Email
                FROM AsyncApexJob
                WHERE ( Id = :jobId )
            ];
        }
        AsyncApexJob job = null;
        if ( ( jobs != null ) && !jobs.isEmpty() ) {
            job = jobs[0];
        }
        return job;
    }

    private void sendEmailNotification( AsyncApexJob job , String plainTextBody ) {
        try {
            if ( EmailDeliverabilityController.IsEnabledOutbound ) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                List<String> toAddresses = new List<String>();
                if ( job != null ) {
                    toAddresses.add( job.CreatedBy.Email );
                } else {
                    toAddresses.add( UserInfo.getUserEmail() );
                }
                mail.setToAddresses( toAddresses );
                if ( ( NSP_DocuSignInvoiceDocumentBatch.bccAddresses != null ) && !NSP_DocuSignInvoiceDocumentBatch.bccAddresses.isEmpty() ) {
                    mail.setBccAddresses( NSP_DocuSignInvoiceDocumentBatch.bccAddresses );
                }
                String statusSuffix = '';
                if ( job != null ) {
                    statusSuffix = ': ' + job.Status;
                }
                mail.setSubject( 'Docusign Invoice Generation Batch Job' + statusSuffix );
                if ( String.isBlank( plainTextBody ) ) {
                    plainTextBody = '.';
                }
                mail.setPlainTextBody( plainTextBody );
                Messaging.sendEmail( new Messaging.SingleEmailMessage[]{ mail } );
            }
        } catch ( Exception e ) {
            NSP_DocuSignInvoiceDocumentBatch.handleException(e,'sendEmailNotification');
        }
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a Scheduled job...
    //

    private static DocusignInvoiceDocumentBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = DocusignInvoiceDocumentBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( NSP_DocuSignInvoiceDocumentBatch.settings != null ) {
                    local = NSP_DocuSignInvoiceDocumentBatch.settings.IsEnabled__c;
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
                if ( ( NSP_DocuSignInvoiceDocumentBatch.settings != null )
                    && ( NSP_DocuSignInvoiceDocumentBatch.settings.BatchSize__c != null )
                    )
                {
                    local = NSP_DocuSignInvoiceDocumentBatch.settings.BatchSize__c.intValue();
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

    @AuraEnabled(cacheable=true)
    public static Integer getBatchSize() {
        return NSP_DocuSignInvoiceDocumentBatch.batchSize;
    }

    private static List<String> bccAddresses  {
        private get {
            if ( bccAddresses == null ) {
                List<String> local = new List<String>();
                if ( NSP_DocuSignInvoiceDocumentBatch.settings != null ) {
                    String rawBccAddresses = NSP_DocuSignInvoiceDocumentBatch.settings.BccAddresses__c;
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

      // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_DocuSignInvoiceDocumentBatch.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_DocuSignInvoiceDocumentBatch.class.getName() ,
            methodName ,
            e
        );
    }
}
//