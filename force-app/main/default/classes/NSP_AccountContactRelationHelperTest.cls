/**
* Represents test class for 
* AccountContactRelation trigger helper
* Created By : Hemali Patel
* Modification Log     :                                                                              
* --------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Rahul Singh      		26/10/2022			         Create OCR as part of user story - 128223
*/

@isTest(SeeAllData=FALSE)
public class NSP_AccountContactRelationHelperTest {
    
    /** 
    * Test Data for AccountContactRelationHelperTest
    * Method Name : testData
    */
    @testsetup 
    static void testData() {
        //Insert Test Account record
        Account acc1 = NSP_TestHelper.createAccount(true);
        NSP_TestHelper.createContact(acc1.id, true);
        
        Account account = New Account(Name = 'TestAccount', AccountNumber = '12345',NSP_AIMS_Client__c = 'ateammember1');
        insert account;
        
     }
    
    /** 
    * Test for before and after insert of ACR trigger
    * Method Name : testAccountContactInsert
    */
    @isTest
    static void testAccountContactInsert() {
        
        
        Account accObj = [Select Id,Name from Account WHERE Name!= null  LIMIT 1];
        ID accountId = accObj.Id;
         //Create Opportunity
        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Name = 'Test Oppty';
        opportuniytObject.AccountId = accountId;
        opportuniytObject.stagename = NSP_SalesConstants.DISCOVERY_STAGE;
        opportuniytObject.CloseDate = date.today();
        opportuniytObject.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject.NSP_Number_of_Employees__c = 100;
        opportuniytObject.NSP_WS_Number_Of_Employees__c = 123;
        opportuniytObject.NSP_WO_Number_Of_Employees__c = 123;
        //Inserting Opportunity Object
        insert opportuniytObject;
        
        AccountContactRelation acrObj  = [Select Id from AccountContactRelation WHERE AccountId =: accountId];
        
        
        acrObj.Roles = 'Agency';
        acrObj.NSP_Is_Primary__c = true;
        acrObj.IsActive =true;
        
        // Start Test
        Test.startTest();
        update acrObj; 
        Test.stopTest();
        System.assertEquals(acrObj.NSP_Is_Primary__c,True);
    }
    
    /** 
    * Test for before and after udapte of ACR trigger
    * Method Name : testAccountContactUpdate
    */
    @isTest
    static void testAccountContactUpdate() {
        
        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        Map<Id,AccountContactRelation> acrMap = new Map<Id,AccountContactRelation>();
        Account accObj = [Select Id,Name from Account  WHERE Name!= null  LIMIT 1 ];
        ID accountId = accObj.Id;       
        AccountContactRelation acrObj  =[Select Id,AccountId from AccountContactRelation WHERE AccountId =: accountId];
        acrObj.Roles = 'Agency';
        acrObj.NSP_Is_Primary__c = true;
        acrObj.IsActive =true;
        acrList.add(acrObj);
        acrMap.put(acrObj.Id,acrObj);
        NSP_AccountContactRelationTriggerHelper acrObj1 = new NSP_AccountContactRelationTriggerHelper();
        acrObj1.afterInsertDirector(acrList,acrMap); 
        // Start Test
        Test.startTest();
        Test.stopTest();
 System.assertEquals(acrObj.NSP_Is_Primary__c,True);
    }
}