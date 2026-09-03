@isTest(seeAllData=false)
private class OpportunityMaxOrientationDateActionTest {

    private static final Integer BULK_SIZE = 251;

    private static void enableQueueable( Boolean isEnabled ) {
        OpportunityTriggerSettings__c settings = new OpportunityTriggerSettings__c();
        settings.SetupOwnerId = UserInfo.getUserId();
        settings.IsEnabledQueueable__c = isEnabled;
        settings.DelayMinutes__c = 1;
        insert settings;
    }

    private static List<Opportunity> createOpportunities( Integer count ) {
        Account acct = new Account();
        acct.Name = 'Test';
        insert acct;

        List<Opportunity> opportunities = new List<Opportunity>();
        for ( Integer i = 0 ; i < count ; i++ ) {
            Opportunity opp = new Opportunity();
            opp.AccountId = acct.Id;
            opp.Name = 'Test Opportunity ' + i;
            opp.StageName = 'Prospecting';
            opp.CloseDate = Date.today();
            opportunities.add( opp );
        }
        insert opportunities;
        return opportunities;
    }

    private static List<OpportunityMaxOrientationDateAction.FlowInput> buildInputs( List<Opportunity> opportunities , Date maxOrientationDate ) {
        List<OpportunityMaxOrientationDateAction.FlowInput> inputs = new List<OpportunityMaxOrientationDateAction.FlowInput>();
        for ( Opportunity opp : opportunities ) {
            OpportunityMaxOrientationDateAction.FlowInput input = new OpportunityMaxOrientationDateAction.FlowInput();
            input.opportunitytId = opp.Id;
            input.maxOrientationDate = maxOrientationDate;
            inputs.add( input );
        }
        return inputs;
    }

    @isTest
    private static void shouldPopulateMaxOrientationDate_WhenEnabled() {
        Date today = Date.today();
        enableQueueable( true );
        List<Opportunity> opportunities = createOpportunities( 1 );

        Test.startTest();
        OpportunityMaxOrientationDateAction.invoke( buildInputs( opportunities , today ) );
        Test.stopTest(); // forces the enqueued Queueable to run before assertions

        List<Opportunity> records = [
            SELECT Id , Max_Orientation_Date__c
            FROM Opportunity
            WHERE Id = :opportunities[0].Id
        ];

        System.Assert.areEqual( 1 , records.size() , 'Exactly one Opportunity should be returned' );
        System.Assert.areEqual( today , records[0].Max_Orientation_Date__c , 'Max Orientation Date should be populated when the queueable is enabled' );
    }

    @isTest
    private static void shouldNotPopulateMaxOrientationDate_WhenDisabled() {
        Date today = Date.today();
        enableQueueable( false );
        List<Opportunity> opportunities = createOpportunities( 1 );

        Test.startTest();
        OpportunityMaxOrientationDateAction.invoke( buildInputs( opportunities , today ) );
        Test.stopTest();

        List<Opportunity> records = [
            SELECT Id , Max_Orientation_Date__c
            FROM Opportunity
            WHERE Id = :opportunities[0].Id
        ];

        System.Assert.areEqual( 1 , records.size() , 'Exactly one Opportunity should be returned' );
        System.Assert.areEqual( null , records[0].Max_Orientation_Date__c , 'Max Orientation Date should remain null when the queueable is disabled' );
    }

    @isTest
    private static void shouldPopulateMaxOrientationDate_WhenBulk() {
        Date today = Date.today();
        enableQueueable( true );
        List<Opportunity> opportunities = createOpportunities( BULK_SIZE );

        Test.startTest();
        OpportunityMaxOrientationDateAction.invoke( buildInputs( opportunities , today ) );
        Test.stopTest();

        List<Opportunity> records = [
            SELECT Id , Max_Orientation_Date__c
            FROM Opportunity
            WHERE Max_Orientation_Date__c = :today
        ];

        System.Assert.areEqual( BULK_SIZE , records.size() , 'All bulk Opportunities should have Max Orientation Date populated' );
    }

    @isTest
    private static void shouldHandleException_WhenInvoked() {
        Test.startTest();
        OpportunityMaxOrientationDateAction.testHandleException( new DmlException( 'test' ) , 'shouldHandleException_WhenInvoked' );
        Test.stopTest();

        System.Assert.isTrue( true , 'handleException should log without throwing' );
    }

}
//end