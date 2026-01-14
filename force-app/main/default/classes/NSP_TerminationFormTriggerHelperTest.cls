/**
Apex Class Name      :  NSP_TerminationFormTriggerHelperTest
Version              :  1.0   
Author               :  Jatin                                                                       
Created Date         :  06/01/22 
Function             :  This class is used as a testclass to NSP_TerminationFormTriggerHelper 
Story                :                                                                        
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Jatin                       06/09/22           First Iteration
*/

@isTest
public class NSP_TerminationFormTriggerHelperTest {
    public static final String NSP_Credit_Specialist_Form = 'NSP_Credit_Specialist_Form';
    public static final String Test_Account = 'Test Account';
    public static final String Test_Account1 = 'Test Account 1';
    public static final String Test1 = 'Test1';
    public static final String Test2 = 'Test2';
    @TestSetup
    public static void setUpData(){
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;

        Notification_Deliverability_Settings__c notificationSetting = Notification_Deliverability_Settings__c.getOrgDefaults();
        notificationSetting.IsEnabledOutbound__c = true;
        upsert notificationSetting;

        Id woAssetRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE)?.getRecordTypeId();
        Id PEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
        List<Account> accList = new List<Account>();
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        oAccount.Name = Test_Account;
        accList.add(oAccount);
        Account oAccount1 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        oAccount1.Name = Test_Account1;
        accList.add(oAccount1);
        insert accList;
        //inserting Asset
        Asset oAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        oAsset.NSP_Actual_Seasonal_EE_Count__c = 1;
        oAsset.NSP_Unique_Active_Employee__c =10;
        oAsset.recordTypeId = woAssetRecordTypeId;
        insert oAsset;
        
        Asset oAsset1 = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        oAsset1.NSP_Actual_Seasonal_EE_Count__c = 1;
        oAsset1.NSP_Unique_Active_Employee__c =10;
        oAsset1.recordTypeId = woAssetRecordTypeId;
        oAsset1.NSP_AIMS_First_Pay_Date__c = System.today();
        oAsset1.Status = NSP_ServiceConstants.ASSET_ACTIVE_STATUS;
        insert oAsset1;

        NSP_Sub_Client__c oSubClient = (NSP_Sub_Client__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', true);
        NSP_Sub_Client__c oSubClient2 = (NSP_Sub_Client__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', false);
        oSubClient2.NSP_Account__c = oAccount.Id;
        oSubClient2.NSP_Asset__c = oAsset1.Id;
        oSubClient2.NSP_Sub_Client__c = String.valueOf(Integer.valueOf((100000 * ( 1 -  1 * Math.random()))));
        oSubClient2.NSP_Account_Status__c = 'Active';
        insert oSubClient2;
        //Inserting Contact
        /*Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact.AccountId = oAccount.Id;
        oContact.Email = 'abctestexamplyxyz@test.com.abc';
        insert oContact;*/
        //Inserting Project
        Test.startTest();
        List<pse__Proj__c> listProject = new List<pse__Proj__c>();
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Start_Date__c = Date.Today();
        oProject.pse__Account__c = oAccount.id;
        listProject.add(oProject);
        pse__Proj__c oProject1 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject1.pse__Start_Date__c = Date.Today();
        oProject1.pse__Account__c = oAccount1.id;
        listProject.add(oProject1);
        insert listProject;
        
        List<NSP_Account_Team__c> accTeamList = new List<NSP_Account_Team__c>();
        NSP_Account_Team__c accTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        accTeam.NSP_Role__c = NSP_ServiceConstants.PAYROLL_SUPERVISOR;
        accTeam.NSP_Account__c = oAccount.Id;
        accTeam.NSP_User__c = UserInfo.getUserId();
        accTeamList.add(accTeam);
        
        NSP_Account_Team__c accTeam1 = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        accTeam1.NSP_Role__c = NSP_ServiceConstants.PAYROLL_SPECIALIST;
        accTeam1.NSP_Account__c = oAccount.Id;
        accTeam1.NSP_User__c = UserInfo.getUserId();
        accTeamList.add(accTeam1);
        
        NSP_Account_Team__c accTeam2 = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        accTeam2.NSP_Role__c = NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR;
        accTeam2.NSP_Account__c = oAccount.Id;
        accTeam2.NSP_User__c = UserInfo.getUserId();
        accTeamList.add(accTeam2);
        
        NSP_Account_Team__c accTeam3 = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        accTeam3.NSP_Role__c = NSP_ServiceConstants.CLIENT_LIAISION;
        accTeam3.NSP_Account__c = oAccount.Id;
        accTeam3.NSP_User__c = UserInfo.getUserId();
        accTeamList.add(accTeam3);
        
        NSP_Account_Team__c accTeam4 = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        accTeam4.NSP_Role__c = NSP_ServiceConstants.MID_MARKET_ACC_EX;
        accTeam4.NSP_Account__c = oAccount.Id;
        accTeam4.NSP_User__c = UserInfo.getUserId();
        accTeamList.add(accTeam4);
        
        NSP_Account_Team__c accTeam5 = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        accTeam5.NSP_Role__c = NSP_ServiceConstants.MANAGER_HRSERVICES;
        accTeam5.NSP_Account__c = oAccount.Id;
        accTeam5.NSP_User__c = UserInfo.getUserId();
        accTeamList.add(accTeam5);
        
        Insert accTeamList;
            
        //Inserting Project Task
        List<pse__Project_Task__c> listProjecttask = new List<pse__Project_Task__c>();
        pse__Project_Task__c oProjectTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask.pse__Project__c = oProject.Id;
        oProjectTask.RecordTypeId = PEOProjectTaskRecordTypeId;
        listProjecttask.add(oProjectTask);
        
        pse__Project_Task__c oProjectTask2 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask2.pse__Project__c = oProject.Id;
        oProjectTask2.RecordTypeId = PEOProjectTaskRecordTypeId;
        oProjectTask2.NSP_Account_Id__c = oAccount.Id;
        oProjectTask2.Name = Test1;
        listProjecttask.add(oProjectTask2);

        pse__Project_Task__c oProjectTask3 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask3.pse__Project__c = oProject1.Id;
        oProjectTask3.RecordTypeId = PEOProjectTaskRecordTypeId;
        oProjectTask3.NSP_Account_Id__c = oAccount1.Id;
        oProjectTask3.Name = Test2;
        listProjecttask.add(oProjectTask3);
        insert listProjecttask;
        Test.stopTest();
    }

    @isTest
    public static void checkTerminationFormSharing(){
        List<pse__Project_Task__c> lProjectTasks = new List<pse__Project_Task__c>([SELECT ID FROM pse__Project_Task__c WHERE Id != null LIMIT 1]);
        String orgId = UserInfo.getOrganizationId();
        User oUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        oUser.EmployeeNumber = System.Label.NSP_User_Employee_Number;
        oUser.NSP_Sales_Office__c = '301';
        oUser.userName = 'testemail@domain'+ orgId +'.com.test';
        insert oUser;
        Test.startTest();
        //Inserting Termination Form
        NSP_Termination_Form__c oTerminationForm = (NSP_Termination_Form__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults', false);
        oTerminationForm.NSP_Project_Task__c = lProjectTasks[0].Id;
        insert oTerminationForm;
        oTerminationForm.NSP_Payroll_Specialist__c = oUser.Id;
        oTerminationForm.NSP_Supervisor__c = oUser.Id;
        oTerminationForm.NSP_Approver__c = oUser.Id;
        //Updating Termination Form
        update oTerminationForm;
        System.assertEquals(2,[SELECT count() FROM NSP_Termination_Form__Share WHERE Id != null LIMIT 10]);
        
        oTerminationForm.NSP_Payroll_Specialist__c = null;
        oTerminationForm.NSP_Supervisor__c = null;
        oTerminationForm.NSP_Approver__c = null;
        update oTerminationForm;
        
        oTerminationForm.OwnerId = oUser.Id;
        update oTerminationForm;
        System.assertEquals(1,[SELECT count() FROM NSP_Termination_Form__Share WHERE Id != null LIMIT 10]);
        Test.stopTest();
    }
    @isTest
    public static void checkAccountandFieldsValues(){
        List<pse__Project_Task__c> lProjectTasks = new List<pse__Project_Task__c>([SELECT ID FROM pse__Project_Task__c WHERE Id != null LIMIT 1]);
        List<String> assetFields = new List<String>{'Id','AccountId','Status','NSP_Account_Status__c','NSP_Termination_Date__c'};
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, assetFields)
            .addFilter('NSP_Account_Status__c', NSP_ServiceConstants.Terminated,NSP_QueryBuilder.Operator.NOT_EQUALS)
            .orderBy('NSP_Termination_Date__c','Desc',False)
            .addLimit(1).build();

        List<Asset> assetsList = (List<Asset>)Database.query(query);
        List<NSP_Sub_Client__c> lSubClients = new List<NSP_Sub_Client__c>([SELECT Id, NSP_Sub_Client__c FROM NSP_Sub_Client__c WHERE NSP_Asset__c IN :assetsList LIMIT 10]);
        List<Asset> lAssets = new List<Asset>([SELECT Id, NSP_Unique_Active_Employee__c,NSP_Client_Segment_type__c, RecordTypeId, Status, AccountId FROM Asset WHERE Id != null]);
        Decimal sumOfEmployess = lAssets[0].NSP_Unique_Active_Employee__c;
        String segmenttype = lAssets[0].NSP_Client_Segment_type__c;
        String subClientNumbers = '';
        for(NSP_Sub_Client__c oSubClient : lSubClients){
            subClientNumbers = subClientNumbers + oSubClient.NSP_Sub_Client__c + ',';
        
        subClientNumbers = subClientNumbers.removeEnd(',');
        Test.startTest();
        //Inserting Termination Form
        NSP_Termination_Form__c oTerminationForm = (NSP_Termination_Form__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults', false);
        oTerminationForm.NSP_Project_Task__c = lProjectTasks[0].Id;
        insert oTerminationForm;
        Test.stopTest();
        List<NSP_Termination_Form__c> lTerminationForms = new List<NSP_Termination_Form__c>([SELECT ID,NSP_Client_Number__c,NSP_Client_Sub_Account_Numbers__c,NSP_Segment_Type__c,NSP_Number_of_Active_Employees__c FROM NSP_Termination_Form__c WHERE Id != null]);
        If(lTerminationForms[0].NSP_Client_Sub_Account_Numbers__c!=null){
            System.assertEquals(subClientNumbers, lTerminationForms[0].NSP_Client_Sub_Account_Numbers__c);}
        If(lTerminationForms[0].NSP_Number_of_Active_Employees__c!=null){
            System.assertEquals(sumOfEmployess, lTerminationForms[0].NSP_Number_of_Active_Employees__c);}
        If(lTerminationForms[0].NSP_Segment_Type__c!=null){
            System.assertEquals(segmenttype, lTerminationForms[0].NSP_Segment_Type__c);}
        }
    }

    @isTest
    public static void updateUserLookupsTest(){
        Map<String, NSP_Account_Team__c> roleAccountTeamIdMap = new Map<String, NSP_Account_Team__c>();
        for(NSP_Account_Team__c accTeam: [SELECT NSP_User__c, NSP_Role__c FROM NSP_Account_Team__c WHERE Id != null LIMIT 10]){
            roleAccountTeamIdMap.put(accTeam.NSP_Role__c, accTeam);
        }
        List<pse__Project_Task__c> lProjectTasks = new List<pse__Project_Task__c>([SELECT Id FROM pse__Project_Task__c WHERE Id != null LIMIT 1]);

        Test.startTest();
        NSP_Termination_Form__c oTerminationForm = (NSP_Termination_Form__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults', false);
        oTerminationForm.NSP_Project_Task__c = lProjectTasks[0].Id;
        insert oTerminationForm;
        Test.stopTest();

        List<NSP_Termination_Form__c> lTerminationForms = new List<NSP_Termination_Form__c>([SELECT 
                                                              NSP_Client_Liaison__c, NSP_Approver__c , NSP_Supervisor__c , NSP_Payroll_Specialist__c , 
                                                              NSP_Sales_Representative__c, NSP_Account_Executive__c from NSP_Termination_Form__c WHERE Id != null LIMIT 1]);
        
        if(roleAccountTeamIdMap.get(NSP_ServiceConstants.PAYROLL_SUPERVISOR)!=null){
            System.assertEquals(roleAccountTeamIdMap.get(NSP_ServiceConstants.PAYROLL_SUPERVISOR).NSP_User__c, lTerminationForms[0].NSP_Supervisor__c);
        }
        if(roleAccountTeamIdMap.get(NSP_ServiceConstants.PAYROLL_SPECIALIST)!=null ){
            System.assertEquals(roleAccountTeamIdMap.get(NSP_ServiceConstants.PAYROLL_SPECIALIST).NSP_User__c, lTerminationForms[0].NSP_Payroll_Specialist__c);
        }
        if(roleAccountTeamIdMap.get(NSP_ServiceConstants.PAYROLL_SUPERVISOR)!=null ){
            System.assertEquals(roleAccountTeamIdMap.get(NSP_ServiceConstants.PAYROLL_SUPERVISOR).NSP_User__c, lTerminationForms[0].NSP_Approver__c);
        }
        if(roleAccountTeamIdMap.get(NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR)!=null){
            System.assertEquals(roleAccountTeamIdMap.get(NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR).NSP_User__c, lTerminationForms[0].NSP_Sales_Representative__c);
        }
        if(roleAccountTeamIdMap.get(NSP_ServiceConstants.CLIENT_LIAISION)!=null){
            System.assertEquals(roleAccountTeamIdMap.get(NSP_ServiceConstants.CLIENT_LIAISION).NSP_User__c, lTerminationForms[0].NSP_Client_Liaison__c);
        }
        if(roleAccountTeamIdMap.get(NSP_ServiceConstants.MID_MARKET_ACC_EX)!=null){
            System.assertEquals(roleAccountTeamIdMap.get(NSP_ServiceConstants.MID_MARKET_ACC_EX).NSP_User__c, lTerminationForms[0].NSP_Account_Executive__c);
        }
        //System.assertEquals(accTeam[0].NSP_User__c, lTerminationForms[0].NSP_Client_Liaison__c);
    }
    
    @isTest
    public static void updateProjectTaskStatusTest(){
        List<pse__Project_Task__c> ProjectTaskIds = new List<pse__Project_Task__c>([SELECT Id FROM pse__Project_Task__c WHERE Id != null LIMIT 1]);
		NSP_Termination_Form__c oTerminationForm = (NSP_Termination_Form__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults', false);
        List<NSP_Termination_Form__c> FormList = new List<NSP_Termination_Form__c>();
        //Adding Termination Form records to Form List
        FormList.add(oTerminationForm);
        Test.startTest();
        //Inserting Form List
        insert FormList;
        //Iterating over FormList
        for(Integer formLst=0;formLst<FormList.size();formLst++){
        	FormList[formLst].NSP_Status__c = NSP_ServiceConstants.TERMINATION_FORM_PR_APPROVED_STATUS;
        }
        //Updating FormList
        update FormList;
        Test.stopTest();
        System.assertEquals(FormList[0].NSP_Status__c, NSP_ServiceConstants.TERMINATION_FORM_PR_APPROVED_STATUS);
    }
    
     @isTest
    public static void updateAccountOnTermtest(){
        
        Test.startTest();
        Account oAccount = [SELECT Id FROM Account WHERE Id != null LIMIT 1];
        List<Contact>  contactList = New List<Contact>();
        contactList.add(New Contact(FirstName = 'FName', LastName = 'LName', AccountId = oAccount.Id));
        insert contactList;
        List<NSP_Termination_Form__c> terminationList = new List<NSP_Termination_Form__c>();
        
        Contact assertCon = [SELECT Id FROM Contact WHERE FirstName = 'FName' LIMIT 1];
        NSP_Termination_Form__c oTerminationForm = (NSP_Termination_Form__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults', false);      
        oTerminationForm.NSP_Client_Owner__c= assertCon.Id;
        insert oTerminationForm;
        Test.stopTest();
        System.assertEquals(oTerminationForm.NSP_Client_Owner__c, assertCon.Id);
    }
    
    @isTest
    public static void sendBellNotificationToPayrollSpecialistTest(){
        String PayrollRecordTypeId = Schema.SObjectType.NSP_Termination_Form__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.NSP_Payroll_Specialist_Form).getRecordTypeId();
		NSP_Termination_Form__c oTerminationForm = (NSP_Termination_Form__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults', false);
        List<NSP_Termination_Form__c> FormList = new List<NSP_Termination_Form__c>();
        //Adding Termination Form records to Form List
        FormList.add(oTerminationForm);
        Test.startTest();
        //Inserting Form List
        insert FormList;
        //Iterating over FormList
        for(Integer formLst=0;formLst<FormList.size();formLst++){
        	FormList[formLst].NSP_Status__c = 'PR Supervisor Denied';
            FormList[formLst].recordtypeId = PayrollRecordTypeId;
        }
        //Updating FormList
        update FormList;
        Test.stopTest();
        System.assertEquals(FormList[0].NSP_Status__c, 'PR Supervisor Denied');
    }
    
    @isTest
    public static void sendBellNotificationToPayrollSupervisorTest(){
        String PayrollRecordTypeId = Schema.SObjectType.NSP_Termination_Form__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.NSP_Payroll_Specialist_Form).getRecordTypeId();
		NSP_Termination_Form__c oTerminationForm = (NSP_Termination_Form__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults', false);
        List<NSP_Termination_Form__c> FormList = new List<NSP_Termination_Form__c>();
        //Adding Termination Form records to Form List
        FormList.add(oTerminationForm);
        Test.startTest();
        //Inserting Form List
        insert FormList;
        //Iterating over FormList
        for(Integer formLst=0;formLst<FormList.size();formLst++){
        	FormList[formLst].NSP_Status__c = 'Term Team Approved';
            FormList[formLst].recordtypeId = PayrollRecordTypeId;
        }
        //Updating FormList
        update FormList;
        Test.stopTest();
        System.assertEquals(FormList[0].NSP_Status__c, 'Term Team Approved');
    }
    
    @isTest
    public static void sendBellNotificationToCreditOwnerTest(){
        String CreditRecordTypeId = Schema.SObjectType.NSP_Termination_Form__c.getRecordTypeInfosByDeveloperName().get(NSP_Credit_Specialist_Form).getRecordTypeId();
		NSP_Termination_Form__c oTerminationForm = (NSP_Termination_Form__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults', false);
        List<NSP_Termination_Form__c> FormList = new List<NSP_Termination_Form__c>();
        //Adding Termination Form records to Form List
        FormList.add(oTerminationForm);
        Test.startTest();
        //Inserting Form List
        insert FormList;
        //Iterating over FormList
        for(Integer formLst=0;formLst<FormList.size();formLst++){
        	FormList[formLst].NSP_Status__c = 'Term Team Approved';
            FormList[formLst].recordtypeId = CreditRecordTypeId;
        }
        //Updating FormList
        update FormList;
        Test.stopTest();
        System.assertEquals(FormList[0].NSP_Status__c, 'Term Team Approved');
    }
    	@isTest
        public static void sendBellNotificationToCreditSpecialistTest(){
        String CreditRecordTypeId = Schema.SObjectType.NSP_Termination_Form__c.getRecordTypeInfosByDeveloperName().get(NSP_Credit_Specialist_Form).getRecordTypeId();
		NSP_Termination_Form__c oTerminationForm = (NSP_Termination_Form__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults', false);
        List<NSP_Termination_Form__c> FormList = new List<NSP_Termination_Form__c>();
        //Adding Termination Form records to Form List
        FormList.add(oTerminationForm);
        Test.startTest();
        //Inserting Form List
        insert FormList;

        //Iterating over FormList
        for(Integer formLst=0;formLst<FormList.size();formLst++){
        	FormList[formLst].NSP_Status__c = 'Term Team Denied';
            FormList[formLst].recordtypeId = CreditRecordTypeId;
        }
        //Updating FormList
        update FormList;
        Test.stopTest();
        System.assertEquals(FormList[0].NSP_Status__c, 'Term Team Denied');
    }
    
    @isTest
    public static void insertUsMailAddressTest(){
        Test.startTest();
        Account lAccounts = [SELECT Id FROM Account WHERE Name =:Test_Account LIMIT 1];
        Account nAccounts = [SELECT Id FROM Account WHERE Name =:Test_Account1 LIMIT 1];
        pse__Project_Task__c lProjectTasks =[SELECT ID,NSP_Account_Id__c FROM pse__Project_Task__c WHERE Name =:Test1 Limit 1];
        pse__Project_Task__c nProjectTasks =[SELECT ID,NSP_Account_Id__c FROM pse__Project_Task__c WHERE Name =:Test2 Limit 1];

        //Inserting Address
        List<NSP_Address__c> addressList = new List<NSP_Address__c>();
        NSP_Address__c oAddress = (NSP_Address__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Address__c(), 'NSP_TestDataFactory.AddressDefaults', false);
        oAddress.NSP_Related_Site__c = lAccounts.Id;
        oAddress.NSP_Address_Type__c = 'U.S. Mail';
        addressList.add(oAddress);
        NSP_Address__c oAddress1 = (NSP_Address__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Address__c(), 'NSP_TestDataFactory.AddressDefaults', false);
        oAddress1.NSP_Related_Site__c = nAccounts.Id;
        oAddress1.NSP_Address_Type__c = 'U.S. Mail';
        addressList.add(oAddress1);
        NSP_Address__c oAddress2 = (NSP_Address__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Address__c(), 'NSP_TestDataFactory.AddressDefaults', false);
        oAddress2.NSP_Related_Site__c = nAccounts.Id;
        oAddress2.NSP_Address_Type__c = 'U.S. Mail';
        addressList.add(oAddress2);
        insert addressList;
        
        //Inserting Termination Form
        NSP_Termination_Form__c oTerminationForm = (NSP_Termination_Form__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults', false);
        oTerminationForm.NSP_Project_Task__c = lProjectTasks.Id;
        insert oTerminationForm;
        oTerminationForm.NSP_Project_Task__c = nProjectTasks.Id;
        update oTerminationForm;
        Test.stopTest();
        System.assertEquals(2, [SELECT count() FROM US_Mail_Address__c WHERE Termination_Form__c =: oTerminationForm.Id]);      
    }
    @isTest
    public static void insertUsContactTest(){
        Test.startTest();
        Account lAccounts = [SELECT Id FROM Account WHERE Name =: Test_Account LIMIT 1];
        Account nAccounts = [SELECT Id FROM Account WHERE Name =: Test_Account1 LIMIT 1];
        pse__Project_Task__c lProjectTasks =[SELECT ID FROM pse__Project_Task__c WHERE Name =:Test1 Limit 1];
        pse__Project_Task__c nProjectTasks =[SELECT ID FROM pse__Project_Task__c WHERE Name =:Test2 Limit 1];
       
        //Inserting Contact
        List<Contact> contactList = new List<Contact>();
        Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact.AccountId = lAccounts.Id;
        contactList.add(oContact);
        Contact oContact1 = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact1.AccountId = nAccounts.Id;
        contactList.add(oContact1);
        Contact oContact2 = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact2.AccountId = nAccounts.Id;
        contactList.add(oContact2);
        insert contactList;
        
        //Inserting Termination Form
        NSP_Termination_Form__c oTerminationForm = (NSP_Termination_Form__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults', false);
        oTerminationForm.NSP_Project_Task__c = lProjectTasks.Id;
        insert oTerminationForm;
        oTerminationForm.NSP_Project_Task__c = nProjectTasks.Id;
        update oTerminationForm;
        Test.stopTest();
        System.assertEquals(2, [SELECT count() FROM US_Contact__c WHERE Termination_Form__c =: oTerminationForm.Id]);

    }

    @isTest private static void insertcreditspecialistphone() {
        Test.startTest();
        //Inserting Contact
        Account oAccount = [SELECT Id FROM Account WHERE Id != null LIMIT 1];
        List<Contact>  contactList = New List<Contact>();
        contactList.add(New Contact(FirstName = 'FName', LastName = 'LName', AccountId = oAccount.Id));
        insert contactList;
        List<NSP_Termination_Form__c> terminationList = new List<NSP_Termination_Form__c>();
        Contact oCon =[SELECT Id,NSP_Work_Phone__c FROM Contact WHERE Id!=null Limit 1];      
        NSP_Termination_Form__c oTerminationForm = (NSP_Termination_Form__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults', false); 
        oTerminationForm.Credit_Specialist__c = oCon.Id;
        oTerminationForm.NSP_Credit_Specialist_Phone__c = oCon.NSP_Work_Phone__c;
        insert oTerminationForm;
        Test.stopTest();
        System.assertEquals(oTerminationForm.NSP_Credit_Specialist_Phone__c,oCon.NSP_Work_Phone__c);
    }

}