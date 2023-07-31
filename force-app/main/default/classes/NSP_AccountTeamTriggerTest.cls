/**
* Represents test class for AccountTeam Trigger helper 
* Represents test class for AccountTeam Trigger Handler
* Created by : Hemali Patel
* Created Date : 8/11/2021
*/
@isTest(SeeAllData=false)
public without sharing class NSP_AccountTeamTriggerTest {
    
    private static final string EMP_PER_ID = 'EMP 1234';
    /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    @testSetup
    static void testData() {
        User userObj = NSP_TestHelper.createUser(false);
        userObj.NSP_Employee_Per_ID__c = EMP_PER_ID;
        userObj.NSP_Service_Region__c = 'MMSO - Houston';
        insert userObj;
        
        NSP_TestHelper.createAccount(true);
        String PEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
        Id peoProjectRecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
         
        Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        insert acc;
        
        List<pse__Proj__c> lstProject = new List<pse__Proj__c>();
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Account__c = acc.Id;
        oProject.pse__Start_Date__c = system.today();
        oProject.pse__End_Date__c = system.today().addDays(10);
        oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.RecordTypeId = peoProjectRecordTypeId;
        lstProject.add(oProject);
        pse__Proj__c oProject1 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject1.pse__Account__c = acc.Id;
        oProject1.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject1.TemplateName__c = label.FSOImplementationProject;
        oProject1.RecordTypeId = peoProjectRecordTypeId;
        lstProject.add(oProject1);
        insert lstProject;
        
        pse__Milestone__c milestone = (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), 'NSP_TestDataFactory.MileStoneDefaults', false);
        milestone.pse__Project__c = oProject.id;
        insert milestone;
        
        pse__Project_Task__c oProjectTask1 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask1.pse__Project__c = oProject.Id;
        oProjectTask1.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_CANCELLED;
        oProjectTask1.pse__Milestone__c = milestone.id;
        oProjectTask1.NSP_Template_Generated__c = true;
        oProjectTask1.RecordTypeId = PEOProjectTaskRecordTypeId;
        insert oProjectTask1;

        //Added as part of STY-03667
        //Account team insertion
        NSP_Account_Team__c accTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', true);
		accTeam.NSP_Primary__c=true;
        accTeam.NSP_User__c=userObj.Id;
        update accTeam;
        
    }
    
    /**
* Checks the update insert logic of the trigger
* @param N/A. 
* @return void                          
*/    
    @isTest
    public static void testInsert(){
        Account accountObj = [SELECT Id,Name from Account WHERE Name !=null limit 1];
        
        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_PER_ID__c = EMP_PER_ID;
        accTeam.NSP_Role__c = 'Recruiting';
        test.startTest();
        insert accTeam;
        test.stopTest(); 
        User userObj = [SELECT Id FROM User WHERE NSP_Employee_Per_ID__c =: EMP_PER_ID];
        NSP_Account_Team__c accTeamObj = [SELECT Id,NSP_User__c FROM NSP_Account_Team__c WHERE NSP_Account__c =: accountObj.Id limit 1];
        system.assertEquals(userObj.Id, accTeamObj.NSP_User__c);
    }
    
    /**
* Checks the update update logic of the trigger
* @param N/A. 
* @return void                          
*/     
    @isTest
    public static void testUpdate(){
        Account accountObj = [SELECT Id,Name from Account WHERE Name !=null limit 1];
        
        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_PER_ID__c = EMP_PER_ID;
        accTeam.NSP_Role__c = 'Recruiting';
        insert accTeam;
        
        NSP_Account_Team__c accountTeamObj = [SELECT Id from NSP_Account_Team__c WHERE
                                              NSP_Account__c =: accountObj.Id Limit 1];
        
        accountTeamObj.NSP_Role__c = 'HR Specialist';
        test.startTest();
        update accountTeamObj;
        test.stopTest();  
        
        NSP_Account_Team__c accountTeam = [SELECT Id,NSP_Role__c from NSP_Account_Team__c 
                                           WHERE NSP_Account__c =: accountObj.Id Limit 1];
        
        system.assertEquals('HR Specialist', accountTeam.NSP_Role__c);
    }
    
    @isTest
    public static void testInsertAccountClientLiaison(){
        
        //GIVEN
        Account accountObj = [SELECT Id,Name from Account WHERE Id!=null limit 1];
       
        test.startTest();
        List<NSP_Account_Team__c> lstAccTeam = new List<NSP_Account_Team__c>();
        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_PER_ID__c = EMP_PER_ID;
        accTeam.NSP_User__c = UserInfo.getUserId();
        accTeam.NSP_Role__c = NSP_ServiceConstants.CLIENT_LIAISION;
        lstAccTeam.add(accTeam);
        insert lstAccTeam;
        pse__Project_Task__c pt = [SELECT Id,NSP_CC_Emails__c,NSP_Client_Liaison_Name__c,NSP_HR_Specialist_Email__c,NSP_AccountId__c,
                                   NSP_HR_Specialist_Name__c,NSP_Client_Liaison_Email__c FROM pse__Project_Task__c WHERE Id!=null limit 1];
        
        system.assertNotEquals(pt.NSP_Client_Liaison_Email__c, userInfo.getUserEmail());
        test.stopTest();
    } 
     /**
* @Description: This test method test the method in AccountTeamTriggerHelper
* @Created date: 13/10/2022. 
* @return void             
*     */
    @isTest
    public static void updateAccountTeamNameToAssetNameTest(){
        
        //Account accountObj = [SELECT Id,Name FROM Account LIMIT 1];
        Test.startTest();
        Account accountObject = new Account(Name='TestAccountTeamObject');
        INSERT accountObject;
        Asset assetObject = new Asset(Name= 'TestAccountTeam',AccountId= accountObject.Id,CurrencyIsoCode= 'USD' );
        INSERT assetObject;
        NSP_Account_Team__c accountTeamObject = new NSP_Account_Team__c();
        accountTeamObject.NSP_Account__c = accountObject.Id;
        accountTeamObject.NSP_PER_ID__c = EMP_PER_ID;
        accountTeamObject.NSP_User__c = UserInfo.getUserId();
        accountTeamObject.NSP_Role__c = NSP_ServiceConstants.WXWA_BENEFITS;
        INSERT accountTeamObject;
        
        Asset assetObject1 = [SELECT ID, AccountId, NSP_WX_WA_Benefits_Specialist__c FROM Asset WHERE AccountId=: accountObject.Id ];
        System.Assert(String.isNotBlank(assetObject1.NSP_WX_WA_Benefits_Specialist__c));
  
		accountTeamObject.NSP_Role__c = NSP_ServiceConstants.WXWA_PAYROLL;
		UPDATE accountTeamObject;
		assetObject1 = [SELECT ID, AccountId, NSP_WA_WX_Payroll_Specialist__c FROM Asset WHERE AccountId=: accountObject.Id];
        System.Assert(String.isNotBlank(assetObject1.NSP_WA_WX_Payroll_Specialist__c));

		accountTeamObject.NSP_Role__c = NSP_ServiceConstants.PLAN_CONSULTANT;
		UPDATE accountTeamObject;
		assetObject1 = [SELECT ID, AccountId, NSP_Retirement_Service_Plan_Name__c FROM Asset WHERE AccountId =: accountObject.Id];
        System.Assert(String.isNotBlank(assetObject1.NSP_Retirement_Service_Plan_Name__c));
        Test.stopTest();
    } 
    
    @isTest
    public static void testInsertAccountHRSpecialist(){
        Account accountObj = [SELECT Id,Name from Account WHERE Id!=null limit 1];
        
        test.startTest();
        List<NSP_Account_Team__c> lstAccTeam = new List<NSP_Account_Team__c>();
        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_PER_ID__c = EMP_PER_ID;
        accTeam.NSP_User__c = UserInfo.getUserId();
        accTeam.NSP_Role__c = NSP_ServiceConstants.HRSpecialist;
        lstAccTeam.add(accTeam);
        insert lstAccTeam;
        pse__Project_Task__c pt = [SELECT Id,NSP_CC_Emails__c,NSP_Client_Liaison_Name__c,NSP_HR_Specialist_Email__c,NSP_AccountId__c,
                                   NSP_HR_Specialist_Name__c,NSP_Client_Liaison_Email__c FROM pse__Project_Task__c WHERE Id!=null limit 1];
        
        system.assertNotEquals(pt.NSP_Client_Liaison_Email__c, userInfo.getUserEmail());
        test.stopTest();
    }
    
    @isTest
    public static void testInsertBoth(){
        Account accountObj = [SELECT Id,Name from Account WHERE Id!=null limit 1];
        test.startTest();
        List<NSP_Account_Team__c> lstAccTeam = new List<NSP_Account_Team__c>();
        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_PER_ID__c = EMP_PER_ID;
        accTeam.NSP_User__c = UserInfo.getUserId();
        accTeam.NSP_Role__c = NSP_ServiceConstants.BUS_TEAM_HRSP_CL;
        lstAccTeam.add(accTeam);
        insert lstAccTeam;
        pse__Project_Task__c pt = [SELECT Id,NSP_CC_Emails__c,NSP_Client_Liaison_Name__c,NSP_HR_Specialist_Email__c,NSP_AccountId__c,
                                   NSP_HR_Specialist_Name__c,NSP_Client_Liaison_Email__c FROM pse__Project_Task__c WHERE Id!=null LIMIT 1];
        
        system.assertNotEquals(pt.NSP_Client_Liaison_Email__c, userInfo.getUserEmail());
        test.stopTest();
    }

    /***********************************************************************************************
	* MethodName: testErrorOnAccountTeamInsert
	* Description : unit test for account team insert error message
    * Added as part of STY-03667
	* ********************************************************************************************/    
    @isTest
    static void testErrorOnAccountTeam() {
        //GIVEN
        Account accountObj = [SELECT Id,Name from Account WHERE Id!=null limit 1];
        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_PER_ID__c = EMP_PER_ID;
        accTeam.NSP_User__c = UserInfo.getUserId();
        accTeam.NSP_Role__c = NSP_ServiceConstants.CLIENT_LIAISION;
        accTeam.NSP_Primary__c=True;
        
        Test.startTest();
        try{
        	insert accTeam;
        }catch (Exception ex){
            //test positive assertion on insertion record not inserted successfully and throws validation
            system.assertEquals('System.DmlException',ex.getTypeName());
    	}
        accTeam.NSP_Primary__c=false;
        insert accTeam;
        List<NSP_Account_Team__c> accTeamList = [SELECT Id,NSP_Role__c 
                                                 FROM NSP_Account_Team__c
                                                 WHERE NSP_Role__c=:NSP_ServiceConstants.CLIENT_LIAISION ];
        //test assertion negative scenario record saved successfully
        system.assertEquals(2, accTeamList.size());
        accTeam.NSP_Primary__c=true;
        try{
        	update accTeam;
        }catch (Exception ex){
            //test assertion on update record not updated and throws validation
            system.assertEquals('System.DmlException',ex.getTypeName());
    	}
		Test.stopTest();
      
    }
    
    /**
    * @Description: This test method is used to cover updateAssetServiceRegion method
    * @Created date: 12/02/2022. 
    * @return void             
    */
    
    @isTest
    static void updateAssetServiceRegionTest() {
        Test.startTest();
        User user = [SELECT Id, NSP_Service_Region__c FROM User WHERE Id!=null LIMIT 1];
        Account accountObj = [SELECT Id, Name From Account WHERE Id!=null LIMIT 1];
        Id woRecord = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE );
        
        Asset asset = new Asset();
        Asset.Name = 'Test Asset';
        asset.RecordTypeId = woRecord;
        asset.AccountId = accountObj.Id;
        asset.NSP_Account_Status__c = 'Active';
        insert asset;
        
        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_User__c = user.Id;
        accTeam.NSP_Role__c = 'Manager, HR Services';
        Insert accTeam;

        Test.stopTest();
        system.Assert(user.NSP_Service_Region__c == Asset.NSP_Service_Region__c);
        
    }

    /***********************************************************************************************
	* MethodName: testUserUpdateOnAccountTeam
	* Description : unit test for account team -user Update
    * Added as part of DF-03716
	* ********************************************************************************************/    
    @isTest
    static void testUserUpdateOnAccountTeam() {
        //GIVEN
        User userObj = [SELECT Id from User WHERE NSP_Employee_Per_ID__c = 'EMP 1234'];
        NSP_Account_Team__c accTeam = [SELECT Id,NSP_Role__c,NSP_PER_ID__c 
                                                 FROM NSP_Account_Team__c
                                                 WHERE Id != null
                                                 LIMIT 1 ];
        
        test.startTest();
        accTeam.NSP_User__c = userObj.Id;
        update accTeam;
        test.stopTest();  
        system.assertEquals(accTeam.NSP_User__c, userObj.Id );
    }

    /**
    * @Description: This test method is used to cover validationOnDeletionOfAccountTeam
    * @Created date: 6/5/2023. 
    * @return void             
    ***********************************/
    @isTest
    private static void validationOnDeletionOfAccountTeamTest(){
        List<String> accountTeamFields = new List<String>{'Id','NSP_Account__c'};
        Account accountObj = [SELECT Id, Name FROM Account WHERE Id != null LIMIT 1];
        
        List<NSP_Account_Team__c> lstAccTeam = new List<NSP_Account_Team__c>();
        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_PER_ID__c = EMP_PER_ID;
        accTeam.NSP_User__c = UserInfo.getUserId();
        accTeam.NSP_Role__c = NSP_ServiceConstants.BUS_TEAM_HRSP_CL;
        lstAccTeam.add(accTeam);
        insert lstAccTeam;
        
        Test.startTest();
        database.delete(lstAccTeam);
        Test.stopTest();
        
        String accTeamQuery = new NSP_QueryBuilder('NSP_Account_Team__c', accountTeamFields).addFilter('NSP_Account__c', accountObj.Id).addLimit(1).setSecurityEnforce(false).build();
        List<NSP_Account_Team__c> accTeamList =  Database.query(accTeamQuery);
        
      system.assertEquals(accTeamList.isEmpty(), false);       
    }
}