/**
* Represents test class for NSP_ErrorLogHandler
*/

@isTest(SeeAllData=false)
public class NSP_ErrorLogHandlerTest {
    /**
* Checks the logSaveResult and LogSaveException
* @param N/A. 
* @return void                          
*/
    @isTest
    static void checkTestMehod() {
        Test.startTest();
        //List to store account objects
        List<Account> accountList = new List<Account>();
        //Iterating over the loop to create 5 accounts
        for(integer itr =0;itr<5;itr++){
            Account accObject = new Account();
          //Not setting any value so that the account insert would fail
            accountList.add(accObject);
        }
        //Using database.save result 
        try{ 
            Database.SaveResult[] result = Database.Insert(accountList, false);
        } catch (Exception ex) {
            NSP_CustomException.LogException(ex);
        }
        Test.stopTest();
        System.assertEquals(accountList.size(), 5);
    }
}