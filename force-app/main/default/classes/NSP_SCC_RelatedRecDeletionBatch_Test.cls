@isTest(seeAllData=false)
public class NSP_SCC_RelatedRecDeletionBatch_Test {
    @testSetup
    public static void createTestData() {
        // Create Account 
        Account acc = new Account();
        acc.Name = 'Test Acc';
        insert acc;
        
        // Create Contact 
        Contact con = new Contact();
        con.AccountId = acc.Id ;
        con.LastName = 'Test con';
        insert con;
        
        // Create Asset
        Asset asset = new Asset();
        asset.Name = 'Test Asset' ;
        asset.ContactId = con.Id ;
        asset.AccountId = acc.Id ;
        insert asset;
        
        // Create Sub Client 
        NSP_Sub_Client__c subClient = new NSP_Sub_Client__c();
        subClient.NSP_Account__c = acc.Id;
        subClient.NSP_Asset__c = asset.Id ;
        subClient.Name = 'Test Sub Client';
        insert subClient ;
        
        // Create Sub Client Contact
        NSP_Sub_Client_Contact__c subClientCon = new NSP_Sub_Client_Contact__c();
        subClientCon.NSP_Contact__c = con.Id;
        subClientCon.NSP_Sub_Client__c = subClient.Id;
        subClientCon.NSP_Employee_Status__c = 'PRIMED';
        subClientCon.NSP_Status_Date__c = system.today() - 121;
        insert subClientCon ;
        
        // Create Address
        NSP_Address__c address = new NSP_Address__c();
        address.Name = 'Test Add';
        address.NSP_Related_Site__c = acc.Id;
        address.NSP_Label_Code__c = 'TesH';
        address.NSP_Legal_Name__c = 'Billing';
        address.NSP_Street__c = 'Test Address AZ';
        address.NSP_Country__c = 'United States';
        address.NSP_State__c = 'AZ';
        address.NSP_Postal_Code__c = '12345';
        address.NSP_Source__c = 'AIMS';
        address.NSP_Address_Type__c = 'Worksite';
        insert address;
    }
    
    Public Static TestMethod Void testNSPSubClientConRelatedRecDeletionBatchCase1(){
        //Account acc =[Select Id From Account WHERE NAME != NULL];
        
        Contact con =[Select Id, AccountId From Contact WHERE AccountId != NULL];
        
        Account acc1 = new Account ();
        acc1.Name = 'Test2Account';
        insert acc1;
        
        AccountContactRelation acr = new AccountContactRelation(AccountId = acc1.id, ContactId = con.id);
        insert acr;
        NSP_Sub_Client__c subClient = [Select Id, NSP_Account__c,NSP_Asset__c ,Name from NSP_Sub_Client__c WHERE NSP_Account__c !=null];
        NSP_Sub_Client_Contact__c subClientContact = [SELECT Id, NSP_Status_Date__c, NSP_Employee_Status__c, NSP_Contact__c FROM NSP_Sub_Client_Contact__c 
                                                      WHERE NSP_Contact__c != Null ];
        
        NSP_Sub_Client_Contact__c subClientCon2 = new NSP_Sub_Client_Contact__c();
        subClientCon2.NSP_Contact__c = con.Id;
        subClientCon2.NSP_Sub_Client__c = subClient.Id;
        subClientCon2.NSP_Status_Date__c = system.today() - 121;
        insert subClientCon2 ;
        
        
        NSP_Address__c address = [Select Id ,NSP_Related_Site__c FROM NSP_Address__c WHERE NSP_Related_Site__c != Null ];
        // Create Sub Client Contact Address
        // 
        NSP_Sub_Client_Contact_Address__c subClientConAdd = New NSP_Sub_Client_Contact_Address__c();
        subClientConAdd.Name = 'Test'; 
        subClientConAdd.NSP_Address__c = address.Id;
        subClientConAdd.NSP_Sub_Client_Contact__c = subClientContact.Id;
        insert subClientConAdd ;
        
        Test.StartTest();
        // here call the batch NSP_SubClientConRelatedRecDeletionBatch
        NSP_SubClientConRelatedRecDeletionBatch subClientCont = new NSP_SubClientConRelatedRecDeletionBatch();
        DataBase.executeBatch(subClientCont);
        
        Test.stopTest();
        
        List<NSP_Sub_Client_Contact__c> subClientConList = [SELECT Id, NSP_Status_Date__c, NSP_Employee_Status__c, NSP_Contact__c, NSP_Sub_Client__c FROM NSP_Sub_Client_Contact__c WHERE NSP_Employee_Status__c = 'PRIMED'];
        system.assert(subClientConList.size() == 0);
        
    }
    
    Public Static TestMethod Void testNSPSubClientConRelatedRecDeletionBatchCase2(){
        //Account acc =[Select Id From Account WHERE NAME != NULL];
        
        
        //Contact con =[Select Id, AccountId From Contact WHERE AccountId != NULL];
        //NSP_Sub_Client__c subClient = [Select Id, NSP_Account__c,NSP_Asset__c ,Name from NSP_Sub_Client__c WHERE NSP_Account__c !=null];
        NSP_Sub_Client_Contact__c subClientContact = [SELECT Id, NSP_Status_Date__c, NSP_Employee_Status__c, NSP_Contact__c FROM NSP_Sub_Client_Contact__c 
                                                      WHERE NSP_Contact__c != Null ];
        
        NSP_Address__c address = [Select Id ,NSP_Related_Site__c FROM NSP_Address__c WHERE NSP_Related_Site__c != Null ];
        // Create Sub Client Contact Address
        // 
        NSP_Sub_Client_Contact_Address__c subClientConAdd = New NSP_Sub_Client_Contact_Address__c();
        subClientConAdd.Name = 'Test'; 
        subClientConAdd.NSP_Address__c = address.Id;
        subClientConAdd.NSP_Sub_Client_Contact__c = subClientContact.Id;
        insert subClientConAdd ;
        
        Test.StartTest();
        // here call the batch NSP_SubClientConRelatedRecDeletionBatch
        NSP_SubClientConRelatedRecDeletionBatch subClientCont = new NSP_SubClientConRelatedRecDeletionBatch();
        DataBase.executeBatch(subClientCont);
        
        Test.stopTest();
        
        List<NSP_Sub_Client_Contact__c> subClientConList = [SELECT Id, NSP_Status_Date__c, NSP_Employee_Status__c, NSP_Contact__c, NSP_Sub_Client__c FROM NSP_Sub_Client_Contact__c WHERE Id != Null LIMIT 1];
        system.assert(subClientConList.size() == 0);
    }
    
}