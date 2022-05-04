/*Name: NSP_CustomExceptionTest
*Test class for NSP_CustomException
*Purpose : Exception Test Class
*Author :@Utpal Utkalit
*/
@isTest
public class NSP_CustomExceptionTest {
    /***********************************************************************************************
    * MethodName : createAccount
    * Description : Created for unit testing of NSP_CustomException 
    * ********************************************************************************************/
 @isTest
    public static void createAccount() {
        try {
            Account accountObj = new Account();
            insert accountObj;
            system.assertNotEquals(accountObj, null);
        } catch (Exception ex) {
            NSP_CustomException.LogException(ex);
        }    
    } 
}