/**
* @description  : Class to capture custom exceptions to logs
* @author Utpal Utkalit
* @date 07/20/2021
* Name : NSP_CustomException
*/

public class NSP_CustomException extends Exception {
    public static Id apexExceptionRectypeId = Schema.SObjectType.NSP_Exception_Log__c.getRecordTypeInfosByDeveloperName().get('NSP_ApexException').getRecordTypeId();
    
    public static void logException(Exception ex) {
        logException(ex,'','');
    }
    public static void logException(Exception ex, String ObjectName) {
        logException(ex,'',ObjectName);
    }

    /***********************************************************************************************
    * MethodType : Private
    * MethodName: logException
    * Description : logging exception 
    * Params:       Exception ex,String optionalOtherProcess,String ObjectName
    * ********************************************************************************************/
    private static void logException(Exception ex,String optionalOtherProcess,String ObjectName) {
        try{
            String stackTrace = ex.getStackTraceString().substringBefore('\n');
            String className = stackTrace.substringAfter('.').substringBefore('.');  
            String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');
            //Log information in object
            NSP_Exception_Log__c exc = new NSP_Exception_Log__c();
            exc.RecordTypeId= apexExceptionRectypeId;
            exc.NSP_Error_Message__c = ex.getMessage() + 'Exception Type: ' +ex.getTypeName();
            exc.NSP_ErrorSource__c=optionalOtherProcess +'Class: '+className+'**Method: '+methodName;
            exc.NSP_StackTrace__c = ex.getStackTraceString();
            database.insert(exc);            
        }
        finally {
        }
        
    }
}