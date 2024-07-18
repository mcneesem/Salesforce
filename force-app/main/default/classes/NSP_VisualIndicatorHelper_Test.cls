/**
* @description  :   Test class for NSP_VisualIndicatorHelper.
* @date 07/18/2024
* Author : Arun Dasari
* Name : NSP_VisualIndicatorHelper_Test(97%)
*/

@isTest
public class NSP_VisualIndicatorHelper_Test 
{
    // Global constants
    private static final String ACCOUNTDEFAULTS 			= 'NSP_TestDataFactory.AccountDefaults';
    private static final String ASSETDEFAULTS  				= 'NSP_TestDataFactory.AssetDefaults';
    private static final String CASEDEFAULTS  				= 'NSP_TestDataFactory.CaseDefaults';  
    private static final string CONTACTDEFAULTS 			= 'NSP_TestDataFactory.ContactDefaultsLight';
    private static final string CATEGORYSUBCATEGORYDEFAULTS = 'NSP_TestDataFactory.CatSubCatMappingDefaults';
    
    private Static final Id WOAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE); 
    
    // Preparing the test data
    @testSetUp
    private static void PrepareTestData()
    {
        // Create Account
        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), ACCOUNTDEFAULTS, true);
        
        Assert.isTrue(newAccount <> null);
        
        // Create Asset
        Asset woAssetRecord 						= (Asset)NSP_TestDataFactory.createSObject(new Asset(), ASSETDEFAULTS, false);
        woAssetRecord.AccountId 					= newAccount.Id;
        woAssetRecord.NSP_Account_Status__c 		= NSP_ServiceConstants.AIMS_STATUS;
        woAssetRecord.RecordTypeId 					= WOAssetRecordTypeId;
        woAssetRecord.NSP_Client_Segment_type__c 	= NSP_ServiceConstants.CoreAssetSegment;
        
        Database.insert(woAssetRecord, false); 
        
        // ASSERTS
        Assert.isTrue(woAssetRecord <> null);
        Assert.isNotNull(woAssetRecord.AccountId);
        Assert.areEqual(woAssetRecord.RecordTypeId, WOAssetRecordTypeId, 'Record type should be WO Asset');
        
        // Create new contact
        Contact newContact 				= (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), CONTACTDEFAULTS, false);
        newContact.Account 				= newAccount;
        newContact.NSP_Work_email__c 	= 'test123@efg.com';
        
        insert newContact;
        
        // ASSERTS
        Assert.isTrue(newContact <> null);
        Assert.isNotNull(newContact.Account);
        Assert.areEqual(newContact.NSP_Work_email__c, 'test123@efg.com', 'The email should be test email');
        
        // Create Category sub-category mapping
        NSP_Category_Sub_Category_Mapping__c newCat = (NSP_Category_Sub_Category_Mapping__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Category_Sub_Category_Mapping__c(), CATEGORYSUBCATEGORYDEFAULTS, false);
        newCat.NSP_UserTitle__c 					= 'Benefits Manager';
        newCat.NSP_Category__c 						= NSP_ServiceConstants.CATEGORY_ADAPTION;
        newCat.NSP_Subcategory__c 					= NSP_ServiceConstants.SUB_CATEGORY_CLAIM;
        newCat.NSP_Detail__c 						= 'Login';
        newCat.NSP_isActive__c						= True;
        newCat.NSP_Asset_Record_Types__c			= 'WO';
        newCat.NSP_RecordType__c					= 'PEO';
        newCat.NSP_Public_Groups_To_Share__c 		= 'All Data Visibility'; 
        
        Database.insert(newCat);
        
        // ASSERTS
        Assert.isTrue(newCat <> null);
        Assert.isNotNull(newCat.NSP_Category__c);
        Assert.areEqual(newCat.NSP_Subcategory__c, NSP_ServiceConstants.SUB_CATEGORY_CLAIM, 'Sub Category should be populated');
        Assert.areNotEqual(newCat.NSP_Detail__c, '', 'Detail value is expected');
        
        // Creating case
        Case caseRecord 				= (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        caseRecord.NSP_Category__c 		= NSP_ServiceConstants.CATEGORY_ADAPTION;
        caseRecord.NSP_SubCategory__c 	= NSP_ServiceConstants.SUB_CATEGORY_CLAIM;
        caseRecord.NSP_Detail__c		= newCat.NSP_Detail__c;
        caseRecord.Subject 				= 'Test Report Dev Notifications';
        caseRecord.AccountId 			= newAccount.Id;
        caseRecord.ContactId			= newContact.Id;
        
        Database.insert(caseRecord, false);
        
        // ASSERTS
        Assert.isTrue(caseRecord <> null);
        Assert.isNotNull(caseRecord.AccountId);
        Assert.isNotNull(caseRecord.ContactId);
        Assert.areEqual(caseRecord.NSP_Category__c, NSP_ServiceConstants.CATEGORY_ADAPTION, 'Category is needed to create a case');
        Assert.areNotEqual(caseRecord.NSP_SubCategory__c, '', 'Sub Category is needed to create a case');
        
    }
    
    @isTest static void Test_Record_Id(){
        String resultId;
        
        Account account = [SELECT ID FROM Account LIMIT 1];
        Asset asset = [SELECT ID FROM Asset LIMIT 1];
        Case cse = [SELECT ID FROM Case LIMIT 1];
        List<String> recIds = new List<String>{account.Id,asset.Id,cse.Id};
            for(String recId: recIds){
                resultId = Validate_Account_Id(recId);
                
                // ASSERTS
                Assert.isTrue(resultId <> null);
                Assert.areEqual(resultId,account.Id,'The expected parameter should be account Id');               
            }
        
    }
    
    // Validating the Service Exceptions Logic
    @istest static void Test_ServiceExceptions_For_Account()
    {
        Account newAccount = [SELECT ID FROM Account LIMIT 1];
        
        NSP_Service_Exception__c serviceException 	= new NSP_Service_Exception__c();
        serviceException.NSP_Account__c				= newAccount.Id;
        serviceException.NSP_Exception_Notes__c		= 'test';
        serviceException.NSP_Start_Date__c			= system.today()-1; 
        serviceException.NSP_End_Date__c			= Date.today();
        
        insert serviceException;
        
        // ASSERTS
        Assert.isTrue(serviceException <> null);
        Assert.areNotEqual(serviceException.NSP_Account__c, null, 'Account should be linked to Service Exception to perform the test case');
        Assert.areEqual(serviceException.NSP_End_Date__c, Date.today(), 'End date is required to do the logic');
        
        Test.startTest();    
        List<NSP_VisualIndicatorHelper.VisualIndicatorWrapper> wrapper = NSP_VisualIndicatorHelper.gethisAccount(newAccount.Id);
        Test.stopTest();
    }
    
    // Validating the Survey logic
    @isTest static void Test_Account_Survey_Logic()
    {
        Account newAccount 						= [SELECT ID FROM Account LIMIT 1];
        
        Id vocSruveyRecordTypeId 				= Schema.SObjectType.NSP_Survey__c.getRecordTypeInfosByDeveloperName().get('VOC').getRecordTypeId();
        
        NSP_Survey__c accountSurvey 			= new NSP_Survey__c();
        accountSurvey.Account__c 				= newAccount.Id;
        accountSurvey.Survey_Name__c 			= 'Test Survey';
        accountSurvey.Survey_End_Date__c 		= Date.Today();
        accountSurvey.Survey_Start_Date__c 		= Date.today() -1;
        accountSurvey.RecordTypeId 				= vocSruveyRecordTypeId;
        
        Database.insert(accountSurvey, false);
        
        // ASSERTS
        Assert.isTrue(accountSurvey <> null);
        Assert.areEqual(accountSurvey.RecordTypeId, vocSruveyRecordTypeId, 'Record type should be VOC');
        Assert.areNotEqual(accountSurvey.Account__c, null, 'Account should be linked to perform this test case');
        
        Test.startTest();
        List<NSP_VisualIndicatorHelper.VisualIndicatorWrapper> wrapper = NSP_VisualIndicatorHelper.gethisAccount(newAccount.Id);
        Test.stopTest();
    }
    
    // Validate the paperless value in Asset that is linked to Account
    @isTest static void Test_Paperless_Asset()
    {
        Account newAccount 	= [SELECT ID FROM Account LIMIT 1];
        Asset asset 		= [SELECT ID, AccountId, NSP_Paperless__c, RecordTypeId FROM Asset LIMIT 1];
        
        asset.NSP_Paperless__c = NSP_ServiceConstants.VALUE_TRUE;
        update asset;
        
        // ASSERTS
        Assert.areNotEqual(asset.AccountId, null, 'Account should be linked to Asset');
        Assert.areEqual(asset.NSP_Paperless__c, NSP_ServiceConstants.VALUE_TRUE, 'The NSP_Paperless__c value should be true to pass the test case');
        
        Test.startTest();
        List<NSP_VisualIndicatorHelper.VisualIndicatorWrapper> wrapper = NSP_VisualIndicatorHelper.gethisAccount(newAccount.Id);
        Test.stopTest();
        
        // ASSERTS
        Assert.isNotNull(wrapper);
        Assert.areEqual(wrapper[0].assetPaperlessPresent, NSP_ServiceConstants.VALUE_TRUE, 'Output value should be true');
        
    }
    
    // Validate the Natioal account value in Asset
    @isTest static void Test_National_Account_Asset()
    {
        Account newAccount 	= [SELECT ID FROM Account LIMIT 1];
        Asset asset 		= [SELECT ID, AccountId, NSP_National_Account__c, RecordTypeId FROM Asset LIMIT 1];
        
        asset.NSP_National_Account__c =  NSP_ServiceConstants.VALUE_TRUE;
        update asset;
        
        // ASSERTS
        Assert.areNotEqual(asset.AccountId, null, 'Account should be linked to Asset');
        Assert.areEqual(asset.NSP_National_Account__c, NSP_ServiceConstants.VALUE_TRUE, 'The NSP_National_Account__c value should be true to pass the test case');
        
        Test.startTest();
        List<NSP_VisualIndicatorHelper.VisualIndicatorWrapper> wrapper = NSP_VisualIndicatorHelper.gethisAccount(newAccount.Id);
        Test.stopTest();
        
        // ASSERTS
        Assert.isNotNull(wrapper);
        Assert.areEqual(wrapper[0].assetNationalAccount, NSP_ServiceConstants.VALUE_TRUE, 'Output value should be true');
        
    }
    
    // Validate the Service Package in Asset
    @isTest static void Test_Service_Package_Value_In_Asset()
    {
        Account newAccount 	= [SELECT ID FROM Account LIMIT 1];
        Asset asset 		= [SELECT ID, AccountId, NSP_Service_Package__c, RecordTypeId FROM Asset LIMIT 1];
        
        asset.NSP_Service_Package__c = 'WS - Bundle Plus';
        update asset;
        
        // ASSERTS
        Assert.areNotEqual(asset.AccountId, null, 'Account should be linked to Asset');
        Assert.areEqual(asset.NSP_Service_Package__c, 'WS - Bundle Plus', 'The NSP_Service_Package__c value should starts with WS to pass the test case');
        
        Test.startTest();
        List<NSP_VisualIndicatorHelper.VisualIndicatorWrapper> wrapper = NSP_VisualIndicatorHelper.gethisAccount(newAccount.Id);
        Test.stopTest();
        
        // ASSERTS
        Assert.isNotNull(wrapper);
        Assert.areEqual(wrapper[0].workSyncClientTrue, NSP_ServiceConstants.VALUE_TRUE , 'Output value should starts with WS');
    }
    
    // Validating the client value in Asset
    @isTest static void Test_Client_Retained_Workers_In_Asset()
    {
        Account newAccount 	= [SELECT ID FROM Account LIMIT 1];
        Asset asset 		= [SELECT ID, AccountId, NSP_Client_Retained_Workers_Comp__c, RecordTypeId FROM Asset LIMIT 1];
        
        asset.NSP_Client_Retained_Workers_Comp__c = '100% Client';
        update asset;
        
        // ASSERTS
        Assert.areNotEqual(asset.AccountId, null, 'Account should be linked to Asset');
        Assert.areEqual(asset.NSP_Client_Retained_Workers_Comp__c, '100% Client', 'The NSP_Client_Retained_Workers_Comp__c value should equal to 100% Client to pass the test case');
        
        Test.startTest();
        List<NSP_VisualIndicatorHelper.VisualIndicatorWrapper> wrapper = NSP_VisualIndicatorHelper.gethisAccount(newAccount.Id);
        Test.stopTest();
        
        // ASSERTS
        Assert.isNotNull(wrapper);
        Assert.areEqual(wrapper[0].client100True, NSP_ServiceConstants.VALUE_TRUE, 'Output value should equals to true');
    }
    
    // Validating the client and inserity value in Asset
    @isTest static void Test_Insperity_Client_Retained_Workers_In_Asset()
    {
        Account newAccount 	= [SELECT ID FROM Account LIMIT 1];
        Asset asset 		= [SELECT ID, AccountId, NSP_Client_Retained_Workers_Comp__c, RecordTypeId FROM Asset LIMIT 1];
        
        asset.NSP_Client_Retained_Workers_Comp__c = 'Client & Insperity';
        update asset;
        
        // ASSERTS
        Assert.areNotEqual(asset.AccountId, null, 'Account should be linked to Asset');
        Assert.areEqual(asset.NSP_Client_Retained_Workers_Comp__c, 'Client & Insperity', 'The NSP_Client_Retained_Workers_Comp__c value should equal to Client & Insperity to pass the test case');
        
        Test.startTest();
        List<NSP_VisualIndicatorHelper.VisualIndicatorWrapper> wrapper = NSP_VisualIndicatorHelper.gethisAccount(newAccount.Id);
        Test.stopTest();
        
        // ASSERTS
        Assert.isNotNull(wrapper);
        Assert.areEqual(wrapper[0].clientAndInsperity, NSP_ServiceConstants.VALUE_TRUE, 'Output value should equals to true');
    }
    
    // Validatin the Termination value in Asset
    @isTest static void Test_Pending_Termination_In_Asset()
    {
        Account newAccount 	= [SELECT ID FROM Account LIMIT 1];
        Asset asset 		= [SELECT ID, AccountId, NSP_Pending_Termination__c, RecordTypeId FROM Asset LIMIT 1];
        
        asset.NSP_Pending_Termination__c =  NSP_ServiceConstants.VALUE_TRUE;
        update asset;
        
        // ASSERTS
        Assert.areNotEqual(asset.AccountId, null, 'Account should be linked to Asset');
        Assert.areEqual(asset.NSP_Pending_Termination__c, NSP_ServiceConstants.VALUE_TRUE, 'The NSP_Pending_Termination__c value should be true to pass the test case');
        
        Test.startTest();
        List<NSP_VisualIndicatorHelper.VisualIndicatorWrapper> wrapper = NSP_VisualIndicatorHelper.gethisAccount(newAccount.Id);
        Test.stopTest();
        
        // ASSERTS
        Assert.isNotNull(wrapper);
        Assert.areEqual(wrapper[0].pendingTermination, NSP_ServiceConstants.VALUE_TRUE, 'Output value should be true');
    }
    private static String Validate_Account_Id(String recId){
        return NSP_VisualIndicatorHelper.getAccountId(recId);        
    }
}