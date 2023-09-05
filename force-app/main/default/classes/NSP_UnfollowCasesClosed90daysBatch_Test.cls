/**

Apex Class Name      :  NSP_UnfollowCasesClosedFor90Days_Test
Version              :  1.0 
Author               :  Simran                                                                          
Created Date         :  23/8/2022
Function             :  Represents test class for NSP_UnfollowCasesClosedFor90DaysOver class

**/
@IsTest
public class NSP_UnfollowCasesClosed90daysBatch_Test {
    public static final String CASEDEFAULTS = 'NSP_TestDataFactory.CaseDefaults';
    public static final Id PEO_RECORDTYPEID = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PEO').getRecordTypeId();
    private static final String EN_US = 'en_US'; 
	@testSetup()
    static void testData() {
        //Creating list which stores case records
        Case case1 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        case1.Status = NSP_ServiceConstants.CASE_CLOSED_STATUS;
        case1.NSP_Confidential__c = true;
        case1.recordTypeId = PEO_RECORDTYPEID;
        case1.NSP_Rating__c = NSP_ServiceConstants.NEUTRAL;
        //inserting case 
        Database.insert(case1);
        Profile profileobj = [SELECT Id FROM Profile WHERE Name='BPS Service'];
        User serviceUser = new User(alias = 'jBPA', email='jsmithyUserBPA@insperity.com', languagelocalekey= EN_US, 
                                localesidkey= EN_US,
                                emailencodingkey='UTF-8', lastname='Smith', profileid = profileobj.Id,
                                timezonesidkey='America/Los_Angeles' ,
                                username='insperitytestadminuser@insperity.com.testBPA');
        insert serviceUser;
        
        EntitySubscription entitySub = new EntitySubscription(
        ParentId = case1.Id,
        SubscriberId = serviceUser.Id);
		insert entitySub;				
    }
    //unfollowing the case records if it is closed over 90 days.
     @isTest 
    static void testToUnFollowCaseClosedFor90DaysOver() { 
        Test.startTest();
        Case closedcase = [SELECT Id, NSP_Subcategory__c, closeddate FROM Case WHERE Status =: NSP_ServiceConstants.CASE_CLOSED_STATUS  LIMIT 1];
        
        //Calling the batch for Closed Case 
        Database.executeBatch(new NSP_UnfollowCasesClosedFor90DaysBatch((closedcase.closeddate).date()),100); //executes the batch class
		Test.stopTest();
        System.assertEquals([select count() FROM EntitySubscription WHERE ParentId =: closedcase.Id], 1);
        
    }
}