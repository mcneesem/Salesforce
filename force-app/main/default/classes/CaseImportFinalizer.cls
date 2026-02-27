public class CaseImportFinalizer implements Finalizer {
    // test w/ FileUploadControllerTest (100%)
    public void execute(FinalizerContext ctx) {
        try {
            CaseImportFinalizer.settings.Bypass_Opened_Date__c = false;
            update CaseImportFinalizer.settings;
            CaseImportFinalizer.emailDeliverability.IsEnabledOutbound__c = true;
            update CaseImportFinalizer.emailDeliverability;
            CaseImportFinalizer.notificationDeliverability.IsEnabledOutbound__c = true;
            update CaseImportFinalizer.notificationDeliverability;
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                CaseImportFinalizer.class.getName() ,
                'execute' ,
                e
            );
        }
    }
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
}