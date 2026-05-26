public with sharing class FinanceLogHandler {
    // test w/ FinanceLogHandlerTest (98%)

    private static final String NEW_LINE = '\r\n';

    // Log Platform Events
    public static void logPlatformEvents(
        String className ,
        String methodName ,
        List<Process_Billing_Event__e> events
        )
    {
        if ( ( events != null ) && !events.isEmpty() ) {
            FinanceLogHandler.insertLog(
                className ,
                methodName ,
                events
            );
        }
    }

    // Log Successful DML Operations
    public static void logResults(
        String className ,
        String methodName ,
        List<Database.SaveResult> results
        )
    {
        String recordId = FinanceLogHandler.getRecordID( results );
        String objectName = null;
        if ( String.isNotBlank( recordId ) && ( recordId InstanceOf Id ) ) {
            Id recordIdCheck = Id.valueOf( recordId );
            if ( recordIdCheck != null ) {
                objectName = String.valueOf( recordIdCheck.getSObjectType() );
            }
        }
        FinanceLogHandler.insertLog(
            className ,
            methodName ,
            objectName ,
            FinanceLogHandler.summarizeDatabaseResults( results ) ,
            recordId
        );
    }

    //Construct Event log description
    private static String buildMessage( Process_Billing_Event__e event ) {
        String result = null;
        List<String> messageParts = new List<String>();
        if ( event != null ) {
            if ( event.NSP_Action__c != null ) {
                messageParts.add( 'Action: ' + event.NSP_Action__c );
            }
            if ( event.NSP_Project_SF_Id__c != null ) {
                messageParts.add( 'Project ID: ' + event.NSP_Project_SF_Id__c );
            }
            if ( event.NSP_Project_Go_Live_Date__c != null ) {
                messageParts.add( 'Go Live Date: ' + String.valueOf( event.NSP_Project_Go_Live_Date__c ) );
            }
            if ( event.NSP_Invoice_Ready__c != null ) {
                messageParts.add( 'Invoice Ready: ' + String.valueOf( event.NSP_Invoice_Ready__c ) );
            }
        }
        if ( !messageParts.isEmpty() ) {
            result = String.join( messageParts , FinanceLogHandler.NEW_LINE );
        }
        return result;
    }

    //Construct DML log description
    private static String buildMessage( List<String> messageParts ) {
        String message = null;
        if ( ( messageParts != null ) && !messageParts.isEmpty() ) {
            message = String.join( messageParts , FinanceLogHandler.NEW_LINE );
        }
        return message;
    }

    //SUMMARIZE DATABASE RESULTS
    private static List<String> summarizeDatabaseResults( List<Database.SaveResult> results ) {
        List<String> messages = new List<String>();
        if ( results != null && !results.isEmpty() ) {
            // Collect errors
            messages.addAll( collectErrorMessages( results ) );
            // Collect and format successes
            List<Id> successIds = collectSuccessfulIds( results );
            messages.addAll( formatSuccessMessages( successIds ) );
        }
        return messages;
    }

    private static List<Id> collectSuccessfulIds( List<Database.SaveResult> results ) {
        List<Id> successIds = new List<Id>();
        for ( Database.SaveResult result : results ) {
            if ( result.isSuccess() ) {
                successIds.add( result.getId() );
            }
        }
        return successIds;
    }

    private static List<String> collectErrorMessages( List<Database.SaveResult> results ) {
        List<String> messages = new List<String>();
        for ( Database.SaveResult result : results ) {
            if ( !result.isSuccess() ) {
                messages.addAll(
                    NSP_ErrorLogHandler.summarizeDatabaseErrors(
                        result.getErrors() ,
                        result.getId()
                    )
                );
            }
        }
        return messages;
    }

    private static List<String> formatSuccessMessages( List<Id> successIds ) {
        List<String> messages = new List<String>();
        if ( successIds != null && !successIds.isEmpty() ) {
            Integer recordCount = successIds.size();
            Integer maxIds = Math.min( successIds.size(), 100 );
            messages.add( 'Successfully updated ' + recordCount + ' ' + ( recordCount > 1 ? 's' : '' ) );
            List<String> idStrings = new List<String>();
            for ( Integer i = 0 ; i < maxIds ; i++ ) {
                idStrings.add( String.valueOf( successIds[i] ) );
            }
            messages.add( 'Record IDs: ' + String.join( idStrings, ', ' ) );
            if ( successIds.size() > maxIds ) {
                messages.add( '... and ' + ( successIds.size() - maxIds ) + ' more' );
            }
        }
        return messages;
    }

    private static String getRecordID( List<Database.SaveResult> results ) {
        String result = null;
        List<Id> successId = new List<Id>();
        if ( ( results != null ) && !results.isEmpty() ) {
            for ( Database.SaveResult saveResult : results ) {
                if ( saveResult.isSuccess() ) {
                    successId.add( saveResult.getId() );
                }
            }
        }
        if ( successId != null && !successId.isEmpty() ) {
            result = String.valueOf( successId[0] );
        }
        return result;
    }

    //Method to prepare log for DML insert operations...
    private static Finance_Log__c buildLog(
        String className ,
        String methodName ,
        String objectName ,
        String message
        )
    {
        Finance_Log__c log = new Finance_Log__c();
        log.Class__c = SchemaController.safeText(
            className ,
            sObjectType.Finance_Log__c.Fields.Class__c
        );
        log.Method__c = SchemaController.safeText(
            methodName ,
            sObjectType.Finance_Log__c.Fields.Method__c
        );
        log.Object__c = SchemaController.safeText(
            objectName ,
            sObjectType.Finance_Log__c.Fields.Object__c
        );
        log.Description__c = SchemaController.safeText(
            message ,
            sObjectType.Finance_Log__c.Fields.Description__c
        );
        return log;
    }

    //Method to insert Event logs
    private static void insertLog(
        String className ,
        String methodName ,
        List<Process_Billing_Event__e> events
        )
    {
        List<Finance_Log__c> logsToInsert = new List<Finance_Log__c>();
        for ( Process_Billing_Event__e event : events ) {
            String message = FinanceLogHandler.buildMessage( event );
            if ( message != null ) {
                Finance_Log__c log = FinanceLogHandler.buildLog(
                    className ,
                    methodName ,
                    event.getSObjectType().getDescribe().getName() ,
                    message
                );
                if ( log != null ) {
                    log.Project_Id__c = SchemaController.safeText(
                        event.NSP_Project_SF_Id__c ,
                        sObjectType.Finance_Log__c.Fields.Project_Id__c
                    );
                    log.Event_UUID__c = SchemaController.safeText(
                        event.EventUuid ,
                        sObjectType.Finance_Log__c.Fields.Event_UUID__c
                    );
                    logsToInsert.add( log );
                }
            }
        }
        String debugPrefix = ' ~ FinanceLogHandler.insertLogs';
        System.debug( debugPrefix + ' ~ className=' + className );
        System.debug( debugPrefix + ' ~ methodName=' + methodName );
        System.debug( debugPrefix + ' ~ logsToInsert.size()=' + logsToInsert.size() );
        if ( !logsToInsert.isEmpty() ) {
            FinanceLogHandler.insertLogs( logsToInsert );
        }
    }

    private static void insertLog(
        String className ,
        String methodName ,
        String sObjectName ,
        List<String> messages ,
        String recordId
        )
    {
        FinanceLogHandler.insertLog(
            className ,
            methodName ,
            sObjectName ,
            FinanceLogHandler.buildMessage( messages ) ,
            recordId
        );
    }

    //Method to insert DML logs
    private static void insertLog(
        String className ,
        String methodName ,
        String objectName ,
        String message ,
        String recordId
        )
    {
        String debugPrefix = ' ~ FinanceLogHandler.insertSuccessLog';
        System.debug( debugPrefix + ' ~ className=' + className );
        System.debug( debugPrefix + ' ~ methodName=' + methodName );
        System.debug( debugPrefix + ' ~ objectName=' + objectName );
        System.debug( debugPrefix + ' ~ message=' + message );
        if ( message != null ) {
            Finance_Log__c log = FinanceLogHandler.buildLog(
                className ,
                methodName ,
                objectName ,
                message
            );
            if ( log != null ) {
                log.Record_Id__c = SchemaController.safeText(
                    recordId ,
                    sObjectType.Finance_Log__c.Fields.Record_Id__c
                );
                FinanceLogHandler.insertLogs( new List<Finance_Log__c>{ log } );
            }
        }
    }

    //Consolidated DML operation
    private static void insertLogs( List<Finance_Log__c> logs ) {
        if ( ( logs != null ) && !logs.isEmpty() ) {
            try {
                insert logs;
            } catch ( Exception e ) {
                System.debug( ' ~ FinanceLogHandler.insertLogs ~ Exception ~ ' + e );
            }
        }
    }

}
//