/**
Apex Class Name      :  NSP_UpdateServiceSegmentOnAccBatchTest for NSP_UpdateServiceSegmentOnAccBatch
Version              :  1.0                                                                          
Created Date         :  1/11/2022   
Function             :  Test class for NSP_UpdateServiceSegmentOnAccBatch 
Story                :  STY-02819                                                                    
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Srushti                     1/11/2022            First Iteration
*/

@isTest
public class NSP_UpdateServiceSegmentOnAccBatchTest {
    private static final Id woAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', 'WO');
    private static final Id wxWaAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', 'NSP_Asset_Product');
    @testSetup
    private static void setUpTestData(){

        //Creating Account record
        Account accountRecord = (Account)NSP_TestExtendedDataFactory.createSObject(new Account());
        accountRecord.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.Account_Status;
        accountRecord.NSP_First_Pay_Date__c = system.Today();
        Database.insert(accountRecord);
        //insert account
        Account accoutObject = (Account)NSP_TestExtendedDataFactory.createSObject(new Account());
        accoutObject.Name = 'Test Account';
        Database.insert(accoutObject);
        
        //create asset records
        Asset woAssetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        woAssetRecord.AccountId = accoutObject.Id;
        woAssetRecord.Status = NSP_ServiceConstants.ASSET_ONBOARDING_STATUS;
        woAssetRecord.RecordTypeId = woAssetRecordTypeId;
        woAssetRecord.NSP_Client_Segment_type__c = NSP_ServiceConstants.CoreAssetSegment;
        Database.insert(woAssetRecord, false);
        //insert asset records
        Asset wxWaAssetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        wxWaAssetRecord.AccountId = accountRecord.Id;
        wxWaAssetRecord.Status = NSP_ServiceConstants.ASSET_ONBOARDING_STATUS;
        wxWaAssetRecord.RecordTypeId = wxWaAssetRecordTypeId;
        wxWaAssetRecord.NSP_Client_Segment_type__c = NSP_ServiceConstants.CoreAssetSegment;
        Database.insert(wxWaAssetRecord, false);
    }
    
    /***********************************************************************************************
    * MethodName: updateServiceSegmentOnAccountTest
    * Description : Test method to check if Service Segment is updated on Account
    * Parameters : N/A
    * return : void
    *********************************************************************************************/
    @isTest
    private static void updateServiceSegmentOnAccountTest(){
        test.startTest();
        NSP_UpdateServiceSegmentOnAccBatch batchSch = new NSP_UpdateServiceSegmentOnAccBatch();
        Database.executeBatch(batchSch, 200);
        test.stopTest();
        
        List<String> assetFields = new List<String>{
            'Id',
            'RecordTypeId',
            'NSP_Client_Segment_type__c',
            'Status',
            'AccountId'
        };
        
        List<String> accountFields = new List<String>{
            'Id',
            'NSP_Service_Segment__c',
            'Name'
        };
                
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder('Account', accountFields)
                						.addFilter('Name', 'Test Account')
            							.addLimit(1)
            							.setSecurityEnforce(false);
        String query = queryBuilder.build();    
        Account acc = Database.query(query);
        
        NSP_QueryBuilder assetQueryBuilder = new NSP_QueryBuilder(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, assetFields)
            							.addFilter('AccountId', acc.Id)
            							.addFilter('RecordTypeId', woAssetRecordTypeId)
            							.addFilter('Status', NSP_ServiceConstants.ASSET_ONBOARDING_STATUS)
            							.addFilter('NSP_Client_Segment_type__c', NSP_ServiceConstants.CoreAssetSegment)
            							.addLimit(1)
            							.setSecurityEnforce(false);
        String assetQuery = assetQueryBuilder.build();   
        //assert statement
        System.assertEquals(NSP_ServiceConstants.CoreAssetSegment, acc.NSP_Service_Segment__c);
    }	
    
    /***********************************************************************************************
    * MethodName: updateServiceSegmentOnAccountNegativeTest
    * Description : Test method to check if Service Segment is not updated if condition is 
    * 				not satisfied.
    * Parameters : N/A
    * return : void
    *********************************************************************************************/
    @isTest
    private static void updateServiceSegmentOnAccountNegativeTest(){
        List<String> assetFields = new List<String>{
            'Id',
            'RecordTypeId',
            'NSP_Client_Segment_type__c',
            'Status',
            'AccountId'
        };
        
        List<String> accountFields = new List<String>{
            'Id',
            'NSP_Service_Segment__c',
            'Name'
        };
                
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder('Account', accountFields)
                						.addFilter('Name', 'Test Account')
            							.addLimit(1)
            							.setSecurityEnforce(false);
        String query = queryBuilder.build();    
        Account acc = Database.query(query);
        
        NSP_QueryBuilder assetQueryBuilder = new NSP_QueryBuilder(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, assetFields)
            							.addFilter('AccountId', acc.Id)
            							.addFilter('RecordTypeId', woAssetRecordTypeId)
            							.addFilter('Status', NSP_ServiceConstants.ASSET_ONBOARDING_STATUS)
            							.addFilter('NSP_Client_Segment_type__c', NSP_ServiceConstants.CoreAssetSegment)
            							.addLimit(1)
            							.setSecurityEnforce(false);
        String assetQuery = assetQueryBuilder.build();    
        Asset woAssetRec = Database.query(assetQuery);
        

        woAssetRec.Status = NSP_ServiceConstants.ASSETBLACKOUT;
        woAssetRec.NSP_Client_Segment__c = NSP_ServiceConstants.BTAssetSegment;
        
        test.startTest();
        Database.update(woAssetRec);
        NSP_UpdateServiceSegmentOnAccBatch batchSch = new NSP_UpdateServiceSegmentOnAccBatch();
        Database.executeBatch(batchSch, 200);
        test.stopTest();
        //assertstatement
        System.assertEquals(NSP_ServiceConstants.CoreAssetSegment, acc.NSP_Service_Segment__c);  
    }

}