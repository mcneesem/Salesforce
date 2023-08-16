/**
Apex Class Name      :  NSP_AccrualProfileControllerTest
Version              :  1.0
Author               :  
Created Date         :  March 20 2023
Function             :  This class is used as a test class of NSP_AccrualProfileController
Story                :  
*/
@isTest
private class NSP_AccrualProfileControllerTest {
    //test setUp method
    @testSetup 
    static void setUpAllData(){
        
        Account accoutObject = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        accoutObject.Name = 'Test Account';
        accoutObject.NSP_AIMS_Client__c = '52000';
        insert accoutObject;
        
        NSP_Service_Plan__c servicePlan = (NSP_Service_Plan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Service_Plan__c(), 'NSP_TestDataFactory.ServicePlanDefaults', false);
        servicePlan.NSP_Account__c = accoutObject.Id;
        insert servicePlan;
        
        List<ContentVersion> contVersion = new List<ContentVersion>();
        
        ContentVersion newContentVersion = (ContentVersion)NSP_TestExtendedDataFactory.createSObject(new ContentVersion(), 'NSP_TestDataFactory.ContentVersionDefaults', false);
        newContentVersion.NSP_Signature_Date__c = System.today()+1;
        contVersion.add(newContentVersion);
        
        ContentVersion newContentVersion2 = (ContentVersion)NSP_TestExtendedDataFactory.createSObject(new ContentVersion(), 'NSP_TestDataFactory.ContentVersionDefaults', false);
        newContentVersion2.NSP_Signature_Date__c = System.today();
        contVersion.add(newContentVersion2);
        
        insert contVersion;

        
        NSP_Accrual_Profile__c accProfile = (NSP_Accrual_Profile__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Accrual_Profile__c(), 'NSP_TestDataFactory.AccrualProfileDefaults', false);
        accProfile.NSP_Accrual_Profile_Plan_Name__c = 'Test Accrual Profile';
        insert accProfile;
        
        NSP_Accrual_Profile_Account_Relationship__c accProfileAccRelationship = (NSP_Accrual_Profile_Account_Relationship__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Accrual_Profile_Account_Relationship__c(), 'NSP_TestDataFactory.AccrualProfileAccountRelationshipDefaults', false);
		accProfileAccRelationship.NSP_Accrual_Profile__c = accProfile.Id;
        accProfileAccRelationship.NSP_Account__c= accoutObject.Id;
        insert accProfileAccRelationship;
    }
    
    // description : This test method is used to cover NSP_AccrualProfileController.getPlanOptions() method
    @isTest
    static void getPlanOptionsTest (){
        Test.startTest();
        //GIVEN
        Account acc = [SELECT Id,Name FROM Account 
                       WHERE Name = 'Test Account' LIMIT 1];
        List<String> accIds = new List<String>();
        accIds.add(acc.Id);
        try {
            //WHEN
            List<NSP_LookupOption> lstOption = NSP_AccrualProfileController.getPlanOptions(accIds);
            //THEN
            System.assertEquals(lstOption.size(), 1);
        } 
        catch(AuraHandledException ex) {
            System.assertEquals( 'null Input', ex.getMessage());
        }
        Test.stopTest();
    }
    
    // description : This test method is used to cover NSP_AccrualProfileController.linkFilesToRecord() method
    @isTest
    static void linkFilesToRecordTest (){
        Test.startTest();
        //GIVEN
        Account acc = [SELECT Id,Name FROM Account WHERE Name != null LIMIT 1];
        List<ContentDocumentLink> docLink = [SELECT contentdocumentid, LinkedEntityId  FROM ContentDocumentLink WHERE LinkedEntityId =: acc.Id LIMIT 2];
        System.assertNotEquals(docLink.size(), 2);
        
        List<ContentVersion> contVersion =[SELECT Id, contentdocumentid FROM contentversion WHERE Id != null LIMIT 2];
        //st<String> contentdocid = contVersion.contentdocumentid;
        List<contentversion> contentdocid = [SELECT Id, contentdocumentid FROM contentversion WHERE Id IN: contVersion LIMIT 2];
        List<String> contntDoc = new List<String>();
        contntDoc.add(contentdocid[0].contentdocumentid);
        contntDoc.add(contentdocid[1].contentdocumentid);
        try {
            //WHEN 
            NSP_AccrualProfileController.linkFilesToRecord(String.valueOf(acc.Id), contntDoc);
            
            //THEN
            List<ContentDocumentLink> contDocLink = [SELECT contentdocumentid, LinkedEntityId  FROM ContentDocumentLink WHERE contentdocumentid IN: contntDoc];
            System.assertEquals(4, contDocLink.size());
        } 
        catch(AuraHandledException ex) {
            System.assertEquals( 'null Input', ex.getMessage());
        }
        Test.stopTest();
    }
    
    // description : This test method is used to cover NSP_AccrualProfileController.linkFilesToRecord(accId, null) method
    @isTest
    static void negativeTestLinkFilesToRecord (){
        
        //GIVEN
        Account acc = [SELECT Id,Name FROM Account WHERE Name != null LIMIT 1];
        List<String> contentDocIds = new List<String>();
        contentDocIds.add('abc');
        contentDocIds.add('xyz');
        try {
            //WHEN 
            NSP_AccrualProfileController.linkFilesToRecord(String.valueOf(acc.Id), contentDocIds);
        } 
        catch(AuraHandledException ex) {
            System.assertEquals( 'Invalid id: abc', ex.getMessage());
        }
    }
    
    // description : This test method is used to cover NSP_AccrualProfileController.setrecId,NSP_AccrualProfileController.setrecId,NSP_AccrualProfileController.accrualProfilePlanName and NSP_AccrualProfileController.accrualProfileAccountNames 
    @isTest
    static void accrualProfilePlanName (){ 
        
        //GIVEN
        NSP_Accrual_Profile__c accProfile = [SELECT Id,Name FROM NSP_Accrual_Profile__c WHERE Id != null LIMIT 1];
        String recId = accProfile.Id;
        //WHEN
        NSP_AccrualProfileController.setrecId(recId);
        String accProfilePlanName = NSP_AccrualProfileController.accrualProfilePlanName;
        String accProfileAccountNames = NSP_AccrualProfileController.accrualProfileAccountNames;
        //THEN
        System.assertEquals(accProfilePlanName , 'Test Accrual Profile');
        System.assertEquals(recId , NSP_AccrualProfileController.getrecId());
    }
}