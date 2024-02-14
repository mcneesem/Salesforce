/**
Apex Class Name      :   NSP_CreateRAforRecurringEventsBatchTest
Version              :  1.0                                                                          
Created Date         :  11/23/2023   
Function             :  This class is used as a test class to NSP_CreateRAforRecurringEventsBatch
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Harsha Khiroya                   11/23/2023            First Iteration
*/
@isTest(SeeAllData=false)
public class NSP_CreateRAforRecurringEventsBatchTest {

    @testSetup
    static void setupTestData(){
        User tUser =  NSP_TestHelper.createUser(false);
        tUser.Phone = '(112)6475261 ext415';
        tUser.Username = 'jsmith@test.com.abc'+System.currentTimeMillis();
        tUser.NSP_Service_Region__c = 'MMSO - Southeast';
        tUser.NSP_Salesforce_Field_Service__c = NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_DISPATCHER_RESOURCE;
        tUser.NSP_Dispatch_Region__c = NSP_ServiceConstants.CHILD_DISPATCH_REGION;
        insert tUser;
        Event newEvent = new Event();
        newEvent.OwnerId = tUser.Id;
        newEvent.Subject = 'Test Subject For Event';
        newEvent.DurationInMinutes = 60;
        newEvent.ActivityDateTime = system.today();
        newEvent.StartDateTime = system.today();
        newEvent.IsRecurrence = true;
        newEvent.RecurrenceStartDateTime = system.today();
        newEvent.RecurrenceEndDateOnly = System.today()+30;
        newEvent.RecurrenceType = 'RecursDaily';
        newEvent.RecurrenceInterval = 2; // This means that the event will wait 1 day before recurring again
        newEvent.IsAllDayEvent =false;
        newEvent.DurationInMinutes =60;
        Test.startTest();
        system.runAs(tUser){
            insert newEvent; 
        }
        Test.stopTest();
        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(newEvent.Id, yesterday);  
    }
    
    @isTest
    static void terminateAccount(){
        try{
            List<String> RA_FIELD = new List<String>{'Id', 'Event_Id__c','Type'};
            test.startTest();
            NSP_CreateRAforRecurringEventsBatch.schedule();
            test.stopTest();
            String query = new NSP_QueryBuilder('ResourceAbsence', RA_FIELD)
                .addFilter('Type', 'Test Subject For Event').addLimit(1).build();
            ResourceAbsence RARec = Database.query(query);
            system.assertNotEquals(RARec , NULL);
        } catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }

}