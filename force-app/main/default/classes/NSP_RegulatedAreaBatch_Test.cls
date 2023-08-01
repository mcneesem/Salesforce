/***Test Class for Schedulable Apex Class***
/*** @description  : Test Class for Scheduler Class to schedule NSP_AccountRegulatedbatch
* @author Bindushree R
* @date 09/03/2021
* Name : NSP_RegulatedAreaBatch_Test
*/

@isTest(SeeAllData=false)

public class NSP_RegulatedAreaBatch_Test {
    
    @testSetup
    static void testData() {
        Id recordTypeWoAsset =  NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE);        
        //inserting Regulated Area
        List<NSP_Regulated_Area__c> lstRegulatedArea = new List<NSP_Regulated_Area__c>();
        NSP_Regulated_Area__c regArea1 = (NSP_Regulated_Area__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Regulated_Area__c(), 'NSP_TestDataFactory.RegulatedAreaDefaults', false);
        regArea1.NSP_Start_Date__c = System.today();
        regArea1.NSP_State__c = 'NY';
        regArea1.NSP_City__c = null;
        regArea1.NSP_Zip_Code__c = null;
        regArea1.NSP_Regulation_Type__c = 'Sick Leave';
        lstRegulatedArea.add(regArea1);

        NSP_Regulated_Area__c regArea2 = (NSP_Regulated_Area__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Regulated_Area__c(), 'NSP_TestDataFactory.RegulatedAreaDefaults', false);
        regArea2.NSP_Start_Date__c = System.today();
        regArea2.NSP_State__c = 'NJ';
        regArea2.NSP_City__c = null;
        regArea2.NSP_Zip_Code__c = null;
        regArea2.NSP_Regulation_Type__c = 'Sick Leave';
        lstRegulatedArea.add(regArea2);


        NSP_Regulated_Area__c regArea3 = (NSP_Regulated_Area__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Regulated_Area__c(), 'NSP_TestDataFactory.RegulatedAreaDefaults', false);
        regArea3.NSP_Start_Date__c = System.today();
        regArea3.NSP_City__c = 'Chicago';
        regArea3.NSP_Zip_Code__c = '404675';
        regArea3.NSP_State__c = null;
        regArea3.NSP_Regulation_Type__c = 'Sick Leave';
        lstRegulatedArea.add(regArea3);

        NSP_Regulated_Area__c regArea4 = (NSP_Regulated_Area__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Regulated_Area__c(), 'NSP_TestDataFactory.RegulatedAreaDefaults', false);
        regArea4.NSP_Start_Date__c = System.today();
        regArea4.NSP_City__c = 'Chicago';
        regArea4.NSP_Zip_Code__c = '50053';
        regArea4.NSP_State__c = null;
        regArea4.NSP_Regulation_Type__c = 'Sick Leave';
        lstRegulatedArea.add(regArea4);
        insert lstRegulatedArea;
        
        //inserting Account
        Account acct = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acct.Name = 'Regulated Test Account';
        acct.Type = NSP_SalesConstants.CUSTOMER;
        acct.NSP_Account_Status__c = NSP_SalesConstants.ACTIVE; 
        insert acct;
        
        //Inserting Contacts
        Contact con = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        con.MailingCity = 'Chicago';
        //con.MailingState = 'New York';
        con.MailingPostalCode = '1234567';
        con.AccountId = acct.Id;
        insert con;
        
        NSP_Account_Team__c accTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        accTeam.NSP_Account__c = acct.Id;
        accTeam.NSP_Role__c = NSP_ServiceConstants.BUS_TEAM_HRSP_CL;
        accTeam.NSP_User__c = UserInfo.getUserId();
        accTeam.NSP_Primary__c = true;
        insert accTeam;

        //inserting Asset 
        Asset assetObj = (Asset) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetObj.accountId = acct.Id;
        assetObj.name='Test';
        assetObj.RecordTypeId = recordTypeWoAsset;
        assetObj.NSP_AIMS_First_Pay_Date__c = null;
        assetObj.Status= 'Active';
       	assetObj.NSP_Account_Status__c =  'Active';
        insert assetObj;
        
        //Inserting Sub Client
        NSP_Sub_Client__c subClientObj = (NSP_Sub_Client__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', false);
        subClientObj.NSP_Account__c = acct.Id;
        subClientObj.NSP_Asset__c = assetObj.id;
        insert subClientObj;
        
        //Inserting Sub Client Contact
        NSP_Sub_Client_Contact__c subClientContObj = (NSP_Sub_Client_Contact__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', false);
        subClientContObj.NSP_Contact__c = con.Id;
        insert subClientContObj;
        
        //Inserting Address
        List<NSP_Address__c> lstAddress = new List<NSP_Address__c>();
        NSP_Address__c address = (NSP_Address__c) NSP_TestDataFactory.createSObject(new NSP_Address__c(), 'NSP_TestDataFactory.AddressDefaults', false);
        address.NSP_Contact__c = con.Id;
        address.NSP_Asset__c = assetObj.Id;
        address.NSP_Label_Code__c = 'Testing123';
        address.Name = 'Test';
        address.NSP_Address_Type__c = 'Worksite';
        address.NSP_Country__c = 'United States';
        address.NSP_City__c = 'testing';
        address.NSP_Postal_Code__c = '40065';
        address.NSP_Street__c ='Test';
        address.NSP_State__c ='NY';
        address.NSP_Source__c = 'AIMS';
        lstAddress.add(address);
        NSP_Address__c address1 = (NSP_Address__c) NSP_TestDataFactory.createSObject(new NSP_Address__c(), 'NSP_TestDataFactory.AddressDefaults', false);
        address1.NSP_Contact__c = con.Id;
        address1.NSP_Asset__c = assetObj.Id;
        address1.NSP_Label_Code__c = 'Testing123';
        address1.Name = 'Test';
        address1.NSP_Address_Type__c = 'Worksite';
        address1.NSP_Country__c = 'United States';
        address1.NSP_City__c = 'testung';
        address1.NSP_Postal_Code__c = '40065';
        address1.NSP_Street__c ='Test';
        address1.NSP_State__c ='NJ';
        address1.NSP_Source__c = 'AIMS';
        lstAddress.add(address1);
        NSP_Address__c address3 = (NSP_Address__c) NSP_TestDataFactory.createSObject(new NSP_Address__c(), 'NSP_TestDataFactory.AddressDefaults', false);
        address3.NSP_Contact__c = con.Id;
        address3.NSP_Asset__c = assetObj.Id;
        address3.NSP_Label_Code__c = 'Testing123';
        address3.Name = 'Test';
        address3.NSP_Address_Type__c = 'Worksite';
        address3.NSP_Country__c = 'United States';
        address3.NSP_City__c = 'Testing';
        address3.NSP_Postal_Code__c = '50053';
        address3.NSP_Street__c ='Test';
        address3.NSP_State__c ='IL';
        address3.NSP_Source__c = 'AIMS';
        lstAddress.add(address3);
        NSP_Address__c address4 = (NSP_Address__c) NSP_TestDataFactory.createSObject(new NSP_Address__c(), 'NSP_TestDataFactory.AddressDefaults', false);
        address4.NSP_Contact__c = con.Id;
        address4.NSP_Asset__c = assetObj.Id;
        address4.NSP_Label_Code__c = 'Testing123';
        address4.Name = 'Test';
        address4.NSP_Address_Type__c = 'Worksite';
        address4.NSP_Country__c = 'United States';
        address4.NSP_City__c = 'Chicago';
        address4.NSP_Postal_Code__c = '404675';
        address4.NSP_Street__c ='Test';
        address4.NSP_State__c ='AK';
        address4.NSP_Source__c = 'AIMS';
        lstAddress.add(address4);
        insert lstAddress;

        List<NSP_Sub_Client_Contact_Address__c> lstSubClientContactAddress = new list<NSP_Sub_Client_Contact_Address__c>();
        //Inserting NSP_Sub_Client_Contact_Address
        NSP_Sub_Client_Contact_Address__c subClientContactAddress = (NSP_Sub_Client_Contact_Address__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact_Address__c(), 'NSP_TestDataFactory.SubClientContactAddressDefaults', false);
        subClientContactAddress.NSP_Address__c = lstAddress[0].Id;
        subClientContactAddress.NSP_Sub_Client_Contact__c = subClientContObj.Id;
        subClientContactAddress.NSP_Contact__c = con.Id;
        lstSubClientContactAddress.add(subClientContactAddress);
        NSP_Sub_Client_Contact_Address__c subClientContactAddress1 = (NSP_Sub_Client_Contact_Address__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact_Address__c(), 'NSP_TestDataFactory.SubClientContactAddressDefaults', false);
        subClientContactAddress1.NSP_Address__c = lstAddress[1].Id;
        subClientContactAddress1.NSP_Sub_Client_Contact__c = subClientContObj.Id;
        subClientContactAddress1.NSP_Contact__c = con.Id;
        lstSubClientContactAddress.add(subClientContactAddress1);
        NSP_Sub_Client_Contact_Address__c subClientContactAddress2 = (NSP_Sub_Client_Contact_Address__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact_Address__c(), 'NSP_TestDataFactory.SubClientContactAddressDefaults', false);
        subClientContactAddress2.NSP_Address__c = lstAddress[2].Id;
        subClientContactAddress2.NSP_Sub_Client_Contact__c = subClientContObj.Id;
        subClientContactAddress2.NSP_Contact__c = con.Id;
        lstSubClientContactAddress.add(subClientContactAddress2);
        NSP_Sub_Client_Contact_Address__c subClientContactAddress3 = (NSP_Sub_Client_Contact_Address__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact_Address__c(), 'NSP_TestDataFactory.SubClientContactAddressDefaults', false);
        subClientContactAddress3.NSP_Address__c = lstAddress[3].Id;
        subClientContactAddress3.NSP_Sub_Client_Contact__c = subClientContObj.Id;
        subClientContactAddress3.NSP_Contact__c = con.Id;
        lstSubClientContactAddress.add(subClientContactAddress3);
        insert subClientContactAddress;
    }   
    
    //Static Test Method to Call the Scheduler Class
    static testMethod void testAccountRegulatedBatchScheduler() {  
        Test.startTest();  
        NSP_AccountRegulatedArea_Scheduler regualtedAreaScheduler = new NSP_AccountRegulatedArea_Scheduler();
        //Map<String, String> regulatedState = NSP_RegulatedAreaBatch.regulatedState;
        String sch = '0 0 2 * * ?';
        String jobId = System.schedule('Test Regulated Batch', sch, regualtedAreaScheduler);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();     
   }  

}