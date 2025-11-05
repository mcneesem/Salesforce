/**
Apex Class Name      :  NSP_IP_Automation_Helper_Test
Version              :  1.0                                                                          
Created Date         :  12/24/2021   
Function             :  Represents test class for NSP_IP_Automation_Helper 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* ------------------------------------------------------------------------------------------------- 
* Masthan                     10/24/2025             Added test for getNewCasesToInsertSubjectIp to cover new logic introduced in NSP_IP_Automation_Helper
*/
@isTest
public class NSP_IP_Automation_Helper_Test {
    //Strings
    private static final String TEST_AUTOMATION = 'Test Automation';
    private static final String TEST_FUNCTION = 'Test Function';
    private static final String TEST_SECTION = 'Test Section';
    @testSetup
    static void setUpData(){
        Test.startTest();
        Id peoProjectRecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
        
        Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        Insert acc;
        
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Account__c = acc.Id;
        oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;//FSOImplementationProject
        oProject.RecordTypeId = peoProjectRecordTypeId;
        oProject.pse__End_Date__c = System.today()+ 5;
        Insert oProject;
        Test.stopTest();

    }
    
    //Test Setup Method
    @isTest
    static void testCreateIPAutomation() {
        Test.startTest();
        //Get IP Rec 
        Implementation_Profile__c ip = [SELECT Id,RecordTypeId FROM Implementation_Profile__c WHERE Id!=NULL LIMIT 1];
        //WHen
        NSP_IP_Automation_Helper helper = new NSP_IP_Automation_Helper();
        NSP_Implementation_Profile_Automation__c ipAutomation = helper.createIPAutomation(ip, TEST_AUTOMATION, TEST_FUNCTION, TEST_SECTION);
        //Then
        System.assertEquals(TEST_AUTOMATION, ipAutomation.Name);
        System.assertEquals(TEST_FUNCTION, ipAutomation.NSP_Method_Name__c);
        System.assertEquals(TEST_SECTION, ipAutomation.NSP_Section__c);
        System.assertEquals(ip.Id, ipAutomation.NSP_Implementation_Profile__c);
        System.assertEquals(NSP_ServiceConstants.IP_CASE_AUTOMATIONCLASS, ipAutomation.NSP_Class_Name__c);
        System.assertNotEquals(null, ipAutomation.NSP_Last_Run__c);
        System.assertEquals(NSP_ServiceConstants.MIDDLEMARKET, ipAutomation.NSP_Record_Type__c);
        Test.stopTest();

    }
    
    @isTest
    static void testGetAllIPAutomation() {
        //get IP recs
        String query = new NSP_QueryBuilder('Implementation_Profile__c', new List<String>{'Name','RecordTypeId'}).addLimit(1).build();
        Implementation_Profile__c ipRec = (Implementation_Profile__c) Database.query(query);
        
        String iPquery = new NSP_QueryBuilder('Account', new List<String>{'Name'}).addLimit(1).build();
        Account acc = (Account) Database.query(iPquery);
        //Given
        NSP_Implementation_Profile_Automation__c ipAutomation = (NSP_Implementation_Profile_Automation__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Implementation_Profile_Automation__c(), 'NSP_TestDataFactory.ImplementationProfileAutomationsDefaults', false);
        ipAutomation.Name = TEST_AUTOMATION;
        ipAutomation.NSP_Method_Name__c = TEST_FUNCTION;
        ipAutomation.NSP_Section__c = TEST_SECTION;
        ipAutomation.NSP_Implementation_Profile__c = ipRec.Id;
        ipAutomation.NSP_Class_Name__c = NSP_ServiceConstants.IP_CASE_AUTOMATIONCLASS;
        ipAutomation.NSP_Last_Run__c = System.now();
        ipAutomation.NSP_Record_Type__c = NSP_ServiceConstants.FSOProfile;
        insert ipAutomation;
        
        Case caseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        caseRecord.NSP_Category__c = 'Adaption';
        caseRecord.NSP_SubCategory__c = 'Claim';
        caseRecord.Subject = 'Test Report Dev Notifications';
        caseRecord.AccountId = acc.Id;
        caseRecord.NSP_Implementation_Profile__c = ipRec.id;
        insert caseRecord;
        //When
        Test.startTest();
        Set<Id> ipIds = new Set<Id>{ipRec.Id};
            NSP_IP_Automation_Helper helper = new NSP_IP_Automation_Helper();
        helper.getAllIPAutomation(ipIds);
        helper.getnewCasestoInsert(new List<Case>{caseRecord});
        helper.getNewCasesToInsertSubjectIp(new List<Case>{caseRecord});
        NSP_Implementation_Profile_Automation__c ipAutomation2 = helper.createIPAutomation(ipRec, TEST_AUTOMATION, TEST_FUNCTION, TEST_SECTION);
        helper.getnewAutomationListtoInsert(new List<NSP_Implementation_Profile_Automation__c>{ipAutomation2});
        helper.getAllCases(ipIds);
        //Then
        System.assertEquals(1, helper.existingIpAutomations.size());
        Test.stopTest();
    }
}