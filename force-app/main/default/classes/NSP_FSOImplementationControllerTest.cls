/**
* @description  :   Test class for NSP_FSOImplementationController .
* @date 08/3/2022
* Author : Nischay Jindal
* Name : NSP_FSOImplementationControllerTest
*/
@isTest
public class NSP_FSOImplementationControllerTest {
    /***********************************************************************************************
    * MethodName: loadAutomationRecordsTest
    * Description : Unit test for loadAutomationRecords 
    * Parameters : None
    * ********************************************************************************************/
    @Istest
    public static void loadAutomationRecordsTest(){
        //Get PEO Project Record Type Id
        Id peoProjectRecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
        //Get FSO Project Record Type Id
        Id FSORecordIPRecordTypeId = Schema.SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get('FSO').getRecordTypeId();
		List <NSP_Implementation_Profile_Automation__c> ipAutomationList = new List <NSP_Implementation_Profile_Automation__c>();
        // Inserting Account 
        Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
		insert acc;
        // Inserting Contact
        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.lastName= 'Test';
        insert con;
        // Inserting Project
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
		oProject.pse__Account__c = acc.Id;
        oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject.TemplateName__c = 'FSO - Implementation';
        oProject.RecordTypeId = peoProjectRecordTypeId;
        insert oProject;
        
        // Inserting Imp Profile
        Implementation_Profile__c impProfile= new Implementation_Profile__c();
        impProfile.NSP_Project__c = oProject.Id;
        impProfile.RecordTypeId = FSORecordIPRecordTypeId;
        impProfile.Account__c= acc.Id;
        insert impProfile;
        
        // Inserting IP Automation
        NSP_Implementation_Profile_Automation__c ipAutomation = new NSP_Implementation_Profile_Automation__c();
		ipAutomation.Name='EPLI Notification' ;       
        ipAutomation.NSP_Method_Name__c = 'NSP_EPLI_POLICY';
        ipAutomation.NSP_Class_Name__c = 'NSP_Implementationprofile_ServiceHelper';
        ipAutomation.NSP_Record_Type__c = 'FSO';
        ipAutomation.NSP_Implementation_Profile__c = impProfile.Id;
        ipAutomation.NSP_Section__c = 'Benefits';
        ipAutomation.NSP_Last_Run__c = system.now();
        ipAutomationList.add(ipAutomation) ;
        
        NSP_Implementation_Profile_Automation__c ipAutomation2 = new NSP_Implementation_Profile_Automation__c();
		ipAutomation2.Name='RRP' ;       
        ipAutomation2.NSP_Method_Name__c = 'RRPCase';
        ipAutomation2.NSP_Class_Name__c = 'NSP_Implementationprofile_ServiceHelper';
        ipAutomation2.NSP_Record_Type__c = 'FSO';
        ipAutomation2.NSP_Implementation_Profile__c = impProfile.Id;
        ipAutomation2.NSP_Section__c = 'Payroll';
        ipAutomation2.NSP_Last_Run__c = system.now();
        ipAutomationList.add(ipAutomation2) ;
        
        NSP_Implementation_Profile_Automation__c ipAutomation3 = new NSP_Implementation_Profile_Automation__c();
		ipAutomation3.Name='EDC' ;       
        ipAutomation3.NSP_Method_Name__c = 'garnishments';
        ipAutomation3.NSP_Class_Name__c = 'NSP_Implprofile_ServiceHelperUpdate';
        ipAutomation3.NSP_Record_Type__c = 'FSO';
        ipAutomation3.NSP_Implementation_Profile__c = impProfile.Id;
        ipAutomation3.NSP_Section__c = 'Payroll';
        ipAutomation3.NSP_Last_Run__c = system.now();
        ipAutomationList.add(ipAutomation3) ;
        
                
        NSP_Implementation_Profile_Automation__c ipAutomation4 = new NSP_Implementation_Profile_Automation__c();
		ipAutomation4.Name='Post-Tax Client Setup' ;       
        ipAutomation4.NSP_Method_Name__c = 'NSP_Post_Tax_SponsporedPlan';
        ipAutomation4.NSP_Class_Name__c = 'NSP_MMImplProfile_ServHelpUpdate';
        ipAutomation4.NSP_Record_Type__c = 'Middle Market';
        ipAutomation4.NSP_Implementation_Profile__c = impProfile.Id;
        ipAutomation4.NSP_Section__c = 'Payroll';
        ipAutomation4.NSP_Last_Run__c = system.now();
        ipAutomationList.add(ipAutomation4) ;
        
        //Insert the IP Automation List
        insert ipAutomationList;
		Boolean isRunAutomation ;
        
        //Insert Premier Peformance Trigger Switch (custom setting)
        NSP_Trigger_Switch__c triggerSwitch = new NSP_Trigger_Switch__c(  
            Name = UserInfo.getUserId(),  
            Premier_Performance_Automation__c = true  
        );  
        insert triggerSwitch;
        
     Test.startTest();
     // calling Class method
        NSP_FSOImplementationController.loadAutomationRecords(impProfile.Id,FSORecordIPRecordTypeId);
        isRunAutomation =NSP_FSOImplementationController.runIpAutomations(impProfile.Id,'Email',ipAutomationList[0].NSP_Method_Name__c,'FSO');
        NSP_FSOImplementationController.runIpAutomations(impProfile.Id,'CASE CREATION',ipAutomationList[1].NSP_Method_Name__c,'FSO');
         NSP_FSOImplementationController.runIpAutomations(impProfile.Id,'PROJECT TASK CREATION',ipAutomationList[2].NSP_Method_Name__c,'FSO');
         NSP_FSOImplementationController.runIpAutomations(impProfile.Id,'PROJECT TASK CREATION',ipAutomationList[3].NSP_Method_Name__c,'Middle market');
    Test.stopTest();
    // verifying the test results 
        system.assertEquals(isRunAutomation, true);
    }
}