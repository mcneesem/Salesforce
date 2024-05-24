@isTest(SeeAllData=false)
public class NSP_AddressTriggerHelper_Test {
    private static final List<String> profileFields = new List<String>{'Id', 'Name'};
    private static final Profile integrationProfile =  Database.query(new NSP_QueryBuilder('Profile', profileFields).addFilter('Name', NSP_ServiceConstants.INTEGRATION_USER).addLimit(1).setSecurityEnforce(false).build());
    
    @testSetup
    public static void testData() { 
        
        // Create Accountrecord
        Account acc = new Account();
        acc.Name = 'Test Acc';
        insert acc;
        
        Account acc1 = new Account();
        acc1.Name = 'Test Acc1';
        insert acc1;
       
        
        // Create Contact record
        Contact con = new Contact();
        con.AccountId = acc.Id ;
        con.LastName = 'Test con';
        insert con;
        
        // Create Asset record 
        Asset asset = new Asset();
        asset.Name = 'Test Asset' ;
        asset.ContactId = con.Id ;
        asset.AccountId = acc.Id ;
        insert asset;
        
        // Create Sub Client record
        NSP_Sub_Client__c subClient = new NSP_Sub_Client__c();
        subClient.NSP_Account__c = acc.Id;
        subClient.NSP_Asset__c = asset.Id ;
        subClient.Name = 'Test Sub Client';
        insert subClient ;
        
        // Create Sub Client Contact record
        NSP_Sub_Client_Contact__c subClientCon = new NSP_Sub_Client_Contact__c();
        subClientCon.NSP_Sub_Client__c = subClient.Id;
        insert subClientCon;
        
        // Create Address record With Label Code EndWith 'H'
        NSP_Address__c addressObject = new NSP_Address__c();
        addressObject.NSP_Legal_Name__c  = 'Test';
        addressObject.NSP_State__c = 'Up';
        addressObject.NSP_Label_Code__c = '23456-123456H';
        addressObject.NSP_Postal_Code__c = '45678';
        addressObject.NSP_Source__c = NSP_ServiceConstants.SOURCE;
        addressObject.NSP_Address_Type__c = NSP_ServiceConstants.US_MAIL;
        insert addressObject;
        
        // Create Address record Without Label Code EndWith 'H'
        NSP_Address__c addressObject1 = new NSP_Address__c();
        addressObject1.NSP_Legal_Name__c  = 'Test';
        addressObject1.NSP_State__c = 'Up';
        addressObject1.NSP_Label_Code__c = '23456-123456W';
        addressObject1.NSP_Postal_Code__c = '45678'; 
        insert addressObject1;
        
        addressObject1.NSP_Postal_Code__c = '456789'; 
        update addressObject1;
        
        // Create Address record Without Label Code EndWith 'H'
        NSP_Address__c addressObject2 = new NSP_Address__c();
        addressObject2.NSP_Legal_Name__c  = 'Test';
        addressObject2.NSP_State__c = 'Up';
        addressObject2.NSP_Label_Code__c = '23456-123456';
        addressObject2.NSP_Postal_Code__c = '45678'; 
        insert addressObject2;
        delete addressObject2;
        
        // Create Sub Client Contact Address record
        NSP_Sub_Client_Contact_Address__c subClientConAdd = New NSP_Sub_Client_Contact_Address__c();
        subClientConAdd.Name = 'Test';
        subClientConAdd.NSP_Label_Code__c = '23456-123456';
        subClientConAdd.NSP_Address__c = addressObject.Id;
        subClientConAdd.NSP_Sub_Client_Contact__c = subClientCon.Id;
        insert subClientConAdd ;
        
    }
    
    public static testmethod void testDeleteAddressRelatedRecords() {
        List<NSP_Address__c> address =[select Id, NSP_Label_Code__c From NSP_Address__c];
        System.assert(address.size() == 2);
    }
    
    static testmethod void testUpdateSCCAddressWithStreet() {
        
        User integrationUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        integrationUser.ProfileId = integrationProfile.Id;
        insert integrationUser;
        COntact con = [SELECT Id FROM Contact LIMIT 1];
        System.runAs(integrationUser) {
            NSP_Sub_Client_Contact_Address__c sccAddress = [select Id From NSP_Sub_Client_Contact_Address__c LIMIT 1];
            NSP_Address__c oldAddress = new NSP_Address__c(NSP_Street__c = 'Old Street', NSP_Contact__c = con.Id, NSP_Address_Type__c = 'U.S. Mail', NSP_Source__c = 'AIMS');
            insert oldAddress;
            //Update SCC Address
            sccAddress.NSP_Address__c = oldAddress.Id;
            update sccAddress;
            Test.startTest();
            
            oldAddress.NSP_Street__c = 'Test Street';
            Update oldAddress;
            Test.stopTest();
            NSP_Sub_Client_Contact_Address__c sccAddress1 = [select Id, Name From NSP_Sub_Client_Contact_Address__c LIMIT 1];
            system.assertEquals('Test Street',sccAddress1.Name);   
        }
        
    }
    
   @isTest
   public static void updateContact() {
      Test.startTest();
       Account acc = new Account();
       acc.Name = 'Test Acc2';
       insert acc;	
       NSP_Address__c addr = [SELECT Id, NSP_Related_Site__c FROM NSP_Address__c Where NSP_Address_Type__c =: NSP_ServiceConstants.US_MAIL LIMIT 1];
       addr.NSP_Related_Site__c = acc.Id;
       update addr;
      Test.stopTest();
      System.assertEquals(1,[SELECT count() FROM NSP_Address__c WHERE NSP_Related_Site__c =: acc.Id]);
    }
    
}