/**

Apex Class Name      :  NSP_WXBenefitsRenewalProjCreat_Test
Version              :  1.0 
Author               :  Simran                                                                          
Created Date         :  11/12/2022
Function             :  Represents test class for NSP_WXBenefitsRenewalProjectCreation class

**/

@isTest
public class NSP_WXBenefitsRenewalProjCreat_Test {
  private static final Id TES_BPS_RECTYPE_ID = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', 'TES_BPS');
  private static Id WX_RECORDTYPE_ID = NSP_GenericRecordType.getRecordTypeId('Asset', 'NSP_Asset_Product');
  private static final String NSP_ROLE = 'NSP_Role__c';
  private static final String NSP_PRIMARY = 'NSP_Primary__c';
  private static final String NAME = 'Name';
  private static final String ACCOUNT_TEAM_MEMBER_DEFAULTS= 'NSP_TestDataFactory.AccountTeamMemberDefaults';
  //Setting Up data  
  @testSetup 
  static void testData() {
    //start test
    Test.startTest();
    Profile profileobj = [SELECT Id FROM Profile WHERE Name='System Administrator'];
    UserRole userRole = [SELECT Id FROM UserRole WHERE Name='Business Performance Advisor'];
    User BpaUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
    BpaUser.alias = 'jsmit';
    BpaUser.email='jsmith@insperity.com';
    BpaUser.emailencodingkey='UTF-8';
    BpaUser.lastname='Smith';
    BpaUser.languagelocalekey='en_US';
    BpaUser.profileid = profileobj.Id;
    BpaUser.userroleid = userRole.Id;
    BpaUser.localesidkey='en_US'; 
    BpaUser.timezonesidkey='America/Los_Angeles';
    BpaUser.username='insperitytestadminuser@insperity.com.testUsr';
        
    List<NSP_Account_Team__c> accountTeam = new List<NSP_Account_Team__c>();        
    //inserting Account Records
    Account acct = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
    acct.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.Account_Status; 
    insert acct;
    
    //inserting account
    Account acct2 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
    acct2.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.Account_Status; 
    acct2.name= 'Testing New Account Insert';
    insert acct2;

    system.runAs(new user(ID = UserInfo.getUserID())){
      //inserting BPA user 
      insert BpaUser;
      NSP_Account_Team__c accTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), ACCOUNT_TEAM_MEMBER_DEFAULTS, false);
      accTeam.NSP_Account__c = acct.Id;
      accTeam.NSP_Role__c = NSP_ServiceConstants.WXWA_BENEFITS;
      accTeam.NSP_User__c = BpaUser.Id;
      accTeam.NSP_Primary__c = true;
      //inserting account Team
      Insert accTeam;
    }
    
    NSP_Account_Team__c accTeam2 = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), ACCOUNT_TEAM_MEMBER_DEFAULTS, false);
    accTeam2.NSP_Account__c = acct.Id;
    accTeam2.NSP_Role__c = NSP_ServiceConstants.WXWA_BENEFITS;
    accountTeam.add(accTeam2);
    
    NSP_Account_Team__c accTeam3 = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), ACCOUNT_TEAM_MEMBER_DEFAULTS, false);
    accTeam3.NSP_Account__c = acct.Id;
    accTeam3.NSP_Role__c = NSP_ServiceConstants.BENEFITS_SPECIALIST;
    accTeam3.NSP_Primary__c = true;
    accountTeam.add(accTeam3);
    
    NSP_Account_Team__c accTeam4 = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), ACCOUNT_TEAM_MEMBER_DEFAULTS, false);
    accTeam4.NSP_Account__c = acct2.Id;
    accTeam4.NSP_Role__c = NSP_ServiceConstants.BENEFITS_SPECIALIST;
    accountTeam.add(accTeam4);
    //inserting more account Teams to check for correct user to be assigned
    insert accountTeam;
    //asserts matching with the batch class scenerio
    List<Asset> assetList = new List<Asset>();
    Asset assetObj = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
    assetObj.accountId = acct.Id;
    assetObj.name= 'Test';
    assetObj.NSP_Renewal_Date__c = system.today().addDays(65);
    assetObj.NSP_Benefits_Renewal_Date__c = system.today().addDays(65);
    assetObj.RecordTypeId = WX_RECORDTYPE_ID;
    assetList.add(assetObj);
    
    Asset assetObj2 = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
    assetObj2.accountId = acct2.Id;
    assetObj2.name= 'Test 2';
    assetObj2.NSP_Renewal_Date__c = system.today().addDays(65);
    assetObj2.NSP_Benefits_Renewal_Date__c = system.today().addDays(65);
    assetObj2.RecordTypeId = WX_RECORDTYPE_ID;
    assetList.add(assetObj2);
    insert assetList;
    Test.stopTest();
    //stop test
  }
  
  //if account team has two benefit specialist with one primary checked
  @isTest
  static void testProjOFBenefitRenewalTemplateBatch(){
    //inserting project for test data
    pse__Proj__c project = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
    project.Name = 'WX Benefits Renewal Project';
    project.recordTypeId = TES_BPS_RECTYPE_ID ;
    project.TemplateName__c = NSP_ServiceConstants.WX_BENEFIT_RENEW_PROJ;
    project.pse__Start_Date__c = System.today();
    insert project;
        
    //start test
    Test.startTest();
    // executes the batch class
    NSP_WXBenefitsRenewalProjectCreation batchClass = new NSP_WXBenefitsRenewalProjectCreation();
    batchClass.opp = new NSP_OpportunityTriggerServiceHelper(new Set<Id>{ project.Id });
    Database.executeBatch(batchClass, 200); 
      
    //stop test
    Test.stopTest();

    //querying the proj after running batch class
    pse__Proj__c proj = [SELECT Id,Name, TemplateName__c, pse__Start_Date__c , recordTypeId, Project_Implementer__c FROM pse__Proj__c WHERE pse__Start_Date__c=:System.today() AND TemplateName__c =: NSP_ServiceConstants.WX_BENEFIT_RENEW_PROJ LIMIT 1];
    // querying accountteam who user is expected to be assigned
    List<String> accTeamFields = new List<String>{'Id',NAME,NSP_ROLE,'NSP_Account__c', 'NSP_User__c', NSP_PRIMARY};
    String accTeam = new NSP_QueryBuilder('NSP_Account_Team__c', accTeamFields)
    .addFilter(NSP_PRIMARY, true) 
    .addFilter(NSP_ROLE, NSP_ServiceConstants.WXWA_BENEFITS).addLimit(1).build();
        
    NSP_Account_Team__c accTeamRec = Database.query(accTeam);
    System.assertEquals(proj.Project_Implementer__c, accTeamRec.NSP_User__c);
  }

  // when ther is no benefit specialist record on account
  @isTest
  static void testProjOFBenefitRenewalTemplateWithNOBenefitSpecialistBatch(){
    //querying account which has no record which has no benefit specialist account team
    List<String> acctField = new List<String>{'Id',NAME,'NSP_Sales_Service_Account_Status__c'};
    String query = new NSP_QueryBuilder('Account', acctField)
        .addFilter(NAME, 'Testing New Account Insert').addLimit(1).build(); 
    Account acct = Database.query(query);
    
    pse__Proj__c project = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
    project.Name = 'WX Benefits Renewal Project';
    project.recordTypeId = TES_BPS_RECTYPE_ID ;
    project.pse__Account__c = acct.Id ;
    project.TemplateName__c = NSP_ServiceConstants.WX_BENEFIT_RENEW_PROJ;
    project.pse__Start_Date__c = System.today();
    insert project;
    
    //start test
    Test.startTest();

    //executes the batch class
    NSP_WXBenefitsRenewalProjectCreation batchClass = new NSP_WXBenefitsRenewalProjectCreation();
    batchClass.opp = new NSP_OpportunityTriggerServiceHelper(new Set<Id>{ project.Id });
    Database.executeBatch(batchClass, 200); 
    
    Test.stopTest();
    //stop test

    //querying projects after calling batch
    pse__Proj__c proj = [SELECT Id,Name, TemplateName__c, pse__Start_Date__c , recordTypeId,OwnerId, Project_Implementer__c FROM pse__Proj__c WHERE pse__Start_Date__c=:System.today() AND TemplateName__c =: NSP_ServiceConstants.WX_BENEFIT_RENEW_PROJ LIMIT 1];
    
    //query to Account Team 
    List<String> accTeamFields = new List<String>{'Id',NAME,NSP_ROLE,'NSP_Account__c', 'NSP_User__c', NSP_PRIMARY};
    String accTeam = new NSP_QueryBuilder('NSP_Account_Team__c', accTeamFields)
    .addFilter(NSP_PRIMARY, true) 
    .addFilter(NSP_ROLE, NSP_ServiceConstants.WXWA_BENEFITS).addLimit(1).build();
        
    NSP_Account_Team__c accTeamRec = Database.query(accTeam);
    //assertion project Implementor field is un assigned
    System.assertNotEquals(proj.Project_Implementer__c, accTeamRec.NSP_User__c);
  }
}