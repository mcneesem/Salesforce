//
// @description  : Batch Class to send email notification when invoice documents are missing using DocuSIgn CLM API
// @author Arun Dasari
// @date 02/16/2023
// Name : InvoiceMissingFilesAlertBatch
//
public class InvoiceMissingFilesAlertBatch implements Schedulable , Database.Batchable<SObject> , Database.Stateful , Database.AllowsCallouts {
    // test w/ InvoiceMissingFilesAlertBatchTest (87%)

    //
    // Schedulable
    //

    public void execute( SchedulableContext sc ) {
        if ( InvoiceMissingFilesAlertBatch.isEnabled ) {
            Database.executeBatch(
                new InvoiceMissingFilesAlertBatch() ,
                Integer.valueOf( InvoiceMissingFilesAlertBatch.batchSize )
            );
        }
    }

    //
    // Batchable
    //

    private List<String> invcIdList = null;
    private Map<Id,String> processedInvoicesMap = new Map<Id,String>();

    public InvoiceMissingFilesAlertBatch() {
    }

    public InvoiceMissingFilesAlertBatch( List<String> sfInvIds ) {
        this.invcIdList = sfInvIds;
    }

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        if ( bc != null ) {
            AsyncApexJob job = this.selectAsyncApexJob( bc.getJobId() );
            this.sendEmailNotification(
                job ,
                'The batch for sending notification job started.'
            );
        }
        Database.QueryLocator locator;
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
                    LIMIT :InvoiceMissingFilesAlertBatch.soqlInvoiceLimit
                ]
            );
        }else{
            locator = Database.getQueryLocator(
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
                    LIMIT :InvoiceMissingFilesAlertBatch.soqlInvoiceLimit
                ]
            );
        }
        return locator;
    }

    public void execute( Database.BatchableContext bc , List<blng__Invoice__c> scope ) {
        if ( InvoiceMissingFilesAlertBatch.isEnabled ) {
            try {
                for ( blng__Invoice__c inv : scope ) {
                    this.processedInvoicesMap.put( inv.id, inv.Name );
                }
            } catch( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    InvoiceMissingFilesAlertBatch.class.getName() ,
                    'execute' ,
                    e
                );
            }
        }
    }

    public void finish( Database.BatchableContext bc ) {
        Set<Id> invWithoutAttachments = new Set<Id>();
        List<String> invNumberWithoutAttachments = new List<String>();
        if ( ( processedInvoicesMap != null ) && !processedInvoicesMap.isEmpty()){
            invWithoutAttachments = getInvoicesMissingAttachments();
            if ( ( invWithoutAttachments != null ) && !invWithoutAttachments.isEmpty() ) {
                for ( Id invoiceId : invWithoutAttachments ) {
                    if ( processedInvoicesMap.containsKey( invoiceId ) ) {
                        invNumberWithoutAttachments.add( processedInvoicesMap.get( invoiceId ) );
                    }
                }
            }
        }
        if ( bc != null ) {
            AsyncApexJob job = this.selectAsyncApexJob( bc.getJobId() );
            String emailBody = 'The batch apex job processed ' + job.TotalJobItems
                + ' batches with Total Records : ' + this.processedInvoicesMap.values().size()
                + '\n'
                + '\n'
                + 'A Total of ' + invNumberWithoutAttachments.size() + ' Invoice Numbers are Missing attachments: \n';
            if(invNumberWithoutAttachments.size() > 0){
                emailBody += String.join(invNumberWithoutAttachments, ',');
            }
            this.sendEmailNotification(job , emailBody);
        }
    }

    private Set<Id> getInvoicesMissingAttachments() {
        Set<Id> invWithAttachments = new Set<Id>();
        Set<Id> invWithoutAttachments = new Set<Id>();
        if ( ( processedInvoicesMap != null )
            && ( processedInvoicesMap.keySet() != null )
            && !processedInvoicesMap.keySet().isEmpty()
            )
        {
            invWithoutAttachments = processedInvoicesMap.keySet();
            for ( ContentDocumentLink link : [
                        SELECT LinkedEntityId
                        FROM ContentDocumentLink
                        WHERE ( LinkedEntityId IN :processedInvoicesMap.keySet() )
                    ]
                )
            {
                invWithAttachments.add(link.LinkedEntityId);
            }
        }
        invWithoutAttachments.removeAll(invWithAttachments);
        return invWithoutAttachments;
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
                if ( ( InvoiceMissingFilesAlertBatch.bccAddresses != null ) && !InvoiceMissingFilesAlertBatch.bccAddresses.isEmpty() ) {
                    mail.setBccAddresses( InvoiceMissingFilesAlertBatch.bccAddresses );
                }
                String statusSuffix = '';
                if ( job != null ) {
                    statusSuffix = ': ' + job.Status;
                }
                mail.setSubject( 'Missing Invoice DocuSign files Batch Job' + statusSuffix );
                if ( String.isBlank( plainTextBody ) ) {
                    plainTextBody = '.';
                }
                mail.setPlainTextBody( plainTextBody );
                Messaging.sendEmail( new Messaging.SingleEmailMessage[]{ mail } );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                InvoiceMissingFilesAlertBatch.class.getName() ,
                'sendEmailNotification' ,
                e
            );
        }
    }

    private static InvoiceMissingFilesBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = InvoiceMissingFilesBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    public static Integer batchSize {
        public get {
            if ( batchSize == null ) {
                Integer local = 200;
                if ( ( settings != null ) && ( settings.BatchSize__c != null ) ) {
                    local = settings.BatchSize__c.intValue();
                }
                if ( local < 1 ) {
                    local = 1;
                }
                if ( local > 2000 ) {
                    local = 2000;
                }
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

    public static Integer soqlInvoiceLimit{
        public get {
            if ( soqlInvoiceLimit== null ) {
                Integer local = 10000;
                if ( ( settings != null )
                    && ( settings.SoqlInvoiceLimit__c != null )
                    )
                {
                    local = settings.SoqlInvoiceLimit__c.intValue();
                }
                // limit must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                soqlInvoiceLimit = local;
            }
            return soqlInvoiceLimit;
        }
        private set;
    }

}
//