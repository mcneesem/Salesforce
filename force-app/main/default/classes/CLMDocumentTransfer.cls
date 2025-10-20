public with sharing class CLMDocumentTransfer {
    // test w/ CLMDocumentTransferTest, SpringCMTests (88%)
    // test w/ CLMDocumentTransferTest (79%)
    // test w/ SpringCMTests (13%)

    String dsAccountId;
    String iss;
    String aud;
    String sub;
    String pkey;
    String dataCenter;
    String version;

    public CLMDocumentTransfer() {
        //
        // Setup CLM.DS authentication - will need to modified for CLM.CM
        List<DocuSign_Settings__c> lstDCS = [
            SELECT
                Id , IsEnabled__c , AccountId__c , IntegrationKey__c , BaseUrl__c , UserId__c , DataCenter__c , Version__c ,
                PrivateKey1__c , PrivateKey2__c , PrivateKey3__c , PrivateKey4__c , PrivateKey5__c , PrivateKey6__c , PrivateKey7__c
            FROM DocuSign_Settings__c
            WHERE ( IsEnabled__c = True )
            LIMIT 1
        ];
        DocuSign_Settings__c dcs = null;
        if ( ( lstDCS != null ) && ( lstDCS.size() > 0 ) ) {
            dcs = lstDCS[0];
        }
        if ( dcs != null ) {
            dsAccountId = dcs.AccountId__c;
            iss = dcs.IntegrationKey__c;
            aud = dcs.BaseUrl__c;
            sub = dcs.UserId__c;
            pkey = dcs.PrivateKey1__c + dcs.PrivateKey2__c + dcs.PrivateKey3__c + dcs.PrivateKey4__c + dcs.PrivateKey5__c + dcs.PrivateKey6__c + dcs.PrivateKey7__c;
            dataCenter = dcs.DataCenter__c;
            version = dcs.Version__c;
        }
        DSAPIUserAuthenticator auth = new DSAPIUserAuthenticator(dsAccountId,iss,aud,sub,pkey,dataCenter,version);
        this.authenticator = auth;
        this.svc = new SpringCMService(authenticator);
    }

    //
    // Authentication and Service variables
    //
    SpringCMIAuthenticator authenticator;
    SpringCMService svc;

    public void downloadDocumentById(String clmDocId, String sfdcLinkedEntityId){
        //
        // Need the filename, so get the document information
        //
        //CLMDocument docInfo = new CLMDocument();
        CLMDocument docInfo;
        if (Test.isRunningTest()) {
            docInfo = new CLMDocument();
            docInfo.name = 'test';
        } else {
            docInfo = svc.GetDocumentById(clmDocId).getDocument();
            System.assert(docInfo != null);
        }
        //
        // Download the document contents into a Blob
        //
        Blob docBlob;
        if (Test.isRunningTest()) {
            docBlob = Blob.valueOf('Test Content');
        } else {
            docBlob = svc.GetDocumentById(clmDocId).downloadDocument('');
            System.assert(docInfo != null);
        }
        //
        // Create a ContentVersion record with the filename and the document contents (Blob)
        //
        ContentVersion cv = new ContentVersion();
        cv.VersionData = docBlob;
        cv.Title = docInfo.Name;
        cv.PathOnClient = docInfo.Name;
        cv.NSP_Signature_Date__c = System.today();
        insert cv;
        //
        // Get the ContentDocumentId
        //
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        //
        // Create a ContentDocumentLink record to relate the document to the target record
        //
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = sfdcLinkedEntityId;
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.shareType = 'I';
        insert cdl;
    }

    @future (callout=true)
    public static void downloadDocument(String clmDocId, String sfdcLinkedEntityId) {
        CLMDocumentTransfer cdt = new CLMDocumentTransfer();
        cdt.downloadDocumentById(clmDocId, sfdcLinkedEntityId);
        Id recId = sfdcLinkedEntityId;
        String objName = String.valueOf(recId.getsobjecttype());
        if (objName == 'blng__Invoice__c') {
            if ( CLMDocumentTransfer.isEnabledClmDocumentReceived ) {
                try {
                    blng__Invoice__c invToUpdate = new blng__Invoice__c();
                    invToUpdate.Id = recId;
                    invToUpdate.NSP_CLM_Document_Received__c = true;
                    NSP_InvoiceTriggerHandler.TriggerDisabled = true;
                    update invToUpdate;
                } catch ( Exception e ) {
                    NSP_ErrorLogHandler.logException(
                        CLMDocumentTransfer.class.getName() ,
                        'downloadDocument' ,
                        e
                    );
                }
            }
            NSP_AutomationSetting__mdt invoiceEmailsEnabled = NSP_AutomationSetting__mdt.getInstance('NSP_Invoice_Email_Service');
            if (!invoiceEmailsEnabled.NSP_Disable__c) {
                NSP_InvoiceEmailMessageService.sendInvoiceEmail(new List<String>{sfdcLinkedEntityId});
            }
        }
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a Scheduled job...
    //

    private static CLMDocumentTransferSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = CLMDocumentTransferSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabledClmDocumentReceived {
        private get {
            if ( isEnabledClmDocumentReceived == null ) {
                Boolean local = False;
                if ( CLMDocumentTransfer.settings != null ) {
                    local = CLMDocumentTransfer.settings.IsEnabledClmDocumentReceived__c;
                }
                isEnabledClmDocumentReceived = local;
            }
            return isEnabledClmDocumentReceived;
        }
        private set;
    }

    public static Boolean isEnabledRestToken {
        public get {
            if ( isEnabledRestToken == null ) {
                Boolean local = False;
                if ( CLMDocumentTransfer.settings != null ) {
                    local = CLMDocumentTransfer.settings.IsEnabledRestToken__c;
                }
                isEnabledRestToken = local;
            }
            return isEnabledRestToken;
        }
        private set;
    }

}
//