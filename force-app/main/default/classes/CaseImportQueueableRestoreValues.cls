public class CaseImportQueueableRestoreValues implements Queueable {
	// test w/ FileUploadControllerTest (77%)
    private Id targetUserId;

    public CaseImportQueueableRestoreValues(Id targetUserId) {
        this.targetUserId = targetUserId;
    }

    public void execute(QueueableContext context) {
        try {
            // Restore the custom settings to their original values
            if( this.targetUserId != null ) {
                Case_Import_Tool_Settings__c settings = Case_Import_Tool_Settings__c.getInstance(this.targetUserId);
                if (settings != null) {
                    settings.Bypass_Opened_Date__c = false;
                    update settings;
                }    
                Notification_Deliverability_Settings__c notificationDeliverability = Notification_Deliverability_Settings__c.getInstance(this.targetUserId);
                if (notificationDeliverability != null) {
                    notificationDeliverability.IsEnabledOutbound__c = true;
                    update notificationDeliverability;
                }
                
                Email_Deliverability_Settings__c emailDeliverability = Email_Deliverability_Settings__c.getInstance(this.targetUserId);
                if (emailDeliverability != null) {
                    emailDeliverability.IsEnabledOutbound__c = true;
                    update emailDeliverability;
                }
            }
        } catch (Exception e) {
            NSP_ErrorLogHandler.logException(
                CaseImportQueueableRestoreValues.class.getName(),
                'execute',
                e
            );
        }
    }
}