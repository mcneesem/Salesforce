/**
* Represents test class for NSP_OpportunitySplitHelper
* Test Class to cover Opportunity Split Trigger Handler and Helper classes 
*/
@isTest
public class NSP_OpportunitySplitTriggerHelperTest {
    /**
* Does test data setup
* @param N/A. 
* @return void                          
*/

    @testSetup
    public static void testData() {
        //Account creation
        Account accoutObject = new Account();
        accoutObject.Name = 'Test Account';
        //inserting account object
        insert accoutObject;

        //Create Opportunity
        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Name = 'Test Oppty';
        opportuniytObject.AccountId = accoutObject.id;
        opportuniytObject.stagename = 'Analysis';
        opportuniytObject.CloseDate = date.today();
        opportuniytObject.CurrencyIsoCode ='USD';
        opportuniytObject.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject.NSP_Number_of_Employees__c = 100;
        opportuniytObject.Type ='CAMS';
        //Inserting Opportunity Object
        insert opportuniytObject;
    }

    /**
* INSERT: Checks if NSP_Number_of_Employees__c is greater than 
* Opportunity NSP_Number_of_Employees__c, it will throw validation.
* @param N/A. 
* @return void                          
*/
    @isTest
    public static void throwErrorWhenSumOfEmployeeExceedOnInsertTest() {
        List<Opportunity> opp = [SELECT NSP_Number_of_Employees__c FROM Opportunity WHERE NSP_Number_of_Employees__c = 100];

        // Creating Opportunity Split Record
        NSP_Employee_Split__c oppSplit = new NSP_Employee_Split__c ();
        oppSplit.NSP_Opportunity__c = opp[0].id;
        oppSplit.NSP_Number_of_Employees__c = 101;
        test.startTest();
        try{
            insert oppSplit;
        }catch(Exception ex){
            System.Assert(ex.getMessage().contains(System.Label.NSP_ErrorMessageSumOfEEIsGreaterThanNumberOfEmployeesOnOppty));
        }
        test.stopTest();
    }

    /**
* UPDATE: Checks if NSP_Number_of_Employees__c is greater than 
* Opportunity NSP_Number_of_Employees__c, it will throw validation.
* @param N/A. 
* @return void                          
*/
    @isTest
    public static void throwErrorWhenSumOfEmployeeExceedOnUpdateTest() {
        List<Opportunity> opp = [SELECT NSP_Number_of_Employees__c FROM Opportunity WHERE NSP_Number_of_Employees__c = 100];

        // Creating Opportunity Split Record
        NSP_Employee_Split__c oppSplit = new NSP_Employee_Split__c ();
        oppSplit.NSP_Opportunity__c = opp[0].id;
        oppSplit.NSP_Number_of_Employees__c = 99;
        insert oppSplit;
        test.startTest();
        try{
            oppSplit.NSP_Number_of_Employees__c = 101;
            update oppSplit;
        }catch(Exception ex){
            System.Assert(ex.getMessage().contains(System.Label.NSP_ErrorMessageSumOfEEIsGreaterThanNumberOfEmployeesOnOppty));
        }
        test.stopTest();
    }

    @isTest
    Public static void autoPopulateAccountTest(){
        List<Opportunity> opp = [SELECT AccountId, NSP_Number_of_Employees__c FROM Opportunity WHERE NSP_Number_of_Employees__c = 100];

        // Creating Opportunity Split Record
        NSP_Employee_Split__c oppSplit = new NSP_Employee_Split__c ();
        oppSplit.NSP_Opportunity__c = opp[0].id;
        oppSplit.NSP_Number_of_Employees__c = 90;

        test.startTest();
        insert oppSplit;
        NSP_Employee_Split__c updatedAccountOnOppSplit = [SELECT NSP_Account__c FROM NSP_Employee_Split__c WHERE ID = : oppSplit.id];
        System.assertEquals(opp[0].AccountId, updatedAccountOnOppSplit.NSP_Account__c, 'NSP_Account__c on Opp Split will be auto populated with Opportunity Account');
        test.stopTest();
    }
    
    @isTest
   public static void salesOfficeTest()
   {
       NSP_Sales_Office_Mapping__c officeMapping = new NSP_Sales_Office_Mapping__c();
        officeMapping.NSP_Sales_Office__c = '1081';
        officeMapping.NSP_Sales_Division__c = 'Central';
        officeMapping.NSP_Sales_Region__c = 'Central 1';
        officeMapping.NSP_Start_Date__c = system.today()-1;
        officeMapping.NSP_End_Date__c = system.today()+100;
        insert officeMapping;
       
        List<Opportunity> opp = [SELECT AccountId, NSP_Number_of_Employees__c FROM Opportunity WHERE NSP_Number_of_Employees__c = 100];

        // Creating Opportunity Split Record
        NSP_Employee_Split__c oppSplit = new NSP_Employee_Split__c ();
        oppSplit.NSP_Opportunity__c = opp[0].id;
        oppSplit.NSP_Number_of_Employees__c = 90;
		oppSplit.NSP_Sales_Office__c = '1081';
        test.startTest();
        insert oppSplit;
       test.stopTest();
   }
}