@isTest
private class LeadLastActivityDateHelperTest {

    @isTest
    private static void testEventUpdateLeadLastActivityDate() {

        Lead record = new Lead(
            FirstName='test' ,
            LastName='test' ,
            Company='test' ,
            Email='test@test.com.invalid' ,
            DNB_connect_DUNS_Number__c='743243789'
        );
        insert record;
        Assert.isNotNull( record.Id );

        Event activity = new Event(
            ActivityDate=System.today().addDays( -1 ) ,
            StartDateTime=System.now().addDays( -1 ) ,
            DurationInMinutes=1 ,
            Subject='test' ,
            WhoId=record.Id
        );

        Test.startTest();
        insert activity;
        Assert.isNotNull( activity.Id );
        Test.stopTest();

        Lead verify = [ SELECT Id , NSP_Last_Activity__c FROM Lead WHERE ( Id = :record.Id ) ]; 
        Assert.isNotNull( verify );
        Assert.isTrue( activity.ActivityDate == verify.NSP_Last_Activity__c );

    }

    @isTest
    private static void testTaskUpdateLeadLastActivityDate() {

        Lead record = new Lead(
            FirstName='test' ,
            LastName='test' ,
            Company='test' ,
            Email='test@test.com.invalid' ,
            DNB_connect_DUNS_Number__c='743243789'
        );
        insert record;
        Assert.isNotNull( record.Id );

        Task activity = new Task(
            ActivityDate=System.today().addDays( -1 ) ,
            Status='Completed' ,
            Subject='test' ,
            WhoId=record.Id
        );

        Test.startTest();
        insert activity;
        Assert.isNotNull( activity.Id );
        Test.stopTest();

        Lead verify = [ SELECT Id , NSP_Last_Activity__c FROM Lead WHERE ( Id = :record.Id ) ]; 
        Assert.isNotNull( verify );
        Assert.isTrue( activity.ActivityDate == verify.NSP_Last_Activity__c );

    }

}
//