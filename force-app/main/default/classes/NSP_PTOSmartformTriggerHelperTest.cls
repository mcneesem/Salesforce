/**
Apex Class Name      : NSP_PTOSmartformTriggerHelperTest
Version              :  1.0
Author               :  Jatin                                                                          
Created Date         :  6/1/2022  
Function             :  This class is used as a test class for NSP_PTOSmartformTriggerHelperTest
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Jatin                6/9/2022           First Iteration
*/

@isTest
public class NSP_PTOSmartformTriggerHelperTest {
    @testSetup
    static void testData() {
        //Inserting Account
        Account accoutObject = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        accoutObject.Name = 'PTO SmartForm Test Account';
        insert accoutObject;
 		//inserting COntact
        Contact con = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        con.AccountId = accoutObject.Id;
        con.NSP_Work_email__c = 'test@gmail.com';
        insert con;
       
        //Inserting Account Team
        NSP_Account_Team__c AT = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        AT.NSP_Account__c = accoutObject.Id;
        AT.NSP_Role__c = NSP_SalesConstants.MANAGERHRSERVICE;
        insert AT;
        
        NSP_Account_Team__c AT1 = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        AT1.NSP_Account__c = accoutObject.Id;
        AT1.NSP_Role__c = NSP_SalesConstants.HRSpecialist;
        insert AT1;
    } 
    
    Static testMethod void itaptoTest() {  
        Test.startTest();
        	Contact con = [SELECT Id, AccountId FROM Contact WHERE Account.Name = 'PTO SmartForm Test Account'];
        	NSP_PTO_Smartform__c PTO = new NSP_PTO_Smartform__c();
        	PTO.Name = 'test PTO';
        	PTO.NSP_Status__c = NSP_SalesConstants.Draft;
        	insert PTO;
        	PTO.NSP_Account__c = con.AccountId;
            PTO.NSP_Contact_Name__c = con.Id;
        	PTO.NSP_Status__c = NSP_SalesConstants.Submitted;
            update PTO;
        	PTO.NSP_Status__c = NSP_SalesConstants.Resubmit;
            update PTO;	
        
        	NSP_PTO_Smartform__c PTO1 = new NSP_PTO_Smartform__c();
        	PTO1.Name = 'test PTO';
        	PTO1.NSP_Account__c = con.AccountId;
            PTO1.NSP_Contact_Name__c = con.Id;
            PTO1.NSP_Status__c = NSP_SalesConstants.Submitted;
        	insert PTO1;
        	
        	System.assertEquals(1, [SELECT count() FROM Case WHERE NSP_PTO_Smartform__c =: PTO.Id]);
        Test.stopTest();
        
    }
}