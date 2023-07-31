/**************************************************************************************************************************
*  Test Class for NSP_RET_AssetSyncWithClientHistBatch 
* Created By: Ramya Ravi
* Dated:      25/11/2022
* Version:     V1
*************************************************************************************************************************/
@isTest
Private class NSP_RET_AssetSyncWithClientHistTest {

     @testSetup
    static void testDataSetup(){
        String orgId = UserInfo.getOrganizationId();
       User testUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
         testUser.userName = 'testemail@domain'+ orgId +'.com.test';
        insert testUser;
       //create Account Record
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        insert oAccount;
        
        //create Contact Record
		Contact contactObject = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', true);        
        contactObject.AccountId = oAccount.Id;
        contactObject.lastName= 'Test';
        contactObject.pse__Salesforce_User__c=testUser.Id;
        update contactObject;                     
        
        Opportunity newOpp = (Opportunity)NSP_TestExtendedDataFactory.createSObject(new Opportunity(), 'NSP_TestDataFactory.OpportunityDefaults', false);
        newOpp.stagename = 'Proposal';
        newOpp.AccountId = oAccount.id;
        newOpp.NSP_Has_WO_Products__c = true;
        newOpp.NSP_PrimaryProduct__c ='WO';
        newOpp.Type ='Client Growth Credit';
        newOpp.NSP_Number_of_Employees__c = 12;
        //insert opportunity
        insert newOpp;
        
         //create Plan Record
        Id choicePlanRT = NSP_GenericRecordType.getRecordTypeId('NSP_Plan__c', NSP_ServiceConstants.CHOICE_RT_NAME);         
        NSP_Plan__c planRec = (NSP_Plan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan__c(), 'NSP_TestDataFactory.PlanDefaults', false);
        planRec.RecordTypeId = choicePlanRT;
        insert planRec;       

        //create Plan Sub Plan Record
        Id choiceSubPlanRT = NSP_GenericRecordType.getRecordTypeId('NSP_Plan_SubPlan__c', NSP_ServiceConstants.CHOICE_RT_NAME);        
        NSP_Plan_SubPlan__c planSubplanRec = (NSP_Plan_SubPlan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan_SubPlan__c(), 'NSP_TestDataFactory.SubPlanDefaults', false);
        planSubplanRec.NSP_Subplan_Name__c = 'Test Subplan';
        planSubplanRec.NSP_Parent_Plan_ID__c = planRec.Id;
        planSubplanRec.NSP_Subplan_ID__c = '123';
        planSubplanRec.RecordTypeId = choiceSubPlanRT;        
        insert planSubplanRec;    
                
        
        //inserting Asset
        Id RETCHOICEASSETRECORDTYPE = NSP_GenericRecordType.getRecordTypeId('Asset', 'RET_Choice');
        Asset asst = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        asst.AccountId = oAccount.Id;
        asst.ContactId = contactObject.Id;
        asst.NSP_Client__c = 'asset1';
        asst.Opportunity__c = newOpp.Id;
        asst.name = 'assetLinked';       
        asst.Status= NSP_ServiceConstants.ASSET_ONBOARDING_STATUS;
        asst.recordTypeId = RETCHOICEASSETRECORDTYPE;
        asst.NSP_RET_Plan_and_Sub_Plan__c = planSubplanRec.ID;
        insert asst;  
        
        //inserting NSP_Client_Sub_Plan_History
        Id CHOICECLIENTSUBPLANRECORDTYPEID = NSP_GenericRecordType.getRecordTypeId('NSP_Client_Sub_Plan_History__c', 'Choice');
        NSP_Client_Sub_Plan_History__c clientSubPlanHistRec1 = (NSP_Client_Sub_Plan_History__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Client_Sub_Plan_History__c(), 'NSP_TestDataFactory.clientSubPlanHistoryDefaults', false);
        clientSubPlanHistRec1.RecordTypeId = CHOICECLIENTSUBPLANRECORDTYPEID;
		clientSubPlanHistRec1.NSP_Asset__c = asst.Id;
        clientSubPlanHistRec1.NSP_End_Date__c = Date.newInstance(2022, 12, 07);
        clientSubPlanHistRec1.NSP_Start_Date__c = System.today();
        clientSubPlanHistRec1.NSP_Plan_Subplan_Relationship__c = planSubplanRec.Id;
        insert clientSubPlanHistRec1;
                  
    }
     /***********************************************************************************************
    * MethodName: testBatchClass
    * Description : Unit test for NSP_RET_AssetSyncWithClientHistBatch 
    * ********************************************************************************************/
    @isTest
    static void testBatchClass(){
        test.startTest();                                                                                              
        NSP_RET_AssetSyncWithClientHistBatch batchSch = new NSP_RET_AssetSyncWithClientHistBatch();
        Database.executeBatch(batchSch, 200);
        batchSch.execute(null);
        test.stopTest(); 
        List<Asset> Assetlist = [SELECT Id,Status,Name FROM Asset WHERE Status=: NSP_ServiceConstants.TERMINATED OR Status=: NSP_ServiceConstants.ASSET_ONBOARDING_STATUS]; 
        for(Asset AssetID:Assetlist){
            if(AssetID.name == 'assetLinked'){
                system.assertEquals(NSP_ServiceConstants.ASSET_ACTIVE_STATUS, AssetID.Status);  
            }
            if(AssetID.name == 'assetLinked1'){// test negative scenario
                system.assertEquals(NSP_ServiceConstants.TERMINATED,AssetID.Status  ); 
            }
        } 
        
    }
}