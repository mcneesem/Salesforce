/**
Apex Class Name      :  NSP_SubClientContactAddressHelperTest
Version              :  1.0 
Author               :  Virendra Kumar                                                                          
Created Date         :  10/20/22 
Function             :  Represents test class for NSP_SubClientContactAddressTriggerHelper && NSP_SubCCAddressTriggerHandler class
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Virendra                  10/20/2022                First Iteration
*/

@isTest
public class NSP_SubClientContactAddressHelperTest {
    private static final string TEST1 = 'test';

    // Create test data
    @TestSetup
    Public Static Void createTestData() {
        
        Profile profileRec = [SELECT Id FROM Profile WHERE Name='Integration User']; 
        
        User usr = New User(Alias = 'standt', Email='standarduser@insperity.com', 
                            EmailEncodingKey='UTF-8', LastName='Testing 1', LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', ProfileId = profileRec.Id, 
                            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testing123.com');
        Insert usr ;
        
        
        NSP_Address__c address = New NSP_Address__c();
        address.Name = TEST1 ;
        address.NSP_Street__c = 'Test Street';
        address.NSP_Label_Code__c = 'TesT';
        Insert address;
        
        Account acc = New Account();
        acc.Name = TEST1;
        Insert acc;
        
        Contact con = New Contact();
        con.NSP_Do_Not_Contact__c = true;
        con.LastName = 'Test Con';
        con.AccountId = acc.Id;
        Insert con;
        
        NSP_Sub_Client_Contact__c subclientcon = new NSP_Sub_Client_Contact__c();
        subclientcon.NSP_WC_Contact__c = True;
        subclientcon.NSP_Contact__c = con.Id;
        Insert subclientcon;
        
        NSP_Sub_Client_Contact_Address__c subClientContactAddress = New NSP_Sub_Client_Contact_Address__c();
        subClientContactAddress.Name = TEST1;
        subClientContactAddress.NSP_Address__c = address.Id;
        subClientContactAddress.OwnerId = usr.Id;
        Insert subClientContactAddress;
        
        NSP_Sub_Client_Contact_Address__c subClientContactAddress2 = New NSP_Sub_Client_Contact_Address__c();
        subClientContactAddress2.Name = TEST1;
        subClientContactAddress2.NSP_Contact__c = subclientcon.NSP_Contact__c;
        Insert subClientContactAddress2;
        
    }
    
    // Test method for updateNameByStreetAddress
    Public Static TestMethod Void testUpdateNameByStreetAddress() {        
        Test.StartTest();
        
        NSP_Sub_Client_Contact_Address__c subClientContactAddress =[SELECT Id, NSP_Address__r.NSP_Street__c, NSP_Label_Code__c, Name 
                                                                    FROM NSP_Sub_Client_Contact_Address__c WHERE Name = 'Test' LIMIT 1];
        
        User usr = [
            SELECT Id , Name
            FROM User
            WHERE (
                ( Profile.Name = 'Integration User' )
                AND ( IsActive = true )
            )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        System.runAs(usr) {
            subClientContactAddress.Name = 'Test 1';
            update subClientContactAddress;
        }
        Test.stopTest();
        NSP_Sub_Client_Contact_Address__c subClientContactAddressUpdate = [SELECT Id, NSP_Address__r.NSP_Street__c, NSP_Label_Code__c, Name 
                                                                           FROM NSP_Sub_Client_Contact_Address__c WHERE Name = 'Test Street' LIMIT 1];
        System.Assert(subClientContactAddressUpdate.Name == subClientContactAddressUpdate.NSP_Address__r.NSP_Street__c);
    }
    
}