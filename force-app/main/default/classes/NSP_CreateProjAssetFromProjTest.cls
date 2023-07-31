// Test Class for NSP_CreateProjAssetFromProjBatch
// Created By:Ramya Ravi 
// Date: 13/1/2023

@isTest
public class NSP_CreateProjAssetFromProjTest {
    
 @testSetup
    public static void setupData(){
        Id RETChoiceRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE);
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
        Account oAccountnew = new Account(); 
        oAccountnew.name = 'Account New';
        insert oAccountnew;

        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);      
        oProject.NSP_Is_Project_Asset_Created__c = false;
        oProject.NSP_Asset_Type__c = NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE;
        insert oProject;
        
         //Creating Asset record
        Asset assetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetRecord.AccountId = oAccount.Id;      
        assetRecord.NSP_Account_Status__c = NSP_ServiceConstants.AIMS_STATUS;
        assetRecord.RecordTypeId = RETChoiceRecordTypeId;       
        INSERT assetRecord; 
        
        Asset assetRecordNew = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetRecordNew.name = 'asset New';
        assetRecordNew.AccountId = oAccountnew.Id;       
        assetRecordNew.NSP_Account_Status__c = NSP_ServiceConstants.AIMS_STATUS;
        assetRecordNew.RecordTypeId = RETChoiceRecordTypeId;      
        INSERT assetRecordNew;  
        
        project_account__c projAcct = new project_account__c();
        projAcct.project__c = oProject.ID;
        projAcct.Account__c =oAccountnew.ID;
        Insert projAcct;        
    }
    
    @isTest
    public static void createProjAssetFromProj(){
        Test.startTest();
          Database.executeBatch(new NSP_CreateProjAssetFromProjBatch(),2000);
        System.assert(Database.executeBatch(new NSP_CreateProjAssetFromProjBatch(),2000) != null);
        Test.stopTest();     
    }
}