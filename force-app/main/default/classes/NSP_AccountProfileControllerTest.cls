/**
Apex Class Name      :  NSP_AccountProfileControllerTest
Version              :  1.0
Author               :  Shreemanth
Created Date         :  10/27/2022
Function             :  This class is used as a test class of NSP_AccountProfileController
Story                :  
*/

@isTest
private class NSP_AccountProfileControllerTest {
    @testSetup
    static void setAllData(){
        Id woAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        Id retAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE);
        Id retClientSubPlanId = NSP_GenericRecordType.getRecordTypeId('NSP_Client_Sub_Plan_History__c', 'Choice');
        Id retSubPlanId = NSP_GenericRecordType.getRecordTypeId('NSP_Plan_SubPlan__c', 'Choice');
        Id eligibilityChoiceRecordTypeId = NSP_GenericRecordType.getRecordTypeId('NSP_Eligibility__c','Choice');
        Id planRecordTypeId = NSP_GenericRecordType.getRecordTypeId('NSP_Plan__c','Choice');
        
        // Update Account
        Account acc = (Account) NSP_TestDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc.Name = 'Test Account';
        acc.Website = 'abc.com';
        acc.TickerSymbol = 'xyz';
        acc.NSP_Year_Established__c = '2018';
        insert acc;

        List<Asset> assetList = new List<Asset>();
         // WO Asset Creation
        Asset assetObj = (Asset) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetObj.AccountId = acc.Id;
        assetObj.RecordTypeId = woAssetRecordTypeId;
        assetObj.NSP_Business_Type__c = 'test Business Type';
        assetObj.NSP_Handbook_Status__c = 'Work in Progress';
        assetObj.NSP_Government_Contractor__c = false;
        assetList.add(assetObj);

        // Create RET Asset object
        Asset retassetObj = (Asset) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        retassetObj.Name = 'Test Asset RET Choice';
        retassetObj.RecordTypeId = retAssetRecordTypeId;
        retassetObj.NSP_Business_Type__c = 'test Business Type';
        retassetObj.NSP_Handbook_Status__c = 'Work in Progress';
        retassetObj.NSP_Government_Contractor__c = false;
        retassetObj.AccountId = acc.Id;
        retassetObj.Status = 'Active';
        assetList.add(retassetObj);
        insert assetList;

        // SubClient Creation
        NSP_Sub_Client__c subClientObj = (NSP_Sub_Client__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', false);
        subClientObj.NSP_Sub_Client__c = '4200';
        subClientObj.NSP_Benefit_Package_Name__c = 'Test Benefit Package';
        subClientObj.NSP_Asset__c = assetObj.Id;
        subClientObj.NSP_Margin__c = 1.00;
        subClientObj.NSP_Reserve__c = 2.00;
        subClientObj.NSP_Part_Time_Margin__c = 2.00;
        subClientObj.NSP_Part_Time_Reserve__c = 3.00;
        insert subClientObj;

        // Create Plan record
        NSP_Plan__c plan = (NSP_Plan__c) NSP_TestDataFactory.createSObject(new NSP_Plan__c(), 'NSP_TestDataFactory.PlanDefaults', false);
        plan.RecordTypeId = planRecordTypeId;
        insert plan;

        // Create Sub Plan record
        NSP_Plan_SubPlan__c planSubPlan = (NSP_Plan_SubPlan__c) NSP_TestDataFactory.createSObject(new NSP_Plan_SubPlan__c(), 'NSP_TestDataFactory.SubPlanDefaults', false);
        planSubPlan.NSP_Parent_Plan_ID__c = plan.Id;
        planSubPlan.NSP_Subplan_ID__c = '122345667';
        planSubPlan.NSP_Subplan_Lead_Parent__c = retassetObj.Id;
        planSubPlan.RecordTypeId = retSubPlanId;
        insert planSubPlan;
        
        // Create Client Sub Plan History record
        NSP_Client_Sub_Plan_History__c clientSubPlan = (NSP_Client_Sub_Plan_History__c) NSP_TestDataFactory.createSObject(new NSP_Client_Sub_Plan_History__c(), 'NSP_TestDataFactory.ClientSubPlanHistoryDefaults', false);
        clientSubPlan.NSP_Asset__c = retassetObj.Id;
        clientSubPlan.NSP_Plan_Subplan_Relationship__c = planSubPlan.Id;
        clientSubPlan.NSP_Current_Subplan__c = true;
        clientSubPlan.RecordTypeId = retClientSubPlanId;
        insert clientSubPlan;

        // Create Participation SaaS Activity record
        NSP_Participation_SaaS_Activity__c saasActivity = new NSP_Participation_SaaS_Activity__c();
        saasActivity.NSP_Asset__c = retassetObj.Id;
        saasActivity.NSP_Subplan_Plan_Details_Record__c = planSubPlan.Id;
        saasActivity.NSP_Eligible_Participating_Count__c = 12;
        insert saasActivity;
        
        // Create Eligibility Record
        NSP_Eligibility__c eligibility = (NSP_Eligibility__c) NSP_TestDataFactory.createSObject(new NSP_Eligibility__c(), 'NSP_TestDataFactory.EligibilityDefaults', false);
        eligibility.RecordTypeId = eligibilityChoiceRecordTypeId;
        eligibility.NSP_Plan_Subplan_Relationship__c = planSubPlan.Id;
        eligibility.NSP_Asset__c = retassetObj.Id;
        insert eligibility;
		
        //Create an Asset RET Education Association Record
        AssetRETEducationAssociation__c retEduAssociation = (AssetRETEducationAssociation__c)NSP_TestExtendedDataFactory.createSObject(new AssetRETEducationAssociation__c(),'NSP_TestDataFactory.AssetRETEducationAssociationDefaults',false);
        retEduAssociation.NSP_Education_Client__c = retassetObj.Id;
        retEduAssociation.NSP_Lead_Parent__c = retassetObj.Id;
        retEduAssociation.NSP_Status__c = 'Active';
        retEduAssociation.NSP_Subplan__c = planSubPlan.Id;
        insert retEduAssociation;

        // Create Account Team record
        NSP_Account_Team__c accTeam = (NSP_Account_Team__c) NSP_TestDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.accountTeamDefaults', false);
        accTeam.NSP_Account__c = acc.Id;
        accTeam.NSP_Role__c = '401k Plan Consultant';
        accTeam.NSP_User__c = UserInfo.getUserId();
        insert accTeam;
    }
 /**
    * Method to test - NSP_AccountProfileController.getAccountProfileRelatedInfo
    */

    @isTest
    static void getAccountProfileRelatedInfoReturnsFieldValues(){
        //GIVEN
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
        try {
             //WHEN
             Test.startTest();
             Map<String, Map<String, String>> relatedInfo = NSP_AccountProfileController.getAccountProfileRelatedInfo(acc.Id);
			Test.stopTest();
             //THEN
             System.assertEquals(false, relatedInfo.isEmpty());
        } catch(AuraHandledException ex){
            System.assert(false, 'Should not throw error.');
        }
    }

    @isTest
    static void getAccountProfileRelatedInfoWhenAccountIdIsNull(){
        System.assertEquals(0, NSP_AccountProfileController.getAccountProfileRelatedInfo(null).size(), 'Should Return null');
    }

    @isTest
    static void getAccountProfileRelatedInforeturnsCorrectAssetDetails(){
        // GIVEN
        Test.startTest();
        Account acc = [SELECT Id, Name FROM Account WHERE Name= 'Test Account' LIMIT 1];
       	List<String> assetFields = new List<String>{ 
            'Id', 'NSP_Account_Status__c','NSP_AIMS_First_Pay_Date__c',
            'Status'
        };

        String query = new NSP_QueryBuilder('Asset', assetFields)
                .addFilter('RecordType.DeveloperName', NSP_ServiceConstants.WO_ASSET_RECORDTYPE)
                .addFilter('AccountId', acc.Id).addLimit(1).build();

        List<Asset> assets = (List<Asset>) Database.query(query);
        assets[0].NSP_AIMS_First_Pay_Date__c = System.today();
        assets[0].Status = 'Active';
        Update assets[0];
        
        // WHEN
        Map<String, Map<String, String>> relatedInfo = NSP_AccountProfileController.getAccountProfileRelatedInfo(acc.Id);

        // THEN
        System.assertEquals('test Business Type', getValue('NSP_Business_Type__c', relatedInfo));
        System.assertEquals( 'Work in Progress', getValue('NSP_Handbook_Status__c', relatedInfo));
        System.assertEquals( 'false', getValue('NSP_Government_Contractor__c', relatedInfo));
        Test.stopTest();
    }

    @isTest
    static void getAccountProfileRelatedInforeturnsCorrectAccountDetails(){
        // GIVEN
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];

        // WHEN
        Test.startTest();
        Map<String, Map<String, String>> relatedInfo = NSP_AccountProfileController.getAccountProfileRelatedInfo(acc.Id);
		Test.stopTest();
        // THEN
        System.assertEquals('abc.com', getValue('Website', relatedInfo));
        System.assertEquals('xyz', getValue('TickerSymbol', relatedInfo));
        System.assertEquals('2018', getValue('NSP_Year_Established__c', relatedInfo));
    }

    @isTest
    static void getAccountProfileRelatedInforeturnsCorrectSubClientDetails(){
        // GIVEN
       Test.startTest();
        Account acc = [SELECT Id, Name FROM Account WHERE Name= 'Test Account' LIMIT 1];
       	List<String> assetFields = new List<String>{ 
            'Id', 'NSP_Account_Status__c','NSP_AIMS_First_Pay_Date__c',
            'Status'
        };

        String query = new NSP_QueryBuilder('Asset', assetFields)
                .addFilter('RecordType.DeveloperName', NSP_ServiceConstants.WO_ASSET_RECORDTYPE)
                .addFilter('AccountId', acc.Id).addLimit(1).build();

        List<Asset> assets = (List<Asset>) Database.query(query);
        assets[0].NSP_AIMS_First_Pay_Date__c = System.today();
        assets[0].Status = 'Active';
        Update assets[0];
        // WHEN
        Map<String, Map<String, String>> relatedInfo = NSP_AccountProfileController.getAccountProfileRelatedInfo(acc.Id);

        // THEN
        System.assertEquals('1.00/2.00', getValue('NSP_Full_time_Margin_Part_time_Margin__c', relatedInfo));
        System.assertEquals('2.00/3.00', getValue('NSP_Full_time_Reserve_Part_time_Reserve__c', relatedInfo));
        Test.stopTest();
    }

    @isTest
    static void getAccountProfileRelatedInforeturnsSaaSActivityField(){
        // GIVEN
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];

        // WHEN
        Test.startTest();
        Map<String, Map<String, String>> relatedInfo = NSP_AccountProfileController.getAccountProfileRelatedInfo(acc.Id);
		Test.stopTest();
        // THEN
        System.assertEquals('12', getValue('NSP_How_many_emplys_enrolled_in_401k__c', relatedInfo));
    }

    @isTest 
    static void getAccountProfileRelatedInforeturnsRetEdu(){
        // GIVEN
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];

        // WHEN
        Test.startTest();
        Map<String, Map<String, String>> relatedInfo = NSP_AccountProfileController.getAccountProfileRelatedInfo(acc.Id);
		Test.stopTest();
        // THEN
        System.assertNotEquals(null, getValue('NSP_last_employee_401k_education_webinar__c', relatedInfo));
    }

    @isTest 
    static void getAccountProfileRelatedInforeturnsEligibility(){
        // GIVEN
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];

        // WHEN
        Test.startTest();
        Map<String, Map<String, String>> relatedInfo = NSP_AccountProfileController.getAccountProfileRelatedInfo(acc.Id);
		Test.stopTest();
        // THEN
        System.assertNotEquals(null, getValue('NSP_401K_ORK_wait_period__c', relatedInfo));
    }

    @isTest
    static void getAccountProfileRelatedInforeturnsAccTeam(){
        // GIVEN
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];

        // WHEN
        Test.startTest();
        Map<String, Map<String, String>> relatedInfo = NSP_AccountProfileController.getAccountProfileRelatedInfo(acc.Id);
		Test.stopTest();
        // THEN
        System.assertNotEquals(null, getValue('NSP_Assigned_RS_Specialist__c', relatedInfo));
    }

    @isTest
    static void getRecentlyUpdatedFieldswhenNoFieldValueChangedreturnsEmptyList(){
        // GIVEN
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];

        // WHEN
        Test.startTest();
        List<String> recentlyUpdatedFields = NSP_AccountProfileController.getRecentlyUpdatedFields(acc.Id);
        Test.stopTest();
        // THEN
        System.assertEquals(new List<String>(), recentlyUpdatedFields, 'Field Name list should be empty when no field value is changed.');
    }

    static String getValue(String fieldName, Map<String, Map<String, String>> relatedInfo){
        return relatedInfo.get(fieldName)?.get('value');
    }
}