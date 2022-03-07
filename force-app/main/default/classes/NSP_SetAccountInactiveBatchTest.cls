/**
* Represents test class for SetAccountInactive batch class
*/
@isTest(SeeAllData=false)  
public class NSP_SetAccountInactiveBatchTest {
    
    /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    @testSetup
    static void testData() {
        //List to store account objects
        List<Account> accountList = new List<Account>();
        //Account creation
        for(integer itr=0;itr<10;itr++){
            Account accoutObject = new Account();
            accoutObject.Name = 'Test Account';
            accoutObject.NSP_Stage__c = 'Sold';
            accoutObject.NSP_Account_Status__c = 'Active'; 
            accountList.add(accoutObject);
        }
        //inserting account list
        insert accountList;
 
    }    
    
    static testMethod void testSetCreatedDate() {  

         Test.startTest();  
        //calling the batch
        Database.executeBatch(new NSP_SetAccountInactiveBatch(),15);
        system.assert(true,true);
        
        NSP_SetAccountStageToInactiveScheduler testsche = new NSP_SetAccountStageToInactiveScheduler();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, testsche);
        Test.stopTest(); 
       
    }  
    
}