@isTest
// Test class for RETEducationController
public class RETEducationControllerTest {
    
    @testSetup
    public static void setupRETEducationControllerTest(){       
        Id choicePlanRT = NSP_GenericRecordType.getRecordTypeId('NSP_Plan__c', NSP_ServiceConstants.CHOICE_RT_NAME);
        Id choiceSubPlanRT = NSP_GenericRecordType.getRecordTypeId('NSP_Plan_SubPlan__c', NSP_ServiceConstants.CHOICE_RT_NAME);
        Id RETChoiceRT = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE);
        Id WXRT = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WX_WA);
        //Test Setup
        Account oAccount = new Account(Name = 'ABC Company');
        insert oAccount;
        
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = : 'System Administrator' LIMIT 1];
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@randomorg.com';
        User usr = new User(alias = 'uDelet', email='testfake@insperity.com', 
                            emailencodingkey='UTF-8', lastname='temp', 
                            languagelocalekey='en_US',
                            localesidkey='en_US', profileid = profileRec.Id,
                            timezonesidkey='America/Los_Angeles', 
                            username=uniqueUserName);
        insert usr;
        
                
        NSP_Account_Team__c oAccountTeam = new NSP_Account_Team__c(NSP_Account__c = oAccount.Id,NSP_Role__c = 'WX/WA Benefits Specialist',NSP_User__c = usr.Id );
        insert oAccountTeam;       
        Asset oAsset = new Asset(Name = 'Test 9090', AccountId = oAccount.Id, NSP_Biometric_End_Date__c = System.today().addDays(-1));
        insert oAsset;
        Asset oAsset1 = new Asset(Name = 'Test RET Choice', AccountId = oAccount.Id, NSP_Biometric_End_Date__c = System.today().addDays(-1), recordtypeId = RETChoiceRT);
        insert oAsset1;
        Asset oAsset2 = new Asset(Name = 'Test WX', AccountId = oAccount.Id, NSP_Biometric_End_Date__c = System.today().addDays(-1) ,  recordtypeId = WXRT);
        insert oAsset2;
        
        //Insert new Plan with Choice Record Type
        NSP_Plan__c plan = (NSP_Plan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan__c(), 'NSP_TestDataFactory.PlanDefaults', false);
        plan.RecordTypeId = choicePlanRT;
        insert plan;
        
        //Insert new Sub Plan with Choice Record Type
        NSP_Plan_SubPlan__c subPlan = (NSP_Plan_SubPlan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan_SubPlan__c(), 'NSP_TestDataFactory.SubPlanDefaults', false);
        subPlan.NSP_Parent_Plan_ID__c = plan.Id;
        subPlan.RecordTypeId = choiceSubPlanRT;
        insert subPlan ;
                
        AssetRETEducationAssociation__c assetretedassociation = new AssetRETEducationAssociation__c();
        assetretedassociation.NSP_Lead_Parent__c = oAsset2.Id;
        assetretedassociation.NSP_Education_Client__c = oAsset2.Id;
        assetretedassociation.NSP_Subplan__c = subPlan.Id;
        assetretedassociation.NSP_Status__c = 'Active';
        insert assetretedassociation;
    }
    @isTest
    static void retEducationControllerTst(){
        Test.startTest();                        
        AssetRETEducationAssociation__c  RETEductUpdate=[Select Id, createdDate, name,  NSP_AIMs__c,NSP_Subplan__c,NSP_Status__c,
                                                              NSP_Language_Needs__c, NSP_Education_Client__c, NSP_Name__c
                                                         from AssetRETEducationAssociation__c WHERE name != null LIMIT 1];
       
        RETEductUpdate.NSP_Status__c = null;
        RETEductUpdate.NSP_Subplan__c =null;
        RETEductUpdate.NSP_Name__c = 'Update Name'; 
        RETEducationController.updateRETRecords(RETEductUpdate);   
        RETEducationController.getRETEducationOverview(RETEductUpdate.Id);
         AssetRETEducationAssociation__c  RETEductUpdateNew =[Select Id, createdDate, name,  NSP_AIMs__c,NSP_Subplan__c,NSP_Status__c,
                                                              NSP_Language_Needs__c, NSP_Education_Client__c, NSP_Name__c
                                                         from AssetRETEducationAssociation__c WHERE name != null LIMIT 1];
         system.assertEquals(RETEductUpdateNew.NSP_Name__c,'Update Name' );
        Test.stopTest();
    }
    
    @isTest
    static void retEducationControllerTest1(){
        test.startTest();
        Id WXRT = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WX_WA);
        ID RET_WO_AssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.RET_WO_ASSET_RECORDTYPE);
        Account accountObj = [SELECT Id,Name from Account WHERE name ='ABC Company'  LIMIT 1];        
        Asset assetTestChoice = [Select id, accountId,recordtypeId from asset WHERE Id != null AND accountId =: accountObj.Id LIMIT 1 ];
        Asset oAsset1 = new Asset(Name = 'Test WO', AccountId = accountObj.Id, NSP_Biometric_End_Date__c = System.today().addDays(-1) ,  recordtypeId = RET_WO_AssetRecordTypeId);
        insert oAsset1;  
         Asset oAsset2 = new Asset(Name = 'Test WX', AccountId = accountObj.Id, NSP_Biometric_End_Date__c = System.today().addDays(-1) ,  recordtypeId = WXRT);
        insert oAsset2;       
        Map<String, String> testChoice = RETEducationController.getAccountTeam(oAsset1.id);
        Map<String, String> testWX = RETEducationController.getAccountTeam(oAsset2.id);      
        system.assertEquals('WX/WA Benefits Specialist', testChoice.get('temp'));
        test.stopTest();
    }
    
}