@isTest
private class ProjectPercentageCompleteQueueableTest {

    @testSetup
    private static void setup() {
        ProjectTaskTriggerSettings__c taskSettings = ProjectTaskTriggerSettings__c.getOrgDefaults();
        taskSettings.IsEnabled__c = true;
        taskSettings.IsEnabledQueueablePercentage__c = true;
        taskSettings.IsEnabledFuturePercentage__c = false;
        upsert taskSettings;
        //
        ProjectPercentageCompleteSettings__c percentageSettings = ProjectPercentageCompleteSettings__c.getOrgDefaults();
        percentageSettings.IsEnabled__c = true;
        percentageSettings.StepSize__c = 1;
        upsert percentageSettings;
    }

    @isTest
    private static void testProjectPercentageComplete() {
        pse__Proj__c projectRecord = new pse__Proj__c(
            Name='testProject'
        );
        insert projectRecord;
        //
        Test.startTest();
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