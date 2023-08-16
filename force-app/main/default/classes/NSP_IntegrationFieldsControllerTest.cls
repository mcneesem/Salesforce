/**
Apex Class Name      :  NSP_IntegrationFieldsControllerTest
Version              :  1.0   
Author               :  Virendra                                                                       
Created Date         :  9/06/2022 
Function             :   Represent test class for NSP_IntegrationFieldsController
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Virendra               9/06/2022          First Iteration
*/

@isTest
public class NSP_IntegrationFieldsControllerTest {
	@TestSetup
    public static void createTestData(){
        //Test Data Setup
        Account objaccount = NSP_TestHelper.createAccount(true);
        Contact objcontact = NSP_TestHelper.createContact(objaccount.id, true);
    }
    
     /*
    *Test Method : shouldCheckForIntegrationField
    *@Virendra Kumar
    */
     @isTest
    private static void shouldCheckForIntegrationField(){
        Contact objaccount  = [SELECT Id, Name FROM Contact LIMIT 1];
        
        Test.startTest();
        NSP_IntegrationFieldsController.getIntegrationFieldsBasedOnObject(objaccount.Id);
        sObject con = NSP_IntegrationFieldsController.getContact(objaccount.Id);
        System.assert(con != null);
        Test.stopTest();
    }
}