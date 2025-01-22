public with sharing class EmailMessageQueueable implements Queueable {
    // test w/ NSP_EmailMessageTriggerHelperTest (100%)

    private List<EmailMessage> newEmailMessageList = null;
    private Map<Id,EmailMessage> newEmailMessageMap = null;

    public EmailMessageQueueable( List<EmailMessage> newList , Map<Id,EmailMessage> newMap ) {
        this.newEmailMessageList = newList;
        this.newEmailMessageMap = newMap;
    }

    public void execute( QueueableContext context ) {
        NSP_EmailMessageTriggerHelper oEmailMessageTriggerHelper = new NSP_EmailMessageTriggerHelper();
        oEmailMessageTriggerHelper.afterInsertionEmailMessage(
            (List<EmailMessage>)newEmailMessageList ,
            (Map<Id,EmailMessage>)newEmailMessageMap
        );
        NSP_EmailMessageTriggerHelper.updateEmailMessageFields( (List<EmailMessage>)newEmailMessageList );
    }

}
//