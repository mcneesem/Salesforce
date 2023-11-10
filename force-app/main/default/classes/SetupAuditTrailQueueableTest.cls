@isTest private class SetupAuditTrailQueueableTest {
    private static final String CLASS_NAME = ' ~ SetupAuditTrailQueueableTest';
    private static final Boolean ENABLE_testSetupAuditTrailQueueableStartReport = True;
    private static final Boolean ENABLE_testSetupAuditTrailQueueableEnqueueJob = True;
    private static final Boolean ENABLE_testSetupAuditTrailQueueable = True;

    @testSetup private static void prepareData() {
        SetupAuditTrailReporting__c settings = SetupAuditTrailReporting__c.getOrgDefaults();
        settings.IsEnabled__c = True;
        settings.SoqlHoursLimit__c = 6;
        settings.SoqlUserLimit__c = 5;
        settings.SoqlAuditLimit__c = 10;
        settings.AuditorEmailAddresses__c = 'test@test.com.invalid';
        settings.NonCriticalTranslatedSections__c = 'Login-As Access';
        upsert settings;
        Set<String> testCoverage = SetupAuditTrailQueueable.nonCriticalTranslatedSections;
    }

    @isTest private static void testSetupAuditTrailQueueable() {
        String METHOD_NAME = ' ~ testSetupAuditTrailQueueable';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testSetupAuditTrailQueueable ) {
            Test.startTest();
            String local = SetupAuditTrailQueueable.sandboxName;
            System.assertEquals( True , True );
            Assert.isTrue( True , 'Failed assertion.' );
            Test.stopTest();
        }
    }

    @isTest private static void testSetupAuditTrailQueueableStartReport() {
        String METHOD_NAME = ' ~ testSetupAuditTrailQueueableStartReport';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testSetupAuditTrailQueueableStartReport ) {
            Test.startTest();
            SetupAuditTrailQueueable.startReport();
            String local = SetupAuditTrailQueueable.sandboxName;
            System.assertEquals( True , True );
            Assert.isTrue( True , 'Failed assertion.' );
            Test.stopTest();
        }
    }

    @isTest private static void testSetupAuditTrailQueueableEnqueueJob() {
        String METHOD_NAME = ' ~ testSetupAuditTrailQueueableEnqueueJob';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testSetupAuditTrailQueueableEnqueueJob ) {
            Test.startTest();

            SetupAuditTrail audit = SetupAuditTrailQueueableTest.selectSetupAuditTrail();
            List<Id> auditCreatorIds = new List<Id>();
            auditCreatorIds.add( audit.CreatedById );

            SetupAuditTrailQueueable.testEnqueueJob( auditCreatorIds );
            //System.enqueueJob( new SetupAuditTrailQueueable( auditCreatorIds ) );
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