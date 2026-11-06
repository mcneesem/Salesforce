public class NSP_GenericEmailUtility {
    // test w/ NSP_GenericEmailUtilityTest (86%)

    //
    // Method to send emails.
    // @param  Email Messages - Type List of Messaging.SingleEmailMessage
    // @return Integer - Count of emails sent
    // @Author Rakesh Das
    // @Since September 2022
    //
    public static Integer sendSingleEmailMessages ( Messaging.SingleEmailMessage[] emailMessages , Boolean allOrNone ) {
        Integer emailSentCount = 0;
        try {
            if ( EmailDeliverabilityController.isEnabledOutbound ) {
                List<Messaging.SendEmailResult> results = Messaging.sendEmail( emailMessages , allOrNone );
                List<String> errorMessages = new List<String>();
                for ( Messaging.SendEmailResult res : results ) {
                    if ( res.isSuccess() ) {
                        emailSentCount += 1;
                    } else {
                        for ( Messaging.SendEmailError error : res.getErrors() ) {
                            errorMessages.add(
                                error.getStatusCode()
                                + ', '
                                + error.getMessage()
                                + ': ['
                                + String.join( error.getFields() , ', ' )
                                + ']'
                                + ' ('
                                + error.getTargetObjectId()
                                + ')'
                            );
                        }
                    }
                }
                if ( !errorMessages.isEmpty() ) {
                    NSP_ErrorLogHandler.logInfo(
                        NSP_GenericEmailUtility.class.getName() ,
                        'sendSingleEmailMessages' ,
                        String.join( errorMessages , '\r\n' )
                    );
                }
            }
        } catch( Exception e ) {
            NSP_GenericEmailUtility.handleException( e , 'sendSingleEmailMessages' );
            return emailSentCount;
        }
        return emailSentCount;
    }

    //
    // Method to generate emails.
    // @param  Email Messages Parameters - Subject, Body, TemplateId, OrgWideEmailId, recordId, TargetObjId, ToAddressList, CCAddressList
    // @return List of Email Messages - List of Messaging.SingleEmailMessage objects
    // @Author Rakesh Das
    // @Since September 2022
    //
    public static Messaging.SingleEmailMessage generateSingleMessageWithTemplate(
        String templateId ,
        String recordId ,
        String targetObjId ,
        String orgWideEmailId ,
        List<String> toAddressList ,
        List<String> ccAddressList ,
        String subject ,
        String plainTextBody
        )
    {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        try {
            mail.setWhatId( recordId );
            if ( String.isNotBlank( templateId ) ) {
                mail.setTemplateId( templateId );
                mail.setTargetObjectId( targetObjId );
            } else {
                mail.setSubject( subject );
                mail.setPlainTextBody( plainTextBody );
            }
            if ( String.isNotBlank( orgWideEmailId ) ) {
                mail.setOrgWideEmailAddressId( orgWideEmailId );
            }
            if ( toAddressList != null ) {
                mail.setToAddresses( toAddressList );
            }
            if ( ccAddressList != null ) {
                mail.setCcAddresses( ccAddressList );
            }
        } catch ( Exception e ) {
            NSP_GenericEmailUtility.handleException( e , 'generateSingleMessageWithTemplate' );
            mail = null;
        }
        return mail;
    }

    //
    // Method to get Template Id from Template Developer Name stored in Org.
    // @param  String templateDevName - Template Developer Name
    // @return String TemplateId
    // @Author Rakesh Das
    // @Since September 2022
    //
    public static String getTemplateIdFromDevName( String templateDevName ) {
        String templateId = null;
        if ( String.isNotBlank( templateDevName ) ) {
            try {
                List<EmailTemplate> emailTemplateStored = [
                    SELECT Id , DeveloperName
                    FROM EmailTemplate
                    WHERE DeveloperName = :templateDevName
                    LIMIT 1
                ];
                if( !emailTemplateStored.isEmpty()) {
                  templateId = emailTemplateStored[0].Id;
                }         
            } catch ( Exception e ) {
                NSP_GenericEmailUtility.handleException( e , 'getTemplateIdFromDevName' );
            }
        }
        return templateId;
    }

    //
    // Method to get TOrg Wide Address.
    // @param  String displayName
    // @return String orgWidAddress
    // @Author Rakesh Das
    // @Since January 2023
    //
    public static OrgWideEmailAddress getOrgWideAddress( String displayName ) {
        OrgWideEmailAddress orgWidAddress = null;
        try {
            List<OrgWideEmailAddress> orgWidAddressList = [
                SELECT Id , Address , DisplayName
                FROM OrgWideEmailAddress
                WHERE ( DisplayName = :displayName )
                LIMIT 1
            ];
            if(!orgWidAddressList.isEmpty()){
                orgWidAddress = orgWidAddressList[0];
            }
        } catch ( Exception e ) {
            NSP_GenericEmailUtility.handleException( e , 'getOrgWideAddress' );
        }
        return orgWidAddress;
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_GenericEmailUtility.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_GenericEmailUtility.class.getName() ,
            methodName ,
            e
        );
    }

}
//