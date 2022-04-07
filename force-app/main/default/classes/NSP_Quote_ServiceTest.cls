/**
* Represents test class for NSP_Quote_Service
* Created by : Tejas
* Created Date : 20/Dec/2021
*/
@isTest
public without sharing class NSP_Quote_ServiceTest {
    
    @isTest
    public static void getDocusignUrlTest(){
        String DOCUSIGN_AID=System.Label.NSP_Docusign_Account_Id;
        string sUrl = NSP_Quote_Service.getDocuSignUrl('testRecordId','testTemplateId','testName','testAccountName',DOCUSIGN_AID);
        System.assertEquals(true, sUrl.contains('testAccountName'));
    }
}