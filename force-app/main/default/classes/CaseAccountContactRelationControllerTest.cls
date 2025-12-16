@isTest
private class CaseAccountContactRelationControllerTest {
    private static final String CASEDEFAULTS  = 'NSP_TestDataFactory.CaseDefaults';
    private static final String ACCOUNTDEFAULTS = 'NSP_TestDataFactory.AccountDefaults';
    private static final String CONTACT_DEFAULTS_LIGHT = 'NSP_TestDataFactory.ContactDefaultsLight';
    private static final Id bpsProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', NSP_ServiceConstants.PROJECT_BPS_RECORDTYPE);
    private static final Id wOAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
   @testSetup
    private static void testData() {
        List<Case> caseList = new List<Case>();
        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), ACCOUNTDEFAULTS, true);
        Account assetAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), ACCOUNTDEFAULTS, false);
        assetAccount.Name = 'Test Asset';
        insert assetAccount;
        
        //create new contact
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), CONTACT_DEFAULTS_LIGHT, false);
        newContact.AccountId = newAccount.Id;
        newContact.NSP_Work_email__c = 'test123@efg.com';
        insert newContact;
        
        Asset woAssetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        woAssetRecord.AccountId = assetAccount.Id;
        woAssetRecord.NSP_Account_Status__c = NSP_ServiceConstants.AIMS_STATUS;
        woAssetRecord.RecordTypeId = wOAssetRecordTypeId;
        woAssetRecord.NSP_Client_Segment_type__c = NSP_ServiceConstants.CoreAssetSegment;
        Database.insert(woAssetRecord, false); 
        
        NSP_Category_Sub_Category_Mapping__c newCat = (NSP_Category_Sub_Category_Mapping__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Category_Sub_Category_Mapping__c(), 'NSP_TestDataFactory.CatSubCatMappingDefaults', false);
        newCat.NSP_UserTitle__c = 'Benefits Manager';
        newCat.NSP_Category__c = NSP_ServiceConstants.CATEGORY_ADAPTION;
        newCat.NSP_Subcategory__c = NSP_ServiceConstants.SUB_CATEGORY_CLAIM;
        newCat.NSP_Detail__c = 'Login';
        newCat.NSP_isActive__c=True;
        newCat.NSP_Asset_Record_Types__c='WO';
        newCat.NSP_RecordType__c='PEO';
        newCat.NSP_Public_Groups_To_Share__c = 'All Data Visibility'; 
        Database.insert(newCat);
        
        pse__Proj__c bpsProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        bpsProject.RecordTypeId = bpsProjectRecordTypeId;
        bpsProject.Templates_Used__c = NSP_ServiceConstants.ITA_IMPLEMENTATION;
        bpsProject.pse__Project_Status__c = 'Active';
        bpsProject.Project_Implementer__c = userinfo.getUserId();
        bpsProject.pse__Is_Active__c = true; 
        insert bpsProject; 
        
        Test.startTest();
        //Creating case for Report dev Notification testing
        Case asssetCaseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        asssetCaseRecord.NSP_Category__c = 'Adaption';
        asssetCaseRecord.NSP_SubCategory__c = 'Claim';
        asssetCaseRecord.Subject = 'Test Asset Mapping';
        asssetCaseRecord.AccountId = newAccount.Id;
        caseList.add(asssetCaseRecord); 
        insert caseList;
        
        NSP_Case_Contacts__c addCseCon = (NSP_Case_Contacts__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Case_Contacts__c(), 'NSP_TestDataFactory.caseContactDefaults', false);
        addCseCon.NSP_Contact__c = newContact.Id;
        addCseCon.NSP_Case__c = asssetCaseRecord.Id;
        addCseCon.NSP_IsPrimary__c = false;
        insert addCseCon;
       
        
        Test.stopTest();
        
    }
    @isTest
    private static void testACR(){
        List<Case> records = [Select Id, AccountId, ContactId from case Limit 1];
        CaseAccountContactRelationController.getACRDetails(records[0].Id);
    }
}