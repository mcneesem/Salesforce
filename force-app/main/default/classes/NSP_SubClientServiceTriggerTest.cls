/**
* Represents test class for SubClient Service Trigger helper 
* Represents test class for SubClient Trigger Handler
* Created by : Nishkarsh Manav
* Created Date : 5/05/2022
*/
@isTest
private class NSP_SubClientServiceTriggerTest {

    /**
    * Does test data setup
    * @param N/A. 
    * @return void                          
    */
    @testSetup
    static void testData() {
        Account accObj = NSP_TestHelper.createAccount(true);
        
        // Create Asset Record
        Asset assetObj = new Asset();
        assetObj.accountId = accObj.Id;
        assetObj.NSP_Client__c = 'asset1';
        assetObj.name = 'asset1';
        insert assetObj;

        // Create Subclient Record
        NSP_Sub_Client__c subClientObj = new NSP_Sub_Client__c();
        subClientObj.NSP_Account__c = assetobj.AccountId;
        subClientObj.NSP_Asset__c = assetobj.Id;
        subClientObj.NSP_Client__c = 'Client 123';
        insert subClientObj;

        List<NSP_Payroll__c> payrolls = new List<NSP_Payroll__c>();

        // Payroll Record 1
        NSP_Payroll__c payrollRec1 = new NSP_Payroll__c();
        payrollRec1.NSP_Sub_Client_Name__c = subClientObj.Id;
        payrolls.add(payrollRec1);

        // Payroll Record 2
        /*NSP_Payroll__c payrollRec2 = new NSP_Payroll__c();
        payrollRec2.NSP_Sub_Client_Name__c = subClientObj.Id;
        payrolls.add(payrollRec2);*/

        insert payrolls;
    }

    /**
    * Checks the related payroll records should be updated with correct "States of Operation" field value.
    * @param N/A. 
    * @return void                          
    */    
    @isTest
    static void onUpdateOfSubClientContactRecordPayrollRecordsShouldBeUpdated(){
        // GIVEN
        final String STATE_OF_OPERATIONS = 'Test stateOfOperations';

        NSP_Sub_Client__c subClientObj = [Select Id FROM NSP_Sub_Client__c WHERE NSP_Client__c = 'Client 123' LIMIT 1];
        subClientObj.NSP_States_of_Operations__c = STATE_OF_OPERATIONS;

        // WHEN
        Test.startTest();
        update subClientObj;
        Test.stopTest();

        List<NSP_Payroll__c> payrolls = [SELECT Id, NSP_States_of_Operation__c FROM NSP_Payroll__c WHERE NSP_Sub_Client_Name__c = :subClientObj.Id];

        // THEN
        for(NSP_Payroll__c payrollRec : payrolls){
            System.assertEquals(payrollRec.NSP_States_of_Operation__c, STATE_OF_OPERATIONS);
        }
    }

}