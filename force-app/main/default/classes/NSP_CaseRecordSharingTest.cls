/**
Apex Class Name      :  NSP_CaseRecordSharingTest
Version              :  1.0  
Author               :  Teja Mani                                                                        
Created Date         :   8/23/2022  
Function             :   Represents test class for NSP_CaseRecordSharing
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Teja Mani                      8/24/2022            First Iteration
*/


@isTest
private class NSP_CaseRecordSharingTest {
    
    private static final String CASEDEFAULTS = 'NSP_TestDataFactory.CaseDefaults';
    private static final Id PEO_RECORDTYPEID = NSP_GenericRecordType.getRecordTypeId('Case',NSP_ServiceConstants.PEO );
    /***********************************************************************************************
    * MethodName: testData
    * Description : Test Data Method
    * Author :      Teja Mani
    * ********************************************************************************************/
    @testSetup
    static void testData() {
        //creating a PEO user
        User PEOUSER = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'PEO Service'][0].Id,
            LastName = 'TestClassUser',
            Email = 'testuser@insperity.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert PEOUSER;
    
        //Creating list which stores case records
        System.runAs (PEOUSER) {
            List<case> cList = new List<case>();
            Case case1 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
            case1.NSP_Category__c =  NSP_ServiceConstants.BEN_SERVICE_CLAIMS;
            case1.NSP_Subcategory__c = 'Commuter';
            case1.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
        	case1.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
            cList.add(case1);
            Case section125Case = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
            section125Case.NSP_Category__c =  NSP_ServiceConstants.HW_SECTION_125;
            section125Case.NSP_Subcategory__c = 'CAMS';
            section125Case.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
        	section125Case.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
            cList.add(section125Case);
            //inserting case 
            Database.insert(cList);
        }

    system.runAs(new User(Id = UserInfo.getUserId())){
        NSP_Category_Sub_Category_Mapping__c newCat = (NSP_Category_Sub_Category_Mapping__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Category_Sub_Category_Mapping__c(), 'NSP_TestDataFactory.CatSubCatMappingDefaults', false);
        newCat.NSP_UserTitle__c = 'Benefits Manager';
        newCat.NSP_Category__c = 'Ben Service - Claims';
        newCat.NSP_Subcategory__c = 'Commuter';
        newCat.NSP_Detail__c = 'Login';
        newCat.NSP_isActive__c=True;
        newCat.NSP_Asset_Record_Types__c='WO';
        newCat.NSP_RecordType__c='PEO';
        newCat.NSP_Public_Groups_To_Share__c = 'All Data Visibility'; 
        Database.insert(newCat);
        
        //category subcategory mapping record creation
        NSP_Category_Sub_Category_Mapping__c newCat1 = (NSP_Category_Sub_Category_Mapping__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Category_Sub_Category_Mapping__c(), 'NSP_TestDataFactory.CatSubCatMappingDefaults', false);
        newCat1.NSP_Category__c = 'Ben Service - Claims';
        newCat1.NSP_Subcategory__c = 'Commute';
        insert newCat1;
        
        //case record creation
        List<Case> caseList = new List<Case>();
        Case oCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
            oCase.NSP_Category__c =  NSP_ServiceConstants.BEN_SERVICE_CLAIMS;
            oCase.NSP_Subcategory__c = 'Commute';
        	oCase.NSP_OneVoice_External_ID__c='1234';
            oCase.NSP_Confidential__c=true;
        	oCase.recordtypeId=PEO_RECORDTYPEID;
        	oCase.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
        	oCase.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
            caseList.add(oCase);
        
        Case oCase1 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
            oCase1.NSP_Category__c =  NSP_ServiceConstants.BEN_SERVICE_CLAIMS;
            oCase1.NSP_Subcategory__c = 'Subcommute';
        	oCase1.NSP_OneVoice_External_ID__c='1234';
            oCase1.recordtypeId=PEO_RECORDTYPEID;
        	oCase1.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
        	oCase1.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
            caseList.add(oCase1);
        if(!caseList.isEmpty()){
            database.insert(caseList);
        }
    }
    }
    /**
* @Description: This test method is used to cover insertion of sharing records
* @Created date: 08/23/2022. 
* @return void             
*     */
    @isTest
    private static void insertConfidentialCase(){ 
        User getPeoUser = [SELECT Id,Email FROM user WHERE Email = 'testuser@insperity.com' LIMIT 1];
        System.runAs (getPeoUser) {
            Case getCase = [SELECT Id, NSP_Category__c, 
                            NSP_Subcategory__c, 
                            NSP_Confidential__c FROM Case 
                            WHERE NSP_Category__c =: NSP_ServiceConstants.BEN_SERVICE_CLAIMS LIMIT 1];
            getCase.NSP_Confidential__c = true;
            Test.startTest();
            database.update(getCase);
            Test.stopTest();
            system.assertEquals(getCase.NSP_Confidential__c, true);
        }
    }
    
    /**
* @Description: This test method is used to cover removal of sharing records
* @Created date: 08/23/2022. 
* @return void             
*     */
    @isTest
    private static void removeSharingTest(){
        User getPeoUser = [SELECT Id,Email FROM user WHERE Email = 'testuser@insperity.com'];
        Case getCase = [SELECT Id, NSP_Category__c, NSP_Confidential__c FROM Case WHERE NSP_Category__c =:  NSP_ServiceConstants.BEN_SERVICE_CLAIMS LIMIT 1];
        System.runAs (getPeoUser) {
            getCase.NSP_Confidential__c = false;
            Test.startTest();
            database.update(getCase);
            Test.stopTest();
            system.assertEquals(getCase.NSP_Confidential__c, false);
        }
    }

    /**
    * migratedCaseTest
	* @Description: This test method is used to test sharing of migrated case
	* @Created date: 11/29/2022. 
	* @return void             
	*/
    
    @isTest
    private static void migratedCaseTest(){
        List<String> fields = new List<String>{'Id', 'Type','DeveloperName'};
        Case getCase = [SELECT Id, NSP_Category__c, NSP_Confidential__c 
                        FROM Case
                        WHERE NSP_Subcategory__c='Commute' LIMIT 1];
        Id  groupId = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.TYPE_REGULAR, NSP_ServiceConstants.ALL_DATA_GROUP, fields).Id;
        List<CaseShare> caseShareList =[SELECT Id 
                                 	  FROM CaseShare
                                 	  WHERE CaseId=:getCase.Id 
                                      AND UserOrGroupId=:groupId];
        Case nCase = [SELECT Id, NSP_Category__c, NSP_Confidential__c 
                        FROM Case
                        WHERE NSP_Subcategory__c='Subcommute' LIMIT 1];
        Test.startTest();
            //case insertion (positive) scenario
        	system.assertEquals(caseShareList.size(),1);
        	getCase.NSP_Confidential__c=false;
        	update getCase;
        	//test case sharing removal scenarion
        	List<CaseShare> cseShareList =[SELECT Id 
                                 	  FROM CaseShare
                                 	  WHERE CaseId=:getCase.Id 
                                      AND UserOrGroupId=:groupId];
        	system.assertEquals(cseShareList.size(),0);
        	//case insertion (negative) scenario
        	List<CaseShare> casesShareList =[SELECT Id 
                                 	  FROM CaseShare
                                 	  WHERE CaseId=:nCase.Id 
                                      AND UserOrGroupId=:groupId];
        	system.assertEquals(casesShareList.size(),0);
            
        Test.stopTest();
    }

        /**
* @Description: This test method is used to cover sharing of Private Cases
* @Created date: 11/30/2022. 
* @return void             
*     */
@isTest
private static void sharePrivateCasesTest(){
    List<String> fields = new List<String>{'Id', 'Type','DeveloperName'};
    Case getCase = [SELECT Id, NSP_Category__c, NSP_Confidential__c, NSP_Private__c
                    FROM Case
                    WHERE NSP_Category__c =: NSP_ServiceConstants.HW_SECTION_125 LIMIT 1];
    User getPeoUser = [SELECT Id,Email FROM user WHERE Email = 'testuser@insperity.com'];
    Id  groupId = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.TYPE_REGULAR, NSP_ServiceConstants.SECTION_125_PRIVATE_CASE_VISIBILTY, fields).Id;
    GroupMember grpMem = new GroupMember (UserOrGroupId = getPeoUser.Id, GroupId = groupId);
    List<GroupMember> groupMemberList= new List<GroupMember>{grpMem};
        // Inserting Group Members
        Insert groupMemberList;
    system.runAs(getPeoUser){
        getCase.NSP_Private__c = true;
        database.update(getCase);
        List<CaseShare> caseShareList =[SELECT Id 
                                        FROM CaseShare
                                        WHERE CaseId =: getCase.Id 
                                        AND UserOrGroupId =: groupId];
        system.assertEquals(caseShareList.size(),1); // Positive Scenario
        
        getCase.NSP_Private__c = false;
        database.update(getCase);
        List<CaseShare> removedcaseShareList =[SELECT Id 
                                               FROM CaseShare
                                               WHERE CaseId =: getCase.Id 
                                               AND UserOrGroupId =: groupId];
        system.assertEquals(removedcaseShareList.size(),0); // Negative Scenario
        
    }
}
    
}