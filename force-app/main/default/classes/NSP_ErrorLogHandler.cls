public with sharing class NSP_ErrorLogHandler {
    // test w/ NSP_ErrorLogHandlerTest (91%)

    private static final String NO_ERRORS_FOUND = 'No errors found.';
    private static final String NEW_LINE = '\r\n';

    //
    // PUBLIC
    //

    // primary entry point...
    public static void logException( String className , String methodName , Exception e ) {
        NSP_ErrorLogHandler.insertLog(
            className ,
            methodName ,
            null ,
            NSP_ErrorLogHandler.buildMessage( e )
        );
    }

    // primary entry point...
    public static void logResults( String className , String methodName , List<Database.SaveResult> results ) {
        NSP_ErrorLogHandler.insertLog(
            className ,
            methodName ,
            null ,
            NSP_ErrorLogHandler.summarizeDatabaseResults( results )
        );
    }

    // primary entry point...
    public static void logResults( String className , String methodName , List<Database.UpsertResult> results ) {
        NSP_ErrorLogHandler.insertLog(
            className ,
            methodName ,
            null ,
            NSP_ErrorLogHandler.summarizeDatabaseResults( results )
        );
    }

    // primary entry point...
    public static void logResults( String className , String methodName , List<Database.DeleteResult> results ) {
        NSP_ErrorLogHandler.insertLog(
            className ,
            methodName ,
            null ,
            NSP_ErrorLogHandler.summarizeDatabaseResults( results )
        );
    }

    // primary entry point...
    public static void logInfo( String className , String methodName , String info ) {
        NSP_ErrorLogHandler.insertLog(
            className ,
            methodName ,
            null ,
            info
        );
    }

    // primary entry point...
    public static void logInfo( String className , String methodName , String objectName , String info ) {
        NSP_ErrorLogHandler.insertLog(
            className ,
            methodName ,
            objectName ,
            info
        );
    }

    //
    // DEPRECATED
    //

    // DEPRECATED ~ see logException
    // ~ 46 classes
    public static void logSaveException( String className , String methodName , String message ) {
        NSP_ErrorLogHandler.insertLog(
            className ,
            methodName ,
            null ,
            message
        );
    }

    // DEPRECATED ~ see logResults
    // ~ 6 classes
    public static void logSaveResult( String className , String methodName , List<Database.SaveResult> saveResultList ) {
        NSP_ErrorLogHandler.logResults(
            className ,
            methodName ,
            saveResultList
        );
    }

    // DEPRECATED ~ see logResults
    // ~ 16 classes
    public static void logSaveResultsException( String className , String methodName , List<Database.SaveResult> results ) {
        NSP_ErrorLogHandler.logResults(
            className ,
            methodName ,
            results
        );
    }

    // DEPRECATED ~ see logResults
    // ~ 3 classes
    public static void logDeleteResultsException( String className , String methodName , List<Database.DeleteResult> results ) {
        NSP_ErrorLogHandler.logResults(
            className ,
            methodName ,
            results
        );
    }

    //
    // SUMMARIZE DATABASE RESULTS
    //

    public static List<String> summarizeDatabaseErrors( List<Database.Error> errors , Id recordId ) {
        List<String> messages = new List<String>();
        if ( ( errors != null ) && !errors.isEmpty() ) {
            for ( Database.Error error : errors ) {
                messages.add(
                    error.getStatusCode()
                    + ', '
                    + error.getMessage()
                    + ': ['
                    + String.join( error.getFields() , ', ' )
                    + ']'
                    + ' ('
                    + recordId
                    + ')'
                );
            }
        }
        return messages;
    }

    private static List<String> summarizeDatabaseResults( List<Database.SaveResult> results ) {
        List<String> messages = new List<String>();
        if ( ( results != null ) && !results.isEmpty() ) {
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
        }
        if ( messages.isEmpty() ) {
            messages.add( NSP_ErrorLogHandler.NO_ERRORS_FOUND );
        } else {
            messages.add( NSP_ErrorLogHandler.getStackTraceString() );
        }
        return messages;
    }

    private static List<String> summarizeDatabaseResults( List<Database.UpsertResult> results ) {
        List<String> messages = new List<String>();
        if ( ( results != null ) && !results.isEmpty() ) {
            for ( Database.UpsertResult result : results ) {
                if ( !result.isSuccess() ) {
                    messages.addAll(
                        NSP_ErrorLogHandler.summarizeDatabaseErrors(
                            result.getErrors() ,
                            result.getId()
                        )
                    );
                }
            }
        }
        if ( messages.isEmpty() ) {
            messages.add( NSP_ErrorLogHandler.NO_ERRORS_FOUND );
        } else {
            messages.add( NSP_ErrorLogHandler.getStackTraceString() );
        }
        return messages;
    }

    private static List<String> summarizeDatabaseResults( List<Database.DeleteResult> results ) {
        List<String> messages = new List<String>();
        if ( ( results != null ) && !results.isEmpty() ) {
            for ( Database.DeleteResult result : results ) {
                if ( !result.isSuccess() ) {
                    messages.addAll(
                        NSP_ErrorLogHandler.summarizeDatabaseErrors(
                            result.getErrors() ,
                            result.getId()
                        )
                    );
                }
            }
        }
        if ( messages.isEmpty() ) {
            messages.add( NSP_ErrorLogHandler.NO_ERRORS_FOUND );
        } else {
            messages.add( NSP_ErrorLogHandler.getStackTraceString() );
        }
        return messages;
    }

    private static String getStackTraceString() {
        return NSP_ErrorLogHandler.NEW_LINE
            + (new CustomException()).getStackTraceString();
    }

    private class CustomException extends Exception {}

    //
    // PRIVATE
    //

    private static String buildMessage( Exception e ) {
        String message = null;
        if ( e != null ) {
            message = ''
                + e.getTypeName() + ': ' + e.getMessage() + NSP_ErrorLogHandler.NEW_LINE
                + NSP_ErrorLogHandler.NEW_LINE
                + e.getStackTraceString()
                ;
        }
        return message;
    }

    private static String buildMessage( List<String> messages ) {
        String message = null;
        if ( ( messages != null ) && !messages.isEmpty() ) {
            message = String.join(
                messages ,
                NSP_ErrorLogHandler.NEW_LINE
            );
        }
        return message;
    }

    private static void insertLog( String className , String methodName , String sObjectName , List<String> messages ) {
        NSP_ErrorLogHandler.insertLog(
            className ,
            methodName ,
            sObjectName ,
            NSP_ErrorLogHandler.buildMessage( messages )
        );
    }

    private static void insertLog( String className , String methodName , String sObjectName , String message ) {
        NSP_Error_Log__c log = new NSP_Error_Log__c();
        log.NSP_Class__c = SchemaController.safeText(
            className ,
            sObjectType.NSP_Error_Log__c.Fields.NSP_Class__c
        );
        log.NSP_Method__c = SchemaController.safeText(
            methodName ,
            sObjectType.NSP_Error_Log__c.Fields.NSP_Method__c
        );
        log.NSP_Object__c = SchemaController.safeText(
            sObjectName ,
            sObjectType.NSP_Error_Log__c.Fields.NSP_Object__c
        );
        log.NSP_Description__c = SchemaController.safeText(
            message ,
            sObjectType.NSP_Error_Log__c.Fields.NSP_Description__c
        );
        String debugPrefix = ' ~ NSP_ErrorLogHandler.insertLog';
        System.debug( debugPrefix + ' ~ className=' + className );
        System.debug( debugPrefix + ' ~ methodName=' + methodName );
        System.debug( debugPrefix + ' ~ message=' + message );
        if ( message != NSP_ErrorLogHandler.NO_ERRORS_FOUND ) {
            try {
                insert log;
            } catch ( Exception e ) {
                System.debug( debugPrefix + ' ~ CATCH ~ e=' + e );
            }
        }
    }

}
//