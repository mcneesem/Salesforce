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
        
        List<Asset> assetList = new List<Asset>();
        
        Account oAccount = [SELECT Id, Name, NSP_Sales_Service_Account_Status__c  FROM Account WHERE Name='Test Account' LIMIT 1];
        oAccount.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.STATUS_ACTIVE;
        update oAccount;
    	//integra asset creation
        Asset integraAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        integraAsset.AccountId = oAccount.Id;
        integraAsset.recordTypeId = INTEGRA_ASSET;
        
        assetList.add(integraAsset);       
        
        // WHEN
        Test.startTest();
        if(!assetList.isEmpty()){
        	insert assetList;
        }
        Test.stopTest();
        
            
        // THEN
        System.assertEquals(1, assetList.size());
    }
    
    @isTest
    public static void testUpdateAssetTerminationForm(){
        
        List<Asset> asset =[SELECT NSP_Verbal_Term_recd__c,NSP_Written_Term_Date__c,NSP_Written_Term_recd__c,
                            NSP_Anticipated_Date_Of_Termination__c,NSP_Reason_for_Term__c FROM Asset WHERE recordTypeId=:WO_ASSET LIMIT 1];
        test.startTest();
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