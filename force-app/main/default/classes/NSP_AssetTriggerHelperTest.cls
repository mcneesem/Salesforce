/**
* Represents test class for Asset Trigger helper 
* Represents test class for Asset Trigger Handler
* Created by : Hemali Patel
* Created Date : 9/7/2021
*/
@isTest(SeeAllData=false)
public class NSP_AssetTriggerHelperTest {
    
    /**
* Does test data setup
* Purpose : prepare test data for Test class
* @param N/A. 
* @return void                          
*/
    
    @testSetup
    static void testData() {
        
        //Account creation
        Account accoutObject = new Account();
        accoutObject.Name = 'Test Account';
        insert accoutObject;
        
        Account accoutObject1 = new Account();
        accoutObject1.Name = 'Test Account1';
        insert accoutObject1;
        
        Account accoutObject2 = new Account();
        accoutObject2.Name = 'Test Account2';
        insert accoutObject2;
        
        Account accoutObject3 = new Account();
        accoutObject3.Name = 'Test Account3';
        insert accoutObject3;
         
        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Name = 'Test Oppty';
        opportuniytObject.AccountId = accoutObject2.id;
        opportuniytObject.stagename = NSP_SalesConstants.DISCOVERY_STAGE;
        opportuniytObject.CloseDate = date.today();
        //Inserting Opportunity Object
        insert opportuniytObject;
        //Create Asset
        Asset assetObj = new Asset();
        assetObj.accountId = accoutObject.Id;
        assetObj.NSP_Client__c = 'asset1';
        assetObj.name = 'asset1';
        insert assetObj;
        
        
        //Create Asset
        Asset assetObj1 = new Asset();
        assetObj1.accountId = accoutObject1.Id;
        assetObj1.NSP_Client__c = 'asset2';
        assetObj1.name = 'asset2';
        assetObj1.NSP_Need_Rollup_Recalculation__c = true;
        insert assetObj1;
		 
		//Create Asset
        Asset assetObj2 = new Asset();
        assetObj2.accountId = accoutObject3.Id;
        assetObj2.NSP_Client__c = 'asset3';
        assetObj2.opportunity__c = opportuniytObject.Id;
        assetObj2.name = 'asset3';
        insert assetObj2;
        
        //Create Asset
        Asset assetObj4 = new Asset();
        assetObj4.accountId = accoutObject2.Id;
        assetObj4.RecordTypeId= Schema.SObjectType.Asset.RecordTypeInfosByName.get('WO').getRecordTypeId();
        assetObj4.NSP_Client__c = 'asset4';
        assetObj4.opportunity__c = opportuniytObject.Id;
        assetObj4.name = 'asset4';
        insert assetObj4;
        
        List<NSP_Sub_Client__c> subClientList = new List<NSP_Sub_Client__c>();
        for(integer icount = 0 ; icount< 5 ;icount++){
            NSP_Sub_Client__c subClientObj = new NSP_Sub_Client__c();
            subClientObj.NSP_Client__c = 'asset1'+String.valueOf(icount);
            subClientObj.NSP_Paid_Employees_Last_Month__c = 1;
            subClientObj.NSP_Actual_Full_Time_EE_Count__c = 1;
            subClientObj.NSP_Actual_Part_Time_EE_Count__c = 3;
            subClientObj.NSP_Actual_Seasonal_Time_EE_Count__c =2;
            subClientObj.NSP_Contractual_Full_time_EE_Count__c = 2;
            subClientObj.NSP_Contractual_Part_time_EE_Count__c = 3;
            subClientObj.NSP_Contractual_Seasonal_Time_EE_Count__c = 1 ;  
            subClientObj.NSP_Account__c = accoutObject.Id;
            subClientObj.NSP_Asset__c = assetObj.Id;
            subClientList.add(subClientObj);    
        }
        
        for(integer icount = 0 ; icount< 3 ;icount++){
            NSP_Sub_Client__c subClientObj = new NSP_Sub_Client__c();
            subClientObj.NSP_Client__c = 'asset2'+icount;
            subClientObj.NSP_Paid_Employees_Last_Month__c = 1;
            subClientObj.NSP_Actual_Full_Time_EE_Count__c = 1;
            subClientObj.NSP_Actual_Part_Time_EE_Count__c = 3;
            subClientObj.NSP_Actual_Seasonal_Time_EE_Count__c =2;
            subClientObj.NSP_Contractual_Full_time_EE_Count__c = 2;
            subClientObj.NSP_Contractual_Part_time_EE_Count__c = 3;
            subClientObj.NSP_Contractual_Seasonal_Time_EE_Count__c = 1 ;  
            subClientObj.NSP_Account__c = accoutObject1.Id;
            subClientObj.NSP_Asset__c = assetObj1.Id;
            subClientList.add(subClientObj);
        }
        
        if(subClientList.size() > 0){
            insert subClientList;
        }
        
        
    }
    
    /**
* Checks the update protion of the trigger
* Purpose : positive test method for beforeUpdateDirector
* @param N/A. 
* @return void                          
*/
    @isTest
    static void beforeUpdateDirectorTest() {
        List<Asset> assetList = [SELECT ID,Name,NSP_Need_Rollup_Recalculation__c FROM Asset WHERE Name !=null LIMIT 1];
        Test.startTest();
            Asset assetObj = new Asset();
            assetObj.Id = assetList[0].ID;
            assetObj.NSP_Need_Rollup_Recalculation__c = true;
            assetObj.NSP_Client_Segment_type__c ='Core';
        	assetObj.NSP_Client_SegmentDate__c = system.Today().addDays(10);
            update assetObj;
        Test.stopTest();
        List<Asset> assetList1 = [SELECT ID,NSP_Need_Rollup_Recalculation__c,NSP_Actual_Part_Time_EE_Count__c FROM 
                                  Asset WHERE NSP_Need_Rollup_Recalculation__c = true]; 
    	System.assertEquals(true, assetList1[0].NSP_Need_Rollup_Recalculation__c);
    
    }
  /**
* Checks the update protion of the trigger of WX_WA record type
* Created by Rahul Singh
* Date : 8/29/2022
* @param N/A. 
* @return void                          
*/    
     @isTest
    static void afterUpdateWXTest() {
        
        Id new_Asset_RT_ID = Schema.SObjectType.Asset.RecordTypeInfosByName.get('WX_WA').getRecordTypeId();
        List<Asset> assetList = [SELECT ID,Name FROM Asset WHERE Name = 'asset3' LIMIT 1];
        Test.startTest();
        Asset assetObj = new Asset();
        assetObj.Id = assetList[0].ID;
        assetObj.recordtypeid = new_Asset_RT_ID;
        assetObj.NSP_First_Pay_Date__c = date.today();
        update assetObj;
        Test.stopTest();
        List<Asset> assetList1 = [SELECT ID,Name, NSP_First_Pay_Date__c FROM Asset WHERE Name = 'asset3' LIMIT 1];
		System.assertEquals(date.today(), assetList1[0].NSP_First_Pay_Date__c);
        
    }

/**
* Checks the update protion of the trigger of WO record type
* Created by Rahul Singh
* Date : 8/29/2022
* @param N/A. 
* @return void                          
*/    
     @isTest
    static void afterUpdateWOTest() {
        
        Id new_Asset_RT_ID = Schema.SObjectType.Asset.RecordTypeInfosByName.get('WO').getRecordTypeId();
        List<Asset> assetList = [SELECT ID,Name FROM Asset WHERE Name = 'asset3' LIMIT 1];
        Test.startTest();
        Asset assetObj = new Asset();
        assetObj.Id = assetList[0].ID;
        assetObj.recordtypeid = new_Asset_RT_ID;
        assetObj.NSP_AIMS_First_Pay_Date__c = date.today();
        update assetObj;
        Test.stopTest();
        List<Asset> assetList1 = [SELECT ID,Name,NSP_AIMS_First_Pay_Date__c FROM Asset WHERE Name = 'asset3' LIMIT 1];
		System.assertEquals(date.today(), assetList1[0].NSP_AIMS_First_Pay_Date__c);
        
    }
    
    @isTest
    static void afterPayDateWOTest() {
        
        Id new_Asset_RT_ID = Schema.SObjectType.Asset.RecordTypeInfosByName.get('WX_WA').getRecordTypeId();
        Id  soldToCheckListRecordTypeId = Schema.SObjectType.NSP_Checklist__c.getRecordTypeInfosByDeveloperName().get('NSP_Sold_to_Paid_Checklist').getRecordTypeId();
        List<Asset> assetList = [SELECT ID,Name,recordtypeid,NSP_AIMS_First_Pay_Date__c,Opportunity__c FROM Asset WHERE Name = 'asset4' LIMIT 1];
        Opportunity eachOppty = [SELECT id,NSP_PrimaryProduct__c,StageName,OwnerId from opportunity LIMIT 1];
        
         Id taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Core_Sales_Task_RT').getRecordTypeId();
        Task taskRec = new Task(
            Subject = 'Discovery Call',
            WhatId = eachOppty.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = taskRecTypeId,
            NSP_Task_Subtype__c = 'Client Meeting',
            NSP_Status__c='Completed'
        );
        insert taskRec;
        
        eachOppty.NSP_BPA__c = eachOppty.OwnerId;
        //eachOppty.StageName = 'Closed Won';
        eachOppty.NSP_PrimaryProduct__c = 'WO';
        eachOppty.StageName = 'Closing';
        Test.startTest();
        update eachOppty;
            NSP_Checklist__c eachCheckList = new NSP_Checklist__c();
            eachCheckList.RecordTypeId = soldToCheckListRecordTypeId;
            eachCheckList.NSP_Opportunity__c = eachOppty.Id;
            eachCheckList.NSP_Requested_First_Pay_Date__c = system.today();
          insert eachCheckList;
        
        Asset assetObj = new Asset();
        assetObj.Id = assetList[0].ID;
        assetObj.recordtypeid = new_Asset_RT_ID;
        assetObj.NSP_AIMS_First_Pay_Date__c = date.today();
        assetObj.Opportunity__c = eachOppty.ID;
        update assetObj;
        Test.stopTest();
        List<Asset> assetList1 = [SELECT ID,Name,NSP_AIMS_First_Pay_Date__c FROM Asset WHERE Name = 'asset4' LIMIT 1];
		System.assertEquals(date.today(), assetList1[0].NSP_AIMS_First_Pay_Date__c);
        
    }
    
    
}