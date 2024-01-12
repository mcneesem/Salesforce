/**
Apex Class Name      :  NSP_AccountGrowthForeCastBatch
Version              :  1.0                                                                          
Created Date         :  11/01/2022
Function             :  Represents test class for NSP_AccountGrowthForeCastBatch helper 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Anil                       11/01/2022          First Iteration
*/

@isTest
private class NSP_AccountGrowthForeCastBatch_Test{
	private static Id recordTypeId = SObjectType.NSP_Account_Group__c.getRecordTypeInfosByDeveloperName().get('Automatically_Created').getRecordTypeId();

    @testSetup static void setup(){
        List<NSP_Account_Group__c> lstAccGroups = new List<NSP_Account_Group__c>();
        for(Integer ints=0; ints<5; ints++){
            lstAccGroups.add(new NSP_Account_Group__c(
                Name = 'Growth Forecast',
                RecordTypeId = recordTypeId,
                NSP_Account__c = 'Test Account',
                NSP_Type__c = 'Growth Forecast',
                NSP_Organic_Current_Quarter__c = 1.1, 
                NSP_Organic_Current_Quarter_1__c = 1.1, 
                NSP_Organic_Current_Quarter_2__c = 1.1, 
                NSP_Organic_Current_Quarter_3__c = 1.1, 
                NSP_Acquisition_Current_Quarter_2__c = 1.1, 
                NSP_Acquisition_Current_Quarter__c = 1.1, 
                NSP_Acquisition_Current_Quarter_1__c = 1.1, 
                NSP_Acquisition_Current_Quarter_3__c = 1.1, 
                NSP_Reduction_Current_Quarter__c = 1.1, 
                NSP_Reduction_Current_Quarter_1__c = 1.1, 
                NSP_Reduction_Current_Quarter_2__c = 1.1, 
                NSP_Reduction_Current_Quarter_3__c = 1.1, 
                NSP_Past_Quarter__c = pastQuarter,
                NSP_Past_Quarter_Date__c = System.today().addMonths(-6),
                NSP_Tag__c = 'Test Tag'));
            
        }
        
        insert lstAccGroups;
        
    }

	@isTest static void testMethod1() {
		Test.startTest();
        //Calling the batch for case and regulated area creation for 1st time     
        Database.executeBatch(new NSP_AccountGrowthForeCastBatch(), 200); //executes the bacth class
		Test.stopTest();

		NSP_Account_Group__c accGrp = [SELECT Id, NSP_Reduction_Current_Quarter_3__c ,NSP_Type__c
										FROM NSP_Account_Group__c
										WHERE NSP_Type__c = 'Growth Forecast'
										LIMIT 1];
		system.assertEquals(null, accGrp.NSP_Reduction_Current_Quarter_3__c, 'Last Quater has been rolled off');
	}

	@isTest static void testNegativeCase() {
		List<NSP_Account_Group__c> lstAccGroups = new List<NSP_Account_Group__c>();
		for(NSP_Account_Group__c accGrp : [SELECT Id,NSP_Past_Quarter_Date__c 
											FROM NSP_Account_Group__c 
											WHERE NSP_Type__c = 'Growth Forecast'
											LIMIT 10]){
			accGrp.NSP_Past_Quarter_Date__c = System.today();
			lstAccGroups.add(accGrp);
		}
		Database.update(lstAccGroups); 

		Test.startTest();
		Database.executeBatch(new NSP_AccountGrowthForeCastBatch(), 200); //executes the batch class
        //Calling the batch for case and regulated area creation for 1st time     
        Test.stopTest();
		NSP_Account_Group__c accGrp = [SELECT Id,NSP_Reduction_Current_Quarter_3__c FROM NSP_Account_Group__c  WHERE Id != null LIMIT 1];
		system.AssertEquals( 1.1, accGrp.NSP_Reduction_Current_Quarter_3__c, 'it is not rolled off');
	}

	private static String currentQuarter{
        get{
            DateTime dt = System.now();
            Integer currentMnt =dt.month();
            Integer currentQ =((currentMnt-1)/3) + 1;
            return 'Q'+currentQ+'/'+ dt.year();
        } private set;
    }

	private static String pastQuarter{
        get{
            DateTime dt = System.now();
            Integer currentMnt =dt.month();
            Integer currentQ =((currentMnt-1)/3) + 1;
            return 'Q'+(currentQ-1)+'/'+ dt.year();
        } private set;
    }
}