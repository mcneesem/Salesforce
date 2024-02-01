@isTest private class SchemaControllerTest {
    private static final String CLASS_NAME = ' ~ SchemaControllerTest';
    private static final Boolean ENABLE_testSchemaControllerSafeText = True;
    private static final Boolean ENABLE_testSchemaControllerSafeInteger = True;
    private static final String STRING_100 = '123456789X123456789X123456789X123456789X123456789L123456789X123456789X123456789X123456789X123456789C';

    @isTest private static void testSchemaControllerSafeText() {
        String METHOD_NAME = ' ~ testSchemaControllerSafeText';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testSchemaControllerSafeText ) {
            Test.startTest();
            Schema.DescribeFieldResult describedField = sObjectType.Lead.Fields.Name;
            String safeFieldValue = SchemaController.safeText(
                STRING_100 + STRING_100 + STRING_100 + STRING_100 + STRING_100 ,
                describedField
            );
            Assert.isNotNull( safeFieldValue , 'SchemaController.safeText() returned null.' );
            Assert.isTrue(
                ( safeFieldValue.length() <= describedField.getLength() ) ,
                'SchemaController.safeText() failed to truncate correctly.'
            );
            Test.stopTest();
        }
    }

    @isTest private static void testSchemaControllerSafeInteger() {
        String METHOD_NAME = ' ~ testSchemaControllerSafeInteger';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testSchemaControllerSafeInteger ) {
            Test.startTest();
            Schema.DescribeFieldResult describedField = sObjectType.Opportunity.Fields.Amount;
            Integer safeFieldValue = SchemaController.safeInteger(
                99999999999999999999.99 ,
                describedField
            );
            Assert.isNotNull( safeFieldValue , 'SchemaController.safeText() returned null.' );
            Decimal maxFieldValue = ( ( Decimal.valueOf( 10 ).pow( describedField.Precision ) - 1 ) / ( Decimal.valueOf( 10 ).pow( describedField.Scale ) ) );
            Assert.isTrue(
                ( safeFieldValue <= Integer.valueOf( maxFieldValue ) ) ,
                'SchemaController.safeText() failed to ceiling correctly.'
            );
            Test.stopTest();
        }
    }

}
//