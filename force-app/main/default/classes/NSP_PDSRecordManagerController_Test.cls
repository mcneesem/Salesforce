/**
Apex Class Name      :  NSP_PDSRecordManagerController_Test
Version              :  1.0   
Author               :  Virendra                                                                       
Created Date         :  8/16/2022  
Function             :   Represent test class for NSP_PDSRecordManagerController_Test
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Virendra               8/22/2022          First Iteration
*/

@isTest
public class NSP_PDSRecordManagerController_Test {
    
    public static testMethod void testGetPDSRecordsForSubClient() {
        
        Account acc = new Account();
        acc.Name='Test Account';
        insert acc;
        //creating asset
        Asset Ass = new Asset();
        Ass.Name='Test ';
        Ass.AccountId = acc.Id ;
        insert Ass ;
        //creating subclients
        NSP_Sub_Client__c SCIns = New NSP_Sub_Client__c ();
        SCIns.Name = 'Test';
        SCIns.NSP_Account__c = acc.Id ;
        SCIns.NSP_Asset__c = Ass.Id ;
        insert SCIns ;
        
        List<NSP_Payroll__c> lstAcc = new List<NSP_Payroll__c>();
        NSP_Payroll__c PDSIns = new NSP_Payroll__c();
        PDSIns.NSP_Sub_Client_Name__c = SCIns.Id ;
        lstAcc.add(PDSIns);
        insert lstAcc;
        
        Test.StartTest();
        
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(lstAcc);
        NSP_PDSRecordManagerController PDSRec = new NSP_PDSRecordManagerController(sc);
        Test.StopTest();
        System.assert(lstAcc != null);
    }
    
    public static testMethod void testGetPDSRecordsForSubClient1() {
        Account acc1 = new Account();
        acc1.Name='Test Account';
        insert acc1;
        
        Asset Ass1 = new Asset();
        Ass1.Name='Test ';
        Ass1.AccountId = acc1.Id ;
        insert Ass1 ;
        
        NSP_Sub_Client__c SCIns1 = New NSP_Sub_Client__c ();
        SCIns1.Name = 'Test';
        SCIns1.NSP_Account__c = acc1.Id ;
        SCIns1.NSP_Asset__c = Ass1.Id ;
        insert SCIns1 ;
        
        
        NSP_Payroll__c PDSIns1 = new NSP_Payroll__c();
        PDSIns1.NSP_Sub_Client_Name__c = SCIns1.Id ;
        insert PDSIns1;
        
        Test.StartTest();
        
        List<NSP_Payroll__c> payrollDetails = [SELECT Id FROM NSP_Payroll__c  WHERE Name != '' LIMIT 1];
        List<NSP_Sub_Client__c> SubClientDetails = [SELECT Id FROM NSP_Sub_Client__c  WHERE Name != '' LIMIT 1];
        String pdsResponse = NSP_PDSRecordManagerController.getPDSRecordsForSubClient(String.valueof(SubClientDetails[0].Id));
        Test.StopTest();
        System.assert(pdsResponse !='');
    }
    
    public static testMethod void testGetPDSRecordsForSubClient2() {
        Account acc1 = new Account();
        acc1.Name='Test Account';
        insert acc1;
        
        Asset Ass1 = new Asset();
        Ass1.Name='Test ';
        Ass1.AccountId = acc1.Id ;
        insert Ass1 ;
        
        NSP_Sub_Client__c SCIns1 = New NSP_Sub_Client__c ();
        SCIns1.Name = 'Test';
        SCIns1.NSP_Account__c = acc1.Id ;
        SCIns1.NSP_Asset__c = Ass1.Id ;
        insert SCIns1 ;
        
        Test.StartTest();
        
        List<NSP_Payroll__c> payrollDetails = [SELECT Id FROM NSP_Payroll__c WHERE Name != '' LIMIT 1 ];
        List<NSP_Sub_Client__c> SubClientDetails = [SELECT Id , LastModifiedBy.Profile.Name FROM NSP_Sub_Client__c WHERE Name != '' LIMIT 1];
        String pdsResponse = NSP_PDSRecordManagerController.getPDSRecordsForSubClient(String.valueof(SubClientDetails[0].Id));
        
        Test.StopTest();
        System.assert(pdsResponse !='');
    }
    
    public static testMethod void testGetUpdatedSubClient() {
        Account acc1 = new Account();
        acc1.Name='Test Account';
        insert acc1;
        
        Asset Ass1 = new Asset();
        Ass1.Name='Test ';
        Ass1.AccountId = acc1.Id ;
        insert Ass1 ;
        
        NSP_Sub_Client__c SCIns1 = New NSP_Sub_Client__c ();
        SCIns1.Name = 'Test';
        SCIns1.NSP_Account__c = acc1.Id ;
        SCIns1.NSP_Asset__c = Ass1.Id ;
        insert SCIns1 ;
        
        NSP_Payroll__c PDSIns = new NSP_Payroll__c();
        PDSIns.NSP_Sub_Client_Name__c = SCIns1.Id ;
        insert PDSIns;
        
        Test.StartTest();
        //getting subclient details
        NSP_Sub_Client__c SubClientDetails = [SELECT Id , LastModifiedBy.Profile.Name FROM NSP_Sub_Client__c WHERE Name = 'Test'  LIMIT 1];
        string returnedValue = NSP_PDSRecordManagerController.getUpdatedSubClient(SubClientDetails.Id);
        System.assert(returnedValue !='');
        Test.StopTest();
        
    }
}