// @description  :   Test class for NSP_FSOImplementationController .
// @date 08/3/2022
// Author : Nischay Jindal
// Name : NSP_FSOImplementationControllerTest

@isTest
public class NSP_FSOImplementationControllerTest {
    
    // MethodName: loadAutomationRecordsTest
    // Description : Unit test for loadAutomationRecords 
    // Parameters : None
    
    @Istest
    public static void loadAutomationRecordsTest(){
        //creating user
        User createUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', true);
        
        // Getting the Permission Sets
        List<PermissionSet> permissionSets = [
            SELECT Id
            FROM PermissionSet
            WHERE (
                Name = 'Implementation_Profile_Read_Only' 
                OR 
                Name = 'NSP_Implementation_Profile_permission_set')
        ];
        
        Assert.areNotEqual(null, permissionSets, 'Permission sets are needed for this test class');
        Assert.areEqual(2, permissionSets?.size(), 'Query results should match the count');
        
        List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
        for(PermissionSet ps : permissionSets)
        {
            permissionSetAssignments.add(new PermissionSetAssignment(
                AssigneeId = createUser.id,
                PermissionSetId = ps.Id
            ));
        }
        
        insert permissionSetAssignments;
        
        System.runAs(createUser)
        {
            //Get PEO Project Record Type Id
            Id peoProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , 'PEO_Project' );
            //Get FSO Project Record Type Id
            Id fsoRecordIPRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Implementation_Profile__c' , 'FSO' );
            Id mmRecordIPRecordTypeId= NSP_GenericRecordType.getRecordTypeId( 'Implementation_Profile__c' , 'Middle_Market' );
            List <NSP_Implementation_Profile_Automation__c> ipAutomationList = new List <NSP_Implementation_Profile_Automation__c>();
            List <Implementation_Profile__c> ipList = new List <Implementation_Profile__c>();
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
            Implementation_Profile__c impProfile1= new Implementation_Profile__c();
            impProfile1.NSP_Project__c = oProject.Id;
            impProfile1.RecordTypeId = fsoRecordIPRecordTypeId;
            impProfile1.Account__c= acc.Id;
            ipList.add(impProfile1);
            
            Implementation_Profile__c impProfile2= new Implementation_Profile__c();
            impProfile2.NSP_Project__c = oProject.Id;
            impProfile2.RecordTypeId = mmRecordIPRecordTypeId;
            impProfile2.Account__c= acc.Id;
            ipList.add(impProfile2);
            insert ipList;
            
            // Inserting IP Automation
            NSP_Implementation_Profile_Automation__c ipAutomation = new NSP_Implementation_Profile_Automation__c();
            ipAutomation.Name='EPLI Notification' ;       
            ipAutomation.NSP_Method_Name__c = 'NSP_EPLI_POLICY';
            ipAutomation.NSP_Class_Name__c = 'NSP_Implementationprofile_ServiceHelper';
            ipAutomation.NSP_Record_Type__c = 'FSO';
            ipAutomation.NSP_Implementation_Profile__c = ipList[0].Id;
            ipAutomation.NSP_Section__c = 'Benefits';
            ipAutomation.NSP_Last_Run__c = system.now();
            ipAutomationList.add(ipAutomation) ;
            
            NSP_Implementation_Profile_Automation__c ipAutomation2 = new NSP_Implementation_Profile_Automation__c();
            ipAutomation2.Name='RRP' ;       
            ipAutomation2.NSP_Method_Name__c = 'RRPCase';
            ipAutomation2.NSP_Class_Name__c = 'NSP_Implementationprofile_ServiceHelper';
            ipAutomation2.NSP_Record_Type__c = 'FSO';
            ipAutomation2.NSP_Implementation_Profile__c = ipList[0].Id;
            ipAutomation2.NSP_Section__c = 'Payroll';
            ipAutomation2.NSP_Last_Run__c = system.now();
            ipAutomationList.add(ipAutomation2) ;
            
            NSP_Implementation_Profile_Automation__c ipAutomation3 = new NSP_Implementation_Profile_Automation__c();
            ipAutomation3.Name='EDC' ;       
            ipAutomation3.NSP_Method_Name__c = 'garnishments';
            ipAutomation3.NSP_Class_Name__c = 'NSP_Implprofile_ServiceHelperUpdate';
            ipAutomation3.NSP_Record_Type__c = 'FSO';
            ipAutomation3.NSP_Implementation_Profile__c = ipList[0].Id;
            ipAutomation3.NSP_Section__c = 'Payroll';
            ipAutomation3.NSP_Last_Run__c = system.now();
            ipAutomationList.add(ipAutomation3) ;
            
            
            NSP_Implementation_Profile_Automation__c ipAutomation4 = new NSP_Implementation_Profile_Automation__c();
            ipAutomation4.Name='Post-Tax Client Setup' ;       
            ipAutomation4.NSP_Method_Name__c = 'NSP_Post_Tax_SponsporedPlan';
            ipAutomation4.NSP_Class_Name__c = 'NSP_MMImplProfile_ServHelpUpdate';
            ipAutomation4.NSP_Record_Type__c = 'Middle Market';
            ipAutomation4.NSP_Implementation_Profile__c = ipList[0].Id;
            ipAutomation4.NSP_Section__c = 'Payroll';
            ipAutomation4.NSP_Last_Run__c = system.now();
            ipAutomationList.add(ipAutomation4) ;
            
            //Insert the IP Automation List
            insert ipAutomationList;
            Boolean isRunAutomation ;
            
            Test.startTest();
            // calling Class method
            NSP_FSOImplementationController.loadAutomationRecords(ipList[0].Id,fsoRecordIPRecordTypeId);
            NSP_FSOImplementationController.loadAutomationRecords(ipList[1].Id,mmRecordIPRecordTypeId);
            isRunAutomation =NSP_FSOImplementationController.runIpAutomations(ipList[0].Id,'Email',ipAutomationList[0].NSP_Method_Name__c,'FSO');
            NSP_FSOImplementationController.runIpAutomations(ipList[0].Id,'CASE CREATION',ipAutomationList[1].NSP_Method_Name__c,'FSO');
            NSP_FSOImplementationController.runIpAutomations(ipList[0].Id,'PROJECT TASK CREATION',ipAutomationList[2].NSP_Method_Name__c,'FSO');
            NSP_FSOImplementationController.runIpAutomations(ipList[1].Id,'PROJECT TASK CREATION',ipAutomationList[3].NSP_Method_Name__c,'Middle market');
            Test.stopTest();
            // verifying the test results 
            system.assertEquals(isRunAutomation, true);
        }
    }
}
//