// 2021-07-20 ~ Utpal Utkalit ~ Class to capture custom exceptions to logs
public class NSP_CustomException extends Exception {
    // test w/ NSP_CustomExceptionTest (93%)

    //
    // DEPRECATED ~ see NSP_ErrorLogHandler.logException
    //

    //
    // PUBLIC
    //

    // primary entry point...
    // ~ 10 classes
    public static void logException( Exception e ) {
        NSP_CustomException.insertLog( e );
    }

    //
    // PRIVATE
    //

    private static void insertLog( Exception record ) {
        try {
            if ( record != null ) {
                String stackTrace = record.getStackTraceString().substringBefore( '\n' );
                String className = stackTrace.substringAfter( '.' ).substringBefore( '.' );
                String methodName = stackTrace.substringBefore( ':' ).substringAfter( className ).substringAfter( '.' );
                NSP_Exception_Log__c log = new NSP_Exception_Log__c();
                log.RecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'NSP_Exception_Log__c' , 'NSP_ApexException' );
                log.NSP_Error_Message__c = record.getTypeName() + ': ' + record.getMessage();
                log.NSP_ErrorSource__c = className + '.' + methodName;
                log.NSP_StackTrace__c = record.getStackTraceString();
                Database.insert( log );
            }
        } catch ( Exception e ) {
            System.debug( ' ~ CATCH ~ e=' + e );
            System.debug( ' ~ CATCH ~ e.getStackTraceString=' + e.getStackTraceString() );
        }
    }

}
//