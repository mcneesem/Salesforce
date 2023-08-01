@isTest
Private class NSP_RelatedAssetsController_Test {
    /**
    * Test data for RelatedAssets for Assets and regulated States.
    * @param N/A. 
    * @return void                          
    */
    
    @testSetup
    static void testData() {
        Account newAcc =  New Account(Name = 'TestAccount', AccountNumber = '1234',NSP_AIMS_Client__c = 'ateammember1');
        insert newAcc;
        
        Id woRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();
        
        List<Asset> lstAssets = new List<Asset>();
        Asset newAsset = new Asset(AccountId = newAcc.Id, Status='Active', NSP_Client__c = 'Asset1', NSP_Company_Name__c = 'Test Company', Name = 'Asset1', RecordTypeId = wORecordTypeId);
        lstAssets.add(newAsset);
        
        Asset newAsset2 = new Asset(AccountId = newAcc.Id, Status='Active', NSP_Client__c = 'Asset2', NSP_Company_Name__c = 'Company Test PwC', Name = 'Asset Company', RecordTypeId = wORecordTypeId);
        lstAssets.add(newAsset2);
        insert lstAssets;
        
        List<NSP_Regulated_Area__c> lstRegulatedAssets = new List<NSP_Regulated_Area__c>();
        NSP_Regulated_Area__c regulatedAsset = new NSP_Regulated_Area__c(NSP_Regulation_Type__c = 'State Retirement Plan', NSP_State__c = 'NH');
        lstRegulatedAssets.add(regulatedAsset);
        
        NSP_Regulated_Area__c regulatedAsset2 = new NSP_Regulated_Area__c(NSP_Regulation_Type__c = 'State Retirement Plan', NSP_State__c = 'VA');
        lstRegulatedAssets.add(regulatedAsset2);
        insert lstRegulatedAssets;
        
    }
    
    @isTest
    static void createImplementationProject(){
        Test.startTest();
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Id != null LIMIT 1];
        Implementation_Profile__c oIProfile = new Implementation_Profile__c(Legal_Name__c = 'Legal Name');
        oIProfile.Account__c = acc.Id;
        oIProfile.First_Pay_Date__c= system.today();
        oIProfile.Num_of_Worksite_Employees_Full_Time__c= 11;
        oIProfile.Num_of_Worksite_Employees_Part_Time__c=11;
        oIProfile.Num_of_Worksite_Employees_Seasonal__c=11;
        oIProfile.Client_have_any_EEs_on_F1_or_J1_Visa_s__c = NSP_ServiceConstants.YES;
        oIProfile.NSP_EE_Name__c = 'Test 123';
        oIProfile.Client_Profile_Information__c = 'Related Clients';
        insert oIProfile;
        
        NSP_IP_Related_Client__c relateClient = new NSP_IP_Related_Client__c();
        relateClient.NSP_Related_Client__c = acc.Id;
        relateClient.NSP_Implementation_Profile__c = oIProfile.Id;
        insert relateClient;
        // WHEN
        NSP_RelatedAssetsController.getrecId();
        NSP_RelatedAssetsController.setrecId(oIProfile.Id);
        NSP_RelatedAssetsController.getState();
        NSP_RelatedAssetsController.setState('NH;VA');
        String accountId = NSP_RelatedAssetsController.accountId;
        String state = NSP_RelatedAssetsController.state;
        List<Asset> relatedAssets = NSP_RelatedAssetsController.relatedAssets;
        List<String> regulatedAreaStates = NSP_RelatedAssetsController.regulatedAreaStates; 
        List<NSP_IP_Related_Client__c> ipRelatedClients = NSP_RelatedAssetsController.ipRelatedClients; 
        
        NSP_RelatedAssetsController.getFSOEmail();
        
        //THEN
        System.assertEquals(accountId, acc.Id, 'Account Id Matched');
        System.assertEquals(regulatedAreaStates.size(), 2, '2 states found');
        System.assertEquals(relatedAssets.size(),2);
        System.assertEquals(state,'NH;VA');
        Test.stopTest();
    }
}