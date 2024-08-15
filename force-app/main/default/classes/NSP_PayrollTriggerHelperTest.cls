@isTest
public class NSP_PayrollTriggerHelperTest {
    public Static final Id WOASSETRECTYPEID = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();
    
    @testSetup
    private static void setupTestData(){
        
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
    
    static testMethod void shouldPublishEvent() {
        
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
    @isTest
    public static void deepCloneRec() {
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
    
    @isTest
    static void checkForGovernmentContractorTest() {
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
    @isTest
    static void updatePDSRelatedContactFieldsTest() {
        
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
}