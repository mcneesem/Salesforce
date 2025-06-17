@isTest
public class CaseGuidanceControllerTest 
{
    @testSetup 
    private static void prepareTestData()
    {
        // Create Account
        Account newAccount      = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
        Account assetAccount    = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        assetAccount.Name       = 'Test Asset';
        
        insert assetAccount;

        Assert.isTrue(assetAccount != null);
        
        // Create Category Sub Category Record
        NSP_Category_Sub_Category_Mapping__c newCat = (NSP_Category_Sub_Category_Mapping__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Category_Sub_Category_Mapping__c(), 'NSP_TestDataFactory.CatSubCatMappingDefaults', false);
        newCat.NSP_UserTitle__c                 = 'Benefits Manager';
        newCat.NSP_Category__c                  = NSP_ServiceConstants.CATEGORY_ADAPTION;
        newCat.NSP_Subcategory__c               = NSP_ServiceConstants.SUB_CATEGORY_CLAIM;
        newCat.NSP_Detail__c                    = 'Login';
        newCat.NSP_isActive__c                  = True;
        newCat.NSP_Asset_Record_Types__c        = 'WO';
        newCat.NSP_RecordType__c                = 'PEO';
        newCat.NSP_Public_Groups_To_Share__c    = 'All Data Visibility'; 
        newCat.Case_Guidance__c                 = 'Hello';
        
        Database.insert(newCat);

        Assert.isTrue(newCat != null);
        Assert.isNotNull(newCat.NSP_Category__c);
        Assert.isNotNull(newCat.NSP_Subcategory__c);
        Assert.areNotEqual(newCat.Case_Guidance__c, null);
        
        // Create Case
        Case caseRec                = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        caseRec.NSP_Category__c     = newCat.NSP_Category__c;
        caseRec.NSP_SubCategory__c  = newCat.NSP_Subcategory__c;
        caseRec.NSP_Detail__c       = newCat.NSP_Detail__c;
        caseRec.Subject             = 'Test Asset Mapping';
        caseRec.AccountId           = assetAccount.Id;
        
        Database.insert(caseRec);

        Assert.areNotEqual(caseRec.NSP_Category__c, null);
    }
    
    @isTest
    private static void testCaseRecordWithGuidance()
    {
        Case caseRec = [SELECT ID FROM Case LIMIT 1];
        Test.StartTest();
        string caseGuidance = CaseGuidanceController.getCaseGuidance(caseRec.Id);
        Test.stopTest();
        
        Assert.areEqual(caseGuidance, 'Hello');
    }
    
    @isTest
    private static void testCaseRecordWithoutGuidance()
    {
        NSP_Category_Sub_Category_Mapping__c newCat = [SELECT ID, Case_Guidance__c FROM NSP_Category_Sub_Category_Mapping__c LIMIT 1];
        newCat.Case_Guidance__c = '';
        update newCat;
        
        Case caseRec = [SELECT ID FROM Case LIMIT 1];
        Test.StartTest();
        string caseGuidance = CaseGuidanceController.getCaseGuidance(caseRec.Id);
        Test.stopTest();
        
        Assert.areNotEqual(caseGuidance, 'Hello');
    }
    
    @IsTest
    private static void testGetCaseGuidanceSetting()
    {
        Test.StartTest();
        Case_Guidance_Setting__c caseGuidanceSetting = CaseGuidanceController.getCaseGuidanceSetting();
        Test.stopTest();
        
        Assert.areNotEqual(caseGuidanceSetting, null);
    }
}