/**
* Represents test class forNSP_Implementationprofile_ServiceHelper
*/

@isTest(SeeAllData=false)
public class NSP_ImpprofileServiceHelper_Test {
    public static final String TEST_NAME = 'test';
    
      public static Id ipMMRecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.MMProfile).getRecordTypeId();
      public static Id fsoRecordTypeId =  Schema.SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get('FSO').getRecordTypeId();

    
        /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    @testSetup
    public static void setUpData(){
        
        User userRec = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', true);
        
        Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
		Contact con = new Contact();
        con.AccountId = acc.Id;
        con.lastName= TEST_NAME;
        con.pse__Salesforce_User__c=userRec.Id;
        con.NSP_Work_email__c='test@pwc.com';
        insert con;

        list<Implementation_Profile__c> ipListFSA = new list<Implementation_Profile__c>();
        Implementation_Profile__c impl = new Implementation_Profile__c();
        impl.RecordTypeId = fsoRecordTypeId;
        impl.NSP_Form_Completed__c = True;
        impl.Client_Profile_Information__c = 'Related Clients';
        ipListFSA.add(impl);
        
        Implementation_Profile__c impl4 = new Implementation_Profile__c();
        impl4.Client_have_will_have_any_Seasonal_EEs__c = 'No';
        impl4.RecordTypeId = ipMMRecordTypeId;
        impl4.NSP_Form_Completed__c = True;
        ipListFSA.add(impl4);
        
        /*Implementation_Profile__c impl1 = new Implementation_Profile__c();
        impl1.Insperity_benefits_waiting_period__c = '0 days';
        impl1.Client_s_previous_waiting_period__c = '0 days';
        impl1.NSP_List_Employee_Names__c = 'Test Employee ';
        ipListFSA.add(impl1);
        
        Implementation_Profile__c impl2 = new Implementation_Profile__c();
        impl2.Any_EEs_with_urgent_medical_needs__c = 'No';
        ipListFSA.add(impl2);       
        
        Implementation_Profile__c impl3 = new Implementation_Profile__c();
        impl3.NSP_Immediate_need_for_Workers_Comp_Cert__c = 'No';
        ipListFSA.add(impl3);        
        
               
        
        Implementation_Profile__c impl5 = new Implementation_Profile__c();
        impl5.NSP_Check_to_create_the_RRP_Case__c = False;
        ipListFSA.add(impl5);        
        
        Implementation_Profile__c impl6 = new Implementation_Profile__c();
        impl6.Does_the_client_offer_a_HSA__c = NSP_ServiceConstants.YES;
        impl6.Is_client_s_current_HSA_with_Optum_Bank__c = NSP_ServiceConstants.YES;
        impl6.Does_client_have_their_code_group_ID__c = NSP_ServiceConstants.YES;
        ipListFSA.add(impl6);*/
        
        Implementation_Profile__c impl7 = new Implementation_Profile__c();
        impl7.Does_the_client_offer_a_HSA__c = NSP_ServiceConstants.YES;
        impl7.Is_client_s_current_HSA_with_Optum_Bank__c = NSP_ServiceConstants.YES;
        impl7.Does_client_have_their_code_group_ID__c = NSP_ServiceConstants.NO;
        ipListFSA.add(impl7);
        
        /*Implementation_Profile__c impl8 = new Implementation_Profile__c();
        impl8.Are_there_any_EEs_on_Leave_of_Absence__c = NSP_ServiceConstants.YES;
        ipListFSA.add(impl8);*/ 
        insert ipListFSA; 
        
        //CHECK FOR EMAIL TRIGGER FOR FSO IP
        Implementation_Profile__c fsoIp = new Implementation_Profile__c();
        fsoIp.RecordTypeId = fsoRecordTypeId;
        fsoIp.Client_s_previous_payroll_provider__c='test abc';
        fsoIp.Client_does_business_in_MA_NY_or_VA__c=NSP_ServiceConstants.NO;
        fsoIp.Employees_work_in_the_following_states__c = 'NH';
        fsoIp.Effective_Date_Payroll_Worker_comp_EPLI__c=System.today();
        fsoIp.Client_maintaining_existing_EPLI_policy__c=NSP_ServiceConstants.YES;
        fsoIp.Wnt_cpy_of_Insperity_EPLI_policy_cert__c=NSP_ServiceConstants.YES;
        fsoIp.NSP_Has_the_client_s_logo_been_collected__c=NSP_ServiceConstants.YES;
        fsoIp.NSP_Does_the_client_more_FEIN__c=NSP_ServiceConstants.YES;
        fsoIp.Is_there_a_need_for_a_subaccount__c=NSP_ServiceConstants.YES;
        fsoIp.classing_req_a_new_download_for_Subacc__c=NSP_ServiceConstants.YES;
        fsoIp.Why_is_subaccount_needed__c=	'Multiple pay frequencies or pay dates';
        fsoIp.Insperity_pay_frequency__c='Weekly';
        fsoIp.remove_employee_directory_from_premier__c=NSP_ServiceConstants.YES;
        fsoIp.Client_has_Service_Contract_Act_SCA_EEs__c=NSP_ServiceConstants.YES;
        fsoIp.Have_the_SCA_EEs_been_approved__c=NSP_ServiceConstants.YES;
        fsoIp.SCA_EEs_get_wages_in_lieu_of_benefits__c=NSP_ServiceConstants.YES;
        fsoIp.Does_client_employ_ministers_or_teachers__c=NSP_ServiceConstants.YES;
        fsoIp.Check_all_tht_apply_ministers_teachers__c='Client has Teacher retirement plan which is exempt from social security';
        fsoIp.Has_form_8973_been_discussed__c=NSP_ServiceConstants.YES;
        fsoIp.Form_8973_Contact__c=TEST_NAME;
        fsoIp.Contact_Information__c=TEST_NAME;
        fsoIp.NSP_Onboarding_Specialist_Coordinator__c=con.id;
        fsoIp.NSP_Payroll_Specialist__c=con.id;
        fsoIp.NSP_Project_Manager__c=con.id;
        
        insert fsoIp;
        
         Implementation_Profile__c fsoIp1 = new Implementation_Profile__c();
        fsoIp1.RecordTypeId = fsoRecordTypeId;
        fsoIp1.Is_there_a_need_for_a_tech_package__c=NSP_ServiceConstants.YES;
        fsoIp1.Chngs_for_cafeteria_plan_questionnaire__c=NSP_ServiceConstants.YES;
        fsoIp1.List_change_s__c=TEST_NAME;
        fsoIp1.Client_s_previous_payroll_provider__c=TEST_NAME;
        fsoIp1.Will_the_owner_s_be_on_payroll__c = NSP_ServiceConstants.YES;
        fsoIp1.Client_have_any_EEs_on_F1_or_J1_Visa_s__c = NSP_ServiceConstants.YES;
        fsoIp1.NSP_Select_all_that_apply__c='IRR';
        fsoIp1.NSP_Does_the_client_offer_Stock_Options__c=NSP_ServiceConstants.YES;
        fsoIp1.First_Pay_Date__c=system.today();
        fsoIp1.Num_of_Worksite_Employees_Full_Time__c=10;
        fsoIp1.Does_the_client_offer_a_Stock_Purchase__c=NSP_ServiceConstants.YES;
        fsoIp1.Client_has_any_special_payroll_needs__c=NSP_ServiceConstants.YES;
        fsoIp1.Select_all_payroll_needs_that_apply__c='Job Costing';
        fsoIp1.Time_Entry_Method__c=NSP_ServiceConstants.XML;
        fsoIp1.NSP_Payroll_Specialist__c=con.id;
        fsoIp1.NSP_Onboarding_Specialist_Coordinator__c=con.Id;
        fsoIp1.NSP_Project_Manager__c=con.id;
        
        insert fsoIp1;
        
       
        
    }      
    
    /**
* @Description: This test method is used to cover createCaseForImplprofile method
* @Created date: 07/18/2022. 
* @return void             
*     */ 
    @isTest
    public static void createCaseTest(){
        List<Implementation_Profile__c> getListFSA = [SELECT Id,Client_Profile_Information__c 
                                                      FROM Implementation_Profile__c 
                                                      WHERE Client_Profile_Information__c = 'Related Clients' 
                                                      LIMIT 1];
        getListFSA[0].Client_Profile_Information__c = NSP_ServiceConstants.FORMERCLIENT;
        database.update(getListFSA);
        
        Test.startTest();
        List<Implementation_Profile__c> getImpProfileList = [SELECT Id,Any_EEs_with_urgent_medical_needs__c FROM Implementation_Profile__c WHERE Id != null LIMIT 1];
        getImpProfileList[0].Any_EEs_with_urgent_medical_needs__c = NSP_ServiceConstants.YES;
        getImpProfileList[0].Insperity_benefits_waiting_period__c = '90 Days';
        getImpProfileList[0].Client_s_previous_waiting_period__c = '0 Days';
        getImpProfileList[0].NSP_Immediate_need_for_Workers_Comp_Cert__c = NSP_ServiceConstants.YES;
        getImpProfileList[0].Does_the_client_offer_a_HSA__c = NSP_ServiceConstants.YES;
        getImpProfileList[0].Is_client_s_current_HSA_with_Optum_Bank__c = NSP_ServiceConstants.YES;
        getImpProfileList[0].Does_client_have_their_code_group_ID__c = NSP_ServiceConstants.YES;
        getImpProfileList[0].Are_there_any_EEs_on_Leave_of_Absence__c = NSP_ServiceConstants.YES;
        getImpProfileList[0].NSP_List_Employee_Names__c = TEST_NAME;
       
        database.update(getImpProfileList);
        Test.stopTest();
        system.assertEquals( getImpProfileList[0].NSP_Immediate_need_for_Workers_Comp_Cert__c, NSP_ServiceConstants.YES);
    }

    /* @Description: This test method is used to cover createCaseForImplprofile method
	* @Created date: 06/13/2023. 
	* @return void             
	*/ 
    @isTest
    public static void createCaseTest2() {
        Test.startTest();
        List<Implementation_Profile__c> getListCompCerts = [SELECT Id,NSP_Immediate_need_for_Workers_Comp_Cert__c FROM Implementation_Profile__c WHERE Id != null LIMIT 1];
        getListCompCerts[0].NSP_Immediate_need_for_Workers_Comp_Cert__c = NSP_ServiceConstants.YES;
        database.update(getListCompCerts);
        Test.stopTest();
        system.assertEquals( getListCompCerts[0].NSP_Immediate_need_for_Workers_Comp_Cert__c, NSP_ServiceConstants.YES);
    }
    
    /* @Description: This test method is used to cover createCaseForImplprofile method
	* @Created date: 06/13/2023. 
	* @return void             
	*/ 
    @isTest
    public static void createCaseTest3() {
        Test.startTest();
        List<Implementation_Profile__c> getListSeasonal = [SELECT Id,Client_have_will_have_any_Seasonal_EEs__c FROM Implementation_Profile__c WHERE Id != null LIMIT 1];
        getListSeasonal[0].Client_have_will_have_any_Seasonal_EEs__c = NSP_ServiceConstants.YES;
        database.update(getListSeasonal);

        List<Implementation_Profile__c> getListRRP = [SELECT Id,NSP_Check_to_create_the_RRP_Case__c FROM Implementation_Profile__c WHERE Id != null LIMIT 1];
        getListRRP[0].NSP_Check_to_create_the_RRP_Case__c = NSP_ServiceConstants.VALUE_TRUE;
        database.update(getListRRP);
        Test.stopTest();
		system.assertEquals( getListRRP[0].NSP_Check_to_create_the_RRP_Case__c , NSP_ServiceConstants.VALUE_TRUE);
        
    }
    
    /* @Description: This test method is used to cover createCaseForImplprofile method
	* @Created date: 06/13/2023. 
	* @return void             
	*/ 
    @isTest
    public static void createCaseTest4() {
        Test.startTest();
        List<Implementation_Profile__c> getListOptum = [SELECT Id,Does_client_have_their_code_group_ID__c FROM Implementation_Profile__c WHERE Does_client_have_their_code_group_ID__c=:NSP_ServiceConstants.NO];
        getListOptum[0].RecordTypeId = fsoRecordTypeId;
        getListOptum[0].NSP_Form_Completed__c = True;
        database.update(getListOptum);

        List<Implementation_Profile__c> getListMMIps = [SELECT Id,How_are_empl_hrs_reported_to_Insperity__c FROM Implementation_Profile__c WHERE RecordTypeId=:ipMMRecordTypeId];
        getListMMIps[0].How_are_empl_hrs_reported_to_Insperity__c = NSP_ServiceConstants.XML;
        getListMMIps[0].Client_have_will_have_any_Seasonal_EEs__c = NSP_ServiceConstants.YES;
        getListMMIps[0].Are_there_any_EEs_on_Leave_of_Absence__c = NSP_ServiceConstants.YES;
        getListMMIps[0].NSP_Form_Completed__c = true;  
        database.update(getListMMIps);
        Test.stopTest();
		system.assertEquals( getListMMIps[0].How_are_empl_hrs_reported_to_Insperity__c , NSP_ServiceConstants.XML);
        
    }
    
    @isTest
    public static void createEmailTest(){
        List<Implementation_Profile__c> getListIp = [SELECT Id,Form_8973_Contact__c 
                                                      FROM Implementation_Profile__c 
                                                      WHERE Form_8973_Contact__c = 'test' 
                                                      LIMIT 1];
        Test.startTest();
        getListIp[0].NSP_Form_Completed__c = true;
        getListIp[0].Client_does_business_in_MA_NY_or_VA__c=NSP_ServiceConstants.YES;
        update getListIp;
        system.assertEquals( getListIp[0].NSP_Form_Completed__c ,true);
        
        List<Implementation_Profile__c> getList = [SELECT Id,EEO__c 
                                                      FROM Implementation_Profile__c 
                                                      WHERE NSP_Select_all_that_apply__c = 'IRR' 
                                                      LIMIT 1];
        
        getList[0].NSP_Form_Completed__c = true; 
        getList[0].Employees_work_in_the_following_states__c = 'DE';
        getList[0].Client_have_any_Commission_only_EEs__c=NSP_ServiceConstants.YES;
        getList[0].Has_FLSA_team_approved__c=NSP_ServiceConstants.NO;
        update getListIp;
        system.assertEquals( getList[0].NSP_Form_Completed__c ,true);
        Test.stopTest();
        
        
    }
    
    
    @isTest
    public static void createEmailTestEECommission(){
        
        Contact con=[SELECT Id,pse__Salesforce_User__c FROM Contact WHERE Id != null LIMIT 1];
        Test.startTest();
        Implementation_Profile__c ip = new Implementation_Profile__c();
        ip.RecordTypeId = fsoRecordTypeId;
        ip.NSP_Form_Completed__c = true;
        ip.Client_have_any_Commission_only_EEs__c=NSP_ServiceConstants.YES;
        ip.Has_FLSA_team_approved__c=NSP_ServiceConstants.NO;
        ip.Employees_work_in_the_following_states__c='AK;AR;CT;IL';
        ip.Time_Entry_Method__c=NSP_ServiceConstants.XML;
        ip.Client_has_any_special_payroll_needs__c=NSP_ServiceConstants.YES;
        ip.Select_all_payroll_needs_that_apply__c='Departments';
        ip.NSP_Payroll_Specialist__c=con.id;
        ip.NSP_Project_Manager__c=con.id;
        ip.NSP_Onboarding_Specialist_Coordinator__c=con.id;
        insert ip;
        Test.stopTest();
        system.assertEquals(ip.NSP_Onboarding_Specialist_Coordinator__c,con.id);
    }
    
    @isTest
    public static void createEmailTestStock(){
        
        Contact con=[SELECT Id,pse__Salesforce_User__c FROM Contact WHERE Id != null LIMIT 1];
        Test.startTest();
        Implementation_Profile__c ip = new Implementation_Profile__c();
        ip.RecordTypeId = fsoRecordTypeId;
        ip.NSP_Form_Completed__c = true;
        ip.Employees_work_in_the_following_states__c='MN;TN;VT';
        ip.Does_the_client_offer_a_Stock_Purchase__c=NSP_ServiceConstants.YES;
        ip.NSP_Does_the_client_offer_Stock_Options__c=NSP_ServiceConstants.YES;
        ip.First_Pay_Date__c=system.today();
        ip.Num_of_Worksite_Employees_Full_Time__c=10;
        ip.NSP_Select_all_that_apply__c='IRR';
        ip.Client_have_any_EEs_on_F1_or_J1_Visa_s__c=NSP_ServiceConstants.YES;
        ip.NSP_Project_Manager__c=con.id;
        ip.NSP_Onboarding_Specialist_Coordinator__c=con.id;
        insert ip;
        Test.stopTest();
        system.assertEquals(ip.NSP_Select_all_that_apply__c,'IRR');
    }
}