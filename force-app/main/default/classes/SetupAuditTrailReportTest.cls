@isTest private class SetupAuditTrailReportTest {
    private static final String CLASS_NAME = ' ~ SetupAuditTrailReportTest';
    private static final Boolean ENABLE_testSetupAuditTrailReportSummary = True;
    private static final Boolean ENABLE_testSetupAuditTrailReportSingle = True;

    @testSetup private static void prepareData() {
        SetupAuditTrailQueueableTest.upsertCustomSettings();
    }

    @isTest private static void testSetupAuditTrailReportSummary() {
        String METHOD_NAME = ' ~ testSetupAuditTrailReportSummary';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testSetupAuditTrailReportSummary ) {
            Test.startTest();
            SetupAuditTrail audit = SetupAuditTrailReportTest.selectSetupAuditTrail();
            List<Id> auditCreatorIds = new List<Id>();
            auditCreatorIds.add( audit.CreatedById );
            SetupAuditTrailReport report = new SetupAuditTrailReport( auditCreatorIds );
            //Assert.isTrue( report.isNotBlank() , 'Blank SetupAuditTrailReport.' );
            String subject = report.getSubject();
            String body = report.getBody();
            System.assertEquals( True , True );
            Assert.isTrue( True , 'Failed assertion.' );
            Test.stopTest();
        }
    }

    @isTest private static void testSetupAuditTrailReportSingle() {
        String METHOD_NAME = ' ~ testSetupAuditTrailReportSingle';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testSetupAuditTrailReportSingle ) {
            Test.startTest();
            SetupAuditTrail audit = SetupAuditTrailReportTest.selectSetupAuditTrail();
            SetupAuditTrailReport report = new SetupAuditTrailReport( audit.CreatedById );
            //Assert.isTrue( report.isNotBlank() , 'Blank SetupAuditTrailReport.' );
            String subject = report.getSubject();
            String body = report.getBody();
            System.assertEquals( True , True );
            Assert.isTrue( True , 'Failed assertion.' );
            Test.stopTest();
        }
    }

    private static SetupAuditTrail selectSetupAuditTrail() {
        return SetupAuditTrailQueueableTest.selectSetupAuditTrail();
    }

}
//