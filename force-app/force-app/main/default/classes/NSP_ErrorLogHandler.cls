public class NSP_ErrorLogHandler {
    
 /**
* Dummy private constructor             
*                
*/  
    private NSP_ErrorLogHandler() {  }
    
    
        /**
* 
* @param className String holds the name of the class 
* @param methodName String holds the name of the method from the class 
* @param saveResultList List<Database.SaveResult> List of records that are processed as part of the batch
* @return void             
*                
*/
    public static void logSaveResult(String className, String methodName, List<Database.SaveResult> saveResultList){
        List<NSP_Error_Log__c> logList = new List<NSP_Error_Log__c>();
        for (Database.SaveResult sr: saveResultList) {        
            if (!sr.isSuccess()) {                    
                NSP_Error_Log__c log = new NSP_Error_Log__c();
                log.NSP_Class__c = className;
                log.NSP_Method__c = methodName;                
                log.NSP_Description__c = String.valueOf(sr.getErrors()[0].getMessage());
                log.NSP_Record_Id__c = sr.getId();
                //Adding object to the list
                logList.add(log);  
            }
        }
        if(!logList.isEmpty()){
            //Inserting the record in the log object
            Insert logList;
        }   
    }
    
   
            /**
* 
* @param className String holds the name of the class 
* @param methodName String holds the name of the method from the class 
* @param message String holds the error message string
* @return void             
*                
*/
    public static void logSaveException(String className, String methodName, String message){
        //Creating a refernce for the log Object
        NSP_Error_Log__c log = new NSP_Error_Log__c();
        log.NSP_Class__c = className;
        log.NSP_Method__c = methodName;                
        log.NSP_Description__c = String.valueOf(message);
        
        //Inserting the record in the log object
        Insert log;
    }
}