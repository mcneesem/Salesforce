@isTest
public class OnboardingMeetingDetailHistoryTest 
{
    //=== Preparing the test data
    @testSetup static void setupTestData()
    {
        
        // Create Onboarding Meeting Request
        Onboarding_Meeting_Request__c newOMR = createOnboardingMeetingRequest();
        insert newOMR;
        
        // Create New Onboarding Meeting Detail
        Onboarding_Meeting_Detail__c newOMD = createOnboardingMeetingDetial(newOMR.Id);
        insert newOMD;
        
        // Asserts
        Assert.isNotNull(newOMR, 'Onboarding Meeting Reqeust is should not be null');
        Assert.isNotNull(newOMD, 'Onboarding Meeting Detail should not be null');
        Assert.areEqual(newOMD.Onboarding_Meeting_Request__c, newOMR.Id);
        
    }
    
    // Test Method to check the History object
    @isTest static void Test_get_OMD_History()
    {
        Onboarding_Meeting_Detail__c meetingRequest 		= [SELECT ID, Onboarding_Meeting_Request__c, EE_Count__c, Effective_Date__c, 
                                                               Special_Instructions__c, Pay_Frequency__c    
                                                               FROM Onboarding_Meeting_Detail__c ORDER BY CreatedDate DESC LIMIT 1];
        
        List<Onboarding_Meeting_Detail__History> histories 	= getOnboardingMeetingDetailHistory(meetingRequest.Id);
        // Preparing the Request wrapper to get the response wrapper
        List<OnboardingMeetingDetailHistory.Request> requests  	= new List<OnboardingMeetingDetailHistory.Request>();
        OnboardingMeetingDetailHistory.Request req 				= new OnboardingMeetingDetailHistory.Request();
        req.OMDHistory 											= histories;
        requests.add(req);
        
        // Calling the class for test coverage
        Test.startTest();
        
        List<OnboardingMeetingDetailHistory.Response> res = OnboardingMeetingDetailHistory.getOMDHistory(requests);
        Test.stopTest();
        
        
        // Asserts
        Assert.isTrue(meetingRequest != null, 'Meeting Request should be there for the history to be created');
        Assert.isTrue(histories?.size() > 0, 'History is required to process this test');
    }
    
    //== Method to set the fields for Onboarding Meeting Request
    public static Onboarding_Meeting_Request__c createOnboardingMeetingRequest()
    {
        Onboarding_Meeting_Request__c newOMR 				= new Onboarding_Meeting_Request__c();
        newOMR.Meeting_Type__c 								= 'Discovery/SKO';
        newOMR.Start_Time_picklist__c 						= '8:00 AM';
        newOMR.End_Time_picklist__c 						= '8:00 AM';
        newOMR.Parent__c 									= true;
        newOMR.Start__c 									= System.Today();
        newOMR.End__c 										= System.Today();
        newOMR.Select_Day_s_of_Week_that_Block_Repeats__c 	= 'Repeat selected days';
        newOMR.Monday__c 									= true;
        newOMR.Tuesday__c 									= true;
        newOMR.Wednesday__c 								= true;
        newOMR.Thursday__c 									= true;
        newOMR.Friday__c 									= true;
        newOMR.Total_Slots_Offered__c 						= 1;  
        
        return newOMR;
    }
    
    //== Method to set the fields for Onboarding Meeting Detial
    public static Onboarding_Meeting_Detail__c createOnboardingMeetingDetial(Id newOMR_Id)
    {
        Onboarding_Meeting_Detail__c newOMD 	= new Onboarding_Meeting_Detail__c();
        newOMD.Preferred_Meeting_Time__c 		= '8AM - 9AM';
        newOMD.Status__c 						= 'Active';
        newOMD.Onboarding_Meeting_Request__c 	= newOMR_Id;
        newOMD.EE_Count__c						= 10;
        newOMD.Effective_Date__c				= Date.Today();
        newOMD.Special_Instructions__c			= 'Test Data';
        newOMD.Pay_Frequency__c					= 'Weekly';
        
        return newOMD;
    }
    
    //== Get History Records related to Onboarding Meeting Detail
    public static List<Onboarding_Meeting_Detail__History> getOnboardingMeetingDetailHistory(Id meetingId)
    {
        List<Onboarding_Meeting_Detail__History> histories;
        // If it is test calss then create dummy data
        if(Test.isRunningTest())
        {
            histories = new List<Onboarding_Meeting_Detail__History>();
            histories.add(new Onboarding_Meeting_Detail__History(parentId = meetingId, Field='Onboarding_Meeting_Request__c'));
            histories.add(new Onboarding_Meeting_Detail__History(parentId = meetingId, Field='EE_Count__c'));
            histories.add(new Onboarding_Meeting_Detail__History(parentId = meetingId, Field='Effective_Date__c'));
            histories.add(new Onboarding_Meeting_Detail__History(parentId = meetingId, Field='Special_Instructions__c'));
            histories.add(new Onboarding_Meeting_Detail__History(parentId = meetingId, Field='Pay_Frequency__c'));
        }
        else
        {
            histories = [SELECT Id, ParentId, Field, OldValue, NewValue, DataType FROM Onboarding_Meeting_Detail__History WHERE ParentId = :meetingId];
        }
        
        return histories;
    }
}