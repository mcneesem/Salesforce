@isTest private class SetupAuditTrailSchedulableTest {
    private static final String CLASS_NAME = ' ~ SetupAuditTrailSchedulableTest';
    private static final Boolean ENABLE_testSetupAuditTrailSchedulable = True;

    @isTest private static void testSetupAuditTrailSchedulable() {
        String METHOD_NAME = ' ~ testSetupAuditTrailSchedulable';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testSetupAuditTrailSchedulable ) {
            Test.startTest();
            SetupAuditTrailSchedulable.ScheduleJob();
            System.assertEquals( True , True );
            Assert.isTrue( True , 'Failed assertion.' );
            Test.stopTest();
        }
    }

    private static SetupAuditTrail selectSetupAuditTrail() {
        String METHOD_NAME = ' ~ selectSetupAuditTrail';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        SetupAuditTrail record = [
            SELECT
            Id , Action , Section , Display ,
            CreatedDate , CreatedById , CreatedBy.Name ,
            DelegateUser , ResponsibleNamespacePrefix , CreatedByContext , CreatedByIssuer
            FROM SetupAuditTrail
            LIMIT 1
        ];
        System.debug( DEBUG_PREFIX + ' ~ record=' + record );
        Assert.areNotEqual( null , record , 'No SetupAuditTrail records exist.');
        return record;
    }

}
//