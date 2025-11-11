@isTest
private class NSP_PayrollTriggerHelperTest {
    private Static final Id WOASSETRECTYPEID = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();
    
    @testSetup private static void setupTestData(){
        
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.NSP_Work_email__c = 'Test@email.com';
        newContact.MobilePhone = '876657787';
        newContact.Phone = '67763478';
        newContact.NSP_Work_Phone__c = '87278483';
        insert newContact;
        
        Account accoutObject = new Account();
        accoutObject.Name = 'Test Account';
        accoutObject.NSP_AIMS_Client__c = '52000';
        insert accoutObject;
            
        User oUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        oUser.EmployeeNumber = System.Label.NSP_User_Employee_Number;
        oUser.userName = 'testpallavi257045@testpallavi.testpallavi';
        insert oUser;
        
        NSP_Account_Team__c accteam = new NSP_Account_Team__c();
        accteam.NSP_Account__c = accoutObject.Id;
        accteam.NSP_Role__c = 'Payroll Specialist';
        accteam.NSP_User__c = oUser.Id;
        insert accteam;

        Contact con = new Contact();
        con.AccountId = accoutObject.Id ;
        con.NSP_Per_ID__c = 'Test123';
        con.LastName = 'Test con';
        insert con;
        Test.startTest();
        Asset asset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        asset.AccountId = accoutObject.Id;
        asset.NSP_Client_Segment_type__c = NSP_ServiceConstants.EG50AssetSegment;
        asset.recordtypeId = WOASSETRECTYPEID;
        Database.insert(asset);
        
        NSP_Sub_Client__c scIns = (NSP_Sub_Client__c) NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', false);
        scIns.Name = 'Test';
        scIns.NSP_Account__c = accoutObject.Id ;
        scIns.NSP_Asset__c = asset.Id ;
        insert scIns ;
        
        NSP_Sub_Client__c scIns1 = (NSP_Sub_Client__c) NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', false);
        scIns1.Name = 'Test 1';
        scIns1.NSP_Account__c = accoutObject.Id ;
        scIns1.NSP_Asset__c = asset.Id ;
        insert scIns1 ;
        
        NSP_Sub_Client_Contact__c subClientCon = new NSP_Sub_Client_Contact__c();
        subClientCon.NSP_Sub_Client__c = scIns1.Id;
        subClientCon.NSP_Contact__c = con.Id;
        subClientCon.NSP_On_Site_Supervisor__c = true;
        subClientCon.NSP_Payroll_Contact__c = true;
        subClientCon.NSP_HR_Contact__c = true;
        subClientCon.NSP_Background_Contact__c = true;
        insert subClientCon ; 
        Test.stopTest();
        
        NSP_Payroll__c pdsIns = (NSP_Payroll__c) NSP_TestExtendedDataFactory.createSObject(new NSP_Payroll__c(), 'NSP_TestDataFactory.PayrollDataSheetDefaults', false); 
        pdsIns.NSP_Sub_Client_Name__c = scIns1.Id ;
        Database.insert(pdsIns);       
        

    }
    
    @isTest private static void shouldPublishEvent() {
        
        Test.startTest();
        Contact con = [SELECT Id, Email, MobilePhone, Phone, NSP_Work_Phone__c FROM Contact WHERE Contact.MobilePhone = '876657787'];
        NSP_Sub_Client__c scIns = [SELECT ID FROM NSP_Sub_Client__c WHERE Name = 'Test'];
        NSP_Payroll__c Payroll = (NSP_Payroll__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Payroll__c(), 'NSP_TestDataFactory.PayrollDataSheetDefaults', false);
        Payroll.NSP_On_site_Supervisor__c = con.Id;
        Payroll.NSP_Back_Up_Payroll_Contact__c = con.Id;
        Payroll.NSP_HR_Contact__c = con.Id;
        Payroll.NSP_Primary_Payroll_Contact__c= con.Id;
        Payroll.NSP_Sub_Client_Name__c = scIns.Id ;
        insert Payroll;
        Test.stopTest();
        System.assert(NSP_PayrollTriggerHelper.payrollDataSheetEventListToBeInserted.size()==1 );
    }

    @isTest private static void deepCloneRec() {
        Test.StartTest();
        Account acc = new Account();
        acc.Name='Test Account';
        insert acc;
        
        Contact conI = new Contact();
        conI.LastName = 'Test';
        conI.AccountId = acc.Id ;
        insert conI ;
        
        Asset ass = new Asset();
        ass.Name='Test ';
        ass.AccountId = acc.Id ;
        ass.recordTypeId = WOASSETRECTYPEID;
        insert ass ;
        
        NSP_Sub_Client__c scIns = new NSP_Sub_Client__c ();
        scIns.Name = 'Test';
        scIns.NSP_Account__c = acc.Id ;
        scIns.NSP_Asset__c = ass.Id ;
        insert scIns ;
        
        NSP_Payroll__c pdsIns = new NSP_Payroll__c ();
        pdsIns.NSP_Sub_Client_Name__c = scIns.Id ;
        insert pdsIns;
        
        NSP_Related_Account__c relAcc1 = New NSP_Related_Account__c ();
        relAcc1.NSP_Payroll_Data_Sheet__c = pdsIns.Id;
        relAcc1.NSP_Account__c = acc.Id;
        insert relAcc1;
        
        NSP_Payroll_Calendar__c payCal = new NSP_Payroll_Calendar__c ();
        payCal.NSP_Payroll_Data_Sheet__c = pdsIns.Id;
        Insert payCal;
        
        Additional_Payroll_Contact__c adPayCon = new Additional_Payroll_Contact__c ();
        adPayCon.Payroll__c = pdsIns.Id;
        adPayCon.Contact__c = conI.Id;
        insert adPayCon ;
        
        List<Id> payrollIds = new List<Id>();
        List<NSP_Sub_Client__c> subClientDetails = [SELECT Id FROM NSP_Sub_Client__c WHERE Id != null];
        List<NSP_Payroll__c> payrollDetails = [SELECT Id FROM NSP_Payroll__c WHERE Id = :pdsIns.Id];
        payrollIds.Add(payrollDetails[0].Id);
        try {
            NSP_PayrollTriggerHelper.deepCloneRec(payrollDetails[0].Id,subClientDetails[0].Id);
            
        } catch (Exception exp) {
            
            System.assert(exp.getMessage().Contains('There is an existing PDS attached to the given Sub Client.'));
        }
        
        Test.StopTest();
        
    }
    /**
    * @Description: This test method is used to cover checkForGovernmentContractor method
    * @Created date: 10/17/2022. 
    * @return void             
    */ 
    
    @isTest private static void checkForGovernmentContractorTest() {
        Asset woAsset = [SELECT Id, NSP_Government_Contractor__c FROM Asset WHERE recordTypeId =: WOASSETRECTYPEID LIMIT 1];
        woAsset.NSP_Government_Contractor__c = true;
        Test.startTest();
        Database.update(woAsset);
        NSP_Payroll__c assertPDS = [SELECT Id, NSP_Government_Contractor__c FROM NSP_Payroll__c WHERE NSP_Government_Contractor__c = true LIMIT 1];
        Test.stopTest();
        system.assertEquals(true, assertPDS.NSP_Government_Contractor__c);
    }

    
    /**
    * @Description: This test method is used to cover updatePDSRelatedContactFields method
    * @Created date: 11/23/2022. 
    * @return void             
    */
    @isTest private static void updatePDSRelatedContactFieldsTest() {
        
        Test.startTest();
        NSP_Sub_Client__c subCli = [SELECT Id, NSP_Account__c ,NSP_Account__r.NSP_AIMS_Client__c FROM NSP_Sub_Client__c LIMIT 1];
        Contact con = [SELECT Id,LastName FROM Contact WHERE LastName = 'Test con' LIMIT 1];        
            
        NSP_Sub_Client_Contact__c subClientCon = [SELECT Id, NSP_Is_Primary__c FROM NSP_Sub_Client_Contact__c WHERE Id != null LIMIT 1];
        subClientCon.NSP_Is_Primary__c = true;
        update subClientCon;
        
        NSP_Payroll__c pds = [SELECT Id, NSP_Primary_Payroll_Contact__c FROM NSP_Payroll__c WHERE Id != null LIMIT 1];
        pds.NSP_Primary_Payroll_Contact__c = null;
        update pds;
        pds.NSP_Primary_Payroll_Contact__c = con.Id;
        update pds;
                
        Test.stopTest();
        NSP_Payroll__c assertPDS = [SELECT Id, NSP_Payroll_SCC__c  FROM NSP_Payroll__c WHERE Id != null LIMIT 1];
        system.assert(subClientCon.NSP_Is_Primary__c);
    }
   /**
    * @Description: This test method is used to cover updatePDSPayrollReviewersField method 
    * when Payroll Data Sheet record insert/update
    * @Created date: 28/08/2022. 
    * @return void             
    */
    @isTest
    private static void updatePayrollReviewersTest(){
        Test.startTest();
        //GIVEN
        Contact contact = [SELECT Id,LastName FROM Contact WHERE LastName = 'Test con' LIMIT 1];
        NSP_Payroll__c pds = [SELECT Id, NSP_Primary_Payroll_Contact__c,NSP_Back_Up_Payroll_Contact__c,NSP_HR_Contact__c,NSP_On_site_Supervisor__c, Primary_View_Payroll_Paperwork__c,Back_Up_View_Payroll_Paperwork__c,On_Site_View_Payroll_Paperwork__c,View_Payroll_Paperwork__c FROM NSP_Payroll__c WHERE Id != null LIMIT 1];
        
        pds.NSP_Primary_Payroll_Contact__c = contact.Id;
        pds.NSP_Back_Up_Payroll_Contact__c = contact.Id;
        pds.NSP_HR_Contact__c = contact.Id;
        pds.NSP_On_site_Supervisor__c = contact.Id;
        pds.Primary_View_Payroll_Paperwork__c = true;
        pds.Back_Up_View_Payroll_Paperwork__c = true;
        pds.On_Site_View_Payroll_Paperwork__c = true;
        pds.View_Payroll_Paperwork__c = true;
        update pds;
        
        Test.stopTest();
        NSP_Payroll__c assertPDS = [SELECT Id, Payroll_Reviewers__c  FROM NSP_Payroll__c WHERE Id != null LIMIT 1];
        system.assertEquals(assertPDS.Payroll_Reviewers__c,'Test con');
        system.assertNotEquals(assertPDS.Payroll_Reviewers__c,null);
    }
    
    /**
    * @Description: This test method is used to cover updatePDSPayrollReviewersField method 
    * when Additional Payroll Contact record insert, update or delete.
    * @Created date: 28/08/2022. 
    * @return void             
    */
    @isTest
    private static void updatePayrollReviewersTest2(){
        Test.startTest();
        //GIVEN
        Contact contact = [SELECT Id,LastName FROM Contact WHERE LastName = 'Test con' LIMIT 1];
        NSP_Payroll__c pds = [SELECT Id,Name FROM NSP_Payroll__c WHERE Id != null LIMIT 1];
        //WHEN
        Additional_Payroll_Contact__c newAdditionalPayrollContact = (Additional_Payroll_Contact__c)NSP_TestExtendedDataFactory.createSObject(new Additional_Payroll_Contact__c(), 'NSP_TestDataFactory.AdditionalPayrollContactDefaults', false);
        newAdditionalPayrollContact.Contact__c = contact.Id ;
        newAdditionalPayrollContact.Payroll__c = pds.Id;
        newAdditionalPayrollContact.View_Payroll_Paperwork__c = true;
        insert newAdditionalPayrollContact;

        Test.stopTest();
        
        Additional_Payroll_Contact__c APcontact=[SELECT Id,Payroll__r.Id,Contact__r.Name FROM Additional_Payroll_Contact__c LIMIT 1];
        NSP_Payroll__c assertPDS = [SELECT Id, Payroll_Reviewers__c  FROM NSP_Payroll__c WHERE Id != null LIMIT 1];
        system.assertEquals(assertPDS.Payroll_Reviewers__c,'Test con');
        system.assertNotEquals(assertPDS.Payroll_Reviewers__c,null);
        
    }
     /**
    * @Description: This test method is used to cover updatePayrollSpecialistField method
    * @Created date: 28/08/2024
    * @return void             
    */
    @isTest private static void updatePayrollSpecialistField() {
        
        Test.startTest();
        Account acc = [Select Id from Account Where Name = 'Test Account' LIMIT 1];
        NSP_Payroll__c pds = [SELECT Id, Account__c FROM NSP_Payroll__c WHERE Id != null LIMIT 1];
        pds.Account__c = acc.Id;
        update pds;
        
        Test.stopTest();
        NSP_Payroll__c assertpds = [SELECT Id, Payroll_Specialist__c FROM NSP_Payroll__c WHERE Id != null LIMIT 1];
        User userobj = [Select Id, Name From User WHERE userName = 'testpallavi257045@testpallavi.testpallavi' LIMIT 1];
        system.assertEquals(assertpds.Payroll_Specialist__c,userobj.Name);
        system.assertNotEquals(assertpds.Payroll_Specialist__c,null);
        } 
    
    @isTest private static void getSCCPCCountTest() {
        
        Test.startTest();       
        List<NSP_Sub_Client__c> subCliList = [SELECT Id, NSP_Account__c, NSP_Account__r.NSP_AIMS_Client__c FROM NSP_Sub_Client__c LIMIT 1 ];
        NSP_Sub_Client__c subCli;

        if (!subCliList.isEmpty()) {
            subCli = subCliList[0];            
        }

        List<Contact> conList = [SELECT Id, LastName FROM Contact WHERE LastName = 'Test con' LIMIT 1 ];
        Contact con;

        if (!conList.isEmpty()) {
            con = conList[0];    
        }

        List<NSP_Sub_Client_Contact__c> subClientConList = [SELECT Id, NSP_Payroll_Contact__c FROM NSP_Sub_Client_Contact__c WHERE Id != null LIMIT 1 ];
        NSP_Sub_Client_Contact__c subClientCon;

        if (!subClientConList.isEmpty()) {
            subClientCon = subClientConList[0];
        }

        subClientCon.NSP_Payroll_Contact__c = true;
        subClientCon.NSP_Sub_Client__c = subCli.Id;
        update subClientCon;
                      
        List<NSP_Payroll__c> pdsList = [SELECT Id, NSP_Sub_Client_Name__c FROM NSP_Payroll__c WHERE Id != null LIMIT 1 ];
        NSP_Payroll__c pds;

        if (!pdsList.isEmpty()) {
            pds = pdsList[0];    
        }

        pds.NSP_Sub_Client_Name__c = subCli.Id;
        update pds;
        Integer result = PdsContactController.getSCCPCCount(pds.Id);
        Test.stopTest();

        // From setup: payroll-contact=true under the same sub client
        System.assertEquals(1, result, 'Should count only NSP_Payroll_Contact__c=true records for the given Sub Client');
    }
    
     @isTest private static void getSCCHRCountTest() {
        
        Test.startTest();       
        List<NSP_Sub_Client__c> subCliList = [SELECT Id, NSP_Account__c, NSP_Account__r.NSP_AIMS_Client__c FROM NSP_Sub_Client__c LIMIT 1 ];
        NSP_Sub_Client__c subCli;

        if (!subCliList.isEmpty()) {
            subCli = subCliList[0];            
        }

        List<Contact> conList = [SELECT Id, LastName FROM Contact WHERE LastName = 'Test con' LIMIT 1 ];
        Contact con;

        if (!conList.isEmpty()) {
            con = conList[0];    
        }
                
        List<NSP_Sub_Client_Contact__c> subClientConList = [SELECT Id, NSP_HR_Contact__c FROM NSP_Sub_Client_Contact__c WHERE Id != null LIMIT 1 ];
        NSP_Sub_Client_Contact__c subClientCon;

        if (!subClientConList.isEmpty()) {
            subClientCon = subClientConList[0];
        }        
        subClientCon.NSP_HR_Contact__c = true;
        subClientCon.NSP_Sub_Client__c = subCli.Id;
        update subClientCon;
                
        List<NSP_Payroll__c> pdsList = [SELECT Id, NSP_Sub_Client_Name__c FROM NSP_Payroll__c WHERE Id != null LIMIT 1 ];
        NSP_Payroll__c pds;

        if (!pdsList.isEmpty()) {
            pds = pdsList[0];    
        }
        pds.NSP_Sub_Client_Name__c = subCli.Id;
        update pds;

        Integer result = PdsContactController.getSCCHRCount(pds.Id);
        Test.stopTest();

        // From setup:  hr-contact=true under the same sub client
        System.assertEquals(1, result, 'Should count only NSP_HR_Contact__c=true records for the given Sub Client');
    }
    
}