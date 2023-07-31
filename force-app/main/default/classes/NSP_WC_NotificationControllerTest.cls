@isTest

/**
* Represents the NSP_WC_NotificationControllerTest for WC_Notification email Template Logic.
*/
public without sharing class NSP_WC_NotificationControllerTest {
    /**
    * Classes Covered
    * NSP_WC_NotificationController
    * @param null
    * @return void
    */
    @isTest
    static void test(){
        Test.startTest();
        Implementation_Profile__c oIProfile = new Implementation_Profile__c(Legal_Name__c = 'Legal Name',Employees_work_in_the_following_states__c = 'MA;NY;RI;VA',Client_does_business_in_MA_NY_or_VA__c='Yes', NSP_Business_Meeting_States__c='MA;NY;RI;VA' );
        insert oIProfile;
        NSP_WC_NotificationController.getrecId(); 
        NSP_WC_NotificationController.setrecId(oIProfile.id);
        Implementation_Profile__c oIProfile1 = NSP_WC_NotificationController.imptProfile;
        String employeesWhoWork = NSP_WC_NotificationController.employeesWhoWork;
        List<String> employeesWhoWorkList = NSP_WC_NotificationController.employeesWhoWorkList;
        String clientWhoWorkList = NSP_WC_NotificationController.clientDoesBusiness;
        Test.stopTest();
        system.assertEquals(oIProfile.Legal_Name__c, 'Legal Name');
        Assert.areEqual('Massachusetts, New York, Virginia, Rhode Island', clientWhoWorkList);
    }

}