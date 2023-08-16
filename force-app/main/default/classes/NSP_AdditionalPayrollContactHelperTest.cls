/**
Apex Class Name      :   NSP_AdditionalPayrollContactHelperTest for NSP_AdditionalPayrollContactHelper
Version              :  1.0                                                                          
Created Date         :  6/1/2022 
Function             :  This class is used as a test class  to NSP_AdditionalPayrollContactHelperTest. 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Nischay                    8/17/2022           First Iteration
*/

@isTest
public class NSP_AdditionalPayrollContactHelperTest {
    @testSetup
    private static void setupTestData(){
        //contact creation
        Contact newContact = (Contact)NSP_TestDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.NSP_Work_email__c = 'Test@email.com';
        newContact.MobilePhone = '876657787';
        newContact.Phone = '67763478';
        newContact.NSP_Work_Phone__c = '87278483';
        // inserting created new contact
   		insert newContact;

        NSP_Sub_Client__c newSubClient = (NSP_Sub_Client__c)NSP_TestDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults',true);

        NSP_Sub_Client_Contact__c subClientCon = new NSP_Sub_Client_Contact__c();
        subClientCon.NSP_Sub_Client__c = newSubClient.Id;
        subClientCon.NSP_Contact__c = newContact.Id;
        subClientCon.NSP_On_Site_Supervisor__c = true;
        subClientCon.NSP_Payroll_Contact__c = true;
        subClientCon.NSP_HR_Contact__c = true;
        subClientCon.NSP_Background_Contact__c = true;
        insert subClientCon ; 

        NSP_Payroll__c Payroll = (NSP_Payroll__c)NSP_TestDataFactory.createSObject(new NSP_Payroll__c(), 'NSP_TestDataFactory.PayrollDataSheetDefaults', false);
        Payroll.NSP_Sub_Client_Name__c = newSubClient.Id;
        insert Payroll;
    }
    
    @isTest
    private static void testAdditionalPayrollContactTriggerOperation(){
        test.startTest();
        Contact con = [SELECT Id, NSP_Work_email__c, MobilePhone, Phone, NSP_Work_Phone__c FROM Contact WHERE Contact.MobilePhone = '876657787'];
        NSP_Payroll__c Payroll = [SELECT Id FROM NSP_Payroll__c WHERE NSP_Payroll__c.NSP_Additional_information__c = 'Test'];
        Additional_Payroll_Contact__c newAdditionalPayrollContact = (Additional_Payroll_Contact__c)NSP_TestExtendedDataFactory.createSObject(new Additional_Payroll_Contact__c(), 'NSP_TestDataFactory.AdditionalPayrollContactDefaults', false);
        newAdditionalPayrollContact.Contact__c = con.Id ;
        newAdditionalPayrollContact.Payroll__c = Payroll.Id;
        insert newAdditionalPayrollContact;
        newAdditionalPayrollContact = [SELECT Id,NSP_Contact_Email__c,NSP_Contact_Cell__c,NSP_Contact_International_Phone__c,NSP_Contact_Office_Phone__c FROM Additional_Payroll_Contact__c WHERE ID =: newAdditionalPayrollContact.ID];
        
        update newAdditionalPayrollContact;
        
        System.assertEquals(con.NSP_Work_email__c, newAdditionalPayrollContact.NSP_Contact_Email__c);
        System.assertEquals(con.MobilePhone, newAdditionalPayrollContact.NSP_Contact_Cell__c);
        System.assertEquals(con.Phone, newAdditionalPayrollContact.NSP_Contact_International_Phone__c);
        System.assertEquals(con.NSP_Work_Phone__c, newAdditionalPayrollContact.NSP_Contact_Office_Phone__c);
        test.stopTest();
    }
    @IsTest
    static void beforeDelete() {
        new NSP_AdditionalPayrollContactHandler().beforeDelete(null, null);
         System.assert(new NSP_AdditionalPayrollContactHandler().beforeDelete(null, null) == null);
    }
    @IsTest
    static void afterDelete() {
        new NSP_AdditionalPayrollContactHandler().afterDelete(null, null);
         System.assert(new NSP_AdditionalPayrollContactHandler().afterDelete(null, null) == null);
    }

}