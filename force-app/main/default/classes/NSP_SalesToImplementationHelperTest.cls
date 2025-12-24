/**
Apex Class Name      :  NSP_SalesToImplementationHelperTest
Version              :  1.0                                                                          
Created Date         :  10/13/2022  
Function             :  Represents test class for NSP_SalesToImplementationHelperTest class
Story                :  STY-02743                                                                    
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Ramya Ravi              10/13/2022             First Iteration
*/
@isTest
public class NSP_SalesToImplementationHelperTest {
/***********************************************************************************************
    * MethodName: setUpData
    * Description : Setting the Test Data
    * ********************************************************************************************/
    @testSetup
    public static void setUpData(){
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;
        
        //Get Record type Id of Retirement_Services
        Id AssetRecordTypeId  = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE);        
        
        //create Account Record
        Account accoutObject = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        insert accoutObject;
        
        //create Contact Record
		Contact contactObject = new Contact();
        contactObject.AccountId = accoutObject.Id;
        contactObject.lastName= 'Test';
        contactObject.pse__Salesforce_User__c= userinfo.getUserId() ;
        insert contactObject;

        //create Asset Record
        Asset assetObj1 = new Asset();
        assetObj1.accountId = accoutObject.Id;
        assetObj1.ContactId = contactObject.Id;
        assetObj1.NSP_Client__c = 'asset1';
        assetObj1.Name = 'assetLinkedWithClientSubPlanHis';
        assetObj1.RecordTypeId = AssetRecordTypeId;
        insert assetObj1;

        //create Asset Record
        Asset assetObj2 = new Asset();
        assetObj2.accountId = accoutObject.Id;
        assetObj2.ContactId = contactObject.Id;
        assetObj2.NSP_Client__c = 'assetNotLinkedWithClientSubPlanHis';
        assetObj2.name = 'asset2';
        assetObj2.RecordTypeId = AssetRecordTypeId;
        insert assetObj2;

        //create Plan Record
        NSP_Plan__c planRec = new NSP_Plan__c();
        insert planRec;

        //create Plan Sub Plan Record
        NSP_Plan_SubPlan__c planSubplanRec = new NSP_Plan_SubPlan__c();
        planSubplanRec.NSP_Parent_Plan_ID__c = planRec.Id;
        planSubplanRec.NSP_Subplan_ID__c = '123';
        insert planSubplanRec;  
    }
    
    
    /***********************************************************************************************
    * MethodName: afterInsertTest
    * Description : Unit test for afterInsertTest 
    * ********************************************************************************************/
    @isTest
    public static void afterInsertUpdateTest(){
        
        //get List of Asset created in test setup
        Asset assetRec = [SELECT Id , Name FROM Asset WHERE Name != null LIMIT 1 ];    
        
        NSP_Plan_SubPlan__c planSubplanRec = [SELECT Id FROM NSP_Plan_SubPlan__c WHERE Id != null LIMIT 1];

        //create Amendment Checklist Record
        NSP_Sales_to_Implementation__c S2IRec = new NSP_Sales_to_Implementation__c();
        S2IRec.NSP_Status_Date__c =  Date.newInstance(2016, 12, 9);
        S2IRec.NSP_Asset__c = assetRec.Id;
        S2IRec.NSP_Subplan_Plan_Details_Record__c = planSubplanRec.Id;
        
         NSP_Sales_to_Implementation__c S2IRecUpdate = new NSP_Sales_to_Implementation__c();
        S2IRecUpdate.NSP_Asset__c = assetRec.Id;
        S2IRecUpdate.NSP_Subplan_Plan_Details_Record__c = planSubplanRec.Id;   
       
            Test.startTest();           
            	 insert S2IRec;
       			 insert S2IRecUpdate;
         		 S2IRecUpdate.NSP_Status_Date__c =  Date.newInstance(2016, 12, 9);
       			 update S2IRecUpdate;
            Test.stopTest();        
        System.assertEquals(Date.newInstance(2016, 12, 9), S2IRecUpdate.NSP_Status_Date__c);
    }

}