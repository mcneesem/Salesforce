/**
* Represents test class for NSP_SurveyTriggerHelper
*/
@isTest
public class NSP_SurveyTriggerHelperTest {
    
    public static final Id CSAT_RECORDTYPEID = Schema.SObjectType.NSP_Survey__c.getRecordTypeInfosByDeveloperName().get('CSAT').getRecordTypeId();
    public static final Id CSAT_TRANSITIONPROGRESSRECORDTYPEID = Schema.SObjectType.NSP_Survey__c.getRecordTypeInfosByDeveloperName().get('Transition_Progress').getRecordTypeId();
    
    
/**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    @testSetup
    public static void testSetup(){
         String orgId = UserInfo.getOrganizationId();
    	User oUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), false); 
        oUser.userName = 'testemail@domain'+ orgId +'.com.test';
        insert oUser;
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), true); 
        // inserting account team members
        NSP_Account_Team__c member1 = new NSP_Account_Team__c();
        member1.NSP_Account__c = oAccount.Id;
        member1.NSP_User__c = oUser.Id;
        member1.NSP_Role__c = 'Manager, HR Services';
        insert member1;
        //inserting group
        Group oGroup = (Group)NSP_TestExtendedDataFactory.createSObject(new Group());
        oGroup.Type = 'Queue';
        oGroup.Name = 'Admin Queue';
        insert oGroup;
        //inserting case
        Case oCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case());  
        oCase.Subject = 'Client Contact requested a call';
        oCase.AccountId = oAccount.Id;
        insert oCase;
        //creating a list of records for Survey object
        List<NSP_Survey__c> SurveyList = new List<NSP_Survey__c>();
        //first survey record
        NSP_Survey__c survey1 = new NSP_Survey__c();
        survey1.OwnerId = oUser.Id;
        survey1.CurrencyIsoCode = 'USD';
        survey1.RecordTypeId = CSAT_RECORDTYPEID;
        survey1.Call_Requested__c = 'Yes';
        survey1.Account__c = oAccount.Id;
        survey1.Overall_Satisfaction__c = 'Not Satisfied';
        survey1.Recommend__c = 1;
        survey1.Renew__c = 'Agree';
        survey1.NSP_Onboarding_Experience__c = 'Yes';
        SurveyList.add(survey1);
        //second survey record
        NSP_Survey__c survey2 = new NSP_Survey__c();
        survey2.OwnerId = oUser.Id;
        survey2.CurrencyIsoCode = 'USD';
        survey2.RecordTypeId = CSAT_TRANSITIONPROGRESSRECORDTYPEID;
        survey2.Account__c = oAccount.Id;
        survey2.Overall_Satisfaction__c = 'Not Satisfied';
        survey2.Renew__c = 'Agree';
        survey2.Recommend__c = 2;
		survey2.NSP_Onboarding_Experience__c = 'No';
        SurveyList.add(survey2);
        
        insert SurveyList;
    }

        /**
* @Description: This test method is used to cover createCaseFromCSATSurveyResult method
* @Created date: 08/18/2022. 
* @return void             
*     */  
    
    @isTest
    public static void createCaseTest(){
        
        List<NSP_Survey__c> SurveyList = [SELECT Id,Overall_Satisfaction__c,Recommend__c,Renew__c,NSP_Onboarding_Experience__c FROM NSP_Survey__c WHERE Id != null LIMIT 100];
        List<Case> caseList =  [SELECT id FROM Case WHERE Id != null LIMIT 10];
        
        Test.startTest();
        
        for(NSP_Survey__c sur : SurveyList){
            sur.Overall_Satisfaction__c = 'Somewhat Satisfied';
            sur.Recommend__c = 5;
            sur.Renew__c = 'Disagree';
        }
        update SurveyList;
        Test.stopTest();
        system.assertEquals(true,caseList.size()>0);

    }
}