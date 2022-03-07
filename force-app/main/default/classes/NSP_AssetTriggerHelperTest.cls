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
            update assetObj;
        Test.stopTest();
        List<Asset> assetList1 = [SELECT ID,NSP_Need_Rollup_Recalculation__c,NSP_Actual_Part_Time_EE_Count__c FROM 
                                  Asset WHERE NSP_Need_Rollup_Recalculation__c = true]; 
    	System.assertEquals(true, assetList1[0].NSP_Need_Rollup_Recalculation__c);
    
    }
    
}