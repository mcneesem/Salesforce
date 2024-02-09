@isTest(isParallel=True) public class SecurityControllerTest {
    private static final String CLASS_NAME = ' ~ SecurityControllerTest';
    private static final Boolean ENABLE_testSecurityController = True;

    @isTest private static void testSecurityController() {
        String METHOD_NAME = 'testSecurityController';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testSecurityController ) {
            Test.startTest();
            //
            String soqlQuery = SecurityController.getAccessibleSelectQuery( Lead.getSObjectType() );
            Assert.isTrue( String.isNotBlank( soqlQuery ) );
            soqlQuery = SecurityController.getAccessibleSelectQuery( Lead.getSObjectType() );
            Assert.isTrue( String.isNotBlank( soqlQuery ) );
            Map<String,Schema.SObjectField> accessibleFieldMap = SecurityController.getAccessibleFieldMap( Lead.getSObjectType() );
            Assert.isTrue( accessibleFieldMap != null );
            //
            Test.stopTest();
        }
    }
}
//