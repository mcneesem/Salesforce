@isTest(seeAllData=false)
public class NSP_SCC_RelatedRecDeletionBatch_Test 
{
    @testSetup static void createTestData() 
    {
        // Create Account 
        Account acc = new Account();
        acc.Name    = 'Test Acc';
        insert acc;
        
        // Create Contact 
        Contact con     = new Contact();
        con.AccountId   = acc.Id ;
        con.LastName    = 'Test con';
        insert con;
        
        // Create Asset
        Asset asset     = new Asset();
        asset.Name      = 'Test Asset' ;
        asset.ContactId = con.Id ;
        asset.AccountId = acc.Id ;
        insert asset;
        
        // Create Sub Client 
        NSP_Sub_Client__c subClient = new NSP_Sub_Client__c();
        subClient.NSP_Account__c    = acc.Id;
        subClient.NSP_Asset__c      = asset.Id ;
        subClient.Name              = 'Test Sub Client';
        insert subClient ;
        
        // Create Sub Client Contact
        NSP_Sub_Client_Contact__c subClientCon = new NSP_Sub_Client_Contact__c();
        subClientCon.NSP_Contact__c         = con.Id;
        subClientCon.NSP_Sub_Client__c      = subClient.Id;
        subClientCon.NSP_Employee_Status__c = 'PRIMED';
        subClientCon.NSP_Status_Date__c     = system.today() - 121;
        insert subClientCon ;
        
        // Create Address
        NSP_Address__c address = new NSP_Address__c();
        address.Name                = 'Test Add';
        address.NSP_Related_Site__c = acc.Id;
        address.NSP_Label_Code__c   = 'PTesH';
        address.NSP_Legal_Name__c   = 'Billing';
        address.NSP_Street__c       = 'Test Address AZ';
        address.NSP_Country__c      = 'United States';
        address.NSP_State__c        = 'AZ';
        address.NSP_Postal_Code__c  = '12345';
        address.NSP_Source__c       = 'AIMS';
        address.NSP_Address_Type__c = 'Worksite';
        insert address;
    }
    
    //== Test Method to test the delete scenario
    @isTest static void testSubClientContactDelete()
    {
        Test.StartTest();

        DataBase.executeBatch(new NSP_SubClientConRelatedRecDeletionBatch());
        
        Test.stopTest();
        
        List<NSP_Sub_Client_Contact__c> subClientConList    = [SELECT Id, NSP_Status_Date__c, NSP_Employee_Status__c, NSP_Contact__c, NSP_Sub_Client__c FROM NSP_Sub_Client_Contact__c WHERE NSP_Employee_Status__c = 'PRIMED'];
        List<AccountContactRelation> acrList                = [SELECT ID FROM AccountContactRelation];
        //Asserts
        Assert.areEqual(subClientConList.size(), 0);
    }
    
    //== Test Method for No Delete
    @isTest static void testNoDeleteOfSubClientContactsBaseOnFiles()
    {
        Account account = [SELECT ID FROM Account LIMIT 1];
        Contact contact = [SELECT ID FROM Contact WHERE AccountId = :account.Id LIMIT 1];
        
        /** INSERT DOCUMENTS */

        ContentVersion contentVersion = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        
        insert contentVersion;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId      = contact.id;
        cdl.ContentDocumentId   = documents[0].Id;
        cdl.ShareType           = 'V';
        
        insert cdl;

        Test.StartTest();

        DataBase.executeBatch(new NSP_SubClientConRelatedRecDeletionBatch());
        
        Test.stopTest();
        
        List<NSP_Sub_Client_Contact__c> subClientConList    = [SELECT Id, NSP_Status_Date__c, NSP_Employee_Status__c, NSP_Contact__c, NSP_Sub_Client__c FROM NSP_Sub_Client_Contact__c WHERE NSP_Employee_Status__c = 'PRIMED'];
        List<AccountContactRelation> acrList                = [SELECT ID FROM AccountContactRelation];
        //Asserts
        Assert.areEqual(subClientConList.size(), 1);
        Assert.areEqual(acrList.size(), 1);
    }
    
    //== Test Method for No Delete
    @isTest static void testNoDeleteOfSubClientContactsBasedOnNotes()
    {
        Account account = [SELECT ID FROM Account LIMIT 1];
        Contact contact = [SELECT ID FROM Contact WHERE AccountId = :account.Id LIMIT 1];
        
        // Notes
        NSP_Note__c note = new NSP_Note__c( NSP_Contact__c = contact.Id );
        insert note;
        
        Test.StartTest();

        DataBase.executeBatch(new NSP_SubClientConRelatedRecDeletionBatch());
        
        Test.stopTest();
        
        List<NSP_Sub_Client_Contact__c> subClientConList    = [SELECT Id, NSP_Status_Date__c, NSP_Employee_Status__c, NSP_Contact__c, NSP_Sub_Client__c FROM NSP_Sub_Client_Contact__c WHERE NSP_Employee_Status__c = 'PRIMED'];
        List<AccountContactRelation> acrList                = [SELECT ID FROM AccountContactRelation];
        //Asserts
        Assert.areEqual(subClientConList.size(), 1);
        Assert.areEqual(acrList.size(), 1);
    }
    
    //== Test Method to test the delete with case contacts
    @isTest static void testCaseContacts()
    {
        Account account = [SELECT ID FROM Account LIMIT 1];
        Contact contact = [SELECT ID FROM Contact WHERE AccountId = :account.Id LIMIT 1];
        
        // Create Case
        Case nCorpCase = (Case) NSP_TestExtendedDataFactory.createSObject(new Case(), 
                                                                          'NSP_TestDataFactory.CaseDefaults', 
                                                                          false);
        nCorpCase.contactId 					= contact.Id;
        nCorpCase.AccountId 					= account.Id;
        nCorpCase.NSP_CorporateEmployeeEE__c 	= true;
        
        insert nCorpCase;
        
        Test.StartTest();
        
        // Create Case Contact
        NSP_Case_Contacts__c caseContact 	= (NSP_Case_Contacts__c) NSP_TestExtendedDataFactory.createSObject(new NSP_Case_Contacts__c(), 
                                                                                                              'NSP_TestDataFactory.caseContactDefaults', 
                                                                                                              false);
        caseContact.NSP_Contact__c 			= contact.Id;
        caseContact.NSP_Case__c 			= nCorpCase.Id;
        caseContact.NSP_IsPrimary__c 		= true;
        INSERT caseContact;
        
        
        
        DataBase.executeBatch(new NSP_SubClientConRelatedRecDeletionBatch());
        
        Test.stopTest();
        
        List<NSP_Sub_Client_Contact__c> subClientConList    = [SELECT Id, NSP_Status_Date__c, NSP_Employee_Status__c, NSP_Contact__c, NSP_Sub_Client__c FROM NSP_Sub_Client_Contact__c WHERE NSP_Employee_Status__c = 'PRIMED'];
        //Asserts
        Assert.areEqual(subClientConList.size(), 1);
    }

    //== Test method for scheduler
    @isTest static void testScheduler()
    {
        Test.startTest();
        String cronExp = '0 0 12 * * ?';
        System.schedule('Delete batch', cronExp, new NSP_SubClientConRelatedRecDeletionBatch());
        Test.stopTest();
    }
}