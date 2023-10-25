@isTest
public class NSP_CloneRSAPRelatedRecordsTest {
	@testSetup
    public static void createTestData() {
        //Account creation
        Account accRecord = NSP_TestHelper.createAccount(true);
        
        //RSAP creation
        NSP_Relationship_Strategy_Action_Plan__c rsap = new NSP_Relationship_Strategy_Action_Plan__c();
        rsap.Name = 'RSAP1';
        rsap.NSP_Account__c = accRecord.Id;
        rsap.NSP_Status__c='Active';
        insert rsap;
        
        NSP_Initiative__c initiativeRec = new NSP_Initiative__c();
        initiativeRec.Name = 'Test';
        initiativeRec.NSP_ALL__c = 'Test';
        initiativeRec.NSP_Business_Drivers__c = 'Test';
        initiativeRec.Initiative_Type__c = 'Short Term (90 day) Strategy';
        initiativeRec.NSP_Status__c = 'In Progress';
        initiativeRec.NSP_Relationship_Strategy_Action_Plan__c = rsap.Id;
        INSERT initiativeRec;
        
        NSP_Engagement_Path__c engagementRec = new NSP_Engagement_Path__c();
        engagementRec.Action__c = 'test';
        engagementRec.Name = 'test';
        engagementRec.NSP_Initiative__c = initiativeRec.Id;
        engagementRec.NSP_Start_Date__c = System.today();
        engagementRec.NSP_Actual_End_Date__c = System.today().addDays(2);
        engagementRec.NSP_Target_Date__c = System.today();
        engagementRec.Relationship_Strategy_Action_Plan__c = rsap.Id;
        
        INSERT engagementRec;
    }
    
    @isTest
    public static void test01() {
        Test.startTest();
        NSP_Relationship_Strategy_Action_Plan__c rsapRec = [SELECT Id FROM NSP_Relationship_Strategy_Action_Plan__c LIMIT 1];
        List<NSP_Initiative__c> initiativeRecList = [SELECT Id, NSP_ALL__c, NSP_Business_Drivers__c,
                                                     Name, Initiative_Type__c, NSP_Relationship_Strategy_Action_Plan__c, NSP_Status__c 
                                                     FROM NSP_Initiative__c];
        List<NSP_Engagement_Path__c> engagementRecList = [SELECT Id, Action__c, NSP_Actual_End_Date__c,
                                                          Name, NSP_Initiative__c, Initiative_Type__c 
                                                          FROM NSP_Engagement_Path__c];
        
        
        List<NSP_CloneRSAPRelatedRecords.FlowInputvalues> objList = new List<NSP_CloneRSAPRelatedRecords.FlowInputvalues>();
        NSP_CloneRSAPRelatedRecords.FlowInputvalues obj = new NSP_CloneRSAPRelatedRecords.FlowInputvalues();
        obj.oldRSAPId = rsapRec.Id;
        objList.add(obj);
        
        NSP_CloneRSAPRelatedRecords.cloneRelatedRSAPRecords(objList);
        Test.stopTest();
    }
}