/**
Apex Class Name      :  NSP_CustomCaseCreationPageControllerTest
Version              :  1.0   
Author               :  Jatin                                                                       
Created Date         :  12/24/2021   
Function             :  Represents test class for NSP_CustomCaseCreationPageController class
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Bindu                6/21/2022           First Iteration
*/
@isTest(SeeAllData=false)
public class NSP_CustomCaseCreationPageControllerTest {
	@testSetup
    static void testData() {
        //Inserting Category
        NSP_Category_Sub_Category_Mapping__c newCat = (NSP_Category_Sub_Category_Mapping__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Category_Sub_Category_Mapping__c(), 'NSP_TestDataFactory.CatSubCatMappingDefaults', false);
        newCat.NSP_UserTitle__c = 'Benefits Manager';
        newCat.NSP_Category__c = 'M&A';
        newCat.NSP_Subcategory__c = 'eLearning';
        newCat.NSP_Detail__c = 'Login';
        newCat.NSP_isActive__c=True;
        newCat.NSP_Asset_Record_Types__c='WO';
        newCat.NSP_RecordType__c='PEO';
        insert newCat;
    
        NSP_Category_Sub_Category_Mapping__c newCat1 = (NSP_Category_Sub_Category_Mapping__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Category_Sub_Category_Mapping__c(), 'NSP_TestDataFactory.CatSubCatMappingDefaults', false);
        newCat1.NSP_UserTitle__c = 'Client Liaison';
        insert newCat1;
        //Inserting Account
        Account accoutObject = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        accoutObject.Name = System.Label.NSP_InternalAccountName; 
        insert accoutObject;
        //Inserting Contact
        Contact con = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        con.AccountId = accoutObject.Id;
        insert con;
        //Inserting Asset
        Asset ast = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        ast.AccountId = accoutObject.Id;
        ast.RecordTypeId= Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('WO').getRecordTypeId();
        insert ast;
        //Inserting Case
        Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        newCase.AccountId = accoutObject.Id;
        newCase.Type = 'Mobile – WX';
        newCase.NSP_Category__c ='M&A';
        newCase.NSP_SubCategory__c='eLearning';
        newCase.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
        newCase.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
        newCase.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PEO').getRecordTypeId();
        insert newCase;
        
        Case newCase1 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
       
        newCase1.Type = 'Holiday Admin Relief';
        insert newCase1;
        //Inserting Group
        Group newGroup= (Group)NSP_TestExtendedDataFactory.createSObject(new Group(), 'NSP_TestDataFactory.GroupDefaults', false); 
        newGroup.Type ='Queue';
        newGroup.Name='test group';
        insert newGroup;
        
        ////Rob Inserting non Admin User
        Profile prof = [SELECT id from profile where name =: NSP_ServiceConstants.BPSSERVICE];
        
        User bpsUser = new User(
            Alias = 'random',
            Email='random@insperity.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'random',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = prof.Id,
            TimeZoneSidKey ='America/Los_Angeles',
            UserName ='testuser_@test.com' + System.currentTimeMillis(),
            Title = 'EEO',
            NSP_Curated_Picklist_Role__c = 'EEO'
        );
        insert bpsUser;
        
        Profile bpsProf = [SELECT id from profile where name =: NSP_ServiceConstants.BPSSERVICE];
        
        User noTitleUser = new User(
            Alias = 'random',
            Email='noTitle@insperity.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'random',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = bpsProf.Id,
            TimeZoneSidKey ='America/Los_Angeles',
            UserName ='testuser_@test.com' + System.currentTimeMillis(),
            Title = '',
            NSP_Curated_Picklist_Role__c = ''
        );
        insert noTitleUser;
        
        Profile adminprof = [SELECT id from profile where name =: NSP_ServiceConstants.SYSTEM_ADMINISTRATOR];
        
        User adminUser = new User(
            Alias = 'SystAdm',
            Email='admin@insperity.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'SysAd',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = adminprof.Id,
            TimeZoneSidKey ='America/Los_Angeles',
            UserName ='testuser_@test.com' + System.currentTimeMillis(),
            Title = 'EEO',
            NSP_Curated_Picklist_Role__c = 'EEO'
        );
        insert adminUser;
    }
    
    Static testMethod void testMethod1() {  
        User bpsUser = [SELECT Id, Title
                       FROM User
                       WHERE Email = 'random@insperity.com' LIMIT 1];
        User adminUser = [SELECT Id, Title
                       FROM User
                       WHERE Email = 'admin@insperity.com' LIMIT 1];
        User noTitleUser = [SELECT Id, Title
                       FROM User
                       WHERE Email = 'noTitle@insperity.com' LIMIT 1];

        String peoRecordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PEO').getRecordTypeId();
        String bpsRecordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('BPS').getRecordTypeId();
        Test.startTest();
        	Contact con = [SELECT Id, AccountId FROM Contact WHERE Account.Name =: System.Label.NSP_InternalAccountName LIMIT 1];
        //Getting Category Records
        	Case ca = [SELECT Id, AccountId, NSP_Category__c,NSP_SubCategory__c  FROM Case WHERE Account.Name =: System.Label.NSP_InternalAccountName LIMIT 1];
        //Getting Asset Records
        List<NSP_Category_Sub_Category_Mapping__c> lCategoriesRecords =[SELECT Id, NSP_Detail__c, NSP_Category__c, NSP_Subcategory__c,NSP_Version__c
                                                         FROM NSP_Category_Sub_Category_Mapping__c 
                                                         WHERE  NSP_Category__c !=null];
        	
        	NSP_CustomCaseCreationPageController.getCategoryList(peoRecordtypeId, false);
            NSP_CustomCaseCreationPageController.getInternalAccountId();
            NSP_CustomCaseCreationPageController.getAllCategoryList(peoRecordtypeId, '');
            NSP_CustomCaseCreationPageController.getAllDependenciesValues(peoRecordtypeId);
            NSP_CustomCaseCreationPageController.getCategoryDependenciesMap(peoRecordtypeId, false);
            NSP_CustomCaseCreationPageController.getRelatedCategory('BPS User', peoRecordtypeId);
            NSP_CustomCaseCreationPageController.getRelatedSubCategory('M&A', peoRecordtypeId, false);
            NSP_CustomCaseCreationPageController.getRelatedDetail('eLearning', 'Web Support', peoRecordtypeId);
            NSP_CustomCaseCreationPageController.getCaseFromConfig('Mobile – WX', con.AccountId);
            NSP_CustomCaseCreationPageController.getRelatedCategory('Client Liaison', peoRecordtypeId);
            NSP_CustomCaseCreationPageController.getCaseRecordType('');
            NSP_CustomCaseCreationPageController.getContactParent(ca.Id);
            NSP_CustomCaseCreationPageController.getAssetParent(ca.Id);
            NSP_CustomCaseCreationPageController.autoPopulateAsset(ca.NSP_Category__c, ca.NSP_SubCategory__c, ca.AccountId );
        	List<object> objList = (List<object>)json.deserializeUntyped('[{"Title":"test","FileContent":"25 lines of data added","FileType":"xml"}]');
            NSP_CustomCaseCreationPageController.saveFiles(objList, ca.Id);
            NSP_CustomCaseCreationPageController.getDependencyWrapper(lCategoriesRecords);
        	NSP_Category_Sub_Category_Mapping__c cat3 = [SELECT Id, NSP_Detail__c , NSP_Category__c
                                                         FROM NSP_Category_Sub_Category_Mapping__c 
                                                         WHERE NSP_Detail__c = 'Login' AND NSP_Category__c = 'M&A'];
        	cat3.NSP_Version__c = 'Test';
        //Updating Category 3
        update cat3;
        
        
        NSP_CustomCaseCreationPageController.getRelatedVersion('Login', peoRecordtypeId);
        
        System.assertEquals(1, [SELECT count() FROM Case WHERE Account.Name =: System.Label.NSP_InternalAccountName]);

        //coverage changes
       	NSP_CustomCaseCreationPageController.getCategoryList(bpsRecordtypeId, false);
        NSP_CustomCaseCreationPageController.getCaseFromConfig('nulls', con.AccountId);
        
        //Rob run as non Admin
        System.runAs(bpsUser){
            NSP_CustomCaseCreationPageController.getCategoryList(bpsRecordtypeId, false);
        }
        
        System.runAs(adminUser){
            NSP_CustomCaseCreationPageController.getCategoryList(bpsRecordtypeId, false);
        }
        System.runAs(noTitleUser){
            NSP_CustomCaseCreationPageController.getCategoryList(bpsRecordtypeId, false);
        }

        Test.stopTest();
    }

                 /**
 * @Description: This test method is used to check the Default Contact records
 * @Created date: 11/15/2022. 
 * @return void             
 **/
    
@isTest
private static void isContactHasMultipleACRsTest(){
         List<Contact> getContact = [SELECT Id, Name FROM Contact WHERE AccountId != '' LIMIT 1];
     Test.startTest();
   Boolean isACRs =  NSP_CustomCaseCreationPageController.isContactHasMultipleACRs(getContact[0].Id);
    Test.stopTest();  
    system.assertEquals(false, isACRs);
}

/**
 * @Description: This test method is used to check the getProfileName
 * @Created date: 11/24/2022. 
 * @return void             
 **/
@isTest
private static void getProfileNameTest() {
    Test.startTest();
    String getProfileName = NSP_CustomCaseCreationPageController.getProfileName();
    Test.stopTest();
    system.assertEquals('System Administrator', getProfileName);
}
    /**
* @Description: This test method is used to check the isMemberOfPrivateSection125Visibility
* @Created date: 11/30/2022. 
* @return void             
**/
@isTest
private static void isMemberOfPrivateSection125VisibilityTest(){
    Boolean ishavingAccess;
    List<String> fields = new List<String>{'Id', 'Type','DeveloperName'};
Id  groupId = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.TYPE_REGULAR, NSP_ServiceConstants.SECTION_125_PRIVATE_CASE_VISIBILTY, fields).Id;
    GroupMember grpMem = new GroupMember (UserOrGroupId = userInfo.getUserId(), GroupId = groupId);
    List<GroupMember> groupMemberList= new List<GroupMember>{grpMem};
        // Inserting Group Members
        Insert groupMemberList;
    Test.startTest();
    ishavingAccess = NSP_CustomCaseCreationPageController.isMemberOfPrivateSection125Visibility();
    Test.stopTest();
    system.assertEquals(true, ishavingAccess);
    
    Delete groupMemberList;
    ishavingAccess = NSP_CustomCaseCreationPageController.isMemberOfPrivateSection125Visibility();
    system.assertEquals(false, ishavingAccess); // negative Scenario
}

        
    /**
    * @Description: This test method is used to check the getMapOfObjectNameAndKeyPrefix
    * @Created date: 04/14/2023. 
    * @return void             
    **/
    @isTest
    private static void getMapOfObjectNameAndKeyPrefix(){

    Test.startTest();
    Map<string, string> objectNameKeyPrefixMap = NSP_CustomCaseCreationPageController.getMapOfObjectNameAndKeyPrefix();
    Test.stopTest();

    system.assert(objectNameKeyPrefixMap != null);
    }
}