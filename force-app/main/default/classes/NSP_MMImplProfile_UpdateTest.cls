/**
Apex Class Name      :  NSP_MMImplProfile_UpdateTest
Version              :  1.0 
Author               :  Bindu                                                                        
Created Date         :  8/5/2022   
Function             :  Represents test class for NSP_Implementationprofile_ServiceHelper
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Tejas                        9/9/2022             First Iteration
*/


@isTest
public class NSP_MMImplProfile_UpdateTest {
    
     public static Id ipMMRecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.MMProfile).getRecordTypeId();
     public static Id projectPEORecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get('PEO_Project').getRecordTypeId();

    /**
    * Does test data setup 
    * @return void                          
    */
    @testSetup
    public static void setUpData(){
        
       //creating user
       User createUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', true);
       //creating contact and assign user to contact
       Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
       //Assigning  Salesforce user to user id
       oContact.pse__Salesforce_User__c=createUser.Id;
       //inserting contact
       insert oContact;
       //Project creation
       List<pse__Proj__c> projList = new List<pse__Proj__c>();
       /*pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
       oProject.pse__Start_Date__c = Date.Today();
       oProject.Name='test';
       oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
       oProject.TemplateName__c = label.FSOImplementationProject;
       oProject.pse__End_Date__c = System.Today().addDays(100);
       oProject.RecordTypeId = projectPEORecordTypeId;
       projList.add(oProject);*/
        
       //creating another project record
       pse__Proj__c oProject1 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
       oProject1.Name='test record';
       oProject1.pse__Start_Date__c = Date.Today();
       oProject1.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
       oProject1.TemplateName__c=label.Middle_Market_Implementation_Project;
       oProject1.pse__End_Date__c = System.Today().addDays(100);
       oProject1.RecordTypeId = projectPEORecordTypeId;
       projList.add(oProject1);
       database.insert(projList);
        
       /* pse__Proj__c oProject2 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
       oProject2.Name='test project';
       oProject2.pse__Start_Date__c = Date.Today();
       oProject2.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
       oProject2.pse__End_Date__c = System.Today().addDays(100);
       oProject2.RecordTypeId = projectPEORecordTypeId;
       insert oProject2;*/
        
       //create MM implementation profile and assign project to IP
       /*Implementation_Profile__c impProfile = new Implementation_Profile__c();
       impProfile.NSP_Project__c = oProject1.Id;
       impProfile.NSP_Form_Completed__c = true;
       impProfile.RecordTypeId=ipMMRecordTypeId;
       insert impProfile;
        
       Implementation_Profile__c impProfile1 = new Implementation_Profile__c();
       impProfile1.NSP_Project__c = oProject1.Id;
       impProfile1.NSP_Form_Completed__c = true;
       impProfile1.RecordTypeId=ipMMRecordTypeId;
       insert impProfile1;
       
       Implementation_Profile__c impProfile2 = new Implementation_Profile__c();
       impProfile2.NSP_Project__c = oProject2.Id;
       impProfile2.NSP_Form_Completed__c = true;
       impProfile2.RecordTypeId=ipMMRecordTypeId;
       impProfile2.Select_BPSes__c = NSP_ServiceConstants.SCREENING;
       insert impProfile2;*/
    }
    
    /**
    * Classes Covered
    * NSP_MMImplProfile_ServHelpUpdate
    * cover project task creation when IP gets updated
    *
    */
    //test method handleIPForProjectTask
    @isTest
    
     public static void handleIPForProjectTask(){
        pse__Proj__c project = [SELECT Id FROM pse__Proj__c WHERE  TemplateName__c=:label.Middle_Market_Implementation_Project LIMIT 1];
        Contact cont = [select Id,pse__Salesforce_User__c from Contact WHERE LastName='ResourceLN' ];
        User user=[SELECT  Id, Username FROM User WHERE Id != null LIMIT 1];
        
        Implementation_Profile__c ip = [SELECT Id, NSP_Project__c FROM Implementation_Profile__c WHERE NSP_Project__c=:project.Id LIMIT 1 ];
         ip.Recent_Payroll_Register_Collected__c=NSP_ServiceConstants.NO;
         ip.Received_Section_125_Questionnaire__c=NSP_ServiceConstants.NO;
         ip.Has_FEIN_documentation_been_collected__c=NSP_ServiceConstants.NO;
         ip.Gotten_Cvrg_Cert_Gen_Liability_Auto__c=NSP_ServiceConstants.REQUESTED;
         ip.Client_interested_in_NSP_tracking_PTO__c= NSP_ServiceConstants.YES;
         ip.PTO_Types__c=NSP_ServiceConstants.AIMS;
         ip.NSP_Where_will_PTO_be_tracked__c=NSP_ServiceConstants.AIMS;
         ip.Client_have_will_have_any_Seasonal_EEs__c=NSP_ServiceConstants.YES;
         ip.Does_the_client_have_any_union_EEs__c=NSP_ServiceConstants.YES;
         ip.Are_there_any_EEs_on_Leave_of_Absence__c=NSP_ServiceConstants.YES;
         ip.Select_the_applicable_LOA_types__c = NSP_ServiceConstants.MILITARY_LEAVE;
         ip.Select_BPSes__c = 'Employment Screening;Recruiting Services';
         ip.Client_have_any_urgent_HR_needs__c = NSP_ServiceConstants.YES;
         ip.Select_client_urgent_HR_needs__c=NSP_ServiceConstants.JOBDESCRIPTION;
         ip.Is_client_s_current_HSA_with_Optum_Bank__c = NSP_ServiceConstants.Yes;
         ip.NSP_Payroll_Project_Manager__c=cont.id;
         ip.NSP_Project_Manager__c  = cont.id;
         ip.HR_Specialist__c=user.id;
         ip.NSP_Payroll_Specialist__c=cont.id;
         ip.NSP_Client_Sponsored_Plan__c = NSP_ServiceConstants.YES;
         ip.Sponsored_plan_contribution_type__c=NSP_ServiceConstants.PRETAX;
         ip.Allowances__c='Per Diem';
         ip.Pre_tax_Client_Sponsored_Plan_CSP_Type__c ='Health Care Flexible Spending Account (HCFSA);Health Savings Account;Dependent Care Flexible Spending Account (DCFSA);Medical (Pretax);Dental (Pretax);Vision (Pretax)';
         ip.NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c=NSP_ServiceConstants.REQUESTED;
         ip.NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c=NSP_ServiceConstants.REQUESTED;
       	 ip.NSP_Medical_Ongoing_CSP_cafeteria_Doc__c= NSP_ServiceConstants.REQUESTED;
         ip.NSP_Dental_Ongoing_CSP_cafeteria_Doc__c= NSP_ServiceConstants.REQUESTED;
         ip.NSP_Vision_Ongoing_CSP_cafeteria_Doc__c= NSP_ServiceConstants.REQUESTED;
         ip.NSP_Form_Completed__c=true;
        
        Test.startTest();
        //update ip record for the above fields
        update  ip;
        System.assertEquals(NSP_ServiceConstants.MILITARY_LEAVE,ip.Select_the_applicable_LOA_types__c);
        Test.stopTest();

    }
    //test method handleProjectTask
    @isTest
    public static void handleProjectTask(){
        pse__Proj__c project = [SELECT Id,Name FROM pse__Proj__c WHERE  TemplateName__c=:label.Middle_Market_Implementation_Project LIMIT 1];
        Implementation_Profile__c ip = [SELECT Id, NSP_Project__c FROM Implementation_Profile__c WHERE NSP_Project__c= :project.Id LIMIT 1];
        Contact cont = [SELECT Id,pse__Salesforce_User__c FROM Contact WHERE LastName='ResourceLN' ];
        ip.Select_the_applicable_LOA_types__c = NSP_ServiceConstants.GREATER_THAN;
        ip.Client_has_any_post_tax_deductions__c = NSP_ServiceConstants.Yes;
        ip.Client_utilizing_Insperity_s_TimeStar__c = NSP_ServiceConstants.Yes;
        ip.Do_any_EEs_have_garnishments__c=NSP_ServiceConstants.YES;
        ip.Do_any_EEs_have_tax_levies__c=NSP_ServiceConstants.YES;
        ip.Type_of_retirement_plan_client_has_today__c=NSP_ServiceConstants.CSP401K;
        ip.Does_the_client_offer_a_HSA__c =NSP_ServiceConstants.Yes;
        ip.Is_client_s_current_HSA_with_Optum_Bank__c =NSP_ServiceConstants.No;
        ip.Select_BPSes__c = NSP_ServiceConstants.INSURANCE;
        ip.Client_have_any_urgent_HR_needs__c = NSP_ServiceConstants.YES;
        ip.Select_client_urgent_HR_needs__c=NSP_ServiceConstants.SEVERANCEAGREEMENT;
        ip.Pre_tax_Client_Sponsored_Plan_CSP_Type__c=NSP_ServiceConstants.HCFSA; 
        ip.NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c = NSP_ServiceConstants.REQUESTED;
        ip.NSP_Project_Manager__c  = cont.id;
        ip.NSP_Payroll_Project_Manager__c=cont.id;
        ip.NSP_Payroll_Specialist__c=cont.id;
        ip.NSP_Form_Completed__c=true;
        Test.startTest();
        //update ip record for the above fields
        update  ip;
        System.assertEquals(NSP_ServiceConstants.CSP401K,ip.Type_of_retirement_plan_client_has_today__c);
		Test.stopTest();
    }
    //test method handleTaskCreation
    @isTest
    public static void handleTaskCreation(){
        pse__Proj__c project = [SELECT Id,Name FROM pse__Proj__c WHERE TemplateName__c=:label.Middle_Market_Implementation_Project LIMIT 1];
        Implementation_Profile__c ip = [SELECT Id, NSP_Project__c FROM Implementation_Profile__c WHERE NSP_Project__c= :project.Id LIMIT 1];
        Contact cont = [SELECT Id,pse__Salesforce_User__c FROM Contact WHERE LastName='ResourceLN' ];
      
        ip.Participants_on_COBRA_eligibility_period__c = NSP_ServiceConstants.YES;
        ip.Reviewed_deductible_carryover_w_client__c=true;
        ip.Any_EEs_with_urgent_medical_needs__c = NSP_ServiceConstants.YES;
        ip.Any_EEs_in_clients_waiting_period__c = NSP_ServiceConstants.YES;
        ip.Insperity_benefits_waiting_period__c='90 days';
        ip.Client_s_previous_waiting_period__c='30 days';
        ip.Client_want_to_begin_401k_w_NSP_setup__c = NSP_ServiceConstants.Yes;
        IP.Client_has_existing_retirement_plan__c=NSP_ServiceConstants.Yes;
        ip.Type_of_retirement_plan_client_has_today__c = NSP_ServiceConstants.PEOMULTIPLIER;
        ip.Client_has_any_of_the_following__c = NSP_ServiceConstants.STANDARD_LETTER;
        ip.Does_client_perform_background_checks__c = NSP_ServiceConstants.Yes;
        ip.Client_does_pre_employment_drug_screen__c = NSP_ServiceConstants.Yes;
        ip.Select_BPSes__c = NSP_ServiceConstants.ORGANIZATIONAL;
        ip.Select_the_applicable_LOA_types__c = NSP_ServiceConstants.SALARY;
        ip.Spnsrd_pln_when_Insperity_hndles_payroll__c=NSP_ServiceConstants.Yes;
        ip.Pre_tax_Client_Sponsored_Plan_CSP_Type__c=NSP_ServiceConstants.MEDICAL;
        ip.NSP_Medical_Ongoing_CSP_cafeteria_Doc__c=NSP_ServiceConstants.REQUESTED;
        ip.NSP_Project_Manager__c  = cont.id;
        ip.NSP_Payroll_Project_Manager__c=cont.id;
        ip.NSP_Payroll_Specialist__c=cont.id;
        ip.NSP_Form_Completed__c = true;
        Test.startTest();
        //update ip record for the above fields
        update  ip;
        System.assertEquals(NSP_ServiceConstants.PEOMULTIPLIER,ip.Type_of_retirement_plan_client_has_today__c);
		Test.stopTest();
    }
    //test method handleBPSTaskCreation
    @isTest
    public static void handleBPSTaskCreation(){
        pse__Proj__c project = [SELECT Id,Name FROM pse__Proj__c WHERE TemplateName__c=:label.Middle_Market_Implementation_Project LIMIT 1];
        Implementation_Profile__c ip = [SELECT Id, NSP_Project__c,Select_BPSes__c FROM Implementation_Profile__c WHERE NSP_Project__c =:project.Id LIMIT 1];
        Contact cont = [SELECT Id,pse__Salesforce_User__c FROM Contact WHERE LastName='ResourceLN' ];
      
        ip.Select_the_applicable_LOA_types__c = NSP_ServiceConstants.MILITARY_LEAVE;
        ip.Employees_work_in_the_following_states__c = 'CA';
        ip.Spnsrd_pln_when_Insperity_hndles_payroll__c = NSP_ServiceConstants.YES;
        ip.Sponsored_plan_contribution_type__c=NSP_ServiceConstants.PRETAX;
        ip.Client_has_any_post_tax_deductions__c=NSP_ServiceConstants.YES;
        ip.NSP_Employees_with_multiple_types_of_pay__c =NSP_ServiceConstants.HOUSINGALLOWANCE;
        ip.Pre_tax_Client_Sponsored_Plan_CSP_Type__c =NSP_ServiceConstants.DCFSA;
        ip.NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c = NSP_ServiceConstants.REQUESTED;
        ip.Client_have_any_urgent_HR_needs__c = NSP_ServiceConstants.YES;
        ip.Select_client_urgent_HR_needs__c=NSP_ServiceConstants.HANDBOOK;
        ip.Client_has_any_of_the_following__c =NSP_ServiceConstants.SUBSTANCE;
        ip.Select_BPSes__c=NSP_ServiceConstants.CERTIFY;
        ip.NSP_Project_Manager__c  = cont.id;
        ip.NSP_Payroll_Project_Manager__c=cont.id;
        ip.NSP_Payroll_Specialist__c=cont.id;
        ip.NSP_Form_Completed__c = true;
        Test.startTest();
        //update ip record for the above fields
        update  ip;
        System.assertEquals(NSP_ServiceConstants.YES,ip.Client_have_any_urgent_HR_needs__c);
		Test.stopTest();
                                                              
    }
    
}