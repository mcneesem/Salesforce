/**
* @description  :  Test Class to NSP_ServiceConstants.
* Name : NSP_ServiceConstantsTest
*/

@isTest
public class NSP_ServiceConstantsTest {
    
    @isTest
    public static void afterUpdateProjectTaskTest(){
      System.assertEquals('Active', NSP_ServiceConstants.PROJECTSTATUSACTIVE);
    }

}