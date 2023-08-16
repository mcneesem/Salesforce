/**
 * @description       : 
 * @author            : Anil
 * @group             : 
 * @last modified on  : 02-09-2023
 * @last modified by  : Anil
**/
@isTest
private class NSP_AccountGroupSelector_Test {
    /**
    * Setup test data for Accounts, Groups and Group members.
    * @param N/A. 
    * @return void                          
    */
    @testSetup
    static void testData() {
        Test.startTest();
        Account accoutObject = (Account) NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        accoutObject.Name = 'account';
        accoutObject.Phone = '11223344';
        accoutObject.NSP_AIMS_Client__c = '11223344';
        insert accoutObject; 
        
        Id manuallyCreatedRecordTypeId = NSP_GenericRecordType.getRecordTypeId('NSP_Account_Group__c','Automatically_Created');
        
        NSP_Account_Group__c accountGroupRec = (NSP_Account_Group__c) NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group__c(), 'NSP_TestDataFactory.AccountGroupDefaults', false);
        accountGroupRec.Name = 'Account Health - Test Grp 1';
        accountGroupRec.NSP_Tag__c = 'Test Grp 1';
        accountGroupRec.NSP_Type__c = 'Account Health';
        accountGroupRec.RecordTypeId = manuallyCreatedRecordTypeId;
        insert accountGroupRec;
        
        NSP_Account_Group_Member__c accGrpMem1 = (NSP_Account_Group_Member__c) NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group_Member__c(), 'NSP_TestDataFactory.AccountGroupMemberDefaults', false);
        accGrpMem1.NSP_Member_Account__c = accoutObject.Id;
        accGrpMem1.NSP_Group__c = accountGroupRec.Id;
        insert accGrpMem1;
        Test.stopTest();
    }

    /**
    * @description Test Account Groups if there are records
    * @author Anil | 02-09-2023 
    **/
    @isTest static void getAccountGroups() {
        Test.startTest();
        String searchConfig = '{"groupType":"Account Health","account":"","aimsClient":""}';
        List<NSP_Account_Group_Member__c> lstGrpMbrs = NSP_AccountGroupSelector.searchRecordsByFilters(searchConfig);
        System.assertEquals(lstGrpMbrs.size(), 1, 'Success');
        Test.stopTest();
    }
    
    /**
    * @description test Account Groups if there are no Records
    * @author Anil | 02-09-2023 
    **/
    @isTest static void getAccountGroupsNoRecords() {
        Test.startTest();
        try{
            List<NSP_Account_Group_Member__c> lstGrpMbrs = NSP_AccountGroupSelector.searchRecordsByFilters(null);
            System.assert(false, 'Should throw exception');
        }catch(AuraHandledException ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_AccountGroupSelector_Test','getAccountGroupsNoRecords',ex.getMessage());
        }
        Test.stopTest();
    }
    
}