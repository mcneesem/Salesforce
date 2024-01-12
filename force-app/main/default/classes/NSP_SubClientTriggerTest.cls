/**
* Represents test class for SubClient Trigger helper 
* Represents test class for SubClient Trigger Handler
* Created by : Hemali Patel
* Created Date : 8/11/2021
*/
@isTest(SeeAllData=false)
public class NSP_SubClientTriggerTest {
    
    /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    @testSetup
    static void testData() {
        Account accObj = NSP_TestHelper.createAccount(true);
        
        //Create Asset
        Asset assetObj = new Asset();
        assetObj.accountId = accObj.Id;
        assetObj.NSP_Client__c = 'asset1';
        assetObj.name = 'asset1';
        insert assetObj;

        //Create Asset
        // Asset assetObj1 = new Asset();
        // assetObj1.accountId = accObj.Id;
        // assetObj1.NSP_Client__c = 'asset2';
        // assetObj1.name = 'asset2';
        // assetObj1.NSP_Need_Rollup_Recalculation__c = true;
        // assetObj1.NSP_Verbal_Term_recd__c=true;
        // assetObj1.NSP_Written_Term_recd__c=true;
        // assetObj1.NSP_Written_Term_Date__c =null;
        // assetObj1.NSP_Verbal_Term_Date__c = null;
        // assetObj1.NSP_Anticipated_Date_Of_Termination__c=System.today();
        // assetObj1.NSP_Reason_for_Term__c='testing';
        // insert assetObj1; 
        
        // create Subclient
        NSP_Sub_Client__c subClientObj = new NSP_Sub_Client__c();
        subClientObj.NSP_Account__c = accObj.Id;
        subClientObj.NSP_Asset__c = assetobj.Id;
        subClientObj.NSP_Client__c = 'Client 123';
        subClientObj.NSP_Sub_Client__c='23400';
        subClientObj.NSP_States_of_Operations__c = 'test states of operations';
        insert subClientObj; 

        // //Create payroll
        // NSP_Payroll__c payrollObj = (NSP_Payroll__c) NSP_TestDataFactory.createSObject(new NSP_Payroll__c(), 'NSP_TestDataFactory.PayrollDataSheetDefaults', true);     
    }
    
    /**
* Checks the update insert logic of the trigger
* @param N/A. 
* @return void                          
*/     
    @isTest
    public static void testInsert(){
        Account accountObj = [select Id from Account WHERE name = 'ABCTest Co' limit 1];
        Asset assetobj = [Select Id from Asset WHERE NSP_Client__c = 'asset1' limit 1];
        //creating List which stores new list of subclients
        List<NSP_Sub_Client__c> newList = new List<NSP_Sub_Client__c>();
        NSP_Sub_Client__c subClientObj = new NSP_Sub_Client__c();
        subClientObj.NSP_Account__c = accountObj.Id;
        subClientObj.NSP_Asset__c = assetobj.Id;
        subClientObj.NSP_Client__c = 'Client 1234';
        test.startTest();
        insert subClientObj;
        newList.add(subClientObj);
        NSP_SubClientTriggerHelper helperObj = new NSP_SubClientTriggerHelper();
        helperObj.beforeInsertDirector(newList);
        test.stopTest(); 
        
        NSP_Sub_Client__c subClinetObj = [Select Id,NSP_Asset__c FROM NSP_Sub_Client__c WHERE Id = :subClientObj.Id];
        system.assertEquals(subClinetObj.NSP_Asset__c, assetobj.Id);
    }
    
    /**
* Checks the update update logic of the trigger
* @param N/A. 
* @return void                          
*/    
    @isTest
    public static void testUpdate(){
        
        Account accountObj = [select Id from Account WHERE name = 'ABCTest Co' limit 1];
        NSP_Sub_Client__c subClientObj = [Select Id FROM NSP_Sub_Client__c WHERE NSP_Account__c = :accountObj.Id limit 1];
        // NSP_Payroll__c payrollObjRec = [SELECT Id, NSP_States_of_Operation__c,NSP_Additional_information__c FROM NSP_Payroll__c WHERE NSP_Additional_information__c = 'Test' LIMIT 1];
        subClientObj.NSP_Account_Status__c = 'Active';
        subClientObj.NSP_Account_Status_Date__c = System.today();
        subClientObj.NSP_States_of_Operations__c = 'test SOO';
        test.startTest();
        update subClientObj;
        test.stopTest(); 
        
        Asset assetobj1 = [SELECT Id,NSP_Account_Status__c,NSP_Account_Status_Date__c FROM Asset 
                           WHERE NSP_Client__c = 'asset1' limit 1];
        // NSP_Payroll__c updatedPayrollObjRec = [SELECT Id, NSP_States_of_Operation__c,NSP_Additional_information__c FROM NSP_Payroll__c];
        system.assertEquals(assetobj1.NSP_Account_Status__c, 'Active');
        system.assertEquals(assetobj1.NSP_Account_Status_Date__c, System.today());
        // system.assertEquals(updatedPayrollObjRec.NSP_States_of_Operation__c, 'test SOO');
    }
     /*before insert test method*/
    @isTest
    public static void testBeforeInsertUseCase1(){
        List<NSP_Sub_Client__c> subClientObj_Obj  =  [Select Id,NSP_Client__c from NSP_Sub_Client__c WHERE NSP_Client__c = 'Client 123' limit 1];
        System.assertEquals(true,subClientObj_Obj.size()>0);
        NSP_SubClientTriggerHandler obj01 = new NSP_SubClientTriggerHandler();
        obj01.beforeInsert(new List<sObject>());
    }
    /*after delete test method*/
    @isTest
    public static void testAfterDeleteUseCase1(){
        List<NSP_Sub_Client__c> subClientObj_Obj  =  [Select Id,NSP_Client__c from NSP_Sub_Client__c WHERE NSP_Client__c = 'Client 123' limit 1];
        System.assertEquals(true,subClientObj_Obj.size()>0);
        NSP_SubClientTriggerHandler obj01 = new NSP_SubClientTriggerHandler();
        obj01.afterDelete(new List<sObject>(),new Map<Id,sObject>());
    }

    @isTest
    public static void testUpdateAssetTerminationForm(){
        List<NSP_Sub_Client__c> subClientObj_Obj  =  [Select Id,NSP_Client__c from NSP_Sub_Client__c WHERE NSP_Client__c = 'Client 123' limit 1];
        // Asset assRec = [SELECT Id, NSP_Anticipated_Date_Of_Termination__c, NSP_Verbal_Term_recd__c, NSP_Written_Term_recd__c FROM Asset WHERE NSP_Client__c = 'asset2' LIMIT 1];
        test.startTest();
        subClientObj_Obj[0].NSP_Renewal_Date__c=system.today();
        update subClientObj_Obj;
        System.assertEquals('Client 123',subClientObj_Obj[0].NSP_Client__c);
        test.stopTest();
    }

}