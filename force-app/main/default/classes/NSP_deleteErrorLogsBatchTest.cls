/**
* @description  : Test Class to delete old error logs
* @author Rakesh Das
* @date 08/05/2022
* Name : NSP_deleteErrorLogsBatchTest
*/

@isTest
public class NSP_deleteErrorLogsBatchTest {
    
    /**
* Method Name: setup
* Description: This method creates test data                
*/
    
    @testSetup static void setup(){
        List<NSP_Error_Log__c> elogs = new List<NSP_Error_Log__c>();
        for(Integer i=0;i<200;i++) {
            NSP_Error_Log__c log = new NSP_Error_Log__c();
            log.NSP_Class__c = 'Test Class';
            log.NSP_Method__c = 'Test Method';                
            log.NSP_Description__c = 'Test Message';
            elogs.add(log);
        }
        insert elogs;
    }

	
	@isTest
    public static void testDeleteErrorLogBatch() {
        
        Test.startTest();
        NSP_deleteErrorLogsBatch delbatch = new NSP_deleteErrorLogsBatch();
        database.executeBatch(delbatch);
		Test.stopTest();
        List<NSP_Error_Log__c> eLogs = [SELECT NSP_Class__c FROM NSP_Error_Log__c WHERE NSP_Class__c LIKE 'Test%'];
        System.assertEquals(0, eLogs.size());
    }
}