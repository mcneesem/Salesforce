public with sharing class EmailTemplateRenderer {
    // test w/ EmailTemplateRendererTest (93%)

    //method to render email template for a single temr form
    @InvocableMethod(label='Render Email Templates')
    public static List<Output> renderTemplates( List<Input> inputs ) {
        List<Output> results = new List<Output>();
        for ( Input input : inputs ) {
            try {
                Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(
                    input.templateId , // templateId
                    input.whoId , // whoId
                    input.whatId // whatId
                );
                //construct email
                Output emailStructure = new Output();
                if ( email != null ) {
                    emailStructure.htmlBody = email.getHtmlBody();
                    emailStructure.plainTextBody = email.getPlainTextBody();
                    emailStructure.subject = email.getSubject();
                }
                results.add( emailStructure );
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    EmailTemplateRenderer.class.getName() ,
                    'renderTemplates' ,
                    e
                );
            }
        }
        return results;
    }

    public class Input {
        @InvocableVariable(label='Email Template Id' required=true)
        public String templateId;
        @InvocableVariable(label='Recipient Id' required=false)
        public String whoId;
        @InvocableVariable(label='Related Record Id' required=true)
        public String whatId;
    }

    public class Output {
        @InvocableVariable(label='Rendered HTML Body')
        public String htmlBody;
        @InvocableVariable(label='Rendered Plain Text Body')
        public String plainTextBody;
        @InvocableVariable(label='Rendered Subject')
        public String subject;
    }

}
//