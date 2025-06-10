/**

Apex Class Name      :  NSP_WXBenefitsRenewalProjCreat_Test
Version              :  1.0 
Author               :  Simran                                                                          
Created Date         :  11/12/2022
Function             :  Represents test class for NSP_WXBenefitsRenewalProjectCreation class

**/

@isTest
public class NSP_WXBenefitsRenewalProjCreat_Test
{
    // Global Variables
    private static final Id TES_BPS_RECTYPE_ID 					= NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', 'TES_BPS');
    private static Id WX_RECORDTYPE_ID 							= NSP_GenericRecordType.getRecordTypeId('Asset', 'NSP_Asset_Product');
    private static final String NSP_ROLE 						= 'WX Open Enrollment Specialist';
    private static final String NSP_PRIMARY 					= 'NSP_Primary__c';
    private static final String NAME 							= 'Name';
    private static final String ACCOUNT_TEAM_MEMBER_DEFAULTS	= 'NSP_TestDataFactory.AccountTeamMemberDefaults';
    
    
    @testSetup 
    private static void prepareTestData() 
    {
        // Create User Record
        UserRole userRole 			= NSP_sObjectSelector.selectUserRoleByName('Business Performance Advisor');
        User sysAdminUser 			= (User)NSP_TestDataFactory.createSObject(new User(),'NSP_TestDataFactory.UserDefaults', false);
        sysAdminUser.userRoleId 	= userRole.Id;
        insert sysAdminUser;
        
        System.runAs(sysAdminUser)
        {
            // Create Account    
            Account account 								= (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 
                                                                                                                 'NSP_TestDataFactory.AccountDefaults', 
                                                                                                                 false);
            account.NSP_Sales_Service_Account_Status__c 	= NSP_ServiceConstants.Account_Status; 
            insert account;
            
            // Create List of Account Team Members
            List<NSP_Account_Team__c> accountTeam 	= new List<NSP_Account_Team__c>();
            
            NSP_Account_Team__c accTeam1 			= (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject( new NSP_Account_Team__c(), ACCOUNT_TEAM_MEMBER_DEFAULTS, false );
            accTeam1.NSP_Account__c 				= account.Id;
            accTeam1.NSP_Role__c 					= 'WX Open Enrollment Specialist';
            accTeam1.NSP_Primary__c 				= true;
            
            accountTeam.add(accTeam1);
            
            NSP_Account_Team__c accTeam2 			= (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject( new NSP_Account_Team__c(), ACCOUNT_TEAM_MEMBER_DEFAULTS, false );
            accTeam2.NSP_Account__c 				= account.Id;
            accTeam2.NSP_Role__c 					= 'WX Open Enrollment Specialist';
            accTeam2.NSP_Primary__c 				= false;
            
            accountTeam.add(accTeam2);
            
            insert accountTeam;
            
            // Create Asset
            Asset assetObj 								= (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
            assetObj.accountId 							= account.Id;
            assetObj.name								= 'Test';
            assetObj.NSP_Renewal_Date__c 				= system.today().addDays(75);
            assetObj.Medical_Benefits_Renewal_Date__c 	= system.today().addDays(75);
            assetObj.Ancillary_Benefits_Renewal_Date__c = system.today().addDays(75);
            assetObj.Fringe_Benefits_Renewal_Date__c 	= system.today().addDays(75);
            assetObj.RecordTypeId 						= WX_RECORDTYPE_ID;
            
            insert assetObj;
            
            // Create Custom Setting
            Benefits_Renewal_Batch_Settings__c customObject = new Benefits_Renewal_Batch_Settings__c();
            customObject.Name 						= 'Test';
            customObject.IsEnabledAncillary_c__c 	= true;
            customObject.IsEnabledDefault__c 		= true;
            customObject.IsEnabledFringe__c 		= true;
            
            insert customObject;
        }
    }
    /** Test Project specific logic related to batch class */
    @isTest
    private static void testProjectCreate()
    {
        pse__Proj__c project 		= (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        project.Name 				= 'WX Benefits Renewal Project';
        project.recordTypeId 		= TES_BPS_RECTYPE_ID ;
        project.TemplateName__c 	= NSP_ServiceConstants.WX_BENEFIT_RENEW_PROJ;
        project.pse__Start_Date__c 	= System.today();
        insert project;
        
        List<Asset> assetList = [SELECT ID, RecordTypeId, AccountId, Status  FROM Asset LIMIT 1];
        Test.startTest();
        
        
        // To cover the managed package logic
        WXBenefitsRenewalProjectHelper helperClass 	= new WXBenefitsRenewalProjectHelper();
        helperClass.opp 							= new NSP_OpportunityTriggerServiceHelper(new Set<Id>{ project.Id });
        helperClass.createProjectFromTemplateBasedOnAccountAndAsset(assetList);
        Test.stopTest();
    }
    
    /** Test Project specific logic related to batch class for sending the email */
    @isTest
    private static void testSendEmailWithNoDesiredAccountTeamMemberRole()
    {
        pse__Proj__c project 		= (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        project.Name 				= 'WX Benefits Renewal Project';
        project.recordTypeId 		= TES_BPS_RECTYPE_ID ;
        project.TemplateName__c 	= NSP_ServiceConstants.WX_BENEFIT_RENEW_PROJ;
        project.pse__Start_Date__c 	= System.today();
        insert project;
        
        List<Asset> assetList = [SELECT ID, RecordTypeId, AccountId, Status  FROM Asset LIMIT 1];
        
        Account account = [SELECT ID FROM Account LIMIT 1];
        
        Delete[SELECT ID FROM NSP_Account_Team__c];
        
        NSP_Account_Team__c accTeam2 			= (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject( new NSP_Account_Team__c(), ACCOUNT_TEAM_MEMBER_DEFAULTS, false );
        accTeam2.NSP_Account__c 				= account.Id;
        accTeam2.NSP_Role__c 					= 'WX/WA Benefits Specialist';
        accTeam2.NSP_Primary__c 				= false;
        
        insert accTeam2;
        
        Test.startTest();
        
        // To cover the managed package logic
        WXBenefitsRenewalProjectHelper helperClass 	= new WXBenefitsRenewalProjectHelper();
        helperClass.opp 							= new NSP_OpportunityTriggerServiceHelper(new Set<Id>{ project.Id });
        helperClass.createProjectFromTemplateBasedOnAccountAndAsset(assetList);
        Test.stopTest();
    }
    /** Test Project specific logic related to batch class for sending the email */
    @isTest
    private static void testSendEmailWithNoDesiredAccountTeamMembers()
    {
        pse__Proj__c project 		= (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        project.Name 				= 'WX Benefits Renewal Project';
        project.recordTypeId 		= TES_BPS_RECTYPE_ID ;
        project.TemplateName__c 	= NSP_ServiceConstants.WX_BENEFIT_RENEW_PROJ;
        project.pse__Start_Date__c 	= System.today();
        insert project;
        
        List<Asset> assetList = [SELECT ID, RecordTypeId, AccountId, Status  FROM Asset LIMIT 1];
        
        Account account = [SELECT ID FROM Account LIMIT 1];
        
        Delete[SELECT ID FROM NSP_Account_Team__c];
        
        Test.startTest();
        
        // To cover the managed package logic
        WXBenefitsRenewalProjectHelper helperClass 	= new WXBenefitsRenewalProjectHelper();
        helperClass.opp 							= new NSP_OpportunityTriggerServiceHelper(new Set<Id>{ project.Id });
        helperClass.createProjectFromTemplateBasedOnAccountAndAsset(assetList);
        Test.stopTest();
    }
    
    /** Test Scheduler Batch all in one go */
    @isTest
    private static void testSchedulerBatch()
    {
        Test.startTest();
        NSP_WXBenefitsRenewalProjectCreation.schedule();
        Test.stopTest();
    }
}