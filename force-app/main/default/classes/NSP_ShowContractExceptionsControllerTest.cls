/**
 * Author: Bindushree Raju
* Represents test class for NSP_ShowContractExceptionsControllerTest
* Test Class to cover Show Contract Exceptions Controller 
* Modified Date: 12 Sep 2022
*/
@isTest
public class NSP_ShowContractExceptionsControllerTest {
    
    //setup test data
      @testSetup
     static void testSetup() {
         
        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
        
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.AccountId = newAccount.Id;
        insert newContact;
        
        NSP_Service_Exception__c serviceException = new NSP_Service_Exception__c();
         serviceException.NSP_Account__c=newAccount.Id;
         serviceException.NSP_Exception_Notes__c='test';
         serviceException.NSP_Start_Date__c=system.today();
       
         
         insert serviceException;
     }
    // method to test exception by controller
     @isTest
    static void testException(){
        Test.startTest();
        
        Contact  cc = [SELECT Id, FirstName, pse__Is_Resource_Active__c, AccountId FROM Contact WHERE FirstName = 'ResourceFN' LIMIT 1];
        try{
            List<NSP_Service_Exception__c> exList1 = NSP_ShowContractExceptionsController.getExceptionList(cc.Id);
            List<NSP_Service_Exception__c> exList2 = NSP_ShowContractExceptionsController.getExceptionListFromContact(cc.Id);
            system.assertEquals(TRUE, exList1 != null);
            system.assertEquals(TRUE, exList2 != null);
            
        }catch(Exception ex){
            
        }
        
        Test.stopTest();
      }
    
    @isTest
    static void testExceptionNullValues(){
        Test.startTest();
        List<NSP_Service_Exception__c> exList1;
        try{
            exList1 = NSP_ShowContractExceptionsController.getExceptionListFromContact(null);
            
        }catch(Exception ex){
            ex.getMessage();
            system.assertEquals(FALSE, exList1 != null);
        }
        Test.stopTest();
    }
}