/**
Apex Class Name      :  NSP_ServicePlanTriggerHelperTest
Version              :  1.0                                                                          
Created Date         :  5/08/2023
Function             :  Represents test class for NSP_ServicePlanTriggerHelper class
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Simran Thukral                  5/08/2023            First Iteration
*/
@isTest
public class NSP_ServicePlanTriggerHelperTest {
    @testSetup
    static void testData() {
        
        Id woAssetRecordType = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        //inserting Account
        Account acct = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acct.Name = 'Account 1';
        acct.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.Account_Status; 
        insert acct;
        
        Asset assetObj = (Asset) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetObj.accountId = acct.Id;
        assetObj.name= 'Test';
        assetObj.RecordTypeId = woAssetRecordType;
        assetObj.Status = NSP_ServiceConstants.AIMS_STATUS;
        assetObj.NSP_Company_Name__c = 'Test Company Name';
        insert assetObj;

        NSP_Service_Plan__c servicePlan = (NSP_Service_Plan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Service_Plan__c(), 'NSP_TestDataFactory.ServicePlanDefaults', false);
        servicePlan.NSP_Account__c = acct.Id;
        insert servicePlan;

        Account acctObject = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acctObject.Name = 'Account 2';
        acctObject.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.Account_Status; 
        insert acctObject;
        
        Asset assetObj2 = (Asset) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetObj2.accountId = acctObject.Id;
        assetObj2.name= 'Test Asset Company Name';
        assetObj2.RecordTypeId = woAssetRecordType;
        assetObj2.Status = NSP_ServiceConstants.AIMS_STATUS;
        assetObj2.NSP_Company_Name__c = 'Update Company Name';
        insert assetObj2;
        
    }
    /***********************************************************************************************
    * MethodName: testAIMSClientNameOnServicePlan
    * Description : AIMS Client Name is populated on creation of Service Plan record
    * ********************************************************************************************/
     @isTest 
    static void testAIMSClientNameOnServicePlan() { 
        //when Service plan has Account lookup on creation of records
        Test.startTest();
        NSP_Service_Plan__c servicePlan = [SELECT Id,Name, NSP_Asset_AIMS_Client_Name__c FROM NSP_Service_Plan__c WHERE NSP_Account__c != NULL LIMIT 1];
        System.assertEquals(servicePlan.NSP_Asset_AIMS_Client_Name__c, 'Test Company Name');
        Test.stopTest();

    }
    /***********************************************************************************************
    * MethodName: testAIMSClientNameAfterUpdatingAccountOnServicePlan
    * Description : update the AIMS CLient Name when update the account on Service Plan
    * ********************************************************************************************/
    @isTest 
    static void testAIMSClientNameAfterUpdatingAccountOnServicePlan() { 
        
        Test.startTest();
        Account acct = [SELECT Id,Name FROM Account WHERE Name = 'Account 2' LIMIT 1]; 
        NSP_Service_Plan__c servicePlan = [SELECT Id,Name, NSP_Asset_AIMS_Client_Name__c FROM NSP_Service_Plan__c WHERE NSP_Account__c != NULL LIMIT 1]; 
       //when Account lookup is updated on service plan
        servicePlan.NSP_Account__c = acct.Id;
        update servicePlan;
        NSP_Service_Plan__c servicePlan2 = [SELECT Id,Name, NSP_Asset_AIMS_Client_Name__c FROM NSP_Service_Plan__c WHERE NSP_Account__c != NULL LIMIT 1]; 
        System.assertEquals(servicePlan2.NSP_Asset_AIMS_Client_Name__c, 'Update Company Name');
        //when Account Lookup on Service plan is empty
        servicePlan2.NSP_Account__c = NULL;
        update servicePlan2;
        NSP_Service_Plan__c servicePlan3 = [SELECT Id,Name, NSP_Asset_AIMS_Client_Name__c FROM NSP_Service_Plan__c WHERE NSP_Account__c = NULL LIMIT 1]; 
        System.assertEquals(servicePlan3.NSP_Asset_AIMS_Client_Name__c, NULL); 
        Test.stopTest();
        
        
    }
    
     @IsTest
    static void afterUpdate() {
        new NSP_ServicePlanTriggerHandler().afterUpdate(null, null);
         System.assert(new NSP_ServicePlanTriggerHandler().afterUpdate(null, null) == null);
    }
    @IsTest
    static void beforeDelete() {
        new NSP_ServicePlanTriggerHandler().beforeDelete(null, null);
         System.assert(new NSP_ServicePlanTriggerHandler().beforeDelete(null, null) == null);
    }
    @IsTest
    static void afterDelete() {
        new NSP_ServicePlanTriggerHandler().afterDelete(null, null);
         System.assert(new NSP_ServicePlanTriggerHandler().afterDelete(null, null) == null);
    }

}