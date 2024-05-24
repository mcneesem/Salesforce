/**
Apex Class Name      :  NSP_AssetServiceHelperTest
Version              :  1.0                                                                          
Created Date         :  10/18/2022  
Author               :  Bindushree  
Function             :  This class is used as a test class to NSP_AssetServiceHelper
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Bindushree                 10/18/2022          First Iteration
*/

@isTest
public class NSP_AssetServiceHelperTest {
    
    
    //Declare asset record type ids
    public static final Id INTEGRA_ASSET = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.INTEGRA );
    public static final Id PERFORM_SMART_ASSET = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.PERFORMANCE_ASSET );
    public static final Id TIME_ATTENDANCE_ASSET = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.ASSET_TT_RECORDTYPE );
    public static final Id XML_ASSET = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.XML_ASSET );
    public static final Id WO_ASSET = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE );
       

            
    
    
    /**
	* Does test data setup
	* @param N/A.
	* @return void                          
	*/
    
    @testSetup
    static void testData() {
        
        //Account creation
        Account accoutObject = new Account();
        accoutObject.Name = 'Test Account';
        accoutObject.NSP_Sales_Service_Account_Status__c= NSP_ServiceConstants.STATUS_ACTIVE;
        insert accoutObject;
        
        //Opportunity Creation
        Opportunity newOpp = (Opportunity)NSP_TestExtendedDataFactory.createSObject(new Opportunity(), 'NSP_TestDataFactory.OpportunityDefaults', false);
        newOpp.stagename = 'Discovery';
        newOpp.AccountId = accoutObject.id;
        newOpp.NSP_Has_WO_Products__c = true;
        newOpp.NSP_PrimaryProduct__c ='Applicant Tracking';
        newOpp.NSP_Number_of_Employees__c = 151;
        insert newOpp;
        
        //Asset creation
        Asset woAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        woAsset.AccountId = accoutObject.Id;
        woAsset.recordTypeId = WO_ASSET;
        insert woAsset;
        
        // create Subclient
        NSP_Sub_Client__c subClientObj = new NSP_Sub_Client__c();
        subClientObj.NSP_Account__c = accoutObject.Id;
        subClientObj.NSP_Asset__c = woAsset.Id;
        subClientObj.NSP_Client__c = 'Client 123';
        subClientObj.NSP_Sub_Client__c='23400';
        subClientObj.NSP_Renewal_Date__c=system.today();
        insert subClientObj; 
    }
    
    @isTest
    static void createBPSProjectwithAssetRecordType(){
        // GIVEN
        Test.startTest();
        List<Asset> assetList = new List<Asset>();
        List<Opportunity> opportunityList = [SELECT Id,NSP_PrimaryProduct__c,AccountId,OwnerId FROM Opportunity WHERE NSP_Number_Of_Employees__c = 151 LIMIT 1];
            opportunity oppty = opportunityList[0];
            oppty.NSP_DM_User__c = oppty.OwnerId;
            oppty.NSP_DA_User__c = oppty.OwnerId;
            oppty.NSP_BPA__c = oppty.OwnerId;
            oppty.StageName = 'Closed Won';
      		oppty.NSP_PrimaryProduct__c = 'Performance Management';
            oppty.NSP_Time_Entry_Recommendation__c = NSP_ServiceConstants.Premier_Time_Att;
            oppty.NSP_Signed_CSA__c = true;
            oppty.NSP_Signed_CSA_Date__c = system.today();
      
            update oppty;
      
        Account oAccount = [SELECT Id, Name, NSP_Sales_Service_Account_Status__c  FROM Account WHERE Name='Test Account' LIMIT 1];
        oAccount.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.STATUS_ACTIVE;
        update oAccount;
    	//integra asset creation
        Asset integraAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        integraAsset.AccountId = oAccount.Id;
        integraAsset.recordTypeId = INTEGRA_ASSET;
        
        Asset PerformanceAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        PerformanceAsset.AccountId = oAccount.Id;
        PerformanceAsset.Opportunity__c = oppty.Id;
        PerformanceAsset.recordTypeId = PERFORM_SMART_ASSET;
        
        assetList.add(integraAsset);
        assetList.add(PerformanceAsset);
        
        // WHEN
        
        if(!assetList.isEmpty()){
        	insert assetList;
        }
        Test.stopTest();
        
            
        // THEN
        System.assertEquals(2, assetList.size());
    }
    @isTest
    static void createPerformanceProjectwithAssetRecordType(){
        Test.startTest();
        // GIVEN
        
        List<Asset> assetList = new List<Asset>();
        List<Opportunity> opportunityList = [SELECT Id,NSP_PrimaryProduct__c,AccountId,OwnerId FROM Opportunity WHERE NSP_Number_Of_Employees__c = 151 LIMIT 1];
            opportunity oppty = opportunityList[0];
            oppty.NSP_DM_User__c = oppty.OwnerId;
            oppty.NSP_DA_User__c = oppty.OwnerId;
            oppty.NSP_BPA__c = oppty.OwnerId;
            oppty.StageName = 'Closed Won';
      		oppty.NSP_PrimaryProduct__c = 'Performance Management';
            oppty.NSP_Time_Entry_Recommendation__c = NSP_ServiceConstants.Premier_Time_Att;
            oppty.NSP_Signed_CSA__c = true;
            oppty.NSP_Signed_CSA_Date__c = system.today();
        	oppty.NSP_IPMRecommendation__c = 'Yes';
      
            update oppty;
      
        Account oAccount = [SELECT Id, Name, NSP_Sales_Service_Account_Status__c  FROM Account WHERE Name='Test Account' LIMIT 1];
        oAccount.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.STATUS_ACTIVE;
        update oAccount;
        
        Asset PerformanceAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        PerformanceAsset.AccountId = oAccount.Id;
        PerformanceAsset.Opportunity__c = oppty.Id;
        PerformanceAsset.recordTypeId = PERFORM_SMART_ASSET;
        
        assetList.add(PerformanceAsset);
        
        // WHEN
        
        if(!assetList.isEmpty()){
        	insert assetList;
        }
        Test.stopTest();
        
            
        // THEN
        System.assertEquals(1, assetList.size());
    }
    @isTest
    static void createTimeAndAttendence(){
        Test.startTest();
        // GIVEN
        
        List<Asset> assetList = new List<Asset>();
        List<Opportunity> opportunityList = [SELECT Id,NSP_PrimaryProduct__c,AccountId,OwnerId FROM Opportunity WHERE NSP_Number_Of_Employees__c = 151 LIMIT 1];
            opportunity oppty = opportunityList[0];
            oppty.NSP_DM_User__c = oppty.OwnerId;
            oppty.NSP_DA_User__c = oppty.OwnerId;
            oppty.NSP_BPA__c = oppty.OwnerId;
            oppty.StageName = NSP_ServiceConstants.CLOSED_WON;
      		oppty.NSP_PrimaryProduct__c = NSP_ServiceConstants.TIME_ATTENDANCE;
            oppty.NSP_Time_Entry_Recommendation__c = NSP_ServiceConstants.Premier_Time_Att;
            oppty.NSP_Signed_CSA__c = true;
            oppty.NSP_Signed_CSA_Date__c = system.today();
            update oppty;
        
        Account oAccount = [SELECT Id, Name, NSP_Sales_Service_Account_Status__c  FROM Account WHERE Name='Test Account' LIMIT 1];
        oAccount.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.STATUS_ACTIVE;
        update oAccount;
        
        Asset timeAttendenceAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        timeAttendenceAsset.AccountId = oAccount.Id;
        timeAttendenceAsset.Opportunity__c = oppty.Id;
        timeAttendenceAsset.recordTypeId = TIME_ATTENDANCE_ASSET;
        
        assetList.add(timeAttendenceAsset);
        
        // WHEN
        
        if(!assetList.isEmpty()){
        	insert assetList;
        }
        Test.stopTest();
        
        System.assertEquals(1, assetList.size());
     
    }
    
    @isTest
    public static void testUpdateAssetTerminationForm(){
        test.startTest();
        List<Asset> asset =[SELECT NSP_Verbal_Term_recd__c,NSP_Written_Term_Date__c,NSP_Written_Term_recd__c,
                            NSP_Anticipated_Date_Of_Termination__c,NSP_Reason_for_Term__c FROM Asset WHERE recordTypeId=:WO_ASSET LIMIT 1];
        
        asset[0].NSP_Verbal_Term_recd__c=true;
        asset[0].NSP_Written_Term_recd__c=true;
        asset[0].NSP_Anticipated_Date_Of_Termination__c=system.today();
        asset[0].NSP_Reason_for_Term__c='testing';
        
        update asset;
        asset[0].NSP_Anticipated_Date_Of_Termination__c=system.today()-1;
        update asset;
        
        
        test.stopTest();
        System.assertEquals(null, asset[0].NSP_Written_Term_Date__c);
        
        
    }

}