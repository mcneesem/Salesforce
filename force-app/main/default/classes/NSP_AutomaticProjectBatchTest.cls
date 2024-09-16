@isTest
public class NSP_AutomaticProjectBatchTest {

    //Setting up test data
    @testSetup
    public static void setupProjectdata(){
        
        Id assert_WORTId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
       
        //Creating Account
        List<Account> accList = new List<Account>();
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        oAccount.Name = 'Account Test1';
        accList.add(oAccount);
        //Creating Account
        Account oAccount1 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        oAccount1.Name = 'Account Test2';
        accList.add(oAccount1);
        Account oAccount2 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        oAccount2.Name = 'Account Test3';
        accList.add(oAccount2);
        if(!accList.isEmpty()){
            Database.insert(accList);
        }
        
        List<NSP_Account_Team__c> accTeamList = new List<NSP_Account_Team__c>();
        //Creating Account Team for the account
        NSP_Account_Team__c oAccountTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        oAccountTeam.NSP_Role__c = NSP_ServiceConstants.MANAGER_HRSERVICES;
        oAccountTeam.NSP_Account__c = oAccount.Id;
        accTeamList.add(oAccountTeam);
        //Creating Account Team for the account
        NSP_Account_Team__c oAccountTeam1 = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        oAccountTeam1.NSP_Role__c = NSP_ServiceConstants.MANAGER_HRSERVICES;
        oAccountTeam1.NSP_Account__c = oAccount1.Id;
        accTeamList.add(oAccountTeam1);
        NSP_Account_Team__c oAccountTeam2 = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        oAccountTeam2.NSP_Role__c = NSP_ServiceConstants.MANAGER_HRSERVICES;
        oAccountTeam2.NSP_Account__c = oAccount2.Id;
        accTeamList.add(oAccountTeam2);
        if(!accTeamList.isEmpty()){
            Database.insert(accTeamList);
        }
        
        List<Asset> assetList = new List<Asset>();
        // Creating Asset
        Asset oAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        oAsset.AccountId = oAccount.Id;
        oAsset.Name = 'Test Asset1';
        oAsset.RecordTypeId = assert_WORTId;
        oAsset.NSP_Account_Status__c = NSP_ServiceConstants.AIMS_STATUS;
        oAsset.NSP_Account_Status_Date__c = System.today();
        oAsset.NSP_Client_Segment_type__c = NSP_ServiceConstants.BTAssetSegment;
        oAsset.NSP_Product_Line__c = NSP_ServiceConstants.INSURANCE;
        oAsset.NSP_ProductBundle__c = NSP_ServiceConstants.WA_PRODUCT_BUNDLE;
        oAsset.Status = NSP_ServiceConstants.ONBOARDING;
        assetList.add(oAsset);
        
        if(!assetList.isEmpty()){
            Database.insert(assetList);
        }

    }
    
    /**
    * @description  : create a project if the project doesn't exists against the asset accountId and it is schedule nightly
    * @param: NA
    * @return: void
   */
    @isTest
    static void btEngagementProjectTest(){
        Id project_PEORTId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT_SOBJECT_NAME, NSP_ServiceConstants.PROJECT_PEO_RECORDTYPE);
        pse__proj__c project = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        project.Name = 'BT Engagement Plan Test';
    	project.recordTypeId = project_PEORTId ;
    	project.TemplateName__c = NSP_ServiceConstants.PROJECT_TEMPLATE_NAME;
    	project.pse__Start_Date__c = System.today();
    	insert project;
        List<String> setOfAccFields =new List<String> {'Id','Name'};
        String accQuery = new NSP_QueryBuilder('Account', setOfAccFields)
            			  .addFilter('Name', 'Account Test1')
            			  .addLimit(1).build();
        Account accObj = Database.query(accQuery);
        
        Test.startTest();
        NSP_AutomaticProjectBatchClass batchClass = new NSP_AutomaticProjectBatchClass();
        batchClass.opp = new NSP_OpportunityTriggerServiceHelper(new Set<Id>{ project.Id });
    	Database.executeBatch(batchClass, 1); 
    
    	Test.stopTest();
        
        Date todaydate = System.today();
      	List<String> projField = new List<String>{'Id','Name', 'TemplateName__c', 'pse__Start_Date__c' , 'OwnerId', 'pse__Account__c'};
          String projObj = new NSP_QueryBuilder('pse__Proj__c', projField)
          .addFilter('TemplateName__c', NSP_ServiceConstants.PROJECT_TEMPLATE_NAME)
          .addFilter('pse__Account__c', accObj.Id)
          .setSecurityEnforce(false)
          .build();
      	projObj += 'AND pse__Start_Date__c =: todaydate';
      	List<pse__proj__c>  proj = (List<pse__proj__c>) Database.query(projObj); 
        List<String> accTeamFields = new List<String>{'Id','Name','NSP_Role__c','NSP_Account__c', 'NSP_User__c', 'NSP_Primary__c'};
    	String accTeam = new NSP_QueryBuilder('NSP_Account_Team__c', accTeamFields)
    						.addFilter('NSP_Role__c', NSP_ServiceConstants.MANAGER_HRSERVICES)
            				.addFilter('NSP_Account__c', accObj.Id).addLimit(1).build();
 
    	List<NSP_Account_Team__c> accTeamRec = (List<NSP_Account_Team__c>)Database.query(accTeam);
    	System.assertEquals(proj[0].OwnerId, accTeamRec[0].NSP_User__c);
        
    }
    
}