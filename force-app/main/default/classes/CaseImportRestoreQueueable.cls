public class CaseImportRestoreQueueable implements Queueable {
    // test w/ FileUploadControllerTest (77%)

    public static void enqueueJob() {
        if ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) {
            System.enqueueJob(
                new CaseImportRestoreQueueable() ,
                10
            );
        }
    }

    public void execute( QueueableContext context ) {
        try {
            // Restore the custom settings to their original values
            Case_Import_Tool_Settings__c settings = Case_Import_Tool_Settings__c.getInstance( UserInfo.getUserId() );
            if ( settings != null ) {
                settings.Bypass_Opened_Date__c = false;
                update settings;
            }
            Notification_Deliverability_Settings__c notificationDeliverability = Notification_Deliverability_Settings__c.getInstance( UserInfo.getUserId() );
            if ( notificationDeliverability != null ) {
                notificationDeliverability.IsEnabledOutbound__c = true;
                update notificationDeliverability;
            }
            Email_Deliverability_Settings__c emailDeliverability = Email_Deliverability_Settings__c.getInstance( UserInfo.getUserId() );
            if ( emailDeliverability != null ) {
                emailDeliverability.IsEnabledOutbound__c = true;
                update emailDeliverability;
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                CaseImportRestoreQueueable.class.getName() ,
                'execute' ,
                e
            );
        }
    }

}
//