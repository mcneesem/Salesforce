/**
Apex Class Name      :  NSP_GetTaskRecordTypesWrapperTest for NSP_GetTaskRecordTypesWrapper
Version              :  1.0                                                                          
Created Date         :  1/05/2022   
Function             :  Test class for NSP_GetTaskRecordTypesWrapper 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Srushti                     1/05/2022              First Iteration
*/

@isTest
public class NSP_GetTaskRecordTypesWrapperTest {
    
     /***********************************************************************************************
    * MethodName: testGetRecordTypes
    * Description : Test method to cover getRecordTypes 
    * ********************************************************************************************/
	@isTest
    private static void testGetRecordTypes(){
        NSP_GetTaskRecordTypesWrapper.getRecordTypes();
        System.assertEquals(true, NSP_GetTaskRecordTypesWrapper.getRecordTypes().size() > 0);
    }
}