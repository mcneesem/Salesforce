/**
 * Represents test class for 
 * NSP_SingleRelatedListController
 * Author: Harsha Khiroya
 */

@isTest(SeeAllData=false)
public class NSP_SingleRelatedListControllerTest {
	@testSetup
    static void testData() {
		Account accoutObject = new Account();
            accoutObject.Name = 'Test Account';
            //inserting account object
            insert accoutObject;
    }
    
     @isTest
    static void testHistoryTrackingAView() {
    	String jsonData = '{\"fields\":\"NSP_Field_Name__c,NSP_Modified_Date__c,NSP_Old_Value__c,NSP_New_Value__c,\\tNSP_Modified_By__r.Name\",\"relatedFieldApiName\":\"NSP_Sobject_Record_Id__c\",\"recordId\":\"00111000028nQgoAAE\",\"numberOfRecords\":50001,\"sobjectApiName\":\"NSP_SObjects_History_Tracking__b\",\"sortedBy\":\"NSP_Modified_Date__c\",\"sortedDirection\":\"ASC\"}';
        Test.startTest();
        String output = NSP_SingleRelatedListController.initData(jsonData);
        Test.stopTest();
        system.assertNotEquals(null, output);
        
    }
    
    @isTest
    static void testDeleteRecord(){
        List<Account> accountList = [SELECT ID FROM ACCOUNT WHERE NAME = 'Test Account' ];
        Test.startTest();
        Boolean result = NSP_SingleRelatedListController.deleteRecord(accountList[0].id);
        Test.stopTest();
        system.assertEquals(true, result);
    }
    
    @isTest
    static void testDeleteNullRecord(){
        Boolean exceptionThrown = false;
        try{
            Test.startTest();
            Boolean result = NSP_SingleRelatedListController.deleteRecord(null);
        	Test.stopTest();	
        }catch (Exception e){
          exceptionThrown = true;
        }finally{
           system.assertEquals(true, exceptionThrown, 'Expected an exception to be thrown, but there was no exception');
        }
    }
    
    @isTest
    static void testIncorrectJSONFile(){
        Boolean exceptionThrown = false;
        try{
            String jsonData = '{\"fields\":\"NSP_Field_Name__c,NSP_Modified_Date__c,NSP_Old_Value__c,NSP_New_Value__c,\\tNSP_Modified_By__r.Name\",\"relatedFieldApiName\":\"NSP_Sobject_Record_Id__c\",\"recordId\":\"00111000028nQgoAAE\",\"numberOfRecords\":"50001",\"sobjectApiName\":\"NSP_SObjects_History_Tracking__b\",\"sortedBy\":\"NSP_Modified_Date__c\",\"sortedDirection\":\"ASC\"}';
            Test.startTest();
            String output = NSP_SingleRelatedListController.initData(jsonData);
            Test.stopTest();	
        }catch (Exception e){
          exceptionThrown = true;
        }finally{
           system.assertEquals(true, exceptionThrown, 'Expected an exception to be thrown, but there was no exception');
        }
    }
}