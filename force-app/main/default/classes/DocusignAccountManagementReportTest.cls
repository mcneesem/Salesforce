@isTest
private class DocusignAccountManagementReportTest {

    @TestSetup
    private static void setUpData(){
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        oAccount.Name = 'Test Account';
        insert oAccount;
        
        Id autoCreatedRecordTypeId = Schema.SObjectType.NSP_Account_Group__c.getRecordTypeInfosByName().get('Automatically Created').getRecordTypeId();
        NSP_Account_Group__c accountGroupRec = (NSP_Account_Group__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group__c(), 'NSP_TestDataFactory.AccountGroupDefaults', false);
        accountGroupRec.Name = 'Account Health - Test Grp 1';
        accountGroupRec.NSP_Tag__c = 'Test Grp 1';
        accountGroupRec.NSP_Type__c = 'Renewal Probability';
        accountGroupRec.NSP_Account__c = oAccount.name;
        accountGroupRec.RecordTypeId = autoCreatedRecordTypeId;
        INSERT accountGroupRec;
        
        NSP_Account_Group_Member__c accGrpMem = (NSP_Account_Group_Member__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group_Member__c(), 'NSP_TestDataFactory.AccountGroupMemberDefaults', false);
        accGrpMem.NSP_Member_Account__c = oAccount.Id;
        accGrpMem.NSP_Group__c = accountGroupRec.Id;
        accGrpMem.NSP_Primary__c = TRUE;
        INSERT accGrpMem;
        
        NSP_Docusign_Account_Details__c customSetting = new NSP_Docusign_Account_Details__c();
        customSetting.Docusign_Account_Id__c = '50202';
        customSetting.CLM_Base_URL__c = 'uatna11.springcm.com';
        insert customSetting;
    }
    @IsTest 
    private static void getPrimaryAccountTest() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Map<Id, String> accountMap = DocusignAccountManagementReport.getPrimaryAccount(acc.Id);
        System.assertNotEquals(null, accountMap);
        Test.stopTest();
    }
    
    @IsTest 
    private static void getDocusignURLTest() {
        Test.startTest();
        NSP_Docusign_Account_Details__c  result = DocusignAccountManagementReport.getDocusignURL();
        System.assertEquals('50202', result.Docusign_Account_Id__c);
        Test.stopTest();
    }
}