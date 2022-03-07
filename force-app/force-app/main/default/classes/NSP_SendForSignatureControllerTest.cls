/**
 * Author: Harsha
* Represents test class for NSP_SendForSignatureController
* Test Class to cover Opportunity Trigger Handler and Helper classes 
* Modified Date: 19 Aug 2021
*/

@isTest(SeeAllData=false)
public class NSP_SendForSignatureControllerTest {
public static final String ACCOUNTNAME ='testCustomer'; // Added as part of code scan fix
    @testSetup static void setupData(){
        
        Account customerAccount = new Account(name = 'testCustomer',  NSP_Partner_Lifecycle__c = 'Evaluation');
        insert customerAccount;
    }

    @isTest static void testController(){
        List<Account> acc = [SELECT id, NSP_Partner_Lifecycle__c FROM Account WHERE Name =: ACCOUNTNAME LIMIT 1]; // Added as part of code scan fix
        PageReference pageRef = Page.NSP_SendForSignature;
        Test.setCurrentPage(pageRef);
        test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(acc[0]);
        NSP_SendForSignatureController controller = new NSP_SendForSignatureController(sc);
        NSP_SendForSignatureController.updatePartnerLifeCycleValue();
        test.stopTest();
        Account acc1 = [SELECT id, NSP_Partner_Lifecycle__c FROM Account WHERE Name =: ACCOUNTNAME LIMIT 1];
        System.assertEquals(acc1.NSP_Partner_Lifecycle__c,NSP_SalesConstants.ONBOARDING);
        system.assertNotEquals(controller, null);
        

    }
}
    