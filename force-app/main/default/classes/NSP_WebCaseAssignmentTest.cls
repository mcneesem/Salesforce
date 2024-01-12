/**
Apex Class Name      :  NSP_WebCaseAssignmentTest for NSP_WebCaseAssignment
Version              :  1.0                                                                          
Created Date         :  10/3/2022   
Function             :  Test class for NSP_WebCaseAssignment 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Srushti                     10/3/2022            First Iteration
*/


@isTest
public class NSP_WebCaseAssignmentTest {
    public static final Id BPSCASERECORDTYPEID = SObjectType.Case.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.BPS).getRecordTypeId();
    public static final String EMAILMESSAGETOADDRESS = 'test.bps.customerservice_sfqa2@1i1dkofee60i318prn5936em3ztnijkto9sx6phd0z8hz4fs1x.8g-8hsjuai.cs219.case.sandbox.salesforce.com';
    public static final String EMAILMESSAGESUBJECT = 'Test email Subject';
    public static final String EMAILMESSAGEHTMLBODY = 'Test email body';

    @testSetup
    public static void setUpTestData(){
        //Create a case record 
        Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        newCase.RecordTypeId = BPSCASERECORDTYPEID;
        Database.insert(newCase);     
    }
    
    @isTest
    public static void webCaseAssignTest(){
        User getLoggedInUser = [SELECT Id, Email FROM USER WHERE Id =: UserInfo.getUserId()];
        Case getCaseRec = [SELECT Id, RecordTypeId, OwnerId FROM Case WHERE RecordTypeId =: BPSCASERECORDTYPEID LIMIT 1];
        //Create an EmailMessage Record
        EmailMessage eMsg = new EmailMessage ();
        eMsg.FromAddress = getLoggedInUser.Email;
        eMsg.Incoming = True;
        eMsg.ToAddress= EMAILMESSAGETOADDRESS;
        eMsg.Subject = EMAILMESSAGESUBJECT;
        eMsg.HtmlBody = EMAILMESSAGEHTMLBODY;
        eMsg.ParentId = getCaseRec.id;
        Test.startTest();
        Database.insert(eMsg);
        Test.stopTest();
        System.assertEquals(getCaseRec.OwnerId, getLoggedInUser.Id);
    }
}