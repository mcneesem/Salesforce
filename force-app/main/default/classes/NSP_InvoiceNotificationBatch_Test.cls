//***Test Class for NSP_InvoiceNotificationBatch***
/**
* @description  : Test Class for NSP_InvoiceNotificationBatch Class
* @date 12 July 2023
* Name : NSP_InvoiceNotificationBatch_Test
*/
@isTest
public class NSP_InvoiceNotificationBatch_Test{

    @isTest
    private static void NSP_InvoiceNotificationBatchTest(){
        Test.startTest();
        String message = NSP_InvoiceNotificationBatch.staticMessage;
        System.assertEquals('Code Cleaned', message);
        Test.stopTest();
    }
}