/**
Apex Class Name      :  NSP_SalesToImplementationBatch_Test
Version              :  1.0                                                                          
Created Date         :  02/03/2023  
Function             :  Represents test class for NSP_SalesToImplementationBatch class
Story                :  STY-02198                                                                    
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Virendra Kumar            02/03/2023             First Iteration
*/

@isTest
public class NSP_SalesToImplementationBatch_Test {
    @testSetup
    public static void createTestData() {
        Id woRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.RET_WO_ASSET_RECORDTYPE).getRecordTypeId();
        
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
        
        Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact.AccountId = oAccount.Id;
        oContact.pse__Salesforce_User__c = UserInfo.getUserId();
        oContact.Email = 'abctestexamplyxyz@test.com.abc';
        insert oContact;
        
        //inserting Asset 
        Asset assetObj = (Asset) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetObj.accountId = oAccount.Id;
        assetObj.name='Test';
        assetObj.RecordTypeId = woRecordTypeId;
        assetObj.Status= 'Active';
        assetObj.ContactId = oContact.Id ;
        insert assetObj;
        
        NSP_Sales_to_Implementation__c  salestoImp = new NSP_Sales_to_Implementation__c(); 
        salestoImp.NSP_Client__c = oAccount.Id ;
        salestoImp.NSP_Startup__c = true;
        insert salestoImp;
    }
    
    /**
    * @Description: This test method is used to cover execute batch class
    * @Created date: 02/03/2023 
    * @return void             
    */
    
    public static  testMethod void shouldUpdateAssetOnS2I() {
        //Execute the batch
        Test.startTest();
            NSP_SalesToImplementationBatch slsToImp = new NSP_SalesToImplementationBatch();
            Database.executeBatch(slsToImp);
        Test.stopTest();
        //Check if Asset is Updated
        List<NSP_Sales_to_Implementation__c> salesToImp = [SELECT Id, NSP_Asset__c FROM NSP_Sales_to_Implementation__c WHERE NSP_Startup__c = true AND NSP_Asset__c != null LIMIT 1 ];
        
        system.assert(salesToImp.size() > 0);
    }
}