/**
* Represents test class for NSP_IP_MM_EmailAutoController
*/
@isTest
public class NSP_IP_MM_EmailAutoController_Test {                         
   
    /**
    * Does test data setup 
    * @return void                          
    */
    @testSetup
    static void setUpData(){
        
        Id peoProjectRecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
        
        Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
		Insert acc;
        
        //creation of a Contact record
        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.lastName= 'Test';
        con.pse__Salesforce_User__c = UserInfo.getUserId();
        con.NSP_Work_email__c = 'abctestexamplyxyz@test.com.abc';
        Insert con;
        
        //creation of Project Task
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
		oProject.pse__Account__c = acc.Id;
        oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;//FSOImplementationProject
        oProject.RecordTypeId = peoProjectRecordTypeId;
        oProject.pse__End_Date__c = System.today()+ 5;
        Insert oProject;

        List<NSP_Regulated_Area__c> lstRegulatedAssets = new List<NSP_Regulated_Area__c>();
        NSP_Regulated_Area__c regulatedAsset = new NSP_Regulated_Area__c(NSP_Regulation_Type__c = NSP_ServiceConstants.STATE_RET_PLAN, NSP_State__c = 'NH');
        lstRegulatedAssets.add(regulatedAsset);
        
        NSP_Regulated_Area__c regulatedAsset1 = new NSP_Regulated_Area__c(NSP_Regulation_Type__c = NSP_ServiceConstants.STATE_RET_PLAN, NSP_State__c = 'NJ');
        lstRegulatedAssets.add(regulatedAsset1);
        
        NSP_Regulated_Area__c regulatedAsset2 = new NSP_Regulated_Area__c(NSP_Regulation_Type__c = NSP_ServiceConstants.STATE_RET_PLAN, NSP_State__c = 'VA');
        lstRegulatedAssets.add(regulatedAsset2);
        Insert lstRegulatedAssets;
        
    }
    
    @isTest static void checkforRemoveEmployeeDirectory(){
        Test.startTest();
        //GIVEN
        Implementation_Profile__c ip = [SELECT Id, NSP_Form_Completed__c, Remove_client_employee_directory__c FROM Implementation_Profile__c WHERE ID != null LIMIT 1];
        //WHEN
        ip.NSP_Form_Completed__c = true;
        ip.Remove_client_employee_directory__c = NSP_ServiceConstants.YES;
        Update ip;
        //THEN
        system.assertEquals(ip.NSP_Form_Completed__c, true);
        Test.stopTest();
    }

    @isTest static void checkEPLINotification(){
        Test.startTest();
        //GIVEN
        Implementation_Profile__c ip = [SELECT Id, NSP_Form_Completed__c, Client_maintaining_existing_EPLI_policy__c, Wnt_cpy_of_Insperity_EPLI_policy_cert__c FROM Implementation_Profile__c WHERE ID != null LIMIT 1];
        //WHEN
        ip.NSP_Form_Completed__c = true;
        ip.Client_maintaining_existing_EPLI_policy__c = NSP_ServiceConstants.YES;
        ip.Wnt_cpy_of_Insperity_EPLI_policy_cert__c = NSP_ServiceConstants.YES;
        Update ip;
        //THEN
        system.assertEquals(ip.NSP_Form_Completed__c, true);
        Test.stopTest();
    }

    @isTest static void checkforStockPurchasePlan(){
        Test.startTest();
        //GIVEN
        Implementation_Profile__c ip = [SELECT Id, NSP_Form_Completed__c, Does_the_client_offer_a_Stock_Purchase__c FROM Implementation_Profile__c WHERE ID != null LIMIT 1];
        //WHEN
        ip.NSP_Form_Completed__c = true;
        ip.Does_the_client_offer_a_Stock_Purchase__c = NSP_ServiceConstants.YES;
        Update ip;
        //THEN
        system.assertEquals(ip.NSP_Form_Completed__c, true);
        Test.stopTest();
    }
    @isTest static void checkforExistingRetirementPlanKeep(){
        Test.startTest();
        //GIVEN
        Implementation_Profile__c ip = [SELECT Id, NSP_Form_Completed__c, Client_has_existing_retirement_plan__c, Type_of_retirement_plan_client_has_today__c FROM Implementation_Profile__c WHERE ID != null LIMIT 1];
        //WHEN
        ip.NSP_Form_Completed__c = true;
        ip.Client_has_existing_retirement_plan__c = NSP_ServiceConstants.YES;
        ip.Type_of_retirement_plan_client_has_today__c = NSP_ServiceConstants.CSP401K;
        Update ip;
        ip.Type_of_retirement_plan_client_has_today__c = NSP_ServiceConstants.SIMPLEIRA;
        Update ip;
        ip.Type_of_retirement_plan_client_has_today__c = NSP_ServiceConstants.CLIENTB;
        Update ip;
        //THEN
        system.assertEquals(ip.NSP_Form_Completed__c, true);
        Test.stopTest();
    }
    
    @isTest static void checkforExistingRetirementMovetoNSP401(){
        Test.startTest();
        //GIVEN
        Implementation_Profile__c ip = [SELECT Id, Client_has_existing_retirement_plan__c, NSP_Form_Completed__c, Type_of_retirement_plan_client_has_today__c FROM Implementation_Profile__c WHERE ID != null LIMIT 1];
        //WHEN
        ip.NSP_Form_Completed__c = true;
        ip.Client_has_existing_retirement_plan__c = NSP_ServiceConstants.YES;
        ip.Type_of_retirement_plan_client_has_today__c = NSP_ServiceConstants.PEOMULTIPLIER;
        Update ip;
        ip.Type_of_retirement_plan_client_has_today__c = NSP_ServiceConstants.CSP401KNSP;
        Update ip;
        //THEN
        system.assertEquals(ip.NSP_Form_Completed__c, true);
        Test.stopTest();
    }

    @isTest static void checkforEEOInformation(){
        Test.startTest();
        //GIVEN
        Implementation_Profile__c ip = [SELECT Id, Client_has_existing_retirement_plan__c, NSP_Form_Completed__c, Type_of_retirement_plan_client_has_today__c FROM Implementation_Profile__c WHERE ID != null LIMIT 1];
        //WHEN
        ip.NSP_Form_Completed__c = true;
        ip.Is_the_client_a_federal_contractor__c = NSP_ServiceConstants.NO;
        ip.Client_have_EEO_filing_under__c = NSP_ServiceConstants.NO;
        ip.Can_client_provide_EEO_filing_address__c = NSP_ServiceConstants.YES;
        ip.EEO__c = 'Test EEO';
        ip.Filing_address__c = 'Test Filing Address';
        Update ip;
        //THEN
        system.assertEquals(ip.NSP_Form_Completed__c, true);
        Test.stopTest();
    }

    @isTest static void checkSRPNotification(){
        Test.startTest();
        //GIVEN
        Implementation_Profile__c ip = [SELECT Id, Client_has_existing_retirement_plan__c, Client_want_to_begin_401k_w_NSP_setup__c , NSP_Form_Completed__c FROM Implementation_Profile__c WHERE ID != null LIMIT 1];
        //WHEN
        ip.NSP_Form_Completed__c = true;
        ip.Client_has_existing_retirement_plan__c = NSP_ServiceConstants.NO;
        ip.Client_want_to_begin_401k_w_NSP_setup__c = NSP_ServiceConstants.NO;
        ip.Employees_work_in_the_following_states__c = 'NJ;NH;VA';
        Update ip;
        //THEN
        system.assertEquals(ip.NSP_Form_Completed__c, true);
        Test.stopTest();
    }

    @isTest static void checkforNew401k(){
        Test.startTest();
        //GIVEN
        Implementation_Profile__c ip = [SELECT Id, Client_has_existing_retirement_plan__c, Client_want_to_begin_401k_w_NSP_setup__c , NSP_Form_Completed__c FROM Implementation_Profile__c WHERE ID != null LIMIT 1];
        //WHEN
        ip.NSP_Form_Completed__c = true;
        ip.Client_has_existing_retirement_plan__c = NSP_ServiceConstants.NO;
        ip.Client_want_to_begin_401k_w_NSP_setup__c = NSP_ServiceConstants.YES;
        Update ip;
        //THEN
        system.assertEquals(ip.NSP_Form_Completed__c, true);
        Test.stopTest();
    }

    @isTest static void checkforNull(){
        Test.startTest();
        //GIVEN
        Id ipMMRecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.MMProfile).getRecordTypeId();
       
        //WHEN
        Implementation_Profile__c ip = new Implementation_Profile__c();
        ip.RecordTypeId = ipMMRecordTypeId;
        Insert ip;

        //THEN
        system.assertEquals(ip.RecordTypeId, ipMMRecordTypeId);
        Test.stopTest();
    }

    @isTest static void checkforCOBRA(){
        Test.startTest();
        //GIVEN
        Id fsoRecordTypeId =  Schema.SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.FSOProfile).getRecordTypeId();

        Implementation_Profile__c ip = new Implementation_Profile__c();
        //WHEN
        ip.RecordTypeId = fsoRecordTypeId;
        ip.NSP_Form_Completed__c = true;
        ip.Have_name_s_of_COBRA_takeovr_employees__c = NSP_ServiceConstants.NO;
        Insert ip;

        ip.Have_name_s_of_COBRA_takeovr_employees__c = NSP_ServiceConstants.YES;
        Update ip;
        //THEN
        system.assertEquals(ip.NSP_Form_Completed__c, true);
        Test.stopTest();
    }

    @isTest static void checkforCOBRAFormCollected(){
        Test.startTest();
        //GIVEN
        Id fsoRecordTypeId =  Schema.SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.FSOProfile).getRecordTypeId();

        Implementation_Profile__c ip = new Implementation_Profile__c();
        //WHEN
        ip.RecordTypeId = fsoRecordTypeId;
        ip.NSP_Form_Completed__c = true;
        ip.Have_name_s_of_COBRA_takeovr_employees__c = NSP_ServiceConstants.YES;
        Insert ip;

        //THEN
        system.assertEquals(ip.NSP_Form_Completed__c, true);
        Test.stopTest();
    }

    @isTest static void checkforLOAInfo(){
        Test.startTest();
        //GIVEN
        Id fsoRecordTypeId =  Schema.SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.FSOProfile).getRecordTypeId();

        Implementation_Profile__c ip = new Implementation_Profile__c();
        //WHEN
        ip.RecordTypeId = fsoRecordTypeId;
        ip.NSP_Form_Completed__c = true;
        ip.Do_you_have_the_LOA_information__c = NSP_ServiceConstants.YES;
        Insert ip;
        
        ip.Do_you_have_the_LOA_information__c = NSP_ServiceConstants.NO;
        Update ip;

        //THEN
        system.assertEquals(ip.NSP_Form_Completed__c, true);
        Test.stopTest();
    }
    
}