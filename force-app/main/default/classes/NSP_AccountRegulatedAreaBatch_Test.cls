/**
Apex Class Name      :  NSP_AccountRegulatedAreaBatch_Test
Version              :  1.0 
Author               :  Jatin                                                                          
Created Date         :    06/01/22 
Function             :  Represents test class for NSP_AccountRegulatedAreaBatch class
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Anil                  8/19/2022                First Iteration
*/

@isTest
public class NSP_AccountRegulatedAreaBatch_Test { 
    private static Id recordTypePEOID = NSP_GenericRecordType.getRecordTypeId('Case', NSP_ServiceConstants.PEO);
    /**
     * Setup Data for the Regulated Area and Account, contact, Address & AccountTeam
     * @param N/A. 
     * @return void                          
     */
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
        regArea3.NSP_End_Date__c = System.today().addDays(1);
        regArea3.NSP_City__c = 'Chicago';
        regArea3.NSP_Zip_Code__c = '404675';
        regArea3.NSP_State__c = null;
        regArea3.NSP_Regulation_Type__c = 'Sick Leave';
        lstRegulatedArea.add(regArea3);

        NSP_Regulated_Area__c regArea4 = (NSP_Regulated_Area__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Regulated_Area__c(), 'NSP_TestDataFactory.RegulatedAreaDefaults', false);
        regArea4.NSP_Start_Date__c = System.today();
        regArea4.NSP_End_Date__c = System.today().addDays(1);
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
        subClientContObj.NSP_Sub_Client__c = subClientObj.Id;
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
        insert lstSubClientContactAddress;
    }   
    
    

    /**
    * Checks When the contact relatedAdress meets the Criteria then AccountRegulatedArea and Case will be created
    * @param N/A. 
    * @return void                          
    */   
    @isTest Static void testAccountRegulatedAreaBatch() { 
        

        Test.startTest();
        Asset asset = Database.Query(new NSP_QueryBuilder( 'Asset', new List<String>{'Id', 'NSP_Account_Status__c'}).addLimit(1).build());
        asset.NSP_Account_Status__c = 'Active';
        update asset;
        //Calling the batch for case and regulated area creation for 1st time     
        Database.executeBatch(new NSP_RegulatedAreaBatch()); //executes the bacth class
        System.assertEquals(0, [select count() FROM Case WHERE Subject !='' LIMIT 20], 'Case will not be created');

        Test.stopTest();
    }
    
    /**
    * Cases and AccountRegulatedArea already exists for the that Account then It wont Create new
    * @param N/A. 
    * @return void                          
    */
    @isTest Static void testAccountRegulatedAreaBatchWithExistingRecords() {  
       
        //Calling the batch for case and regulated area creation for 1st time     
    
        Account acc = Database.Query(new NSP_QueryBuilder( 'Account', new List<String>{'Id'}).addFilter('Name','Regulated Test Account').addLimit(1).build());
        
        Test.startTest();
        //Inserting Cases
        Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        newCase.AccountId = acc.Id;
        newCase.RecordTypeId = recordTypePEOID;
        newCase.NSP_Category__c = NSP_ServiceConstants.INFRASTRUCTURE;
        newCase.NSP_SubCategory__c = NSP_ServiceConstants.SUBCATEGORY_PAID_SICK_LEAVE;
        newCase.Status = NSP_SalesConstants.OPEN;
        newCase.Subject = 'Employees work in New Jersey, California, New York, Chicago';
        insert newCase;
        
        Database.executeBatch(new NSP_RegulatedAreaBatch(),50); //executes the bacth class
        //if case already exists with the accountRegulatedArea then it should not create another case
        System.assertEquals(1, [select count() FROM Case WHERE Subject !='' LIMIT 20], 'Case already exists it wont create new');
        Test.stopTest();
        
    }

    /**
    * description test existing records of AccountRegulatedArea and Cases
    * @param N/A. 
    * @return void                          
    */   
    @isTest Static void testAccountExistingCasesRegulatedAreaBatch() { 

        Test.startTest();        
        //Calling the batch for case and regulated area creation for 1st time     

        Account acc = [SELECT Id FROM Account WHERE Name = 'Regulated Test Account'];
        List<NSP_Account_Regulated_area__c> lstAccReArea = new List<NSP_Account_Regulated_area__c>();
        for(NSP_Regulated_Area__c rg : [SELECT Id FROM NSP_Regulated_Area__c WHERE NSP_Regulation_Type__c != '' LIMIT 10]){
        NSP_Account_Regulated_area__c accRegArea = new NSP_Account_Regulated_area__c();
            accRegArea.NSP_Account__c = acc.Id;
            accRegArea.NSP_Regulated_Area__c = rg.Id;
            lstAccReArea.add(accRegArea);
        }
        insert lstAccReArea;
        
        //Inserting Cases
        Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        newCase.AccountId = acc.Id;
        newCase.RecordTypeId = recordTypePEOID;
        newCase.NSP_Category__c = NSP_ServiceConstants.INFRASTRUCTURE;
        newCase.NSP_SubCategory__c = NSP_ServiceConstants.SUBCATEGORY_PAID_SICK_LEAVE;
        newCase.Status = NSP_SalesConstants.OPEN;
        newCase.Subject = 'Employees work in New Jersey, California, New York, Chicago';
        insert newCase; 
        NSP_AccountRegulatedAreaBatch.setAccountIds.add(acc.Id);
        
        Asset asset = Database.Query(new NSP_QueryBuilder( 'Asset', new List<String>{'Id', 'NSP_Account_Status__c'}).addLimit(1).build());
        asset.NSP_Account_Status__c = 'Active';
        update asset;
        //Calling the batch for case and regulated area creation for 1st time     
        Database.executeBatch(new NSP_RegulatedAreaBatch(),50); //executes the bacth class
        System.assertEquals(1, [select count() FROM Case WHERE Subject != '' LIMIT 20], 'Case will not be created');

        Test.stopTest();
    }

    /**
    * @Description testing for negative case if there is not asset associated then it fails to create new records
    * @param N/A. 
    * @return void                          
    */
    @isTest Static void testAccountRegulatedAreaNegativeCase() {  
       
        //Calling the batch for case and regulated area creation for 1st time     
        Test.startTest();
        Database.executeBatch(new NSP_RegulatedAreaBatch(),50); //executes the bacth class
        //if case already exists with the accountRegulatedArea then it should not create another case
        System.assertEquals(0, [SELECT COUNT() FROM Case WHERE Subject != '' LIMIT 20], 'condition not satisfied wont create any records');
        System.assertEquals(0, [SELECT COUNT() FROM NSP_Account_Regulated_area__c WHERE NSP_Case__c != '' LIMIT 20], 'condition not satisfied wont create any records');
        Test.stopTest();
        
    }
}