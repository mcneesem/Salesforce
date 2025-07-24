@isTest
private class ProjectPercentageCompleteQueueableTest {

    @isTest
    private static void testProjectPercentageComplete() {
        pse__Proj__c projectRecord = new pse__Proj__c(
            Name='testProject'
        );
        insert projectRecord;
        //
        pse__Project_Task__c projectTaskRecord01 = new pse__Project_Task__c(
            Name='testProjectTask' ,
            pse__Project__c=projectRecord.Id ,
            pse__Status__c='Not Started'
        );
        insert projectTaskRecord01;
        pse__Project_Task__c projectTaskRecord02 = new pse__Project_Task__c(
            Name='testProjectTask' ,
            pse__Project__c=projectRecord.Id ,
            pse__Status__c='Complete'
        );
        insert projectTaskRecord02;
        //
        Test.startTest();
        ProjectPercentageCompleteQueueable.enqueueJob( new Set<Id>{ projectRecord.Id } );
        Test.stopTest();
        //
        List<pse__Proj__c> records = [ SELECT Id , NSP_Project_Complete__c FROM pse__Proj__c WHERE ( Id = :projectRecord.Id ) LIMIT 1 ];
        Assert.isNotNull( records , 'Null pse__Proj__c query results.' );
        Assert.isTrue( ( records.size() > 0 ) , 'No pse__Proj__c query results.' );
        Assert.isTrue( ( records.size() == 1 ) , 'Incorrect pse__Proj__c query results.' );
        Assert.isTrue( ( records[0].NSP_Project_Complete__c == 50.0 ) , 'Incorrect pse__Proj__c.NSP_Project_Complete__c query results.' );
    }

}
//