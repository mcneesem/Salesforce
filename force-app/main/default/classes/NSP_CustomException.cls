// 2021-07-20 ~ Utpal Utkalit ~ Class to capture custom exceptions to logs
public class NSP_CustomException extends Exception {
    // test w/ NSP_CustomExceptionTest (87%)

    public static Id apexExceptionRectypeId = Schema.SObjectType.NSP_Exception_Log__c.getRecordTypeInfosByDeveloperName().get( 'NSP_ApexException' ).getRecordTypeId();
    
    //
    // PUBLIC
    //

    // primary entry point...
    public static void logException( Exception ex ) {
        logException( ex );
    }

    //
    // DEPRECATED
    //

    // DEPRECATED ~ see logException( Exception )
    public static void logException( Exception ex , String ObjectName ) {
        logException( ex );
    }

    //
    // PRIVATE
    //

    private static void logException( Exception record ) {
        try {
            if ( record != null ) {
                String stackTrace = record.getStackTraceString().substringBefore( '\n' );
                String className = stackTrace.substringAfter( '.' ).substringBefore( '.' );
                String methodName = stackTrace.substringBefore( ':' ).substringAfter( className ).substringAfter( '.' );
                NSP_Exception_Log__c log = new NSP_Exception_Log__c();
                log.RecordTypeId = NSP_CustomException.apexExceptionRectypeId;
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