/**
* Represents test class for NSP_Quote_Service
* Created by : Tejas
* Created Date : 20/Dec/2021
*/
@isTest
public without sharing class NSP_Quote_ServiceTest {
    
    @isTest
    public static void getDocusignUrlTest(){
        //NSP_Quote_Service quoteServiceObj = new NSP_Quote_Service();
        string sUrl = NSP_Quote_Service.getDocuSignUrl('testRecordId','testTemplateId','testName','testAccountName');
        System.assertEquals(true, sUrl.contains('testAccountName'));
    }
}