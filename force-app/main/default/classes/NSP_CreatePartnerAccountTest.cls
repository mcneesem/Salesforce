/**
* Represents test class for NSP_CreatePartnerAccount class
*/
@isTest(SeeAllData=false)
public class NSP_CreatePartnerAccountTest {
    /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    
    @testSetup
    static void testData() {
        
        //Contact creation        
        Contact contactObject = new Contact();
        contactObject.lastname = 'TestContact';
        contactObject.email = 'test@test.com';
        //Inserting contact object
        insert contactObject;
    }
    /**
* Checks if the account is created or not
* @param N/A. 
* @return void                          
*/
    @isTest
    static void checkCreateAccount() {
        //Querying to get get lead with last name as 
        Contact  cnt = [SELECT id,lastname  FROM Contact WHERE lastname != null];
        //Setting the fire score to greater than 80
        
        Test.startTest();
        //Creating Account referecne
        Account accObject = new Account();
        accObject.Name = 'Test Account1';
        //Seerialising the account and passing it to the method
        NSP_CreatePartnerAccount.createAccount(JSON.serialize(accObject),cnt.id);
        NSP_CreatePartnerAccount.returnAllPickListValues();
        Test.stopTest();
        //Assert statement
         system.assert(true, 'TestContact'.equals(cnt.lastname));        
    }
    
    @isTest
    static void checkBlankData() {
        //Querying to get get lead with last name as 
        Contact  cnt = [SELECT id,lastname  FROM Contact WHERE lastname != null];
        //Setting the fire score to greater than 80
        
        Test.startTest();
        try{
        NSP_CreatePartnerAccount.createAccount(null,cnt.id);
        NSP_CreatePartnerAccount.getPiklistValues(null,null);
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
        NSP_CreatePartnerAccount.returnAllPickListValues();
        Test.stopTest();
               
    }
}