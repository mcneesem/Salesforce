/*
 * @Description: This test class is used to cover NSP_DO_NOTHING.
 * @Created Date: 02/01/2022
 * */
@isTest
public class NSP_DO_NOTHING_Test {
  /*
 * @Description: This method is used to cover NSP_DO_NOTHING.doNothing method.
 * @Created Date: 02/01/2022
 * @return void  
 * */  
    static testmethod void Test_DoNothing(){
        Exception unexpectedException;
        Test.startTest();
        try{
        NSP_DO_NOTHING.doNothing();
        }catch (Exception e){
            unexpectedException = e;
        }
        Test.stopTest();
        system.assertEquals(null, unexpectedException);
    }
}