/**
* Represents test class for NSP_SurveySubjectTriggerHelper
*/
@isTest
public class NSP_SurveySubjectHelperTest {

           /**
* @Description: This test method is used to cover afterInsertFilterTest method
* @Created date: 08/18/2022. 
* @return void             
*     */  
    @isTest(seeAllData=true)
    private  static void afterInsertFilterTest(){
        Case oCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), true);
        SurveyInvitation SInv = New SurveyInvitation();
        String getCommunityName = Label.NSP_SurveySubjectHelperTest_Label;
        Sinv.CommunityId = [SELECT Id FROM Network WHERE Name =: getCommunityName].Id; 
        SInv.Name = 'Staff – Wellness Survey';
        SInv.OptionsCollectAnonymousResponse = false;
        SInv.OptionsAllowGuestUserResponse = true;
        SInv.OPTIONSALLOWPARTICIPANTACCESSTHEIRRESPONSE = false;
        SInv.SurveyId = [select id,name from survey WHERE Id != Null LIMIT 1].Id;
        insert SInv;
        
        SurveySubject oSurveySubject = new SurveySubject();
        oSurveySubject.Name = 'testObj1';
        oSurveySubject.ParentId = SInv.Id;
        oSurveySubject.SubjectId = oCase.Id;
        
        
        Test.startTest();
        insert oSurveySubject;
        Test.stopTest();
        system.assertEquals(oCase.Id, oSurveySubject.SubjectId);
    }

    @IsTest
    static void afterUpdate() {
        new NSP_SurveySubjectTriggerHandler().afterUpdate(null, null);
         System.assert(new NSP_SurveySubjectTriggerHandler().afterUpdate(null, null) == null);
    }
    
    @IsTest
    static void beforeUpdate() {
        new NSP_SurveySubjectTriggerHandler().beforeUpdate(null, null);
         System.assert(new NSP_SurveySubjectTriggerHandler().beforeUpdate(null, null) == null);
    } 
    @IsTest
    static void afterDelete() {
        new NSP_SurveySubjectTriggerHandler().afterDelete(null, null);
         System.assert(new NSP_SurveySubjectTriggerHandler().afterDelete(null, null) == null);
    }

    @IsTest
    static void beforeDelete() {
        new NSP_SurveySubjectTriggerHandler().beforeDelete(null, null);
         System.assert(new NSP_SurveySubjectTriggerHandler().beforeDelete(null, null) == null);
    }
}